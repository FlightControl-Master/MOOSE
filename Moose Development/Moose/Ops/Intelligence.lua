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
-- @field Core.Set#SET_ZONE conflictzoneset Set of conflict zones. Contacts in these zones are considered, even if they are not in accept zones or if they are in reject zones.
-- @field Core.Set#SET_ZONE corridorzoneset Set of corridor zones. Contacts in these zones are never considered. Also see corridorfloorheight and corridorfloorceiling.
-- @field #number corridorfloor [Air] Contacts below this height (ASL!) are considered, even if they are in a corridor zone.
-- @field #number corridorceiling [Air] Contacts above this height (ASL!) are considered, even if they are in a corridor zone.
-- @field #table Contacts Table of detected items.
-- @field #table ContactsLost Table of lost detected items.
-- @field #table ContactsUnknown Table of new detected items.
-- @field #table Clusters Clusters of detected groups.
-- @field #boolean clusteranalysis If true, create clusters of detected targets.
-- @field #boolean clustermarkers If true, create cluster markers on F10 map.
-- @field #number clustercounter Running number of clusters.
-- @field #number dTforget Time interval in seconds before a known contact which is not detected any more is forgotten.
-- @field #number clusterradius Radius in meters in which groups/units are considered to belong to a cluster.
-- @field #number prediction Seconds default to be used with CalcClusterFuturePosition.
-- @field #boolean detectStatics If `true`, detect STATIC objects. Default `false`.
-- @field #number statusupdate Time interval in seconds after which the status is refreshed. Default 60 sec. Should be negative.
-- @field #boolean DetectAccoustic If true, also detect by sound (ie proximity).
-- @field #number DetectAccousticRadius Radius dfor accoustic detection, defaults to 2000 meters.
-- @field #table DetectAccousticUnitTypes Types of units we can detect accousticly. Defaults to {Unit.Category.HELICOPTER}
-- @extends Core.Fsm#FSM

--- Top Secret!
--
-- ===
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
-- ## Set up a detection SET_GROUP
--
--     Red_DetectionSetGroup = SET_GROUP:New()
--     Red_DetectionSetGroup:FilterPrefixes( { "Red EWR" } )
--     Red_DetectionSetGroup:FilterOnce()
--
-- ## New Intel type detection for the red side, logname "KGB"
--
--     RedIntel = INTEL:New(Red_DetectionSetGroup, "red", "KGB")
--     RedIntel:SetClusterAnalysis(true, true)
--     RedIntel:SetVerbosity(2)
--     RedIntel:__Start(2)
--
-- ## Hook into new contacts found
--
--     function RedIntel:OnAfterNewContact(From, Event, To, Contact)
--       local text = string.format("NEW contact %s detected by %s", Contact.groupname, Contact.recce or "unknown")
--       MESSAGE:New(text, 15, "KGB"):ToAll()
--     end
--
--  ## And/or new clusters found
--
--     function RedIntel:OnAfterNewCluster(From, Event, To, Cluster)
--       local text = string.format("NEW cluster #%d of size %d", Cluster.index, Cluster.size)
--       MESSAGE:New(text,15,"KGB"):ToAll()
--     end
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
  clusterradius   = 15000,
  clusteranalysis =  true,
  clustermarkers  = false,
  clusterarrows   = false,
  prediction      =   300,
  detectStatics   = false,
  DetectAccoustic = false,
  DetectAccousticRadius = 1000,
  DetectAccousticUnitTypes =  {Unit.Category.HELICOPTER},
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
-- @field #boolean isship If `true`, contact is a naval group.
-- @field #boolean ishelo If `true`, contact is a helo group.
-- @field #boolean isground If `true`, contact is a ground group.
-- @field #boolean isStatic If `true`, contact is a STATIC object.
-- @field Ops.Auftrag#AUFTRAG mission The current Auftrag attached to this contact.
-- @field Ops.Target#TARGET target The Target attached to this contact.
-- @field #string recce The name of the recce unit that detected this contact.
-- @field #string ctype Contact type of #INTEL.Ctype.
-- @field #string platform [AIR] Contact platform name, e.g. Foxbat, Flanker_E, defaults to Bogey if unknown
-- @field #number heading [AIR] Heading of the contact, if available.
-- @field #boolean maneuvering [AIR] Contact has changed direction by >10 deg.
-- @field #number altitude [AIR] Flight altitude of the contact in meters.

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
-- @field #number markerID Marker ID.
-- @field Ops.Auftrag#AUFTRAG mission The current Auftrag attached to this cluster.
-- @field #string ctype Cluster type of #INTEL.Ctype.
-- @field #number altitude [AIR] Average flight altitude of the cluster in meters.

--- Contact or cluster type.
-- @type INTEL.Ctype
-- @field #string GROUND Ground.
-- @field #string NAVAL Ship.
-- @field #string AIRCRAFT Airpane or helicopter.
-- @field #string STRUCTURE Static structure.
INTEL.Ctype={
  GROUND="Ground",
  NAVAL="Naval",
  AIRCRAFT="Aircraft",
  STRUCTURE="Structure"
}

