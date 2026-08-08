-- Optional INTEL snapshot and event extension for MOOSE Bridge.
--
-- MOOSE remains the owner of INTEL tactical logic. This extension only mirrors
-- registered INTEL objects and forwards their FSM events to Python.

local function bridge_intel_safe_tostring(value)
  if value == nil then return nil end
  return tostring(value)
end

local function bridge_intel_object_name(object)
  if not object then return nil end
  if MOOSE_BRIDGE and MOOSE_BRIDGE._ObjectName then
    local ok, value = pcall(function() return MOOSE_BRIDGE:_ObjectName(object) end)
    if ok and value then return value end
  end
  if object.alias then return tostring(object.alias) end
  if object.name then return tostring(object.name) end
  if object.Name then return tostring(object.Name) end
  if object.groupname then return tostring(object.groupname) end
  return nil
end

local function bridge_intel_auftrag_id(bridge, auftrag)
  if not auftrag then return nil end
  if bridge and bridge._AuftragObjectId then
    local ok, value = pcall(function() return bridge:_AuftragObjectId(auftrag) end)
    if ok and value then return value end
  end
  if auftrag.auftragsnummer then return "AUFTRAG:" .. tostring(auftrag.auftragsnummer) end
  if auftrag.name then return "AUFTRAG:" .. tostring(auftrag.name) end
  return nil
end

local function bridge_intel_point(bridge, value)
  if not value then return nil end
  if bridge and bridge._PointFromMooseObject then
    local ok, point = pcall(function() return bridge:_PointFromMooseObject(value) end)
    if ok and point then return point end
  end
  if type(value) == "table" and type(value.x) == "number" and type(value.z) == "number" then
    return value
  end
  return nil
end

local function bridge_intel_velocity(value)
  if type(value) ~= "table" then return nil end
  return {
    x=type(value.x) == "number" and value.x or nil,
    y=type(value.y) == "number" and value.y or nil,
    z=type(value.z) == "number" and value.z or nil,
  }
end

function MOOSE_BRIDGE:_EnsureIntelRegistry()
  self.RegisteredIntels = self.RegisteredIntels or {}
  return self.RegisteredIntels
end

function MOOSE_BRIDGE:RegisterIntel(intel, name)
  if not intel then return self end
  local intel_name = name or bridge_intel_object_name(intel) or intel.alias
  if not intel_name then return self end
  intel_name = tostring(intel_name)
  self:_EnsureIntelRegistry()[intel_name] = intel
  self:_AttachIntelEventForwarders(intel, intel_name)
  if type(intel.SetAgentAuto) ~= "function" then error("INTEL:SetAgentAuto is not available") end
  intel:SetAgentAuto()
  return self
end

function MOOSE_BRIDGE:RegisterIntels(intels)
  if type(intels) ~= "table" then return self end
  for name, intel in pairs(intels) do self:RegisterIntel(intel, name) end
  return self
end

function MOOSE_BRIDGE:_IntelObjectId(intel_name)
  return "INTEL:" .. tostring(intel_name)
end

function MOOSE_BRIDGE:_IntelContactId(intel_name, contact)
  local name = contact and contact.groupname or nil
  if not name then return nil end
  return "INTELCONTACT:" .. tostring(intel_name) .. ":" .. tostring(name)
end

function MOOSE_BRIDGE:_IntelClusterId(intel_name, cluster)
  local index = cluster and cluster.index or nil
  if not index then return nil end
  return "INTELCLUSTER:" .. tostring(intel_name) .. ":" .. tostring(index)
end

function MOOSE_BRIDGE:_IntelContactTargetObjectId(contact)
  if not contact then return nil end
  local name = contact.groupname
  if not name then return nil end
  if contact.isStatic then return "STATIC:" .. tostring(name) end
  return "GROUP:" .. tostring(name)
end

function MOOSE_BRIDGE:_IntelAgentCounts(intel)
  local detectionset = intel and intel.detectionset or nil
  if not detectionset then return 0, 0 end
  return detectionset:Count(), detectionset:CountAlive()
end

