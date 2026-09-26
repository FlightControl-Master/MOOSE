--- **Core** - Reusable rectangular and hexagonal spatial grids.
--
-- **Main Features:**
--
--    * Rectangular and hexagonal cell geometry.
--    * Grid creation from corridor bounds or MOOSE zones.
--    * Indexed neighbours and bounded grid expansion.
--    * Position lookup, grid distances, rings, ranges and intersected cell boundaries.
--    * Shared grids with independent ASTAR searches.
--    * Batched grid drawings and point markers on the F10 map.
--
-- ===
--
-- @module Core.Grid

--- GRID class.
-- @type GRID
-- @field #string ClassName Class name.
-- @field #string name Grid name.
-- @field #string GridType Fixed geometry type selected in the constructor; do not modify.
-- @field #table cells Cells indexed by stable cell ID.
-- @field #number CellCount Number of accepted geometric cells.
-- @field #table GridDrawCellIDs Polygon mark IDs indexed by cell ID.
-- @field #table LastGridDrawResult Drawing status, CellsQueued, CellsDrawn and batch timing.
-- @field #table LastGridMarkResult Marker status, CellsQueued, CellsMarked and batch timing.
-- @field #number Version Monotonically increasing mutation version.
-- @field #number GridCandidateCount Candidate count before zone and surface filters.
-- @field #boolean GridBuilt True after successful construction, including an empty filtered grid.
-- @extends Core.Base#BASE

--- # The GRID Concept
--
-- GRID owns cell geometry that is read-only by contract, surface samples, indexed neighbours, expansion and F10 overlays.
-- It performs no path search and stores no movement-rule or travel-cost caches. Cells use VECTOR positions.
-- Configure before building. Creation checks MaxCells before terrain sampling; expansion retains accepted and rejected samples.
-- A zone limits initial cell centers only: later enlargement may leave it. Cell outlines are not traversability guarantees.
--
-- # Usage
--
--     local grid = GRID:New("Sea", GRID.Type.RECTANGLE)
--     grid:SetSpacing(2000):SetMaxCells(5000):SetDiagonals(true)
--     grid:SetValidSurfaceTypes(land.SurfaceType.WATER)
--     local built, reason = grid:CreateFromZone(searchZone)
--     if built then
--       local search = ASTAR:New():SetGrid(grid)
--       search:SetStartCoordinate(start):SetEndCoordinate(goal):SetValidNeighbourLoS(500)
--       local path, report = search:GetPathWithExpansion()
--       if path then grid:DrawGridWithPath(path) end
--     end
--
-- # Grid Configuration
--
-- New(Name, GridType) requires a non-empty name and GRID.Type.RECTANGLE or GRID.Type.HEXAGON.
-- The geometry type is fixed for the lifetime of the object and GetType() exposes it before construction.
-- For a corridor, use CreateFromBounds(start, goal); for a zone, use CreateFromZone(zone).
-- SetBounds(start, goal) optionally defines the frame before a zone build.
-- Zone builders also work without bounds: their frame is centered on the zone bounding box with heading zero.
-- Options: Width=40000, Margin=10000, Spacing=2000, CrossSpacing=Spacing (rectangles only),
-- Diagonals=true, MaxCells=5000; Expansion={GrowthFactor=1.5, MaxAttempts=5}.
-- Expansion.MaxWidth and Expansion.MaxMargin are optional meter limits with no defaults.
-- SetOptions updates only supplied fields, including fields within Expansion; nil and empty tables leave settings unchanged.
-- ResetOptions restores all option defaults. GetOptions returns an independent copy. Geometry and surface filters lock after construction.
-- SetSpacing(Spacing, CrossSpacing), SetMaxCells(MaxCells) and SetDiagonals(Diagonals) preserve unrelated options.
-- SetSpacing selects manual mode; SetResolution selects automatic mode. Omitted setter arguments restore their documented defaults.
-- SetExpansion(GrowthFactor, MaxAttempts, MaxWidth, MaxMargin) replaces the complete expansion configuration.
-- For example, SetExpansion(1.5, 5) removes previous dimension limits; SetExpansion() restores all expansion defaults.
-- A nil field in a partial options table cannot clear a value: use these setters or ResetOptions instead.
-- Diagonals and limits may change afterwards. A successful mutation increments GetVersion(); ASTAR synchronizes before searching.
--
-- # Relative Corridor Dimensions
--
-- SetCorridor(GRID.Width.NORMAL, GRID.Margin.NORMAL) sizes the initial corridor from horizontal endpoint distance D.
-- GRID.Margin.SMALL, NORMAL and LARGE set the margin M at each end to 10, 25 and 50 percent of D.
-- Total length L is D+2*M. GRID.Width.NARROW, NORMAL and WIDE set the total width to 25, 50 and 100 percent of L.
-- The corridor follows the endpoint connection line, with half its width on each side.
-- For D=40000 meters, both NORMAL presets produce M=10000, L=60000 and a width of 30000 meters.
--
--     local grid = GRID:New("Sea", GRID.Type.HEXAGON)
--     grid:SetCorridor(GRID.Width.NORMAL, GRID.Margin.NORMAL)
--     grid:SetResolution(GRID.Resolution.NORMAL)
--     local built, reason = grid:CreateFromBounds(start, goal)
--     if built then local dimensions = grid:GetDimensions() end -- Width/Margin/Spacing in meters.
--
-- Width and Margin in SetOptions() also accept these presets. Each setting may instead be an explicit non-negative meter value.
-- SetCorridor() changes only these two settings. Without presets the defaults remain Width=40000 and Margin=10000 meters.
-- Presets need distinct endpoints; coincident endpoints require both dimensions in meters.
-- Resolution is calculated after the initial dimensions. Explicit cell and expansion limits are never raised to fit a requested grid.
-- Expansion starts from the computed dimensions and retains spacing; it does not recompute the initial preset proportions.
-- Zone builders ignore corridor Width/Margin settings and derive their initial dimensions from the zone as before.
-- GetOptions() preserves preset strings; GetDimensions() exposes the current meter dimensions after construction.
--
-- # Automatic Resolution
--
-- SetResolution(GRID.Resolution.NORMAL) selects automatic spacing and clears explicit Spacing/CrossSpacing.
-- COARSE uses the shorter positive initial extent / 10, NORMAL / 20 and FINE / 40.
-- Corridors use start-goal distance plus both margins and the configured width; zones use their projected bounding box.
-- Both grid types use the same center spacing in meters. Automatic rectangular cells are squares.
-- A zero-width line uses the remaining length; a point requires manual spacing. Altitude is ignored.
-- These are relative detail levels, not target cell counts or guarantees that narrow passages are represented.
-- MaxCells is checked before terrain/zone filtering and is never raised; an oversized build returns nil, "cell_limit".
-- Expansion retains the calculated spacing. Changing resolution or switching spacing mode requires a new grid after construction.
--
--     local grid = GRID:New("Sea", GRID.Type.HEXAGON)
--     grid:SetMaxCells(5000):SetExpansion(1.5, 5)
--     grid:SetResolution(GRID.Resolution.NORMAL)
--     grid:SetValidSurfaceTypes(land.SurfaceType.WATER)
--     local built, reason = grid:CreateFromZone(searchZone)
--     local info = grid:GetResolutionInfo() -- Spacing, ReferenceLength, Status, MaxCells; CandidateCount after success.
--
-- SetOptions({Resolution=GRID.Resolution.FINE, ...}) is also supported; explicit Spacing/CrossSpacing cannot be combined with it.
-- GetOptions() preserves this configuration with nil Spacing in automatic mode, so its copy can be passed back to SetOptions().
-- GetResolutionInfo() reports the calculated spacing after a build attempt; GetDimensions() also exposes spacing after success.
-- SetResolution(nil) restores manual mode with default spacing before construction; SetOptions() can select any explicit spacing.
-- Without a preset or explicit spacing, the existing 2000-meter default applies.
--
-- # Shared Grids and Cell Access
--
-- Sharing a grid shares its extensions and options. Separate ASTAR objects own separate search nodes, endpoints, caches and overlays.
-- Cell objects returned by getters are read-only references: do not modify their vectors, IDs, indices or metadata.
--
-- # Geometry Queries
--
-- PositionToIndex(position) returns i,j for rectangles or q,r for hexagons, even outside the built area.
-- IndexToPosition(first, second) returns the corresponding center as a new VECTOR at height zero.
-- GetCellAtPosition(position) returns only that indexed cell; a filtered or unbuilt position returns nil.
-- Use FindClosestCell(position) when the nearest accepted cell is wanted instead.
--
-- GetGridDistance(a, b), GetRing(center, radius) and GetCellsInRange(center, radius) use cell steps, not meters.
-- They accept owned cells or positions. Positions snap to the lattice, including outside the built area.
-- Rectangle distances use Manhattan distance with Diagonals=false, otherwise Chebyshev distance; hexagons use cube distance.
-- These are geometric distances on the complete lattice: missing cells and blocked connections do not increase them.
-- Rings and ranges return existing cells in insertion order, not in angular order, and scan only existing cells.
--
-- GetLineCells(start, goal) returns all existing cells touched by the actual horizontal segment (a supercover).
-- Edge and vertex contacts are included, with a tolerance of 1e-9 cell spacings.
-- Results follow segment entry order, with cell ID breaking ties; holes remain holes, and no connection is implied.
-- GetPolygonBoundaryCells(vertices) closes the last edge and removes duplicates in first-encounter order.
-- Neither method fills a polygon or validates a navigable route. Queries never sample terrain or create cells.
-- Index, distance, ring, range, line and polygon queries require a built grid, including a successfully built empty grid.
--
--     local cell = grid:GetCellAtPosition(position)
--     local nearby = grid:GetCellsInRange(position, 3)
--     local ring = grid:GetRing(position, 2)
--     local crossed = grid:GetLineCells(start, goal)
--
-- # F10 Map Drawing
--
-- DrawGrid/MarkGrid use bounded timer batches; UndrawGrid/UnmarkGrid remove only their owner's overlays.
--
-- @field #GRID
GRID = {
  ClassName = "GRID"
}

--- Supported fixed grid geometries.
-- @type GRID.Type
-- @field #string RECTANGLE Rectangular cells, including squares.
-- @field #string HEXAGON Regular hexagonal cells.
---@enum GRID.Type
GRID.Type={RECTANGLE="rectangular", HEXAGON="hexagonal"}

--- Relative spacing presets based on the shorter positive initial extent.
-- @type GRID.Resolution
-- @field #string COARSE Ten center-to-center intervals across the reference extent.
-- @field #string NORMAL Twenty center-to-center intervals across the reference extent.
-- @field #string FINE Forty center-to-center intervals across the reference extent.
---@enum GRID.Resolution
GRID.Resolution={COARSE="coarse", NORMAL="normal", FINE="fine"}

--- Initial corridor width as a fraction of its total length, including both margins.
-- @type GRID.Width
-- @field #string NARROW Total width is 25 percent of corridor length.
-- @field #string NORMAL Total width is 50 percent of corridor length.
-- @field #string WIDE Total width is 100 percent of corridor length.
---@enum GRID.Width
GRID.Width={NARROW="narrow", NORMAL="normal", WIDE="wide"}

--- Initial margin at each end as a fraction of endpoint distance.
-- @type GRID.Margin
-- @field #string SMALL Each margin is 10 percent of endpoint distance.
-- @field #string NORMAL Each margin is 25 percent of endpoint distance.
-- @field #string LARGE Each margin is 50 percent of endpoint distance.
---@enum GRID.Margin
GRID.Margin={SMALL="small", NORMAL="normal", LARGE="large"}

--- GRID class version.
-- @field #string version
GRID.version="0.1.0"

--- Grid geometry and resource limits. All fields are optional; distances are meters.
-- @type GRID.GridOptions
-- @field #number Width Total search width in meters or a GRID.Width preset, default 40000. Ignored by zone builders.
-- @field #number Margin Margin at each end in meters or a GRID.Margin preset, default 10000. Ignored by zone builders.
-- @field #number Spacing Manual center spacing, default 2000. Omitted in automatic resolution mode.
-- @field #number CrossSpacing Rectangular transverse spacing; omitted means Spacing. Rejected for hex grids.
-- @field #string Resolution Optional GRID.Resolution preset; mutually exclusive with Spacing and CrossSpacing.
-- @field #boolean Diagonals Allow diagonal neighbours in local rectangular mode, default true. Ignored by hex grids. Can change after creation.
-- @field #number MaxCells Shared candidate-cell limit before filtering, default 5000. Counts candidate centers before surface and zone filtering.
-- @field #GRID.ExpansionOptions Expansion Expansion configuration.
---@class GRID.GridOptions
---@field Width? number|GRID.Width Total corridor width in meters or a relative preset; default 40000.
---@field Margin? number|GRID.Margin Margin at each end in meters or a relative preset; default 10000.
---@field Spacing? number Manual center spacing in meters; default 2000. Mutually exclusive with Resolution.
---@field CrossSpacing? number Rectangular transverse spacing in meters; defaults to Spacing. Mutually exclusive with Resolution.
---@field Resolution? GRID.Resolution Automatic relative spacing; mutually exclusive with Spacing and CrossSpacing.
---@field Diagonals? boolean Eight rectangular neighbours if true, four if false; default true.
---@field MaxCells? integer Candidate-cell limit before filtering; default 5000.
---@field Expansion? GRID.ExpansionOptions Iterative search settings.

--- Expansion limits and default settings for iterative searches.
-- @type GRID.ExpansionOptions
-- @field #number GrowthFactor Finite multiplier greater than 1, default 1.5.
-- @field #number MaxAttempts Positive integer search limit including the first attempt, default 5.
-- @field #number MaxWidth Optional maximum width in meters; nil means no width limit.
-- @field #number MaxMargin Optional maximum margin at each end in meters; nil means no margin limit.
---@class GRID.ExpansionOptions
---@field GrowthFactor? number Finite multiplier greater than one; default 1.5.
---@field MaxAttempts? integer Positive search attempt limit including the first search; default 5.
---@field MaxWidth? number Non-negative maximum width in meters; omitted means no limit.
---@field MaxMargin? number Non-negative maximum margin per end in meters; omitted means no limit.

--- Snapshot of manual or automatically calculated spacing.
-- @type GRID.ResolutionInfo
-- @field #string Mode manual or automatic.
-- @field #string Resolution Selected GRID.Resolution preset, or nil in manual mode.
-- @field #string Status configured, pending, resolved, built or cell_limit.
-- @field #number Spacing Effective center spacing in meters; nil while automatic calculation is pending.
-- @field #number CrossSpacing Effective rectangular cross spacing; nil for hexagons or while pending.
-- @field #number ReferenceLength Shorter positive initial extent in meters; nil for manual spacing.
-- @field #number Intervals Number of spacings across the reference extent: 10, 20 or 40.
-- @field #number MaxCells Current candidate-cell budget; never increased by automatic resolution.
-- @field #number CandidateCount Current candidate count after a successful build, including expansion; nil before construction.

