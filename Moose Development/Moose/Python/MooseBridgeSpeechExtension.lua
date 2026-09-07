--- Serialized MOOSE/MSRS speech support for MOOSE_BRIDGE.
--
-- Load after MooseBridge.lua and before constructing the bridge.

if not MOOSE_BRIDGE then error("Load MooseBridge.lua before MooseBridgeSpeechExtension.lua") end
if MOOSE_BRIDGE._SpeechExtensionLoaded then return end
MOOSE_BRIDGE._SpeechExtensionLoaded = true

local function speech_number(value, minimum, maximum)
  return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
    and value >= minimum and value <= maximum
end

local function speech_string(value, maximum)
  return type(value) == "string" and #value > 0 and #value <= maximum and not value:find("[%c]")
end

local function speech_now()
  return timer and timer.getTime and timer.getTime() or 0
end

local function speech_coalition_id(value)
  if value == 0 or value == "neutral" then return 0 end
  if value == 1 or value == "red" then return 1 end
  if value == 2 or value == "blue" then return 2 end
  return nil
end

function MOOSE_BRIDGE:_SpeechStatus()
  local available = type(HoundTTS) == "table" and type(HoundTTS.Transmit) == "function"
    and type(HoundTTS.TestTone) == "function" and type(HoundTTS.getSpeechTime) == "function"
    and type(MSRS) == "table" and type(MSRS.New) == "function"
  local config = self.SpeechConfig
  local sender_count, pending_count, active_count, network_count = 0, 0, 0, 0
  for _, sender in pairs(self.SpeechSenders or {}) do
    sender_count = sender_count + 1
    pending_count = pending_count + #(sender.queue or {})
    if sender.active then active_count = active_count + 1 end
  end
  for _ in pairs(self.SpeechNetworks or {}) do network_count = network_count + 1 end
  return {api_version=2, available=available, enabled=config ~= nil,
    owner_id=config and config.owner_id or nil,
    profile_count=config and config.profile_count or 0,
    hound_host=type(HoundTTS) == "table" and HoundTTS.SRS_HOST or nil,
    hound_transmitter=type(HoundTTS) == "table" and HoundTTS.DEFAULT_TRANSMITTER or nil,
    sender_count=sender_count, network_count=network_count,
    pending_count=pending_count, active_count=active_count,
    synthetic_only=true, human_ptt_observed=false}
end

function MOOSE_BRIDGE:_ClearSpeechQueues()
  self.SpeechSenders = {}
  self.SpeechNetworks = {}
  self.SpeechTransmitters = {}
  self.SpeechIntentHistory = {}
  self.SpeechSerial = 0
end

