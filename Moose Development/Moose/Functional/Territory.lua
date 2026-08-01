--- **Ops** - Passive strategic territory.
--
-- **Main Features:**
--
--    * Associate a static MOOSE zone with a coalition
--    * Keep strategic territory geometry separate from OPSZONE scanning
--    * Register territories in the MOOSE database
--    * Delegate coordinate checks and F10 drawing to the underlying zone
--
-- A TERRITORY is deliberately passive. It does not scan DCS objects, evaluate
-- ownership, run a scheduler, or make tactical or strategic decisions.
--
-- ===
--
-- @module Ops.Territory


--- TERRITORY class.
-- @type TERRITORY
-- @field #string ClassName Name of the class.
-- @field #string version Class version.
-- @field #number verbose Verbosity level.
-- @field #string lid Log ID string.
-- @field #string name Unique territory name.
-- @field #string zoneName Name of the underlying MOOSE zone.
-- @field Core.Zone#ZONE_BASE zone Underlying MOOSE zone.
-- @field #number coalition Coalition associated with the territory.
-- @extends Core.Base#BASE

--- A passive strategic area defined by an existing MOOSE zone.
--
-- TERRITORY contains geometry and declarative ownership only. Unlike
-- @{Ops.OpsZone#OPSZONE}, it performs no periodic object scans and has no FSM.
--
-- @field #TERRITORY
TERRITORY = {
  ClassName = "TERRITORY",
  verbose = 0,
}

--- TERRITORY class version.
-- @field #string version
TERRITORY.version = "0.1.0"

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DATABASE extension
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Finds a TERRITORY based on its name.
-- @param Core.Database#DATABASE self
-- @param #string TerritoryName Name of the territory.
-- @return #TERRITORY The found territory or `nil`.
function DATABASE:FindTerritory(TerritoryName)
  local territories = self.TERRITORIES or {}
  return territories[TerritoryName]
end

--- Adds a TERRITORY to the database.
-- @param Core.Database#DATABASE self
-- @param #TERRITORY Territory Territory to add.
-- @return #TERRITORY The registered territory or `nil`.
function DATABASE:AddTerritory(Territory)
  if not Territory then
    return nil
  end

  self.TERRITORIES = self.TERRITORIES or {}

  local territoryName = Territory:GetName()
  if not self.TERRITORIES[territoryName] then
    self.TERRITORIES[territoryName] = Territory
  end

  return self.TERRITORIES[territoryName]
end

--- Deletes a TERRITORY from the database.
-- @param Core.Database#DATABASE self
-- @param #string TerritoryName Name of the territory.
-- @return Core.Database#DATABASE self
function DATABASE:DeleteTerritory(TerritoryName)
  if self.TERRITORIES then
    self.TERRITORIES[TerritoryName] = nil
  end
  return self
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new TERRITORY class object.
-- @param #TERRITORY self
-- @param Core.Zone#ZONE_BASE Zone The underlying MOOSE zone or its Mission Editor name.
-- @param #number Coalition (Optional) Associated coalition. Default `coalition.side.NEUTRAL`.
-- @param #string Name (Optional) Unique territory name. Default is the zone name.
-- @return #TERRITORY self
-- @usage
-- local north = TERRITORY:New("Territory North", coalition.side.BLUE)
-- local southZone = ZONE:FindByName("Territory South")
-- local south = TERRITORY:New(southZone, coalition.side.RED, "Southern Territory")
function TERRITORY:New(Zone, Coalition, Name)

  -- Inherit everything from BASE class.
  local self = BASE:Inherit(self, BASE:New()) -- #TERRITORY

  -- Resolve a Mission Editor zone name.
  if type(Zone) == "string" then
    local zoneName = Zone
    Zone = ZONE:FindByName(zoneName)
    if not Zone then
      self:E(string.format("ERROR: No ZONE found for name: %s", tostring(zoneName)))
      return nil
    end
  elseif not Zone then
    self:E("ERROR: First parameter Zone is nil in TERRITORY:New(Zone) call!")
    return nil
  end

  -- A territory relies only on the common ZONE_BASE interface.
  if type(Zone.GetName) ~= "function"
    or type(Zone.GetCoordinate) ~= "function"
    or type(Zone.IsCoordinateInZone) ~= "function" then
    self:E("ERROR: TERRITORY requires a ZONE_BASE derived object!")
    return nil
  end

  local zoneName = Zone:GetName()
  local territoryName = Name or zoneName
  if type(territoryName) ~= "string" or territoryName == "" then
    self:E("ERROR: TERRITORY requires a non-empty name!")
    return nil
  end

  self.zone = Zone
  self.zoneName = zoneName
  self.name = territoryName
  self.lid = string.format("TERRITORY %s | ", territoryName)

  if not self:SetCoalition(Coalition or coalition.side.NEUTRAL) then
    return nil
  end

  -- Register in the MOOSE database.
  _DATABASE:AddTerritory(self)

  return self
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Set functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the coalition associated with this territory.
-- This method only changes declarative ownership. It does not evaluate DCS
-- units or trigger any capture logic.
-- @param #TERRITORY self
-- @param #number Coalition Coalition side number.
-- @return #TERRITORY self or `nil` if the coalition is invalid.
function TERRITORY:SetCoalition(Coalition)
  if Coalition ~= coalition.side.NEUTRAL
    and Coalition ~= coalition.side.RED
    and Coalition ~= coalition.side.BLUE then
    self:E(self.lid .. string.format("ERROR: Invalid coalition: %s", tostring(Coalition)))
    return nil
  end

  self.coalition = Coalition
  return self
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Get functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Find a TERRITORY by name.
-- @param #TERRITORY self
-- @param #string Name Name of the territory.
-- @return #TERRITORY The found territory or `nil`.
function TERRITORY:FindByName(Name)
  return _DATABASE:FindTerritory(Name)
end

--- Get the territory name.
-- @param #TERRITORY self
-- @return #string Territory name.
function TERRITORY:GetName()
  return self.name
end

--- Get the underlying zone name.
-- @param #TERRITORY self
-- @return #string Zone name.
function TERRITORY:GetZoneName()
  return self.zoneName
end

--- Get the underlying MOOSE zone.
-- @param #TERRITORY self
-- @return Core.Zone#ZONE_BASE The underlying zone.
function TERRITORY:GetZone()
  return self.zone
end

--- Get the territory center coordinate.
-- @param #TERRITORY self
-- @return Core.Point#COORDINATE Territory center coordinate.
function TERRITORY:GetCoordinate()
  return self.zone:GetCoordinate()
end

--- Get the coalition associated with the territory.
-- @param #TERRITORY self
-- @return #number Coalition side number.
function TERRITORY:GetCoalition()
  return self.coalition
end

--- Get the name of the coalition associated with the territory.
-- @param #TERRITORY self
-- @return #string Coalition name.
function TERRITORY:GetCoalitionName()
  return UTILS.GetCoalitionName(self.coalition)
end

--- Get the owner of the territory.
-- This is an alias for @{#TERRITORY.GetCoalition}.
-- @param #TERRITORY self
-- @return #number Coalition side number.
function TERRITORY:GetOwner()
  return self:GetCoalition()
end

--- Get the owner coalition name.
-- This is an alias for @{#TERRITORY.GetCoalitionName}.
-- @param #TERRITORY self
-- @return #string Coalition name.
function TERRITORY:GetOwnerName()
  return self:GetCoalitionName()
end

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Zone functions
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Test whether a coordinate lies inside the territory.
-- @param #TERRITORY self
-- @param Core.Point#COORDINATE Coordinate Coordinate to test.
-- @return #boolean `true` if the coordinate lies inside the territory.
function TERRITORY:ContainsCoordinate(Coordinate)
  return self.zone:IsCoordinateInZone(Coordinate)
end

--- Test whether a Vec2 lies inside the territory.
-- @param #TERRITORY self
-- @param DCS#Vec2 Vec2 Vec2 to test.
-- @return #boolean `true` if the Vec2 lies inside the territory.
function TERRITORY:ContainsVec2(Vec2)
  return self.zone:IsVec2InZone(Vec2)
end

--- Draw the territory on the F10 map.
-- Drawing is delegated to the underlying MOOSE zone.
-- @param #TERRITORY self
-- @param #number Coalition (Optional) Coalition visibility. Default `-1` for all.
-- @param #table Color (Optional) RGB line color.
-- @param #number Alpha (Optional) Line alpha.
-- @param #table FillColor (Optional) RGB fill color.
-- @param #number FillAlpha (Optional) Fill alpha.
-- @param #number LineType (Optional) DCS line type.
-- @return #TERRITORY self
function TERRITORY:Draw(Coalition, Color, Alpha, FillColor, FillAlpha, LineType)
  self.zone:DrawZone(Coalition, Color, Alpha, FillColor, FillAlpha, LineType)
  return self
end

--- Remove the territory drawing from the F10 map.
-- @param #TERRITORY self
-- @return #TERRITORY self
function TERRITORY:Undraw()
  self.zone:UndrawZone()
  return self
end

--- Remove the territory from the MOOSE database.
-- The underlying zone is not deleted.
-- @param #TERRITORY self
-- @return #TERRITORY self
function TERRITORY:Remove()
  _DATABASE:DeleteTerritory(self.name)
  return self
end