--- Cell text-marker configuration.
-- @type GRID.MarkGridOptions
-- @field #boolean ShowID Include cell id, default true.
-- @field #boolean ShowGridIndex Include q/r or i/j, default true.
-- @field #boolean ShowNeighbourCount Include candidate-neighbor count, default true.
-- @field #number Coalition -1 for all, 0 neutral, 1 red, 2 blue. Default -1.
-- @field #boolean ReadOnly Prevent manual removal, default true.
-- @field #number BatchSize Maximum cells per batch, default 25.
-- @field #number Interval Simulation seconds between batches, default 0.1.
-- @field #number MaxBatchSeconds Soft CPU-time budget per batch, default 0.005.

--- Read-only cell geometry. Contains no ASTAR search state.
-- @type GRID.Cell
-- @field #number id Stable cell ID.
-- @field Core.Vector#VECTOR vector Position, treated as immutable.
-- @field #number surfacetype Sampled DCS surface type.
-- @field #number i Rectangular row index.
-- @field #number j Rectangular column index.
-- @field #number q Hex axial coordinate.
-- @field #number r Hex axial coordinate.
-- @field #table rectGrid Shared rectangular drawing geometry.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create an empty independent grid with a name and fixed geometry type.
-- @param #GRID self
-- @param #string Name Required non-empty grid name.
-- @param #string GridType Required GRID.Type.RECTANGLE or GRID.Type.HEXAGON.
-- @return #GRID self
function GRID:New(Name, GridType)

  assert(type(Name)=="string" and Name:find("%S"), "GRID: a non-empty name is required")
  assert(GridType==GRID.Type.RECTANGLE or GridType==GRID.Type.HEXAGON, "GRID: a valid GRID.Type is required")
  
  local self=BASE:Inherit(self, BASE:New())
  
  self.name=Name
  self.GridType=GridType
  self.lid="GRID "..self.name.." | "
  self.cells={}
  self._CellOwner={}
  self.CellList={}
  self.counter=1
  self.CellCount=0
  self.Version=0
  
  return self
end

--- Invalidate geometric caches and increment the grid mutation version.
-- Existing samples and cell IDs are retained during expansion.
-- @param #GRID self
-- @return #nil No return value.
function GRID:_Touch()

  self.Version=self.Version+1
  self.gridLinks=nil

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Grid bounds
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set the origin and orientation of a corridor before construction. Inputs are copied.
-- @param #GRID self
-- @param Core.Vector#VECTOR Start Start position (also accepts COORDINATE, Vec2 or Vec3).
-- @param Core.Vector#VECTOR Goal End position (also accepts COORDINATE, Vec2 or Vec3).
-- @return #GRID self.
function GRID:SetBounds(Start, Goal)

  assert(not self.GridBuilt, "GRID: bounds cannot change after creation")
  assert(Start and Goal, "GRID: both corridor bounds are required")
  local first, last=self:_PositionVector(Start), self:_PositionVector(Goal)
  self.startVector=first
  self.endVector=last
  self._ResolutionInfo=nil
  self:_Touch()
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Geometry and configuration helpers
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Six axial offsets; adjacent centers are one spacing apart.
local hexDirections={{1, 0}, {0, 1}, {-1, 1}, {-1, 0}, {0, -1}, {1, -1}}

--- Start a CPU-time measurement when DCS exposes os.clock.
-- Does not substitute simulation time when the os library is sanitized.
-- @return #table Clock state with read and start fields, or nil if unavailable.
local function startCPUClock()
  if os and type(os.clock)=="function" then
    return {read=os.clock, start=os.clock()}
  end
end

--- Read the non-negative elapsed CPU time of a measurement.
-- @param #table clock (Optional) Clock state returned by startCPUClock().
-- @return #number Elapsed CPU seconds, or nil when no clock is available.
local function elapsedCPU(clock)
  if clock then
    return math.max(0, clock.read()-clock.start)
  end
end

--- Format a CPU duration for diagnostic log messages.
-- @param #number seconds (Optional) Measured CPU seconds; nil indicates an unavailable clock.
-- @return #string Formatted duration or an unavailable-clock message.
local function cpuTimeText(seconds)
  return seconds and string.format("CPU time %.6f sec", seconds) or "CPU time unavailable"
end

--- Validate finite, non-negative grid width and margin values.
-- Raises an error when either dimension is invalid.
-- @param #GRID self
-- @param #number width Total corridor width in meters.
-- @param #number margin Margin before start and after goal in meters.
-- @return #nil No return value.
function GRID:_CheckGridDimensions(width, margin)

  assert(type(width)=="number" and width>=0 and width<math.huge, "GRID: Width must be finite and non-negative")
  assert(type(margin)=="number" and margin>=0 and margin<math.huge, "GRID: Margin must be finite and non-negative")

end

--- Validate and copy grid options, including nested expansion settings.
-- Unknown keys and invalid values raise an error.
-- @param #GRID self
-- @param #GRID.GridOptions options (Optional) Settings to copy; nil produces an empty table.
-- @return #GRID.GridOptions Independent copy without default values.
function GRID:_CopyGridOptions(options)

  if options==nil then
    return {}
  end
  assert(type(options)=="table", "GRID: grid options must be a table")
  local copy={}
  for key, value in pairs(options) do
    if key=="Expansion" then
      assert(type(value)=="table", "GRID: Expansion must be a table")
      copy.Expansion={}
      for name, setting in pairs(value) do
        if name=="GrowthFactor" then
          assert(type(setting)=="number" and setting>1 and setting<math.huge, "GRID: GrowthFactor must be finite and greater than one")
        elseif name=="MaxAttempts" then
          assert(type(setting)=="number" and setting>=1 and setting<math.huge and setting==math.floor(setting), "GRID: MaxAttempts must be a positive integer")
        elseif name=="MaxWidth" or name=="MaxMargin" then
          assert(type(setting)=="number" and setting>=0 and setting<math.huge, "GRID: "..name.." must be finite and non-negative")
        else
          error("GRID: unknown expansion option '"..tostring(name).."'")
        end
        copy.Expansion[name]=setting
      end
    elseif key=="Resolution" then
      assert(value==GRID.Resolution.COARSE or value==GRID.Resolution.NORMAL or value==GRID.Resolution.FINE,
        "GRID: invalid resolution; use GRID.Resolution.COARSE, NORMAL or FINE")
      copy[key]=value
    elseif key=="Diagonals" then
      assert(type(value)=="boolean", "GRID: Diagonals must be a boolean")
      copy[key]=value
    elseif key=="Width" or key=="Margin" then
      local preset=key=="Width" and (value==GRID.Width.NARROW or value==GRID.Width.NORMAL or value==GRID.Width.WIDE)
        or key=="Margin" and (value==GRID.Margin.SMALL or value==GRID.Margin.NORMAL or value==GRID.Margin.LARGE)
      assert(preset or (type(value)=="number" and value>=0 and value<math.huge),
        "GRID: "..key.." must be finite and non-negative meters or a valid GRID."..key.." preset")
      copy[key]=value
    elseif key=="Spacing" or key=="CrossSpacing" then
      assert(type(value)=="number" and value>0 and value<math.huge, "GRID: "..key.." must be finite and positive")
      copy[key]=value
    elseif key=="MaxCells" then
      assert(type(value)=="number" and value>=1 and value<math.huge and value==math.floor(value), "GRID: MaxCells must be a positive integer")
      copy[key]=value
    else
      error("GRID: unknown grid option '"..tostring(key).."'")
    end
  end
  assert(not copy.Resolution or (copy.Spacing==nil and copy.CrossSpacing==nil),
    "GRID: Resolution cannot be combined with Spacing or CrossSpacing")
  return copy

end

--- Resolve grid configuration by validating options and applying defaults.
-- @param #GRID self
-- @param #GRID.GridOptions options (Optional) Explicit settings; nil uses defaults.
-- @return #GRID.GridOptions Independent effective configuration, including expansion defaults.
function GRID:_ResolveGridOptions(options)

  local saved=self:_CopyGridOptions(options)
  local expansion=saved.Expansion or {}
  local result={Width=saved.Width or 40000, Margin=saved.Margin or 10000,
    Spacing=saved.Spacing or 2000, CrossSpacing=saved.CrossSpacing, Diagonals=saved.Diagonals~=false, MaxCells=saved.MaxCells or 5000}
  result.Resolution=saved.Resolution
  if saved.Resolution then result.Spacing=nil end
  result.Expansion={GrowthFactor=expansion.GrowthFactor or 1.5, MaxAttempts=expansion.MaxAttempts or 5,
    MaxWidth=expansion.MaxWidth, MaxMargin=expansion.MaxMargin}
  return result

end

--- Transform grid-local offsets into horizontal DCS world coordinates.
-- @param #GRID self
-- @param #table grid Geometry containing the orientation values cos and sin.
-- @param #number along Longitudinal offset in meters.
-- @param #number across Transverse offset in meters.
-- @param #table origin (Optional) World origin with x and z fields; defaults to grid.
-- @return #number World x coordinate in meters.
-- @return #number World z coordinate in meters.
function GRID:_GridPosition(grid, along, across, origin)

  origin=origin or grid
  return origin.x+along*grid.cos-across*grid.sin, origin.z+along*grid.sin+across*grid.cos

end


--- Calculate inclusive axial row bounds for a centered hex corridor.
-- Includes boundary centers using a small floating-point tolerance.
-- @param #GRID self
-- @param #table grid Hex geometry containing rowSpacing in meters.
-- @param #number width Total corridor width in meters.
-- @return #number Minimum axial row index r.
-- @return #number Maximum axial row index r.
function GRID:_HexRowBounds(grid, width)

  -- Include centers on a boundary despite floating-point rounding in axial coordinates.
  return math.ceil(-width/2/grid.rowSpacing-1e-9), math.floor(width/2/grid.rowSpacing+1e-9)

end

--- Calculate inclusive axial column bounds for one hex row.
-- @param #GRID self
-- @param #table grid Hex geometry containing spacing and corridor distance in meters.
-- @param #number margin Margin before start and after goal in meters; ignored when area is supplied.
-- @param #number r Axial row index.
-- @param #table area (Optional) Projected zone bounds with alongMin and alongMax in meters.
-- @return #number Minimum axial column index q.
-- @return #number Maximum axial column index q.
function GRID:_HexColumnBounds(grid, margin, r, area)

  local first=area and area.alongMin or -margin
  local last=area and area.alongMax or grid.distance+margin
  return math.ceil(first/grid.spacing-r/2-1e-9), math.floor(last/grid.spacing-r/2+1e-9)

end

--- Prepare hex row ranges and count candidate centers before changing the grid.
-- The count includes cells that may later be rejected by zone or surface filters.
-- @param #GRID self
-- @param #table grid Hex geometry containing spacing, rowSpacing and corridor distance.
-- @param #number width Total corridor width in meters; ignored when area is supplied.
-- @param #number margin Margin at each end in meters; ignored when area is supplied.
-- @param #number limit (Optional) Maximum candidate count; nil disables the budget check.
-- @param #table area (Optional) Projected zone bounds with alongMin, alongMax, acrossMin and acrossMax.
-- @return #table Bounds with rmin, rmax, count and per-row qmin/qmax; nil if the budget or safe index range is exceeded.
function GRID:_HexBounds(grid, width, margin, limit, area)

  local rmin, rmax
  if area then
    rmin=math.ceil(area.acrossMin/grid.rowSpacing-1e-9)
    rmax=math.floor(area.acrossMax/grid.rowSpacing+1e-9)
  else
    rmin, rmax=self:_HexRowBounds(grid, width)
  end
  if not self:_ValidIndexRange(rmin, rmax) then
    return nil
  end
  local bounds={rmin=rmin, rmax=rmax, count=0}
  local rows=math.max(0, rmax*1.0-rmin+1)
  if rows==0 then
    return bounds
  end
  -- Column counts repeat every two rows. Preflight in constant time, including long empty strips.
  local qmin, qmax=self:_HexColumnBounds(grid, margin, rmin, area)
  if not self:_ValidIndexRange(qmin, qmax) then
    return nil
  end
  local firstCount=math.max(0, qmax*1.0-qmin+1)
  local secondCount=0
  if rows>1 then
    qmin, qmax=self:_HexColumnBounds(grid, margin, rmin+1, area)
    if not self:_ValidIndexRange(qmin, qmax) then
      return nil
    end
    secondCount=math.max(0, qmax*1.0-qmin+1)
  end
  bounds.count=math.ceil(rows/2)*firstCount+math.floor(rows/2)*secondCount
  if limit and bounds.count>limit then
    return nil
  end
  if bounds.count==0 then
    bounds.rmax=rmin-1
    return bounds
  end
  bounds.count=0
  for r=rmin, rmax do
    qmin, qmax=self:_HexColumnBounds(grid, margin, r, area)
    if not self:_ValidIndexRange(qmin, qmax) then
      return nil
    end
    bounds.count=bounds.count+math.max(0, qmax*1.0-qmin+1)
    if limit and bounds.count>limit then
      return nil
    end
    bounds[r]={qmin=qmin, qmax=qmax}
  end
  return bounds

end

--- Calculate rectangular index ranges and count candidate centers before filtering.
-- Indices remain anchored to the initial lattice, including fractional initial margins.
-- @param #GRID self
-- @param #table grid Rectangular geometry containing spacing, crossSpacing, offsets and corridor distance.
-- @param #number width Total corridor width in meters; ignored when area is supplied.
-- @param #number margin Margin at each end in meters; ignored when area is supplied.
-- @param #number limit (Optional) Maximum candidate count; nil disables the budget check.
-- @param #table area (Optional) Projected zone bounds with alongMin, alongMax, acrossMin and acrossMax.
-- @return #table Bounds with imin, imax, jmin, jmax and count; nil if the budget or safe index range is exceeded.
function GRID:_RectBounds(grid, width, margin, limit, area)

  local acrossMin=area and area.acrossMin or -width/2
  local acrossMax=area and area.acrossMax or width/2
  local alongMin=area and area.alongMin or -margin
  local alongMax=area and area.alongMax or grid.distance+margin
  local bounds={
    imin=math.ceil((acrossMin-grid.acrossOffset)/grid.crossSpacing-1e-9),
    imax=math.floor((acrossMax-grid.acrossOffset)/grid.crossSpacing+1e-9),
    jmin=math.ceil((alongMin-grid.alongOffset)/grid.spacing-1e-9),
    jmax=math.floor((alongMax-grid.alongOffset)/grid.spacing+1e-9)}
  if not self:_ValidIndexRange(bounds.imin, bounds.imax) or not self:_ValidIndexRange(bounds.jmin, bounds.jmax) then
    return nil
  end
  local nx=math.max(0, bounds.imax*1.0-bounds.imin+1)
  local nz=math.max(0, bounds.jmax*1.0-bounds.jmin+1)
  if limit and nz>0 and nx>limit/nz then
    return nil
  end
  bounds.count=nx*nz
  if bounds.count==0 then
    bounds.imax=bounds.imin-1
    bounds.jmax=bounds.jmin-1
  end
  return bounds

