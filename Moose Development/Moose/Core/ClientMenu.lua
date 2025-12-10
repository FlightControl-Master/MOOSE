--- **Core** - Client Menu Management.
--
-- **Main Features:**
--
--    * For complex, non-static menu structures
--    * Lightweigt implementation as alternative to MENU
--    * Separation of menu tree creation from menu on the clients's side
--    * Works with a SET_CLIENT set of clients
--    * Allow manipulation of the shadow tree in various ways
--    * Push to all or only one client
--    * Change entries' menu text
--    * Option to make an entry usable once only across all clients
--    * Auto appends GROUP and CLIENT objects to menu calls
--
-- ===
--
-- ### Author: **applevangelist**
-- 
-- ===
-- 
-- @module Core.ClientMenu
-- @image Core_Menu.JPG
-- last change: Sept 2025

-- TODO
----------------------------------------------------------------------------------------------------------------
--
-- CLIENTMENU
--
----------------------------------------------------------------------------------------------------------------

---
-- @type CLIENTMENU
-- @field #string ClassName Class Name
-- @field #string lid Lid for log entries
-- @field #string version Version string
-- @field #string name Name
-- @field #string groupname Group name
-- @field #table path
-- @field #table parentpath
-- @field #CLIENTMENU Parent
-- @field Wrapper.Client#CLIENT client
-- @field #number GroupID Group ID
-- @field #number ID Entry ID
-- @field Wrapper.Group#GROUP group
-- @field #string UUID Unique ID based on path+name
-- @field #string Function
-- @field #table Functionargs
-- @field #table Children
-- @field #boolean Once
-- @field #boolean Generic
-- @field #boolean debug
-- @field #CLIENTMENUMANAGER Controller
-- @field #active boolean
-- @extends Core.Base#BASE

---
-- @field #CLIENTMENU
CLIENTMENU = {
  ClassName = "CLIENTMENU",
  lid = "",
  version = "0.1.3",
  name = nil,
  path = nil,
  group = nil,
  client = nil,
  GroupID = nil,
  Children = {},
  Once = false,
  Generic = false,
  debug = false,
  Controller = nil,
  groupname = nil,
  active = false,
}

---
-- @field #CLIENTMENU_ID
CLIENTMENU_ID = 0

