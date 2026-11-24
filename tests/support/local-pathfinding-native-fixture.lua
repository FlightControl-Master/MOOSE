-- Host integration fixture ONLY. Its fabricated load/log evidence is not DCS
-- evidence. Actual archived Core methods still capture and replay all queries.
local root, codecPath = assert(arg[1]), assert(arg[2])
local function read(path)
  local file = assert(io.open(root .. "/" .. path, "rb"))
  local bytes = assert(file:read("*a"))
  assert(file:close())
  return bytes
end
local Codec = assert(loadstring(read(codecPath), "@fixture-archived-codec"))()
local reference = Codec.Decode(read("reference.json"))
local members, imported = {}, {}
for _, member in ipairs(reference.Members) do members[member.LogicalPath] = member end
local function source(path)
  return assert(loadstring(read(assert(members[path]).LoadedPath), "@" .. path))
end
local import
import = function(path)
  if imported[path] == nil then imported[path] = source(path)(import) end
  return imported[path]
end
local P0 = import("tests/support/local-pathfinding.lua")
local Loader = import("tests/support/local-pathfinding-loader.lua")
local fixture = P0.Fixtures.Install(function(path) return source(path)() end)
local definition = P0.Fixtures.Definition("island")
definition.Regions[2] = {XMin = 600, XMax = 1400, ZMin = 750, ZMax = 1250, Depth = 5}
fixture.ActiveTerrain = P0.Fixtures.Terrain(definition)
local positions = {
  ["ASTAR Start 1"] = {x = 0, y = -1000}, ["ASTAR Goal 1"] = {x = 2000, y = -1000},
  ["PATHLINE Shallow Start"] = {x = 0, y = 1000}, ["PATHLINE Shallow Goal"] = {x = 2000, y = 1000},
  ["PATHLINE Coast Start"] = {x = 0, y = 0}, ["PATHLINE Coast Goal"] = {x = 2000, y = 0},
}
ZONE = {FindByName = function(_, name) return {GetVec2 = function() return positions[name] end} end}
local schedule = {Now = 0, Capture = {}}
function schedule.getTime() return schedule.Now end
function schedule.scheduleFunction(callback, value, time)
  schedule.Capture.Callback, schedule.Time = callback, time
  return 1
end
function schedule.removeFunction() end
timer = schedule
env = {mission = {theatre = "PersianGulf"}, info = function() end}
local context = Loader.New(reference, {Root = root})
context.Completed, context.Sealed = true, true
context.Events = Codec.Decode(read("fixture-load-events.json"))
for _, member in ipairs(reference.Members) do
  context.BytesWritten = context.BytesWritten + member.Bytes
end
local Runner = import("tests/support/local-pathfinding-dcs.lua")
local job = Runner.Start(context)
while schedule.Time do
  schedule.Now = schedule.Time
  schedule.Time = schedule.Capture.Callback(nil, schedule.Now)
end
assert(job.State == "complete", "fixture capture failed")
assert(fixture.DrawingCalls == 0 and fixture.ForbiddenCalls == 0)
