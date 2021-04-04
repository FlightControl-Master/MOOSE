--- **Ops** - Office of Military Intelligence.
--
-- **Main Features:**
--
--    * Detect and track contacts consistently
--    * Detect and track clusters of contacts consistently
--    * Use FSM events to link functionality into your scripts
--    * Easy setup 
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Intel
-- @image OPS_Intel.png


--- INTEL class.
-- @type INTEL
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number coalition Coalition side number, e.g. `coalition.side.RED`.
-- @field #string alias Name of the agency.
-- @field Core.Set#SET_GROUP detectionset Set of detection groups, aka agents.
-- @field #table filterCategory Filter for unit categories.
-- @field #table filterCategoryGroup Filter for group categories.
-- @field Core.Set#SET_ZONE acceptzoneset Set of accept zones. If defined, only contacts in these zones are considered.
-- @field Core.Set#SET_ZONE rejectzoneset Set of reject zones. Contacts in these zones are not considered, even if they are in accept zones.
-- @field #table Contacts Table of detected items.
-- @field #table ContactsLost Table of lost detected items.
-- @field #table ContactsUnknown Table of new detected items.
-- @field #table Clusters Clusters of detected groups.
-- @field #boolean clusteranalysis If true, create clusters of detected targets.
-- @field #boolean clustermarkers If true, create cluster markers on F10 map. 
-- @field #number clustercounter Running number of clusters.
-- @field #number dTforget Time interval in seconds before a known contact which is not detected any more is forgotten.
-- @field #number clusterradius Radius im kilometers in which groups/units are considered to belong to a cluster
-- @extends Core.Fsm#FSM

