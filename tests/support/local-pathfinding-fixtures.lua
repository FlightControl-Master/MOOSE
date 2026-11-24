-- Standalone P0 fixtures only. This file is not included in MOOSE or a mission.
local import = ...
if type(import) ~= "function" then
  import = dofile
end
local Codec = import("tests/support/local-pathfinding-codec.lua")
local Fixtures = {Revision = "p0-analytic-1"}

local function vec(x, z, y)
  if y == nil then
    y = 0
  end
  return {x = x, y = y, z = z}
end

-- Regions are ordered; later definitions take precedence where they overlap.
function Fixtures.Definition(kind)
  local terrain = {Id = kind, Revision = Fixtures.Revision, Depth = 30, Regions = {}}
  if kind == "shoal" then
    terrain.Regions[1] = {XMin = 600, XMax = 1400, ZMin = -250, ZMax = 250, Depth = 5}
  elseif kind == "island" then
    terrain.Regions[1] = {XMin = 600, XMax = 1400, ZMin = -250, ZMax = 250, Land = true}
  elseif kind == "missing_data" then
    terrain.Regions[1] = {XMin = -100, XMax = 1400, ZMin = -100, ZMax = 250, Missing = true}
  else
    assert(kind == "open_water", "P0 fixture: unknown analytic terrain")
  end
  return terrain
end

function Fixtures.Case(kind, experiment)
  if experiment == nil then
    experiment = "request_parity"
  end
  local start, goal = vec(0, 0), vec(2000, 0)
  return {
    SchemaVersion = 1, CaseId = kind, Revision = "p0-i1-1", VariantId = "weight-1",
    Experiment = experiment, InitialState = "cold",
    Environment = {
      ReplayCapability = "analytic", Terrain = Fixtures.Definition(kind), LuaVersion = _VERSION,
      SourceVerification = "unverified", SourceManifest = {},
    },
    Route = {Start = start, Goal = goal, OriginalTargetId = "configured-target"},
    Search = {
      Grid = {Type = "hexagonal", Spacing = 400, MaxCells = 3000,
        SurfaceTypes = {"WATER", "SHALLOW_WATER"}, ZoneRestriction = "none"},
      GridNeighboursOnly = true, Window = {Ahead = 6000, Width = 4000, Behind = 1500},
      HeadingPolicy = "towards_goal", Depth = {MinDepth = 3.5, CorridorWidth = 50},
      Cost = {Kind = "depth", PreferredDepth = 15, Weight = 1}, LearningLimit = 4096,
      Progress = {MinDistance = 10, HistorySize = 32, RepeatLimit = 3},
    },
    Validation = {
      Geometry = {MaxPoints = 10000},
      Connection = {RuleSource = "search", CostUnits = "depth_weighted_meters"},
      Depth = {LongitudinalSpacing = 25, LateralSpacing = 10, MaxSectionLength = 1000,
        MaxOffsets = 65, MaxProfilePoints = 4096, MaxDirectPoints = 4097},
      Maneuver = {Status = "unverified"},
    },
    Pose = {Position = Codec.Copy(start), HeadingDeg = 0, ActualSpeedMps = 0, RequestedSpeedMps = 0},
    Provenance = {Route = "configured", Pose = "configured", Terrain = "configured"},
    Actions = experiment == "virtual_follow" and {
      {Kind = "observe", Position = Codec.Copy(start), Provenance = "virtual"},
    } or {
      {Kind = "observe", Position = Codec.Copy(start), Provenance = "virtual"},
      {Kind = "start", Start = Codec.Copy(start), Goal = Codec.Copy(goal)},
      {Kind = "step", UntilComplete = true},
    },
    Execution = {
      Clock = "synthetic", SliceNodes = 100, SliceSeconds = 0.005,
      MaxSlicesPerRequest = 4000, MaxWorkItemsPerRequest = 400000, MaxRequests = 200,
      MaxEvents = 10000, MaxCandidates = 8, MaxPositionsPerCandidate = 10000,
      MaxArtifactBytes = 64 * 1024 * 1024, Debug = false,
      Connection = {Slice = {MaxWorkUnits = 64, MaxEvaluatorCalls = 1},
        Total = {MaxWorkUnits = 200000, MaxEvaluatorCalls = 4096}},
      Depth = {Slice = {MaxWorkUnits = 64, MaxPointChecks = 8, MaxProfileQueries = 1},
        Total = {MaxWorkUnits = 200000, MaxPointChecks = 50000, MaxProfileQueries = 4096}},
      MaxValidationSlices = 200000,
    },
    Expected = {DriverStatus = "complete", NativeStopReason = "path_found"},
  }
