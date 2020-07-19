--- **Ops** - Office of Military Intelligence.
--
-- **Main Features:**
--
--    * Stuff
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Intel
-- @image OPS_Intel.png


--- INTEL class.
-- @type INTEL
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number coalition Coalition side number, e.g. `coalition.side.RED`.
-- @field #string alias Name of the agency.
-- @field #table filterCategory Category filters.
-- @field Core.Set#SET_ZONE acceptzoneset Set of accept zones. If defined, only contacts in these zones are considered.
-- @field Core.Set#SET_ZONE rejectzoneset Set of reject zones. Contacts in these zones are not considered, even if they are in accept zones.
-- @field #table Contacts Table of detected items.
-- @field #table ContactsLost Table of lost detected items.
-- @field #table ContactsUnknown Table of new detected items.
-- @field #table Clusters Clusters of detected groups.
-- @field #number clustercounter Running number of clusters.
-- @field #number dTforget Time interval in seconds before a known contact which is not detected any more is forgotten.
-- @extends Core.Fsm#FSM

--- Top Secret!
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\INTEL_Main.jpg)
--
-- # The INTEL Concept
--
--
--
-- @field #INTEL
INTEL = {
  ClassName       = "INTEL",
  Debug           =   nil,
  lid             =   nil,
  alias           =   nil,
  filterCategory  =    {},
  detectionset    =   nil,
  Contacts        =    {},
  ContactsLost    =    {},
  ContactsUnknown =    {},
  Clusters        =    {},
  clustercounter  =     1,
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
-- @field #number speed Last known speed.
-- @field #number markerID F10 map marker ID.

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


--- INTEL class version.
-- @field #string version
INTEL.version="0.0.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Accept zones.
-- TODO: Reject zones.
-- TODO: Filter detection methods.
-- NOGO: SetAttributeZone --> return groups of generalized attributes in a zone.
-- DONE: Loose units only if they remain undetected for a given time interval. We want to avoid fast oscillation between detected/lost states. Maybe 1-5 min would be a good time interval?!
-- DONE: Combine units to groups for all, new and lost.
-- TODO: process detected set asynchroniously for better performance.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new INTEL object and start the FSM.
-- @param #INTEL self
-- @param Core.Set#SET_GROUP DetectionSet Set of detection groups.
-- @param #number Coalition Coalition side. Can also be passed as a string "red", "blue" or "neutral".
-- @return #INTEL self
function INTEL:New(DetectionSet, Coalition)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #INTEL

  -- Detection set.
  self.detectionset=DetectionSet or SET_GROUP:New()
  
  -- Determine coalition from first group in set.
  self.coalition=Coalition or DetectionSet:CountAlive()>0 and DetectionSet:GetFirst():GetCoalition() or nil
  
  -- Set alias.
  self.alias="SPECTRE"  
  if self.coalition then
    if self.coalition==coalition.side.RED then
      self.alias="KGB"
    elseif self.coalition==coalition.side.BLUE then
      self.alias="CIA"
    end
  end
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("INTEL %s | ", self.alias)

  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- INTEL status update
  
  self:AddTransition("*",             "Detect",             "*")           -- Start detection run. Not implemented yet!
  
  self:AddTransition("*",             "NewContact",         "*")           -- New contact has been detected.
  self:AddTransition("*",             "LostContact",        "*")           -- Contact could not be detected any more.
  
  
  -- Defaults
  self:SetForgetTime()
  self:SetAcceptZones()

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


  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  self.Debug=true

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set accept zones. Only contacts detected in this/these zone(s) are considered. 
-- @param #INTEL self
-- @param Core.Set#SET_ZONE AcceptZoneSet Set of accept zones
-- @return #INTEL self
function INTEL:SetAcceptZones(AcceptZoneSet)
  self.acceptzoneset=AcceptZoneSet or SET_ZONE:New()
  return self
end

--- Set accept zones. Only contacts detected in this zone are considered. 
-- @param #INTEL self
-- @param Core.Zone#ZONE AcceptZone Add a zone to the accept zone set.
-- @return #INTEL self
function INTEL:AddAcceptZone(AcceptZone)
  self.acceptzoneset:AddZone(AcceptZone)
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
  self:I(self.lid..text)
  
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
-- @param #table Categories Filter categories, e.g. {Group.Category.AIRPLANE, Group.Category.HELICOPTER}.
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
  self:I(self.lid..text)
  
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

  -- Short info.
  local text=string.format("Status %s [Agents=%s]: Contacts=%d, New=%d, Lost=%d", fsmstate, self.detectionset:CountAlive(), Ncontacts, #self.ContactsUnknown, #self.ContactsLost)
  self:I(self.lid..text)
  
  -- Detailed info.
  if Ncontacts>0 then
    text="Detected Contacts:"
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

  self:__Status(-30) 
end


--- Update detected items.
-- @param #INTEL self
function INTEL:UpdateIntel()

  -- Set of all detected units.
  local DetectedSet=SET_UNIT:New()

  -- Loop over all units providing intel.
  for _,_group in pairs(self.detectionset:GetSet()) do
    local group=_group --Wrapper.Group#GROUP
    if group and group:IsAlive() then
      for _,_recce in pairs(group:GetUnits()) do
        local recce=_recce --Wrapper.Unit#UNIT
        
        -- Get set of detected units.
        local detectedunitset=recce:GetDetectedUnitSet()
               
        -- Add detected units to all set.
        DetectedSet=DetectedSet:GetSetUnion(detectedunitset)
      end
    end    
  end
  
  -- TODO: Filter units from reject zones.
  -- TODO: Filter detection methods?
  local remove={}
  for _,_unit in pairs(DetectedSet.Set) do
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
        table.insert(remove, unit:GetName())
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
        self:I(self.lid..string.format("Removing unit %s category=%d", unit:GetName(), unit:GetCategory()))
        table.insert(remove, unit:GetName())
      end
    end    
        
  end
  
  -- Remove filtered units.
  for _,unitname in pairs(remove) do
    DetectedSet:Remove(unitname, true)
  end
  
  -- Create detected contacts.  
  self:CreateDetectedItems(DetectedSet)
  
  -- Paint a picture of the battlefield.
  self:PaintPicture()
  
end





--- Create detected items.
-- @param #INTEL self
-- @param Core.Set#SET_UNIT detectedunitset Set of detected units. 
function INTEL:CreateDetectedItems(detectedunitset)

  local detectedgroupset=SET_GROUP:New()

  -- Convert detected UNIT set to detected GROUP set.
  for _,_unit in pairs(detectedunitset:GetSet()) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    local group=unit:GetGroup()
    
    if group and group:IsAlive() then
      local groupname=group:GetName()     
      detectedgroupset:Add(groupname, group)
    end
      
  end
  
  -- Current time.
  local Tnow=timer.getAbsTime()
  
  for _,_group in pairs(detectedgroupset.Set) do
    local group=_group --Wrapper.Group#GROUP
    
    -- Group name.
    local groupname=group:GetName()
    
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
      item.threatlevel=group:GetUnit(1):GetThreatLevel()
      item.position=group:GetCoordinate()
      item.velocity=group:GetVelocityVec3()
      item.speed=group:GetVelocityMPS()
      
      -- Add contact to table.    
      self:AddContact(item)
      
      -- Trigger new contact event.
      self:NewContact(item)
    end
    
  end
  
  -- Now check if there some groups could not be detected any more.
  for i=#self.Contacts,1,-1 do
    local item=self.Contacts[i] --#INTEL.Contact
    
    local group=detectedgroupset:FindGroup(item.groupname)
    
    -- Check if deltaT>Tforget. We dont want quick oscillations between detected and undetected states.
    if self:_CheckContactLost(item) then
    
      -- Trigger LostContact event. This also adds the contact to the self.ContactsLost table.
      self:LostContact(item)
      
      -- Remove contact from table.
      self:RemoveContact(item)
            
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
  self:I(self.lid..string.format("NEW contact %s", Contact.groupname))
  table.insert(self.ContactsUnknown, Contact) 
end

--- On after "LostContact" event.
-- @param #INTEL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #INTEL.Contact Contact Detected contact.
function INTEL:onafterLostContact(From, Event, To, Contact)
  self:I(self.lid..string.format("LOST contact %s", Contact.groupname))
  table.insert(self.ContactsLost, Contact)
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
  
  
  for _,_contact in pairs(self.Contacts) do
    local contact=_contact --#INTEL.Contact
    
    -- Check if this contact is in any cluster.
    local isincluster=self:CheckContactInClusters(contact)
    
    -- Get the current cluster (if any) this contact belongs to.
    local currentcluster=self:GetClusterOfContact(contact)
    
    if currentcluster then

      ---
      -- Contact is currently part of a cluster.
      ---
    
      -- Check if the contact is still connected to the cluster.
      local isconnected=self:IsContactConnectedToCluster(contact, currentcluster)
      
      if not isconnected then

        local cluster=self:IsContactPartOfAnyClusters(contact)
        
        if cluster then
          self:AddContactToCluster(contact, cluster)
        else
        
          local newcluster=self:CreateCluster(contact.position)
          self:AddContactToCluster(contact, newcluster)
        end
      
      end
      
    
    else
    
      ---
      -- Contact is not in any cluster yet.
      ---
    
      local cluster=self:IsContactPartOfAnyClusters(contact)
      
      if cluster then
        self:AddContactToCluster(contact, cluster)
      else
      
        local newcluster=self:CreateCluster(contact.position)
        self:AddContactToCluster(contact, newcluster)
      end
      
    end
    
  end
  

  
  -- Update F10 marker text if cluster has changed.
  for _,_cluster in pairs(self.Clusters) do
    local cluster=_cluster --#INTEL.Cluster
  
      local coordinate=self:GetClusterCoordinate(cluster)
  
  
      -- Update F10 marker.
      self:UpdateClusterMarker(cluster, coordinate)
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

  return threatlevel
end

--- Calculate cluster threat level average.
-- @param #INTEL self
-- @param #INTEL.Cluster cluster The cluster of contacts.
-- @return #number Average of all threat levels of all groups in the cluster. 
function INTEL:CalcClusterThreatlevelAverage(cluster)

  local threatlevel=self:CalcClusterThreatlevelSum(cluster)  
  threatlevel=threatlevel/cluster.size
  
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
      
      local dist=Contact.position:Get2DDistance(contact.position)
      
      if dist<10*1000 then
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
    y=y+contact.position.z
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
function INTEL:CheckClusterCoordinateChanged(cluster, coordinate)

  coordinate=coordinate or self:GetClusterCoordinate(cluster)
  
  local dist=cluster.coordinate:Get2DDistance(coordinate)
  
  if dist>1000 then
    return true
  else
    return false
  end

end


--- Update cluster F10 marker.
-- @param #INTEL self
-- @param #INTEL.Cluster cluster The cluster.
-- @param Core.Point#COORDINATE newcoordinate Updated cluster positon.
function INTEL:UpdateClusterMarker(cluster, newcoordinate)

  -- Create a marker.
  local text=string.format("Cluster #%d. Size %d, TLsum=%d", cluster.index, cluster.size, cluster.threatlevelSum)

  if not cluster.marker then
    cluster.marker=MARKER:New(cluster.coordinate, text):ToAll()    
  else
  
    local refresh=false
  
    if cluster.marker.text~=text then
      --cluster.marker:UpdateText(text)
      cluster.marker.text=text
      refresh=true
    end
    
    if newcoordinate then
      cluster.coordinate=newcoordinate
      cluster.marker.coordinate=cluster.coordinate
      refresh=true    
    end
    
    if refresh then
      cluster.marker:Refresh()
    end
  
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