--- Create an new CLIENTMENU object.
-- @param #CLIENTMENU self
-- @param Wrapper.Client#CLIENT Client The client for whom this entry is. Leave as nil for a generic entry.
-- @param #string Text Text of the F10 menu entry.
-- @param #CLIENTMENU Parent The parent menu entry.
-- @param #string Function (optional) Function to call when the entry is used.
-- @param ... (optional) Arguments for the Function, comma separated
-- @return #CLIENTMENU self 
function CLIENTMENU:NewEntry(Client,Text,Parent,Function,...)
  -- Inherit everything from BASE class.
  local self=BASE:Inherit(self, BASE:New()) -- #CLIENTMENU
  CLIENTMENU_ID = CLIENTMENU_ID + 1
  self.ID = CLIENTMENU_ID
  if Client then
    self.group = Client:GetGroup()
    self.client = Client
    self.GroupID = self.group:GetID()
    self.groupname = self.group:GetName() or "Unknown Groupname"
  else
    self.Generic = true
  end
  self.name = Text or "unknown entry"
  if Parent then
    if Parent:IsInstanceOf("MENU_BASE") then
      self.parentpath = Parent.MenuPath
    else
      self.parentpath = Parent:GetPath()
      Parent:AddChild(self)
    end
  end
  self.Parent = Parent
  self.Function = Function
  self.Functionargs = arg or {}
  table.insert(self.Functionargs,self.group)
  table.insert(self.Functionargs,self.client)
  if self.Functionargs and self.debug then
    self:T({"Functionargs",self.Functionargs})
  end
  if not self.Generic and self.active == false then
    if Function ~= nil then
      local ErrorHandler = function( errmsg )
        env.info( "MOOSE Error in CLIENTMENU COMMAND function: " .. errmsg )
        if BASE.Debug ~= nil then
          env.info( BASE.Debug.traceback() )
        end
        return errmsg
      end
      self.CallHandler = function()
      local function MenuFunction() 
        return self.Function( unpack( self.Functionargs ) )
      end
        local Status, Result = xpcall( MenuFunction, ErrorHandler)
        if self.Once == true then
          self:Clear()
        end
      end
      self.path = missionCommands.addCommandForGroup(self.GroupID,Text,self.parentpath, self.CallHandler)
      self.active = true
    else
      self.path = missionCommands.addSubMenuForGroup(self.GroupID,Text,self.parentpath)
      self.active = true
    end
  else
    if self.parentpath then
      self.path = UTILS.DeepCopy(self.parentpath)
    else
      self.path = {}
    end
    self.path[#self.path+1] = Text
  end
  self.UUID = table.concat(self.path,";")
  self:T({self.UUID})
  self.Once = false
  -- Log id.
  self.lid=string.format("CLIENTMENU %s | %s | ", self.ID, self.name)
  self:T(self.lid.."Created")
  return self
end

--- Create a UUID
-- @param #CLIENTMENU self
-- @param #CLIENTMENU Parent The parent object if any
-- @param #string Text The menu entry text
-- @return #string UUID
function CLIENTMENU:CreateUUID(Parent,Text)
  local path = {}
  if Parent and Parent.path then
    path = Parent.path
  end
  path[#path+1] = Text
  local UUID = table.concat(path,";")
  return UUID
end

--- Set the CLIENTMENUMANAGER for this entry.
-- @param #CLIENTMENU self
-- @param #CLIENTMENUMANAGER Controller The controlling object.
-- @return #CLIENTMENU self 
function CLIENTMENU:SetController(Controller)
  self.Controller = Controller
  return self
end

--- The entry will be deleted after being used used - for menu entries with functions only.
-- @param #CLIENTMENU self
-- @return #CLIENTMENU self 
function CLIENTMENU:SetOnce()
  self:T(self.lid.."SetOnce")
  self.Once = true
  return self
end

--- Remove the entry from the F10 menu.
-- @param #CLIENTMENU self
-- @return #CLIENTMENU self 
function CLIENTMENU:RemoveF10()
  self:T(self.lid.."RemoveF10")
  if self.GroupID then
    --self:I(self.lid.."Removing "..table.concat(self.path,";"))
    local function RemoveFunction()
      return missionCommands.removeItemForGroup(self.GroupID , self.path )
    end
    local status, err = pcall(RemoveFunction)
    if not status then
      self:I(string.format("**** Error Removing Menu Entry %s for %s!",tostring(self.name),self.groupname))
    end
    self.active = false
  end
  return self
end

--- Get the menu path table.
-- @param #CLIENTMENU self
-- @return #table Path
function CLIENTMENU:GetPath()
  self:T(self.lid.."GetPath")
  return self.path 
end

--- Get the UUID.
-- @param #CLIENTMENU self
-- @return #string UUID
function CLIENTMENU:GetUUID()
  self:T(self.lid.."GetUUID")
  return self.UUID
end

--- Link a child entry.
-- @param #CLIENTMENU self
-- @param #CLIENTMENU Child The entry to link as a child.
-- @return #CLIENTMENU self
function CLIENTMENU:AddChild(Child)
  self:T(self.lid.."AddChild "..Child.ID)
  table.insert(self.Children,Child.ID,Child)
  return self
end

--- Remove a child entry.
-- @param #CLIENTMENU self
-- @param #CLIENTMENU Child The entry to remove from the children.
-- @return #CLIENTMENU self
function CLIENTMENU:RemoveChild(Child)
  self:T(self.lid.."RemoveChild "..Child.ID)
  table.remove(self.Children,Child.ID)
  return self
end

--- Remove all subentries (children) from this entry.
-- @param #CLIENTMENU self
-- @return #CLIENTMENU self
function CLIENTMENU:RemoveSubEntries()
  self:T(self.lid.."RemoveSubEntries")
  self:T({self.Children})
  for _id,_entry in pairs(self.Children) do
    self:T("Removing ".._id)
    if _entry then
      _entry:RemoveSubEntries()
      _entry:RemoveF10()
      if _entry.Parent then
        _entry.Parent:RemoveChild(self)
      end
      --if self.Controller then
        --self.Controller:_RemoveByID(_entry.ID)
      --end
      --_entry = nil
    end
  end
  return self
end

--- Remove this entry and all subentries (children) from this entry.
-- @param #CLIENTMENU self
-- @return #CLIENTMENU self
function CLIENTMENU:Clear()
  self:T(self.lid.."Clear")
  for _id,_entry in pairs(self.Children) do
    if _entry then
      _entry:RemoveSubEntries()
      _entry = nil
    end
  end
  self:RemoveF10()
  if self.Parent then
    self.Parent:RemoveChild(self)
  end
  --if self.Controller then
    --self.Controller:_RemoveByID(self.ID)
  --end
  return self
end

-- TODO
----------------------------------------------------------------------------------------------------------------
--
-- CLIENTMENUMANAGER
--
----------------------------------------------------------------------------------------------------------------


--- Class CLIENTMENUMANAGER              
-- @type CLIENTMENUMANAGER
-- @field #string ClassName Class Name
-- @field #string lid Lid for log entries
-- @field #string version Version string
-- @field #string name Name
-- @field Core.Set#SET_CLIENT clientset The set of clients this menu manager is for
-- @field #table flattree
-- @field #table rootentries
-- @field #table menutree
-- @field #number entrycount
-- @field #boolean debug
-- @field #table PlayerMenu
-- @field #number Coalition
-- @extends Core.Base#BASE

--- *As a child my family's menu consisted of two choices: take it, or leave it.*
--
-- ===
--
-- ## CLIENTMENU and CLIENTMENUMANAGER
-- 
-- Manage menu structures for a SET_CLIENT of clients.
-- 
-- ## Concept
-- 
-- Separate creation of a menu tree structure from pushing it to each client. Create a shadow "reference" menu structure tree for your client pilot's in a mission. 
-- This can then be propagated to all clients. Manipulate the entries in the structure with removing, clearing or changing single entries, create replacement sub-structures 
-- for entries etc, push to one or all clients.
-- 
-- Many functions can either change the tree for one client or for all clients.
-- 
-- ## Conceptual remarks
-- 
-- There's a couple of things to fully understand: 
-- 
-- 1) **CLIENTMENUMANAGER** manages a set of entries from **CLIENTMENU**, it's main purpose is to administer the *shadow menu tree*, ie. a menu structure which is not 
-- (yet) visible to any client   
-- 2) The entries are **CLIENTMENU** objects, which are linked in a tree form. There's two ways to create them:   
--          A) in the manager with ":NewEntry()" which initially 
--              adds it to the shadow menu **only**   
--          B) stand-alone directly as `CLIENTMENU:NewEntry()` - here it depends on whether or not you gave a CLIENT object if the entry is created as generic entry or pushed 
--              a **specific** client. **Be aware** though that the entries are not managed by the CLIENTMANAGER before the next step!   
-- A generic entry can be added to the manager (and the shadow tree) with `:AddEntry()` - this will also push it to all clients(!) if no client is given, or a specific client only.  
-- 3) Pushing only works for alive clients.   
-- 4) Live and shadow tree entries are managed via the CLIENTMENUMANAGER object.   
-- 5) `Propagate()`refreshes the menu tree for all, or a single client.   
-- 
-- ## Create a base reference tree and send to all clients
-- 
--            local clientset = SET_CLIENT:New():FilterStart()
--            
--            local menumgr = CLIENTMENUMANAGER:New(clientset,"Dayshift")
--            local mymenu = menumgr:NewEntry("Top")
--            local mymenu_lv1a = menumgr:NewEntry("Level 1 a",mymenu)
--            local mymenu_lv1b = menumgr:NewEntry("Level 1 b",mymenu)
--            -- next one is a command menu entry, which can only be used once
--            local mymenu_lv1c = menumgr:NewEntry("Action Level 1 c",mymenu, testfunction, "testtext"):SetOnce()
--            
--            local mymenu_lv2a = menumgr:NewEntry("Go here",mymenu_lv1a)
--            local mymenu_lv2b = menumgr:NewEntry("Level 2 ab",mymenu_lv1a)
--            local mymenu_lv2c = menumgr:NewEntry("Level 2 ac",mymenu_lv1a)
--            
--            local mymenu_lv2ba = menumgr:NewEntry("Level 2 ba",mymenu_lv1b)
--            local mymenu_lv2bb = menumgr:NewEntry("Level 2 bb",mymenu_lv1b)
--            local mymenu_lv2bc = menumgr:NewEntry("Level 2 bc",mymenu_lv1b)
--            
--            local mymenu_lv3a = menumgr:NewEntry("Level 3 aaa",mymenu_lv2a)
--            local mymenu_lv3b = menumgr:NewEntry("Level 3 aab",mymenu_lv2a)
--            local mymenu_lv3c = menumgr:NewEntry("Level 3 aac",mymenu_lv2a)
--            
--            menumgr:Propagate() -- propagate **once** to all clients in the SET_CLIENT
--            
-- ## Remove a single entry's subtree
-- 
--            menumgr:RemoveSubEntries(mymenu_lv3a)
--            
 -- ## Remove a single entry and also it's subtree
