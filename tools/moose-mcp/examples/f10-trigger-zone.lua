-- MOOSE 2.9.19. Load Moose.lua before this script.
-- Create the circular trigger zone and group using these exact names.
local zoneName = "LZ Alpha"
local groupName = "Training Flight"

local zone = ZONE:New(zoneName)
if not zone then
  -- ZONE:New logs the missing trigger zone.
  return
end

local function reportZoneStatus()
  -- Resolve the group when the command is selected so it can activate later.
  local group = GROUP:FindByName(groupName)
  local insideZone
  if group then
    insideZone = group:IsInZone(zone)
  end

  local status
  if insideZone == nil then
    status = groupName .. " is unavailable."
  elseif insideZone then
    status = "At least one unit in " .. groupName .. " is inside " .. zoneName .. "."
  else
    status = "All units in " .. groupName .. " are outside " .. zoneName .. "."
  end

  MESSAGE:New(status, 10):ToAll()
end

local trainingMenu = MENU_MISSION:New("Training")
MENU_MISSION_COMMAND:New("Check " .. zoneName, trainingMenu, reportZoneStatus)
