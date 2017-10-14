--- **Core** -- Spawn dynamically new STATICs in your missions.
--  
-- ![Banner Image](..\Presentations\SPAWNSTATIC\Dia1.JPG)
-- 
-- ====
-- 
-- SPAWNSTATIC spawns static structures in your missions dynamically. See below the SPAWNSTATIC class documentation.
-- 
-- ====
-- 
-- # Demo Missions
-- 
-- ### [SPAWNSTATIC Demo Missions source code](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master-release/SPS - Spawning Statics)
-- 
-- ### [SPAWNSTATIC Demo Missions, only for beta testers](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/SPS%20-%20Spawning%20Statics)
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
-- ### Author: **Sven Van de Velde (FlightControl)**
-- ### Contributions: 
-- 
-- ====
-- 
-- @module SpawnStatic



--- @type SPAWNSTATIC
-- @extends Core.Base#BASE


--- # SPAWNSTATIC class, extends @{Base#BASE}
-- 
-- The SPAWNSTATIC class allows to spawn dynamically new @{Static}s.
-- Through creating a copy of an existing static object template as defined in the Mission Editor (ME),
-- SPAWNSTATIC can retireve the properties of the defined static object template (like type, category etc), and "copy"
-- these properties to create a new static object and place it at the desired coordinate.
-- 
-- New spawned @{Static}s get **the same name** as the name of the template Static, 
-- or gets the given name when a new name is provided at the Spawn method.  
-- By default, spawned @{Static}s will follow a naming convention at run-time:
-- 
--   * Spawned @{Static}s will have the name _StaticName_#_nnn_, where _StaticName_ is the name of the **Template Static**, 
--   and _nnn_ is a **counter from 0 to 99999**.
-- 
--   
-- ## SPAWNSTATIC construction methods
-- 
-- Create a new SPAWNSTATIC object with the @{#SPAWNSTATIC.NewFromStatic}():
-- 
--   * @{#SPAWNSTATIC.NewFromStatic}(): Creates a new SPAWNSTATIC object given a name that is used as the base of the naming of each spawned Static.
--
-- ## **Spawn** methods
-- 
-- Groups can be spawned at different times and methods:
-- 
--   * @{#SPAWNSTATIC.SpawnFromPointVec2}(): Spawn a new group from a POINT_VEC2 coordinate. 
--   (The group will be spawned at land height ).
--   * @{#SPAWNSTATIC.SpawnFromZone}(): Spawn a new group in a @{Zone}.
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
function SPAWNSTATIC:NewFromStatic( SpawnTemplatePrefix, CountryID ) --R2.1
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
function SPAWNSTATIC:NewFromType( SpawnTypeName, SpawnShapeName, SpawnCategory, CountryID ) --R2.1
  local self = BASE:Inherit( self, BASE:New() ) -- #SPAWNSTATIC
  self:F( { SpawnTypeName } )
  
  self.SpawnTypeName = SpawnTypeName
  self.CountryID = CountryID
  self.SpawnIndex = 0

  self:SetEventPriority( 5 )

  return self
end

--- Creates a new @{Static} at the original position.
-- @param #SPAWNSTATIC self
-- @param #number Heading The heading of the static, which is a number in degrees from 0 to 360.
-- @param #string (optional) The name of the new static.
-- @return #SPAWNSTATIC
function SPAWNSTATIC:Spawn( Heading, NewName ) --R2.3
  self:F( { Heading, NewName  } )
  
  local CountryName = _DATABASE.COUNTRY_NAME[self.CountryID]
  
  local StaticTemplate = _DATABASE:GetStaticUnitTemplate( self.SpawnTemplatePrefix )
  
  StaticTemplate.name = NewName or string.format("%s#%05d", self.SpawnTemplatePrefix, self.SpawnIndex )
  StaticTemplate.heading = ( Heading / 180 ) * math.pi
  
  StaticTemplate.CountryID = nil
  StaticTemplate.CoalitionID = nil
  StaticTemplate.CategoryID = nil
  
  local Static = coalition.addStaticObject( self.CountryID, StaticTemplate )
  
  self.SpawnIndex = self.SpawnIndex + 1

  return Static
end



--- Creates a new @{Static} from a POINT_VEC2.
-- @param #SPAWNSTATIC self
-- @param Core.Point#POINT_VEC2 PointVec2 The 2D coordinate where to spawn the static.
-- @param #number Heading The heading of the static, which is a number in degrees from 0 to 360.
-- @param #string (optional) The name of the new static.
-- @return #SPAWNSTATIC
function SPAWNSTATIC:SpawnFromPointVec2( PointVec2, Heading, NewName ) --R2.1
  self:F( { PointVec2, Heading, NewName  } )
  
  local CountryName = _DATABASE.COUNTRY_NAME[self.CountryID]
  
  local StaticTemplate = _DATABASE:GetStaticUnitTemplate( self.SpawnTemplatePrefix )
  
  StaticTemplate.x = PointVec2.x
  StaticTemplate.y = PointVec2.z

  StaticTemplate.units = nil
  StaticTemplate.route = nil
  StaticTemplate.groupId = nil
    
  
  StaticTemplate.name = NewName or string.format("%s#%05d", self.SpawnTemplatePrefix, self.SpawnIndex )
  StaticTemplate.heading = ( Heading / 180 ) * math.pi
  
  StaticTemplate.CountryID = nil
  StaticTemplate.CoalitionID = nil
  StaticTemplate.CategoryID = nil
  
  local Static = coalition.addStaticObject( self.CountryID, StaticTemplate )
  
  self.SpawnIndex = self.SpawnIndex + 1

  return Static
end

--- Creates a new @{Static} from a @{Zone}.
-- @param #SPAWNSTATIC self
-- @param Core.Zone#ZONE_BASE Zone The Zone where to spawn the static.
-- @param #number Heading The heading of the static, which is a number in degrees from 0 to 360.
-- @param #string (optional) The name of the new static.
-- @return #SPAWNSTATIC
function SPAWNSTATIC:SpawnFromZone( Zone, Heading, NewName ) --R2.1
  self:F( { Zone, Heading, NewName  } )

  local Static = self:SpawnFromPointVec2( Zone:GetPointVec2(), Heading, NewName )
  
  return Static
end