end

function Fixtures.Terrain(definition)
  local data = Codec.Copy(definition)
  local terrain = {Definition = data, Calls = {Surface = 0, Depth = 0, Profile = 0}}
  function terrain:Sample(x, z)
    local depth, onLand, missing = data.Depth, false, false
    for _, region in ipairs(data.Regions) do
      if x >= region.XMin and x <= region.XMax and z >= region.ZMin and z <= region.ZMax then
        if region.Depth ~= nil then
          depth = region.Depth
        end
        if region.Land ~= nil then
          onLand = region.Land
        end
        if region.Missing ~= nil then
          missing = region.Missing
        end
      end
    end
    return depth, onLand, missing
  end
  function terrain:Surface(position)
    self.Calls.Surface = self.Calls.Surface + 1
    assert(data.ErrorFunction ~= "Surface", "P0 fixture: injected Surface error")
    local depth, onLand = self:Sample(position.x, position.y)
    return onLand and 1 or (depth < 15 and 2 or 3)
  end
  function terrain:Depth(position)
    self.Calls.Depth = self.Calls.Depth + 1
    assert(data.ErrorFunction ~= "Depth", "P0 fixture: injected Depth error")
    local depth, onLand, missing = self:Sample(position.x, position.y)
    if missing then
      return 0, nil
    end
    return 0, onLand and 0 or depth
  end
  function terrain:Profile(first, last)
    self.Calls.Profile = self.Calls.Profile + 1
    assert(data.ErrorFunction ~= "Profile", "P0 fixture: injected Profile error")
    local fractions = {0, 1}
    -- Include each feature boundary and interval midpoint, including small islets.
    for _, region in ipairs(data.Regions) do
      for _, axis in ipairs({{"x", "XMin", "XMax"}, {"z", "ZMin", "ZMax"}}) do
        local delta = last[axis[1]] - first[axis[1]]
        if delta ~= 0 then
          for field = 2, 3 do
            local fraction = (region[axis[field]] - first[axis[1]]) / delta
            if fraction > 0 and fraction < 1 then
              fractions[#fractions + 1] = fraction
            end
          end
        end
      end
    end
    table.sort(fractions)
    local support = {}
    for _, fraction in ipairs(fractions) do
      if support[#support] ~= fraction then
        support[#support + 1] = fraction
      end
    end
    local samples = {}
    for index, fraction in ipairs(support) do
      samples[#samples + 1] = fraction
      if index < #support then
        samples[#samples + 1] = (fraction + support[index + 1]) / 2
      end
    end
    local result = {}
    for index, fraction in ipairs(samples) do
      local x = first.x + (last.x - first.x) * fraction
      local z = first.z + (last.z - first.z) * fraction
      local depth, onLand, missing = self:Sample(x, z)
      if missing then
        return nil
      end
      result[index - 1] = {x = x, y = onLand and 0 or -depth, z = z}
    end
    return result
  end
  return terrain
end

local function internalCopy(value)
  if type(value) ~= "table" then
    return value
  end
  local result = {}
  for key, item in pairs(value) do
    result[key] = internalCopy(item)
  end
  return setmetatable(result, getmetatable(value))
end

-- Install only controlled external dependencies, then load actual Core sources.
-- Each standalone suite has its own Lua process; no native DCS hooks are altered.
function Fixtures.Install(loadSource)
  local environment = {ForbiddenCalls = 0, DrawingCalls = 0}
  local function forbidden()
    environment.ForbiddenCalls = environment.ForbiddenCalls + 1
    error("P0 fixture: unexpected simulator/controller/timer access")
  end
  BASE = {}
  function BASE:New()
    return setmetatable({}, {__index = self})
  end
  function BASE:Inherit(child, parent)
    return setmetatable(internalCopy(child), {__index = parent})
  end
  function BASE:T() end
  function BASE:T2() end
  function BASE:E() end
  UTILS = {GetOSTime = function() return 0 end}
  function UTILS.VecDist2D(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2)
  end
  function UTILS.AdjustHeading360(heading)
    return heading % 360
  end
  function UTILS.VecTranslate(v, distance, heading)
    local angle = math.rad(heading)
    return {x = v.x + distance * math.cos(angle), y = v.y, z = v.z + distance * math.sin(angle)}
  end
  function UTILS.Rotate2D(v, heading)
    local angle = math.rad(heading)
    return {x = v.x * math.cos(angle) + v.z * math.sin(angle), y = v.y,
      z = v.z * math.cos(angle) - v.x * math.sin(angle)}
  end
  local markID = 0
  function UTILS.GetMarkID()
    markID = markID + 1
    return markID
  end
  function UTILS.RemoveMark()
    environment.DrawingCalls = environment.DrawingCalls + 1
  end
  local function draw() environment.DrawingCalls = environment.DrawingCalls + 1 end
  trigger = {action = {markToAll = draw, lineToAll = draw, removeMark = draw}}
  timer = {getTime = function() return 0 end, getAbsTime = function() return 0 end,
    scheduleFunction = forbidden, removeFunction = forbidden}
  TIMER, Group, Controller = {New = forbidden}, {getByName = forbidden}, {setTask = forbidden}
  MESSAGE = {New = function() return {ToAllIf = draw} end}
  COORDINATE = {}
  function COORDINATE:New(x, y, z)
    return setmetatable({x = x, y = y, z = z}, {__index = self})
  end
  function COORDINATE:NewFromVec3(v)
    return self:New(v.x, v.y, v.z)
  end
  function COORDINATE:GetVec3()
    return vec(self.x, self.z, self.y)
  end
  function COORDINATE:Get2DDistance(other)
    return math.sqrt((self.x - other.x)^2 + (self.z - other.z)^2)
  end
  function COORDINATE:Get3DDistance(other)
    return math.sqrt(self:Get2DDistance(other)^2 + (self.y - other.y)^2)
  end
  function COORDINATE:HeadingTo(other)
    return math.deg(math.atan2(other.z - self.z, other.x - self.x))
  end
  function COORDINATE:Translate(distance, heading)
    local v = UTILS.VecTranslate(self, distance, heading)
    return self:New(v.x, v.y, v.z)
  end
  local function active()
    return assert(environment.ActiveTerrain, "P0 fixture: no active terrain")
  end
  land = {SurfaceType = {LAND = 1, SHALLOW_WATER = 2, WATER = 3},
    getSurfaceType = function(position) return active():Surface(position) end,
    getSurfaceHeightWithSeabed = function(position) return active():Depth(position) end,
    profile = function(first, last) return active():Profile(first, last) end}
  environment.FixtureLand = land
  loadSource = loadSource or dofile
  loadSource("Moose Development/Moose/Core/Vector.lua")
  loadSource("Moose Development/Moose/Core/Pathline.lua")
  loadSource("Moose Development/Moose/Core/Grid.lua")
  loadSource("Moose Development/Moose/Core/Astar.lua")
  environment.LoadedSources = {
    "Moose Development/Moose/Core/Vector.lua", "Moose Development/Moose/Core/Pathline.lua",
    "Moose Development/Moose/Core/Grid.lua", "Moose Development/Moose/Core/Astar.lua",
  }
  return environment
end

return Fixtures