function MOOSE_BRIDGE:_IntelAgentSnapshot(intel)
  local result = {}
  local detectionset = intel and intel.detectionset or nil
  if not detectionset then return result, 0, 0 end

  for name, _ in pairs(detectionset.Set or {}) do
    result[#result + 1] = "GROUP:" .. tostring(name)
  end

  local agent_count, alive_agent_count = self:_IntelAgentCounts(intel)
  return result, agent_count, alive_agent_count
end

function MOOSE_BRIDGE:_ResolveRegisteredIntel(intel_id)
  local name = type(intel_id) == "string" and string.match(intel_id, "^INTEL:(.+)$") or nil
  if not name then return nil, nil, "Invalid INTEL object id: " .. tostring(intel_id) end
  local intel = self:_EnsureIntelRegistry()[name]
  if not intel then return nil, nil, "INTEL not registered: " .. name end
  return intel, name, nil
end

function MOOSE_BRIDGE:_ResolveIntelAgent(agent_id)
  local prefix, name
  if type(agent_id) == "string" then prefix, name = string.match(agent_id, "^([^:]+):(.+)$") end
  if not prefix or not name then return nil, "Invalid agent object id: " .. tostring(agent_id) end

  if prefix == "GROUP" then
    local group = GROUP and GROUP.FindByName and GROUP:FindByName(name) or nil
    if not group then return nil, "GROUP not found: " .. name end
    return group, nil
  end

  if prefix == "OPSGROUP" then
    if not self._ResolveOpsGroupById then
      return nil, "OPSGROUP agents require MooseBridgeAuftragExecutionExtension.lua"
    end
    return self:_ResolveOpsGroupById(agent_id)
  end

  return nil, "Agent must be GROUP:<name> or OPSGROUP:<name>"
end

function MOOSE_BRIDGE:_BuildIntelContactSnapshotItem(intel_name, contact, source)
  if type(contact) ~= "table" then return nil end
  local point = bridge_intel_point(self, contact.position)
  local recce_name = bridge_intel_safe_tostring(contact.recce)
  local recce_unit = recce_name and UNIT and UNIT.FindByName and UNIT:FindByName(recce_name) or nil
  local recce_group = recce_unit and self:_SafeCall(recce_unit, "GetGroup") or nil
  local recce_group_name = recce_group and self:_SafeCall(recce_group, "GetName") or nil
  local item = {
    object_id=self:_IntelContactId(intel_name, contact),
    dcs_name=bridge_intel_safe_tostring(contact.groupname),
    object_type="INTELCONTACT",
    category=bridge_intel_safe_tostring(contact.ctype or contact.categoryname),
    source=source,
    intel_id=self:_IntelObjectId(intel_name),
    target_object_id=self:_IntelContactTargetObjectId(contact),
    typename=bridge_intel_safe_tostring(contact.typename),
    attribute=bridge_intel_safe_tostring(contact.attribute),
    category_id=contact.category,
    category_name=bridge_intel_safe_tostring(contact.categoryname),
    threat_level=contact.threatlevel,
    detected_time=contact.Tdetected,
    recce=recce_name,
    recce_unit_id=recce_name and "UNIT:" .. recce_name or nil,
    recce_group_id=recce_group_name and "GROUP:" .. tostring(recce_group_name) or nil,
    contact_type=bridge_intel_safe_tostring(contact.ctype),
    speed_mps=contact.speed,
    velocity=bridge_intel_velocity(contact.velocity),
    is_ground=contact.isground and true or false,
    is_ship=contact.isship and true or false,
    is_static=contact.isStatic and true or false,
    platform=bridge_intel_safe_tostring(contact.platform),
    heading=contact.heading,
    maneuvering=contact.maneuvering and true or false,
    altitude_m=contact.altitude,
    rcs=contact.rcs,
    mission_id=bridge_intel_auftrag_id(self, contact.mission),
  }
  if point then self:_AddPointFields(item, point) end
  return item
end

function MOOSE_BRIDGE:_BuildIntelClusterSnapshotItem(intel_name, cluster, source)
  if type(cluster) ~= "table" then return nil end
  local point = bridge_intel_point(self, cluster.coordinate)
  local contact_ids = {}
  if type(cluster.Contacts) == "table" then
    for _, contact in pairs(cluster.Contacts) do
      local contact_id = self:_IntelContactId(intel_name, contact)
      if contact_id then contact_ids[#contact_ids + 1] = contact_id end
    end
  end
  local item = {
    object_id=self:_IntelClusterId(intel_name, cluster),
    dcs_name="Cluster " .. tostring(cluster.index or "?"),
    object_type="INTELCLUSTER",
    category=bridge_intel_safe_tostring(cluster.ctype),
    source=source,
    intel_id=self:_IntelObjectId(intel_name),
    index=cluster.index,
    size=cluster.size,
    contact_ids=contact_ids,
    threat_level_max=cluster.threatlevelMax,
    threat_level_sum=cluster.threatlevelSum,
    threat_level_avg=cluster.threatlevelAve,
    contact_type=bridge_intel_safe_tostring(cluster.ctype),
    altitude_m=cluster.altitude,
    mission_id=bridge_intel_auftrag_id(self, cluster.mission),
  }
  if point then self:_AddPointFields(item, point) end
  return item
end

function MOOSE_BRIDGE:_BuildIntelSnapshotItem(intel_name, intel, source)
  local contacts = self:_SafeCall(intel, "GetContactTable") or intel.Contacts or {}
  local clusters = self:_SafeCall(intel, "GetClusterTable") or intel.Clusters or {}
  local agent_ids, agent_count, alive_agent_count = self:_IntelAgentSnapshot(intel)
  return {
    object_id=self:_IntelObjectId(intel_name),
    dcs_name=tostring(intel_name),
    object_type="INTEL",
    category="INTEL",
    source=source,
    alias=bridge_intel_safe_tostring(intel.alias),
    coalition=self:_CoalitionToName(intel.coalition),
    state=self:_SafeCallArg(intel, "GetState") or nil,
    is_running=self:_SafeCallArg(intel, "Is", "Running") and true or false,
    cluster_analysis=intel.clusteranalysis and true or false,
    cluster_markers=intel.clustermarkers and true or false,
    cluster_arrows=intel.clusterarrows and true or false,
    cluster_radius_m=intel.clusterradius,
    detect_statics=intel.detectStatics and true or false,
    detect_accoustic=intel.DetectAccoustic and true or false,
    detect_accoustic_radius_m=intel.DetectAccousticRadius,
    doppler_radar=intel.DopplerRadar and true or false,
    contact_count=type(contacts) == "table" and #contacts or 0,
    cluster_count=type(clusters) == "table" and #clusters or 0,
    agent_count=agent_count,
    alive_agent_count=alive_agent_count,
    agent_ids=agent_ids,
  }
end

function MOOSE_BRIDGE:BuildIntelSnapshot()
  local result = {}
  for name, intel in pairs(self:_EnsureIntelRegistry()) do
    local ok, item = pcall(function() return self:_BuildIntelSnapshotItem(name, intel, "registered") end)
    if ok and item then result[#result + 1] = item end
  end
  return result
end

function MOOSE_BRIDGE:BuildIntelContactSnapshot()
  local result = {}
  for name, intel in pairs(self:_EnsureIntelRegistry()) do
    local contacts = self:_SafeCall(intel, "GetContactTable") or intel.Contacts or {}
    if type(contacts) == "table" then
      for _, contact in pairs(contacts) do
        local ok, item = pcall(function() return self:_BuildIntelContactSnapshotItem(name, contact, "registered") end)
        if ok and item and item.object_id then result[#result + 1] = item end
      end
    end
  end
  return result
end

function MOOSE_BRIDGE:BuildIntelClusterSnapshot()
  local result = {}
  for name, intel in pairs(self:_EnsureIntelRegistry()) do
    local clusters = self:_SafeCall(intel, "GetClusterTable") or intel.Clusters or {}
    if type(clusters) == "table" then
      for _, cluster in pairs(clusters) do
        local ok, item = pcall(function() return self:_BuildIntelClusterSnapshotItem(name, cluster, "registered") end)
        if ok and item and item.object_id then result[#result + 1] = item end
      end
    end
  end
  return result
end

function MOOSE_BRIDGE:_SendIntelEvent(event_name, intel_name, fsm_event, from_state, to_state, item_kind, item)
  local payload = {
    event=event_name,
    intel_id=self:_IntelObjectId(intel_name),
    fsm_event=fsm_event,
    from_state=from_state,
    to_state=to_state,
  }
  if item_kind == "contact" then
    payload.contact = item
    payload.contact_id = item and item.object_id or nil
    payload.target_object_id = item and item.target_object_id or nil
  elseif item_kind == "cluster" then
    payload.cluster = item
    payload.cluster_id = item and item.object_id or nil
  end
  self:SendEvent(event_name, payload)
end

function MOOSE_BRIDGE:_AttachIntelEventForwarders(intel, intel_name)
  if type(intel) ~= "table" or intel.MooseBridgeIntelEventsRegistered then return self end
  intel.MooseBridgeIntelEventsRegistered = true
  local bridge = self
  local previous_new_contact = intel.OnAfterNewContact
  local previous_lost_contact = intel.OnAfterLostContact
  local previous_new_cluster = intel.OnAfterNewCluster
  local previous_lost_cluster = intel.OnAfterLostCluster

  intel.OnAfterNewContact = function(intel_self, From, Event, To, Contact)
    if type(previous_new_contact) == "function" then pcall(previous_new_contact, intel_self, From, Event, To, Contact) end
    local item = bridge:_BuildIntelContactSnapshotItem(intel_name, Contact, "event")
    bridge:_SendIntelEvent("intel.new_contact", intel_name, Event, From, To, "contact", item)
  end

  intel.OnAfterLostContact = function(intel_self, From, Event, To, Contact)
    if type(previous_lost_contact) == "function" then pcall(previous_lost_contact, intel_self, From, Event, To, Contact) end
    local item = bridge:_BuildIntelContactSnapshotItem(intel_name, Contact, "event")
    bridge:_SendIntelEvent("intel.lost_contact", intel_name, Event, From, To, "contact", item)
  end

  intel.OnAfterNewCluster = function(intel_self, From, Event, To, Cluster)
    if type(previous_new_cluster) == "function" then pcall(previous_new_cluster, intel_self, From, Event, To, Cluster) end
    local item = bridge:_BuildIntelClusterSnapshotItem(intel_name, Cluster, "event")
    bridge:_SendIntelEvent("intel.new_cluster", intel_name, Event, From, To, "cluster", item)
  end

  intel.OnAfterLostCluster = function(intel_self, From, Event, To, Cluster, Mission)
    if type(previous_lost_cluster) == "function" then pcall(previous_lost_cluster, intel_self, From, Event, To, Cluster, Mission) end
    local item = bridge:_BuildIntelClusterSnapshotItem(intel_name, Cluster, "event")
    if item and not item.mission_id then item.mission_id = bridge_intel_auftrag_id(bridge, Mission) end
    bridge:_SendIntelEvent("intel.lost_cluster", intel_name, Event, From, To, "cluster", item)
  end

  return self
end

local _moose_bridge_base_register_default_commands_for_intel = MOOSE_BRIDGE.RegisterDefaultCommands

function MOOSE_BRIDGE:RegisterDefaultCommands()
  _moose_bridge_base_register_default_commands_for_intel(self)

  local previous_snapshot_all = self.CommandHandlers["snapshot.all"]

  self:RegisterCommand("snapshot.intels", function(cmd)
    local intels = self:BuildIntelSnapshot()
    self:SendSnapshot("intels", {intels=intels})
    return {kind="intels", count=#intels}
  end)

  self:RegisterCommand("intel.add_agent", function(cmd)
    local params = self:_CommandParams(cmd)
    local intel, intel_name, intel_err = self:_ResolveRegisteredIntel(params.intel_id)
    if not intel then error(intel_err) end
    local agent, agent_err = self:_ResolveIntelAgent(params.agent_id)
    if not agent then error(agent_err) end

    intel:AddAgent(agent)
    local agent_count, alive_agent_count = self:_IntelAgentCounts(intel)
    return {
      action="intel.add_agent",
      intel_id=self:_IntelObjectId(intel_name),
      agent_id=params.agent_id,
      agent_count=agent_count,
      alive_agent_count=alive_agent_count,
    }
  end)

  self:RegisterCommand("snapshot.intel_contacts", function(cmd)
    local contacts = self:BuildIntelContactSnapshot()
    self:SendSnapshot("intel_contacts", {intel_contacts=contacts})
    return {kind="intel_contacts", count=#contacts}
  end)

  self:RegisterCommand("snapshot.intel_clusters", function(cmd)
    local clusters = self:BuildIntelClusterSnapshot()
    self:SendSnapshot("intel_clusters", {intel_clusters=clusters})
    return {kind="intel_clusters", count=#clusters}
  end)

  if previous_snapshot_all then
    self:RegisterCommand("snapshot.all", function(cmd)
      local result = previous_snapshot_all(cmd) or {}
      local intels = self:BuildIntelSnapshot()
      local contacts = self:BuildIntelContactSnapshot()
      local clusters = self:BuildIntelClusterSnapshot()
      self:SendSnapshot("intels", {intels=intels})
      self:SendSnapshot("intel_contacts", {intel_contacts=contacts})
      self:SendSnapshot("intel_clusters", {intel_clusters=clusters})
      result.intels = #intels
      result.intel_contacts = #contacts
      result.intel_clusters = #clusters
      return result
    end)
  end
end