end

--- Calculate candidate bounds for the current grid geometry and requested dimensions.
-- Requires an existing rectangular or hex grid.
-- @param #GRID self
-- @param #number width Requested total width in meters.
-- @param #number margin Requested margin at each end in meters.
-- @param #number limit (Optional) Maximum candidate count; nil disables the budget check.
-- @return #table Geometry-specific index bounds and count; nil if the limit is exceeded.
function GRID:_ExpansionBounds(width, margin, limit)

  if self.hexGrid then
    return self:_HexBounds(self.hexGrid, width, margin, limit)
  end
  return self:_RectBounds(self.rectGrid, width, margin, limit)

end

--- Determine the grid frame and projected bounding box of a MOOSE zone.
-- Uses SetBounds() when available; otherwise uses the zone bounds center and heading zero.
-- Reads polygon bounds or derives radius-zone bounds. Actual membership is checked later through IsVec2InZone().
-- @param #GRID self
-- @param Core.Zone#ZONE_BASE zone Circle, rectangle or polygon zone providing membership and bounding geometry.
-- @return #table Grid frame with x, z, cos, sin and corridor distance.
-- @return #table Projected bounds with alongMin, alongMax, acrossMin and acrossMax in meters.
function GRID:_ZoneGridArea(zone)

  assert(type(zone)=="table" and type(zone.IsVec2InZone)=="function", "GRID: a MOOSE zone with IsVec2InZone is required")
  local box=type(zone.GetBoundingSquare)=="function" and zone:GetBoundingSquare() or nil
  if not box and type(zone.GetRadius)=="function" and type(zone.GetVec2)=="function" then
    local center, radius=zone:GetVec2(), zone:GetRadius()
    assert(type(center)=="table" and type(center.x)=="number" and type(center.y)=="number"
      and type(radius)=="number" and radius>=0 and radius<math.huge, "GRID: invalid radius zone geometry")
    box={x1=center.x-radius, y1=center.y-radius, x2=center.x+radius, y2=center.y+radius}
  end
  assert(type(box)=="table", "GRID: zone must provide polygon bounds or a center and radius")
  for _, key in ipairs({"x1", "y1", "x2", "y2"}) do
    local value=box[key]
    assert(type(value)=="number" and value>-math.huge and value<math.huge, "GRID: invalid zone bounding box")
  end
  assert(box.x1<=box.x2 and box.y1<=box.y2, "GRID: invalid zone bounding box order")
  local first, last=self.startVector, self.endVector
  if not first then
    first=VECTOR:New((box.x1+box.x2)/2, 0, (box.y1+box.y2)/2)
    last=first
  end
  local distance=first:GetDistance(last, true)
  local angle=distance>0 and math.rad(first:GetHeadingTo(last)) or 0
  local grid={x=first.x, z=first.z, cos=math.cos(angle), sin=math.sin(angle), distance=distance}
  local area={alongMin=math.huge, alongMax=-math.huge, acrossMin=math.huge, acrossMax=-math.huge}
  for _, point in ipairs({{box.x1, box.y1}, {box.x1, box.y2}, {box.x2, box.y1}, {box.x2, box.y2}}) do
    local dx, dz=point[1]-grid.x, point[2]-grid.z
    local along, across=dx*grid.cos+dz*grid.sin, -dx*grid.sin+dz*grid.cos
    area.alongMin=math.min(area.alongMin, along)
    area.alongMax=math.max(area.alongMax, along)
    area.acrossMin=math.min(area.acrossMin, across)
    area.acrossMax=math.max(area.acrossMax, across)
  end
  return grid, area

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Grid configuration
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Configure accepted DCS surface types before building a grid. Nil accepts all surfaces; an empty list accepts none.
-- Takes a single surface type or a list, copied on input. A successful grid build locks the filter, even if no cells passed it.
-- @param #GRID self
-- @param #table SurfaceTypes (Optional) DCS surface types; also accepts a single number.
-- @return #GRID self
---@param SurfaceTypes? number|number[]
---@return GRID
function GRID:SetValidSurfaceTypes(SurfaceTypes)

  assert(not self.GridBuilt, "GRID: surface types cannot change after grid creation; use a new GRID object")
  local function check(value)
    assert(type(value)=="number" and value>=1 and value<=5 and value==math.floor(value), "GRID: invalid DCS surface type")
  end
  local copy
  if type(SurfaceTypes)=="number" then
    check(SurfaceTypes)
    copy=SurfaceTypes
  elseif SurfaceTypes~=nil then
    assert(type(SurfaceTypes)=="table", "GRID: surface types must be a number or list")
    copy={}
    local count=0
    for key, value in pairs(SurfaceTypes) do
      assert(type(key)=="number" and key>=1 and key==math.floor(key), "GRID: surface types must be a sequential list")
      check(value)
      copy[key]=value
      count=count+1
    end
    for i=1, count do
      assert(copy[i]~=nil, "GRID: surface types must be a sequential list")
    end
  end
  self.ValidSurfaceTypes=copy
  self:_Touch()
  return self

end

--- Validate and replace the complete internal option snapshot atomically. Does not build or draw anything.
-- Used by partial updates and dedicated setters so removed optional values do not survive a merge.
-- After grid creation Width, Margin, Spacing, CrossSpacing and Resolution are locked; Diagonals and limits may still change.
-- Lowering MaxCells below the existing grid size makes an expanding search return cell_limit without searching.
-- @param #GRID self
-- @param #GRID.GridOptions Options (Optional) Grid settings, including the nested Expansion table.
-- @return #GRID self
---@param Options? GRID.GridOptions
---@return GRID
function GRID:_SetOptions(Options)

  local saved=self:_CopyGridOptions(Options)
  assert(self.GridType~=GRID.Type.HEXAGON or saved.CrossSpacing==nil, "GRID: CrossSpacing is only supported by rectangular grids")
  local proposed=self:_ResolveGridOptions(saved)
  if self.GridBuilt then
    local current=self:GetOptions()
    for _, key in ipairs({"Width", "Margin", "Spacing", "CrossSpacing", "Resolution"}) do
      assert(proposed[key]==current[key], "GRID: "..key.." cannot change after grid creation; use a new GRID object")
    end
    assert(not self.hexGrid or saved.CrossSpacing==nil, "GRID: CrossSpacing is only supported by rectangular grids")
  end
  if self.rectGrid and proposed.Diagonals~=self:GetOptions().Diagonals then
    self.gridLinks=nil
  end
  self.GridOptions=saved
  if not self.GridBuilt then self._ResolutionInfo=nil end
  self:_Touch()
  return self

end

--- Update only supplied grid options, preserving omitted fields, including nested Expansion fields.
-- Resolution selects automatic spacing; Spacing or CrossSpacing selects manual spacing.
-- A single update cannot contain both modes. Nil or an empty table leaves the configuration unchanged.
-- Use the dedicated setters to clear optional values, or ResetOptions() to restore all defaults.
-- Geometry remains locked after construction; validation errors leave the configuration unchanged.
-- @param #GRID self
-- @param #GRID.GridOptions Options (Optional) Partial configuration to merge.
-- @return #GRID self.
---@param Options? GRID.GridOptions
---@return GRID
function GRID:SetOptions(Options)

  local update=self:_CopyGridOptions(Options)
  if next(update)==nil then return self end
  local saved=self:_CopyGridOptions(self.GridOptions)
  if update.Resolution then
    saved.Spacing=nil
    saved.CrossSpacing=nil
  elseif update.Spacing or update.CrossSpacing then
    saved.Resolution=nil
  end
  for key, value in pairs(update) do
    if key=="Expansion" then
      saved.Expansion=saved.Expansion or {}
      for name, setting in pairs(value) do saved.Expansion[name]=setting end
    else
      saved[key]=value
    end
  end
  return self:_SetOptions(saved)

end

--- Restore all grid option defaults, leaving bounds and surface filters unchanged.
-- After construction this is rejected if it would change locked geometry; use a new GRID in that case.
-- @param #GRID self
-- @return #GRID self.
---@return GRID
function GRID:ResetOptions()

  return self:_SetOptions({})

end

--- Select manual center spacing and disable automatic resolution, preserving other options.
-- The transverse spacing is supported only by rectangular grids. Changing spacing after creation is rejected.
-- @param #GRID self
-- @param #number Spacing (Optional) Positive center spacing in meters; nil restores the 2000-meter default.
-- @param #number CrossSpacing (Optional) Positive transverse spacing in meters; nil uses Spacing and removes any previous override.
-- @return #GRID self.
---@param Spacing? number
---@param CrossSpacing? number
---@return GRID
function GRID:SetSpacing(Spacing, CrossSpacing)

  local options=self:_CopyGridOptions(self.GridOptions)
  options.Resolution=nil
  options.Spacing=Spacing
  options.CrossSpacing=CrossSpacing
  return self:_SetOptions(options)

end

--- Set the shared candidate-cell budget without changing geometry or resolution.
-- Counts candidate centers before surface and zone filtering. May change after construction.
-- @param #GRID self
-- @param #number MaxCells (Optional) Positive integer candidate limit; nil restores 5000.
-- @return #GRID self.
---@param MaxCells? integer
---@return GRID
function GRID:SetMaxCells(MaxCells)

  local options=self:_CopyGridOptions(self.GridOptions)
  options.MaxCells=MaxCells
  return self:_SetOptions(options)

end

--- Enable or disable direct diagonal neighbours for rectangles, preserving other options.
-- May change after construction; neighbour links are rebuilt on demand. Ignored by hex grids.
-- @param #GRID self
-- @param #boolean Diagonals (Optional) True for eight neighbours, false for four; nil restores true.
-- @return #GRID self.
---@param Diagonals? boolean
---@return GRID
function GRID:SetDiagonals(Diagonals)

  local options=self:_CopyGridOptions(self.GridOptions)
  options.Diagonals=Diagonals
  return self:_SetOptions(options)

end

--- Replace all expansion settings without changing other grid options or starting a search.
-- Omitted limits remove previous limits. May change after construction; MaxCells remains an independent budget.
-- @param #GRID self
-- @param #number GrowthFactor (Optional) Finite multiplier greater than 1; default 1.5.
-- @param #number MaxAttempts (Optional) Positive integer number of search attempts including the initial search; default 5.
-- @param #number MaxWidth (Optional) Finite non-negative maximum width in meters; nil means no width limit.
-- @param #number MaxMargin (Optional) Finite non-negative maximum margin at each end in meters; nil means no margin limit.
-- @return #GRID self.
---@param GrowthFactor? number
---@param MaxAttempts? integer
---@param MaxWidth? number
---@param MaxMargin? number
---@return GRID
function GRID:SetExpansion(GrowthFactor, MaxAttempts, MaxWidth, MaxMargin)

  local options=self:_CopyGridOptions(self.GridOptions)
  options.Expansion={GrowthFactor=GrowthFactor, MaxAttempts=MaxAttempts, MaxWidth=MaxWidth, MaxMargin=MaxMargin}
  return self:_SetOptions(options)

end

--- Return an independent copy of effective grid settings, including expansion defaults.
-- CrossSpacing is nil unless explicitly configured; rectangular builders then use Spacing.
-- In automatic mode Spacing and CrossSpacing stay nil; GetResolutionInfo() exposes the calculated distances.
-- Width and Margin retain their configured presets; GetDimensions() exposes current meter values after construction.
-- @param #GRID self
-- @return #GRID.GridOptions Configuration copy.
---@return GRID.GridOptions
function GRID:GetOptions()

  return self:_ResolveGridOptions(self.GridOptions)

end

--- Configure initial corridor width and the margin at each end, preserving all other options.
-- Presets are evaluated from endpoint distance during CreateFromBounds(). Zone builds ignore both settings.
-- With distance D and per-end margin M, total length is D+2*M; width presets apply to that total length.
-- Explicit meter values and presets may be selected independently. Expansion uses the resulting dimensions without reevaluating presets.
-- @param #GRID self
-- @param #number Width Required non-negative total width in meters, or a GRID.Width.NARROW, NORMAL or WIDE preset.
-- @param #number Margin Required non-negative margin at each end in meters, or a GRID.Margin.SMALL, NORMAL or LARGE preset.
-- @return #GRID self.
---@param Width number|GRID.Width
---@param Margin number|GRID.Margin
---@return GRID
function GRID:SetCorridor(Width, Margin)

  assert(Width~=nil and Margin~=nil, "GRID: SetCorridor requires both width and margin")
  local options=self:_CopyGridOptions(self.GridOptions)
  options.Width=Width
  options.Margin=Margin
  return self:SetOptions(options)

end

--- Resolve initial corridor dimensions from meter values or relative presets.
-- Coincident endpoints require explicit meter values. Resolution and cell budgets do not influence these dimensions.
-- @param #GRID self
-- @param #GRID.GridOptions Options Effective grid configuration.
-- @param #number Distance Horizontal endpoint distance in meters.
-- @return #number Total width in meters, centered on the endpoint connection line.
-- @return #number Margin in meters at each end.
function GRID:_ResolveCorridorDimensions(Options, Distance)

  local width,margin=Options.Width,Options.Margin
  if type(width)=="string" or type(margin)=="string" then
    assert(Distance>0 and Distance<math.huge,
      "GRID: relative corridor dimensions require distinct endpoints with finite distance; configure Width and Margin in meters")
  end
  if type(margin)=="string" then
    local fraction=margin==GRID.Margin.SMALL and 0.1 or (margin==GRID.Margin.NORMAL and 0.25 or 0.5)
    margin=Distance*fraction
  end
  if type(width)=="string" then
    local fraction=width==GRID.Width.NARROW and 0.25 or (width==GRID.Width.NORMAL and 0.5 or 1)
    width=(Distance+2*margin)*fraction
  end
  self:_CheckGridDimensions(width,margin)
  return width,margin

end

--- Select automatic relative spacing without changing other grid options.
-- Clears explicit Spacing and CrossSpacing. Nil selects manual mode with the default spacing of 2000 meters.
-- Changing resolution after construction is rejected; expansion always retains the original spacing.
-- @param #GRID self
-- @param #string Level GRID.Resolution.COARSE, NORMAL or FINE; nil disables automatic resolution.
-- @return #GRID self.
---@param Level? GRID.Resolution
---@return GRID
function GRID:SetResolution(Level)

  local options=self:_CopyGridOptions(self.GridOptions)
  options.Resolution=Level
  options.Spacing=nil
  options.CrossSpacing=nil
  return self:_SetOptions(options)