-- 
--            menumgr:DeleteEntry(mymenu_lv3a)
-- 
-- ## Add a single entry
-- 
--            local baimenu = menumgr:NewEntry("BAI",mymenu_lv1b)
--            
--            menumgr:AddEntry(baimenu)  
--            
-- ## Add an entry with a function 
-- 
--            local baimenu = menumgr:NewEntry("Task Action", mymenu_lv1b, TestFunction, Argument1, Argument1)
--            
--  Now, the class will **automatically append the call with GROUP and CLIENT objects**, as this is can only be done when pushing the entry to the clients. So, the actual function implementation needs to look like this:
--  
--            function TestFunction( Argument1, Argument2, Group, Client)
--            
--  **Caveat is**, that you need to ensure your arguments are not **nil** or **false**, as LUA will optimize those away. You would end up having Group and Client in wrong places in the function call. Hence,
--  if you need/ want to send **nil** or **false**, send a place holder instead and ensure your function can handle this, e.g.
--  
--            local baimenu = menumgr:NewEntry("Task Action", mymenu_lv1b, TestFunction, "nil", Argument1)
--     
-- ## Change the text of a leaf entry in the menu tree          
--            
--            menumgr:ChangeEntryTextForAll(mymenu_lv1b,"Attack")
--            
-- ## Reset a single clients menu tree
-- 
--            menumgr:ResetMenu(client)
--            
-- ## Reset all and clear the reference tree
-- 
--            menumgr:ResetMenuComplete()
--            
-- ## Set to auto-propagate for CLIENTs joining the SET_CLIENT **after** the script is loaded - handy if you have a single menu tree.
-- 
--            menumgr:InitAutoPropagation()
--
-- @field #CLIENTMENUMANAGER
CLIENTMENUMANAGER = {
  ClassName = "CLIENTMENUMANAGER",
  lid = "",
  version = "0.1.7",
  name = nil,
  clientset = nil,
  menutree = {},
  flattree = {},
  playertree = {},
  entrycount = 0,
  rootentries = {},
  debug = true,
  PlayerMenu = {},
  Coalition = nil,
}