--- INTEL class version.
-- @field #string version
INTEL.version="0.3.10"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add min cluster size. Only create new clusters if they have a certain group size.
-- NODO: process detected set asynchroniously for better performance.
-- DONE: Add statics.
-- DONE: Filter detection methods.
-- DONE: Accept zones.
-- DONE: Reject zones.
-- NOGO: SetAttributeZone --> return groups of generalized attributes in a zone.
-- DONE: Loose units only if they remain undetected for a given time interval. We want to avoid fast oscillation between detected/lost states. Maybe 1-5 min would be a good time interval?!
-- DONE: Combine units to groups for all, new and lost.
-- DONE: Add corridor zones.

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
    self.alias="INTEL SPECTRE"
    if self.coalition then
      if self.coalition==coalition.side.RED then
        self.alias="INTEL KGB"
      elseif self.coalition==coalition.side.BLUE then
        self.alias="INTEL CIA"
      end
    end
  end

  self.DetectVisual = true
  self.DetectOptical = true
  self.DetectRadar = true
  self.DetectIRST = true
  self.DetectRWR = true
  self.DetectDLINK = true

  self.statusupdate = -60

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", self.alias, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")

  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- INTEL status update.
  self:AddTransition("*",             "Stop",               "Stopped")     -- Stop FSM.

  self:AddTransition("*",             "Detect",             "*")           -- Start detection run. Not implemented yet!

  self:AddTransition("*",             "NewContact",         "*")           -- New contact has been detected.
  self:AddTransition("*",             "LostContact",        "*")           -- Contact could not be detected any more.

  self:AddTransition("*",             "NewCluster",         "*")           -- New cluster has been detected.
  self:AddTransition("*",             "LostCluster",        "*")           -- Cluster could not be detected any more.


  -- Defaults
  self:SetForgetTime()
  self:SetAcceptZones()
  self:SetRejectZones()
  self:SetCorridorZones()
  self:SetConflictZones()

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


  --- Triggers the FSM event "NewContact".
  -- @function [parent=#INTEL] NewContact
  -- @param #INTEL self
  -- @param #INTEL.Contact Contact Detected contact.

  --- Triggers the FSM event "NewContact" after a delay.
  -- @function [parent=#INTEL] NewContact
  -- @param #INTEL self
  -- @param #number delay Delay in seconds.
  -- @param #INTEL.Contact Contact Detected contact.

  --- On After "NewContact" event.
  -- @function [parent=#INTEL] OnAfterNewContact
  -- @param #INTEL self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #INTEL.Contact Contact Detected contact.


  --- Triggers the FSM event "LostContact".
  -- @function [parent=#INTEL] LostContact
  -- @param #INTEL self
  -- @param #INTEL.Contact Contact Lost contact.

  --- Triggers the FSM event "LostContact" after a delay.
  -- @function [parent=#INTEL] LostContact
  -- @param #INTEL self
  -- @param #number delay Delay in seconds.
  -- @param #INTEL.Contact Contact Lost contact.

  --- On After "LostContact" event.
  -- @function [parent=#INTEL] OnAfterLostContact
  -- @param #INTEL self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #INTEL.Contact Contact Lost contact.


  --- Triggers the FSM event "NewCluster".
  -- @function [parent=#INTEL] NewCluster
  -- @param #INTEL self
  -- @param #INTEL.Cluster Cluster Detected cluster.

  --- Triggers the FSM event "NewCluster" after a delay.
  -- @function [parent=#INTEL] NewCluster
  -- @param #INTEL self
  -- @param #number delay Delay in seconds.
  -- @param #INTEL.Cluster Cluster Detected cluster.

  --- On After "NewCluster" event.
  -- @function [parent=#INTEL] OnAfterNewCluster
  -- @param #INTEL self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #INTEL.Cluster Cluster Detected cluster.


  --- Triggers the FSM event "LostCluster".
  -- @function [parent=#INTEL] LostCluster
  -- @param #INTEL self
  -- @param #INTEL.Cluster Cluster Lost cluster.
  -- @param Ops.Auftrag#AUFTRAG Mission The Auftrag connected with this cluster or `nil`.

  --- Triggers the FSM event "LostCluster" after a delay.
  -- @function [parent=#INTEL] LostCluster
  -- @param #INTEL self
  -- @param #number delay Delay in seconds.
  -- @param #INTEL.Cluster Cluster Lost cluster.
  -- @param Ops.Auftrag#AUFTRAG Mission The Auftrag connected with this cluster or `nil`.

  --- On After "LostCluster" event.
  -- @function [parent=#INTEL] OnAfterLostCluster
  -- @param #INTEL self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #INTEL.Cluster Cluster Lost cluster.
  -- @param Ops.Auftrag#AUFTRAG Mission The Auftrag connected with this cluster or `nil`.

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

--- Set to accept accoustic detection.
-- @param #INTEL self
-- @param #number Radius Radius in which we can "hear" units. Defaults to 1000 meters.
-- @param #table UnitCategories Set what Unit Categories we can "hear". Defaults to `{Unit.Category.GROUND_UNIT,Unit.Category.HELICOPTER}`
-- @return #INTEL self
function INTEL:SetAccousticDetectionOn(Radius,UnitCategories)
  self.DetectAccoustic = true
  self.DetectAccousticRadius = Radius or 1000
  self.DetectAccousticUnitTypes =  UnitCategories or {Unit.Category.HELICOPTER}
  return self
end

--- Switch off accoustic detection.
-- @param #INTEL self
-- @return #INTEL self
function INTEL:SetAccousticDetectionOff()
  self.DetectAccoustic = false
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
-- Note that reject zones overrule accept zones, i.e. if a unit is inside an accept zone and inside a reject zone, it is rejected.
-- @param #INTEL self
-- @param Core.Set#SET_ZONE RejectZoneSet Set of reject zone(s).
-- @return #INTEL self
function INTEL:SetRejectZones(RejectZoneSet)
  self.rejectzoneset=RejectZoneSet or SET_ZONE:New()
  return self
end

--- Add a reject zone. Contacts detected in this zone are rejected and not reported by the detection.
-- Note that reject zones overrule accept zones, i.e. if a unit is inside an accept zone and inside a reject zone, it is rejected.
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

--- Set conflict zones. Contacts detected in this/these zone(s) are reported by the detection.
-- Note that conflict zones overrule all other zones, i.e. if a unit is outside of an accept zone and inside a reject zone, it is still reported if inside a conflict zone.
-- @param #INTEL self
-- @param Core.Set#SET_ZONE ConflictZoneSet Set of conflict zone(s).
-- @return #INTEL self
function INTEL:SetConflictZones(ConflictZoneSet)
  self.conflictzoneset=ConflictZoneSet or SET_ZONE:New()
  return self
end

--- Add a conflict zone. Contacts detected in this zone are conflicted and not reported by the detection.
-- Note that conflict zones overrule all other zones, i.e. if a unit is outside of an accept zone and inside a reject zone, it is still reported if inside a conflict zone.
-- @param #INTEL self
-- @param Core.Zone#ZONE ConflictZone Add a zone to the conflict zone set.
-- @return #INTEL self
function INTEL:AddConflictZone(ConflictZone)
  self.conflictzoneset:AddZone(ConflictZone)
  return self
end

--- Remove a conflict zone from the conflict zone set.
-- Note that conflict zones overrule all other zones, i.e. if a unit is outside of an accept zone and inside a reject zone, it is still reported if inside a conflict zone.
-- @param #INTEL self
-- @param Core.Zone#ZONE ConflictZone Remove a zone from the conflict zone set.
-- @return #INTEL self
function INTEL:RemoveConflictZone(ConflictZone)
  self.conflictzoneset:Remove(ConflictZone:GetName(), true)
  return self
end

--- Set corrdidor zones. Contacts detected in this/these zone(s) are never reported by the detection.
-- Note that corrdidor zones overrule all other zones, for exceptions see corridor floor and corridor ceiling heights.
-- @param #INTEL self
-- @param Core.Set#SET_ZONE CorridorZoneSet Set of corrdidor zone(s).
-- @return #INTEL self
function INTEL:SetCorridorZones(CorridorZoneSet)
  self.corridorzoneset=CorridorZoneSet or SET_ZONE:New()
  return self
end

--- Add a corrdidor zone. Contacts detected in this zone are corrdidored and not reported by the detection.
-- Note that corrdidor zones overrule all other zones, for exceptions see corridor floor and corridor ceiling heights.
-- @param #INTEL self
-- @param Core.Zone#ZONE CorridorZone Add a zone to the corrdidor zone set.
-- @return #INTEL self
function INTEL:AddCorridorZone(CorridorZone)
  self.corridorzoneset:AddZone(CorridorZone)
  return self
end

--- Remove a corrdidor zone from the corrdidor zone set.
-- Note that corrdidor zones overrule all other zones, for exceptions see corridor floor and corridor ceiling heights.
-- @param #INTEL self
-- @param Core.Zone#ZONE CorridorZone Remove a zone from the corrdidor zone set.
-- @return #INTEL self
function INTEL:RemoveCorridorZone(CorridorZone)
  self.corridorzoneset:Remove(CorridorZone:GetName(), true)
  return self
end

--- [Air] Add corrdidor zone floor and height. This is generally applicable to all(!) corridor zones. Considered as ASL (above sea level or barometric) values.
-- Overrides corridor exception for objects flying outside this limitations.
-- To set an individual ceiling/floor on any Core.Zone#ZONE you wish to use, set these properties on the Core.Zone#ZONE object:
-- `mycorridorzone:SetProperty("CorridorFloor",500)` -- meters, case sensitivity matters!
-- `mycorridorzone:SetProperty("CorridorCeiling",10000)` -- meters, case sensitivity matters!
-- @param #INTEL self
-- @param #number Floor Floor altitude in meters.
-- @param #number Ceiling Ceiling altitude in meters.
-- @return #INTEL self
function INTEL:SetCorridorLimits(Floor,Ceiling)
  self.corridorceiling = Ceiling or 10000
  self.corridorfloor = Floor or 1
  return self
end

--- [Air] Add corrdidor zone floor and height. This is generally applicable to all(!) corridor zones. Considered as ASL (above sea level or barometric) values.
-- Overrides corridor exception for objects flying outside this limitations.
-- To set an individual ceiling/floor on any Core.Zone#ZONE you wish to use, set these properties on the Core.Zone#ZONE object:
-- `mycorridorzone:SetProperty("CorridorFloor",UTILS.FeetToMeters(5000))` -- feet, case sensitivity matters!
-- `mycorridorzone:SetProperty("CorridorCeiling",UTILS.FeetToMeters(20000))` -- feet, case sensitivity matters!
-- @param #INTEL self
-- @param #number Floor Floor altitude in feet.
-- @param #number Ceiling Ceiling altitude in feet.
-- @return #INTEL self
function INTEL:SetCorridorLimitsFeet(Floor,Ceiling)
  local Ceiling = Ceiling or 25000
  local Floor = Floor or 15000
  self.corridorceiling = UTILS.FeetToMeters(Ceiling)
  self.corridorfloor = UTILS.FeetToMeters(Floor)
  return self
end

--- **OBSOLETE, not functional!**  Set forget contacts time interval.
-- Previously known contacts that are not detected any more, are "lost" after this time.
-- This avoids fast oscillations between a contact being detected and undetected.
-- @param #INTEL self
-- @param #number TimeInterval Time interval in seconds. Default is 120 sec.
-- @return #INTEL self
function INTEL:SetForgetTime(TimeInterval)
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

--- Method to make the radar detection less accurate, e.g. for WWII scenarios.
-- @param #INTEL self
-- @param #number minheight Minimum flight height to be detected, in meters AGL (above ground)
-- @param #number thresheight Threshold to escape the radar if flying below minheight, defaults to 90 (90% escape chance)
-- @param #number thresblur Threshold to be detected by the radar overall, defaults to 85 (85% chance to be found)
-- @param #number closing Closing-in in km - the limit of km from which on it becomes increasingly difficult to escape radar detection if flying towards the radar position. Should be about 1/3 of the radar detection radius in kilometers, defaults to 20.
-- @return #INTEL self
function INTEL:SetRadarBlur(minheight,thresheight,thresblur,closing)
  self.RadarBlur = true
  self.RadarBlurMinHeight = minheight or 250 -- meters
  self.RadarBlurThresHeight = thresheight or 90 -- 10% chance to find a low flying group
  self.RadarBlurThresBlur = thresblur or 85 -- 25% chance to escape the radar overall
  self.RadarBlurClosing = closing or 20 -- 20km
  self.RadarBlurClosingSquare = self.RadarBlurClosing * self.RadarBlurClosing 
  return self
end

--- Set the accept range in kilometers from each of the recce. Only object closer than this range will be detected.
-- @param #INTEL self
-- @param #number Range Range in kilometers
-- @return #INTEL self
function INTEL:SetAcceptRange(Range)
  self.RadarAcceptRange = true
  self.RadarAcceptRangeKilometers = Range or 75
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

--- Add a group to the detection set.
-- @param #INTEL self
-- @param Wrapper.Group#GROUP AgentGroup Group of agents. Can also be an @{Ops.OpsGroup#OPSGROUP} object.
-- @return #INTEL self
function INTEL:AddAgent(AgentGroup)

  -- Check if this was an OPS group.
  if AgentGroup:IsInstanceOf("OPSGROUP") then
    AgentGroup=AgentGroup:GetGroup()
  end

  -- Add to detection set.
  self.detectionset:AddGroup(AgentGroup,true)
  return self
end

--- Enable or disable cluster analysis of detected targets.
-- Targets will be grouped in coupled clusters.
-- @param #INTEL self
-- @param #boolean Switch If true, enable cluster analysis.
-- @param #boolean Markers If true, place markers on F10 map.
-- @param #boolean Arrows If true, draws arrows on F10 map.
-- @return #INTEL self
function INTEL:SetClusterAnalysis(Switch, Markers, Arrows)
  self.clusteranalysis=Switch
  self.clustermarkers=Markers
  self.clusterarrows=Arrows
  return self
end

--- Set whether STATIC objects are detected.
-- @param #INTEL self
-- @param #boolean Switch If `true`, statics are detected.
-- @return #INTEL self
function INTEL:SetDetectStatics(Switch)
  if Switch and Switch==true then
    self.detectStatics=true
  else
    self.detectStatics=false
  end
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

--- Change radius of the Clusters.
-- @param #INTEL self
-- @param #number radius The radius of the clusters in kilometers. Default 15 km.
-- @return #INTEL self
function INTEL:SetClusterRadius(radius)
  self.clusterradius = (radius or 15)*1000
  return self
end

--- Set detection types for this #INTEL - all default to true.
-- @param #INTEL self
-- @param #boolean DetectVisual Visual detection
-- @param #boolean DetectOptical Optical detection
-- @param #boolean DetectRadar Radar detection
-- @param #boolean DetectIRST IRST detection
-- @param #boolean DetectRWR RWR detection
-- @param #boolean DetectDLINK Data link detection
-- @return self
function INTEL:SetDetectionTypes(DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK)
  self.DetectVisual = DetectVisual and true
  self.DetectOptical = DetectOptical and true
  self.DetectRadar = DetectRadar and true
  self.DetectIRST = DetectIRST and true
  self.DetectRWR = DetectRWR and true
  self.DetectDLINK = DetectDLINK and true
  return self
end

--- Get table of #INTEL.Contact objects
-- @param #INTEL self
-- @return #table Contacts or nil if not running
function INTEL:GetContactTable()
  if self:Is("Running") then
    return self.Contacts
  else
    return nil
  end
end

--- Get table of #INTEL.Cluster objects
-- @param #INTEL self
-- @return #table Clusters or nil if not running
function INTEL:GetClusterTable()
  if self:Is("Running") and self.clusteranalysis then
    return self.Clusters
  else
    return nil
  end
end

--- Get name of a contact.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact.
-- @return #string Name of the contact.
function INTEL:GetContactName(Contact)
  return Contact.groupname
end

--- Get group of a contact.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact.
-- @return Wrapper.Group#GROUP Group object.
function INTEL:GetContactGroup(Contact)
  return Contact.group
end

--- Get threatlevel of a contact.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact.
-- @return #number Threat level.
function INTEL:GetContactThreatlevel(Contact)
  return Contact.threatlevel
end


--- Get type name of a contact.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact.
-- @return #string Type name.
function INTEL:GetContactTypeName(Contact)
  return Contact.typename
end

--- Get category name of a contact.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact.
-- @return #string Category name.
function INTEL:GetContactCategoryName(Contact)
  return Contact.categoryname
end

--- Get coordinate of a contact.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact.
-- @return Core.Point#COORDINATE Coordinates.
function INTEL:GetContactCoordinate(Contact)
  return Contact.position
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
  return self
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
      text=text..string.format("\n- %s (%s): %s, units=%d, T=%d sec", contact.categoryname, contact.attribute, contact.groupname, contact.isStatic and 1 or contact.group:CountAliveUnits(), dT)
      if contact.mission then
        local mission=contact.mission --Ops.Auftrag#AUFTRAG
        text=text..string.format(" mission name=%s type=%s target=%s", mission.name, mission.type, mission:GetTargetName() or "unknown")
      end
    end
    self:I(self.lid..text)
  end

  self:__Status(self.statusupdate)
  return self
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
        self:GetDetectedUnits(recce, DetectedUnits, RecceDetecting, self.DetectVisual, self.DetectOptical, self.DetectRadar, self.DetectIRST, self.DetectRWR, self.DetectDLINK)

      end
      
      if self.DetectAccoustic then
        local recce = group:GetFirstUnitAlive()
        local detectionzone = group:GetProperty("INTEL_DETECT_ACCZONE")
        if not detectionzone then
          detectionzone = ZONE_GROUP:New(group.IdentifiableName.."INTEL_DETECT_ACCZONE",group,self.DetectAccousticRadius or 2000)
          group:SetProperty("INTEL_DETECT_ACCZONE",detectionzone)
        end
        if recce and recce:IsGround() then
          self:GetDetectedUnitsAccoustic(recce,DetectedUnits,RecceDetecting,detectionzone)
        end
      end

    end
  end

  local remove={}
  for unitname,_unit in pairs(DetectedUnits) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    local inconflictzone=false
    -- Check if unit is in any of the conflict zones.
    if self.conflictzoneset:Count()>0 then
      for _,_zone in pairs(self.conflictzoneset.Set) do
        local zone=_zone --Core.Zone#ZONE
        if unit:IsInZone(zone) then
          inconflictzone=true
          break
        end
      end
    end
    
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
      if (not inzone) and (not inconflictzone) then
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
      if inzone and (not inconflictzone) then
        table.insert(remove, unitname)
      end
    end
    
    -- Check if unit is in any of the corridor zones.
    if self.corridorzoneset:Count()>0 then
      self:T("Corridorzone Check for unit "..unit:GetName())
      local inzone = false
      for _,_zone in pairs(self.corridorzoneset.Set) do
        local zone=_zone --Core.Zone#ZONE
        if unit:IsInZone(zone) then
          local corridorfloor = zone:GetProperty("CorridorFloor") or self.corridorfloor
          local corridorceiling = zone:GetProperty("CorridorCeiling") or self.corridorceiling
          local debugtext = "Corridorzone Check for unit "..unit:GetName().."\n"
          debugtext = debugtext .. string.format("IsAir %s | Alt %dft | Floor %dft | Ceil %dft",tostring(unit:IsAir()),tonumber(UTILS.MetersToFeet(unit:GetAltitude())),
          tonumber(UTILS.MetersToFeet(corridorfloor)),tonumber(UTILS.MetersToFeet(corridorceiling)))
          MESSAGE:New(debugtext,15,"INTEL"):ToAllIf(self.verbose>1):ToLogIf(self.verbose>1)
          if unit:IsAir() and (corridorfloor ~= nil or corridorceiling ~= nil) then
            local alt = unit:GetAltitude()
            if corridorfloor and alt > corridorfloor then inzone = true end
            if corridorceiling and (inzone == true or corridorfloor == nil) and alt < corridorceiling then inzone = true else inzone = false end
            if inzone == true then break end
          else  
            inzone=true
            break
          end
        end
      end
      -- Unit is inside a corridor zone ==> remove!
      if inzone then
        table.insert(remove, unitname)
      end
    end

    -- Filter unit categories. Added check that we have a UNIT and not a STATIC object because :GetUnitCategory() is only available for units.
    if #self.filterCategory>0 and unit:IsInstanceOf("UNIT") then
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
  local DetectedStatics={}
  local RecceGroups={}
  for unitname,_unit in pairs(DetectedUnits) do
    local unit=_unit --Wrapper.Unit#UNIT
    if unit:IsInstanceOf("UNIT") then
      local group=unit:GetGroup()
      if group then
        local groupname = group:GetName()
        DetectedGroups[groupname]=group
        RecceGroups[groupname]=RecceDetecting[unitname]
      end
    else
      if self.detectStatics then
        DetectedStatics[unitname]=unit
        RecceGroups[unitname]=RecceDetecting[unitname]
      end
    end
  end

  -- Create detected contacts.
  self:CreateDetectedItems(DetectedGroups, DetectedStatics, RecceGroups)

  -- Paint a picture of the battlefield.
  if self.clusteranalysis then
    self:PaintPicture()
  end

  return self
end

--- Update an #INTEL.Contact item.
-- @param #INTEL self
-- @param #INTEL.Contact Contact Contact.
-- @return #INTEL.Contact The contact.
function INTEL:_UpdateContact(Contact)

  if Contact.isStatic then

    -- Statics don't need to be updated.

  else

    if Contact.group and Contact.group:IsAlive() then

      Contact.Tdetected=timer.getAbsTime()
      Contact.position=Contact.group:GetCoordinate()
      Contact.velocity=Contact.group:GetVelocityVec3()
      Contact.speed=Contact.group:GetVelocityMPS()
      if Contact.group:IsAir() then
        Contact.altitude=Contact.group:GetAltitude()
        local oldheading = Contact.heading or 1
        local newheading = Contact.group:GetHeading()
        if newheading == 0 then newheading = 1 end
        local changeh = math.abs(((oldheading - newheading) + 360) % 360)
        Contact.heading = newheading
        if changeh > 10 then
          Contact.maneuvering = true
        else
          Contact.maneuvering = false
        end
      end
    end

  end
  return self
end

--- Create an #INTEL.Contact item from a given GROUP or STATIC object.
-- @param #INTEL self
-- @param Wrapper.Positionable#POSITIONABLE Positionable The GROUP or STATIC object.
-- @param #string RecceName The name of the recce group that has detected this contact.
-- @return #INTEL.Contact The contact.
function INTEL:_CreateContact(Positionable, RecceName)

  if Positionable and Positionable:IsAlive() then

    -- Create new contact.
    local item={} --#INTEL.Contact

    if Positionable:IsInstanceOf("GROUP") then

      local group=Positionable --Wrapper.Group#GROUP

      item.groupname=group:GetName()
      item.group=group
      item.Tdetected=timer.getAbsTime()
      item.typename=group:GetTypeName()
      item.attribute=group:GetAttribute()
      item.category=group:GetCategory()
      item.categoryname=group:GetCategoryName()
      item.threatlevel=group:GetThreatLevel()
      item.position=group:GetCoordinate()
      item.velocity=group:GetVelocityVec3()
      item.speed=group:GetVelocityMPS()
      item.recce=RecceName
      item.isground = group:IsGround() or false
      item.isship = group:IsShip() or false
      item.isStatic=false
      if group:IsAir() then
        item.platform=group:GetNatoReportingName()
        item.heading = group:GetHeading()
        item.maneuvering = false
        item.altitude = group:GetAltitude()
      else
        -- TODO optionally add ground types?
        item.platform="Unknown"
        item.altitude = group:GetAltitude(true)
      end
      if item.category==Group.Category.AIRPLANE or item.category==Group.Category.HELICOPTER then
        item.ctype=INTEL.Ctype.AIRCRAFT
      elseif item.category==Group.Category.GROUND or item.category==Group.Category.TRAIN then
        item.ctype=INTEL.Ctype.GROUND
      elseif item.category==Group.Category.SHIP then
        item.ctype=INTEL.Ctype.NAVAL
      end

      return item

    elseif Positionable:IsInstanceOf("STATIC") then

      local static=Positionable --Wrapper.Static#STATIC

      item.groupname=static:GetName()
      item.group=static
      item.Tdetected=timer.getAbsTime()
      item.typename=static:GetTypeName() or "Unknown"
      item.attribute="Static"
      item.category=3 --static:GetCategory()
      item.categoryname=static:GetCategoryName() or "Unknown"
      item.threatlevel=static:GetThreatLevel() or 0
      item.position=static:GetCoord()
      item.velocity=static:GetVelocityVec3()
      item.speed=0
      item.recce=RecceName
      item.isground = true
      item.isship = false
      item.isStatic=true
      item.ctype=INTEL.Ctype.STRUCTURE

      return item
    else
      self:E(self.lid..string.format("ERROR: object needs to be a GROUP or STATIC!"))
    end

  end

  return nil
end

--- Create detected items.
-- @param #INTEL self
-- @param #table DetectedGroups Table of detected Groups.
-- @param #table DetectedStatics Table of detected Statics.
-- @param #table RecceDetecting Table of detecting recce names.
function INTEL:CreateDetectedItems(DetectedGroups, DetectedStatics, RecceDetecting)
  self:F({RecceDetecting=RecceDetecting})

  -- Current time.
  local Tnow=timer.getAbsTime()

  -- Loop over groups.
  for groupname,_group in pairs(DetectedGroups) do
    local group=_group --Wrapper.Group#GROUP

      -- Create or update contact for this group.
      self:KnowObject(group, RecceDetecting[groupname])

  end

  -- Loop over statics.
  for staticname,_static in pairs(DetectedStatics) do
    local static=_static --Wrapper.Static#STATIC

    -- Create or update contact for this group.
    self:KnowObject(static, RecceDetecting[staticname])

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
  return self
end

--- (Internal) Return the detected target groups of the controllable as a table.
-- The optional parameters specify the detection methods that can be applied.
-- If no detection method is given, the detection will use all the available methods by default.
-- @param #INTEL self
-- @param Wrapper.Unit#UNIT Unit The unit detecting.
-- @param #table DetectedUnits Table of detected units to be filled.
-- @param #table RecceDetecting Table of recce per unit to be filled.
-- @param #boolean DetectVisual (Optional) If *false*, do not include visually detected targets.
-- @param #boolean DetectOptical (Optional) If *false*, do not include optically detected targets.
-- @param #boolean DetectRadar (Optional) If *false*, do not include targets detected by radar.
-- @param #boolean DetectIRST (Optional) If *false*, do not include targets detected by IRST.
-- @param #boolean DetectRWR (Optional) If *false*, do not include targets detected by RWR.
-- @param #boolean DetectDLINK (Optional) If *false*, do not include targets detected by data link.
function INTEL:GetDetectedUnits(Unit, DetectedUnits, RecceDetecting, DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK)

  -- Get detected DCS units.
  local reccename = Unit:GetName()

  local detectedtargets=Unit:GetDetectedTargets(DetectVisual, DetectOptical, DetectRadar, DetectIRST, DetectRWR, DetectDLINK)

  for DetectionObjectID, Detection in pairs(detectedtargets or {}) do
    local DetectedObject=Detection.object -- DCS#Object

    -- NOTE: Got an object that exists but when trying UNIT:Find() the DCS getName() function failed. ID of the object was 5,000,031
    if DetectedObject and DetectedObject:isExist() and DetectedObject.id_<50000000 then

      -- Protected call to get the name of the object.
      local status,name =  pcall(
      function()
        local name=DetectedObject:getName()
        return name
      end)

      if status then

        local unit=UNIT:FindByName(name)
 
        if unit and unit:IsAlive() then
          local DetectionAccepted = true
          
          if self.RadarAcceptRange then
            local reccecoord = Unit:GetCoord()
            local coord = unit:GetCoord()
            local dist = math.floor(coord:Get2DDistance(reccecoord)/1000) -- km
            if dist > self.RadarAcceptRangeKilometers then DetectionAccepted = false end
          end
          
          if self.RadarBlur then
            local reccecoord = Unit:GetCoord()
            local coord = unit:GetCoord()
            local dist = math.floor(coord:Get2DDistance(reccecoord)/1000) -- km
            local AGL = unit:GetAltitude(true)
            local minheight = self.RadarBlurMinHeight or 250 -- meters
            local thresheight = self.RadarBlurThresHeight or 90 -- 10% chance to find a low flying group
            local thresblur = self.RadarBlurThresBlur or 85 -- 25% chance to escape the radar overall
            --local dist = math.floor(Distance)
            if dist <= self.RadarBlurClosing  then
              thresheight = (((dist*dist)/self.RadarBlurClosingSquare)*thresheight)
              thresblur = (((dist*dist)/self.RadarBlurClosingSquare)*thresblur)
            end
            local fheight = math.floor(math.random(1,10000)/100)
            local fblur = math.floor(math.random(1,10000)/100)
            if fblur > thresblur then DetectionAccepted = false end
            if AGL <= minheight and fheight < thresheight then DetectionAccepted = false end
            if self.debug or self.verbose > 1 then
              MESSAGE:New("Radar Blur",10):ToLogIf(self.debug):ToAllIf(self.verbose>1)      
              MESSAGE:New("Unit "..name.." is at "..math.floor(AGL).."m. Distance "..math.floor(dist).."km.",10):ToLogIf(self.debug):ToAllIf(self.verbose>1)
              MESSAGE:New(string.format("fheight = %d/%d | fblur = %d/%d",fheight,thresheight,fblur,thresblur),10):ToLogIf(self.debug):ToAllIf(self.verbose>1)
              MESSAGE:New("Detection Accepted = "..tostring(DetectionAccepted),10):ToLogIf(self.debug):ToAllIf(self.verbose>1)
            end
          end
           
          if DetectionAccepted then
            DetectedUnits[name]=unit
            RecceDetecting[name]=reccename
            self:T(string.format("Unit %s detect by %s", name, reccename))
          end
        else
          if self.detectStatics then
            local static=STATIC:FindByName(name, false)
            if static then
              --env.info("FF found static "..name)
              DetectedUnits[name]=static
              RecceDetecting[name]=reccename
            end
          end
        end

      else
        -- Warning!
        self:T(self.lid..string.format("WARNING: Could not get name of detected object ID=%s! Detected by %s", DetectedObject.id_, reccename))
      end
    end
  end
end

--- (Internal) Return the detected target groups of the controllable as a @{Core.Set#SET_GROUP}.
-- @param #INTEL self
-- @param Wrapper.Unit#UNIT Recce The unit detecting.
-- @param #table DetectedUnits Table of detected units to be filled.
-- @param #table RecceDetecting Table of recce per unit to be filled.
-- @param Core.Zone#ZONE_GROUP detectionzone The zone where to look.
function INTEL:GetDetectedUnitsAccoustic(Recce,DetectedUnits,RecceDetecting,detectionzone)
  local othercoalition = self.coalition == coalition.side.BLUE and coalition.side.RED or coalition.side.BLUE
  self:T("Other coalition = "..othercoalition)
  if detectionzone then
    -- Get detected units
    local reccename = Recce:GetName()
    local DetectAccousticUnitTypes = self.DetectAccousticUnitTypes or {Unit.Category.HELICOPTER}
    detectionzone:Scan({Object.Category.UNIT},DetectAccousticUnitTypes)
    local unitset = detectionzone:GetScannedSetUnit(othercoalition) -- Core.Set#SET_UNIT
    self:T("Accoustic detection found #Units "..unitset:CountAlive())
    for _,_unit in pairs(unitset.Set or {}) do
      if _unit and _unit:IsAlive() and _unit:GetCoalition() ~= self.coalition then
        local name = _unit:GetName() or "none"
        DetectedUnits[name]=_unit
        RecceDetecting[name]=reccename
        self:T("Unit name = "..name)
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

  -- Debug text.
  self:F(self.lid..string.format("NEW contact %s", Contact.groupname))

  -- Add to table of unknown contacts.
  table.insert(self.ContactsUnknown, Contact)
  return self
end

--- On after "LostContact" event.
-- @param #INTEL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #INTEL.Contact Contact Lost contact.
function INTEL:onafterLostContact(From, Event, To, Contact)

  -- Debug text.
  self:F(self.lid..string.format("LOST contact %s", Contact.groupname))

  -- Add to table of lost contacts.
  table.insert(self.ContactsLost, Contact)
  return self
end

--- On after "NewCluster" event.
-- @param #INTEL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #INTEL.Cluster Cluster Detected cluster.
function INTEL:onafterNewCluster(From, Event, To, Cluster)

  -- Debug text.
  self:F(self.lid..string.format("NEW cluster #%d [%s] of size %d", Cluster.index, Cluster.ctype, Cluster.size))

  -- Add cluster to table.
  self:_AddCluster(Cluster)
  return self
end

--- On after "LostCluster" event.
-- @param #INTEL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #INTEL.Cluster Cluster Lost cluster.
-- @param Ops.Auftrag#AUFTRAG Mission The Auftrag connected with this cluster or `nil`.
function INTEL:onafterLostCluster(From, Event, To, Cluster, Mission)

  -- Debug text.
  local text = self.lid..string.format("LOST cluster #%d [%s]", Cluster.index, Cluster.ctype)

  if Mission then
    local mission=Mission --Ops.Auftrag#AUFTRAG
    text=text..string.format(" mission name=%s type=%s target=%s", mission.name, mission.type, mission:GetTargetName() or "unknown")
  end

  self:T(text)
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Make the INTEL aware of a object that was not detected (yet). This will add the object to the contacts table and trigger a `NewContact` event.
-- @param #INTEL self
-- @param Wrapper.Positionable#POSITIONABLE Positionable Group or static object.
-- @param #string RecceName Name of the recce group that detected this object.
-- @param #number Tdetected Abs. mission time in seconds, when the object is detected. Default now.
-- @return #INTEL self
function INTEL:KnowObject(Positionable, RecceName, Tdetected)

  local Tnow=timer.getAbsTime()
  Tdetected=Tdetected or Tnow

  if Positionable and Positionable:IsAlive() then

    if Tdetected>Tnow then
      -- Delay call.
      self:ScheduleOnce(Tdetected-Tnow, self.KnowObject, self, Positionable, RecceName)
    else

      -- Name of the object.
      local name=Positionable:GetName()

      -- Try to get the contact by name.
      local contact=self:GetContactByName(name)

      if contact then

        -- Update contact info.
        self:_UpdateContact(contact)

      else

        -- Create new contact.
        contact=self:_CreateContact(Positionable, RecceName)

        if contact then

          -- Debug info.
          self:T(string.format("%s contact detected by %s", contact.groupname, RecceName or "unknown"))

          -- Add contact to table.
          self:AddContact(contact)

          -- Trigger new contact event.
          self:NewContact(contact)

        end

      end
    end
  end

  return self
end

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

--- Check if a Contact is already known. It is checked, whether the contact is in the contacts table.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact to be added.
-- @return #boolean If `true`, contact is already known.
function INTEL:_IsContactKnown(Contact)

  for i,_contact in pairs(self.Contacts) do
    local contact=_contact --#INTEL.Contact
    if contact.groupname==Contact.groupname then
      return true
    end
  end

  return false
end


--- Add a contact to our list.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact to be added.
-- @return #INTEL self
function INTEL:AddContact(Contact)

  -- First check if the contact is already in the table.
  if self:_IsContactKnown(Contact) then
    self:E(self.lid..string.format("WARNING: Contact %s is already in the contact table!", tostring(Contact.groupname)))
  else
    self:T(self.lid..string.format("Adding new Contact %s to table", tostring(Contact.groupname)))
    table.insert(self.Contacts, Contact)
  end

  return self
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
  return self
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

  -- We never forget statics as they don't move.
  if Contact.isStatic then
    return false
  end

  -- Time since last detected.
  local dT=timer.getAbsTime()-Contact.Tdetected

  local dTforget=nil

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

--- [Internal] Paint picture of the battle field. Does Cluster analysis and updates clusters. Sets markers if markers are enabled.
-- @param #INTEL self
function INTEL:PaintPicture()
  self:F(self.lid.."Painting Picture!")

  -- First remove all lost contacts from clusters.
  for _,_contact in pairs(self.ContactsLost) do
    local contact=_contact --#INTEL.Contact

    -- Get cluster this contact belongs to (if any).
    local cluster=self:GetClusterOfContact(contact)

    if cluster then
      self:RemoveContactFromCluster(contact, cluster)
    end
  end

  -- Clean up cluster table.
  local ClusterSet = {}

  -- Now check if whole clusters were lost.
  for _i,_cluster in pairs(self.Clusters) do
    local cluster=_cluster --#INTEL.Cluster

    if cluster.size>0 and self:ClusterCountUnits(cluster)>0 then
      -- This one has size>0 and units>0
      table.insert(ClusterSet,_cluster)
    else

      -- This cluster is gone.

      -- Remove marker.
      if cluster.marker then
        cluster.marker:Remove()
      end

      -- Marker of the arrow.
      if cluster.markerID then
        COORDINATE:RemoveMark(cluster.markerID)
      end

      -- Lost cluster.
      self:LostCluster(cluster, cluster.mission)
    end
  end

  -- Set Clusters.
  self.Clusters = ClusterSet

  -- Update positions.
  self:_UpdateClusterPositions()


  for _,_contact in pairs(self.Contacts) do
    local contact=_contact --#INTEL.Contact

    -- Debug info.
    self:T(string.format("Paint Picture: checking for %s",contact.groupname))

    -- Get the current cluster (if any) this contact belongs to.
    local currentcluster=self:GetClusterOfContact(contact)

    if currentcluster then
      ---
      -- Contact is currently part of a cluster.
      ---

      -- Check if the contact is still connected to the cluster.
      local isconnected=self:IsContactConnectedToCluster(contact, currentcluster)

      if isconnected then

      else

        --- Not connected to current cluster any more.

        -- Remove from current cluster.
        self:RemoveContactFromCluster(contact, currentcluster)

        -- Find new cluster.
        local cluster=self:_GetClosestClusterOfContact(contact)

        if cluster then
           -- Add contact to cluster.
          self:AddContactToCluster(contact, cluster)
        else

          -- Create a new cluster.
          local newcluster=self:_CreateClusterFromContact(contact)

          -- Trigger new cluster event.
          self:NewCluster(newcluster)
        end

      end

    else

      ---
      -- Contact is not in any cluster yet.
      ---

      -- Debug info.
      self:T(self.lid..string.format("Paint Picture: contact %s has NO current cluster", contact.groupname))

      -- Get the closest existing cluster of this contact.
      local cluster=self:_GetClosestClusterOfContact(contact)

      if cluster then

        -- Debug info.
        self:T(self.lid..string.format("Paint Picture: contact %s has closest cluster #%d",contact.groupname, cluster.index))

        -- Add contact to this cluster.
        self:AddContactToCluster(contact, cluster)

      else
      
        -- Debug info.
        self:T(self.lid..string.format("Paint Picture: contact %s has no closest cluster ==> Create new cluster", contact.groupname))      

        -- Create a brand new cluster.
        local newcluster=self:_CreateClusterFromContact(contact)

        -- Trigger event for a new cluster.
        self:NewCluster(newcluster)
      end

    end

  end

  -- Update positions.
  self:_UpdateClusterPositions()

  -- Update F10 marker text if cluster has changed.
  if self.clustermarkers then
    for _,_cluster in pairs(self.Clusters) do
      local cluster=_cluster --#INTEL.Cluster
      --local coordinate=self:GetClusterCoordinate(cluster)

      -- Update F10 marker.
      if self.verbose >= 1 then
        BASE:I("Updating cluster marker and future position")
      end

      -- Update cluster markers.
      self:UpdateClusterMarker(cluster)

      -- Extrapolate future position of the cluster.
      self:CalcClusterFuturePosition(cluster, 300)

    end
  end

  return self
end

--- Create a new cluster.
-- @param #INTEL self
-- @return #INTEL.Cluster cluster The cluster.
function INTEL:_CreateCluster()

  -- Create new cluster.
  local cluster={} --#INTEL.Cluster

  cluster.index=self.clustercounter
  cluster.coordinate=COORDINATE:New(0, 0, 0)
  cluster.threatlevelSum=0
  cluster.threatlevelMax=0
  cluster.size=0
  cluster.Contacts={}
  cluster.altitude=0

  -- Increase counter.
  self.clustercounter=self.clustercounter+1

  return cluster
end

--- Create a new cluster from a first contact. The contact is automatically added to the cluster.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The first contact.
-- @return #INTEL.Cluster cluster The cluster.
function INTEL:_CreateClusterFromContact(Contact)

  local cluster=self:_CreateCluster()

  self:T(self.lid..string.format("Created NEW cluster #%d with first contact %s", cluster.index, Contact.groupname))

  cluster.coordinate:UpdateFromCoordinate(Contact.position)

  cluster.ctype=Contact.ctype

  self:AddContactToCluster(Contact, cluster)

  return cluster
end

--- Add cluster to table.
-- @param #INTEL self
-- @param #INTEL.Cluster Cluster The cluster to add.
function INTEL:_AddCluster(Cluster)

  --TODO: Check if cluster is already in the table.

  -- Add cluster.
  table.insert(self.Clusters, Cluster)

  return self
end

--- Add a contact to the cluster.
-- @param #INTEL self
-- @param #INTEL.Contact contact The contact.
-- @param #INTEL.Cluster cluster The cluster.
function INTEL:AddContactToCluster(contact, cluster)

  if contact and cluster then

    -- Add neighbour to cluster contacts.
    table.insert(cluster.Contacts, contact)

    -- Add to threat level sum.
    cluster.threatlevelSum=cluster.threatlevelSum+contact.threatlevel

    -- Increase size.
    cluster.size=cluster.size+1

    -- alt
    self:GetClusterAltitude(cluster,true)

    -- Debug info.
    self:T(self.lid..string.format("Adding contact %s to cluster #%d [%s] ==> New size=%d", contact.groupname, cluster.index, cluster.ctype, cluster.size))
  end

  return self
end

--- Remove a contact from a cluster.
-- @param #INTEL self
-- @param #INTEL.Contact contact The contact.
-- @param #INTEL.Cluster cluster The cluster.
function INTEL:RemoveContactFromCluster(contact, cluster)

  if contact and cluster then

    for i=#cluster.Contacts,1,-1 do
      local Contact=cluster.Contacts[i] --#INTEL.Contact

      if Contact.groupname==contact.groupname then

        -- Remove threat level sum.
        cluster.threatlevelSum=cluster.threatlevelSum-contact.threatlevel

        -- Decrease cluster size.
        cluster.size=cluster.size-1

        -- Remove from table.
        table.remove(cluster.Contacts, i)

        -- Debug info.
        self:T(self.lid..string.format("Removing contact %s from cluster #%d ==> New cluster size=%d", contact.groupname, cluster.index, cluster.size))

        return self
      end

    end

  end
  return self
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

--- Calculate cluster heading.
-- @param #INTEL self
-- @param #INTEL.Cluster cluster The cluster of contacts.
-- @return #number Heading average of all groups in the cluster.
function INTEL:CalcClusterDirection(cluster)

  local direction = 0
  local speedsum = 0
  local n=0
  for _,_contact in pairs(cluster.Contacts) do
    local contact=_contact --#INTEL.Contact

    if (not contact.isStatic) and contact.group:IsAlive() then
      local speed = contact.group:GetVelocityKNOTS()
      direction = direction + (contact.group:GetHeading()*speed)
      n=n+1
      speedsum = speedsum + speed
    end
  end

  --TODO: This calculation is WRONG!
  -- Simple example for two groups:
  -- First group is going West, i.e. heading 090
  -- Second group is going East, i.e. heading 270
  -- Total is 360/2=180, i.e. South!
  -- It should not go anywhere as the two movements cancel each other.
  -- Apple - Correct, edge case for N=2^x, but when 2 pairs of groups drive in exact opposite directions, the cluster will split at some point?
  -- maybe add the speed as weight to get a weighted factor:

  if n==0 then
    return 0
  else
    return math.floor(direction / (speedsum * n ))
  end
  
end

--- Calculate cluster speed.
-- @param #INTEL self
-- @param #INTEL.Cluster cluster The cluster of contacts.
-- @return #number Speed average of all groups in the cluster in MPS.
function INTEL:CalcClusterSpeed(cluster)

  local velocity = 0 ; local n=0
  for _,_contact in pairs(cluster.Contacts) do
    local contact=_contact --#INTEL.Contact

    if (not contact.isStatic) and contact.group:IsAlive() then
      velocity = velocity + contact.group:GetVelocityMPS()
      n=n+1
    end

  end

  if n==0 then
    return 0
  else
    return math.floor(velocity / n)
  end
end

--- Calculate cluster velocity vector.
-- @param #INTEL self
-- @param #INTEL.Cluster cluster The cluster of contacts.
-- @return DCS#Vec3 Velocity vector in m/s.
function INTEL:CalcClusterVelocityVec3(cluster)

  local v={x=0, y=0, z=0} --DCS#Vec3

  for _,_contact in pairs(cluster.Contacts) do
    local contact=_contact --#INTEL.Contact

    if (not contact.isStatic) and contact.group:IsAlive() then
      local vec=contact.group:GetVelocityVec3()
      v.x=v.x+vec.x
      v.y=v.y+vec.y
      v.z=v.y+vec.z
    end
  end

  return v
end

--- Calculate cluster future position after given seconds.
-- @param #INTEL self
-- @param #INTEL.Cluster cluster The cluster of contacts.
-- @param #number seconds Time interval in seconds. Default is `self.prediction`.
-- @return Core.Point#COORDINATE Calculated future position of the cluster.
function INTEL:CalcClusterFuturePosition(cluster, seconds)

  -- Get current position of the cluster.
  local p=self:GetClusterCoordinate(cluster)

  -- Velocity vector in m/s.
  local v=self:CalcClusterVelocityVec3(cluster)

  -- Time in seconds.
  local t=seconds or self.prediction

  -- Extrapolated vec3.
  local Vec3={x=p.x+v.x*t, y=p.y+v.y*t, z=p.z+v.z*t}

  -- Future position.
  local futureposition=COORDINATE:NewFromVec3(Vec3)

  -- Create an arrow pointing in the direction of the movement.
  if self.clustermarkers and self.clusterarrows then
    if cluster.markerID then
      COORDINATE:RemoveMark(cluster.markerID)
    end
    cluster.markerID = p:ArrowToAll(futureposition, self.coalition, {1,0,0}, 1, {1,1,0}, 0.5, 2, true, "Position Calc")
  end

  return futureposition
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
-- @return #boolean If `true`, contact is connected to this cluster.
-- @return #number Distance to cluster in meters.
function INTEL:IsContactConnectedToCluster(contact, cluster)

  -- Must be of the same type. We do not want to mix aircraft with ground units.
  if contact.ctype~=cluster.ctype then
    return false, math.huge
  end

  for _,_contact in pairs(cluster.Contacts) do
    local Contact=_contact --#INTEL.Contact

    -- Do not calcuate the distance to the contact itself unless it is the only contact in the cluster.
    if Contact.groupname~=contact.groupname or cluster.size==1 then

      --local dist=Contact.position:Get2DDistance(contact.position)
      local dist=Contact.position:DistanceFromPointVec2(contact.position)

      -- AIR - check for spatial proximity (corrected because airprox was always false for ctype~=INTEL.Ctype.AIRCRAFT)
      local airprox = true
      if contact.ctype == INTEL.Ctype.AIRCRAFT then
       self:T(string.format("Cluster Alt=%d | Contact Alt=%d",cluster.altitude,contact.altitude))
       local adist = math.abs(cluster.altitude - contact.altitude)
       if adist > UTILS.FeetToMeters(10000) then -- limit to 10kft
        airprox = false
       end
      end

      if dist<self.clusterradius and airprox then
        return true, dist
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

--- Get distance to cluster.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact.
-- @param #INTEL.Cluster Cluster The cluster to which the distance is calculated.
-- @return #number Distance in meters.
function INTEL:_GetDistContactToCluster(Contact, Cluster)

  local distmin=math.huge

  for _,_contact in pairs(Cluster.Contacts) do
    local contact=_contact --#INTEL.Contact

    if contact.group and contact.group:IsAlive() and Contact.groupname~=contact.groupname then

      local dist=Contact.position:Get2DDistance(contact.position)

      if dist<distmin then
        distmin=dist
      end
    end

  end

  return distmin
end

--- Get closest cluster of contact.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact.
-- @return #INTEL.Cluster The cluster this contact is part of or `#nil` otherwise.
-- @return #number Distance to cluster in meters.
function INTEL:_GetClosestClusterOfContact(Contact)

  local Cluster=nil  --#INTEL.Cluster

  local distmin=self.clusterradius

  if not Contact.altitude then
    Contact.altitude = Contact.group:GetAltitude()
  end

  for _,_cluster in pairs(self.Clusters) do
    local cluster=_cluster --#INTEL.Cluster

    if cluster.ctype==Contact.ctype then

      local dist=self:_GetDistContactToCluster(Contact, cluster)

      -- AIR - check for spatial proximity (ff: Changed because airprox was always false for ctype~=AIRCRAFT!)
      local airprox=true
      if Contact.ctype == INTEL.Ctype.AIRCRAFT then
        if not cluster.altitude then
          cluster.altitude = self:GetClusterAltitude(cluster,true)
        end
        local adist = math.abs(cluster.altitude - Contact.altitude)
         self:T(string.format("Cluster Alt=%d | Contact Alt=%d",cluster.altitude,Contact.altitude))
        if adist > UTILS.FeetToMeters(10000) then
          airprox = false
        end
      end

      if dist<distmin and airprox then
        Cluster=cluster
        distmin=dist
      end

    end
  end

  return Cluster, distmin
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

--- Get the altitude of a cluster.
-- @param #INTEL self
-- @param #INTEL.Cluster Cluster The cluster.
-- @param #boolean Update If `true`, update the altitude. Default is to just return the last stored altitude.
-- @return #number The average altitude (ASL) of this cluster in meters.
function INTEL:GetClusterAltitude(Cluster, Update)

  -- Init.
  local newalt = 0
  local n=0

  -- Loop over all contacts.
  for _,_contact in pairs(Cluster.Contacts) do
    local contact=_contact --#INTEL.Contact
    if contact.altitude then
      newalt = newalt + contact.altitude
      n=n+1
    end
  end

  -- Average.
  local avgalt = 0
  if n>0 then
    avgalt = newalt/n
  end

  -- Update cluster coordinate.
  Cluster.altitude = avgalt

  self:T(string.format("Updating Cluster Altitude: %d",Cluster.altitude))

  return Cluster.altitude
end

--- Get the coordinate of a cluster.
-- @param #INTEL self
-- @param #INTEL.Cluster Cluster The cluster.
-- @param #boolean Update If `true`, update the coordinate. Default is to just return the last stored position.
-- @return Core.Point#COORDINATE The coordinate of this cluster.
function INTEL:GetClusterCoordinate(Cluster, Update)

  -- Init.
  local x=0 ; local y=0 ; local z=0 ; local n=0

  -- Loop over all contacts.
  for _,_contact in pairs(Cluster.Contacts) do
    local contact=_contact --#INTEL.Contact

    local vec3=nil --DCS#Vec3

    if Update and contact.group and contact.group:IsAlive() then
      vec3 = contact.group:GetVec3()
    end

    if not vec3 then
      vec3=contact.position
    end

    if vec3 then

      -- Sum up posits.
      x=x+vec3.x
      y=y+vec3.y
      z=z+vec3.z

      -- Increase counter.
      n=n+1

    end

  end

  if n>0 then

    -- Average.
    local Vec3={x=x/n, y=y/n, z=z/n} --DCS#Vec3

    -- Update cluster coordinate.
    Cluster.coordinate:UpdateFromVec3(Vec3)

  end

  return Cluster.coordinate
end

--- Check if the coordindate of the cluster changed.
-- @param #INTEL self
-- @param #INTEL.Cluster Cluster The cluster.
-- @param #number Threshold in meters. Default 100 m.
-- @param Core.Point#COORDINATE Coordinate Reference coordinate. Default is the last known coordinate of the cluster.
-- @return #boolean If `true`, the coordinate changed by more than the given threshold.
function INTEL:_CheckClusterCoordinateChanged(Cluster, Coordinate, Threshold)

  Threshold=Threshold or 100

  Coordinate=Coordinate or Cluster.coordinate

  -- Positions of cluster.
  local a=Coordinate:GetVec3()
  local b=self:GetClusterCoordinate(Cluster, true):GetVec3()

  local dist=UTILS.VecDist3D(a,b)

  if dist>Threshold then
    return true
  else
    return false
  end

end

--- Update coordinates of the known clusters.
-- @param #INTEL self
function INTEL:_UpdateClusterPositions()
  for _,_cluster in pairs (self.Clusters) do
    local cluster=_cluster --#INTEL.Cluster

    -- Update cluster coordinate.
    local coord = self:GetClusterCoordinate(cluster, true)
    local alt = self:GetClusterAltitude(cluster,true)

    -- Debug info.
    self:T(self.lid..string.format("Updating Cluster position size: %s", cluster.size))
  end
  return self
end

--- Count number of alive units in contact.
-- @param #INTEL self
-- @param #INTEL.Contact Contact The contact.
-- @return #number unitcount
function INTEL:ContactCountUnits(Contact)
  if Contact.isStatic then
    if Contact.group and Contact.group:IsAlive() then
      return 1
    else
      return 0
    end
  else
    if Contact.group then
      local n=Contact.group:CountAliveUnits()
      return n
    else
      return 0
    end
  end
end

--- Count number of alive units in cluster.
-- @param #INTEL self
-- @param #INTEL.Cluster Cluster The cluster
-- @return #number unitcount
function INTEL:ClusterCountUnits(Cluster)
  local unitcount = 0
  for _,_contact in pairs (Cluster.Contacts) do
    local contact=_contact --#INTEL.Contact
    unitcount = unitcount + self:ContactCountUnits(contact)
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
  local text=string.format("Cluster #%d: %s\nSize %d\nUnits %d\nTLsum=%d", cluster.index, cluster.ctype, cluster.size, unitcount, cluster.threatlevelSum)

  if not cluster.marker then

    -- First time ==> need to create a new marker object.
    cluster.marker=MARKER:New(cluster.coordinate, text):ToCoalition(self.coalition)

  else

    -- Need to refresh?
    local refresh=false

    -- Check if marker text changed.
    if cluster.marker.text~=text then
      cluster.marker.text=text
      refresh=true
    end

    -- Check if coordinate changed.
    local coordchange=self:_CheckClusterCoordinateChanged(cluster, cluster.marker.coordinate)
    if coordchange then
      cluster.marker.coordinate:UpdateFromCoordinate(cluster.coordinate)
      refresh=true
    end

    if refresh then
      cluster.marker:Refresh()
    end

  end

  return self
end

--- Get the contact with the highest threat level from the cluster.
-- @param #INTEL self
-- @param #INTEL.Cluster Cluster The cluster.
-- @return #INTEL.Contact the contact or nil if none
function INTEL:GetHighestThreatContact(Cluster)
  local threatlevel=-1
  local rcontact = nil
  
  for _,_contact in pairs(Cluster.Contacts) do

    local contact=_contact --Ops.Intel#INTEL.Contact

    if contact.threatlevel>threatlevel then
      threatlevel=contact.threatlevel
      rcontact = contact
    end

  end
  return rcontact
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------
-- Start INTEL_DLINK
----------------------------------------------------------------------------------------------

--- **Ops_DLink** - Support for Office of Military Intelligence.
--
-- **Main Features:**
--
--    * Overcome limitations of (non-available) datalinks between ground radars
--    * Detect and track contacts consistently across INTEL instances
--    * Use FSM events to link functionality into your scripts
--    * Easy setup
--
--- ===
--
-- ### Author: **applevangelist**

--- INTEL_DLINK class.
-- @type INTEL_DLINK
-- @field #string ClassName Name of the class.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number verbose Make the logging verbose.
-- @field #string alias Alias name for logging.
-- @field #number cachetime Number of seconds to keep an object.
-- @field #number interval Number of seconds between collection runs.
-- @field #table contacts Table of Ops.Intel#INTEL.Contact contacts.
-- @field #table clusters Table of Ops.Intel#INTEL.Cluster clusters.
-- @field #table contactcoords Table of contacts' Core.Point#COORDINATE objects.
-- @extends Core.Fsm#FSM

--- INTEL_DLINK data aggregator
-- @field #INTEL_DLINK
INTEL_DLINK = {
  ClassName       = "INTEL_DLINK",
  verbose         =     0,
  lid             =   nil,
  alias           =   nil,
  cachetime       =   120,
  interval        =   20,
  contacts        =   {},
  clusters        =   {},
  contactcoords   =   {},
}

--- Version string
-- @field #string version
INTEL_DLINK.version = "0.0.2"

--- Function to instantiate a new object
-- @param #INTEL_DLINK self
-- @param #table Intels Table of Ops.Intel#INTEL objects.
-- @param #string Alias (optional) Name of this instance. Default "SPECTRE"
-- @param #number Interval (optional) When to query #INTEL objects for detected items (default 20 seconds).
-- @param #number Cachetime (optional) How long to cache detected items (default 300 seconds).
-- @usage Use #INTEL_DLINK if you want to merge data from a number of #INTEL objects into one. This might be useful to simulate a
-- Data Link, e.g. for Russian-tech based EWR, realising a Star Topology @{https://en.wikipedia.org/wiki/Network_topology#Star}
-- in a basic setup. It will collect the contacts and clusters from the #INTEL objects.
-- Contact duplicates are removed. Clusters might contain duplicates (Might fix that later, WIP).
--
-- Basic setup:
--
--     local datalink = INTEL_DLINK:New({myintel1,myintel2}), "FSB", 20, 300)
--     datalink:__Start(2)
--
-- Add an Intel while running:
--
--     datalink:AddIntel(myintel3)
--
-- Gather the data:
--
--     datalink:GetContactTable() -- #table of #INTEL.Contact contacts.
--     datalink:GetClusterTable() -- #table of #INTEL.Cluster clusters.
--     datalink:GetDetectedItemCoordinates() -- #table of contact coordinates, to be compatible with @{Functional.Detection#DETECTION}.
--
-- Gather data with the event function:
--
--     function datalink:OnAfterCollected(From, Event, To, Contacts, Clusters)
--       ... <your code here> ...
--     end
--
function INTEL_DLINK:New(Intels, Alias, Interval, Cachetime)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #INTEL_DLINK

  self.intels = Intels or {}
  self.contacts = {}
  self.clusters = {}
  self.contactcoords = {}

  -- Set alias.
  if Alias then
    self.alias=tostring(Alias)
  else
    self.alias="SPECTRE"
  end

  -- Interval
  self.interval = Interval or 20

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("INTEL_DLINK %s | ", self.alias)

  -- Cache time
  self:SetDLinkCacheTime(Cachetime or 120)
  
    -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event        -->    To State
  self:AddTransition("Stopped",       "Start",             "Running")     -- Start FSM.
  self:AddTransition("*",             "Collect",           "*")           -- Collect data.
  self:AddTransition("*",             "Collected",         "*")           -- Collection of data done.
  self:AddTransition("*",             "Stop",              "Stopped")     -- Stop FSM.

  ----------------------------------------------------------------------------------------------
  -- Pseudo Functions
  ----------------------------------------------------------------------------------------------
  --- Triggers the FSM event "Start". Starts the INTEL_DLINK.
  -- @function [parent=#INTEL_DLINK] Start
  -- @param #INTEL_DLINK self

  --- Triggers the FSM event "Start" after a delay. Starts the INTEL_DLINK.
  -- @function [parent=#INTEL_DLINK] __Start
  -- @param #INTEL_DLINK self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the INTEL_DLINK.
  -- @param #INTEL_DLINK self

  --- Triggers the FSM event "Stop" after a delay. Stops the INTEL_DLINK.
  -- @function [parent=#INTEL_DLINK] __Stop
  -- @param #INTEL_DLINK self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Collect". Used internally to collect all data.
  -- @function [parent=#INTEL_DLINK] Collect
  -- @param #INTEL_DLINK self

  --- Triggers the FSM event "Collect" after a delay.
  -- @function [parent=#INTEL_DLINK] __Status
  -- @param #INTEL_DLINK self
  -- @param #number delay Delay in seconds.

  --- On After "Collected" event. Data tables have been refreshed.
  -- @function [parent=#INTEL_DLINK] OnAfterCollected
  -- @param #INTEL_DLINK self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #table Contacts Table of #INTEL.Contact Contacts.
  -- @param #table Clusters Table of #INTEL.Cluster Clusters.

  return self
end
----------------------------------------------------------------------------------------------
-- Helper & User Functions
----------------------------------------------------------------------------------------------

--- Function to add an #INTEL object to the aggregator
-- @param #INTEL_DLINK self
-- @param Ops.Intel#INTEL Intel the #INTEL object to add
-- @return #INTEL_DLINK self
function INTEL_DLINK:AddIntel(Intel)
   self:T(self.lid .. "AddIntel")
   if Intel then
    table.insert(self.intels,Intel)
   end
   return self
end

----------------------------------------------------------------------------------------------
-- FSM Functions
----------------------------------------------------------------------------------------------

--- Function to start the work.
-- @param #INTEL_DLINK self
-- @param #string From The From state
-- @param #string Event The Event triggering this call
-- @param #string To The To state
-- @return #INTEL_DLINK self
function INTEL_DLINK:onafterStart(From, Event, To)
  self:T({From, Event, To})
  local text = string.format("Version %s started.", self.version)
  self:I(self.lid .. text)
  self:__Collect(-math.random(1,10))
  return self
end

  --- Function to set how long INTEL DLINK remembers contacts.
  -- @param #INTEL_DLINK self
  -- @param #number seconds Remember this many seconds. Defaults to 180.
  -- @return #INTEL_DLINK self
  function INTEL_DLINK:SetDLinkCacheTime(seconds)
    self.cachetime = math.abs(seconds or 120)
    self:I(self.lid.."Caching for "..self.cachetime.." seconds.")
    return self
  end

--- Function to collect data from the various #INTEL
-- @param #INTEL_DLINK self
-- @param #string From The From state
-- @param #string Event The Event triggering this call
-- @param #string To The To state
-- @return #INTEL_DLINK self
function INTEL_DLINK:onbeforeCollect(From, Event, To)
  self:T({From, Event, To})
  -- run through our #INTEL objects and gather the contacts tables
  self:T("Contacts Data Gathering")
  local newcontacts = {}
  local intels = self.intels -- #table
  for _,_intel in pairs (intels) do
    _intel = _intel -- #INTEL
    if _intel:Is("Running") then
      local ctable = _intel:GetContactTable() or {} -- #INTEL.Contact
        for _,_contact in pairs (ctable) do
          local _ID = string.format("%s-%d",_contact.groupname, _contact.Tdetected)
          self:T(string.format("Adding %s",_ID))
          newcontacts[_ID] = _contact
        end
    end
  end
  -- clean up for stale contacts and dupes
  self:T("Cleanup")
  local contacttable = {}
  local coordtable = {}
  local TNow = timer.getAbsTime()
  local Tcache = self.cachetime
  for _ind, _contact in pairs(newcontacts) do -- #string, #INTEL.Contact
    if TNow - _contact.Tdetected < Tcache then
      if (not contacttable[_contact.groupname]) or (contacttable[_contact.groupname] and contacttable[_contact.groupname].Tdetected < _contact.Tdetected) then
        self:T(string.format("Adding %s",_contact.groupname))
        contacttable[_contact.groupname] = _contact
        table.insert(coordtable,_contact.position)
      end
    end
  end
  -- run through our #INTEL objects and gather the clusters tables
  self:T("Clusters Data Gathering")
  local newclusters = {}
  local intels = self.intels -- #table
  for _,_intel in pairs (intels) do
    _intel = _intel -- #INTEL
    if _intel:Is("Running") then
      local ctable = _intel:GetClusterTable() or {} -- #INTEL.Cluster
        for _,_cluster in pairs (ctable) do
          local _ID = string.format("%s-%d", _intel.alias, _cluster.index)
          self:T(string.format("Adding %s",_ID))
          table.insert(newclusters,_cluster)
        end
    end
  end
  -- update self tables
  self.contacts = contacttable
  self.contactcoords = coordtable
  self.clusters = newclusters
  self:__Collected(1, contacttable, newclusters) -- make table available via FSM Event
  -- schedule next round
  local interv = self.interval * -1
  self:__Collect(interv)
  return self
end

--- Function called after collection is done
-- @param #INTEL_DLINK self
-- @param #string From The From state
-- @param #string Event The Event triggering this call
-- @param #string To The To state
-- @param #table Contacts The table of collected #INTEL.Contact contacts
-- @param #table Clusters The table of collected #INTEL.Cluster clusters
-- @return #INTEL_DLINK self
function INTEL_DLINK:onbeforeCollected(From, Event, To, Contacts, Clusters)
  self:T({From, Event, To})
  return self
end

--- Function to stop
-- @param #INTEL_DLINK self
-- @param #string From The From state
-- @param #string Event The Event triggering this call
-- @param #string To The To state
-- @return #INTEL_DLINK self
function INTEL_DLINK:onafterStop(From, Event, To)
  self:T({From, Event, To})
  local text = string.format("Version %s stopped.", self.version)
  self:I(self.lid .. text)
  return self
end

--- Function to query the detected contacts
-- @param #INTEL_DLINK self
-- @return #table Table of #INTEL.Contact contacts
function INTEL_DLINK:GetContactTable()
  self:T(self.lid .. "GetContactTable")
  return self.contacts
end

--- Function to query the detected clusters
-- @param #INTEL_DLINK self
-- @return #table Table of #INTEL.Cluster clusters
function INTEL_DLINK:GetClusterTable()
  self:T(self.lid .. "GetClusterTable")
  return self.clusters
end

--- Function to query the detected contact coordinates
-- @param #INTEL_DLINK self
-- @return #table Table of the contacts' Core.Point#COORDINATE objects.
function INTEL_DLINK:GetDetectedItemCoordinates()
  self:T(self.lid .. "GetDetectedItemCoordinates")
  return self.contactcoords
end

----------------------------------------------------------------------------------------------
-- End INTEL_DLINK
----------------------------------------------------------------------------------------------