end

--- Inspect spacing configuration and the most recent initial build calculation.
-- No terrain queries or grid mutations are performed. CandidateCount reflects the current built grid, including expansion.
-- @param #GRID self
-- @return #GRID.ResolutionInfo Independent snapshot; automatic spacing is nil until an initial build is attempted.
function GRID:GetResolutionInfo()

  local options=self:GetOptions()
  local info={}
  for key, value in pairs(self._ResolutionInfo or {}) do info[key]=value end
  info.Mode=options.Resolution and "automatic" or "manual"
  info.Resolution=options.Resolution
  info.MaxCells=options.MaxCells
  info.Status=info.Status or (options.Resolution and "pending" or "configured")
  if not options.Resolution then
    info.Spacing=options.Spacing
    info.CrossSpacing=self.GridType==GRID.Type.RECTANGLE and (options.CrossSpacing or options.Spacing) or nil
  end
  if self.GridBuilt then
    local grid=self.hexGrid or self.rectGrid
    info.Status="built"
    info.Spacing=grid.spacing
    info.CrossSpacing=grid.crossSpacing
    info.CandidateCount=self:GetCandidateCount()
  end
  return info

end

--- Resolve initial center spacing from manual options or the shorter positive extent.
-- A zero-width line uses its length; a point requires explicit spacing. The cell budget never changes this calculation.
-- @param #GRID self
-- @param #GRID.GridOptions Options Effective build options.
-- @param #number Length Longitudinal initial extent in meters.
-- @param #number Width Transverse initial extent in meters.
-- @return #number Center spacing in meters.
-- @return #number Cross spacing for rectangles; nil for hexagons.
function GRID:_ResolveInitialSpacing(Options, Length, Width)

  local spacing=Options.Spacing
  local info={Status="resolved"}
  if Options.Resolution then
    assert(type(Length)=="number" and Length>=0 and Length<math.huge
      and type(Width)=="number" and Width>=0 and Width<math.huge, "GRID: resolution requires finite non-negative extents")
    local reference=Length>0 and (Width>0 and math.min(Length,Width) or Length) or Width
    assert(reference>0, "GRID: automatic resolution requires a non-zero extent; configure explicit Spacing for a point grid")
    local intervals=Options.Resolution==GRID.Resolution.COARSE and 10 or (Options.Resolution==GRID.Resolution.FINE and 40 or 20)
    spacing=reference/intervals
    assert(spacing>0 and spacing<math.huge, "GRID: calculated spacing is outside the supported numeric range")
    info.ReferenceLength=reference
    info.Intervals=intervals
  end
  local cross=self.GridType==GRID.Type.RECTANGLE and (Options.CrossSpacing or spacing) or nil
  info.Spacing=spacing
  info.CrossSpacing=cross
  self._ResolutionInfo=info
  return spacing,cross

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Cell functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Sample a geometric cell without adding it to the grid.
-- Stores a VECTOR and samples its current surface type. A supplied VECTOR is retained by reference;
-- other position types are copied into a new VECTOR. Do not mutate a retained VECTOR after adding the cell.
-- @param #GRID self
-- @param Core.Point#COORDINATE Coordinate Cell position; also accepts VECTOR, DCS Vec2 or Vec3.
-- @return #GRID.Cell The cell.
function GRID:_CreateCell(Coordinate)

  local cell={} --#GRID.Cell

  cell.vector=VECTOR._IsVector(Coordinate) and Coordinate or VECTOR:NewFromVec(Coordinate)
  cell.surfacetype=cell.vector:GetSurfaceType()
  cell.id=self.counter
  cell._owner=self._CellOwner

  self.counter=self.counter+1

  return cell

end

--- Create a fresh COORDINATE from a cell's VECTOR position.
-- Each call returns an independent object with the cell's exact x, y and z values, including altitude.
-- The result is not cached. Changing it does not change the stored cell.
-- @param #GRID self
-- @param #GRID.Cell Cell The owned cell to convert.
-- @return Core.Point#COORDINATE A new coordinate at the cell position.
function GRID:GetCellCoordinate(Cell)

  assert(Cell and self.cells[Cell.id]==Cell, "GRID: cell must belong to this grid")
  return Cell.vector:GetCoordinate()

end