--- Create a new ClientManager instance.
-- @param #CLIENTMENUMANAGER self
-- @param Core.Set#SET_CLIENT ClientSet The set of clients to manage.
-- @param #string Alias The name of this manager.
-- @param #number Coalition (Optional) Coalition of this Manager, defaults to coalition.side.BLUE
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:New(ClientSet, Alias, Coalition)
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, BASE:New()) -- #CLIENTMENUMANAGER
  self.clientset = ClientSet
  self.PlayerMenu = {}
  self.name = Alias or "Nightshift"
  self.Coalition = Coalition or coalition.side.BLUE
    -- Log id.
  self.lid=string.format("CLIENTMENUMANAGER %s | %s | ", self.version, self.name)
  if self.debug then
    self:I(self.lid.."Created")
  end
  return self
end

--- [Internal] Event handling
-- @param #CLIENTMENUMANAGER self
-- @param Core.Event#EVENTDATA EventData
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:_EventHandler(EventData,Retry)
  self:T(self.lid.."_EventHandler: "..EventData.id)
  --self:I(self.lid.."_EventHandler: "..tostring(EventData.IniPlayerName))
  if EventData.id == EVENTS.PlayerLeaveUnit or EventData.id == EVENTS.Ejection or EventData.id == EVENTS.Crash or EventData.id == EVENTS.PilotDead then
    self:T(self.lid.."Leave event for player: "..tostring(EventData.IniPlayerName)) 
    local Client = _DATABASE:FindClient( EventData.IniUnitName )
    if Client then
      self:ResetMenu(Client)
    end
  elseif (EventData.id == EVENTS.PlayerEnterAircraft) and EventData.IniCoalition == self.Coalition then
    if EventData.IniPlayerName and EventData.IniGroup then
      if (not self.clientset:IsIncludeObject(_DATABASE:FindClient( EventData.IniUnitName ))) then
        self:T(self.lid.."Client not in SET: "..EventData.IniPlayerName)
        if not Retry then
          -- try again in 2 secs
          self:ScheduleOnce(2,CLIENTMENUMANAGER._EventHandler,self,EventData,true)
        end
        return self
      end
      --self:I(self.lid.."Join event for player: "..EventData.IniPlayerName)
      local player = _DATABASE:FindClient( EventData.IniUnitName )
      self:Propagate(player)
    end
  elseif EventData.id == EVENTS.PlayerEnterUnit then
    -- special for CA slots
    local grp = GROUP:FindByName(EventData.IniGroupName)
    if grp:IsGround() then
      self:T(string.format("Player %s entered GROUND unit %s!",EventData.IniPlayerName,EventData.IniUnitName))
      local IsPlayer = EventData.IniDCSUnit:getPlayerName()
      if IsPlayer then
        
        local client=_DATABASE.CLIENTS[EventData.IniDCSUnitName] --Wrapper.Client#CLIENT
        
        -- Add client in case it does not exist already.
        if not client then
          
          -- Debug info.
          self:I(string.format("Player '%s' joined ground unit '%s' of group '%s'", tostring(EventData.IniPlayerName), tostring(EventData.IniDCSUnitName), tostring(EventData.IniDCSGroupName)))
        
          client=_DATABASE:AddClient(EventData.IniDCSUnitName)
            
          -- Add player.
          client:AddPlayer(EventData.IniPlayerName)
          
          -- Add player.
          if not _DATABASE.PLAYERS[EventData.IniPlayerName] then
            _DATABASE:AddPlayer( EventData.IniUnitName, EventData.IniPlayerName )
          end
          
          -- Player settings.
          local Settings = SETTINGS:Set( EventData.IniPlayerName )
          Settings:SetPlayerMenu(EventData.IniUnit)
        end
        --local player = _DATABASE:FindClient( EventData.IniPlayerName )
        self:Propagate(client)
      end
    end
  end
  
  return self
