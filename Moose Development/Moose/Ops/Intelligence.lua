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
-- @field #number coalition Coalition side number, e.g. coalition.side.RED.
-- @field #table filter Category filters.
-- @field Core.Set#SET_ZONE acceptzoneset Set of accept zones. If defined, only contacts in these zones are considered.
-- @field Core.Set#SET_ZONE rejectzoneset Set of reject zones. Contacts in these zones are not considered.
-- @field #table Contacts Table of detected items.
-- @field #table ContactsLost Table of lost detected items.
-- @field #table ContactsUnknown Table of new detected items.
-- @field #number dTforget Time interval in seconds before a known contact which is not detected any more is forgotten.
-- @extends Core.Fsm#FSM

--- Be surprised!
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
  filter          =   nil,
  detectionset    =   nil,
  Contacts        =    {},
  ContactsLost    =    {},
  ContactsUnknown =    {},
}

--- Detected item info.
-- @type INTEL.DetectedItem
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

--- INTEL class version.
-- @field #string version
INTEL.version="0.0.3"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Accept and reject zones.
-- TODO: SetAttributeZone --> return groups of generalized attributes in a zone.
-- TODO: Loose units only if they remain undetected for a given time interval. We want to avoid fast oscillation between detected/lost states. Maybe 1-5 min would be a good time interval?!
-- TODO: Combine units to groups for all, new and lost.
-- TODO: process detected set asynchroniously for better performance.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new INTEL object and start the FSM.
-- @param #INTEL self
-- @param Core.Set#SET_GROUP DetectionSet Set of detection groups.
-- @return #INTEL self
function INTEL:New(DetectionSet)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #INTEL

  -- Detection set.
  self.detectionset=DetectionSet
  
  -- Determine coalition from first group in set.
  self.coalition=DetectionSet:GetFirst():GetCoalition()
  
  local alias="SPECTRE"
  if self.coalition==coalition.side.RED then
    alias="KGB"
  elseif self.coalition==coalition.side.BLUE then
    alias="CIA"
  end
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("INTEL %s | ", alias)

  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- INTEL status update
  
  self:AddTransition("*",             "Detect",             "*")           -- INTEL status update
  
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

--- Set accept zones.
-- @param #INTEL self
-- @param Core.Set#SET_ZONE AcceptZoneSet Set of accept zones
-- @return #INTEL self
function INTEL:SetAcceptZones(AcceptZoneSet)
  self.acceptzoneset=AcceptZoneSet or SET_ZONE:New()
  return self
end

--- Set accept zones.
-- @param #INTEL self
-- @param Core.Zone#ZONE AcceptZone Add a zone to the accept zone set.
-- @return #INTEL self
function INTEL:AddAcceptZone(AcceptZone)
  self.acceptzoneset:AddZone(AcceptZone)
  return self
end

--- Set forget contacts time interval. Previously known contacts that are not detected any more, are "lost" after this time.
-- This avoids fast oscillations between a contact being detected and undetected.
-- @param #INTEL self
-- @param #number TimeInterval Time interval in seconds. Default is 120 sec.
-- @return #INTEL self
function INTEL:SetForgetTime(TimeInterval)
  self.dTforget=TimeInterval or 120
  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #INTEL self
-- @param Wrapper.Group#GROUP Group Flight group.
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
-- @param Wrapper.Group#GROUP Group Flight group.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function INTEL:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  self.ContactsLost={}
  self.ContactsUnknown={}
  
  -- Check if group has detected any units.
  self:UpdateIntel()
  
  local Ncontacts=#self.Contacts

  -- Short info.
  local text=string.format("Status %s: Agents=%s, Contacts=%d, New=%d, Lost=%d", fsmstate, self.detectionset:CountAlive(), Ncontacts, #self.ContactsUnknown, #self.ContactsLost)
  self:I(self.lid..text)
  
  -- Detailed info.
  if Ncontacts>0 then
    text="Detected Contacts:"
    for _,_contact in pairs(self.Contacts) do
      local contact=_contact --#INTEL.DetectedItem
      local dT=timer.getAbsTime()-contact.Tdetected
      text=text..string.format("\n- %s (%s): %s, units=%d, T=%d sec", contact.categoryname, contact.attribute, contact.groupname, contact.group:CountAliveUnits(), dT)
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
  
  -- TODO: Filter units from accept/reject zones.
  -- TODO: Filter unit types.
  -- TODO: Filter detection methods?
  
  for _,_zone in pairs(self.acceptzoneset.Set) do
    local zone=_zone --Core.Zone#ZONE
    
  end
  
  -- Create detected contacts.  
  self:CreateDetectedItems(DetectedSet)
  
end

--- Create detected items.
-- @param #INTEL self
-- @param Core.Set#SET_UNIT detectedunitset Set of detected units. 
function INTEL:CreateDetectedItems(detectedunitset)

  local detectedgroupset=SET_GROUP:New()

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
      local item={} --#INTEL.DetectedItem
      
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
    local item=self.Contacts[i] --#INTEL.DetectedItem
    
    local group=detectedgroupset:FindGroup(item.groupname)
    
    -- Check if deltaT>Tforget. We dont want quick oszillations between detected and undetected states.
    if self:CheckContactLost(item) then
      -- Trigger LostContact event.
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
-- @param #INTEL.DetectedItem Contact Detected contact.
function INTEL:onafterNewContact(From, Event, To, Contact)
  self:I(self.lid..string.format("NEW contact %s", Contact.groupname))
  table.insert(self.ContactsUnknown, Contact)
end

--- On after "LostContact" event.
-- @param #INTEL self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #INTEL.DetectedItem Contact Detected contact.
function INTEL:onafterLostContact(From, Event, To, Contact)
  self:I(self.lid..string.format("LOST contact %s", Contact.groupname))
  table.insert(self.ContactsLost, Contact)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Fuctions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create detected items.
-- @param #INTEL self
-- @param #string groupname Name of the contact group.
-- @return #INTEL.DetectedItem 
function INTEL:GetContactByName(groupname)

  for i,_contact in pairs(self.Contacts) do
    local contact=_contact --#INTEL.DetectedItem
    if contact.groupname==groupname then
      return contact
    end
  end

  return nil
end

--- Remove a contact from our list.
-- @param #INTEL self
-- @param #INTEL.DetectedItem Contact The contact to be removed.
function INTEL:RemoveContact(Contact)

  for i,_contact in pairs(self.Contacts) do
    local contact=_contact --#INTEL.DetectedItem
    
    if contact.groupname==Contact.groupname then
      table.remove(self.Contacts, i)
    end
  
  end

end

--- Remove a contact from our list.
-- @param #INTEL self
-- @param #INTEL.DetectedItem Contact The contact to be removed.
function INTEL:AddContact(Contact)
  table.insert(self.Contacts, Contact)
end

--- Remove a contact from our list.
-- @param #INTEL self
-- @param #INTEL.DetectedItem Contact The contact to be removed.
-- @return #boolean If true, contact was not detected for at least *dTforget* seconds.
function INTEL:CheckContactLost(Contact)

  -- Time since last detected.
  local dT=timer.getAbsTime()-Contact.Tdetected
  
  
  if dT>self.dTforget then
    return true
  else
    return false
  end
  
end