--- **Core** - Spawn statics.
--
-- ===
--
-- ## Features:
--
--   * Spawn new statics from a static already defined in the mission editor.
--   * Spawn new statics from a given template.
--   * Spawn new statics from a given type.
--   * Spawn with a custom heading and location.
--   * Spawn within a zone.
--   * Spawn statics linked to units, .e.g on aircraft carriers.
--
-- ===
--
-- # Demo Missions
--
-- ## [SPAWNSTATIC Demo Missions](https://github.com/FlightControl-Master/MOOSE_Demos/tree/master/Core/SpawnStatic)
--
--
-- ===
--
-- # YouTube Channel
--
-- ## No videos yet!
--
-- ===
--
-- ### Author: **FlightControl**
-- ### Contributions: **funkyfranky**
--
-- ===
--
-- @module Core.SpawnStatic
-- @image Core_Spawnstatic.JPG

--- @type SPAWNSTATIC
-- @field #string SpawnTemplatePrefix Name of the template group.
-- @field #number CountryID Country ID.
-- @field #number CoalitionID Coalition ID.
-- @field #number CategoryID Category ID.
-- @field #number SpawnIndex Running number increased with each new Spawn.
-- @field Wrapper.Unit#UNIT InitLinkUnit The unit the static is linked to.
-- @field #number InitOffsetX Link offset X coordinate.
-- @field #number InitOffsetY Link offset Y coordinate.
-- @field #number InitOffsetAngle Link offset angle in degrees.
-- @field #number InitStaticHeading Heading of the static.
-- @field #string InitStaticLivery Livery for aircraft.
-- @field #string InitStaticShape Shape of the static.
-- @field #string InitStaticType Type of the static.
-- @field #string InitStaticCategory Categrory of the static.
-- @field #string InitStaticName Name of the static.
-- @field Core.Point#COORDINATE InitStaticCoordinate Coordinate where to spawn the static.
-- @field #boolean InitStaticDead Set static to be dead if true.
-- @field #boolean InitStaticCargo If true, static can act as cargo.
-- @field #number InitStaticCargoMass Mass of cargo in kg.
-- @extends Core.Base#BASE