end

--- Set this Client Manager to auto-propagate menus **once** to newly joined players. Useful if you have **one** menu structure only. Does not automatically push follow-up changes to the client(s).
-- @param #CLIENTMENUMANAGER self
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:InitAutoPropagation()
  -- Player Events
  self:HandleEvent(EVENTS.PlayerLeaveUnit, self._EventHandler)
  self:HandleEvent(EVENTS.Ejection, self._EventHandler)
  self:HandleEvent(EVENTS.Crash, self._EventHandler)
  self:HandleEvent(EVENTS.PilotDead, self._EventHandler)
  self:HandleEvent(EVENTS.PlayerEnterAircraft, self._EventHandler)
  self:HandleEvent(EVENTS.PlayerEnterUnit, self._EventHandler)
  self:SetEventPriority(6) 
  return self 
end

--- Create a new entry in the **generic** structure.
-- @param #CLIENTMENUMANAGER self
-- @param #string Text Text of the F10 menu entry.
-- @param #CLIENTMENU Parent The parent menu entry.
-- @param #string Function (optional) Function to call when the entry is used.
-- @param ... (optional) Arguments for the Function, comma separated.
-- @return #CLIENTMENU Entry
function CLIENTMENUMANAGER:NewEntry(Text,Parent,Function,...)
  self:T(self.lid.."NewEntry "..Text or "None")
  self.entrycount = self.entrycount + 1
  local entry = CLIENTMENU:NewEntry(nil,Text,Parent,Function,unpack(arg))
  if not Parent then
    self.rootentries[self.entrycount] = entry
  end
  local depth = #entry.path
  if not self.menutree[depth] then self.menutree[depth] = {} end
  table.insert(self.menutree[depth],entry.UUID)
  self.flattree[entry.UUID] = entry
  return entry
end

--- Check matching entry in the generic structure by UUID.
-- @param #CLIENTMENUMANAGER self
-- @param #string UUID UUID of the menu entry.
-- @return #boolean Exists
function CLIENTMENUMANAGER:EntryUUIDExists(UUID)
  local exists = self.flattree[UUID] and true or false
  return exists