--- Top Secret!
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\INTEL_Main.jpg)
--
-- # The INTEL Concept
-- 
--  * Lightweight replacement for @{Functional.Detection#DETECTION}
--  * Detect and track contacts consistently
--  * Detect and track clusters of contacts consistently
--  * Once detected and still alive, planes will be tracked 10 minutes, helicopters 20 minutes, ships and trains 1 hour, ground units 2 hours
--  * Use FSM events to link functionality into your scripts
-- 
-- # Basic Usage 
--
--  ## set up a detection SET_GROUP  
--  
--  `Red_DetectionSetGroup = SET_GROUP:New()`  
--  `Red_DetectionSetGroup:FilterPrefixes( { "Red EWR" } )`  
--  `Red_DetectionSetGroup:FilterOnce()`  
--  
--  ## New Intel type detection for the red side, logname "KGB"    
--  
--  `RedIntel = INTEL:New(Red_DetectionSetGroup,"red","KGB")`  
--  `RedIntel:SetClusterAnalysis(true,true)`  
--  `RedIntel:SetVerbosity(2)`  
--  `RedIntel:Start()`  
--  
--  ## Hook into new contacts found  
--  
--  `function RedIntel:OnAfterNewContact(From, Event, To, Contact)`  
--        `local text = string.format("NEW contact %s detected by %s", Contact.groupname, Contact.recce or "unknown")`  
--        `local m = MESSAGE:New(text,15,"KGB"):ToAll()`  
-- `end`  
-- 
--  ## And/or new clusters found  
--  
-- `function RedIntel:OnAfterNewCluster(From, Event, To, Contact, Cluster)`  
--        `local text = string.format("NEW cluster %d size %d with contact %s", Cluster.index, Cluster.size, Contact.groupname)`  
--        `local m = MESSAGE:New(text,15,"KGB"):ToAll()`  
-- `end`   
-- 
--
-- @field #INTEL
INTEL = {
  ClassName       = "INTEL",
  verbose         =     0,
  lid             =   nil,
  alias           =   nil,
  filterCategory  =    {},
  detectionset    =   nil,
  Contacts        =    {},
  ContactsLost    =    {},
  ContactsUnknown =    {},
  Clusters        =    {},
  clustercounter  =     1,
  clusterradius   =   15,
}

--- Detected item info.
-- @type INTEL.Contact
-- @field #string groupname Name of the group.
-- @field Wrapper.Group#GROUP group The contact group.
-- @field #string typename Type name of detected item.
-- @field #number category Category number.
-- @field #string categoryname Category name.
-- @field #string attribute Generalized attribute.
-- @field #number threatlevel Threat level of this item.
-- @field #number Tdetected Time stamp in abs. mission time seconds when this item was last detected.
-- @field Core.Point#COORDINATE position Last known position of the item.
-- @field DCS#Vec3 velocity 3D velocity vector. Components x,y and z in m/s.
-- @field #number speed Last known speed in m/s.
-- @field #boolean isship
-- @field #boolean ishelo
-- @field #boolean isgrund
-- @field Ops.Auftrag#AUFTRAG mission The current Auftrag attached to this contact
-- @field #string recce The name of the recce unit that detected this contact

--- Cluster info.
-- @type INTEL.Cluster
-- @field #number index Cluster index.
-- @field #number size Number of groups in the cluster.
-- @field #table Contacts Table of contacts in the cluster.
-- @field #number threatlevelMax Max threat level of cluster.
-- @field #number threatlevelSum Sum of threat levels.
-- @field #number threatlevelAve Average of threat levels.
-- @field Core.Point#COORDINATE coordinate Coordinate of the cluster.
-- @field Wrapper.Marker#MARKER marker F10 marker.
-- @field Ops.Auftrag#AUFTRAG mission The current Auftrag attached to this cluster


--- INTEL class version.
-- @field #string version
INTEL.version="0.2.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Filter detection methods.
-- TODO: process detected set asynchroniously for better performance.
-- DONE: Accept zones.
-- DONE: Reject zones.
-- NOGO: SetAttributeZone --> return groups of generalized attributes in a zone.
-- DONE: Loose units only if they remain undetected for a given time interval. We want to avoid fast oscillation between detected/lost states. Maybe 1-5 min would be a good time interval?!
-- DONE: Combine units to groups for all, new and lost.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new INTEL object and start the FSM.
-- @param #INTEL self
-- @param Core.Set#SET_GROUP DetectionSet Set of detection groups.
-- @param #number Coalition Coalition side. Can also be passed as a string "red", "blue" or "neutral".
-- @param #string Alias An *optional* alias how this object is called in the logs etc.
-- @return #INTEL self
function INTEL:New(DetectionSet, Coalition, Alias)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #INTEL

  -- Detection set.
  self.detectionset=DetectionSet or SET_GROUP:New()
  
  if Coalition and type(Coalition)=="string" then
    if Coalition=="blue" then
      Coalition=coalition.side.BLUE
    elseif Coalition=="red" then
      Coalition=coalition.side.RED
    elseif Coalition=="neutral" then
      Coalition=coalition.side.NEUTRAL
    else
      self:E("ERROR: Unknown coalition in INTEL!")
    end
  end
  
  -- Determine coalition from first group in set.
  self.coalition=Coalition or DetectionSet:CountAlive()>0 and DetectionSet:GetFirst():GetCoalition() or nil
  
  -- Filter coalition.
  if self.coalition then
    local coalitionname=UTILS.GetCoalitionName(self.coalition):lower()
    self.detectionset:FilterCoalitions(coalitionname)
  end
  
  -- Filter once.
  self.detectionset:FilterOnce()
  
  -- Set alias.
  if Alias then
    self.alias=tostring(Alias)
  else
    self.alias="SPECTRE"  
    if self.coalition then
      if self.coalition==coalition.side.RED then
        self.alias="KGB"
      elseif self.coalition==coalition.side.BLUE then
        self.alias="CIA"
      end
    end
  end
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("INTEL %s (%s) | ", self.alias, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")

  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- INTEL status update
  
  self:AddTransition("*",             "Detect",             "*")           -- Start detection run. Not implemented yet!
  
  self:AddTransition("*",             "NewContact",         "*")           -- New contact has been detected.
  self:AddTransition("*",             "LostContact",        "*")           -- Contact could not be detected any more.
  
  self:AddTransition("*",             "NewCluster",         "*")           -- New cluster has been detected.
  self:AddTransition("*",             "LostCluster",         "*")          -- Cluster could not be detected any more.
  
  -- Defaults
  self:SetForgetTime()
  self:SetAcceptZones()
  self:SetRejectZones()

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the INTEL. Initializes parameters and starts event handlers.
  -- @function [parent=#INTEL] Start
  -- @param #INTEL self

  --- Triggers the FSM event "Start" after a delay. Starts the INTEL. Initializes parameters and starts event handlers.
  -- @function [parent=#INTEL] __Start
  -- @param #INTEL self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the INTEL and all its event handlers.
  -- @param #INTEL self

  --- Triggers the FSM event "Stop" after a delay. Stops the INTEL and all its event handlers.
  -- @function [parent=#INTEL] __Stop
  -- @param #INTEL self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#INTEL] Status
  -- @param #INTEL self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#INTEL] __Status
  -- @param #INTEL self
  -- @param #number delay Delay in seconds.
  
  --- On After "NewContact" event.
  -- @function [parent=#INTEL] OnAfterNewContact
  -- @param #INTEL self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #INTEL.Contact Contact Detected contact.
  
  --- On After "LostContact" event.
  -- @function [parent=#INTEL] OnAfterLostContact
  -- @param #INTEL self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #INTEL.Contact Contact Lost contact.
  
  --- On After "NewCluster" event.
  -- @function [parent=#INTEL] OnAfterNewCluster
  -- @param #INTEL self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #INTEL.Contact Contact Detected contact.
  -- @param #INTEL.Cluster Cluster Detected cluster
  
  --- On After "LostCluster" event.
  -- @function [parent=#INTEL] OnAfterLostCluster
  -- @param #INTEL self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #INTEL.Cluster Cluster Lost cluster
  -- @param Ops.Auftrag#AUFTRAG Mission The Auftrag connected with this cluster or nil

  return self
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set accept zones. Only contacts detected in this/these zone(s) are considered. 
-- @param #INTEL self
-- @param Core.Set#SET_ZONE AcceptZoneSet Set of accept zones.
-- @return #INTEL self
function INTEL:SetAcceptZones(AcceptZoneSet)
  self.acceptzoneset=AcceptZoneSet or SET_ZONE:New()
  return self
end

--- Add an accept zone. Only contacts detected in this zone are considered.
-- @param #INTEL self
-- @param Core.Zone#ZONE AcceptZone Add a zone to the accept zone set.
-- @return #INTEL self
function INTEL:AddAcceptZone(AcceptZone)
  self.acceptzoneset:AddZone(AcceptZone)
  return self
end

--- Remove an accept zone from the accept zone set.
-- @param #INTEL self
-- @param Core.Zone#ZONE AcceptZone Remove a zone from the accept zone set.
-- @return #INTEL self
function INTEL:RemoveAcceptZone(AcceptZone)
  self.acceptzoneset:Remove(AcceptZone:GetName(), true)
  return self
end

--- Set reject zones. Contacts detected in this/these zone(s) are rejected and not reported by the detection.
-- Note that reject zones overrule accept zones, i.e. if a unit is inside and accept zone and inside a reject zone, it is rejected.
-- @param #INTEL self
-- @param Core.Set#SET_ZONE RejectZoneSet Set of reject zone(s).
-- @return #INTEL self
function INTEL:SetRejectZones(RejectZoneSet)
  self.rejectzoneset=RejectZoneSet or SET_ZONE:New()
  return self
end

--- Add a reject zone. Contacts detected in this zone are rejected and not reported by the detection.
-- Note that reject zones overrule accept zones, i.e. if a unit is inside and accept zone and inside a reject zone, it is rejected.
-- @param #INTEL self
-- @param Core.Zone#ZONE RejectZone Add a zone to the reject zone set.
-- @return #INTEL self
function INTEL:AddRejectZone(RejectZone)
  self.rejectzoneset:AddZone(RejectZone)
  return self
end

--- Remove a reject zone from the reject zone set.
-- @param #INTEL self
-- @param Core.Zone#ZONE RejectZone Remove a zone from the reject zone set.
-- @return #INTEL self
function INTEL:RemoveRejectZone(RejectZone)
  self.rejectzoneset:Remove(RejectZone:GetName(), true)
  return self
end

--- Set forget contacts time interval. 
-- Previously known contacts that are not detected any more, are "lost" after this time.
-- This avoids fast oscillations between a contact being detected and undetected.
-- @param #INTEL self
-- @param #number TimeInterval Time interval in seconds. Default is 120 sec.
-- @return #INTEL self
function INTEL:SetForgetTime(TimeInterval)
  self.dTforget=TimeInterval or 120
  return self
end

--- Filter unit categories. Valid categories are:
-- 
-- * Unit.Category.AIRPLANE
-- * Unit.Category.HELICOPTER
-- * Unit.Category.GROUND_UNIT
-- * Unit.Category.SHIP
-- * Unit.Category.STRUCTURE
-- 
-- @param #INTEL self
-- @param #table Categories Filter categories, e.g. {Unit.Category.AIRPLANE, Unit.Category.HELICOPTER}.
-- @return #INTEL self
function INTEL:SetFilterCategory(Categories)
  if type(Categories)~="table" then
    Categories={Categories}
  end
  
  self.filterCategory=Categories
  
  local text="Filter categories: "
  for _,category in pairs(self.filterCategory) do
    text=text..string.format("%d,", category)
  end
  self:T(self.lid..text)
  
  return self
end

--- Filter group categories. Valid categories are:
-- 
-- * Group.Category.AIRPLANE
-- * Group.Category.HELICOPTER
-- * Group.Category.GROUND
-- * Group.Category.SHIP
-- * Group.Category.TRAIN
-- 
-- @param #INTEL self
-- @param #table GroupCategories Filter categories, e.g. `{Group.Category.AIRPLANE, Group.Category.HELICOPTER}`.
-- @return #INTEL self
function INTEL:FilterCategoryGroup(GroupCategories)
  if type(GroupCategories)~="table" then
    GroupCategories={GroupCategories}
  end
    
  self.filterCategoryGroup=GroupCategories
  
  local text="Filter group categories: "
  for _,category in pairs(self.filterCategoryGroup) do
    text=text..string.format("%d,", category)
  end
  self:T(self.lid..text)
  
  return self
end

--- Enable or disable cluster analysis of detected targets.
-- Targets will be grouped in coupled clusters.
-- @param #INTEL self
-- @param #boolean Switch If true, enable cluster analysis.
-- @param #boolean Markers If true, place markers on F10 map.
-- @return #INTEL self
function INTEL:SetClusterAnalysis(Switch, Markers)
  self.clusteranalysis=Switch
  self.clustermarkers=Markers
  return self
end

--- Set verbosity level for debugging. 
-- @param #INTEL self
-- @param #number Verbosity The higher, the noisier, e.g. 0=off, 2=debug
-- @return #INTEL self
function INTEL:SetVerbosity(Verbosity)
  self.verbose=Verbosity or 2
  return self
end

--- Add a Mission (Auftrag) to a contact for tracking.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact
-- @param Ops.Auftrag#AUFTRAG Mission The mission connected with this contact
-- @return #INTEL self
function INTEL:AddMissionToContact(Contact, Mission)
  if Mission and Contact then
    Contact.mission = Mission
  end
  return self
end

--- Add a Mission (Auftrag) to a cluster for tracking.
-- @param #INTEL self
-- @param #INTEL.Cluster Cluster The cluster
-- @param Ops.Auftrag#AUFTRAG Mission The mission connected with this cluster
-- @return #INTEL self
function INTEL:AddMissionToCluster(Cluster, Mission)
  if Mission and Cluster then
    Cluster.mission = Mission
  end
  return self
end

--- Change radius of the Clusters
-- @param #INTEL self
-- @param #number radius The radius of the clusters
-- @return #INTEL self
function INTEL:SetClusterRadius(radius)
  local radius = radius or 15
  self.clusterradius = radius
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #INTEL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function INTEL:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting INTEL v%s", self.version)
  self:I(self.lid..text)

  -- Start the status monitoring.
  self:__Status(-math.random(10))
end

--- On after "Status" event.
-- @param #INTEL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function INTEL:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  -- Fresh arrays.
  self.ContactsLost={}
  self.ContactsUnknown={}
  
  -- Check if group has detected any units.
  self:UpdateIntel()
  
  -- Number of total contacts.
  local Ncontacts=#self.Contacts
  local Nclusters=#self.Clusters

  -- Short info.
  if self.verbose>=1 then
    local text=string.format("Status %s [Agents=%s]: Contacts=%d, Clusters=%d, New=%d, Lost=%d", fsmstate, self.detectionset:CountAlive(), Ncontacts, Nclusters, #self.ContactsUnknown, #self.ContactsLost)
    self:I(self.lid..text)
  end
  
  -- Detailed info.
  if self.verbose>=2 and Ncontacts>0 then
    local text="Detected Contacts:"
    for _,_contact in pairs(self.Contacts) do
      local contact=_contact --#INTEL.Contact
      local dT=timer.getAbsTime()-contact.Tdetected
      text=text..string.format("\n- %s (%s): %s, units=%d, T=%d sec", contact.categoryname, contact.attribute, contact.groupname, contact.group:CountAliveUnits(), dT)
      if contact.mission then
        local mission=contact.mission --Ops.Auftrag#AUFTRAG
        text=text..string.format(" mission name=%s type=%s target=%s", mission.name, mission.type, mission:GetTargetName() or "unkown")
      end
    end
    self:I(self.lid..text)
  end  

  self:__Status(-60) 
end


--- Update detected items.
-- @param #INTEL self
function INTEL:UpdateIntel()

  -- Set of all detected units.
  local DetectedUnits={}
  -- Set of which units was detected by which recce
  local RecceDetecting = {}
  -- Loop over all units providing intel.
  for _,_group in pairs(self.detectionset.Set or {}) do
    local group=_group --Wrapper.Group#GROUP
    
    if group and group:IsAlive() then
    
      for _,_recce in pairs(group:GetUnits()) do
        local recce=_recce --Wrapper.Unit#UNIT
        
        -- Get detected units.
        self:GetDetectedUnits(recce, DetectedUnits, RecceDetecting)
        
      end
      
    end    
  end
  
  -- TODO: Filter detection methods?
  local remove={}
  for unitname,_unit in pairs(DetectedUnits) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    -- Check if unit is in any of the accept zones.
    if self.acceptzoneset:Count()>0 then
      local inzone=false
      for _,_zone in pairs(self.acceptzoneset.Set) do
        local zone=_zone --Core.Zone#ZONE
        if unit:IsInZone(zone) then
          inzone=true
          break
        end
      end
      
      -- Unit is not in accept zone ==> remove!
      if not inzone then
        table.insert(remove, unitname)
      end
    end

    -- Check if unit is in any of the reject zones.
    if self.rejectzoneset:Count()>0 then
      local inzone=false
      for _,_zone in pairs(self.rejectzoneset.Set) do
        local zone=_zone --Core.Zone#ZONE
        if unit:IsInZone(zone) then
          inzone=true
          break
        end
      end
      
      -- Unit is inside a reject zone ==> remove!
      if inzone then
        table.insert(remove, unitname)
      end
    end
    
    -- Filter unit categories.
    if #self.filterCategory>0 then
      local unitcategory=unit:GetUnitCategory()
      local keepit=false
      for _,filtercategory in pairs(self.filterCategory) do
        if unitcategory==filtercategory then
          keepit=true
          break
        end
      end
      if not keepit then
        self:T(self.lid..string.format("Removing unit %s category=%d", unitname, unit:GetCategory()))
        table.insert(remove, unitname)
      end
    end    
        
  end
  
  -- Remove filtered units.
  for _,unitname in pairs(remove) do
    DetectedUnits[unitname]=nil
  end
  
  -- Create detected groups.
  local DetectedGroups={}
  local RecceGroups={}  
  for unitname,_unit in pairs(DetectedUnits) do
    local unit=_unit --Wrapper.Unit#UNIT
    local group=unit:GetGroup()
    if group then
      local groupname = group:GetName()
      DetectedGroups[groupname]=group
      RecceGroups[groupname]=RecceDetecting[unitname]
    end
  end
  
  -- Create detected contacts.  
  self:CreateDetectedItems(DetectedGroups, RecceGroups)
  
  -- Paint a picture of the battlefield.
  if self.clusteranalysis then
    self:PaintPicture()
  end
  
end





--- Create detected items.
-- @param #INTEL self
-- @param #table DetectedGroups Table of detected Groups
-- @param #table RecceDetecting Table of detecting recce names
function INTEL:CreateDetectedItems(DetectedGroups, RecceDetecting)
  self:F({RecceDetecting=RecceDetecting})
  -- Current time.
  local Tnow=timer.getAbsTime()
  
  for groupname,_group in pairs(DetectedGroups) do
    local group=_group --Wrapper.Group#GROUP
    
    
    -- Get contact if already known.
    local detecteditem=self:GetContactByName(groupname)
    
    if detecteditem then
      ---
      -- Detected item already exists ==> Update data.
      ---
    
      detecteditem.Tdetected=Tnow
      detecteditem.position=group:GetCoordinate()
      detecteditem.velocity=group:GetVelocityVec3()
      detecteditem.speed=group:GetVelocityMPS()
    
    else    
      ---
      -- Detected item does not exist in our list yet.
      ---
    
      -- Create new contact.
      local item={} --#INTEL.Contact
      
      item.groupname=groupname
      item.group=group
      item.Tdetected=Tnow
      item.typename=group:GetTypeName()
      item.attribute=group:GetAttribute()
      item.category=group:GetCategory()
      item.categoryname=group:GetCategoryName()
      item.threatlevel=group:GetThreatLevel()
      item.position=group:GetCoordinate()
      item.velocity=group:GetVelocityVec3()
      item.speed=group:GetVelocityMPS()
      item.recce=RecceDetecting[groupname]
      self:T(string.format("%s group detect by %s/%s", groupname, RecceDetecting[groupname] or "unknonw", item.recce or "unknown"))
      -- Add contact to table.    
      self:AddContact(item)
      
      -- Trigger new contact event.
      self:NewContact(item)
    end
    
  end
  
  -- Now check if there some groups could not be detected any more.
  for i=#self.Contacts,1,-1 do
    local item=self.Contacts[i] --#INTEL.Contact
    
    -- Check if deltaT>Tforget. We dont want quick oscillations between detected and undetected states.
    if self:_CheckContactLost(item) then
    
      -- Trigger LostContact event. This also adds the contact to the self.ContactsLost table.
      self:LostContact(item)
      
      -- Remove contact from table.
      self:RemoveContact(item)
            
    end
  end

end

--- Return the detected target groups of the controllable as a @{SET_GROUP}.
-- The optional parametes specify the detection methods that can be applied.
-- If no detection method is given, the detection will use all the available methods by default.
-- @param #INTEL self
-- @param Wrapper.Unit#UNIT Unit The unit detecting.
-- @param #table DetectedUnits Table of detected units to be filled
-- @param #table RecceDetecting Table of recce per unit to be filled
-- @param #boolean DetectVisual (Optional) If *false*, do not include visually detected targets.
-- @param #boolean DetectOptical (Optional) If *false*, do not include optically detected targets.
-- @param #boolean DetectRadar (Optional) If *false*, do not include targets detected by radar.
-- @param #boolean DetectIRST (Optional) If *false*, do not include targets detected by IRST.
-- @param #boolean DetectRWR (Optional) If *false*, do not include targets detected by RWR.
-- @param #boolean DetectDLINK (Optional) If *false*, do not include targets detected by data link.
function INTEL:GetDetectedUnits(Unit, DetectedUnits, RecceDetecting, DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK)

  -- Get detected DCS units.
  local detectedtargets=Unit:GetDetectedTargets(DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK)
  local reccename = Unit:GetName()
  
  for DetectionObjectID, Detection in pairs(detectedtargets or {}) do
    local DetectedObject=Detection.object -- DCS#Object

    if DetectedObject and DetectedObject:isExist() and DetectedObject.id_<50000000 then
    
      local unit=UNIT:Find(DetectedObject)

      if unit and unit:IsAlive() then
      
        local unitname=unit:GetName()
        
        DetectedUnits[unitname]=unit
        RecceDetecting[unitname]=reccename
        self:T(string.format("Unit %s detect by %s", unitname, reccename))
      end
    end
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "NewContact" event.
-- @param #INTEL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #INTEL.Contact Contact Detected contact.
function INTEL:onafterNewContact(From, Event, To, Contact)
  self:F(self.lid..string.format("NEW contact %s", Contact.groupname))
  table.insert(self.ContactsUnknown, Contact) 
end

--- On after "LostContact" event.
-- @param #INTEL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #INTEL.Contact Contact Detected contact.
function INTEL:onafterLostContact(From, Event, To, Contact)
  self:F(self.lid..string.format("LOST contact %s", Contact.groupname))
  table.insert(self.ContactsLost, Contact)
end

--- On after "NewCluster" event.
-- @param #INTEL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #INTEL.Contact Contact Detected contact.
-- @param #INTEL.Cluster Cluster Detected cluster
function INTEL:onafterNewCluster(From, Event, To, Contact, Cluster)
  self:F(self.lid..string.format("NEW cluster %d size %d with contact %s", Cluster.index, Cluster.size, Contact.groupname))
end

--- On after "LostCluster" event.
-- @param #INTEL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #INTEL.Cluster Cluster Lost cluster
-- @param Ops.Auftrag#AUFTRAG Mission The Auftrag connected with this cluster or nil
function INTEL:onafterLostCluster(From, Event, To, Cluster, Mission)
  local text = self.lid..string.format("LOST cluster %d", Cluster.index)
  if Mission then
    local mission=Mission --Ops.Auftrag#AUFTRAG
    text=text..string.format(" mission name=%s type=%s target=%s", mission.name, mission.type, mission:GetTargetName() or "unkown")
  end
  self:T(text)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get a contact by name.
-- @param #INTEL self
-- @param #string groupname Name of the contact group.
-- @return #INTEL.Contact The contact.
function INTEL:GetContactByName(groupname)

  for i,_contact in pairs(self.Contacts) do
    local contact=_contact --#INTEL.Contact
    if contact.groupname==groupname then
      return contact
    end
  end

  return nil
end

--- Add a contact to our list.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact to be added.
function INTEL:AddContact(Contact)
  table.insert(self.Contacts, Contact)
end

--- Remove a contact from our list.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact to be removed.
function INTEL:RemoveContact(Contact)

  for i,_contact in pairs(self.Contacts) do
    local contact=_contact --#INTEL.Contact
    
    if contact.groupname==Contact.groupname then
      table.remove(self.Contacts, i)
    end
  
  end

end

--- Check if a contact was lost.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact to be removed.
-- @return #boolean If true, contact was not detected for at least *dTforget* seconds.
function INTEL:_CheckContactLost(Contact)

  -- Group dead?
  if Contact.group==nil or not Contact.group:IsAlive() then
    return true
  end

  -- Time since last detected.
  local dT=timer.getAbsTime()-Contact.Tdetected
  
  local dTforget=self.dTforget
  if Contact.category==Group.Category.GROUND then
    dTforget=60*60*2  -- 2 hours
  elseif Contact.category==Group.Category.AIRPLANE then
    dTforget=60*10    -- 10 min
  elseif Contact.category==Group.Category.HELICOPTER then
    dTforget=60*20    -- 20 min
  elseif Contact.category==Group.Category.SHIP then
    dTforget=60*60    -- 1 hour
  elseif Contact.category==Group.Category.TRAIN then
    dTforget=60*60    -- 1 hour
  end
  
  if dT>dTforget then
    return true
  else
    return false
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Cluster Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Paint picture of the battle field.
-- @param #INTEL self 
function INTEL:PaintPicture()

  -- First remove all lost contacts from clusters.
  for _,_contact in pairs(self.ContactsLost) do
    local contact=_contact --#INTEL.Contact
    local cluster=self:GetClusterOfContact(contact)
    if cluster then
      self:RemoveContactFromCluster(contact, cluster)
    end
  end
  -- clean up cluster table
  local ClusterSet = {}
  for _i,_cluster in pairs(self.Clusters) do
    if (_cluster.size > 0) and (self:ClusterCountUnits(_cluster) > 0) then
      table.insert(ClusterSet,_cluster)
    else
      local mission = _cluster.mission or nil
      local marker = _cluster.marker
      if marker then
        marker:Remove()
      end
      self:LostCluster(_cluster, mission)
    end
  end
  self.Clusters = ClusterSet
  -- update positions
  self:_UpdateClusterPositions()
  
  for _,_contact in pairs(self.Contacts) do
    local contact=_contact --#INTEL.Contact
    self:T(string.format("Paint Picture: checking for %s",contact.groupname))
    -- Check if this contact is in any cluster.
    local isincluster=self:CheckContactInClusters(contact)
    
    -- Get the current cluster (if any) this contact belongs to.
    local currentcluster=self:GetClusterOfContact(contact)
    
    if currentcluster then
      --self:I(string.format("Paint Picture: %s has current cluster",contact.groupname))
      ---
      -- Contact is currently part of a cluster.
      ---
    
      -- Check if the contact is still connected to the cluster.
      local isconnected=self:IsContactConnectedToCluster(contact, currentcluster)
      
      if (not isconnected) and (currentcluster.size > 1) then
        --self:I(string.format("Paint Picture: %s has LOST current cluster",contact.groupname))
        local cluster=self:IsContactPartOfAnyClusters(contact)
        
        if cluster then
          self:AddContactToCluster(contact, cluster)
        else
        
          local newcluster=self:CreateCluster(contact.position)
          self:AddContactToCluster(contact, newcluster)
          self:NewCluster(contact, newcluster)
        end
      
      end
      
    
    else
    
      ---
      -- Contact is not in any cluster yet.
      ---
      --self:I(string.format("Paint Picture: %s has NO current cluster",contact.groupname))
      local cluster=self:IsContactPartOfAnyClusters(contact)
      
      if cluster then
        self:AddContactToCluster(contact, cluster)
      else
      
        local newcluster=self:CreateCluster(contact.position)
        self:AddContactToCluster(contact, newcluster)
        self:NewCluster(contact, newcluster)
      end
      
    end
    
  end
  

  
  -- Update F10 marker text if cluster has changed.
  if self.clustermarkers then
    for _,_cluster in pairs(self.Clusters) do
      local cluster=_cluster --#INTEL.Cluster
    
        local coordinate=self:GetClusterCoordinate(cluster)
    
    
        -- Update F10 marker.
        self:UpdateClusterMarker(cluster)
    end
  end
end

--- Create a new cluster.
-- @param #INTEL self
-- @param Core.Point#COORDINATE coordinate The coordinate of the cluster.
-- @return #INTEL.Cluster cluster The cluster. 
function INTEL:CreateCluster(coordinate)

  -- Create new cluster
  local cluster={} --#INTEL.Cluster
  
  cluster.index=self.clustercounter
  cluster.coordinate=coordinate  
  cluster.threatlevelSum=0
  cluster.threatlevelMax=0
  cluster.size=0
  cluster.Contacts={}
    
  -- Add cluster.
  table.insert(self.Clusters, cluster)
      
  -- Increase counter.
  self.clustercounter=self.clustercounter+1  

  return cluster
end

--- Add a contact to the cluster.
-- @param #INTEL self
-- @param #INTEL.Contact contact The contact.
-- @param #INTEL.Cluster cluster The cluster. 
function INTEL:AddContactToCluster(contact, cluster)

  if contact and cluster then
    
    -- Add neighbour to cluster contacts.
    table.insert(cluster.Contacts, contact)
    
    cluster.threatlevelSum=cluster.threatlevelSum+contact.threatlevel
    
    cluster.size=cluster.size+1
  end

end

--- Remove a contact from a cluster.
-- @param #INTEL self
-- @param #INTEL.Contact contact The contact.
-- @param #INTEL.Cluster cluster The cluster. 
function INTEL:RemoveContactFromCluster(contact, cluster)

  if contact and cluster then
  
    for i,_contact in pairs(cluster.Contacts) do
      local Contact=_contact --#INTEL.Contact
      
      if Contact.groupname==contact.groupname then
      
        cluster.threatlevelSum=cluster.threatlevelSum-contact.threatlevel
        cluster.size=cluster.size-1
        
        table.remove(cluster.Contacts, i)
              
        return
      end
    
    end
    
  end

end

--- Calculate cluster threat level sum.
-- @param #INTEL self
-- @param #INTEL.Cluster cluster The cluster of contacts.
-- @return #number Sum of all threat levels of all groups in the cluster. 
function INTEL:CalcClusterThreatlevelSum(cluster)

  local threatlevel=0
  
  for _,_contact in pairs(cluster.Contacts) do
    local contact=_contact --#INTEL.Contact
    
    threatlevel=threatlevel+contact.threatlevel
    
  end
  cluster.threatlevelSum = threatlevel
  return threatlevel
end

--- Calculate cluster threat level average.
-- @param #INTEL self
-- @param #INTEL.Cluster cluster The cluster of contacts.
-- @return #number Average of all threat levels of all groups in the cluster. 
function INTEL:CalcClusterThreatlevelAverage(cluster)

  local threatlevel=self:CalcClusterThreatlevelSum(cluster)  
  threatlevel=threatlevel/cluster.size
  cluster.threatlevelAve = threatlevel
  return threatlevel
end

--- Calculate max cluster threat level.
-- @param #INTEL self
-- @param #INTEL.Cluster cluster The cluster of contacts.
-- @return #number Max threat levels of all groups in the cluster. 
function INTEL:CalcClusterThreatlevelMax(cluster)

  local threatlevel=0
  
  for _,_contact in pairs(cluster.Contacts) do
    local contact=_contact --#INTEL.Contact
    
    if contact.threatlevel>threatlevel then
      threatlevel=contact.threatlevel
    end
    
  end
  cluster.threatlevelMax = threatlevel
  return threatlevel
end


--- Check if contact is in any known cluster.
-- @param #INTEL self
-- @param #INTEL.Contact contact The contact.
-- @return #boolean If true, contact is in clusters 
function INTEL:CheckContactInClusters(contact)

  for _,_cluster in pairs(self.Clusters) do
    local cluster=_cluster --#INTEL.Cluster
    
    for _,_contact in pairs(cluster.Contacts) do
      local Contact=_contact --#INTEL.Contact
      
      if Contact.groupname==contact.groupname then
        return true
      end
    end
  end

  return false
end

--- Check if contact is close to any other contact this cluster.
-- @param #INTEL self
-- @param #INTEL.Contact contact The contact.
-- @param #INTEL.Cluster cluster The cluster the check.
-- @return #boolean If true, contact is connected to this cluster.
function INTEL:IsContactConnectedToCluster(contact, cluster)

  for _,_contact in pairs(cluster.Contacts) do
    local Contact=_contact --#INTEL.Contact
  
    if Contact.groupname~=contact.groupname then
      
      --local dist=Contact.position:Get2DDistance(contact.position)
      local dist=Contact.position:DistanceFromPointVec2(contact.position)
      
      local radius = self.clusterradius or 15
      if dist<radius*1000 then
        return true
      end
      
    end

  end
  
  return false
end

--- Check if contact is close to any contact of known clusters.
-- @param #INTEL self
-- @param #INTEL.Contact contact The contact.
-- @return #INTEL.Cluster The cluster this contact is part of or nil otherwise.
function INTEL:IsContactPartOfAnyClusters(contact)

  for _,_cluster in pairs(self.Clusters) do
    local cluster=_cluster --#INTEL.Cluster

    if self:IsContactConnectedToCluster(contact, cluster) then
      return cluster
    end    
  end

  return nil
end

--- Get the cluster this contact belongs to (if any).
-- @param #INTEL self
-- @param #INTEL.Contact contact The contact.
-- @return #INTEL.Cluster The cluster this contact belongs to or nil. 
function INTEL:GetClusterOfContact(contact)

  for _,_cluster in pairs(self.Clusters) do
    local cluster=_cluster --#INTEL.Cluster
    
    for _,_contact in pairs(cluster.Contacts) do
      local Contact=_contact --#INTEL.Contact
      
      if Contact.groupname==contact.groupname then
        return cluster
      end
    end
  end

  return nil
end

--- Get the coordinate of a cluster.
-- @param #INTEL self
-- @param #INTEL.Cluster cluster The cluster.
-- @return Core.Point#COORDINATE The coordinate of this cluster. 
function INTEL:GetClusterCoordinate(cluster)
  -- Init.  
  local x=0 ; local y=0 ; local z=0 ; local n=0
  
  for _,_contact in pairs(cluster.Contacts) do
    local contact=_contact --#INTEL.Contact
    
    x=x+contact.position.x
    y=y+contact.position.y
    z=z+contact.position.z
    n=n+1
    
  end
  
  -- Average.
  x=x/n ; y=y/n ; z=z/n
  
  -- Create coordinate.
  local coordinate=COORDINATE:New(x, y, z)

  return coordinate
end

--- Get the coordinate of a cluster.
-- @param #INTEL self
-- @param #INTEL.Cluster cluster The cluster.
-- @param Core.Point#COORDINATE coordinate (Optional) Coordinate of the new cluster. Default is to calculate the current coordinate.
-- @return #boolean 
function INTEL:CheckClusterCoordinateChanged(cluster, coordinate)

  coordinate=coordinate or self:GetClusterCoordinate(cluster)
  
  --local dist=cluster.coordinate:Get2DDistance(coordinate)
  local dist=cluster.coordinate:DistanceFromPointVec2(coordinate)
  
  if dist>1000 then
    return true
  else
    return false
  end

end

--- Update coordinates of the known clusters.
-- @param #INTEL self
function INTEL:_UpdateClusterPositions()
  for _,_cluster in pairs (self.Clusters) do
    local coord = self:GetClusterCoordinate(_cluster)
    _cluster.coordinate = coord
    self:T(self.lid..string.format("Cluster size: %s", _cluster.size))
  end
end

--- Count number of units in cluster
-- @param #INTEL self
-- @param #INTEL.Cluster Cluster The cluster
-- @return #number unitcount
function INTEL:ClusterCountUnits(Cluster)
  local unitcount = 0
  for _,_group in pairs (Cluster.Contacts) do -- get Wrapper.GROUP#GROUP _group
    unitcount = unitcount + _group.group:CountAliveUnits()
  end
  return unitcount
end

--- Update cluster F10 marker.
-- @param #INTEL self
-- @param #INTEL.Cluster cluster The cluster.
-- @return #INTEL self
function INTEL:UpdateClusterMarker(cluster)

  -- Create a marker.
  local unitcount = self:ClusterCountUnits(cluster)
  local text=string.format("Cluster #%d. Size %d, Units %d, TLsum=%d", cluster.index, cluster.size, unitcount, cluster.threatlevelSum)

  if not cluster.marker then
    if self.coalition == coalition.side.RED then
      cluster.marker=MARKER:New(cluster.coordinate, text):ToRed()
    elseif self.coalition == coalition.side.BLUE then
      cluster.marker=MARKER:New(cluster.coordinate, text):ToBlue()
    else
      cluster.marker=MARKER:New(cluster.coordinate, text):ToNeutral()
    end    
  else
  
    local refresh=false
  
    if cluster.marker.text~=text then
      cluster.marker.text=text
      refresh=true
    end
    
    if cluster.marker.coordinate~=cluster.coordinate then
      cluster.marker.coordinate=cluster.coordinate
      refresh=true
    end
    
    if refresh then
      cluster.marker:Refresh()
    end
  
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
