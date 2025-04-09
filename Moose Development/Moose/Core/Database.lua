--- **Core** - Manages several databases containing templates, mission objects, and mission information.
--
-- ===
--
-- ## Features:
--
--   * During mission startup, scan the mission environment, and create / instantiate intelligently the different objects as defined within the mission.
--   * Manage database of DCS Group templates (as modelled using the mission editor).
--     - Group templates.
--     - Unit templates.
--     - Statics templates.
--   * Manage database of @{Wrapper.Group#GROUP} objects alive in the mission.
--   * Manage database of @{Wrapper.Unit#UNIT} objects alive in the mission.
--   * Manage database of @{Wrapper.Static#STATIC} objects alive in the mission.
--   * Manage database of players.
--   * Manage database of client slots defined using the mission editor.
--   * Manage database of airbases on the map, and from FARPs and ships as defined using the mission editor.
--   * Manage database of countries.
--   * Manage database of zone names.
--   * Manage database of hits to units and statics.
--   * Manage database of destroys of units and statics.
--   * Manage database of @{Core.Zone#ZONE_BASE} objects.
--   * Manage database of @{Wrapper.DynamicCargo#DYNAMICCARGO} objects alive in the mission.
--
-- ===
--
-- ### Author: **FlightControl**
-- ### Contributions: **funkyfranky**
--
-- ===
--
-- @module Core.Database
-- @image Core_Database.JPG

---
-- @type DATABASE
-- @field #string ClassName Name of the class.
-- @field #table Templates Templates: Units, Groups, Statics, ClientsByName, ClientsByID.
-- @field #table CLIENTS Clients.
-- @field #table STORAGES DCS warehouse storages.
-- @field #table STNS Used Link16 octal numbers for F16/15/18/AWACS planes.
-- @field #table SADL Used Link16 octal numbers for A10/C-II planes.
-- @field #table DYNAMICCARGO Dynamic Cargo objects.
-- @extends Core.Base#BASE

--- Contains collections of wrapper objects defined within MOOSE that reflect objects within the simulator.
--
-- Mission designers can use the DATABASE class to refer to:
--
--  * STATICS
--  * UNITS
--  * GROUPS
--  * CLIENTS
--  * AIRBASES
--  * PLAYERSJOINED
--  * PLAYERS
--  * CARGOS
--  * STORAGES (DCS warehouses)
--  * DYNAMICCARGO
--
-- On top, for internal MOOSE administration purposes, the DATABASE administers the Unit and Group TEMPLATES as defined within the Mission Editor.
--
-- The singleton object **_DATABASE** is automatically created by MOOSE, that administers all objects within the mission.
-- Moose refers to **_DATABASE** within the framework extensively, but you can also refer to the _DATABASE object within your missions if required.
--
-- @field #DATABASE
DATABASE = {
  ClassName = "DATABASE",
  Templates = {
    Units = {},
    Groups = {},
    Statics = {},
    ClientsByName = {},
    ClientsByID = {},
  },
  UNITS = {},
  UNITS_Index = {},
  STATICS = {},
  GROUPS = {},
  PLAYERS = {},
  PLAYERSJOINED = {},
  PLAYERUNITS = {},
  CLIENTS = {},
  CARGOS = {},
  AIRBASES = {},
  COUNTRY_ID = {},
  COUNTRY_NAME = {},
  NavPoints = {},
  PLAYERSETTINGS = {},
  ZONENAMES = {},
  HITS = {},
  DESTROYS = {},
  ZONES = {},
  ZONES_GOAL = {},
  WAREHOUSES = {},
  FLIGHTGROUPS = {},
  FLIGHTCONTROLS = {},
  OPSZONES = {},
  PATHLINES = {},
  STORAGES = {},
  STNS={},
  SADL={},
  DYNAMICCARGO={},
}

local _DATABASECoalition =
  {
    [1] = "Red",
    [2] = "Blue",
    [3] = "Neutral",
  }

local _DATABASECategory =
  {
    ["plane"] = Unit.Category.AIRPLANE,
    ["helicopter"] = Unit.Category.HELICOPTER,
    ["vehicle"] = Unit.Category.GROUND_UNIT,
    ["ship"] = Unit.Category.SHIP,
    ["static"] = Unit.Category.STRUCTURE,
  }


--- Creates a new DATABASE object, building a set of units belonging to a coalitions, categories, countries, types or with defined prefix names.
-- @param #DATABASE self
-- @return #DATABASE
-- @usage
-- -- Define a new DATABASE Object. This DBObject will contain a reference to all Group and Unit Templates defined within the ME and the DCSRTE.
-- DBObject = DATABASE:New()
function DATABASE:New()

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() ) -- #DATABASE

  self:SetEventPriority( 1 )

  self:HandleEvent( EVENTS.Birth, self._EventOnBirth )
  -- DCS 2.9 fixed CA event for players -- TODO: reset unit when leaving
  self:HandleEvent( EVENTS.PlayerEnterUnit, self._EventOnPlayerEnterUnit )
  self:HandleEvent( EVENTS.Dead, self._EventOnDeadOrCrash )
  self:HandleEvent( EVENTS.Crash, self._EventOnDeadOrCrash )
  self:HandleEvent( EVENTS.RemoveUnit, self._EventOnDeadOrCrash )
  self:HandleEvent( EVENTS.UnitLost, self._EventOnDeadOrCrash )  -- DCS 2.7.1 for Aerial units no dead event ATM
  self:HandleEvent( EVENTS.Hit, self.AccountHits )
  self:HandleEvent( EVENTS.NewCargo )
  self:HandleEvent( EVENTS.DeleteCargo )
  self:HandleEvent( EVENTS.NewZone )
  self:HandleEvent( EVENTS.DeleteZone )
  --self:HandleEvent( EVENTS.PlayerEnterUnit, self._EventOnPlayerEnterUnit ) -- This is not working anymore!, handling this through the birth event.
  self:HandleEvent( EVENTS.PlayerLeaveUnit, self._EventOnPlayerLeaveUnit )
  -- DCS 2.9.7 Moose own dynamic cargo events
  self:HandleEvent( EVENTS.DynamicCargoRemoved, self._EventOnDynamicCargoRemoved)

  self:_RegisterTemplates()
  self:_RegisterGroupsAndUnits()
  self:_RegisterClients()
  self:_RegisterStatics()
  --self:_RegisterPlayers()
  --self:_RegisterAirbases()

  self.UNITS_Position = 0

  return self
end

--- Finds a Unit based on the Unit Name.
-- @param #DATABASE self
-- @param #string UnitName
-- @return Wrapper.Unit#UNIT The found Unit.
function DATABASE:FindUnit( UnitName )

  local UnitFound = self.UNITS[UnitName]
  return UnitFound
end


--- Adds a Unit based on the Unit Name in the DATABASE.
-- @param #DATABASE self
-- @param #string DCSUnitName Unit name.
-- @param #boolean force
-- @return Wrapper.Unit#UNIT The added unit.
function DATABASE:AddUnit( DCSUnitName, force )
  
  local DCSunitName = DCSUnitName
  
  if type(DCSunitName) == "number" then DCSunitName = string.format("%d",DCSUnitName) end
  
  if not self.UNITS[DCSunitName] or force == true then
    -- Debug info.
    self:T( { "Add UNIT:", DCSunitName } )

    -- Register unit
    self.UNITS[DCSunitName]=UNIT:Register(DCSunitName)
  end

  return self.UNITS[DCSunitName]
end


--- Deletes a Unit from the DATABASE based on the Unit Name.
-- @param #DATABASE self
function DATABASE:DeleteUnit( DCSUnitName )
  self:T("DeleteUnit "..tostring(DCSUnitName))
  self.UNITS[DCSUnitName] = nil
end

--- Adds a Static based on the Static Name in the DATABASE.
-- @param #DATABASE self
-- @param #string DCSStaticName Name of the static.
-- @return Wrapper.Static#STATIC The static object.
function DATABASE:AddStatic( DCSStaticName )

  if not self.STATICS[DCSStaticName] then
    self.STATICS[DCSStaticName] = STATIC:Register( DCSStaticName )
  end

  return self.STATICS[DCSStaticName]
end


--- Deletes a Static from the DATABASE based on the Static Name.
-- @param #DATABASE self
function DATABASE:DeleteStatic( DCSStaticName )
  self.STATICS[DCSStaticName] = nil
end

--- Finds a STATIC based on the Static Name.
-- @param #DATABASE self
-- @param #string StaticName Name of the static object.
-- @return Wrapper.Static#STATIC The found STATIC.
function DATABASE:FindStatic( StaticName )
  local StaticFound = self.STATICS[StaticName]
  return StaticFound
end

--- Add a DynamicCargo to the database.
-- @param #DATABASE self
-- @param #string Name Name of the dynamic cargo.
-- @return Wrapper.DynamicCargo#DYNAMICCARGO The dynamic cargo object.
function DATABASE:AddDynamicCargo( Name )
  if not self.DYNAMICCARGO[Name] then
    self.DYNAMICCARGO[Name] = DYNAMICCARGO:Register(Name)
  end
  return self.DYNAMICCARGO[Name]
end

--- Finds a DYNAMICCARGO based on the Dynamic Cargo Name.
-- @param #DATABASE self
-- @param #string DynamicCargoName
-- @return Wrapper.DynamicCargo#DYNAMICCARGO The found DYNAMICCARGO.
function DATABASE:FindDynamicCargo( DynamicCargoName )
  local StaticFound = self.DYNAMICCARGO[DynamicCargoName]
  return StaticFound
end

--- Deletes a DYNAMICCARGO from the DATABASE based on the Dynamic Cargo Name.
-- @param #DATABASE self
function DATABASE:DeleteDynamicCargo( DynamicCargoName )
  self.DYNAMICCARGO[DynamicCargoName] = nil
  return self
end

--- Adds a Airbase based on the Airbase Name in the DATABASE.
-- @param #DATABASE self
-- @param #string AirbaseName The name of the airbase.
-- @return Wrapper.Airbase#AIRBASE Airbase object.
function DATABASE:AddAirbase( AirbaseName )

  if not self.AIRBASES[AirbaseName] then
    self.AIRBASES[AirbaseName] = AIRBASE:Register( AirbaseName )
  end

  return self.AIRBASES[AirbaseName]
end


--- Deletes a Airbase from the DATABASE based on the Airbase Name.
-- @param #DATABASE self
-- @param #string AirbaseName The name of the airbase
function DATABASE:DeleteAirbase( AirbaseName )

  self.AIRBASES[AirbaseName] = nil
end

--- Finds an AIRBASE based on the AirbaseName.
-- @param #DATABASE self
-- @param #string AirbaseName
-- @return Wrapper.Airbase#AIRBASE The found AIRBASE.
function DATABASE:FindAirbase( AirbaseName )

  local AirbaseFound = self.AIRBASES[AirbaseName]
  return AirbaseFound
end



--- Adds a STORAGE (DCS warehouse wrapper) based on the Airbase Name to the DATABASE.
-- @param #DATABASE self
-- @param #string AirbaseName The name of the airbase.
-- @return Wrapper.Storage#STORAGE Storage object.
function DATABASE:AddStorage( AirbaseName )

  if not self.STORAGES[AirbaseName] then
    self.STORAGES[AirbaseName] = STORAGE:New( AirbaseName )
  end

  return self.STORAGES[AirbaseName]
end


--- Deletes a STORAGE from the DATABASE based on the name of the associated airbase.
-- @param #DATABASE self
-- @param #string AirbaseName The name of the airbase.
function DATABASE:DeleteStorage( AirbaseName )
  self.STORAGES[AirbaseName] = nil
end


--- Finds an STORAGE based on the name of the associated airbase.
-- @param #DATABASE self
-- @param #string AirbaseName Name of the airbase.
-- @return Wrapper.Storage#STORAGE The found STORAGE.
function DATABASE:FindStorage( AirbaseName )
  local storage = self.STORAGES[AirbaseName]
  return storage
end

do -- Zones and Pathlines

  --- Finds a @{Core.Zone} based on the zone name.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  -- @return Core.Zone#ZONE_BASE The found ZONE.
  function DATABASE:FindZone( ZoneName )

    local ZoneFound = self.ZONES[ZoneName]
    return ZoneFound
  end

  --- Adds a @{Core.Zone} based on the zone name in the DATABASE.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  -- @param Core.Zone#ZONE_BASE Zone The zone.
  function DATABASE:AddZone( ZoneName, Zone )

    if not self.ZONES[ZoneName] then
      self.ZONES[ZoneName] = Zone
    end
  end

  --- Deletes a @{Core.Zone} from the DATABASE based on the zone name.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  function DATABASE:DeleteZone( ZoneName )

    self.ZONES[ZoneName] = nil
  end


  --- Adds a @{Core.Pathline} based on its name in the DATABASE.
  -- @param #DATABASE self
  -- @param #string PathlineName The name of the pathline
  -- @param Core.Pathline#PATHLINE Pathline The pathline.
  function DATABASE:AddPathline( PathlineName, Pathline )

    if not self.PATHLINES[PathlineName] then
      self.PATHLINES[PathlineName]=Pathline
    end
  end

  --- Finds a @{Core.Pathline} by its name.
  -- @param #DATABASE self
  -- @param #string PathlineName The name of the Pathline.
  -- @return Core.Pathline#PATHLINE The found PATHLINE.
  function DATABASE:FindPathline( PathlineName )

    local pathline = self.PATHLINES[PathlineName]

    return pathline
  end


  --- Deletes a @{Core.Pathline} from the DATABASE based on its name.
  -- @param #DATABASE self
  -- @param #string PathlineName The name of the PATHLINE.
  function DATABASE:DeletePathline( PathlineName )

    self.PATHLINES[PathlineName]=nil

    return self
  end

  --- Private method that registers new ZONE_BASE derived objects within the DATABASE Object.
  -- @param #DATABASE self
  -- @return #DATABASE self
  function DATABASE:_RegisterZones()

    for ZoneID, ZoneData in pairs(env.mission.triggers.zones) do
      local ZoneName = ZoneData.name

      -- Color
      local color=ZoneData.color or {1, 0, 0, 0.15}

      -- Create new Zone
      local Zone=nil   --Core.Zone#ZONE_BASE

      if ZoneData.type==0 then

        ---
        -- Circular zone
        ---

        self:I(string.format("Register ZONE: %s (Circular)", ZoneName))

        Zone=ZONE:New(ZoneName)

      else

        ---
        -- Quad-point zone
        ---

        self:I(string.format("Register ZONE: %s (Polygon, Quad)", ZoneName))

        Zone=ZONE_POLYGON:NewFromPointsArray(ZoneName, ZoneData.verticies)

        --for i,vec2 in pairs(ZoneData.verticies) do
        --  local coord=COORDINATE:NewFromVec2(vec2)
        --  coord:MarkToAll(string.format("%s Point %d", ZoneName, i))
        --end

      end

      if Zone then

        -- Store color of zone.
        Zone.Color=color

        -- Store zone ID.
        Zone.ZoneID=ZoneData.zoneId

        -- Store zone properties (if any)
        local ZoneProperties = ZoneData.properties or nil
        Zone.Properties = {}
        if ZoneName and ZoneProperties then
          for _,ZoneProp in ipairs(ZoneProperties) do
            if ZoneProp.key then
              Zone.Properties[ZoneProp.key] = ZoneProp.value
            end
          end
        end

        -- Store in DB.
        self.ZONENAMES[ZoneName] = ZoneName

        -- Add zone.
        self:AddZone(ZoneName, Zone)

      end

    end

    -- Polygon zones defined by late activated groups.
    for ZoneGroupName, ZoneGroup in pairs( self.GROUPS ) do
      if ZoneGroupName:match("#ZONE_POLYGON") then

        local ZoneName1 = ZoneGroupName:match("(.*)#ZONE_POLYGON")
        local ZoneName2 = ZoneGroupName:match(".*#ZONE_POLYGON(.*)")
        local ZoneName = ZoneName1 .. ( ZoneName2 or "" )

        -- Debug output
        self:I(string.format("Register ZONE: %s (Polygon)", ZoneName))

        -- Create a new polygon zone.
        local Zone_Polygon = ZONE_POLYGON:New( ZoneName, ZoneGroup )

        -- Set color.
        Zone_Polygon:SetColor({1, 0, 0}, 0.15)

        -- Store name in DB.
        self.ZONENAMES[ZoneName] = ZoneName

        -- Add zone to DB.
        self:AddZone( ZoneName, Zone_Polygon )
      end

    end

    -- Drawings as zones
    if env.mission.drawings and env.mission.drawings.layers then

      -- Loop over layers.
      for layerID, layerData in pairs(env.mission.drawings.layers or {}) do
        
        -- Loop over objects in layers.
        for objectID, objectData in pairs(layerData.objects or {}) do
          
          -- Check for polygon which has at least 4 points (we would need 3 but the origin seems to be there twice)
          if objectData.polygonMode and (objectData.polygonMode=="free") and objectData.points and #objectData.points>=4 then

            ---
            -- Drawing: Polygon free
            ---

            -- Name of the zone.
            local ZoneName=objectData.name or "Unknown free Polygon Drawing"

            -- Reference point. All other points need to be translated by this.
            local vec2={x=objectData.mapX, y=objectData.mapY}

            -- Debug stuff.
            --local vec3={x=objectData.mapX, y=0, z=objectData.mapY}
            --local coord=COORDINATE:NewFromVec2(vec2):MarkToAll("MapX, MapY")
            --trigger.action.markToAll(id,  "mapXY", vec3)

            -- Copy points array.
            local points=UTILS.DeepCopy(objectData.points)

            -- Translate points.
            for i,_point in pairs(points) do
              local point=_point --DCS#Vec2
              points[i]=UTILS.Vec2Add(point, vec2)
            end

            -- Remove last point.
            table.remove(points, #points)

            -- Debug output
            self:I(string.format("Register ZONE: %s (Polygon (free) drawing with %d vertices)", ZoneName, #points))

            -- Create new polygon zone.
            local Zone=ZONE_POLYGON:NewFromPointsArray(ZoneName, points)
            
            --Zone.DrawID = objectID
            
            -- Set color.
            Zone:SetColor({1, 0, 0}, 0.15)
            Zone:SetFillColor({1, 0, 0}, 0.15)
            
            if objectData.colorString then 
              -- eg colorString = 0xff0000ff
              local color = string.gsub(objectData.colorString,"^0x","")
              local r = tonumber(string.sub(color,1,2),16)/255
              local g = tonumber(string.sub(color,3,4),16)/255
              local b = tonumber(string.sub(color,5,6),16)/255
              local a = tonumber(string.sub(color,7,8),16)/255
              Zone:SetColor({r, g, b}, a)
            end
            if objectData.fillColorString then 
              -- eg fillColorString = 0xff00004b
              local color = string.gsub(objectData.colorString,"^0x","")
              local r = tonumber(string.sub(color,1,2),16)/255
              local g = tonumber(string.sub(color,3,4),16)/255
              local b = tonumber(string.sub(color,5,6),16)/255
              local a = tonumber(string.sub(color,7,8),16)/255
              Zone:SetFillColor({r, g, b}, a)
            end
            
            -- Store in DB.
            self.ZONENAMES[ZoneName] = ZoneName

            -- Add zone.
            self:AddZone(ZoneName, Zone)

          -- Check for polygon which has at least 4 points (we would need 3 but the origin seems to be there twice)
          elseif objectData.polygonMode and objectData.polygonMode=="rect" then

            ---
            -- Drawing: Polygon rect
            ---

            -- Name of the zone.
            local ZoneName=objectData.name or "Unknown rect Polygon Drawing"

            -- Reference point (center of the rectangle).
            local vec2={x=objectData.mapX, y=objectData.mapY}

            -- For a rectangular polygon drawing, we have the width (y) and height (x).
            local w=objectData.width
            local h=objectData.height

            -- Create points from center using with and height (width for y and height for x is a bit confusing, but this is how ED implemented it).
            local points={}
            points[1]={x=vec2.x-h/2, y=vec2.y+w/2} --Upper left
            points[2]={x=vec2.x+h/2, y=vec2.y+w/2} --Upper right
            points[3]={x=vec2.x+h/2, y=vec2.y-w/2} --Lower right
            points[4]={x=vec2.x-h/2, y=vec2.y-w/2} --Lower left

            --local coord=COORDINATE:NewFromVec2(vec2):MarkToAll("MapX, MapY")

            -- Debug output
            self:I(string.format("Register ZONE: %s (Polygon (rect) drawing with %d vertices)", ZoneName, #points))

            -- Create new polygon zone.
            local Zone=ZONE_POLYGON:NewFromPointsArray(ZoneName, points)

            -- Set color.
            Zone:SetColor({1, 0, 0}, 0.15)
            
           if objectData.colorString then 
              -- eg colorString = 0xff0000ff
              local color = string.gsub(objectData.colorString,"^0x","")
              local r = tonumber(string.sub(color,1,2),16)/255
              local g = tonumber(string.sub(color,3,4),16)/255
              local b = tonumber(string.sub(color,5,6),16)/255
              local a = tonumber(string.sub(color,7,8),16)/255
              Zone:SetColor({r, g, b}, a)
            end
            if objectData.fillColorString then 
              -- eg fillColorString = 0xff00004b
              local color = string.gsub(objectData.colorString,"^0x","")
              local r = tonumber(string.sub(color,1,2),16)/255
              local g = tonumber(string.sub(color,3,4),16)/255
              local b = tonumber(string.sub(color,5,6),16)/255
              local a = tonumber(string.sub(color,7,8),16)/255
              Zone:SetFillColor({r, g, b}, a)
            end
            
            -- Store in DB.
            self.ZONENAMES[ZoneName] = ZoneName

            -- Add zone.
            self:AddZone(ZoneName, Zone)

          elseif objectData.lineMode and (objectData.lineMode=="segments" or objectData.lineMode=="segment" or objectData.lineMode=="free") and objectData.points and #objectData.points>=2 then

            ---
            -- Drawing: Line (segments, segment or free)
            ---

           -- Name of the zone.
            local Name=objectData.name or "Unknown Line Drawing"

            -- Reference point. All other points need to be translated by this.
            local vec2={x=objectData.mapX, y=objectData.mapY}

            -- Copy points array.
            local points=UTILS.DeepCopy(objectData.points)

            -- Translate points.
            for i,_point in pairs(points) do
              local point=_point --DCS#Vec2
              points[i]=UTILS.Vec2Add(point, vec2)
            end

            -- Debug output
            self:I(string.format("Register PATHLINE: %s (Line drawing with %d points)", Name, #points))

            -- Create new polygon zone.
            local Pathline=PATHLINE:NewFromVec2Array(Name, points)

            -- Set color.
            --Zone:SetColor({1, 0, 0}, 0.15)

            -- Add zone.
            self:AddPathline(Name,Pathline)

          end

        end

      end

    end


  end

end -- zone

do -- Zone_Goal

  --- Finds a @{Core.Zone} based on the zone name.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  -- @return Core.Zone#ZONE_BASE The found ZONE.
  function DATABASE:FindZoneGoal( ZoneName )

    local ZoneFound = self.ZONES_GOAL[ZoneName]
    return ZoneFound
  end

  --- Adds a @{Core.Zone} based on the zone name in the DATABASE.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  -- @param Core.Zone#ZONE_BASE Zone The zone.
  function DATABASE:AddZoneGoal( ZoneName, Zone )

    if not self.ZONES_GOAL[ZoneName] then
      self.ZONES_GOAL[ZoneName] = Zone
    end
  end


  --- Deletes a @{Core.Zone} from the DATABASE based on the zone name.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  function DATABASE:DeleteZoneGoal( ZoneName )

    self.ZONES_GOAL[ZoneName] = nil
  end

end -- Zone_Goal

do -- OpsZone

  --- Finds a @{Ops.OpsZone#OPSZONE} based on the zone name.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  -- @return Ops.OpsZone#OPSZONE The found OPSZONE.
  function DATABASE:FindOpsZone( ZoneName )

    local ZoneFound = self.OPSZONES[ZoneName]

    return ZoneFound
  end

  --- Adds a @{Ops.OpsZone#OPSZONE} based on the zone name in the DATABASE.
  -- @param #DATABASE self
  -- @param Ops.OpsZone#OPSZONE OpsZone The zone.
  function DATABASE:AddOpsZone( OpsZone )

    if OpsZone then

      local ZoneName=OpsZone:GetName()

      if not self.OPSZONES[ZoneName] then
        self.OPSZONES[ZoneName] = OpsZone
      end

    end
  end


  --- Deletes a @{Ops.OpsZone#OPSZONE} from the DATABASE based on the zone name.
  -- @param #DATABASE self
  -- @param #string ZoneName The name of the zone.
  function DATABASE:DeleteOpsZone( ZoneName )
    self.OPSZONES[ZoneName] = nil
  end

end -- OpsZone

do -- cargo

  --- Adds a Cargo based on the Cargo Name in the DATABASE.
  -- @param #DATABASE self
  -- @param #string CargoName The name of the airbase
  function DATABASE:AddCargo( Cargo )

    if not self.CARGOS[Cargo.Name] then
      self.CARGOS[Cargo.Name] = Cargo
    end
  end


  --- Deletes a Cargo from the DATABASE based on the Cargo Name.
  -- @param #DATABASE self
  -- @param #string CargoName The name of the airbase
  function DATABASE:DeleteCargo( CargoName )

    self.CARGOS[CargoName] = nil
  end

  --- Finds an CARGO based on the CargoName.
  -- @param #DATABASE self
  -- @param #string CargoName
  -- @return Cargo.Cargo#CARGO The found CARGO.
  function DATABASE:FindCargo( CargoName )

    local CargoFound = self.CARGOS[CargoName]
    return CargoFound
  end

  --- Checks if the Template name has a #CARGO tag.
  -- If yes, the group is a cargo.
  -- @param #DATABASE self
  -- @param #string TemplateName
  -- @return #boolean
  function DATABASE:IsCargo( TemplateName )

    TemplateName = env.getValueDictByKey( TemplateName )

    local Cargo = TemplateName:match( "#(CARGO)" )

    return Cargo and Cargo == "CARGO"
  end

  --- Private method that registers new Static Templates within the DATABASE Object.
  -- @param #DATABASE self
  -- @return #DATABASE self
  function DATABASE:_RegisterCargos()

    local Groups = UTILS.DeepCopy( self.GROUPS ) -- This is a very important statement. CARGO_GROUP:New creates a new _DATABASE.GROUP entry, which will confuse the loop. I searched 4 hours on this to find the bug!

    for CargoGroupName, CargoGroup in pairs( Groups ) do
      if self:IsCargo( CargoGroupName ) then
        local CargoInfo = CargoGroupName:match("#CARGO(.*)")
        local CargoParam = CargoInfo and CargoInfo:match( "%((.*)%)")
        local CargoName1 = CargoGroupName:match("(.*)#CARGO%(.*%)")
        local CargoName2 = CargoGroupName:match(".*#CARGO%(.*%)(.*)")
        local CargoName = CargoName1 .. ( CargoName2 or "" )
        local Type = CargoParam and CargoParam:match( "T=([%a%d ]+),?")
        local Name = CargoParam and CargoParam:match( "N=([%a%d]+),?") or CargoName
        local LoadRadius = CargoParam and tonumber( CargoParam:match( "RR=([%a%d]+),?") )
        local NearRadius = CargoParam and tonumber( CargoParam:match( "NR=([%a%d]+),?") )

        self:I({"Register CargoGroup:",Type=Type,Name=Name,LoadRadius=LoadRadius,NearRadius=NearRadius})
        CARGO_GROUP:New( CargoGroup, Type, Name, LoadRadius, NearRadius )
      end
    end

    for CargoStaticName, CargoStatic in pairs( self.STATICS ) do
      if self:IsCargo( CargoStaticName ) then
        local CargoInfo = CargoStaticName:match("#CARGO(.*)")
        local CargoParam = CargoInfo and CargoInfo:match( "%((.*)%)")
        local CargoName = CargoStaticName:match("(.*)#CARGO")
        local Type = CargoParam and CargoParam:match( "T=([%a%d ]+),?")
        local Category = CargoParam and CargoParam:match( "C=([%a%d ]+),?")
        local Name = CargoParam and CargoParam:match( "N=([%a%d]+),?") or CargoName
        local LoadRadius = CargoParam and tonumber( CargoParam:match( "RR=([%a%d]+),?") )
        local NearRadius = CargoParam and tonumber( CargoParam:match( "NR=([%a%d]+),?") )

        if Category == "SLING" then
          self:I({"Register CargoSlingload:",Type=Type,Name=Name,LoadRadius=LoadRadius,NearRadius=NearRadius})
          CARGO_SLINGLOAD:New( CargoStatic, Type, Name, LoadRadius, NearRadius )
        else
          if Category == "CRATE" then
            self:I({"Register CargoCrate:",Type=Type,Name=Name,LoadRadius=LoadRadius,NearRadius=NearRadius})
            CARGO_CRATE:New( CargoStatic, Type, Name, LoadRadius, NearRadius )
          end
        end
      end
    end

  end

end -- cargo

--- Finds a CLIENT based on the ClientName.
-- @param #DATABASE self
-- @param #string ClientName - Note this is the UNIT name of the client!
-- @return Wrapper.Client#CLIENT The found CLIENT.
function DATABASE:FindClient( ClientName )

  local ClientFound = self.CLIENTS[ClientName]
  return ClientFound
end


--- Adds a CLIENT based on the ClientName in the DATABASE.
-- @param #DATABASE self
-- @param #string ClientName Name of the Client unit.
-- @param #boolean Force (optional) Force registration of client.
-- @return Wrapper.Client#CLIENT The client object.
function DATABASE:AddClient( ClientName, Force )
  
  local DCSUnitName = ClientName
  
  if type(DCSUnitName) == "number" then DCSUnitName = string.format("%d",ClientName) end
  
  if not self.CLIENTS[DCSUnitName] or Force == true then
    self.CLIENTS[DCSUnitName] = CLIENT:Register( DCSUnitName )
  end

  return self.CLIENTS[DCSUnitName]
end


--- Finds a GROUP based on the GroupName.
-- @param #DATABASE self
-- @param #string GroupName
-- @return Wrapper.Group#GROUP The found GROUP.
function DATABASE:FindGroup( GroupName )

  local GroupFound = self.GROUPS[GroupName]
  
  if GroupFound == nil and GroupName ~= nil and self.Templates.Groups[GroupName] == nil then
    -- see if the group exists in the API, maybe a dynamic slot
    self:_RegisterDynamicGroup(GroupName)
    return self.GROUPS[GroupName]
  end
  
  return GroupFound
end


--- Adds a GROUP based on the GroupName in the DATABASE.
-- @param #DATABASE self
-- @param #string GroupName
-- @param #boolean force
-- @return Wrapper.Group#GROUP The Group
function DATABASE:AddGroup( GroupName, force )

  if not self.GROUPS[GroupName] or force == true then
    self:T( { "Add GROUP:", GroupName } )
    self.GROUPS[GroupName] = GROUP:Register( GroupName )
  end

  return self.GROUPS[GroupName]
end

--- Adds a player based on the Player Name in the DATABASE.
-- @param #DATABASE self
function DATABASE:AddPlayer( UnitName, PlayerName )
  
  if type(UnitName) == "number" then UnitName = string.format("%d",UnitName) end
  
  if PlayerName then
    self:I( { "Add player for unit:", UnitName, PlayerName } )
    self.PLAYERS[PlayerName] = UnitName
    self.PLAYERUNITS[PlayerName] = self:FindUnit( UnitName )
    self.PLAYERSJOINED[PlayerName] = PlayerName
  end
  
end

--- Get a PlayerName by UnitName from PLAYERS in DATABASE.
-- @param #DATABASE self
-- @return #string PlayerName
-- @return Wrapper.Unit#UNIT PlayerUnit
function DATABASE:_FindPlayerNameByUnitName(UnitName)
  if UnitName then
    for playername,unitname in pairs(self.PLAYERS) do
      if unitname == UnitName and self.PLAYERUNITS[playername] and self.PLAYERUNITS[playername]:IsAlive() then
        return playername, self.PLAYERUNITS[playername]
      end
    end
  end
  return nil
end

--- Deletes a player from the DATABASE based on the Player Name.
-- @param #DATABASE self
function DATABASE:DeletePlayer( UnitName, PlayerName )

  if PlayerName then
    self:T( { "Clean player:", PlayerName } )
    self.PLAYERS[PlayerName] = nil
    self.PLAYERUNITS[PlayerName] = nil
  end
end

--- Get the player table from the DATABASE.
-- The player table contains all unit names with the key the name of the player (PlayerName).
-- @param #DATABASE self
-- @usage
--   local Players = _DATABASE:GetPlayers()
--   for PlayerName, UnitName in pairs( Players ) do
--     ..
--   end
function DATABASE:GetPlayers()
  return self.PLAYERS
end


--- Get the player table from the DATABASE, which contains all UNIT objects.
-- The player table contains all UNIT objects of the player with the key the name of the player (PlayerName).
-- @param #DATABASE self
-- @usage
--   local PlayerUnits = _DATABASE:GetPlayerUnits()
--   for PlayerName, PlayerUnit in pairs( PlayerUnits ) do
--     ..
--   end
function DATABASE:GetPlayerUnits()
  return self.PLAYERUNITS
end


--- Get the player table from the DATABASE which have joined in the mission historically.
-- The player table contains all UNIT objects with the key the name of the player (PlayerName).
-- @param #DATABASE self
-- @usage
--   local PlayersJoined = _DATABASE:GetPlayersJoined()
--   for PlayerName, PlayerUnit in pairs( PlayersJoined ) do
--     ..
--   end
function DATABASE:GetPlayersJoined()
  return self.PLAYERSJOINED
end


--- Instantiate new Groups within the DCSRTE.
-- This method expects EXACTLY the same structure as a structure within the ME, and needs 2 additional fields defined:
-- SpawnCountryID, SpawnCategoryID
-- This method is used by the SPAWN class.
-- @param #DATABASE self
-- @param #table SpawnTemplate Template of the group to spawn.
-- @return Wrapper.Group#GROUP Spawned group.
function DATABASE:Spawn( SpawnTemplate )
  self:F( SpawnTemplate.name )

  self:T( { SpawnTemplate.SpawnCountryID, SpawnTemplate.SpawnCategoryID } )

  -- Copy the spawn variables of the template in temporary storage, nullify, and restore the spawn variables.
  local SpawnCoalitionID = SpawnTemplate.CoalitionID
  local SpawnCountryID = SpawnTemplate.CountryID
  local SpawnCategoryID = SpawnTemplate.CategoryID

  -- Nullify
  SpawnTemplate.CoalitionID = nil
  SpawnTemplate.CountryID = nil
  SpawnTemplate.CategoryID = nil

  self:_RegisterGroupTemplate( SpawnTemplate, SpawnCoalitionID, SpawnCategoryID, SpawnCountryID, SpawnTemplate.name  )

  self:T3( SpawnTemplate )
  coalition.addGroup( SpawnCountryID, SpawnCategoryID, SpawnTemplate )

  -- Restore
  SpawnTemplate.CoalitionID = SpawnCoalitionID
  SpawnTemplate.CountryID = SpawnCountryID
  SpawnTemplate.CategoryID = SpawnCategoryID

  -- Ensure that for the spawned group and its units, there are GROUP and UNIT objects created in the DATABASE.
  local SpawnGroup = self:AddGroup( SpawnTemplate.name )
  for UnitID, UnitData in pairs( SpawnTemplate.units ) do
    self:AddUnit( UnitData.name )
  end

  return SpawnGroup
end

--- Set a status to a Group within the Database, this to check crossing events for example.
-- @param #DATABASE self
-- @param #string GroupName Group name.
-- @param #string Status Status.
function DATABASE:SetStatusGroup( GroupName, Status )
  self:F2( Status )

  self.Templates.Groups[GroupName].Status = Status
end

--- Get a status to a Group within the Database, this to check crossing events for example.
-- @param #DATABASE self
-- @param #string GroupName Group name.
-- @return #string Status or an empty string "".
function DATABASE:GetStatusGroup( GroupName )
  self:F2( GroupName )

  if self.Templates.Groups[GroupName] then
    return self.Templates.Groups[GroupName].Status
  else
    return ""
  end
end

--- Private method that registers new Group Templates within the DATABASE Object.
-- @param #DATABASE self
-- @param #table GroupTemplate
-- @param DCS#coalition.side CoalitionSide The coalition.side of the object.
-- @param DCS#Object.Category CategoryID The Object.category of the object.
-- @param DCS#country.id CountryID the country ID of the object.
-- @param #string GroupName (Optional) The name of the group. Default is `GroupTemplate.name`.
-- @return #DATABASE self
function DATABASE:_RegisterGroupTemplate( GroupTemplate, CoalitionSide, CategoryID, CountryID, GroupName )

  local GroupTemplateName = GroupName or env.getValueDictByKey( GroupTemplate.name )

  if not self.Templates.Groups[GroupTemplateName] then
    self.Templates.Groups[GroupTemplateName] = {}
    self.Templates.Groups[GroupTemplateName].Status = nil
  end

  -- Delete the spans from the route, it is not needed and takes memory.
  if GroupTemplate.route and GroupTemplate.route.spans then
    GroupTemplate.route.spans = nil
  end

  GroupTemplate.CategoryID = CategoryID
  GroupTemplate.CoalitionID = CoalitionSide
  GroupTemplate.CountryID = CountryID

  self.Templates.Groups[GroupTemplateName].GroupName = GroupTemplateName
  self.Templates.Groups[GroupTemplateName].Template = GroupTemplate
  self.Templates.Groups[GroupTemplateName].groupId = GroupTemplate.groupId
  self.Templates.Groups[GroupTemplateName].UnitCount = #GroupTemplate.units
  self.Templates.Groups[GroupTemplateName].Units = GroupTemplate.units
  self.Templates.Groups[GroupTemplateName].CategoryID = CategoryID
  self.Templates.Groups[GroupTemplateName].CoalitionID = CoalitionSide
  self.Templates.Groups[GroupTemplateName].CountryID = CountryID
  
  local UnitNames = {}

  for unit_num, UnitTemplate in pairs( GroupTemplate.units ) do

    UnitTemplate.name = env.getValueDictByKey(UnitTemplate.name)

    self.Templates.Units[UnitTemplate.name] = {}
    self.Templates.Units[UnitTemplate.name].UnitName = UnitTemplate.name
    self.Templates.Units[UnitTemplate.name].Template = UnitTemplate
    self.Templates.Units[UnitTemplate.name].GroupName = GroupTemplateName
    self.Templates.Units[UnitTemplate.name].GroupTemplate = GroupTemplate
    self.Templates.Units[UnitTemplate.name].GroupId = GroupTemplate.groupId
    self.Templates.Units[UnitTemplate.name].CategoryID = CategoryID
    self.Templates.Units[UnitTemplate.name].CoalitionID = CoalitionSide
    self.Templates.Units[UnitTemplate.name].CountryID = CountryID

    if UnitTemplate.skill and (UnitTemplate.skill == "Client" or UnitTemplate.skill == "Player") then
      self.Templates.ClientsByName[UnitTemplate.name] = UnitTemplate
      self.Templates.ClientsByName[UnitTemplate.name].CategoryID = CategoryID
      self.Templates.ClientsByName[UnitTemplate.name].CoalitionID = CoalitionSide
      self.Templates.ClientsByName[UnitTemplate.name].CountryID = CountryID
      self.Templates.ClientsByID[UnitTemplate.unitId] = UnitTemplate
    end
    
    if UnitTemplate.AddPropAircraft then
      if UnitTemplate.AddPropAircraft.STN_L16 then
        local stn = UTILS.OctalToDecimal(UnitTemplate.AddPropAircraft.STN_L16)
        if stn == nil or stn < 1 then
          self:E("WARNING: Invalid STN "..tostring(UnitTemplate.AddPropAircraft.STN_L16).." for ".. UnitTemplate.name)
        else
          self.STNS[stn] = UnitTemplate.name
          self:I("Register STN "..tostring(UnitTemplate.AddPropAircraft.STN_L16).." for ".. UnitTemplate.name)
        end
      end
      if UnitTemplate.AddPropAircraft.SADL_TN then
        local sadl = UTILS.OctalToDecimal(UnitTemplate.AddPropAircraft.SADL_TN)
        if sadl == nil or sadl < 1 then
          self:E("WARNING: Invalid SADL "..tostring(UnitTemplate.AddPropAircraft.SADL_TN).." for ".. UnitTemplate.name)
        else
          self.SADL[sadl] = UnitTemplate.name
          self:I("Register SADL "..tostring(UnitTemplate.AddPropAircraft.SADL_TN).." for ".. UnitTemplate.name)
        end
      end  
    end

    UnitNames[#UnitNames+1] = self.Templates.Units[UnitTemplate.name].UnitName
  end
    
  -- Debug info.
  self:T( { Group     = self.Templates.Groups[GroupTemplateName].GroupName,
            Coalition = self.Templates.Groups[GroupTemplateName].CoalitionID,
            Category  = self.Templates.Groups[GroupTemplateName].CategoryID,
            Country   = self.Templates.Groups[GroupTemplateName].CountryID,
            Units     = UnitNames
          }
        )
end

--- Get next (consecutive) free STN as octal number.
-- @param #DATABASE self
-- @param #number octal Starting octal.
-- @param #string unitname Name of the associated unit.
-- @return #number Octal
function DATABASE:GetNextSTN(octal,unitname)
  local first = UTILS.OctalToDecimal(octal) or 0
  if self.STNS[first] == unitname then return octal end
  local nextoctal = 77777
  local found = false
  if 32767-first < 10 then
    first = 0
  end
  for i=first+1,32767 do
    if self.STNS[i] == nil then
      found = true
      nextoctal = UTILS.DecimalToOctal(i)
      self.STNS[i] = unitname
      self:T("Register STN "..tostring(nextoctal).." for ".. unitname)
      break
    end
  end
  if not found then
    self:E(string.format("WARNING: No next free STN past %05d found!",octal))
    -- cleanup
    local NewSTNS = {}
    for _id,_name in pairs(self.STNS) do
      if self.UNITS[_name] ~= nil then
        NewSTNS[_id] = _name
      end
    end
    self.STNS = nil
    self.STNS = NewSTNS
  end
  return nextoctal 
end

--- Get next (consecutive) free SADL as octal number.
-- @param #DATABASE self
-- @param #number octal Starting octal.
-- @param #string unitname Name of the associated unit.
-- @return #number Octal
function DATABASE:GetNextSADL(octal,unitname)
  local first = UTILS.OctalToDecimal(octal) or 0
  if self.SADL[first] == unitname then return octal end
  local nextoctal = 7777
  local found = false
  if 4095-first < 10 then
    first = 0
  end
  for i=first+1,4095 do
    if self.STNS[i] == nil then
      found = true
      nextoctal = UTILS.DecimalToOctal(i)
      self.SADL[i] = unitname
      self:T("Register SADL "..tostring(nextoctal).." for ".. unitname)
      break
    end
  end
  if not found then
    self:E(string.format("WARNING: No next free SADL past %04d found!",octal))
    -- cleanup
    local NewSTNS = {}
    for _id,_name in pairs(self.SADL) do
      if self.UNITS[_name] ~= nil then
        NewSTNS[_id] = _name
      end
    end
    self.SADL = nil
    self.SADL = NewSTNS
  end
  return nextoctal 
end

--- Get group template.
-- @param #DATABASE self
-- @param #string GroupName Group name.
-- @return #table Group template table.
function DATABASE:GetGroupTemplate( GroupName )
  local GroupTemplate=nil
  if self.Templates.Groups[GroupName] then
    GroupTemplate = self.Templates.Groups[GroupName].Template
    GroupTemplate.SpawnCoalitionID = self.Templates.Groups[GroupName].CoalitionID
    GroupTemplate.SpawnCategoryID = self.Templates.Groups[GroupName].CategoryID
    GroupTemplate.SpawnCountryID = self.Templates.Groups[GroupName].CountryID
  end
  return GroupTemplate
end

--- Private method that registers new Static Templates within the DATABASE Object.
-- @param #DATABASE self
-- @param #table StaticTemplate Template table.
-- @param #number CoalitionID Coalition ID.
-- @param #number CategoryID Category ID.
-- @param #number CountryID Country ID.
-- @return #DATABASE self
function DATABASE:_RegisterStaticTemplate( StaticTemplate, CoalitionID, CategoryID, CountryID )

  local StaticTemplate = UTILS.DeepCopy( StaticTemplate )

  local StaticTemplateGroupName = env.getValueDictByKey(StaticTemplate.name)

  local StaticTemplateName=StaticTemplate.units[1].name

  self.Templates.Statics[StaticTemplateName] = self.Templates.Statics[StaticTemplateName] or {}

  StaticTemplate.CategoryID = CategoryID
  StaticTemplate.CoalitionID = CoalitionID
  StaticTemplate.CountryID = CountryID

  self.Templates.Statics[StaticTemplateName].StaticName = StaticTemplateGroupName
  self.Templates.Statics[StaticTemplateName].GroupTemplate = StaticTemplate
  self.Templates.Statics[StaticTemplateName].UnitTemplate = StaticTemplate.units[1]
  self.Templates.Statics[StaticTemplateName].CategoryID = CategoryID
  self.Templates.Statics[StaticTemplateName].CoalitionID = CoalitionID
  self.Templates.Statics[StaticTemplateName].CountryID = CountryID

  -- Debug info.
  self:T( { Static = self.Templates.Statics[StaticTemplateName].StaticName,
            Coalition = self.Templates.Statics[StaticTemplateName].CoalitionID,
            Category = self.Templates.Statics[StaticTemplateName].CategoryID,
            Country = self.Templates.Statics[StaticTemplateName].CountryID
          }
        )

  self:AddStatic( StaticTemplateName )

  return self
end

--- Get a generic static cargo group template from scratch for dynamic cargo spawns register. Does not register the template!
-- @param #DATABASE self
-- @param #string Name Name of the static.
-- @param #string Typename Typename of the static. Defaults to "container_cargo".
-- @param #number Mass Mass of the static. Defaults to 0.
-- @param #number Coalition Coalition of the static. Defaults to coalition.side.BLUE.
-- @param #number Country Country of the static. Defaults to country.id.GERMANY.
-- @return #table Static template table.
function DATABASE:_GetGenericStaticCargoGroupTemplate(Name,Typename,Mass,Coalition,Country)
  local StaticTemplate = {}
  StaticTemplate.name = Name or "None"
  StaticTemplate.units = { [1] = { 
    name = Name, 
    resourcePayload = {
      ["weapons"] = {},
      ["aircrafts"] = {},
      ["gasoline"] = 0,
      ["diesel"] = 0,
      ["methanol_mixture"] = 0,
      ["jet_fuel"] = 0,   
    },
    ["mass"] = Mass or 0,
    ["category"] = "Cargos",
    ["canCargo"] = true,
    ["type"] = Typename or "container_cargo",
    ["rate"] = 100,
    ["y"] = 0,
    ["x"] = 0,
    ["heading"] = 0,
  }}
  StaticTemplate.CategoryID = "static"
  StaticTemplate.CoalitionID = Coalition or coalition.side.BLUE
  StaticTemplate.CountryID = Country or country.id.GERMANY
  --UTILS.PrintTableToLog(StaticTemplate)
  return StaticTemplate
end

--- Get static group template.
-- @param #DATABASE self
-- @param #string StaticName Name of the static.
-- @return #table Static template table.
function DATABASE:GetStaticGroupTemplate( StaticName )
  if self.Templates.Statics[StaticName] then
    local StaticTemplate = self.Templates.Statics[StaticName].GroupTemplate
    return StaticTemplate, self.Templates.Statics[StaticName].CoalitionID, self.Templates.Statics[StaticName].CategoryID, self.Templates.Statics[StaticName].CountryID
  else
    self:E("ERROR: Static group template does NOT exist for static "..tostring(StaticName))
    return nil
  end
end

--- Get static unit template.
-- @param #DATABASE self
-- @param #string StaticName Name of the static.
-- @return #table Static template table.
function DATABASE:GetStaticUnitTemplate( StaticName )
  if self.Templates.Statics[StaticName] then
    local UnitTemplate = self.Templates.Statics[StaticName].UnitTemplate
    return UnitTemplate, self.Templates.Statics[StaticName].CoalitionID, self.Templates.Statics[StaticName].CategoryID, self.Templates.Statics[StaticName].CountryID
  else
    self:E("ERROR: Static unit template does NOT exist for static "..tostring(StaticName))
    return nil
  end
end

--- Get group name from unit name.
-- @param #DATABASE self
-- @param #string UnitName Name of the unit.
-- @return #string Group name.
function DATABASE:GetGroupNameFromUnitName( UnitName )
  if self.Templates.Units[UnitName] then
    return self.Templates.Units[UnitName].GroupName
  else
    self:E("ERROR: Unit template does not exist for unit "..tostring(UnitName))
    return nil
  end
end

--- Get group template from unit name.
-- @param #DATABASE self
-- @param #string UnitName Name of the unit.
-- @return #table Group template.
function DATABASE:GetGroupTemplateFromUnitName( UnitName )
  if self.Templates.Units[UnitName] then
    return self.Templates.Units[UnitName].GroupTemplate
  else
    self:E("ERROR: Unit template does not exist for unit "..tostring(UnitName))
    return nil
  end
end

--- Get group template from unit name.
-- @param #DATABASE self
-- @param #string UnitName Name of the unit.
-- @return #table Group template.
function DATABASE:GetUnitTemplateFromUnitName( UnitName )
  if self.Templates.Units[UnitName] then
    return self.Templates.Units[UnitName]
  else
    self:E("ERROR: Unit template does not exist for unit "..tostring(UnitName))
    return nil
  end
end


--- Get coalition ID from client name.
-- @param #DATABASE self
-- @param #string ClientName Name of the Client.
-- @return #number Coalition ID.
function DATABASE:GetCoalitionFromClientTemplate( ClientName )
  if self.Templates.ClientsByName[ClientName] then  
    return self.Templates.ClientsByName[ClientName].CoalitionID
  end
  self:E("WARNING: Template does not exist for client "..tostring(ClientName))
  return nil
end

--- Get category ID from client name.
-- @param #DATABASE self
-- @param #string ClientName Name of the Client.
-- @return #number Category ID.
function DATABASE:GetCategoryFromClientTemplate( ClientName )
  if self.Templates.ClientsByName[ClientName] then  
    return self.Templates.ClientsByName[ClientName].CategoryID
  end
  self:E("WARNING: Template does not exist for client "..tostring(ClientName))
  return nil
end

--- Get country ID from client name.
-- @param #DATABASE self
-- @param #string ClientName Name of the Client.
-- @return #number Country ID.
function DATABASE:GetCountryFromClientTemplate( ClientName )
  if self.Templates.ClientsByName[ClientName] then  
    return self.Templates.ClientsByName[ClientName].CountryID
  end
  self:E("WARNING: Template does not exist for client "..tostring(ClientName))
  return nil  
end

--- Airbase

--- Get coalition ID from airbase name.
-- @param #DATABASE self
-- @param #string AirbaseName Name of the airbase.
-- @return #number Coalition ID.
function DATABASE:GetCoalitionFromAirbase( AirbaseName )
  return self.AIRBASES[AirbaseName]:GetCoalition()
end

--- Get category from airbase name.
-- @param #DATABASE self
-- @param #string AirbaseName Name of the airbase.
-- @return #number Category.
function DATABASE:GetCategoryFromAirbase( AirbaseName )
  return self.AIRBASES[AirbaseName]:GetAirbaseCategory()
end



--- Private method that registers all alive players in the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterPlayers()

  local CoalitionsData = { AlivePlayersRed = coalition.getPlayers( coalition.side.RED ), AlivePlayersBlue = coalition.getPlayers( coalition.side.BLUE ), AlivePlayersNeutral = coalition.getPlayers( coalition.side.NEUTRAL ) }
  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for UnitId, UnitData in pairs( CoalitionData ) do
      self:T3( { "UnitData:", UnitData } )
      if UnitData and UnitData:isExist() then
        local UnitName = UnitData:getName()
        local PlayerName = UnitData:getPlayerName()
        if not self.PLAYERS[PlayerName] then
          self:I( { "Add player for unit:", UnitName, PlayerName } )
          self:AddPlayer( UnitName, PlayerName )
        end
      end
    end
  end

  return self
end

--- Private method that registers a single dynamic slot Group and Units within in the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterDynamicGroup(Groupname)
  local DCSGroup = Group.getByName(Groupname)
  if DCSGroup and DCSGroup:isExist() then
  
    -- Group name.
    local DCSGroupName = DCSGroup:getName()
  
    -- Add group.
    self:I(string.format("Register Group: %s", tostring(DCSGroupName)))
    self:AddGroup( DCSGroupName, true )
  
    -- Loop over units in group.
    for DCSUnitId, DCSUnit in pairs( DCSGroup:getUnits() ) do
  
      -- Get unit name.
      local DCSUnitName = DCSUnit:getName()
  
      -- Add unit.
      self:I(string.format("Register Unit: %s", tostring(DCSUnitName)))
      self:AddUnit( tostring(DCSUnitName), true )
  
    end
  else
    self:E({"Group does not exist: ", DCSGroup})
  end
  return self
end

--- Private method that registers all Groups and Units within in the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterGroupsAndUnits()

  local CoalitionsData = { GroupsRed = coalition.getGroups( coalition.side.RED ), GroupsBlue = coalition.getGroups( coalition.side.BLUE ),  GroupsNeutral = coalition.getGroups( coalition.side.NEUTRAL ) }

  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do

    for DCSGroupId, DCSGroup in pairs( CoalitionData ) do

      if DCSGroup:isExist() then

        -- Group name.
        local DCSGroupName = DCSGroup:getName()

        -- Add group.
        self:I(string.format("Register Group: %s", tostring(DCSGroupName)))
        self:AddGroup( DCSGroupName )

        -- Loop over units in group.
        for DCSUnitId, DCSUnit in pairs( DCSGroup:getUnits() ) do

          -- Get unit name.
          local DCSUnitName = DCSUnit:getName()

          -- Add unit.
          self:I(string.format("Register Unit: %s", tostring(DCSUnitName)))
          self:AddUnit( DCSUnitName )

        end
      else
        self:E({"Group does not exist: ", DCSGroup})
      end

    end
  end

  return self
end

--- Private method that registers all Units of skill Client or Player within in the mission.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterClients()

  for ClientName, ClientTemplate in pairs( self.Templates.ClientsByName ) do
    self:I(string.format("Register Client: %s", tostring(ClientName)))
    local client=self:AddClient( ClientName )
    client.SpawnCoord=COORDINATE:New(ClientTemplate.x, ClientTemplate.alt, ClientTemplate.y)
  end

  return self
end

--- Private method that registeres all static objects.
-- @param #DATABASE self
function DATABASE:_RegisterStatics()

  local CoalitionsData={GroupsRed=coalition.getStaticObjects(coalition.side.RED), GroupsBlue=coalition.getStaticObjects(coalition.side.BLUE), GroupsNeutral=coalition.getStaticObjects(coalition.side.NEUTRAL)}

  for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
    for DCSStaticId, DCSStatic in pairs( CoalitionData ) do

      if DCSStatic:isExist() then
        local DCSStaticName = DCSStatic:getName()

        self:I(string.format("Register Static: %s", tostring(DCSStaticName)))
        self:AddStatic( DCSStaticName )
      else
        self:E( { "Static does not exist: ",  DCSStatic } )
      end
    end
  end

  return self
end

--- Register all world airbases.
-- @param #DATABASE self
-- @return #DATABASE self
function DATABASE:_RegisterAirbases()

 for DCSAirbaseId, DCSAirbase in pairs(world.getAirbases()) do

    self:_RegisterAirbase(DCSAirbase)

  end

  return self
end

--- Register a DCS airbase.
-- @param #DATABASE self
-- @param DCS#Airbase airbase Airbase.
-- @return #DATABASE self
function DATABASE:_RegisterAirbase(airbase)
  
  local IsSyria = UTILS.GetDCSMap() == "Syria" and true or false
  local countHSyria = 0
  
  if airbase then

    -- Get the airbase name.
    local DCSAirbaseName = airbase:getName()
    
    -- DCS 2.9.8.1107 added 143 helipads all named H with the same object ID ..
    if IsSyria and DCSAirbaseName == "H" and countHSyria > 0 then
      --[[
      local p = airbase:getPosition().p
      local mgrs = COORDINATE:New(p.x,p.z,p.y):ToStringMGRS()
      self:I("Airbase on Syria map named H @ "..mgrs)
      countHSyria = countHSyria + 1
      if countHSyria > 1 then return self end
      --]]
      return self
    elseif IsSyria and DCSAirbaseName == "H" and countHSyria == 0 then
      countHSyria = countHSyria + 1
    end
    
    -- This gave the incorrect value to be inserted into the airdromeID for DCS 2.5.6. Is fixed now.
    local airbaseID=airbase:getID()

    -- Add and register airbase.
    local airbase=self:AddAirbase( DCSAirbaseName )

    -- Unique ID.
    local airbaseUID=airbase:GetID(true)
    
    local typename = airbase:GetTypeName()
    
    local category = airbase.category
    
    if category == Airbase.Category.SHIP and typename == "FARP_SINGLE_01" then
      category = Airbase.Category.HELIPAD
    end
    
    -- Debug output.
    local text=string.format("Register %s: %s (UID=%d), Runways=%d, Parking=%d [", AIRBASE.CategoryName[category], tostring(DCSAirbaseName), airbaseUID, #airbase.runways, airbase.NparkingTotal)
    for _,terminalType in pairs(AIRBASE.TerminalType) do
      if airbase.NparkingTerminal and airbase.NparkingTerminal[terminalType] then
        text=text..string.format("%d=%d ", terminalType, airbase.NparkingTerminal[terminalType])
      end
    end
    text=text.."]"
    self:I(text)

  end

  return self
end


--- Events

--- Handles the OnBirth event for the alive units set.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnBirth( Event )
  self:T( { Event } )

  if Event.IniDCSUnit then

    if Event.IniObjectCategory == Object.Category.STATIC then

      -- Add static object to DB.
      self:AddStatic( Event.IniDCSUnitName )
    
    elseif Event.IniObjectCategory == Object.Category.CARGO and string.match(Event.IniUnitName,".+|%d%d:%d%d|PKG%d+") then

      -- Add dynamic cargo object to DB
      
      local cargo = self:AddDynamicCargo(Event.IniDCSUnitName)
      
      self:I(string.format("Adding dynamic cargo %s", tostring(Event.IniDCSUnitName)))
      
      self:CreateEventNewDynamicCargo( cargo )
        
    else

      if Event.IniObjectCategory == Object.Category.UNIT then

        -- Add unit and group to DB.
        self:AddUnit( Event.IniDCSUnitName )
        self:AddGroup( Event.IniDCSGroupName )

        -- A unit can also be an airbase (e.g. ships).
        local DCSAirbase = Airbase.getByName(Event.IniDCSUnitName)
        if DCSAirbase then
          -- Add airbase if it was spawned later in the mission.
          self:I(string.format("Adding airbase %s", tostring(Event.IniDCSUnitName)))
          self:AddAirbase(Event.IniDCSUnitName)
        end

      end
    end

    if Event.IniObjectCategory == Object.Category.UNIT then
      
      Event.IniGroup = self:FindGroup( Event.IniDCSGroupName )
      Event.IniUnit = self:FindUnit( Event.IniDCSUnitName )

      -- Client
      local client=self.CLIENTS[Event.IniDCSUnitName] --Wrapper.Client#CLIENT

      if client then
        -- TODO: create event ClientAlive
      end

      -- Get player name.
      local PlayerName = Event.IniUnit:GetPlayerName()

      if PlayerName then

        -- Debug info.
        self:I(string.format("Player '%s' joined unit '%s' of group '%s'", tostring(PlayerName), tostring(Event.IniDCSUnitName), tostring(Event.IniDCSGroupName)))
              
        -- Add client in case it does not exist already.
        if client == nil or (client and client:CountPlayers() == 0) then
          client=self:AddClient(Event.IniDCSUnitName, true)
        end

        -- Add player.
        client:AddPlayer(PlayerName)

        -- Add player.
        if not self.PLAYERS[PlayerName] then
          self:AddPlayer( Event.IniUnitName, PlayerName )
        end
        
        local function SetPlayerSettings(self,PlayerName,IniUnit)
          -- Player settings.
          local Settings = SETTINGS:Set( PlayerName )
          --Settings:SetPlayerMenu(Event.IniUnit)
          Settings:SetPlayerMenu(IniUnit)
          -- Create an event.
          self:CreateEventPlayerEnterAircraft(IniUnit)
          --self:CreateEventPlayerEnterAircraft(Event.IniUnit)
        end
        
        self:ScheduleOnce(1,SetPlayerSettings,self,PlayerName,Event.IniUnit)
        
      end

    end

  end

end


--- Handles the OnDead or OnCrash event for alive units set.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnDeadOrCrash( Event )
  if Event.IniDCSUnit then

    local name=Event.IniDCSUnitName

    if Event.IniObjectCategory == 3 then

      ---
      -- STATICS 
      ---

      if self.STATICS[Event.IniDCSUnitName] then
        self:DeleteStatic( Event.IniDCSUnitName )
      end

      ---
      -- Maybe a UNIT?
      ---
 
      -- Delete unit.
      if self.UNITS[Event.IniDCSUnitName] then
        self:T("STATIC Event for UNIT "..tostring(Event.IniDCSUnitName))
        local DCSUnit = _DATABASE:FindUnit( Event.IniDCSUnitName )
        self:T({DCSUnit})
        if DCSUnit then
          --self:I("Creating DEAD Event for UNIT "..tostring(Event.IniDCSUnitName))
          --DCSUnit:Destroy(true)
          return
        end
      end

    else

      if Event.IniObjectCategory == 1 then

        ---
        -- UNITS
        ---

        -- Delete unit.
        if self.UNITS[Event.IniDCSUnitName] then
          self:ScheduleOnce(1,self.DeleteUnit,self,Event.IniDCSUnitName)
          --self:DeleteUnit(Event.IniDCSUnitName)
        end

        -- Remove client players.
        local client=self.CLIENTS[name] --Wrapper.Client#CLIENT

        if client then
          client:RemovePlayers()
        end

      end
    end

    -- Add airbase if it was spawned later in the mission.
    local airbase=self.AIRBASES[Event.IniDCSUnitName] --Wrapper.Airbase#AIRBASE
    if airbase and (airbase:IsHelipad() or airbase:IsShip()) then
      self:DeleteAirbase(Event.IniDCSUnitName)
    end

  end

  -- Account destroys.
  self:AccountDestroys( Event )
end


--- Handles the OnPlayerEnterUnit event to fill the active players table for CA units (with the unit filter applied).
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnPlayerEnterUnit( Event )
  self:F2( { Event } )

  if Event.IniDCSUnit then
    -- Player entering a CA slot
    if Event.IniObjectCategory == 1 and Event.IniGroup and Event.IniGroup:IsGround() then
        
      local IsPlayer = Event.IniDCSUnit:getPlayerName()
      if IsPlayer then

        -- Debug info.
        self:I(string.format("Player '%s' joined GROUND unit '%s' of group '%s'", tostring(Event.IniPlayerName), tostring(Event.IniDCSUnitName), tostring(Event.IniDCSGroupName)))
        
        local client= self.CLIENTS[Event.IniDCSUnitName] --Wrapper.Client#CLIENT
        
        -- Add client in case it does not exist already.
        if not client then
          client=self:AddClient(Event.IniDCSUnitName)
        end
              
        -- Add player.
        client:AddPlayer(Event.IniPlayerName)

        -- Add player.
        if not self.PLAYERS[Event.IniPlayerName] then
          self:AddPlayer( Event.IniUnitName, Event.IniPlayerName )
        end

        -- Player settings.
        local Settings = SETTINGS:Set( Event.IniPlayerName )
        Settings:SetPlayerMenu(Event.IniUnit)

      end

    end
  end
end

--- Handles the OnDynamicCargoRemoved event to clean the active dynamic cargo table.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnDynamicCargoRemoved( Event )
  self:T( { Event } )
  if Event.IniDynamicCargoName then
    self:DeleteDynamicCargo(Event.IniDynamicCargoName)
  end
end

--- Handles the OnPlayerLeaveUnit event to clean the active players table.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA Event
function DATABASE:_EventOnPlayerLeaveUnit( Event )
  self:F2( { Event } )
  
  local function FindPlayerName(UnitName)
    local playername = nil
    for _name,_unitname in pairs(self.PLAYERS) do
      if _unitname == UnitName then
        playername = _name
        break
      end
    end
    return playername
  end
  
  if Event.IniUnit then

    if Event.IniObjectCategory == 1 then

      -- Try to get the player name. This can be buggy for multicrew aircraft!
      local PlayerName = Event.IniPlayerName or Event.IniUnit:GetPlayerName() or FindPlayerName(Event.IniUnitName)
          
      if PlayerName then

        -- Debug info.
        self:I(string.format("Player '%s' left unit %s", tostring(PlayerName), tostring(Event.IniUnitName)))

        -- Remove player menu.
        local Settings = SETTINGS:Set( PlayerName )
        Settings:RemovePlayerMenu(Event.IniUnit)

        -- Delete player.
        self:DeletePlayer(Event.IniUnit, PlayerName)

        -- Client stuff.
        local client=self.CLIENTS[Event.IniDCSUnitName] --Wrapper.Client#CLIENT
        if client then
          client:RemovePlayer(PlayerName)
          --self.PLAYERSETTINGS[PlayerName] = nil
        end

      end
    end
  end
end

--- Iterators

--- Iterate the DATABASE and call an iterator function for the given set, providing the Object for each element within the set and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called when there is an alive player in the database.
-- @return #DATABASE self
function DATABASE:ForEach( IteratorFunction, FinalizeFunction, arg, Set )
  self:F2( arg )

  local function CoRoutine()
    local Count = 0
    for ObjectID, Object in pairs( Set ) do
        self:T2( Object )
        IteratorFunction( Object, unpack( arg ) )
        Count = Count + 1
--        if Count % 100 == 0 then
--          coroutine.yield( false )
--        end
    end
    return true
  end

--  local co = coroutine.create( CoRoutine )
  local co = CoRoutine

  local function Schedule()

--    local status, res = coroutine.resume( co )
    local status, res = co()
    self:T3( { status, res } )

    if status == false then
      error( res )
    end
    if res == false then
      return true -- resume next time the loop
    end
    if FinalizeFunction then
      FinalizeFunction( unpack( arg ) )
    end
    return false
  end

  --local Scheduler = SCHEDULER:New( self, Schedule, {}, 0.001, 0.001, 0 )
  Schedule()

  return self
end


--- Iterate the DATABASE and call an iterator function for each **alive** STATIC, providing the STATIC and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept a STATIC parameter.
-- @return #DATABASE self
function DATABASE:ForEachStatic( IteratorFunction, FinalizeFunction, ... )  --R2.1
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.STATICS )

  return self
end


--- Iterate the DATABASE and call an iterator function for each **alive** UNIT, providing the UNIT and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept a UNIT parameter.
-- @return #DATABASE self
function DATABASE:ForEachUnit( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.UNITS )

  return self
end


--- Iterate the DATABASE and call an iterator function for each **alive** GROUP, providing the GROUP and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept a GROUP parameter.
-- @return #DATABASE self
function DATABASE:ForEachGroup( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.GROUPS )

  return self
end


--- Iterate the DATABASE and call an iterator function for each **ALIVE** player, providing the player name and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept the player name.
-- @return #DATABASE self
function DATABASE:ForEachPlayer( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.PLAYERS )

  return self
end


--- Iterate the DATABASE and call an iterator function for each player who has joined the mission, providing the Unit of the player and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept a UNIT parameter.
-- @return #DATABASE self
function DATABASE:ForEachPlayerJoined( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.PLAYERSJOINED )

  return self
end

--- Iterate the DATABASE and call an iterator function for each **ALIVE** player UNIT, providing the player UNIT and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept the player name.
-- @return #DATABASE self
function DATABASE:ForEachPlayerUnit( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.PLAYERUNITS )

  return self
end


--- Iterate the DATABASE and call an iterator function for each CLIENT, providing the CLIENT to the function and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called object in the database. The function needs to accept a CLIENT parameter.
-- @return #DATABASE self
function DATABASE:ForEachClient( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.CLIENTS )

  return self
end

--- Iterate the DATABASE and call an iterator function for each CARGO, providing the CARGO object to the function and optional parameters.
-- @param #DATABASE self
-- @param #function IteratorFunction The function that will be called for each object in the database. The function needs to accept a CLIENT parameter.
-- @return #DATABASE self
function DATABASE:ForEachCargo( IteratorFunction, FinalizeFunction, ... )
  self:F2( arg )

  self:ForEach( IteratorFunction, FinalizeFunction, arg, self.CARGOS )

  return self
end


--- Handles the OnEventNewCargo event.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA EventData
function DATABASE:OnEventNewCargo( EventData )
  self:F2( { EventData } )

  if EventData.Cargo then
    self:AddCargo( EventData.Cargo )
  end
end


--- Handles the OnEventDeleteCargo.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA EventData
function DATABASE:OnEventDeleteCargo( EventData )
  self:F2( { EventData } )

  if EventData.Cargo then
    self:DeleteCargo( EventData.Cargo.Name )
  end
end


--- Handles the OnEventNewZone event.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA EventData
function DATABASE:OnEventNewZone( EventData )
  self:F2( { EventData } )

  if EventData.Zone then
    self:AddZone( EventData.Zone.ZoneName, EventData.Zone )
  end
end


--- Handles the OnEventDeleteZone.
-- @param #DATABASE self
-- @param Core.Event#EVENTDATA EventData
function DATABASE:OnEventDeleteZone( EventData )
  self:F2( { EventData } )

  if EventData.Zone then
    self:DeleteZone( EventData.Zone.ZoneName )
  end
end



--- Gets the player settings
-- @param #DATABASE self
-- @param #string PlayerName
-- @return Core.Settings#SETTINGS
function DATABASE:GetPlayerSettings( PlayerName )
  self:F2( { PlayerName } )
  return self.PLAYERSETTINGS[PlayerName]
end


--- Sets the player settings
-- @param #DATABASE self
-- @param #string PlayerName
-- @param Core.Settings#SETTINGS Settings
-- @return Core.Settings#SETTINGS
function DATABASE:SetPlayerSettings( PlayerName, Settings )
  self:F2( { PlayerName, Settings } )
  self.PLAYERSETTINGS[PlayerName] = Settings
end

--- Add an OPS group (FLIGHTGROUP, ARMYGROUP, NAVYGROUP) to the data base.
-- @param #DATABASE self
-- @param Ops.OpsGroup#OPSGROUP opsgroup The OPS group added to the DB.
function DATABASE:AddOpsGroup(opsgroup)
  --env.info("Adding OPSGROUP "..tostring(opsgroup.groupname))
  self.FLIGHTGROUPS[opsgroup.groupname]=opsgroup
end

--- Get an OPS group (FLIGHTGROUP, ARMYGROUP, NAVYGROUP) from the data base.
-- @param #DATABASE self
-- @param #string groupname Group name of the group. Can also be passed as GROUP object.
-- @return Ops.OpsGroup#OPSGROUP OPS group object.
function DATABASE:GetOpsGroup(groupname)

  -- Get group and group name.
  if type(groupname)=="string" then
  else
    groupname=groupname:GetName()
  end

  --env.info("Getting OPSGROUP "..tostring(groupname))
  return self.FLIGHTGROUPS[groupname]
end

--- Find an OPSGROUP (FLIGHTGROUP, ARMYGROUP, NAVYGROUP) in the data base.
-- @param #DATABASE self
-- @param #string groupname Group name of the group. Can also be passed as GROUP object.
-- @return Ops.OpsGroup#OPSGROUP OPS group object.
function DATABASE:FindOpsGroup(groupname)

  -- Get group and group name.
  if type(groupname)=="string" then
  else
    groupname=groupname:GetName()
  end

  --env.info("Getting OPSGROUP "..tostring(groupname))
  return self.FLIGHTGROUPS[groupname]
end

--- Find an OPSGROUP (FLIGHTGROUP, ARMYGROUP, NAVYGROUP) in the data base for a given unit.
-- @param #DATABASE self
-- @param #string unitname Unit name. Can also be passed as UNIT object.
-- @return Ops.OpsGroup#OPSGROUP OPS group object.
function DATABASE:FindOpsGroupFromUnit(unitname)

  local unit=nil --Wrapper.Unit#UNIT
  local groupname

  -- Get group and group name.
  if type(unitname)=="string" then
    unit=UNIT:FindByName(unitname)
  else
    unit=unitname
  end

  if unit then
    groupname=unit:GetGroup():GetName()
  end

  if groupname then
    return self.FLIGHTGROUPS[groupname]
  else
    return nil
  end
end

--- Add a flight control to the data base.
-- @param #DATABASE self
-- @param OPS.FlightControl#FLIGHTCONTROL flightcontrol
function DATABASE:AddFlightControl(flightcontrol)
  self:F2( { flightcontrol } )
  self.FLIGHTCONTROLS[flightcontrol.airbasename]=flightcontrol
end

--- Get a flight control object from the data base.
-- @param #DATABASE self
-- @param #string airbasename Name of the associated airbase.
-- @return OPS.FlightControl#FLIGHTCONTROL The FLIGHTCONTROL object.s
function DATABASE:GetFlightControl(airbasename)
  return self.FLIGHTCONTROLS[airbasename]
end

-- @param #DATABASE self
function DATABASE:_RegisterTemplates()
  self:F2()

  self.Navpoints = {}
  self.UNITS = {}
  --Build self.Navpoints
  for CoalitionName, coa_data in pairs(env.mission.coalition) do
    self:T({CoalitionName=CoalitionName})

    if (CoalitionName == 'red' or CoalitionName == 'blue' or CoalitionName == 'neutrals') and type(coa_data) == 'table' then
      --self.Units[coa_name] = {}

      local CoalitionSide = coalition.side[string.upper(CoalitionName)]
      if CoalitionName=="red" then
        CoalitionSide=coalition.side.RED
      elseif CoalitionName=="blue" then
        CoalitionSide=coalition.side.BLUE
      else
        CoalitionSide=coalition.side.NEUTRAL
      end

      -- build nav points DB
      self.Navpoints[CoalitionName] = {}
      if coa_data.nav_points then --navpoints
        for nav_ind, nav_data in pairs(coa_data.nav_points) do

          if type(nav_data) == 'table' then
            self.Navpoints[CoalitionName][nav_ind] = UTILS.DeepCopy(nav_data)

            self.Navpoints[CoalitionName][nav_ind]['name'] = nav_data.callsignStr  -- name is a little bit more self-explanatory.
            self.Navpoints[CoalitionName][nav_ind]['point'] = {}  -- point is used by SSE, support it.
            self.Navpoints[CoalitionName][nav_ind]['point']['x'] = nav_data.x
            self.Navpoints[CoalitionName][nav_ind]['point']['y'] = 0
            self.Navpoints[CoalitionName][nav_ind]['point']['z'] = nav_data.y
          end
        end
      end

      -------------------------------------------------
      if coa_data.country then --there is a country table
        for cntry_id, cntry_data in pairs(coa_data.country) do

          local CountryName = string.upper(cntry_data.name)
          local CountryID = cntry_data.id

          self.COUNTRY_ID[CountryName] = CountryID
          self.COUNTRY_NAME[CountryID] = CountryName

          --self.Units[coa_name][countryName] = {}
          --self.Units[coa_name][countryName]["countryId"] = cntry_data.id

          if type(cntry_data) == 'table' then  --just making sure

            for obj_type_name, obj_type_data in pairs(cntry_data) do

              if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then --should be an unncessary check

                local CategoryName = obj_type_name

                if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then  --there's a group!

                  --self.Units[coa_name][countryName][category] = {}

                  for group_num, Template in pairs(obj_type_data.group) do

                    if obj_type_name ~= "static" and Template and Template.units and type(Template.units) == 'table' then  --making sure again- this is a valid group
                      
                      self:_RegisterGroupTemplate(Template, CoalitionSide, _DATABASECategory[string.lower(CategoryName)], CountryID)

                    else

                      self:_RegisterStaticTemplate(Template, CoalitionSide, _DATABASECategory[string.lower(CategoryName)], CountryID)

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

  --- Account the Hits of the Players.
  -- @param #DATABASE self
  -- @param Core.Event#EVENTDATA Event
  function DATABASE:AccountHits( Event )
    self:F( { Event } )

    if Event.IniPlayerName ~= nil then -- It is a player that is hitting something
      self:T( "Hitting Something" )

      -- What is he hitting?
      if Event.TgtCategory then

        -- A target got hit
        self.HITS[Event.TgtUnitName] = self.HITS[Event.TgtUnitName] or {}
        local Hit = self.HITS[Event.TgtUnitName]

        Hit.Players = Hit.Players or {}
        Hit.Players[Event.IniPlayerName] = true
      end
    end

    -- It is a weapon initiated by a player, that is hitting something
    -- This seems to occur only with scenery and static objects.
    if Event.WeaponPlayerName ~= nil then
        self:T( "Hitting Scenery" )

      -- What is he hitting?
      if Event.TgtCategory then

        if Event.WeaponCoalition then -- A coalition object was hit, probably a static.
          -- A target got hit
          self.HITS[Event.TgtUnitName] = self.HITS[Event.TgtUnitName] or {}
          local Hit = self.HITS[Event.TgtUnitName]

          Hit.Players = Hit.Players or {}
          Hit.Players[Event.WeaponPlayerName] = true
        else -- A scenery object was hit.
        end
      end
    end
  end

  --- Account the destroys.
  -- @param #DATABASE self
  -- @param Core.Event#EVENTDATA Event
  function DATABASE:AccountDestroys( Event )
    self:F( { Event } )

    local TargetUnit = nil
    local TargetGroup = nil
    local TargetUnitName = ""
    local TargetGroupName = ""
    local TargetPlayerName = ""
    local TargetCoalition = nil
    local TargetCategory = nil
    local TargetType = nil
    local TargetUnitCoalition = nil
    local TargetUnitCategory = nil
    local TargetUnitType = nil

    if Event.IniDCSUnit then

      TargetUnit = Event.IniUnit
      TargetUnitName = Event.IniDCSUnitName
      TargetGroup = Event.IniDCSGroup
      TargetGroupName = Event.IniDCSGroupName
      TargetPlayerName = Event.IniPlayerName

      TargetCoalition = Event.IniCoalition
      TargetCategory = Event.IniCategory
      TargetType = Event.IniTypeName

      TargetUnitType = TargetType

      self:T( { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType } )
    end

    local Destroyed = false

    -- What is the player destroying?
    if self.HITS[Event.IniUnitName] then -- Was there a hit for this unit for this player before registered???
      self.DESTROYS[Event.IniUnitName] = self.DESTROYS[Event.IniUnitName] or {}
      self.DESTROYS[Event.IniUnitName] = true
    end
  end