end

--- Find matching entry in the generic structure by UUID.
-- @param #CLIENTMENUMANAGER self
-- @param #string UUID UUID of the menu entry.
-- @return #CLIENTMENU Entry The #CLIENTMENU object found or nil.
function CLIENTMENUMANAGER:FindEntryByUUID(UUID)
  self:T(self.lid.."FindEntryByUUID "..UUID or "None")
  local entry = nil
  for _gid,_entry in pairs(self.flattree) do
    local Entry = _entry -- #CLIENTMENU
    if Entry and Entry.UUID == UUID then
      entry = Entry
    end
  end
  return entry
end

--- Find matching entries by text in the generic structure by UUID.
-- @param #CLIENTMENUMANAGER self
-- @param #string Text Text or partial text of the menu entry to find.
-- @param #CLIENTMENU Parent (Optional) Only find entries under this parent entry.
-- @return #table Table of matching UUIDs of #CLIENTMENU objects
-- @return #table Table of matching #CLIENTMENU objects
-- @return #number Number of matches
function CLIENTMENUMANAGER:FindUUIDsByText(Text,Parent)
  self:T(self.lid.."FindUUIDsByText "..Text or "None")
  local matches = {}
  local entries = {}
  local n = 0
  for _uuid,_entry in pairs(self.flattree) do
    local Entry = _entry -- #CLIENTMENU
    if Parent then
      if Entry and string.find(Entry.name,Text,1,true) and string.find(Entry.UUID,Parent.UUID,1,true) then
        table.insert(matches,_uuid)
        table.insert(entries,Entry )
        n=n+1
      end
    else
      if Entry and string.find(Entry.name,Text,1,true) then
        table.insert(matches,_uuid)
        table.insert(entries,Entry )
        n=n+1
      end
    end
  end
  return matches, entries, n
end

--- Find matching entries in the generic structure by the menu text.
-- @param #CLIENTMENUMANAGER self
-- @param #string Text Text or partial text of the F10 menu entry.
-- @param #CLIENTMENU Parent (Optional) Only find entries under this parent entry.
-- @return #table Table of matching #CLIENTMENU objects.
-- @return #number Number of matches
function CLIENTMENUMANAGER:FindEntriesByText(Text,Parent)
  self:T(self.lid.."FindEntriesByText "..Text or "None")
  local matches, objects, number = self:FindUUIDsByText(Text, Parent)
  return objects, number
end

--- Find matching entries under a parent in the generic structure by UUID.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Parent Find entries under this parent entry.
-- @return #table Table of matching UUIDs of #CLIENTMENU objects
-- @return #table Table of matching #CLIENTMENU objects
-- @return #number Number of matches
function CLIENTMENUMANAGER:FindUUIDsByParent(Parent)
  self:T(self.lid.."FindUUIDsByParent")
  local matches = {}
  local entries = {}
  local n = 0
  for _uuid,_entry in pairs(self.flattree) do
    local Entry = _entry -- #CLIENTMENU
    if Parent then
      if Entry and string.find(Entry.UUID,Parent.UUID,1,true) then
        table.insert(matches,_uuid)
        table.insert(entries,Entry )
        n=n+1
      end
    end
  end
  return matches, entries, n
end

--- Find matching entries in the generic structure under a parent.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Parent Find entries under this parent entry.
-- @return #table Table of matching #CLIENTMENU objects.
-- @return #number Number of matches
function CLIENTMENUMANAGER:FindEntriesByParent(Parent)
  self:T(self.lid.."FindEntriesByParent")
  local matches, objects, number = self:FindUUIDsByParent(Parent)
  return objects, number
end

--- Alter the text of a leaf entry in the generic structure and push to one specific client's F10 menu.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Entry The menu entry.
-- @param #string Text New Text of the F10 menu entry.
-- @param Wrapper.Client#CLIENT Client (optional) The client for whom to alter the entry, if nil done for all clients.
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:ChangeEntryText(Entry, Text, Client)
  self:T(self.lid.."ChangeEntryText "..Text or "None")
  local newentry = CLIENTMENU:NewEntry(nil,Text,Entry.Parent,Entry.Function,unpack(Entry.Functionargs))
  self:DeleteF10Entry(Entry,Client)
  self:DeleteGenericEntry(Entry)
  if not Entry.Parent then
    self.rootentries[self.entrycount] = newentry
  end
  local depth = #newentry.path
  if not self.menutree[depth] then self.menutree[depth] = {} end
  table.insert(self.menutree[depth],newentry.UUID)
  self.flattree[newentry.UUID] = newentry
  self:AddEntry(newentry,Client)
  return self
