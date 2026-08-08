-- Optional connection tuning extension for MOOSE Bridge.
--
-- Load after MooseBridge.lua and before creating the bridge instance. It reduces
-- DCS main-thread stalls when the Python server is not running by shortening the
-- blocking LuaSocket connect timeout and using less aggressive retry defaults.

if not MOOSE_BRIDGE then error("Load MooseBridge.lua before MooseBridgeSocketTuningExtension.lua") end

local function bridge_tuning_mission_time()
  if timer and timer.getTime then return timer.getTime() end
  return 0
end

local function bridge_tuning_safe_tostring(value)
  if value == nil then return "nil" end
  return tostring(value)
end

local function bridge_should_log_connect_failure(bridge, err, now)
  if bridge.LogConnectFailures == false then return false end
  if err == "timeout" and bridge.LogConnectTimeouts ~= true then return false end

  local interval = bridge.ConnectFailureLogInterval or 60
  if bridge.LastConnectFailureLog and now - bridge.LastConnectFailureLog < interval then return false end

  bridge.LastConnectFailureLog = now
  return true
end

local _moose_bridge_tuning_base_new = MOOSE_BRIDGE.New

function MOOSE_BRIDGE:New(host, port)
  local bridge = _moose_bridge_tuning_base_new(self, host, port)

  -- Keep idle bridge retries low-impact when the Python server is not listening.
  bridge.ConnectTimeout = bridge.ConnectTimeout or 0.02
  if bridge.ConnectRetryDelay == nil or bridge.ConnectRetryDelay == 5 then bridge.ConnectRetryDelay = 10 end
  if bridge.TickInterval == nil or bridge.TickInterval == 0.2 then bridge.TickInterval = 0.5 end
  if bridge.HeartbeatInterval == nil or bridge.HeartbeatInterval == 5 then bridge.HeartbeatInterval = 10 end

  -- Keep expected idle reconnect timeouts out of dcs.log by default.
  if bridge.LogConnectFailures == nil then bridge.LogConnectFailures = true end
  if bridge.LogConnectTimeouts == nil then bridge.LogConnectTimeouts = false end
  bridge.ConnectFailureLogInterval = bridge.ConnectFailureLogInterval or 60
  bridge.LastConnectFailureLog = nil

  return bridge
end

function MOOSE_BRIDGE:_Connect()
  local now = bridge_tuning_mission_time()
  if now - self.LastConnectAttempt < (self.ConnectRetryDelay or 10) then return end
  self.LastConnectAttempt = now

  local lib = require("socket")
  local conn = lib.tcp()
  conn:settimeout(self.ConnectTimeout or 0.02)

  local ok, err = conn:connect(self.Host, self.Port)
  if not ok then
    if bridge_should_log_connect_failure(self, err, now) then
      self:_Log("Connect failed: " .. bridge_tuning_safe_tostring(err))
    end
    conn:close()
    return
  end

  -- All regular bridge IO is polled from the scheduler tick and must not block DCS.
  conn:settimeout(0)
  self.Socket = conn
  self.Connected = true
  self:_Log("Connected to Python bridge")
end