function MOOSE_BRIDGE:_ValidateSpeechProfile(profile, fallback_id)
  if type(profile) ~= "table" then error("speech profile is required") end
  local profile_id = profile.profile_id or fallback_id
  if not speech_string(profile_id, 128) then error("speech profile profile_id is invalid") end
  if not speech_string(profile.network_id, 128) then error("speech profile network_id is invalid") end
  for _, key in ipairs({"srs_path", "srs_host", "provider", "voice", "label"}) do
    if not speech_string(profile[key], key == "srs_path" and 512 or 128) then
      error("speech profile " .. key .. " is invalid")
    end
  end
  if not speech_number(profile.srs_port, 1, 65535)
    or profile.srs_port ~= math.floor(profile.srs_port) then error("speech profile srs_port is invalid") end
  if not speech_number(profile.frequency_mhz, 1, 1000) then error("speech profile frequency_mhz is invalid") end
  if profile.modulation ~= "AM" and profile.modulation ~= "FM" then
    error("speech profile modulation must be AM or FM")
  end
  if not speech_number(profile.volume, 0, 1) then error("speech profile volume is invalid") end
  if not speech_number(profile.speed, 0.1, 4) then error("speech profile speed is invalid") end
  if not speech_number(profile.interval_s, 0, 30) then error("speech profile interval_s is invalid") end
  if profile.arbitration ~= "strict" and profile.arbitration ~= "disciplined"
    and profile.arbitration ~= "congested" and profile.arbitration ~= "uncontrolled" then
    error("speech profile arbitration is invalid")
  end
  if not speech_number(profile.backoff_min_s, 0, 30)
    or not speech_number(profile.backoff_max_s, profile.backoff_min_s, 30) then
    error("speech profile backoff range is invalid")
  end
  if not speech_number(profile.collision_probability, 0, 1) then
    error("speech profile collision_probability is invalid")
  end
  if type(profile.emergency_break_in) ~= "boolean" then
    error("speech profile emergency_break_in must be boolean")
  end
  local hound_host = HoundTTS.SRS_HOST or "127.0.0.1"
  if profile.srs_host ~= hound_host then
    error("speech profile srs_host does not match HoundTTS.SRS_HOST (" .. tostring(hound_host) .. ")")
  end
  if HoundTTS.DEFAULT_TRANSMITTER ~= "srs" then
    error("HoundTTS.DEFAULT_TRANSMITTER must be 'srs', not '"
      .. tostring(HoundTTS.DEFAULT_TRANSMITTER) .. "'; Piper belongs in DEFAULT_PROVIDER")
  end
  return {profile_id=profile_id, network_id=profile.network_id,
    srs_path=profile.srs_path, srs_host=profile.srs_host, srs_port=profile.srs_port,
    frequency_mhz=profile.frequency_mhz, modulation=profile.modulation,
    provider=profile.provider, voice=profile.voice, label=profile.label,
    volume=profile.volume, speed=profile.speed, interval_s=profile.interval_s,
    arbitration=profile.arbitration, backoff_min_s=profile.backoff_min_s,
    backoff_max_s=profile.backoff_max_s,
    collision_probability=profile.collision_probability,
    emergency_break_in=profile.emergency_break_in}
end