end

--- Push the complete menu structure to each of the clients in the set - refresh the menu tree of the clients.
-- @param #CLIENTMENUMANAGER self
-- @param Wrapper.Client#CLIENT Client (optional) If given, propagate only for this client.
-- @return #CLIENTMENU Entry
function CLIENTMENUMANAGER:Propagate(Client)
  self:T(self.lid.."Propagate")
  --self:I(UTILS.PrintTableToLog(Client,1))
  local knownunits = {} -- track so we can ID multi seated
  local Set = self.clientset.Set
  if Client then
    Set = {Client}
  end
  self:ResetMenu(Client)
  for _,_client in pairs(Set) do
    local client = _client -- Wrapper.Client#CLIENT
    if client and client:IsAlive() then
      local playerunit = client:GetName()
      --local playergroup = client:GetGroup()
      local playername = client:GetPlayerName() or "none"
      if not knownunits[playerunit] then
        knownunits[playerunit] = true
      else
        self:I("Player in multi seat unit: "..playername)
        break -- multi seat already build
      end
      if not self.playertree[playername] then
        self.playertree[playername] = {}
      end
      for level,branch in pairs (self.menutree) do
        self:T("Building branch:" .. level)
        for _,leaf in pairs(branch) do
          self:T("Building leaf:" .. leaf)
          local entry = self:FindEntryByUUID(leaf)
          if entry then
            self:T("Found generic entry:" .. entry.UUID)
            local parent = nil
            if entry.Parent and entry.Parent.UUID then
              parent = self.playertree[playername][entry.Parent.UUID] or self:FindEntryByUUID(entry.Parent.UUID)
            end
            self.playertree[playername][entry.UUID] = CLIENTMENU:NewEntry(client,entry.name,parent,entry.Function,unpack(entry.Functionargs))
            self.playertree[playername][entry.UUID].Once = entry.Once
          else
            self:T("NO generic entry for:" .. leaf)
          end  
        end
      end
    end
  end
  return self
end

--- Push a single previously created entry into the F10 menu structure of all clients.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Entry The entry to add.
-- @param Wrapper.Client#CLIENT Client (optional) If given, make this change only for this client. 
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:AddEntry(Entry,Client)
  self:T(self.lid.."AddEntry")
  local Set = self.clientset.Set
  local knownunits = {}
  if Client then
    Set = {Client}
  end
  for _,_client in pairs(Set) do
    local client = _client -- Wrapper.Client#CLIENT
    if client and client:IsAlive() then
      local playername = client:GetPlayerName() or "None"
      local unitname = client:GetName()
      if not knownunits[unitname] then
        knownunits[unitname] = true
      else
        self:I("Player in multi seat unit: "..playername)  
        break
      end
      if Entry then
        self:T("Adding generic entry:" .. Entry.UUID)
        local parent = nil
        if not self.playertree[playername] then
          self.playertree[playername] = {}
        end
        if Entry.Parent and Entry.Parent.UUID then
          parent = self.playertree[playername][Entry.Parent.UUID] or self:FindEntryByUUID(Entry.Parent.UUID)
        end
        self.playertree[playername][Entry.UUID] = CLIENTMENU:NewEntry(client,Entry.name,parent,Entry.Function,unpack(Entry.Functionargs))
        self.playertree[playername][Entry.UUID].Once = Entry.Once
      else
        self:T("NO generic entry given")
      end 
    end
  end
  return self
end

--- Blank out the menu - remove **all root entries** and all entries below from the client's F10 menus, leaving the generic structure untouched.
-- @param #CLIENTMENUMANAGER self
-- @param Wrapper.Client#CLIENT Client (optional) If given, remove only for this client.
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:ResetMenu(Client)
  self:T(self.lid.."ResetMenu")
  for _,_entry in pairs(self.rootentries) do
    --local RootEntry = self.structure.generic[_entry]
    if _entry then
      self:DeleteF10Entry(_entry,Client)
    end
  end
  return self