--- Allows to spawn dynamically new @{Wrapper.Static}s into your mission.
--
-- Through creating a copy of an existing static object template as defined in the Mission Editor (ME), SPAWNSTATIC can retireve the properties of the defined static object template (like type, category etc),
-- and "copy" these properties to create a new static object and place it at the desired coordinate.
--
-- New spawned @{Wrapper.Static}s get **the same name** as the name of the template Static, or gets the given name when a new name is provided at the Spawn method.
-- By default, spawned @{Wrapper.Static}s will follow a naming convention at run-time:
--
--   * Spawned @{Wrapper.Static}s will have the name _StaticName_#_nnn_, where _StaticName_ is the name of the **Template Static**, and _nnn_ is a **counter from 0 to 99999**.
--
-- # SPAWNSTATIC Constructors
--
-- Firstly, we need to create a SPAWNSTATIC object that will be used to spawn new statics into the mission. There are three ways to do this.
--
-- ## Use another Static
--
-- A new SPAWNSTATIC object can be created using another static by the @{#SPAWNSTATIC.NewFromStatic}() function. All parameters such as position, heading, country will be initialized
-- from the static.
--
-- ## From a Template
--
-- A SPAWNSTATIC object can also be created from a template table using the @{#SPAWNSTATIC.NewFromTemplate}(SpawnTemplate, CountryID) function. All parameters are taken from the template.
--
-- ## From a Type
--
-- A very basic method is to create a SPAWNSTATIC object by just giving the type of the static. All parameters must be initialized from the InitXYZ functions described below. Otherwise default values
-- are used. For example, if no spawn coordinate is given, the static will be created at the origin of the map.
--
-- # Setting Parameters
--
-- Parameters such as the spawn position, heading, country etc. can be set via :Init*XYZ* functions. Note that these functions must be given before the actual spawn command!
--
--   * @{#SPAWNSTATIC.InitCoordinate}(Coordinate) Sets the coordinate where the static is spawned. Statics are always spawnd on the ground.
--   * @{#SPAWNSTATIC.InitHeading}(Heading) sets the orientation of the static.
--   * @{#SPAWNSTATIC.InitLivery}(LiveryName) sets the livery of the static. Not all statics support this.
--   * @{#SPAWNSTATIC.InitType}(StaticType) sets the type of the static.
--   * @{#SPAWNSTATIC.InitShape}(StaticType) sets the shape of the static. Not all statics have this parameter.
--   * @{#SPAWNSTATIC.InitNamePrefix}(NamePrefix) sets the name prefix of the spawned statics.
--   * @{#SPAWNSTATIC.InitCountry}(CountryID) sets the country and therefore the coalition of the spawned statics.
--   * @{#SPAWNSTATIC.InitLinkToUnit}(Unit, OffsetX, OffsetY, OffsetAngle) links the static to a unit, e.g. to an aircraft carrier.
--
-- # Spawning the Statics
--
-- Once the SPAWNSTATIC object is created and parameters are initialized, the spawn command can be given. There are different methods where some can be used to directly set parameters
-- such as position and heading.
--
--   * @{#SPAWNSTATIC.Spawn}(Heading, NewName) spawns the static with the set parameters. Optionally, heading and name can be given. The name **must be unique**!
--   * @{#SPAWNSTATIC.SpawnFromCoordinate}(Coordinate, Heading, NewName) spawn the static at the given coordinate. Optionally, heading and name can be given. The name **must be unique**!
--   * @{#SPAWNSTATIC.SpawnFromPointVec2}(PointVec2, Heading, NewName) spawns the static at a POINT_VEC2 coordinate. Optionally, heading and name can be given. The name **must be unique**!
--   * @{#SPAWNSTATIC.SpawnFromZone}(Zone, Heading, NewName) spawns the static at the center of a @{Core.Zone}. Optionally, heading and name can be given. The name **must be unique**!
--
-- @field #SPAWNSTATIC SPAWNSTATIC
--
SPAWNSTATIC = {
  ClassName  = "SPAWNSTATIC",
  SpawnIndex = 0,
}

--- Static template table data.
-- @type SPAWNSTATIC.TemplateData
-- @field #string name Name of the static.
-- @field #string type Type of the static.
-- @field #string category Category of the static.
-- @field #number x X-coordinate of the static.
-- @field #number y Y-coordinate of teh static.
-- @field #number heading Heading in rad.
-- @field #boolean dead Static is dead if true.
-- @field #string livery_id Livery name.
-- @field #number unitId Unit ID.
-- @field #number groupId Group ID.
-- @field #table offsets Offset parameters when linked to a unit.
-- @field #number mass Cargo mass in kg.
-- @field #boolean canCargo Static can be a cargo.

--- Creates the main object to spawn a @{Wrapper.Static} defined in the mission editor (ME).
-- @param #SPAWNSTATIC self
-- @param #string SpawnTemplateName Name of the static object in the ME. Each new static will have the name starting with this prefix.
-- @param DCS#country.id SpawnCountryID (Optional) The ID of the country.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:NewFromStatic(SpawnTemplateName, SpawnCountryID)

  local self = BASE:Inherit( self, BASE:New() ) -- #SPAWNSTATIC

  local TemplateStatic, CoalitionID, CategoryID, CountryID = _DATABASE:GetStaticGroupTemplate(SpawnTemplateName)

  if TemplateStatic then
    self.SpawnTemplatePrefix = SpawnTemplateName
    self.TemplateStaticUnit  = UTILS.DeepCopy(TemplateStatic.units[1])
    self.CountryID           = SpawnCountryID or CountryID
    self.CategoryID          = CategoryID
    self.CoalitionID         = CoalitionID
    self.SpawnIndex          = 0
  else
    error( "SPAWNSTATIC:New: There is no static declared in the mission editor with SpawnTemplatePrefix = '" .. tostring(SpawnTemplateName) .. "'" )
  end

  self:SetEventPriority( 5 )

  return self
end

--- Creates the main object to spawn a @{Wrapper.Static} given a template table.
-- @param #SPAWNSTATIC self
-- @param #table SpawnTemplate Template used for spawning.
-- @param DCS#country.id CountryID The ID of the country. Default `country.id.USA`.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:NewFromTemplate(SpawnTemplate, CountryID)

  local self = BASE:Inherit( self, BASE:New() ) -- #SPAWNSTATIC

  self.TemplateStaticUnit  = UTILS.DeepCopy(SpawnTemplate)
  self.SpawnTemplatePrefix = SpawnTemplate.name
  self.CountryID           = CountryID or country.id.USA

  return self
end

--- Creates the main object to spawn a @{Wrapper.Static} from a given type.
-- NOTE that you have to init many other parameters as spawn coordinate etc.
-- @param #SPAWNSTATIC self
-- @param #string StaticType Type of the static.
-- @param #string StaticCategory Category of the static, e.g. "Planes".
-- @param DCS#country.id CountryID The ID of the country. Default `country.id.USA`.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:NewFromType(StaticType, StaticCategory, CountryID)

  local self = BASE:Inherit( self, BASE:New() ) -- #SPAWNSTATIC

  self.InitStaticType=StaticType
  self.InitStaticCategory=StaticCategory
  self.CountryID=CountryID or country.id.USA
  self.SpawnTemplatePrefix=self.InitStaticType
  self.TemplateStaticUnit = {}

  self.InitStaticCoordinate=COORDINATE:New(0, 0, 0)
  self.InitStaticHeading=0

  return self
end

--- (Internal/Cargo) Init the resource table for STATIC object that should be spawned containing storage objects.
-- NOTE that you have to init many other parameters as the resources.
-- @param #SPAWNSTATIC self
-- @param #number CombinedWeight The weight this cargo object should have (some have fixed weights!), defaults to 1kg.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:_InitResourceTable(CombinedWeight)
  if not self.TemplateStaticUnit.resourcePayload then
    self.TemplateStaticUnit.resourcePayload = {
      ["weapons"] = {},
      ["aircrafts"] = {},
      ["gasoline"] = 0,
      ["diesel"] = 0,
      ["methanol_mixture"] = 0,
      ["jet_fuel"] = 0,   
    }
  end
  self:InitCargo(true)
  self:InitCargoMass(CombinedWeight or 1)
  return self
end

--- (User/Cargo) Add to resource table for STATIC object that should be spawned containing storage objects. Inits the object table if necessary and sets it to be cargo for helicopters.
-- @param #SPAWNSTATIC self
-- @param #string Type Type of cargo. Known types are: STORAGE.Type.WEAPONS, STORAGE.Type.LIQUIDS, STORAGE.Type.AIRCRAFT. Liquids are fuel.
-- @param #string Name Name of the cargo type. Liquids can be STORAGE.LiquidName.JETFUEL, STORAGE.LiquidName.GASOLINE, STORAGE.LiquidName.MW50 and STORAGE.LiquidName.DIESEL. The currently available weapon items are available in the `ENUMS.Storage.weapons`, e.g. `ENUMS.Storage.weapons.bombs.Mk_82Y`. Aircraft go by their typename.
-- @param #number Amount of tons (liquids) or number (everything else) to add.
-- @param #number CombinedWeight Combined weight to be set to this static cargo object. NOTE - some static cargo objects have fixed weights!
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:AddCargoResource(Type,Name,Amount,CombinedWeight)
  if not self.TemplateStaticUnit.resourcePayload then
    self:_InitResourceTable(CombinedWeight)
  end
  if Type == STORAGE.Type.LIQUIDS and type(Name) == "string" then
    self.TemplateStaticUnit.resourcePayload[Name] = Amount
  else
  self.TemplateStaticUnit.resourcePayload[Type] = {
    [Name] = {
      ["amount"] = Amount,
      }
  }
  end
  UTILS.PrintTableToLog(self.TemplateStaticUnit)
  return self
end

--- (User/Cargo) Resets resource table to zero for STATIC object that should be spawned containing storage objects. Inits the object table if necessary and sets it to be cargo for helicopters.
-- Handy if you spawn from cargo statics which have resources already set.
-- @param #SPAWNSTATIC self
-- @return #SPAWNSTATIC self 
function SPAWNSTATIC:ResetCargoResources()
  self.TemplateStaticUnit.resourcePayload = nil
  self:_InitResourceTable()
  return self
end

--- Initialize heading of the spawned static.
-- @param #SPAWNSTATIC self
-- @param Core.Point#COORDINATE Coordinate Position where the static is spawned.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitCoordinate(Coordinate)
  self.InitStaticCoordinate=Coordinate
  return self
end

--- Initialize heading of the spawned static.
-- @param #SPAWNSTATIC self
-- @param #number Heading The heading in degrees.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitHeading(Heading)
  self.InitStaticHeading=Heading
  return self
end

--- Initialize livery of the spawned static.
-- @param #SPAWNSTATIC self
-- @param #string LiveryName Name of the livery to use.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitLivery(LiveryName)
  self.InitStaticLivery=LiveryName
  return self
end

--- Initialize type of the spawned static.
-- @param #SPAWNSTATIC self
-- @param #string StaticType Type of the static, e.g. "FA-18C_hornet".
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitType(StaticType)
  self.InitStaticType=StaticType
  return self
end

--- Initialize shape of the spawned static. Required by some but not all statics.
-- @param #SPAWNSTATIC self
-- @param #string StaticShape Shape of the static, e.g. "carrier_tech_USA".
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitShape(StaticShape)
  self.InitStaticShape=StaticShape
  return self
end

--- Initialize parameters for spawning FARPs.
-- @param #SPAWNSTATIC self
-- @param #number CallsignID Callsign ID. Default 1 (="London").
-- @param #number Frequency Frequency in MHz. Default 127.5 MHz.
-- @param #number Modulation Modulation 0=AM, 1=FM.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitFARP(CallsignID, Frequency, Modulation)
  self.InitFarp=true
  self.InitFarpCallsignID=CallsignID or 1
  self.InitFarpFreq=Frequency or 127.5
  self.InitFarpModu=Modulation or 0
  return self
end

--- Initialize cargo mass.
-- @param #SPAWNSTATIC self
-- @param #number Mass Mass of the cargo in kg.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitCargoMass(Mass)
  self.InitStaticCargoMass=Mass
  return self
end

--- Initialize as cargo.
-- @param #SPAWNSTATIC self
-- @param #boolean IsCargo If true, this static can act as cargo.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitCargo(IsCargo)
  self.InitStaticCargo=IsCargo
  return self
end

--- Initialize as dead.
-- @param #SPAWNSTATIC self
-- @param #boolean IsDead If true, this static is dead.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitDead(IsDead)
  self.InitStaticDead=IsDead
  return self
end

--- Initialize country of the spawned static. This determines the category.
-- @param #SPAWNSTATIC self
-- @param #string CountryID The country ID, e.g. country.id.USA.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitCountry(CountryID)
  self.CountryID=CountryID
  return self
end

--- Initialize name prefix statics get. This will be appended by "#0001", "#0002" etc.
-- @param #SPAWNSTATIC self
-- @param #string NamePrefix Name prefix of statics spawned. Will append #0001, etc to the name.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitNamePrefix(NamePrefix)
  self.SpawnTemplatePrefix=NamePrefix
  return self
end

--- Init link to a unit.
-- @param #SPAWNSTATIC self
-- @param Wrapper.Unit#UNIT Unit The unit to which the static is linked.
-- @param #number OffsetX Offset in X.
-- @param #number OffsetY Offset in Y.
-- @param #number OffsetAngle Offset angle in degrees.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitLinkToUnit(Unit, OffsetX, OffsetY, OffsetAngle)

  self.InitLinkUnit=Unit
  self.InitOffsetX=OffsetX or 0
  self.InitOffsetY=OffsetY or 0
  self.InitOffsetAngle=OffsetAngle or 0

  return self
end

--- Allows to place a CallFunction hook when a new static spawns.
-- The provided method will be called when a new group is spawned, including its given parameters.
-- The first parameter of the SpawnFunction is the @{Wrapper.Static#STATIC} that was spawned.
-- @param #SPAWNSTATIC self
-- @param #function SpawnCallBackFunction The function to be called when a group spawns.
-- @param SpawnFunctionArguments A random amount of arguments to be provided to the function when the group spawns.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:OnSpawnStatic( SpawnCallBackFunction, ... )
  self:F( "OnSpawnStatic" )

  self.SpawnFunctionHook = SpawnCallBackFunction
  self.SpawnFunctionArguments = {}
  if arg then
    self.SpawnFunctionArguments = arg
  end

  return self
end

--- Spawn a new STATIC object.
-- @param #SPAWNSTATIC self
-- @param #number Heading (Optional) The heading of the static, which is a number in degrees from 0 to 360. Default is the heading of the template.
-- @param #string NewName (Optional) The name of the new static.
-- @return Wrapper.Static#STATIC The static spawned.
function SPAWNSTATIC:Spawn(Heading, NewName)

  if Heading then
    self.InitStaticHeading=Heading
  end

  if NewName then
    self.InitStaticName=NewName
  end

  return self:_SpawnStatic(self.TemplateStaticUnit, self.CountryID)

end

--- Creates a new @{Wrapper.Static} from a POINT_VEC2.
-- @param #SPAWNSTATIC self
-- @param Core.Point#POINT_VEC2 PointVec2 The 2D coordinate where to spawn the static.
-- @param #number Heading The heading of the static, which is a number in degrees from 0 to 360.
-- @param #string NewName (Optional) The name of the new static.
-- @return Wrapper.Static#STATIC The static spawned.
function SPAWNSTATIC:SpawnFromPointVec2(PointVec2, Heading, NewName)

  local vec2={x=PointVec2:GetX(), y=PointVec2:GetY()}

  local Coordinate=COORDINATE:NewFromVec2(vec2)

  return self:SpawnFromCoordinate(Coordinate, Heading, NewName)
end


--- Creates a new @{Wrapper.Static} from a COORDINATE.
-- @param #SPAWNSTATIC self
-- @param Core.Point#COORDINATE Coordinate The 3D coordinate where to spawn the static.
-- @param #number Heading (Optional) Heading The heading of the static in degrees. Default is 0 degrees.
-- @param #string NewName (Optional) The name of the new static.
-- @return Wrapper.Static#STATIC The spawned STATIC object.
function SPAWNSTATIC:SpawnFromCoordinate(Coordinate, Heading, NewName)

  -- Set up coordinate.
  self.InitStaticCoordinate=Coordinate

  if Heading then
    self.InitStaticHeading=Heading
  end

  if NewName then
    self.InitStaticName=NewName
  end

  return self:_SpawnStatic(self.TemplateStaticUnit, self.CountryID)
end


--- Creates a new @{Wrapper.Static} from a @{Core.Zone}.
-- @param #SPAWNSTATIC self
-- @param Core.Zone#ZONE_BASE Zone The Zone where to spawn the static.
-- @param #number Heading (Optional)The heading of the static in degrees. Default is the heading of the template.
-- @param #string NewName (Optional) The name of the new static.
-- @return Wrapper.Static#STATIC The static spawned.
function SPAWNSTATIC:SpawnFromZone(Zone, Heading, NewName)

  -- Spawn the new static at the center of the zone.
  local Static = self:SpawnFromPointVec2( Zone:GetPointVec2(), Heading, NewName )

  return Static
end

--- Spawns a new static using a given template. Additionally, the country ID needs to be specified, which also determines the coalition of the spawned static.
-- @param #SPAWNSTATIC self
-- @param #SPAWNSTATIC.TemplateData Template Spawn unit template.
-- @param #number CountryID The country ID.
-- @return Wrapper.Static#STATIC The static spawned.
function SPAWNSTATIC:_SpawnStatic(Template, CountryID)

  Template=Template or {}

  local CountryID=CountryID or self.CountryID

  if self.InitStaticType then
    Template.type=self.InitStaticType
  end

  if self.InitStaticCategory then
    Template.category=self.InitStaticCategory
  end

  if self.InitStaticCoordinate then
    Template.x   = self.InitStaticCoordinate.x
    Template.y   = self.InitStaticCoordinate.z
    Template.alt = self.InitStaticCoordinate.y
  end

  if self.InitStaticHeading then
    Template.heading = math.rad(self.InitStaticHeading)
  end

  if self.InitStaticShape then
    Template.shape_name=self.InitStaticShape
  end

  if self.InitStaticLivery then
    Template.livery_id=self.InitStaticLivery
  end

  if self.InitStaticDead~=nil then
    Template.dead=self.InitStaticDead
  end

  if self.InitStaticCargo~=nil then
    Template.canCargo=self.InitStaticCargo
  end

  if self.InitStaticCargoMass~=nil then
    Template.mass=self.InitStaticCargoMass
  end

  if self.InitLinkUnit then
    Template.linkUnit=self.InitLinkUnit:GetID()
    Template.linkOffset=true
    Template.offsets={}
    Template.offsets.y=self.InitOffsetY
    Template.offsets.x=self.InitOffsetX
    Template.offsets.angle=self.InitOffsetAngle and math.rad(self.InitOffsetAngle) or 0
  end

  if self.InitFarp then
    Template.heliport_callsign_id = self.InitFarpCallsignID
    Template.heliport_frequency   = self.InitFarpFreq
    Template.heliport_modulation  = self.InitFarpModu
    Template.unitId=nil
  end

  -- Increase spawn index counter.
  self.SpawnIndex = self.SpawnIndex + 1

  -- Name of the spawned static.
  Template.name = self.InitStaticName or string.format("%s#%05d", self.SpawnTemplatePrefix, self.SpawnIndex)

  -- Add static to the game.
  local Static=nil  --DCS#StaticObject

  if self.InitFarp then

    local TemplateGroup={}
    TemplateGroup.units={}
    TemplateGroup.units[1]=Template

    TemplateGroup.visible=true
    TemplateGroup.hidden=false
    TemplateGroup.x=Template.x
    TemplateGroup.y=Template.y
    TemplateGroup.name=Template.name

    self:T("Spawning FARP")
    self:T({Template=Template})
    self:T({TemplateGroup=TemplateGroup})

    -- ED's dirty way to spawn FARPS.
    Static=coalition.addGroup(CountryID, -1, TemplateGroup)

    -- Currently DCS 2.8 does not trigger birth events if FARPS are spawned!
    -- We create such an event. The airbase is registered in Core.Event
    local Event = {
      id = EVENTS.Birth,
      time = timer.getTime(),
      initiator = Static
      }
    -- Create BIRTH event.
    world.onEvent(Event)

  else
    self:T("Spawning Static")
    self:T2({Template=Template})
    Static=coalition.addStaticObject(CountryID, Template)
    
    if Static then
      self:T(string.format("Succesfully spawned static object \"%s\" ID=%d", Static:getName(), Static:getID()))
      --[[
      local static=StaticObject.getByName(Static:getName())
      if static then
        env.info(string.format("FF got static from StaticObject.getByName"))
      else
        env.error(string.format("FF error did NOT get static from StaticObject.getByName"))
      end ]]      
    else
      self:E(string.format("ERROR: DCS static object \"%s\" is nil!", tostring(Template.name)))
    end
  end
  
  -- Add and register the new static.
  local mystatic=_DATABASE:AddStatic(Template.name)
  
  -- If there is a SpawnFunction hook defined, call it.
  if self.SpawnFunctionHook then
    -- delay calling this for .3 seconds so that it hopefully comes after the BIRTH event of the group.
    self:ScheduleOnce(0.3, self.SpawnFunctionHook, mystatic, unpack(self.SpawnFunctionArguments))
  end

  return mystatic
end