function MOOSE_BRIDGE:_ConfigureSpeech(params)
  if params.expected_instance_id ~= nil and params.expected_instance_id ~= self:_NavigationRuntimeStatus().instance_id then
    error("Speech bridge instance changed")
  end
  if type(params.enabled) ~= "boolean" then error("enabled must be boolean") end
  if not speech_string(params.owner_id, 128) then
    error("owner_id must be a non-empty string of at most 128 characters")
  end
  if not params.enabled then
    if self.SpeechConfig and self.SpeechConfig.owner_id == params.owner_id then
      self:_ClearSpeechQueues()
      self.SpeechConfig = nil
    end
    return self:_SpeechStatus()
  end
  if not self:_SpeechStatus().available then
    error("HoundTTS and MSRS with the Hound backend are required for speech")
  end
  local requested = params.profiles
  if requested == nil and type(params.profile) == "table" then requested = {params.profile} end
  if type(requested) ~= "table" or #requested == 0 or #requested > 64 then
    error("profiles must contain 1..64 speech profiles")
  end
  local profiles, networks, frequencies = {}, {}, {}
  for index, item in ipairs(requested) do
    local profile = self:_ValidateSpeechProfile(item, index == 1 and "default" or nil)
    if profiles[profile.profile_id] then error("duplicate speech profile_id " .. profile.profile_id) end
    local signature = table.concat({profile.frequency_mhz, profile.modulation, profile.arbitration,
      profile.interval_s, profile.backoff_min_s, profile.backoff_max_s,
      profile.collision_probability, tostring(profile.emergency_break_in)}, ":")
    if networks[profile.network_id] and networks[profile.network_id] ~= signature then
      error("profiles on one network_id must use the same frequency and arbitration policy")
    end
    local frequency_key = string.format("%.3f:%s", profile.frequency_mhz, profile.modulation)
    if frequencies[frequency_key] and frequencies[frequency_key] ~= profile.network_id then
      error("profiles on one frequency/modulation must use the same network_id")
    end
    networks[profile.network_id] = signature
    frequencies[frequency_key] = profile.network_id
    profiles[profile.profile_id] = profile
  end
  self:_ClearSpeechQueues()
  self.SpeechConfig = {owner_id=params.owner_id, profiles=profiles, profile_count=#requested}
  return self:_SpeechStatus()
end

function MOOSE_BRIDGE:_SpeechProfileGuard(params)
  if not self.SpeechConfig or self.SpeechConfig.owner_id ~= params.owner_id then
    error("Speech service is not owned by this client")
  end
  local profile = self.SpeechConfig.profiles[params.profile_id]
  if not profile then error("Unknown speech profile_id") end
  return profile
end

function MOOSE_BRIDGE:_SpeechSenderKey(sender)
  if type(sender) ~= "table" or not speech_string(sender.sender_id, 128)
    or not speech_string(sender.radio_id, 128) then error("speech sender identity is invalid") end
  if sender.kind ~= "player" and sender.kind ~= "unit" and sender.kind ~= "group"
    and sender.kind ~= "airbase" and sender.kind ~= "coordinate" then
    error("speech sender kind is invalid")
  end
  return table.concat({sender.kind, sender.sender_id, sender.radio_id}, ":")
end

function MOOSE_BRIDGE:_ResolveSpeechSender(sender)
  local sender_key = self:_SpeechSenderKey(sender)
  local object, coordinate, coalition_id
  if sender.kind == "player" then
    if not speech_string(sender.group_id, 256) or not speech_string(sender.session_id, 128) then
      error("player speech sender requires group_id and session_id")
    end
    local entry = self:_NavigationMenuEntry({owner_id=self.SpeechConfig.owner_id,
      group_id=sender.group_id, session_id=sender.session_id})
    local _, _, wrapper = self:_FlightStatusReferenceUnit(entry)
    object = wrapper
    coordinate = self:_SafeCall(wrapper, "GetCoordinate")
    coalition_id = self:_SafeCall(entry.group, "GetCoalition")
  elseif sender.kind == "coordinate" then
    if not speech_number(sender.x, -20000000, 20000000)
      or not speech_number(sender.y, -100000, 1000000)
      or not speech_number(sender.z, -20000000, 20000000)
      or type(COORDINATE) ~= "table" or type(COORDINATE.New) ~= "function" then
      error("coordinate speech sender is invalid")
    end
    coordinate = COORDINATE:New(sender.x, sender.y, sender.z)
    coalition_id = speech_coalition_id(sender.coalition)
  else
    if not speech_string(sender.object_id, 256) then error("speech sender object_id is invalid") end
    local prefix, name = string.match(sender.object_id, "^(%u+):(.+)$")
    local expected = sender.kind == "unit" and "UNIT" or sender.kind == "group" and "GROUP" or "AIRBASE"
    if prefix ~= expected or not _DATABASE then error("speech sender object_id does not match its kind") end
    local collection = expected == "UNIT" and _DATABASE.UNITS
      or expected == "GROUP" and _DATABASE.GROUPS or _DATABASE.AIRBASES
    object = type(collection) == "table" and collection[name] or nil
    if not object then error("speech sender DCS object is unavailable") end
    if expected == "UNIT" and self:_SafeCall(object, "IsExist") == false then
      error("speech sender unit no longer exists")
    end
    if expected == "GROUP" and self:_SafeCall(object, "IsAlive") == false then
      error("speech sender group is no longer alive")
    end
    coordinate = self:_SafeCall(object, "GetCoordinate")
    coalition_id = self:_SafeCall(object, "GetCoalition")
  end
  coalition_id = speech_coalition_id(coalition_id)
  if not coordinate then error("speech sender coordinate is unavailable") end
  if coalition_id == nil then error("speech sender coalition is unavailable") end
  return {key=sender_key, descriptor=sender, object=object,
    coordinate=coordinate, coalition_id=coalition_id}
end

function MOOSE_BRIDGE:_SpeechNetwork(profile, coalition_id)
  local key = table.concat({coalition_id, profile.network_id,
    string.format("%.3f", profile.frequency_mhz), profile.modulation}, ":")
  self.SpeechNetworks = self.SpeechNetworks or {}
  local network = self.SpeechNetworks[key]
  if not network then
    network = {key=key, network_id=profile.network_id, coalition_id=coalition_id,
      mode=profile.arbitration, active={}, busy_until=0}
    self.SpeechNetworks[key] = network
  end
  return network
end

function MOOSE_BRIDGE:_SpeechTransmitter(profile, coalition_id)
  local modulation = profile.modulation == "AM" and radio.modulation.AM or radio.modulation.FM
  local key = table.concat({profile.profile_id, coalition_id}, ":")
  self.SpeechTransmitters = self.SpeechTransmitters or {}
  local item = self.SpeechTransmitters[key]
  if not item then
    local msrs = MSRS:New(profile.srs_path, profile.frequency_mhz, modulation, MSRS.Backend.HOUND)
    msrs:SetProvider(profile.provider)
    msrs:SetCoalition(coalition_id)
    msrs:SetVoice(profile.voice)
    msrs:SetVolume(profile.volume)
    msrs:SetLabel(profile.label)
    msrs:SetPort(profile.srs_port)
    item = {msrs=msrs, key=key}
    self.SpeechTransmitters[key] = item
  end
  return item
end

function MOOSE_BRIDGE:_SpeechTestTone(params)
  local profile = self:_SpeechProfileGuard(params)
  local sender = self:_ResolveSpeechSender(params.sender)
  HoundTTS.TestTone(string.format("%.3f", profile.frequency_mhz), profile.modulation,
    sender.coalition_id, 2, profile.volume)
  return {requested=true, frequency_mhz=profile.frequency_mhz,
    modulation=profile.modulation, coalition=sender.coalition_id,
    profile_id=profile.profile_id, sender_id=params.sender.sender_id}
end

function MOOSE_BRIDGE:_EnqueueSpeech(params)
  local profile = self:_SpeechProfileGuard(params)
  if not speech_string(params.intent_id, 128) then error("speech intent_id is invalid") end
  self.SpeechIntentHistory = self.SpeechIntentHistory or {}
  local previous = self.SpeechIntentHistory[params.intent_id]
  if previous then
    return {queued=previous.status == "queued", duplicate=true, status=previous.status,
      intent_id=params.intent_id, sender_queue_depth=previous.sender_queue_depth or 0,
      frequency_mhz=profile.frequency_mhz, modulation=profile.modulation,
      provider=profile.provider, voice=profile.voice}
  end
  if not speech_string(params.text, 1000) then error("speech text must contain 1..1000 printable bytes") end
  local priority = params.priority == nil and 50 or params.priority
  if not speech_number(priority, 1, 100) or priority ~= math.floor(priority) then
    error("speech priority must be an integer from 1 to 100")
  end
  if params.urgency ~= "routine" and params.urgency ~= "urgent" and params.urgency ~= "emergency" then
    error("speech urgency must be routine, urgent, or emergency")
  end
  if not speech_number(params.ttl_s, 0.1, 3600) then error("speech ttl_s must be between 0.1 and 3600") end
  if params.dedupe_key ~= nil and not speech_string(params.dedupe_key, 128) then
    error("speech dedupe_key is invalid")
  end
  local resolved = self:_ResolveSpeechSender(params.sender)
  local ok, duration = pcall(HoundTTS.getSpeechTime, params.text, profile.speed, false)
  if not ok or not speech_number(duration, 0.1, 600) then
    error("HoundTTS could not estimate the speech duration")
  end
  self.SpeechSenders = self.SpeechSenders or {}
  local sender = self.SpeechSenders[resolved.key]
  if not sender then
    sender = {key=resolved.key, descriptor=params.sender, queue={}}
    self.SpeechSenders[resolved.key] = sender
  end
  if params.dedupe_key then
    for index=#sender.queue, 1, -1 do
      if sender.queue[index].dedupe_key == params.dedupe_key then
        self.SpeechIntentHistory[sender.queue[index].intent_id] = {
          status="superseded", completed_at=speech_now()}
        table.remove(sender.queue, index)
      end
    end
  end
  self.SpeechSerial = (self.SpeechSerial or 0) + 1
  local now = speech_now()
  local network = self:_SpeechNetwork(profile, resolved.coalition_id)
  local intent = {intent_id=params.intent_id, profile=profile, sender=params.sender,
    sender_key=resolved.key, network_key=network.key, text=params.text,
    priority=priority, urgency=params.urgency, dedupe_key=params.dedupe_key,
    duration=duration, created_at=now, expires_at=now + params.ttl_s,
    available_at=now, serial=self.SpeechSerial, owner_id=params.owner_id}
  sender.queue[#sender.queue + 1] = intent
  table.sort(sender.queue, function(a, b)
    return a.priority > b.priority or (a.priority == b.priority and a.serial < b.serial)
  end)
  self.SpeechIntentHistory[params.intent_id] = {status="queued", created_at=now,
    sender_key=resolved.key, sender_queue_depth=#sender.queue}
  return {queued=true, estimated_duration_s=duration,
    sender_queue_depth=#sender.queue, network_id=profile.network_id,
    network_mode=profile.arbitration, intent_id=params.intent_id,
    frequency_mhz=profile.frequency_mhz, modulation=profile.modulation,
    provider=profile.provider, voice=profile.voice, priority=priority,
    urgency=params.urgency, expires_at=now + params.ttl_s}
end

function MOOSE_BRIDGE:_SpeechDrop(sender, index, status, now, reason)
  local intent = table.remove(sender.queue, index)
  if not intent then return nil end
  self.SpeechIntentHistory[intent.intent_id] = {status=status, completed_at=now,
    sender_key=sender.key, reason=reason}
  local ok, err = pcall(function()
    self:SendEvent("speech.intent." .. status, {intent_id=intent.intent_id,
      profile_id=intent.profile.profile_id, network_id=intent.profile.network_id,
      sender_id=intent.sender.sender_id, radio_id=intent.sender.radio_id,
      reason=reason})
  end)
  if not ok then self:_Log("Failed to forward speech intent state: " .. tostring(err)) end
  return intent
end

function MOOSE_BRIDGE:_StartSpeechIntent(sender, intent, network, now)
  local ok_resolve, resolved = pcall(function() return self:_ResolveSpeechSender(intent.sender) end)
  if not ok_resolve then
    self:_SpeechDrop(sender, 1, "dropped", now, "sender unavailable: " .. tostring(resolved))
    return false
  end
  if resolved.coalition_id ~= network.coalition_id then
    self:_SpeechDrop(sender, 1, "dropped", now, "sender coalition changed")
    return false
  end
  local transmitter = self:_SpeechTransmitter(intent.profile, resolved.coalition_id)
  local ok_play, err = pcall(function()
    transmitter.msrs:PlayTextExt(intent.text, nil, nil, nil, nil, nil, nil, nil, nil,
      resolved.coordinate, intent.profile.speed, nil)
  end)
  if not ok_play then
    self:_SpeechDrop(sender, 1, "dropped", now, "MSRS transmission failed: " .. tostring(err))
    return false
  end
  table.remove(sender.queue, 1)
  local transmission = {intent=intent, sender_key=sender.key, network_key=network.key,
    started_at=now, ends_at=now + intent.duration,
    guard_until=now + intent.duration + intent.profile.interval_s}
  sender.active = transmission
  network.active[intent.intent_id] = transmission
  if transmission.guard_until > network.busy_until then network.busy_until = transmission.guard_until end
  self.SpeechIntentHistory[intent.intent_id] = {status="transmitting", started_at=now,
    sender_key=sender.key, sender_queue_depth=#sender.queue}
  local ok_event, event_err = pcall(function()
    self:SendEvent("speech.transmission.started", {intent_id=intent.intent_id,
      profile_id=intent.profile.profile_id, network_id=intent.profile.network_id,
      sender_id=intent.sender.sender_id, radio_id=intent.sender.radio_id,
      priority=intent.priority, urgency=intent.urgency,
      estimated_duration_s=intent.duration})
  end)
  if not ok_event then self:_Log("Failed to forward speech start: " .. tostring(event_err)) end
  return true
end

function MOOSE_BRIDGE:_SpeechBackoff(intent)
  local minimum, maximum = intent.profile.backoff_min_s, intent.profile.backoff_max_s
  if maximum <= minimum then return minimum end
  return minimum + ((intent.serial * 7919) % 1000) / 1000 * (maximum - minimum)
end

function MOOSE_BRIDGE:_SpeechCollision(intent)
  return ((intent.serial * 7919) % 1000) / 1000 < intent.profile.collision_probability
end

function MOOSE_BRIDGE:_SpeechTick(now)
  if not self.SpeechConfig then return self end
  now = type(now) == "number" and now or speech_now()
  for _, sender in pairs(self.SpeechSenders or {}) do
    local active = sender.active
    if active and now >= active.ends_at then
      sender.active = nil
      local network = self.SpeechNetworks and self.SpeechNetworks[active.network_key]
      if network then network.active[active.intent.intent_id] = nil end
      self.SpeechIntentHistory[active.intent.intent_id] = {status="completed", completed_at=now,
        sender_key=sender.key, sender_queue_depth=#sender.queue}
      local ok, err = pcall(function()
        self:SendEvent("speech.transmission.completed", {intent_id=active.intent.intent_id,
          profile_id=active.intent.profile.profile_id, network_id=active.intent.profile.network_id,
          sender_id=active.intent.sender.sender_id, radio_id=active.intent.sender.radio_id})
      end)
      if not ok then self:_Log("Failed to forward speech completion: " .. tostring(err)) end
    end
    for index=#sender.queue, 1, -1 do
      if now >= sender.queue[index].expires_at then
        self:_SpeechDrop(sender, index, "expired", now, "time-to-live elapsed")
      end
    end
  end
  local candidates = {}
  for _, sender in pairs(self.SpeechSenders or {}) do
    local intent = not sender.active and sender.queue[1] or nil
    if intent and now >= intent.available_at then
      candidates[intent.network_key] = candidates[intent.network_key] or {}
      candidates[intent.network_key][#candidates[intent.network_key] + 1] = {sender=sender, intent=intent}
    end
  end
  for network_key, list in pairs(candidates) do
    local network = self.SpeechNetworks[network_key]
    table.sort(list, function(a, b)
      return a.intent.priority > b.intent.priority
        or (a.intent.priority == b.intent.priority and a.intent.serial < b.intent.serial)
    end)
    local busy = now < (network.busy_until or 0)
    if network.mode == "uncontrolled" then
      for _, candidate in ipairs(list) do
        self:_StartSpeechIntent(candidate.sender, candidate.intent, network, now)
      end
    elseif not busy then
      local first = table.remove(list, 1)
      if first then self:_StartSpeechIntent(first.sender, first.intent, network, now) end
      if network.mode == "congested" then
        for _, candidate in ipairs(list) do
          if self:_SpeechCollision(candidate.intent) then
            self:_StartSpeechIntent(candidate.sender, candidate.intent, network, now)
          end
        end
      end
      for _, candidate in ipairs(list) do
        if candidate.sender.queue[1] == candidate.intent then
          candidate.intent.available_at = math.max(candidate.intent.available_at,
            network.busy_until + (network.mode == "strict" and 0 or self:_SpeechBackoff(candidate.intent)))
        end
      end
    else
      local break_in
      for _, candidate in ipairs(list) do
        if candidate.intent.urgency == "emergency" and candidate.intent.profile.emergency_break_in then
          break_in = candidate
          break
        end
      end
      if break_in then self:_StartSpeechIntent(break_in.sender, break_in.intent, network, now) end
      if not break_in and network.mode == "congested" then
        for _, candidate in ipairs(list) do
          if self:_SpeechCollision(candidate.intent) then
            self:_StartSpeechIntent(candidate.sender, candidate.intent, network, now)
            break
          end
        end
      end
      for _, candidate in ipairs(list) do
        if candidate.sender.queue[1] == candidate.intent then
          candidate.intent.available_at = math.max(candidate.intent.available_at,
            network.busy_until + (network.mode == "strict" and 0 or self:_SpeechBackoff(candidate.intent)))
        end
      end
    end
  end
  for intent_id, history in pairs(self.SpeechIntentHistory or {}) do
    if history.completed_at and now - history.completed_at > 3600 then
      self.SpeechIntentHistory[intent_id] = nil
    end
  end
  return self
end

function MOOSE_BRIDGE:_ClearSpeechCommand(params)
  if not self.SpeechConfig or self.SpeechConfig.owner_id ~= params.owner_id then
    error("Speech service is not owned by this client")
  end
  if params.sender == nil then
    local active = {}
    for key, sender in pairs(self.SpeechSenders or {}) do
      for index=#sender.queue, 1, -1 do
        self:_SpeechDrop(sender, index, "canceled", speech_now(), "cleared by owner")
      end
      if sender.active then active[key] = sender end
    end
    self.SpeechSenders = active
    return {cleared=true, scope="all_pending"}
  end
  local key = self:_SpeechSenderKey(params.sender)
  local sender = self.SpeechSenders and self.SpeechSenders[key]
  local removed = sender and #sender.queue or 0
  if sender then
    for index=#sender.queue, 1, -1 do
      self:_SpeechDrop(sender, index, "canceled", speech_now(), "sender queue cleared by owner")
    end
  end
  return {cleared=true, scope="sender", sender_key=key, removed=removed}
end

function MOOSE_BRIDGE:_RemoveSpeechMenuSession(entry)
  for _, sender in pairs(self.SpeechSenders or {}) do
    for index=#sender.queue, 1, -1 do
      local descriptor = sender.queue[index].sender
      if descriptor.kind == "player" and descriptor.group_id == "GROUP:" .. entry.group:GetName()
        and descriptor.session_id == entry.session_id then
        self:_SpeechDrop(sender, index, "dropped", speech_now(), "player menu session ended")
      end
    end
  end
end

-- The bridge already ticks at 5 Hz. Compose speech arbitration into that
-- scheduler instead of creating one scheduler per sender or radio network.
local _speech_bridge_tick = MOOSE_BRIDGE._Tick
if type(_speech_bridge_tick) == "function" then
  function MOOSE_BRIDGE:_Tick(...)
    local result = _speech_bridge_tick(self, ...)
    if self.SpeechConfig then
      local ok, err = pcall(function() self:_SpeechTick() end)
      if not ok then self:_Log("Speech arbitration tick failed: " .. tostring(err)) end
    end
    return result
  end
end

local _speech_register_default_commands = MOOSE_BRIDGE.RegisterDefaultCommands
function MOOSE_BRIDGE:RegisterDefaultCommands()
  _speech_register_default_commands(self)
  self:RegisterCommand("speech.status", function(cmd)
    return self:_SpeechStatus()
  end)
  self:RegisterCommand("speech.configure", function(cmd)
    return self:_ConfigureSpeech(cmd.params or {})
  end)
  self:RegisterCommand("speech.test_tone", function(cmd)
    return self:_SpeechTestTone(cmd.params or {})
  end)
  self:RegisterCommand("speech.enqueue", function(cmd)
    return self:_EnqueueSpeech(cmd.params or {})
  end)
  self:RegisterCommand("speech.clear", function(cmd)
    return self:_ClearSpeechCommand(cmd.params or {})
  end)
end