end

--- Blank out the menu - remove **all root entries** and all entries below from all clients' F10 menus, and **delete** the generic structure.
-- @param #CLIENTMENUMANAGER self
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:ResetMenuComplete()
  self:T(self.lid.."ResetMenuComplete")
  for _,_entry in pairs(self.rootentries) do
    --local RootEntry = self.structure.generic[_entry]
    if _entry then
      self:DeleteF10Entry(_entry)
    end
  end
  self.playertree = nil
  self.playertree = {}
  self.rootentries = nil
  self.rootentries = {}
  self.menutree = nil
  self.menutree = {}
  return self
end

--- Remove the entry and all entries below the given entry from the client's F10 menus.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Entry The entry to remove
-- @param Wrapper.Client#CLIENT Client (optional) If given, make this change only for this client. 
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:DeleteEntry(Entry,Client)
  self:T(self.lid.."DeleteEntry")
  return self:DeleteF10Entry(Entry,Client)
end

--- Remove the entry and all entries below the given entry from the client's F10 menus.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Entry The entry to remove
-- @param Wrapper.Client#CLIENT Client (optional) If given, make this change only for this client. 
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:DeleteF10Entry(Entry,Client)
  self:T(self.lid.."DeleteF10Entry")
  local Set = self.clientset.Set
  if Client then
    Set = {Client}
  end
  for _,_client in pairs(Set) do
    if _client and _client:IsAlive() then
      local playername = _client:GetPlayerName()
      if self.playertree[playername] then
        local centry = self.playertree[playername][Entry.UUID] -- #CLIENTMENU
        if centry then
          --self:I("Match for "..Entry.UUID)
          centry:Clear()
        end
      end
    end
  end
  return self
end

--- Remove the entry and all entries below the given entry from the generic tree.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Entry The entry to remove
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:DeleteGenericEntry(Entry)
  self:T(self.lid.."DeleteGenericEntry")
  
  if Entry.Children and #Entry.Children > 0 then
    self:RemoveGenericSubEntries(Entry)
  end
  
  local depth = #Entry.path
  local uuid = Entry.UUID
  
  local tbl = UTILS.DeepCopy(self.menutree)
  
  if tbl[depth] then
    for i=depth,#tbl do
      --self:I("Level = "..i)
      for _id,_uuid in pairs(tbl[i]) do
        self:T(_uuid)
        if string.find(_uuid,uuid,1,true) or _uuid == uuid then
          --self:I("Match for ".._uuid)
          self.menutree[i][_id] = nil
          self.flattree[_uuid] = nil
        end  
      end 
    end
  end
  
  return self
end

--- Remove all entries below the given entry from the generic tree.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Entry The entry where to start. This entry stays.
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:RemoveGenericSubEntries(Entry)
  self:T(self.lid.."RemoveGenericSubEntries")
  
  local depth = #Entry.path + 1
  local uuid = Entry.UUID
  
  local tbl = UTILS.DeepCopy(self.menutree)
  
  if tbl[depth] then
    for i=depth,#tbl do
      self:T("Level = "..i)
      for _id,_uuid in pairs(tbl[i]) do
        self:T(_uuid)
        if string.find(_uuid,uuid,1,true) then
          self:T("Match for ".._uuid)
          self.menutree[i][_id] = nil
          self.flattree[_uuid] = nil
        end  
      end 
    end
  end  
  return self
end


--- Remove all entries below the given entry from the client's F10 menus.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Entry The entry where to start. This entry stays.
-- @param Wrapper.Client#CLIENT Client (optional) If given, make this change only for this client. In this case the generic structure will not be touched.
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:RemoveF10SubEntries(Entry,Client)
  self:T(self.lid.."RemoveSubEntries")
  local Set = self.clientset.Set
  if Client then
    Set = {Client}
  end
  for _,_client in pairs(Set) do
    if _client and _client:IsAlive() then
      local playername = _client:GetPlayerName()
      if self.playertree[playername] then
        local centry = self.playertree[playername][Entry.UUID] -- #CLIENTMENU
        centry:RemoveSubEntries()
      end
    end
  end
  return self
end

----------------------------------------------------------------------------------------------------------------
--
-- End ClientMenu
--
----------------------------------------------------------------------------------------------------------------
