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
-- @field #table filter Category filters.
-- @field #table Contacts Table of detected items.
-- @field #table ContactsLost Table of lost detected items.
-- @field #table ContactsUnknown Table of new detected items.
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
-- @field #string typename Type name of detected item.
-- @field #number category
-- @field #string categoryname
-- @field #string attribute Generalized attribute.
-- @field #number Tdetected Time stamp when this item was last detected.
-- @field #number Tlost Time stamp when this item could not be detected any more.
-- @field #number threatlevel Threat level of this item.
-- @field Core.Point#COORDINATE position Last known position of the item.
-- @field DCS#Vec3 velocity 3D velocity vector. Components x,y and z in m/s.
-- @field #number speed Last known speed.

--- INTEL class version.
-- @field #string version
INTEL.version="0.0.2"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Accept and reject zones.
-- TODO: SetAttributeZone --> return groups of generalized attributes in a zone.

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

  --self.flightgroup=AIGroup
  self.detectionset=DetectionSet
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("INTEL %s | ", "KGB")

  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- INTEL status update
  
  self:AddTransition("*",             "Detect",             "*")           -- INTEL status update
  
  self:AddTransition("*",             "NewContact",         "*")           --
  self:AddTransition("*",             "LostContact",        "*")           --
  

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
  self.acceptzoneset=nil
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
  local text=string.format("Starting INTEL v%s.", self.version)
  self:I(self.sid..text)

  -- Start the status monitoring.
  self:__Status(-1)
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
  
  -- Check if group has detected any units.
  self:UpdateIntel()

  -- Short info.
  local text=string.format("Status=%s", fsmstate)
  self:I(self.lid..text)
  

  self:__Status(-30) 
end


--- Update detected items.
-- @param #INTEL self
function INTEL:UpdateIntel()

  -- Set of all detected units.
  local DetectedSet=SET_UNIT:New()

  -- Loop over all units providing intel.
  for _,_recce in pairs(self.detectionset:GetSet()) do
    local recce=_recce --Wrapper.Unit#UNIT
    
    -- Get set of detected units.
    local detectedunitset=recce:GetDetectedUnitSet()
    
    -- Add detected units to all set.
    DetectedSet=DetectedSet:GetSetUnion(detectedunitset)
    
  end
  
  -- TODO: Filter units from accept/reject zones.
  -- TODO: Filter unit types.
  -- TODO: Filter detection methods?
  
  self:CreateDetectedItems(DetectedSet)
  
  --[[
  
  -- Newly detected units.
  local detectednew=DetectedSet:GetSetComplement(self.detectedunits)
  
  -- Previously detected units which got lost.
  local detectedlost=self.detectedunits:GetSetComplement(DetectedSet)
  
  ]]
  
  -- TODO: Loose units only if they remain undetected for a given time interval. We want to avoid fast oscillation between detected/lost states. Maybe 1-5 min would be a good time interval?!
  -- TODO: Combine units to groups for all, new and lost.
  -- TODO: process detected set asynchroniously for better performance.
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
  
  for _,_group in pairs(detectedgroupset.Set) do
    local group=_group --Wrapper.Group#GROUP
    
    local groupname=group:GetName()
    
    local detecteditem=self:GetContactByName(groupname)
    
    if detecteditem then
      ---
      -- Detected item already exists ==> Update data.
      ---
    
      detecteditem.Tdetected=timer.getAbsTime()
      detecteditem.position=group:GetCoordinate()
    
    else    
      ---
      -- Detected item does not exist in our list yet.
      ---
    
      local item={} --#INTEL.DetectedItem
      
      item.groupname=groupname
      item.Tdetected=timer.getAbsTime()
      item.group=group
      item.position=group:GetCoordinate()
      item.typename=group:GetTypeName()
      item.attribute=group:GetAttribute()
      item.category=group:GetCategory()
      item.categoryname=group:GetCategoryName()
    
      self:AddContact(item)
    end
    
  end
  
  -- Now check if there some groups could not be detected any more.
  for i=#self.Contacts,1,-1 do
    local item=self.Contacts[i] --#INTEL.DetectedItem
    
    local group=detectedgroupset:FindGroup(item.groupname)
    
    if not group then
      --TODO: check if deltaT>Tforget. we dont want quick oszillations between detected and undetected states.
      self:RemoveContact(item)
    end
  end

end

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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------