--- Add a newly sampled cell to the geometric cell set and spatial index.
-- Does not apply the grid surface filter. Adding the same cell again does not increase the cell count.
-- Invalidates grid candidate adjacency. Do not modify cell ids, grid indices or coordinates after adding a cell.
-- @param #GRID self
-- @param #GRID.Cell Cell The cell to be added.
-- @return #GRID self
function GRID:_AddCell(Cell)

  assert(type(Cell)=="table" and Cell._owner==self._CellOwner, "GRID: cell must be created by this grid")
  local existing=self.cells[Cell.id]
  assert(not existing or existing==Cell, "GRID: existing cells cannot be replaced")
  if existing then
    return self
  end
  if self.hexGrid then
    assert(Cell.q~=nil and Cell.r~=nil, "GRID: hex cells require axial indices")
    local column=self.hexIndex[Cell.q]
    assert(not column or not column[Cell.r], "GRID: axial position already occupied")
    self.hexIndex[Cell.q]=column or {}
    self.hexIndex[Cell.q][Cell.r]=Cell
  else
    assert(Cell.rectGrid==self.rectGrid and Cell.i~=nil and Cell.j~=nil, "GRID: rectangular cells require grid indices")
    local row=self.rectIndex[Cell.i]
    assert(not row or not row[Cell.j], "GRID: rectangular position already occupied")
    self.rectIndex[Cell.i]=row or {}
    self.rectIndex[Cell.i][Cell.j]=Cell
  end
  self.CellList[#self.CellList+1]=Cell
  self.CellCount=self.CellCount+1
  self.cells[Cell.id]=Cell
  self:_Touch()

  return self

end

--- Get the cell table used by shared drawing helpers.
-- ASTAR provides its own drawing adapter returning search nodes instead of geometric cells.
-- @param #GRID self
-- @return #table Cells indexed by ID; internal mutable reference.
function GRID:_GetGridCells()

  return self.cells

end

--- Count geometric neighbours for the shared marker renderer.
-- @param #GRID self
-- @param #GRID.Cell Cell Owned cell.
-- @return #number Neighbour count.
function GRID:_GetGridNeighbourCount(Cell)

  return self:GetNeighbourCount(Cell)

end

--- Get the result-field name for a cell drawing or marker counter.
-- ASTAR overrides this adapter to retain its search-node result fields.
-- @param #GRID self
-- @param #string Suffix Counter suffix: Queued, Drawn or Marked.
-- @return #string Cell counter field name.
function GRID:_GridResultField(Suffix)

  return "Cells"..Suffix

end

--- Get the label prefix used for cell text markers.
-- @param #GRID self
-- @return #string Cell label prefix.
function GRID:_GridElementLabel()

  return "Cell "

end

--- Check a sampled surface type against this grid's configured surface filter.
-- Performs no terrain query. An unset filter accepts all surfaces; an empty filter accepts none.
-- Used for grid cells and automatically added ASTAR endpoints.
-- @param #GRID self
-- @param #number SurfaceType DCS surface type to check.
-- @return #boolean True when the configured filter accepts the surface type.
---@param SurfaceType number
---@return boolean
function GRID:IsValidSurfaceType(SurfaceType)

  if not self.ValidSurfaceTypes then return true end
  if type(self.ValidSurfaceTypes)=="number" then return self.ValidSurfaceTypes==SurfaceType end
  for _, allowed in ipairs(self.ValidSurfaceTypes) do
    if allowed==SurfaceType then return true end
  end
  return false

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Grid creation
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check sampled terrain along a straight corridor, without requiring built grid cells.
-- Includes both endpoints, the center line and both edges. Longitudinal and transverse sample gaps never exceed Step.
-- Samples do not guarantee continuous clearance, water depth or sufficient turning room between segments.
-- @param #GRID self
-- @param Core.Vector#VECTOR Start Start position; also accepts COORDINATE, Vec2 or Vec3.
-- @param Core.Vector#VECTOR Goal Goal position; also accepts COORDINATE, Vec2 or Vec3.
-- @param #number Step (Optional) Positive finite maximum sample gap in meters; default 100.
-- @param #number CorridorWidth (Optional) Non-negative total corridor width in meters; default 0.
-- @return #boolean True if all samples satisfy the configured surface filter.
-- @return #number Distance to the last clear sample row before a blocked row, or the full distance on success.
-- @return #string sample_limit when more than one million samples would be required; returns false without terrain queries.
---@param Step? number
---@param CorridorWidth? number
function GRID:CheckSurfacePath(Start, Goal, Step, CorridorWidth)
  if Step==nil then Step=100 end
  if CorridorWidth==nil then CorridorWidth=0 end
  assert(type(Step)=="number" and Step>0 and Step<math.huge,"GRID: surface sample step must be finite and positive")
  assert(type(CorridorWidth)=="number" and CorridorWidth>=0 and CorridorWidth<math.huge,"GRID: corridor width must be finite and non-negative")
  local a,b=self:_PositionVector(Start),self:_PositionVector(Goal)
  local dx,dz=b.x-a.x,b.z-a.z
  local distance=math.sqrt(dx*dx+dz*dz)
  assert(distance<math.huge,"GRID: surface path distance must be finite")
  if not self.ValidSurfaceTypes then return true,distance end
  local rows=math.max(1,math.ceil(distance/Step))
  -- An even number of transverse intervals includes the center line as well as both edges.
  local columns=distance>0 and 2*math.ceil(CorridorWidth/(2*Step)) or 0
  if (rows+1)*(columns+1)>1000000 then return false,0,"sample_limit" end
  local nx,nz=0,0
  if distance>0 then nx=-dz/distance nz=dx/distance end
  for i=0,rows do
    local fraction=i/rows
    for j=0,columns do
      local offset=columns>0 and CorridorWidth*(j/columns-0.5) or 0
      local surface=land.getSurfaceType({x=a.x+dx*fraction+nx*offset,y=a.z+dz*fraction+nz*offset})
      if not self:IsValidSurfaceType(surface) then return false,math.max(0,(i-1)*distance/rows) end
    end
  end
  return true,distance
end

--- Build the configured geometry in a corridor between two positions.
-- Uses SetOptions() and SetValidSurfaceTypes(); creates no drawings or markers.
-- @param #GRID self
-- @param Core.Vector#VECTOR Start Corridor start; also accepts COORDINATE, Vec2 or Vec3.
-- @param Core.Vector#VECTOR Goal Corridor goal; also accepts COORDINATE, Vec2 or Vec3.
-- @return #GRID self, or nil when the candidate-cell budget would be exceeded.
-- @return #string cell_limit on budget rejection; nil on success.
function GRID:CreateFromBounds(Start, Goal)

  self:SetBounds(Start, Goal)
  local built,reason
  if self.GridType==GRID.Type.HEXAGON then built,reason=self:_CreateHexagon()
  else built,reason=self:_CreateRectangle() end
  if self._ResolutionInfo then self._ResolutionInfo.Status=built and "built" or reason end
  return built,reason

end

--- Build the configured geometry inside a circle, rectangle or polygon zone.
-- SetBounds() optionally supplies the frame; otherwise the zone bounds determine it.
-- Surface filtering applies to cell centers. Later expansion may leave the initial zone.
-- @param #GRID self
-- @param Core.Zone#ZONE_BASE Zone Initial zone; Width and Margin are ignored for this build.
-- @return #GRID self, or nil when the candidate-cell budget would be exceeded.
-- @return #string cell_limit on budget rejection; nil on success.
function GRID:CreateFromZone(Zone)

  assert(not self.GridBuilt, "GRID: a grid already exists; use a new GRID object")
  self._ResolutionInfo=nil
  local built,reason
  if self.GridType==GRID.Type.HEXAGON then built,reason=self:_CreateHexagonFromZone(Zone)
  else built,reason=self:_CreateRectangleFromZone(Zone) end
  if self._ResolutionInfo then self._ResolutionInfo.Status=built and "built" or reason end
  return built,reason

end

--- Build a rectangular grid using SetOptions() and SetValidSurfaceTypes().
-- Requires SetBounds() and no prior grid. Generated centers have altitude zero.
-- No markers are created; call DrawGrid() or MarkGrid() explicitly.
-- @param #GRID self
-- @return #GRID self, or nil if MaxCells would be exceeded before surface filtering.
-- @return #string cell_limit on budget rejection; no cells are added on rejection.
function GRID:_CreateRectangle()

  assert(self.GridType==GRID.Type.RECTANGLE, "GRID: builder does not match the configured geometry")
  assert(not self.GridBuilt, "GRID: a grid already exists; use a new GRID object")
  assert(self.startVector and self.endVector, "GRID: start and end coordinates are required for a grid")
  local options=self:GetOptions()
  local MaxCells=options.MaxCells
  local distance=self.startVector:GetDistance(self.endVector, true)
  local Width,Margin=self:_ResolveCorridorDimensions(options,distance)
  local Spacing,CrossSpacing=self:_ResolveInitialSpacing(options,distance+2*Margin,Width)
  -- Match the original numeric-for loop counts even when dimensions are not spacing multiples.
  local nx=math.floor(Width/CrossSpacing+1)
  local nz=math.floor((distance+2*Margin)/Spacing+1)
  if not self:_ValidIndexRange(1, nx) or not self:_ValidIndexRange(1, nz) or nx>MaxCells/nz then
    return nil, "cell_limit"
  end

  local angle=math.rad(self.startVector:GetHeadingTo(self.endVector))
  self.rectGrid={x=self.startVector.x, z=self.startVector.z, cos=math.cos(angle), sin=math.sin(angle),
    along=Spacing/2, across=CrossSpacing/2, spacing=Spacing, crossSpacing=CrossSpacing, distance=distance,
    alongOffset=-Margin-Spacing, acrossOffset=-Width/2-CrossSpacing}
  self.rectIndex={}
  self:_PopulateRectGrid({imin=1, imax=nx, jmin=1, jmax=nz, count=nx*nz}, Width, Margin)
  self:T(self.lid..string.format("Built rectangular grid with %d total cells", self.CellCount))
  return self

end

--- Build an initial hex grid using SetOptions() and SetValidSurfaceTypes().
-- Requires SetBounds() and an empty cell set. CrossSpacing is not supported. Centers have altitude zero.
-- Neighbour queries use six-neighbour topology. No drawing is performed.
-- @param #GRID self
-- @return #GRID self, or nil if MaxCells would be exceeded before surface filtering.
-- @return #string cell_limit on budget rejection; no cells are added on rejection.
function GRID:_CreateHexagon()

  assert(self.GridType==GRID.Type.HEXAGON, "GRID: builder does not match the configured geometry")
  assert(not self.GridBuilt and next(self.cells)==nil, "GRID: create a hex grid on an empty GRID object")
  assert(self.startVector and self.endVector, "GRID: start and end coordinates are required for a hex grid")
  local options=self:GetOptions()
  assert(options.CrossSpacing==nil, "GRID: CrossSpacing is only supported by rectangular grids")
  local MaxCells=options.MaxCells

  local distance=self.startVector:GetDistance(self.endVector, true)
  local Width,Margin=self:_ResolveCorridorDimensions(options,distance)
  local Spacing=self:_ResolveInitialSpacing(options,distance+2*Margin,Width)
  local angle=distance>0 and math.rad(self.startVector:GetHeadingTo(self.endVector)) or 0
  local grid={x=self.startVector.x, z=self.startVector.z, cos=math.cos(angle), sin=math.sin(angle), spacing=Spacing,
    rowSpacing=Spacing*math.sqrt(3)/2, distance=distance}
  local bounds=self:_HexBounds(grid, Width, Margin, MaxCells)
  if not bounds then
    return nil, "cell_limit"
  end

  self.hexGrid=grid
  self.hexIndex={}
  self:_PopulateHexGrid(bounds, Width, Margin)
  self:T(self.lid..string.format("Built hex grid with %d cells, spacing %.1f m", self.CellCount, Spacing))
  return self

end

--- Build initial hex centers inside a MOOSE circle, rectangle or polygon zone.
-- Uses SetBounds() when supplied, otherwise the zone bounds center. Uses configured Spacing, MaxCells and surface types; ignores Width and Margin.
-- Checks the zone before terrain sampling. Expansion can subsequently leave the zone. CrossSpacing is rejected.
-- @param #GRID self
-- @param Core.Zone#ZONE_BASE Zone Initial zone.
-- @return #GRID self, or nil if the projected bounding-box candidates exceed MaxCells before either filter.
-- @return #string cell_limit on budget rejection.
function GRID:_CreateHexagonFromZone(Zone)

  assert(self.GridType==GRID.Type.HEXAGON, "GRID: builder does not match the configured geometry")
  assert(not self.GridBuilt and next(self.cells)==nil, "GRID: create a hex grid on an empty GRID object")
  local options=self:GetOptions()
  assert(options.CrossSpacing==nil, "GRID: CrossSpacing is only supported by rectangular grids")
  local MaxCells=options.MaxCells
  local grid, area=self:_ZoneGridArea(Zone)
  local Spacing=self:_ResolveInitialSpacing(options,area.alongMax-area.alongMin,area.acrossMax-area.acrossMin)
  grid.spacing=Spacing
  grid.rowSpacing=Spacing*math.sqrt(3)/2
  local width=2*math.max(math.abs(area.acrossMin), math.abs(area.acrossMax))
  local margin=math.max(0, -area.alongMin, area.alongMax-grid.distance)
  self:_CheckGridDimensions(width, margin)
  local bounds=self:_HexBounds(grid, width, margin, MaxCells, area)
  if not bounds then
    return nil, "cell_limit"
  end
  self.hexGrid=grid
  self.hexIndex={}
  self:_PopulateHexGrid(bounds, width, margin, Zone)
  self:T(self.lid..string.format("Built zone hex grid with %d cells, spacing %.1f m", self.CellCount, Spacing))
  return self

end

--- Build rectangular centers inside a MOOSE circle, rectangle or polygon zone.
-- Requires no prior grid; SetBounds() optionally supplies the orientation. Uses configured spacing, MaxCells and surface types; ignores Width and Margin.
-- Checks the zone before terrain sampling. Expansion can subsequently leave the zone. No drawing is performed.
-- @param #GRID self
-- @param Core.Zone#ZONE_BASE Zone Initial zone.
-- @return #GRID self, or nil if the projected bounding-box candidates exceed MaxCells before either filter.
-- @return #string cell_limit on budget rejection.
function GRID:_CreateRectangleFromZone(Zone)

  assert(self.GridType==GRID.Type.RECTANGLE, "GRID: builder does not match the configured geometry")
  assert(not self.GridBuilt, "GRID: a grid already exists; use a new GRID object")
  local options=self:GetOptions()
  local MaxCells=options.MaxCells
  local grid, area=self:_ZoneGridArea(Zone)
  local Spacing,CrossSpacing=self:_ResolveInitialSpacing(options,area.alongMax-area.alongMin,area.acrossMax-area.acrossMin)
  grid.along=Spacing/2
  grid.across=CrossSpacing/2
  grid.spacing=Spacing
  grid.crossSpacing=CrossSpacing
  grid.alongOffset=0
  grid.acrossOffset=0
  local width=2*math.max(math.abs(area.acrossMin), math.abs(area.acrossMax))
  local margin=math.max(0, -area.alongMin, area.alongMax-grid.distance)
  self:_CheckGridDimensions(width, margin)
  local bounds=self:_RectBounds(grid, width, margin, MaxCells, area)
  if not bounds then
    return nil, "cell_limit"
  end
  self.rectGrid=grid
  self.rectIndex={}
  self:_PopulateRectGrid(bounds, width, margin, Zone)
  self:T(self.lid..string.format("Built zone rectangular grid with %d total cells", self.CellCount))
  return self

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Grid expansion
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Enlarge the grid within its configured dimension and candidate-cell limits.
-- Retains cell IDs, sampled surfaces, spacing and orientation. Does not draw or run a search.
-- The first actual enlargement of a zone seed also fills previously unsampled holes outside the zone.
-- @param #GRID self
-- @param #number Width Requested total width in meters; cannot shrink.
-- @param #number Margin Requested margin at each end in meters; cannot shrink.
-- @param #boolean FitBudget (Optional) Fit a smaller step when MaxCells would be exceeded; default false.
-- @return #GRID self, or nil when a limit prevents expansion.
-- @return #string cell_limit or size_limit on rejection; nil on success.
-- @return #boolean True if a successful step was reduced to fit MaxCells; false otherwise.
function GRID:ExpandGrid(Width, Margin, FitBudget)

  assert(FitBudget==nil or type(FitBudget)=="boolean", "GRID: FitBudget must be a boolean")
  local grid=self.hexGrid or self.rectGrid
  assert(grid, "GRID: create a grid before expanding")
  self:_CheckGridDimensions(Width, Margin)
  assert(Width>=grid.width and Margin>=grid.margin, "GRID: grid width and margin cannot shrink")
  local options=self:GetOptions()
  if (options.Expansion.MaxWidth and Width>options.Expansion.MaxWidth)
    or (options.Expansion.MaxMargin and Margin>options.Expansion.MaxMargin) then
    return nil, "size_limit", false
  end
  if grid.candidateCount>options.MaxCells then
    return nil, "cell_limit", false
  end
  if Width==grid.width and Margin==grid.margin then
    return self, nil, false
  end
  local bounds=self:_ExpansionBounds(Width, Margin, options.MaxCells)
  local limited=false
  if not bounds and FitBudget then
    Width, Margin, bounds=self:_FitGridExpansion(Width, Margin, options.MaxCells)
    limited=true
  end
  if not bounds then
    return nil, "cell_limit", false
  end
  self:_PopulateGrid(bounds, Width, Margin)
  return self, nil, limited

end


--- Populate preflighted bounds using the current rectangular or hex geometry.
-- Retains previously sampled cells and updates dimensions, candidate count and mutation version.
-- @param #GRID self
-- @param #table Bounds Geometry-specific index ranges and candidate count, already checked against limits.
-- @param #number Width New total width in meters.
-- @param #number Margin New margin at each end in meters.
-- @return #GRID self.
function GRID:_PopulateGrid(Bounds, Width, Margin)

  if self.hexGrid then
    return self:_PopulateHexGrid(Bounds, Width, Margin)
  end
  return self:_PopulateRectGrid(Bounds, Width, Margin)

end

--- Add preflighted rectangular cells, retaining previously accepted and rejected samples.
-- @param #GRID self
-- @param #table Bounds Rectangular index ranges and candidate count.
-- @param #number Width New total width.
-- @param #number Margin New margin.
-- @param Core.Zone#ZONE_BASE Zone Optional initial zone filter.
-- @return #GRID self
function GRID:_PopulateRectGrid(Bounds, Width, Margin, Zone)

  local grid=self.rectGrid
  local old=grid.bounds
  local sampled=Zone and {} or nil
  for i=Bounds.imin, Bounds.imax do
    for j=Bounds.jmin, Bounds.jmax do
      local existingCell=old and i>=old.imin and i<=old.imax and j>=old.jmin and j<=old.jmax
      if grid.initialSamples then
        existingCell=grid.initialSamples[i] and grid.initialSamples[i][j]
      end
      if not existingCell then
        local x, z=self:_GridPosition(grid, grid.alongOffset+j*grid.spacing, grid.acrossOffset+i*grid.crossSpacing)
        if not Zone or Zone:IsVec2InZone({x=x, y=z}) then
          if sampled then
            sampled[i]=sampled[i] or {}
            sampled[i][j]=true
          end
          local cell=self:_CreateCell(VECTOR:New(x, 0, z))
          if self:IsValidSurfaceType(cell.surfacetype) then
            cell.rectGrid=grid
            cell.i=i
            cell.j=j
            self:_AddCell(cell)
          end
        end
      end
    end
  end
  grid.initialSamples=sampled
  grid.bounds=Bounds
  grid.width=Width
  grid.margin=Margin
  grid.candidateCount=Bounds.count
  self.GridCandidateCount=Bounds.count
  self.GridBuilt=true
  self:_Touch()
  return self

end

--- Fit a requested growth step to the cell budget without terrain queries.
-- First fits balanced growth, then spends remaining room on either axis. Discrete cell boundaries can leave unused budget.
-- Returns nil when no new candidate cells (or zone-seed holes) can be reached within the budget.
-- @param #GRID self
-- @param #number Width Requested width.
-- @param #number Margin Requested margin.
-- @param #number MaxCells Candidate-cell budget.
-- @return #number Fitted width in meters, or nil when no additional candidates or zone-seed holes can be reached.
-- @return #number Fitted margin at each end in meters; absent when no expansion is possible.
-- @return #table Candidate bounds for the fitted dimensions; absent when no expansion is possible.
function GRID:_FitGridExpansion(Width, Margin, MaxCells)

  local grid=self.hexGrid or self.rectGrid
  local function fit(fromWidth, fromMargin, toWidth, toMargin)
    local full=self:_ExpansionBounds(toWidth, toMargin, MaxCells)
    if full then
      return toWidth, toMargin, full
    end
    local low, high=0, 1
    local bestWidth, bestMargin, best
    for i=1, 52 do
      local fraction=(low+high)/2
      local width=fromWidth+(toWidth-fromWidth)*fraction
      local margin=fromMargin+(toMargin-fromMargin)*fraction
      local bounds=self:_ExpansionBounds(width, margin, MaxCells)
      if bounds then
        low=fraction
        bestWidth=width
        bestMargin=margin
        best=bounds
      else
        high=fraction
      end
    end
    return bestWidth, bestMargin, best
  end
  local width, margin, bounds=fit(grid.width, grid.margin, Width, Margin)
  if not bounds then
    return nil
  end
  -- Lattice counts jump at row boundaries. Use remaining room on either axis if balanced growth cannot reach it.
  local w1, m1, b1=fit(width, margin, Width, margin)
  if b1 then
    w1, m1, b1=fit(w1, m1, w1, Margin)
  end
  local w2, m2, b2=fit(width, margin, width, Margin)
  if b2 then
    w2, m2, b2=fit(w2, m2, Width, m2)
  end
  -- Also try each axis from the original bounds: the balanced prefix may have spent too much margin to fit a whole row.
  local w3, m3, b3=fit(grid.width, grid.margin, Width, grid.margin)
  if b3 then
    w3, m3, b3=fit(w3, m3, w3, Margin)
  end
  local w4, m4, b4=fit(grid.width, grid.margin, grid.width, Margin)
  if b4 then
    w4, m4, b4=fit(w4, m4, Width, m4)
  end
  for _, candidate in ipairs({{w1, m1, b1}, {w2, m2, b2}, {w3, m3, b3}, {w4, m4, b4}}) do
    local w, m, b=candidate[1], candidate[2], candidate[3]
    if b and (b.count>bounds.count or (b.count==bounds.count and w*(grid.distance+2*m)>width*(grid.distance+2*margin))) then
      width, margin, bounds=w, m, b
    end
  end
  if bounds.count>grid.candidateCount or (grid.initialSamples and (width>grid.width or margin>grid.margin)) then
    return width, margin, bounds
  end

end

--- Add the new cells from preflighted hex bounds. Used by creation and enlargement.
-- @param #GRID self
-- @param #table Bounds Axial row ranges and candidate count.
-- @param #number Width New total width.
-- @param #number Margin New margin.
-- @param Core.Zone#ZONE_BASE Zone Optional zone filter for the initial build only.
-- @return #GRID self
function GRID:_PopulateHexGrid(Bounds, Width, Margin, Zone)

  local grid=self.hexGrid
  local sampled=Zone and {} or nil
  local oldRmin, oldRmax
  if grid.width then
    oldRmin, oldRmax=self:_HexRowBounds(grid, grid.width)
  end
  for r=Bounds.rmin, Bounds.rmax do
    local row=Bounds[r]
    local oldQmin, oldQmax
    if grid.margin then
      oldQmin, oldQmax=self:_HexColumnBounds(grid, grid.margin, r)
    end
    for q=row.qmin, row.qmax do
      local existingCell=oldRmin and r>=oldRmin and r<=oldRmax and q>=oldQmin and q<=oldQmax
      -- A zone seed has unsampled holes inside its bounding rectangle. Fill them on the first real enlargement.
      if grid.initialSamples then
        existingCell=grid.initialSamples[r] and grid.initialSamples[r][q]
      end
      if not existingCell then
        local x, z=self:_GridPosition(grid, grid.spacing*(q+r/2), grid.rowSpacing*r)
        if not Zone or Zone:IsVec2InZone({x=x, y=z}) then
          if sampled then
            sampled[r]=sampled[r] or {}
            sampled[r][q]=true
          end
          local vector=VECTOR:New(x, 0, z)
          local cell=self:_CreateCell(vector)
          if self:IsValidSurfaceType(cell.surfacetype) then
            cell.q=q
            cell.r=r
            self:_AddCell(cell)

          end
        end
      end
    end
  end
  grid.bounds=Bounds
  grid.initialSamples=sampled
  grid.width=Width
  grid.margin=Margin
  grid.candidateCount=Bounds.count
  self.GridCandidateCount=Bounds.count
  self.GridBuilt=true
  self:_Touch()
  return self

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Neighbour queries
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Count direct geometric neighbours of an owned cell.
-- Uses indexed topology only; movement rules and travel costs belong to ASTAR.
-- @param #GRID self
-- @param #GRID.Cell Cell Owned cell.
-- @return #number Neighbour count.
function GRID:GetNeighbourCount(Cell)

  assert(Cell and self.cells[Cell.id]==Cell, "GRID: cell must belong to this grid")
  if not self.gridLinks then
    self:_BuildGridLinks()
  end
  local count=0
  for _ in pairs(self.gridLinks[Cell.id]) do
    count=count+1
  end
  return count

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Grid point markers
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Mark current cells with separate F10 text labels. Replaces previous text labels only; does not draw polygons.
-- Snapshot of the current cell list. Counts are evaluated when each batch runs; later additions are not marked automatically.
-- Counts use geometric adjacency only. Movement-rule checks are available through ASTAR:MarkGrid().
-- Work is batched; without a CPU clock only one marker is processed per batch.
-- @param #GRID self
-- @param #GRID.MarkGridOptions Options (Optional) Label fields, recipient and batch settings.
-- @return #GRID self. LastGridMarkResult contains Status, CellsQueued, CellsMarked, Batches and timing.
function GRID:MarkGrid(Options)

  local cells=self:_GetGridCells()
  if Options==nil then
    Options={}
  end
  assert(type(Options)=="table", "GRID: marker options must be a table")
  local style=self:_GridMarkDefaults()
  for key, value in pairs(Options) do
    assert(style[key]~=nil, "GRID: unknown marker option '"..tostring(key).."'")
    if type(style[key])=="boolean" then
      assert(type(value)=="boolean", "GRID: "..key.." must be a boolean")
    elseif key=="Coalition" then
      assert(type(value)=="number" and value>=-1 and value<=2 and value==math.floor(value), "GRID: Coalition must be -1, 0, 1 or 2")
    else
      assert(type(value)=="number" and value>0 and value<math.huge, "GRID: "..key.." must be finite and positive")
      if key=="BatchSize" then
        assert(value==math.floor(value), "GRID: BatchSize must be an integer")
      end
    end
    style[key]=value
  end
  assert(style.ShowID or style.ShowGridIndex or style.ShowNeighbourCount, "GRID: select at least one marker field")
  self:UnmarkGrid()
  local cellIDs={}
  for id in pairs(cells) do
    cellIDs[#cellIDs+1]=id
  end
  table.sort(cellIDs)
  local clock=startCPUClock()
  local job={cells=cellIDs, index=1, style=style, started=timer.getTime(),
    result={Status="queued", [self:_GridResultField("Queued")]=#cellIDs, [self:_GridResultField("Marked")]=0, Batches=0,
      CPUSeconds=clock and 0 or nil, MaxBatchCPUSeconds=clock and 0 or nil}}
  self.GridMarkJob=job
  self.LastGridMarkResult=job.result
  -- Always defer non-empty jobs; this keeps optional neighbour checks out of the caller's frame.
  if #cellIDs==0 then
    self:_FinishGridMarking(job, "complete")
  else
    job.timerID=timer.scheduleFunction(function()
      if self.GridMarkJob~=job then
        return nil
      end
      if self:_ProcessGridMarkJob(job) then
        return timer.getTime()+style.Interval
      end
    end, nil, timer.getTime()+style.Interval)
  end
  return self

end

--- Cancel pending cell labels and remove this object's text markers. Leaves grid polygons intact.
-- @param #GRID self
-- @return #GRID self
function GRID:UnmarkGrid()

  local job=self.GridMarkJob
  if job then
    if job.timerID then
      timer.removeFunction(job.timerID)
    end
    self:_FinishGridMarking(job, "cancelled")
  end
  for _, id in ipairs(self.GridMarkIDs or {}) do
    trigger.action.removeMark(id)
  end
  self.GridMarkIDs={}
  return self

end

--- Process one batch of cell text labels.
-- @param #GRID self
-- @param #table Job Marker job.
-- @return #boolean True if another batch is needed; false if finished, failed or no longer active.
function GRID:_ProcessGridMarkJob(Job)

  local cells=self:_GetGridCells()
  if self.GridMarkJob~=Job then
    return false
  end
  Job.result.Status="running"
  local clock=startCPUClock()
  local ok, err=pcall(function()
    local last=math.min(#Job.cells, Job.index+(clock and Job.style.BatchSize or 1)-1)
    while Job.index<=last do
      local cell=cells[Job.cells[Job.index]]
      if cell then
        local text={}
        local style=Job.style
        if style.ShowID then
          text[#text+1]=self:_GridElementLabel()..cell.id
        end
        if style.ShowGridIndex then
          if cell.q~=nil then
            text[#text+1]=string.format("Hex: q=%d r=%d", cell.q, cell.r)
          elseif cell.i~=nil then
            text[#text+1]=string.format("Grid: i=%d j=%d", cell.i, cell.j)
          else
            text[#text+1]="Manual / endpoint"
          end
        end
        if style.ShowNeighbourCount then
          text[#text+1]="Candidates: "..self:_GetGridNeighbourCount(cell)
          if style.CheckNeighbours then
            text[#text+1]="Valid connections: "..self:_GetGridNeighbourCount(cell, true)
          end
        end
        local id=cell.vector:Mark(table.concat(text, "\n"), style.Coalition, style.ReadOnly)
        if id then
          self.GridMarkIDs[#self.GridMarkIDs+1]=id
          Job.result[self:_GridResultField("Marked")]=Job.result[self:_GridResultField("Marked")]+1
        end
      end
      Job.index=Job.index+1
      if clock and elapsedCPU(clock)>=Job.style.MaxBatchSeconds then
        break
      end
    end
  end)
  local duration=elapsedCPU(clock)
  Job.result.Batches=Job.result.Batches+1
  if duration and Job.result.CPUSeconds then
    Job.result.CPUSeconds=Job.result.CPUSeconds+duration
    Job.result.MaxBatchCPUSeconds=math.max(Job.result.MaxBatchCPUSeconds, duration)
  else
    Job.result.CPUSeconds=nil
    Job.result.MaxBatchCPUSeconds=nil
  end
  if not ok then
    self:_FinishGridMarking(Job, "error", tostring(err))
  elseif Job.index>#Job.cells then
    self:_FinishGridMarking(Job, "complete")
  else
    return true
  end
  return false

end

--- Finish, fail or cancel a marker job.
-- @param #GRID self
-- @param #table Job Marker job.
-- @param #string Status Completion status.
-- @param #string Error Optional error detail.
-- @return #nil No return value; the job result is updated in place.
function GRID:_FinishGridMarking(Job, Status, Error)

  Job.result.Status=Status
  Job.result.Error=Error
  Job.result.ElapsedSimulationSeconds=math.max(0, timer.getTime()-Job.started)
  self.GridMarkJob=nil
  Job.timerID=nil
  if Error then
    self:E(self.lid.."Grid marking failed: "..Error)
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Grid drawing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Draw accepted grid cells on the F10 map, replacing the previous DrawGrid() overlay.
-- Draws one polygon per generated cell, with the original grid orientation. ASTAR manual nodes and extra endpoints are skipped.
-- Hex vertex radius is Spacing / sqrt(3); rectangular half-sizes are Spacing/2 and CrossSpacing/2.
-- Cells may extend beyond the search area or cover terrain rejected at other cell positions. The overlay does not show connectivity.
-- Does not change pathfinding. Large jobs are scheduled in batches; existing polygon removal and each batch run synchronously.
-- @param #GRID self
-- @param #number Coalition (Optional) All=-1, Neutral=0, Red=1, Blue=2. Default -1.
-- @param #table Color (Optional) Outline RGB values in [0,1], default {0,0,1} (blue).
-- @param #number Alpha (Optional) Outline opacity in [0,1], default 1.
-- @param #table FillColor (Optional) Fill RGB values, default the outline color.
-- @param #number FillAlpha (Optional) Fill opacity in [0,1], default 0 (transparent).
-- @param #number LineType (Optional) 0=none, 1=solid, 2=dashed, 3=dotted, 4=dot dash, 5=long dash, 6=two dash. Default 1.
-- @param #boolean ReadOnly (Optional) Prevent users from removing polygons manually. Default true.
-- @param #table DrawOptions (Optional) BatchSize=25 cells, Interval=0.1 simulation seconds, MaxBatchSeconds=0.005 CPU seconds. No CPU clock means one cell per batch.
-- @return #GRID self; large overlays may still be queued. Inspect LastGridDrawResult for progress.
function GRID:DrawGrid(Coalition, Color, Alpha, FillColor, FillAlpha, LineType, ReadOnly, DrawOptions)

  if Color==nil then Color={0, 0, 1} end
  if FillColor==nil then FillColor=Color end
  if ReadOnly==nil then
    ReadOnly=true
  end
  local style={Coalition=Coalition==nil and -1 or Coalition, Color={Color[1], Color[2], Color[3]}, Alpha=Alpha==nil and 1 or Alpha,
    FillColor={FillColor[1], FillColor[2], FillColor[3]}, FillAlpha=FillAlpha==nil and 0 or FillAlpha,
    LineType=LineType==nil and 1 or LineType, ReadOnly=ReadOnly}
  return self:_StartGridDrawing(style, DrawOptions)

end

--- Draw a one-time debug snapshot of the current grid, highlighting the supplied path's grid cells in green.
-- Uses a previously returned path; does not run a search or enable automatic drawing. Replaces this object's previous overlay.
-- ASTAR manual nodes and exact endpoints without grid cells are skipped. An empty successful path draws the grid without highlights.
-- Later searches, grid additions and UpdateGridDrawing() do not update this snapshot. Call this method again to replace it.
-- Drawing is batched; UndrawGrid() cancels pending batches and removes the snapshot.
-- @param #GRID self
-- @param #table Path Ordered cells, or ASTAR path nodes whose cell references belong to this grid. Nil or foreign cells are rejected.
-- @param #table Options (Optional) Coalition=-1, GridColor={0,0,1}, PathColor={0,1,0}, PathFillAlpha=0.35.
-- Also accepts BatchSize=25, Interval=0.1 and MaxBatchSeconds=0.005. Colors and the path selection are copied at call time.
-- @return #GRID self; inspect LastGridDrawResult for drawing progress.
function GRID:DrawGridWithPath(Path, Options)

  local cells=self:_GetGridCells()
  assert(type(Path)=="table", "GRID: DrawGridWithPath requires a successful path table")
  if Options==nil then Options={} end
  assert(type(Options)=="table", "GRID: path drawing options must be a table")
  local pathCells={}
  for _, entry in ipairs(Path) do
    -- Search-only endpoints belong to this grid but have no polygon to highlight.
    if not (type(entry)=="table" and entry.grid==self and not entry.cell) then
      if type(entry)=="table" and entry.cell and cells[entry.cell.id]==entry.cell then
        entry=entry.cell
      end
      assert(type(entry)=="table" and cells[entry.id]==entry, "GRID: path cells must belong to this grid or drawing view")
      pathCells[entry.id]=true
    end
  end
  local color=Options.GridColor==nil and {0, 0, 1} or Options.GridColor
  local pathColor=Options.PathColor==nil and {0, 1, 0} or Options.PathColor
  local fillAlpha=Options.PathFillAlpha==nil and 0.35 or Options.PathFillAlpha
  assert(type(fillAlpha)=="number" and fillAlpha>=0 and fillAlpha<=1, "GRID: PathFillAlpha must be between zero and one")
  local style={Coalition=Options.Coalition==nil and -1 or Options.Coalition, Color={color[1], color[2], color[3]}, Alpha=1,
    FillColor={color[1], color[2], color[3]}, FillAlpha=0, LineType=1, ReadOnly=true,
    Snapshot=true, PathCellIDs=pathCells, PathColor={pathColor[1], pathColor[2], pathColor[3]}, PathFillAlpha=fillAlpha}
  return self:_StartGridDrawing(style, Options)

end

--- Validate polygon style before removing an existing overlay or scheduling DCS drawing calls.
-- Shared by GRID and ASTAR drawing views. Invalid colors and recipient values must fail in the caller's context.
-- @param #table Style Resolved drawing style.
-- @return #nil No return value; raises an error for invalid values.
function GRID._ValidateDrawStyle(Style)

  local function color(value)
    assert(type(value)=="table", "GRID: drawing colors must be RGB tables")
    for i=1,3 do
      assert(type(value[i])=="number" and value[i]>=0 and value[i]<=1, "GRID: RGB components must be between zero and one")
    end
  end

  color(Style.Color)
  color(Style.FillColor)
  if Style.PathColor then color(Style.PathColor) end

  for _,name in ipairs({"Alpha", "FillAlpha"}) do
    assert(type(Style[name])=="number" and Style[name]>=0 and Style[name]<=1, "GRID: "..name.." must be between zero and one")
  end

  assert(type(Style.Coalition)=="number" and Style.Coalition>=-1 and Style.Coalition<=2 and Style.Coalition==math.floor(Style.Coalition),
    "GRID: Coalition must be -1, 0, 1 or 2")
  assert(type(Style.LineType)=="number" and Style.LineType>=0 and Style.LineType<=6 and Style.LineType==math.floor(Style.LineType),
    "GRID: LineType must be an integer between zero and six")
  assert(type(Style.ReadOnly)=="boolean", "GRID: ReadOnly must be a boolean")
end

--- Validate batch settings and replace the overlay before starting a regular drawing or debug snapshot.
-- @param #GRID self
-- @param #table Style Owned style table.
-- @param #table DrawOptions Optional batch settings.
-- @return #GRID self
function GRID:_StartGridDrawing(Style, DrawOptions)

  if DrawOptions==nil then DrawOptions={} end
  assert(type(DrawOptions)=="table", "GRID: drawing options must be a table")
  local batchSize=DrawOptions.BatchSize==nil and 25 or DrawOptions.BatchSize
  local interval=DrawOptions.Interval==nil and 0.1 or DrawOptions.Interval
  local maxBatchSeconds=DrawOptions.MaxBatchSeconds==nil and 0.005 or DrawOptions.MaxBatchSeconds
  assert(type(batchSize)=="number" and batchSize>=1 and batchSize<math.huge and batchSize==math.floor(batchSize), "GRID: drawing BatchSize must be a positive integer")
  assert(type(interval)=="number" and interval>0 and interval<math.huge, "GRID: drawing Interval must be finite and positive")
  assert(type(maxBatchSeconds)=="number" and maxBatchSeconds>0 and maxBatchSeconds<math.huge, "GRID: drawing MaxBatchSeconds must be finite and positive")
  GRID._ValidateDrawStyle(Style)
  self:UndrawGrid()
  Style.BatchSize=batchSize
  Style.Interval=interval
  Style.MaxBatchSeconds=maxBatchSeconds
  self.GridDrawOptions=Style
  return self:UpdateGridDrawing()

end

--- Add missing cell polygons to the current overlay, retaining its style and existing marks.
-- Also extends a pending drawing job without duplicating queued cells. Does nothing before DrawGrid() or for an already queued debug snapshot.
-- @param #GRID self
-- @return #GRID self
function GRID:UpdateGridDrawing()

  local cells=self:_GetGridCells()
  local style=self.GridDrawOptions
  if not style or (style.Snapshot and style.SnapshotQueued) then
    return self
  end
  if style.Snapshot then
    style.SnapshotQueued=true
  end
  local job=self.GridDrawJob
  if not job then
    local cpuAvailable=os and type(os.clock)=="function"
    job={cells={}, queued={}, index=1, style=style, started=timer.getTime(),
      result={Status="queued", [self:_GridResultField("Queued")]=0, [self:_GridResultField("Drawn")]=0, Batches=0,
        CPUSeconds=cpuAvailable and 0 or nil, MaxBatchCPUSeconds=cpuAvailable and 0 or nil}}
  end
  for id, cell in pairs(cells) do
    if (cell.rectGrid or (self.hexGrid and cell.q~=nil and cell.r~=nil))
    and not self.GridDrawCellIDs[id] and not job.queued[id] then
      job.cells[#job.cells+1]=id
      job.queued[id]=true
    end
  end
  job.result[self:_GridResultField("Queued")]=#job.cells
  -- An active job will process appended cells on subsequent ticks.
  if self.GridDrawJob then
    return self
  end
  self.GridDrawJob=job
  self.LastGridDrawResult=job.result
  local pending=true
  if #job.cells<=style.BatchSize then
    pending=self:_ProcessGridDrawJob(job)
  end
  if pending then
    self:T(self.lid..string.format("Grid drawing queued: %d remaining cells, up to %d per batch, %.3f sec CPU budget (one cell without CPU clock)",
      #job.cells-job.index+1, style.BatchSize, style.MaxBatchSeconds))
    job.timerID=timer.scheduleFunction(function(_, time)
      -- Identity check also protects against an already-dispatched callback after cancellation or replacement.
      if self.GridDrawJob~=job then
        return nil
      end
      if self:_ProcessGridDrawJob(job) then
        return timer.getTime()+style.Interval
      end
    end, nil, timer.getTime()+style.Interval)
  end
  return self

end

--- Draw one batch, bounded by cell count and a CPU budget checked after each cell. Without a CPU clock draw at most one cell.
-- @param #GRID self
-- @param #table Job Current drawing job.
-- @return #boolean Whether the job needs another batch.
function GRID:_ProcessGridDrawJob(Job)

  local cells=self:_GetGridCells()
  if self.GridDrawJob~=Job then
    return false
  end
  Job.result.Status="running"
  local clock=startCPUClock()
  local ok, err=pcall(function()
    -- Count remains an upper limit; with no CPU clock use a conservative one-cell fallback.
    local batchSize=clock and Job.style.BatchSize or 1
    local last=math.min(#Job.cells, Job.index+batchSize-1)
    while Job.index<=last do
      local id=Job.cells[Job.index]
      local cell=cells[id]
      if cell and not self.GridDrawCellIDs[id] then
        local markID=self:_DrawGridCell(cell, Job.style)
        if markID then
          self.GridDrawIDs[#self.GridDrawIDs+1]=markID
          self.GridDrawCellIDs[id]=markID
          Job.result[self:_GridResultField("Drawn")]=Job.result[self:_GridResultField("Drawn")]+1
        end
      end
      Job.queued[id]=nil
      Job.index=Job.index+1
      -- A DCS call cannot be interrupted; yield before starting the next cell once the budget is exhausted.
      if clock and elapsedCPU(clock)>=Job.style.MaxBatchSeconds then
        break
      end
    end
  end)
  local duration=elapsedCPU(clock)
  Job.result.Batches=Job.result.Batches+1
  if duration and Job.result.CPUSeconds then
    Job.result.CPUSeconds=Job.result.CPUSeconds+duration
    Job.result.MaxBatchCPUSeconds=math.max(Job.result.MaxBatchCPUSeconds, duration)
  else
    Job.result.CPUSeconds=nil
    Job.result.MaxBatchCPUSeconds=nil
  end
  if not ok then
    self:_FinishGridDrawing(Job, "error", tostring(err))
  elseif Job.index>#Job.cells then
    self:_FinishGridDrawing(Job, "complete")
  else
    return true
  end
  return false

end

--- Complete or cancel a drawing job, retaining its result for callers.
-- @param #GRID self
-- @param #table Job Current drawing job.
-- @param #string Status complete, cancelled or error.
-- @param #string Error Optional error message.
-- @return #nil No return value; the job result is updated in place.
function GRID:_FinishGridDrawing(Job, Status, Error)

  Job.result.Status=Status
  Job.result.Error=Error
  Job.result.ElapsedSimulationSeconds=math.max(0, timer.getTime()-Job.started)
  self.GridDrawJob=nil
  Job.timerID=nil
  local text=string.format("Grid drawing %s: %d/%d new cells, %d batches, %s, max batch %s, simulation elapsed %.3f sec",
    Status, Job.result[self:_GridResultField("Drawn")], Job.result[self:_GridResultField("Queued")], Job.result.Batches, cpuTimeText(Job.result.CPUSeconds),
    cpuTimeText(Job.result.MaxBatchCPUSeconds), Job.result.ElapsedSimulationSeconds)
  if Error then
    self:E(self.lid..text..": "..Error)
  else
    self:T(self.lid..text)
  end

end

--- Draw one generated grid cell using the saved style; manual endpoints have no polygon.
-- @param #GRID self
-- @param #GRID.Cell Cell Grid cell.
-- @param #table Style Drawing options.
-- @return #number Mark ID, or nil for an ASTAR endpoint without grid geometry.
function GRID:_DrawGridCell(Cell, Style)

  local corners={}
  local grid=Cell.rectGrid
  local function corner(along, across)
    local x, z=self:_GridPosition(grid, along, across, Cell.vector)
    corners[#corners+1]={x=x, y=0, z=z}
  end
  if self.hexGrid and Cell.q~=nil and Cell.r~=nil then
    grid=self.hexGrid
    local radius=grid.spacing/math.sqrt(3)
    for i=0, 5 do
      local angle=math.rad(30+60*i)
      corner(radius*math.cos(angle), radius*math.sin(angle))
    end
  elseif grid then
    corner(grid.along, grid.across)
    corner(-grid.along, grid.across)
    corner(-grid.along, -grid.across)
    corner(grid.along, -grid.across)
  end
  if #corners==0 then
    return nil
  end
  -- Match COORDINATE:MarkupToAllFreeForm's DCS call without constructing full MOOSE objects for polygon vertices.
  local markID=UTILS.GetMarkID()
  local onPath=Style.PathCellIDs and Style.PathCellIDs[Cell.id]
  local color=onPath and Style.PathColor or Style.Color
  local fillColor=onPath and Style.PathColor or Style.FillColor
  local fillAlpha=onPath and Style.PathFillAlpha or Style.FillAlpha
  local outline={color[1], color[2], color[3], Style.Alpha}
  local fill={fillColor[1], fillColor[2], fillColor[3], fillAlpha}
  if #corners==6 then
    trigger.action.markupToAll(7, Style.Coalition, markID, corners[1], corners[2], corners[3], corners[4], corners[5], corners[6],
      outline, fill, Style.LineType, Style.ReadOnly, "")
  else
    trigger.action.markupToAll(7, Style.Coalition, markID, corners[1], corners[2], corners[3], corners[4],
      outline, fill, Style.LineType, Style.ReadOnly, "")
  end
  return markID

end

--- Cancel pending drawing and remove polygons created by DrawGrid() without changing the grid or deleting other F10 marks.
-- Removal is synchronous. Safe to call repeatedly or before drawing. Does not remove MarkGrid text markers.
-- @param #GRID self
-- @return #GRID self
function GRID:UndrawGrid()

  local job=self.GridDrawJob
  if job then
    if job.timerID then
      timer.removeFunction(job.timerID)
    end
    self:_FinishGridDrawing(job, "cancelled")
  end
  for _, markID in ipairs(self.GridDrawIDs or {}) do
    trigger.action.removeMark(markID)
  end
  self.GridDrawIDs={}
  self.GridDrawCellIDs={}
  self.GridDrawOptions=nil
  return self

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Neighbour graph helpers
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get cached candidate adjacency for internal traversal without copying or sorting neighbours.
-- The returned cell-ID sets are owned by GRID and must not be modified by callers.
-- Retrieve them again after a grid mutation; attached searches must copy and translate IDs into their own adjacency.
-- @param #GRID self
-- @return #table Read-only adjacency indexed by cell ID, with neighbour cell IDs mapped to true.
function GRID:_GetGridLinks()

  if not self.gridLinks then
    self:_BuildGridLinks()
  end
  return self.gridLinks

end

--- Build candidate adjacency for the current rectangular or hex grid.
-- Requires existing grid geometry; movement rules and travel costs are not evaluated.
-- @param #GRID self
-- @return #GRID self.
function GRID:_BuildGridLinks()

  if self.hexGrid then
    return self:_BuildHexLinks()
  end
  return self:_BuildRectLinks()

end

--- Build rectangular cell adjacency without search nodes or movement rules.
-- Diagonals require both flanking cells; terrain and zone gaps cannot be cut across a corner.
-- @param #GRID self
-- @return #GRID self.
function GRID:_BuildRectLinks()

  local links={}
  local diagonal=self:GetOptions().Diagonals
  for id, cell in pairs(self.cells) do
    links[id]={}
    for di=-1, 1 do
      for dj=-1, 1 do
        local cardinal=math.abs(di)+math.abs(dj)==1
        local corner=di~=0 and dj~=0
        if cardinal or (corner and diagonal and self:GetCellFromIndex(cell.i+di, cell.j) and self:GetCellFromIndex(cell.i, cell.j+dj)) then
          local neighbor=self:GetCellFromIndex(cell.i+di, cell.j+dj)
          if neighbor then
            links[id][neighbor.id]=true
          end
        end
      end
    end
  end
  self.gridLinks=links
  return self

end

--- Build six-neighbour hex cell adjacency without search nodes or movement rules.
-- @param #GRID self
-- @return #GRID self.
function GRID:_BuildHexLinks()

  local links={}
  for id, cell in pairs(self.cells) do
    links[id]={}
    for _, direction in ipairs(hexDirections) do
      local neighbor=self:GetCellFromIndex(cell.q+direction[1], cell.r+direction[2])
      if neighbor then
        links[id][neighbor.id]=true
      end
    end
  end
  self.gridLinks=links
  return self

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------







--- Get the name of this grid.
-- @param #GRID self
-- @return #string Name.
function GRID:GetName()

  return self.name

end

--- Get the mutation version used by attached searches to invalidate geometric caches.
-- @param #GRID self
-- @return #number Version.
function GRID:GetVersion()

  return self.Version

end

--- Get the number of accepted cells, excluding ASTAR endpoints.
-- @param #GRID self
-- @return #number Cell count.
function GRID:GetCellCount()

  return self.CellCount

end

--- Get the number of candidate centers before zone and surface filters.
-- @param #GRID self
-- @return #number Candidate count, zero before construction.
function GRID:GetCandidateCount()

  return self.GridCandidateCount or 0

end

--- Get the fixed geometry type, including before construction or after a rejected build.
-- @param #GRID self
-- @return #string GRID.Type.RECTANGLE or GRID.Type.HEXAGON.
function GRID:GetType()

  return self.GridType

end

--- Get a cell by stable ID. Returned cells must not be modified.
-- @param #GRID self
-- @param #number ID Cell ID.
-- @return #GRID.Cell Cell, or nil.
function GRID:GetCell(ID)

  return self.cells[ID]

end

--- Get a cell by lattice indices. Returned cells must not be modified.
-- @param #GRID self
-- @param #number First Rectangular i or hex q.
-- @param #number Second Rectangular j or hex r.
-- @return #GRID.Cell Cell, or nil if outside the grid or filtered out.
function GRID:GetCellFromIndex(First, Second)

  local index=self.hexIndex or self.rectIndex
  local row=index and index[First]
  return row and row[Second]

end

--- Get an ordered copy of the cell list. Cell objects are shared read-only references.
-- @param #GRID self
-- @return #table Cells in insertion order.
function GRID:GetCells()

  local cells={}
  for i, cell in ipairs(self.CellList) do
    cells[i]=cell
  end
  return cells

end

--- Get direct geometric neighbours. No movement rules or costs are evaluated.
-- @param #GRID self
-- @param #GRID.Cell Cell Owned cell.
-- @return #table Independent list of read-only neighbouring cells, sorted by ID.
function GRID:GetNeighbours(Cell)

  assert(Cell and self.cells[Cell.id]==Cell, "GRID: cell must belong to this grid")
  local links=self:_GetGridLinks()
  local neighbors={}
  for id in pairs(links[Cell.id]) do
    neighbors[#neighbors+1]=self.cells[id]
  end
  table.sort(neighbors, function(a, b)
    return a.id<b.id
  end)
  return neighbors

end


--- Find the nearest accepted cell in the horizontal plane.
-- @param #GRID self
-- @param Core.Vector#VECTOR Position Position; also accepts COORDINATE, Vec2 or Vec3.
-- @return #GRID.Cell Cell, or nil for an empty grid.
-- @return #number Distance in meters, or math.huge for an empty grid.
function GRID:FindClosestCell(Position)

  local vector=self:_PositionVector(Position)
  local nearest, distance=nil, math.huge
  for _, cell in ipairs(self.CellList) do
    local d=cell.vector:GetDistance(vector, true)
    if d<distance then
      nearest=cell
      distance=d
    end
  end
  return nearest, distance

end

--- Get a snapshot of current dimensions, including expansions. Configuration Width/Margin describe the initial corridor.
-- @param #GRID self
-- @return #table Width, Margin, Spacing and CrossSpacing (rectangles), or nil before construction.
function GRID:GetDimensions()

  local grid=self.hexGrid or self.rectGrid
  if not grid then
    return nil
  end
  return {Width=grid.width, Margin=grid.margin, Spacing=grid.spacing, CrossSpacing=grid.crossSpacing}

end

--- Find nearby cells within the local topology's attachment region.
-- Hexagons use a circle of radius Spacing. Rectangles use normalized distances within one spacing:
-- a square for eight neighbours, a diamond for four. This geometric query does not check travel rules.
-- @param #GRID self
-- @param Core.Vector#VECTOR Position Position; also accepts COORDINATE, Vec2 or Vec3.
-- @return #table Nearby cells, or an empty list before construction or outside the grid.
function GRID:GetNearbyCells(Position)

  local vector=self:_PositionVector(Position)
  local grid=self.hexGrid or self.rectGrid
  local nearby={}
  if not grid then
    return nearby
  end
  local dx, dz=vector.x-grid.x, vector.z-grid.z
  local along=(dx*grid.cos+dz*grid.sin)/grid.spacing
  local epsilon=1e-9
  if self.hexGrid then
    local across=(-dx*grid.sin+dz*grid.cos)/grid.spacing
    local rowScale=math.sqrt(3)/2
    -- Clamp to existing bounds so even very distant finite coordinates cannot create non-progressing loops.
    for r=math.max(grid.bounds.rmin, math.ceil((across-1)/rowScale-epsilon)), math.min(grid.bounds.rmax, math.floor((across+1)/rowScale+epsilon)) do
      local row=grid.bounds[r]
      for q=math.max(row.qmin, math.ceil(along-1-r/2-epsilon)), math.min(row.qmax, math.floor(along+1-r/2+epsilon)) do
        local cell=self:GetCellFromIndex(q, r)
        local dl, dt=q+r/2-along, r*rowScale-across
        if cell and dl*dl+dt*dt<=1+epsilon then
          nearby[#nearby+1]=cell
        end
      end
    end
  else
    along=along-grid.alongOffset/grid.spacing
    local across=(-dx*grid.sin+dz*grid.cos-grid.acrossOffset)/grid.crossSpacing
    local diagonal=self:GetOptions().Diagonals
    for i=math.max(grid.bounds.imin, math.ceil(across-1-epsilon)), math.min(grid.bounds.imax, math.floor(across+1+epsilon)) do
      for j=math.max(grid.bounds.jmin, math.ceil(along-1-epsilon)), math.min(grid.bounds.jmax, math.floor(along+1+epsilon)) do
        local cell=self:GetCellFromIndex(i, j)
        if cell and (diagonal or math.abs(i-across)+math.abs(j-along)<=1+epsilon) then
          nearby[#nearby+1]=cell
        end
      end
    end
  end
  return nearby

end

--- Copy a position and validate finite DCS coordinates before geometric calculations.
-- @param #GRID self
-- @param Core.Vector#VECTOR Position Position; also accepts COORDINATE, Vec2 or Vec3.
-- @return Core.Vector#VECTOR Independent finite position vector.
function GRID:_PositionVector(Position)

  local vector=VECTOR:NewFromVec(Position)
  for _, axis in ipairs({"x", "y", "z"}) do
    local value=vector[axis]
    assert(type(value)=="number" and value>-math.huge and value<math.huge, "GRID: position coordinates must be finite")
  end
  return vector

end

--- Resolve an owned cell or copy a position for a geometry query.
-- @param #GRID self
-- @param #table Value Owned cell, VECTOR, COORDINATE, Vec2 or Vec3.
-- @return Core.Vector#VECTOR Position vector; owned cell vectors remain read-only.
function GRID:_QueryPosition(Value)

  assert(self.GridBuilt, "GRID: geometry queries require a built grid")
  if type(Value)=="table" and Value.vector then
    assert(self.cells[Value.id]==Value, "GRID: cell must belong to this grid")
    return Value.vector
  end
  return self:_PositionVector(Value)

end

--- Map a horizontal position to the nearest center on the complete lattice.
-- Height is ignored. Boundary ties are deterministic: scalar halves round upwards;
-- hex cube correction prefers s, then r, then q when rounding errors tie.
-- @param #GRID self
-- @param #table Position Owned cell, VECTOR, COORDINATE, Vec2 or Vec3.
-- @return #number Rectangular i or hex q, including outside the built area.
-- @return #number Rectangular j or hex r, including filtered positions.
function GRID:PositionToIndex(Position)

  local vector=self:_QueryPosition(Position)
  if Position.vector then return Position.q or Position.i, Position.r or Position.j end
  local grid=self.hexGrid or self.rectGrid
  local dx, dz=vector.x-grid.x, vector.z-grid.z
  local along, across=dx*grid.cos+dz*grid.sin, -dx*grid.sin+dz*grid.cos
  local first, second
  if self.hexGrid then
    second=across/grid.rowSpacing
    first=along/grid.spacing-second/2
    assert(self:_ValidIndexRange(first, second) and self:_ValidIndexRange(-first-second, -first-second),
      "GRID: position exceeds the supported lattice range")
    local third=-first-second
    local q, r, s=math.floor(first+0.5), math.floor(second+0.5), math.floor(third+0.5)
    local dq, dr, ds=math.abs(q-first), math.abs(r-second), math.abs(s-third)
    if dq>dr and dq>ds then
      q=-r-s
    elseif dr>ds then
      r=-q-s
    end
    return q, r
  end
  first=(across-grid.acrossOffset)/grid.crossSpacing
  second=(along-grid.alongOffset)/grid.spacing
  assert(self:_ValidIndexRange(first, second), "GRID: position exceeds the supported lattice range")
  return math.floor(first+0.5), math.floor(second+0.5)

end

--- Convert lattice indices to a center without creating a cell or sampling terrain.
-- @param #GRID self
-- @param #number First Integer rectangular i or hex q, including outside the built area.
-- @param #number Second Integer rectangular j or hex r.
-- @return Core.Vector#VECTOR New center vector at height zero.
function GRID:IndexToPosition(First, Second)

  assert(self.GridBuilt, "GRID: geometry queries require a built grid")
  assert(type(First)=="number" and type(Second)=="number" and self:_ValidIndexRange(First, Second)
    and First==math.floor(First) and Second==math.floor(Second), "GRID: indices must be safe integers")
  local grid=self.hexGrid or self.rectGrid
  local along, across
  if self.hexGrid then
    assert(self:_ValidIndexRange(-First-Second, -First-Second), "GRID: cube index exceeds the supported lattice range")
    along, across=grid.spacing*(First+Second/2), grid.rowSpacing*Second
  else
    along, across=grid.alongOffset+Second*grid.spacing, grid.acrossOffset+First*grid.crossSpacing
  end
  local x, z=self:_GridPosition(grid, along, across)
  return self:_PositionVector({x=x, y=0, z=z})

end

--- Get the existing cell containing a position, using deterministic boundary rounding.
-- Unlike FindClosestCell(), this does not substitute a nearby accepted cell for a gap.
-- @param #GRID self
-- @param #table Position Owned cell, VECTOR, COORDINATE, Vec2 or Vec3; height is ignored.
-- @return #GRID.Cell Read-only cell, or nil outside the built area or in a filtered gap.
function GRID:GetCellAtPosition(Position)

  return self:GetCellFromIndex(self:PositionToIndex(Position))

end

--- Compute the complete-lattice distance between two pairs of indices.
-- @param #GRID self
-- @param #number A First index of the first point.
-- @param #number B Second index of the first point.
-- @param #number C First index of the second point.
-- @param #number D Second index of the second point.
-- @return #number Geometric distance in cell steps, ignoring missing cells and movement rules.
function GRID:_IndexDistance(A, B, C, D)

  local first, second=C-A, D-B
  if self.hexGrid then
    return math.max(math.abs(first), math.abs(second), math.abs(first+second))
  elseif not self.GridOptions or self.GridOptions.Diagonals~=false then
    return math.max(math.abs(first), math.abs(second))
  end
  return math.abs(first)+math.abs(second)

end

--- Get geometric cell-step distance on the complete lattice; this is not a path search.
-- @param #GRID self
-- @param #table Start Owned cell or position (VECTOR, COORDINATE, Vec2 or Vec3).
-- @param #table Goal Owned cell or position; positions snap to their lattice centers.
-- @return #number Hex cube, rectangular Manhattan (four neighbours) or Chebyshev (eight neighbours) distance.
function GRID:GetGridDistance(Start, Goal)

  local a, b=self:PositionToIndex(Start)
  local c, d=self:PositionToIndex(Goal)
  return self:_IndexDistance(a, b, c, d)

end

--- Select existing cells by complete-lattice distance, with work bounded by the existing cell count.
-- @param #GRID self
-- @param #table Center Owned cell or position; positions snap to lattice centers.
-- @param #number Radius Non-negative integer distance in cell steps.
-- @param #boolean Ring True selects exactly Radius, false selects distances up to Radius.
-- @return #table Independent list of read-only cells in insertion order.
function GRID:_GetCellsByDistance(Center, Radius, Ring)

  local a, b=self:PositionToIndex(Center)
  assert(type(Radius)=="number" and Radius>=0 and self:_ValidIndexRange(0, Radius)
    and Radius==math.floor(Radius), "GRID: radius must be a non-negative safe integer")
  local result={}
  for _, cell in ipairs(self.CellList) do
    local distance=self:_IndexDistance(a, b, cell.q or cell.i, cell.r or cell.j)
    if (Ring and distance==Radius) or (not Ring and distance<=Radius) then
      result[#result+1]=cell
    end
  end
  return result

end

--- Get existing cells exactly Radius lattice steps from a center, ignoring obstacles and gaps.
-- @param #GRID self
-- @param #table Center Owned cell or position (VECTOR, COORDINATE, Vec2 or Vec3).
-- @param #number Radius Non-negative integer distance in cell steps; zero selects the center cell if present.
-- @return #table Independent list of read-only cells in insertion order, not angular order.
function GRID:GetRing(Center, Radius)

  return self:_GetCellsByDistance(Center, Radius, true)

end

--- Get existing cells within Radius lattice steps, including the center if present.
-- @param #GRID self
-- @param #table Center Owned cell or position (VECTOR, COORDINATE, Vec2 or Vec3).
-- @param #number Radius Non-negative integer distance in cell steps, not meters.
-- @return #table Independent list of read-only cells in insertion order; obstacles do not affect distance.
function GRID:GetCellsInRange(Center, Radius)

  return self:_GetCellsByDistance(Center, Radius, false)

end

--- Clip a segment against a convex cell in normalized grid coordinates.
-- @param #GRID self
-- @param #table Cell Owned geometric cell.
-- @param Core.Vector#VECTOR Start Segment start.
-- @param Core.Vector#VECTOR Goal Segment goal.
-- @return #number Entry fraction from zero to one, or nil when the cell is not touched.
function GRID:_LineCellEntry(Cell, Start, Goal)

  local grid=self.hexGrid or self.rectGrid
  local dx, dz=Start.x-Cell.vector.x, Start.z-Cell.vector.z
  local ex, ez=Goal.x-Start.x, Goal.z-Start.z
  local cross=grid.crossSpacing or grid.spacing
  local x, y=(dx*grid.cos+dz*grid.sin)/grid.spacing, (-dx*grid.sin+dz*grid.cos)/cross
  local vx, vy=(ex*grid.cos+ez*grid.sin)/grid.spacing, (-ex*grid.sin+ez*grid.cos)/cross
  local enter, leave=0, 1
  local sides=self.hexGrid and 6 or 4
  for side=0, sides-1 do
    local angle=side*2*math.pi/sides
    local nx, ny=math.cos(angle), math.sin(angle)
    -- Exact cardinal normals avoid artificial slopes along rectangular edges.
    if sides==4 then
      nx=side==0 and 1 or (side==2 and -1 or 0)
      ny=side==1 and 1 or (side==3 and -1 or 0)
    end
    local remaining=0.5+1e-9-nx*x-ny*y
    local rate=nx*vx+ny*vy
    if rate==0 then
      if remaining<0 then return nil end
    elseif rate>0 then
      leave=math.min(leave, remaining/rate)
    else
      enter=math.max(enter, remaining/rate)
    end
    if enter>leave then return nil end
  end
  return enter

end

--- Get all existing cells touched by an open horizontal segment, including edge and vertex contacts.
-- Uses a supercover with 1e-9 spacing tolerance, not a center-to-center digital line.
-- Work is bounded by existing cells, even when endpoints are far outside the built area.
-- @param #GRID self
-- @param #table Start Owned cell or position (VECTOR, COORDINATE, Vec2 or Vec3).
-- @param #table Goal Owned cell or position; coincident endpoints select all cells touching that point.
-- @return #table Read-only cells in segment entry order, ties by ID; gaps are omitted and connectivity is not guaranteed.
function GRID:GetLineCells(Start, Goal)

  local first, last=self:_QueryPosition(Start), self:_QueryPosition(Goal)
  self:PositionToIndex(first)
  self:PositionToIndex(last)
  local hits={}
  for _, cell in ipairs(self.CellList) do
    local entry=self:_LineCellEntry(cell, first, last)
    if entry then hits[#hits+1]={cell=cell, entry=entry} end
  end
  table.sort(hits, function(a, b)
    if a.entry==b.entry then return a.cell.id<b.cell.id end
    return a.entry<b.entry
  end)
  local result={}
  for i, hit in ipairs(hits) do result[i]=hit.cell end
  return result

end

--- Get cells touched by a closed polygon boundary; the interior is not filled.
-- Each edge uses GetLineCells(). Repeated vertices and an explicitly repeated closing vertex are allowed.
-- @param #GRID self
-- @param #table Vertices Ordered list of at least three owned cells or positions (VECTOR, COORDINATE, Vec2 or Vec3).
-- @return #table Independent list of read-only cells, deduplicated in first-encounter order around the boundary.
function GRID:GetPolygonBoundaryCells(Vertices)

  assert(type(Vertices)=="table" and #Vertices>=3, "GRID: polygon boundary requires at least three vertices")
  local positions={}
  for i, vertex in ipairs(Vertices) do positions[i]=self:_QueryPosition(vertex) end
  local result, seen={}, {}
  for i, position in ipairs(positions) do
    for _, cell in ipairs(self:GetLineCells(position, positions[i%#positions+1])) do
      if not seen[cell.id] then
        seen[cell.id]=true
        result[#result+1]=cell
      end
    end
  end
  return result

end

--- Check whether a lattice range can be traversed with exact unit increments.
-- Rejects NaN, infinity and indices outside the safe double-precision integer range.
-- @param #GRID self
-- @param #number First First lattice index.
-- @param #number Last Last lattice index; may be smaller than First for an empty range.
-- @return #boolean Whether both endpoints are safe for numeric-for loops.
function GRID:_ValidIndexRange(First, Last)

  local limit=4503599627370495
  return First>=-limit and First<=limit and Last>=-limit and Last<=limit

end

--- Create default cell-marker settings for the shared renderer.
-- ASTAR extends these defaults with its own connection-check option.
-- @param #GRID self
-- @return #table Independent default marker settings.
function GRID:_GridMarkDefaults()

  return {ShowID=true, ShowGridIndex=true, ShowNeighbourCount=true,
    Coalition=-1, ReadOnly=true, BatchSize=25, Interval=0.1, MaxBatchSeconds=0.005}

end
