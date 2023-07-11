--- **Core** - Client Menu Management.
--
-- **Main Features:**
--
--    * For complex, non-static menu structures
--    * Separation of menu tree creation from pushing it to clients
--    * Works with a SET_CLIENT set of clients
--    * Allow manipulation of the shadow tree in various ways
--    * Push to all or only one client
--    * Change entries' menu text, even if they have a sub-structure
--    * Option to make an entry usable once
--
-- ===
--
-- ### Author: **applevangelist**
-- 
-- ===
-- 
-- @module Core.ClientMenu
-- @image Core_Menu.JPG
-- last change: July 2023

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
-- @field #table path
-- @field #table parentpath
-- @field #CLIENTMENU Parent
-- @field Wrapper.Client#CLIENT client
-- @field #number GID
-- @field #number ID
-- @field Wrapper.Group#GROUP group
-- @field #string Function
-- @field #table Functionargs
-- @field #table Children
-- @field #boolean Once
-- @field #boolean Generic
-- @field #boolean debug
-- @field #CLIENTMENUMANAGER Controller
-- @extends Core.Base#BASE

---
-- @field #CLIENTMENU
CLIENTMENU = {
  ClassName = "CLIENTMENUE",
  lid = "",
  version = "0.0.1",
  name = nil,
  path = nil,
  group = nil,
  client = nil,
  GID = nil,
  Children = {},
  Once = false,
  Generic = false,
  debug = false,
  Controller = nil,
}

---
-- @field #CLIENTMENU_ID
CLIENTMENU_ID = 0

--- Create an new CLIENTMENU object.
-- @param #CLIENTMENU self
-- @param Wrapper.Client#CLIENT Client The client for whom this entry is.
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
    self.GID = self.group:GetID()
  else
    self.Generic = true
  end
  self.name = Text or "unknown entry"
  if Parent then
    self.parentpath = Parent:GetPath()
    Parent:AddChild(self)
  end
  self.Parent = Parent
  self.Function = Function
  self.Functionargs = arg
  if self.Functionargs and self.debug then
    self:I({"Functionargs",self.Functionargs})
  end
  if not self.Generic then
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
      self.path = missionCommands.addCommandForGroup(self.GID,Text,self.parentpath, self.CallHandler)
    else
      self.path = missionCommands.addSubMenuForGroup(self.GID,Text,self.parentpath)
    end
  else
    if self.parentpath then
      self.path = UTILS.DeepCopy(self.parentpath)
    else
      self.path = {}
    end
    self.path[#self.path+1] = Text
    self:T({self.path})
  end
  self.Once = false
  -- Log id.
  self.lid=string.format("CLIENTMENU %s | %s | ", self.ID, self.name)
  self:T(self.lid.."Created")
  return self
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
  if not self.Generic then
    missionCommands.removeItemForGroup(self.GID , self.path )
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
  --self:T({self.Children})
  for _id,_entry in pairs(self.Children) do
    self:T("Removing ".._id)
    if _entry then
      _entry:RemoveSubEntries()
      _entry:RemoveF10()
      if _entry.Parent then
        _entry.Parent:RemoveChild(self)
      end
      if self.Controller then
        self.Controller:_RemoveByID(_entry.ID)
      end
      _entry = nil
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
  if self.Controller then
    self.Controller:_RemoveByID(self.ID)
  end
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
-- @field #table structure
-- @field #table replacementstructure
-- @field #table rootentries
-- @field #number entrycount
-- @field #boolean debug
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
--            menumgr:Propagate()
--            
-- ## Remove a single entry's subtree
-- 
--            menumgr:RemoveSubEntries(mymenu_lv3a)
--            
 -- ## Remove a single entry and also it's subtree
-- 
--            menumgr:Clear(mymenu_lv3a)
-- 
-- ## Add a single entry
-- 
--            local baimenu = menumgr:NewEntry("BAI",mymenu_lv1b)
--            menumgr:AddEntry(baimenu)           
--     
-- ## Prepare and push a partial replacement in the tree
--            
--            menumgr:PrepareNewReplacementStructure()
--            local submenu = menumgr:NewReplacementEntry("New Level 2 ba",mymenu_lv2a)
--            menumgr:NewReplacementEntry("New Level 2 bb",mymenu_lv2a)
--            menumgr:NewReplacementEntry("Deleted",mymenu_lv2a)
--            menumgr:NewReplacementEntry("New Level 2 bd",mymenu_lv2a)
--            menumgr:NewReplacementEntry("SubLevel 3 baa",submenu)
--            menumgr:NewReplacementEntry("SubLevel 3 bab",submenu)
--            menumgr:NewReplacementEntry("SubLevel 3 bac",submenu)
--            menumgr:NewReplacementEntry("SubLevel 3 bad",submenu)
--            menumgr:ReplaceEntries(mymenu_lv2a)
--            
-- ## Change the text of an entry in the menu tree          
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
-- @field #CLIENTMENUMANAGER
CLIENTMENUMANAGER = {
  ClassName = "CLIENTMENUMANAGER",
  lid = "",
  version = "0.0.1",
  name = nil,
  clientset = nil,
  ---
  -- @field #CLIENTMENUMANAGER.Structure
  structure = { 
    generic = {},
    IDs = {},
  },
  ---
  -- #CLIENTMENUMANAGER.ReplacementStructure
  replacementstructure = { 
    generic = {},
    IDs = {},
  },
  entrycount = 0,
  rootentries = {},
  debug = true,
}

---
-- @type CLIENTMENUMANAGER.Structure
-- @field #table generic
-- @field #table IDs 

--- Create a new ClientManager instance.
-- @param #CLIENTMENUMANAGER self
-- @param Core.Set#SET_CLIENT ClientSet The set of clients to manage.
-- @param #string Alias The name of this manager.
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:New(ClientSet, Alias)
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, BASE:New()) -- #CLIENTMENUMANAGER
  self.clientset = ClientSet
  self.name = Alias or "Nightshift"
    -- Log id.
  self.lid=string.format("CLIENTMENUMANAGER %s | %s | ", self.version, self.name)
  if self.debug then
    self:I(self.lid.."Created")
  end
  return self
end

--- Create a new entry in the generic structure.
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
  self.structure.generic[self.entrycount] = entry
  self.structure.IDs[entry.ID] = self.entrycount
  if not Parent then
    self.rootentries[self.entrycount] = self.entrycount
  end
  return entry
end

--- Find **first** matching entry in the generic structure by the menu text.
-- @param #CLIENTMENUMANAGER self
-- @param #string Text Text of the F10 menu entry.
-- @return #CLIENTMENU Entry The #CLIENTMENU object found or nil.
-- @return #number GID GID  The GID found or nil.
function CLIENTMENUMANAGER:FindEntryByText(Text)
  self:T(self.lid.."FindEntryByText "..Text or "None")
  local entry = nil
  local gid = nil
  for _gid,_entry in UTILS.spairs(self.structure.generic) do
    local Entry = _entry -- #CLIENTMENU
    if Entry and Entry.name == Text then
      entry = Entry
      gid = _gid
    end
  end
  return entry, gid
end

--- Find first matching entry in the generic structure by the GID.
-- @param #CLIENTMENUMANAGER self
-- @param #number GID The GID of the entry to find.
-- @return #CLIENTMENU Entry The #CLIENTMENU object found or nil.
function CLIENTMENUMANAGER:GetEntryByGID(GID)
  self:T(self.lid.."GetEntryByGID "..GID or "None")
  if GID and type(GID) == "number" then
    return self.structure.generic[GID]
  else
    return nil
  end
end

--- Alter the text of an entry in the generic structure and push to all clients.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Entry The menu entry.
-- @param #string Text Text of the F10 menu entry.
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:ChangeEntryTextForAll(Entry,Text)
  self:T(self.lid.."ChangeEntryTextForAll "..Text or "None")
  for _,_client in pairs(self.clientset.Set) do
    local client = _client -- Wrapper.Client#CLIENT
    if client and client:IsAlive() then
      self:ChangeEntryText(Entry,Text, client)
    end
  end
  return self
end

--- Alter the text of an entry in the generic structure and push to one specific client.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Entry The menu entry.
-- @param #string Text Text of the F10 menu entry.
-- @param Wrapper.Client#CLIENT Client The client for whom to alter the entry
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:ChangeEntryText(Entry,Text, Client)
  self:T(self.lid.."ChangeEntryText "..Text or "None")
  
  local text = Text or "none"
  local oldtext = Entry.name
  Entry.name = text
  
  local newstructure = {}
  local changed = 0
  
  local function ChangePath(path,oldtext,newtext)
    local newpath = {}
    for _id,_text in UTILS.spairs(path) do
      local txt = _text
      if _text == oldtext then
        txt = newtext
      end
      newpath[_id] = txt
    end
    return newpath  
  end
  
  local function AlterPath(children)
    for _,_entry in pairs(children) do
      local entry = _entry -- #CLIENTMENU
      local newpath = ChangePath(entry.path,oldtext,text)
      local newparentpath = ChangePath(entry.parentpath,oldtext,text)
      entry.path = nil
      entry.parentpath = nil
      entry.path = newpath
      entry.parentpath = newparentpath
      self:T({entry.ID})
      --self:T({entry.parentpath})
      newstructure[entry.ID] = UTILS.DeepCopy(entry)
      changed = changed + 1
      if entry.Children and #entry.Children > 0 then
        AlterPath(entry.Children)
      end
    end
  end
 
  -- get the entry
  local ID = Entry.ID
  local GID = self.structure.IDs[ID]
  local playername = Client:GetPlayerName()
  local children = self.structure[playername][GID].Children
  AlterPath(children)
  
  self:T("Changed entries: "..changed)

  local NewParent = self:NewEntry(Entry.name,Entry.Parent,Entry.Function,unpack(Entry.Functionargs))
  
  for _,_entry in pairs(children) do
    self:T("Changed parent for ".._entry.ID.." | GID ".._entry.GID)
    local entry = _entry -- #CLIENTMENU
    entry.Parent = NewParent
  end
  
  self:PrepareNewReplacementStructure()
  
  for _,_entry in pairs(newstructure) do
    self:T("Changed entry: ".._entry.ID.." | GID ".._entry.GID)
    local entry = _entry -- #CLIENTMENU
    self:NewReplacementEntry(entry.name,entry.Parent,entry.Function,unpack(entry.Functionargs))
  end
  

  self:AddEntry(NewParent)
  self:ReplaceEntries(NewParent)
  
  self:Clear(Entry)
  
  return self
end

--- Create a new entry in the replacement structure.
-- @param #CLIENTMENUMANAGER self
-- @param #string Text Text of the F10 menu entry.
-- @param #CLIENTMENU Parent The parent menu entry.
-- @param #string Function (optional) Function to call when the entry is used.
-- @param ... (optional) Arguments for the Function, comma separated
-- @return #CLIENTMENU Entry
function CLIENTMENUMANAGER:NewReplacementEntry(Text,Parent,Function,...)
  self:T(self.lid.."NewReplacementEntry "..Text or "None")
  self.entrycount = self.entrycount + 1
  local entry = CLIENTMENU:NewEntry(nil,Text,Parent,Function,unpack(arg))
  self.replacementstructure.generic[self.entrycount] = entry
  self.replacementstructure.IDs[entry.ID] = self.entrycount
  local pID = Parent and Parent.ID or "none"
  if self.debug then
    self:I("Entry ID = "..self.entrycount.." | Parent ID = "..tostring(pID))
  end
  if not Parent then
    self.rootentries[self.entrycount] = self.entrycount
  end
  return entry
end

--- Prepare a new replacement structure. Deletes the previous one.
-- @param #CLIENTMENUMANAGER self
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:PrepareNewReplacementStructure()
  self:T(self.lid.."PrepareNewReplacementStructure")
  self.replacementstructure = nil -- #CLIENTMENUMANAGER.Structure
  self.replacementstructure = {
    generic = {},
    IDs = {},
    }
  return self
end

--- [Internal] Merge the replacement structure into the generic structure.
-- @param #CLIENTMENUMANAGER self
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:_MergeReplacementData()
  self:T(self.lid.."_MergeReplacementData")
  for _id,_entry in pairs(self.replacementstructure.generic) do
    self.structure.generic[_id] = _entry
  end
  for _id,_entry in pairs(self.replacementstructure.IDs) do
    self.structure.IDs[_id] = _entry
  end
  self:_CleanUpPlayerStructure()
  return self
end

--- Replace entries under the Parent entry with the Replacement structure created prior for all clients.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Parent The parent entry under which to replace with the new structure.
-- @param Wrapper.Client#CLIENT Client (optional) If given, make this change only for this client. In this case the generic structure will not be touched.
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:ReplaceEntries(Parent,Client)
  self:T(self.lid.."ReplaceEntries")
  -- clear Parent substructure
  local Set = self.clientset.Set
  if Client then
    Set = {Client}
  else
    self:RemoveSubEntries(Parent)
  end
  for _,_client in pairs(Set) do
    local client = _client -- Wrapper.Client#CLIENT
    if client and client:IsAlive() then
      local playername = client:GetPlayerName()
        --self.structure[playername] = {}
        for _id,_entry in UTILS.spairs(self.replacementstructure.generic) do
          local entry = _entry -- #CLIENTMENU
          local parent = Parent
          self:T("Posted Parent = "..Parent.ID)
          if entry.Parent and entry.Parent.name then
            parent = self:_GetParentEntry(self.replacementstructure.generic,entry.Parent.name) or Parent
            self:T("Found Parent = "..parent.ID)
          end
          self.structure[playername][_id] = CLIENTMENU:NewEntry(client,entry.name,parent,entry.Function,unpack(entry.Functionargs))
          self.structure[playername][_id].Once = entry.Once
        end
    end
  end
  self:_MergeReplacementData()
  return self
end

--- [Internal] Find a parent entry in a given structure by name.
-- @param #CLIENTMENUMANAGER self
-- @param #table Structure Table of entries.
-- @param #string Name Name to find.
-- @return #CLIENTMENU Entry
function CLIENTMENUMANAGER:_GetParentEntry(Structure,Name)
  self:T(self.lid.."_GetParentEntry")
  local found = nil
  for _,_entry in pairs(Structure) do
    local entry = _entry -- #CLIENTMENU
    if entry.name == Name then
      found = entry
      break
    end
  end
  return found
end

--- Push the complete menu structure to each of the clients in the set.
-- @param #CLIENTMENUMANAGER self
-- @param Wrapper.Client#CLIENT Client (optional) If given, propagate only for this client.
-- @return #CLIENTMENU Entry
function CLIENTMENUMANAGER:Propagate(Client)
  self:T(self.lid.."Propagate")
  local Set = self.clientset.Set
  if Client then
    Set = {Set}
  end
  for _,_client in pairs(Set) do
    local client = _client -- Wrapper.Client#CLIENT
    if client and client:IsAlive() then
      local playername = client:GetPlayerName()
        self.structure[playername] = {}
        for _id,_entry in pairs(self.structure.generic) do
          local entry = _entry -- #CLIENTMENU
          local parent = nil
          if entry.Parent and entry.Parent.name then
            parent = self:_GetParentEntry(self.structure[playername],entry.Parent.name)
          end
          self.structure[playername][_id] = CLIENTMENU:NewEntry(client,entry.name,parent,entry.Function,unpack(entry.Functionargs))
          self.structure[playername][_id].Once = entry.Once
        end
    end
  end
  return self
end

--- Push a single previously created entry into the menu structure of all clients.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Entry The entry to add.
-- @param Wrapper.Client#CLIENT Client (optional) If given, make this change only for this client. 
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:AddEntry(Entry,Client)
  self:T(self.lid.."AddEntry")
  local Set = self.clientset.Set
  if Client then
    Set = {Client}
  end
  for _,_client in pairs(Set) do
    local client = _client -- Wrapper.Client#CLIENT
    if client and client:IsAlive() then
      local playername = client:GetPlayerName()
      local entry = Entry -- #CLIENTMENU
      local parent = nil
      if entry.Parent and entry.Parent.name then
        parent = self:_GetParentEntry(self.structure[playername],entry.Parent.name)
      end
      self.structure[playername][Entry.ID] = CLIENTMENU:NewEntry(client,entry.name,parent,entry.Function,unpack(entry.Functionargs))
      self.structure[playername][Entry.ID].Once = entry.Once
    end
  end
  return self
end

--- Blank out the menu - remove **all root entries** and all entries below from the client's menus, leaving the generic structure untouched.
-- @param #CLIENTMENUMANAGER self
-- @param Wrapper.Client#CLIENT Client 
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:ResetMenu(Client)
  self:T(self.lid.."ResetMenu")
  for _,_entry in pairs(self.rootentries) do
    local RootEntry = self.structure.generic[_entry]
    if RootEntry then
      self:Clear(RootEntry,Client)
    end
  end
  return self
end

--- Blank out the menu - remove **all root entries** and all entries below from all clients' menus, and **delete** the generic structure.
-- @param #CLIENTMENUMANAGER self
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:ResetMenuComplete()
  self:T(self.lid.."ResetMenuComplete")
  for _,_entry in pairs(self.rootentries) do
    local RootEntry = self.structure.generic[_entry]
    if RootEntry then
      self:Clear(RootEntry)
    end
  end
  self.structure = nil
  self.structure = { 
    generic = {},
    IDs = {},
  }
  self.rootentries = nil
  self.rootentries = {}
  return self
end

--- Remove the entry and all entries below the given entry from the client's menus and the generic structure.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Entry The entry to remove
-- @param Wrapper.Client#CLIENT Client (optional) If given, make this change only for this client. In this case the generic structure will not be touched.
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:Clear(Entry,Client)
  self:T(self.lid.."Clear")
  local rid = self.structure.IDs[Entry.ID]
  if rid then
    local generic = self.structure.generic[rid]
    local Set = self.clientset.Set
    if Client then
      Set = {Client}
    end
    for _,_client in pairs(Set) do
      local client = _client -- Wrapper.Client#CLIENT
      if client and client:IsAlive() then
        local playername = client:GetPlayerName()
        local entry = self.structure[playername][rid] -- #CLIENTMENU
        if entry then
          entry:Clear()
          self.structure[playername][rid] = nil        
          end
      end
    end
    if not Client then
      for _id,_entry in pairs(self.structure.generic) do
        local entry = _entry -- #CLIENTMENU
        if entry and entry.Parent and entry.Parent.ID and entry.Parent.ID == rid then
          self.structure.IDs[entry.ID] = nil
          entry = nil
        end
      end
    end
  end
  return self
end

--- [Internal] Clean up player shadow structure
-- @param #CLIENTMENUMANAGER self
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:_CleanUpPlayerStructure()
  self:T(self.lid.."_CleanUpPlayerStructure")
  for _,_client in pairs(self.clientset.Set) do
    local client = _client -- Wrapper.Client#CLIENT
    if client and client:IsAlive()  then
      local playername = client:GetPlayerName()
      local newstructure = {}
      for _id, _entry in UTILS.spairs(self.structure[playername]) do
        if self.structure.generic[_id] then
          newstructure[_id] = _entry
        end
      end
      self.structure[playername] = nil
      self.structure[playername] = newstructure
    end
  end
  return self
end

--- Remove all entries below the given entry from the clients' menus and the generic structure.
-- @param #CLIENTMENUMANAGER self
-- @param #CLIENTMENU Entry The menu entry
-- @param Wrapper.Client#CLIENT Client (optional) If given, make this change only for this client. In this case the generic structure will not be touched.
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:RemoveSubEntries(Entry,Client)
  self:T(self.lid.."RemoveSubEntries")
  local rid = self.structure.IDs[Entry.ID]
  if rid then
    local Set = self.clientset.Set
    if Client then
      Set = {Client}
    end
    for _,_client in pairs(Set) do
      local client = _client -- Wrapper.Client#CLIENT
      if client and client:IsAlive() then
        local playername = client:GetPlayerName()
        local entry = self.structure[playername][rid] -- #CLIENTMENU
        if entry then 
          entry:RemoveSubEntries()
        end
      end
    end
    if not Client then
      for _id,_entry in pairs(self.structure.generic) do
        local entry = _entry -- #CLIENTMENU
        if entry and entry.Parent and entry.Parent.ID and entry.Parent.ID == rid then
          self.structure.IDs[entry.ID] = nil
          self.structure.generic[_id] = nil
        end
      end
    end
  end
  self:_CleanUpPlayerStructure()
  return self
end

--- Remove a specific entry by ID from the generic structure
-- @param #CLIENTMENUMANAGER self
-- @param #number ID
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:_RemoveByID(ID)
  self:T(self.lid.."_RemoveByID "..ID or "none")
  if ID then
    local gid = self.structure.IDs[ID]
    if gid then
      self.structure.generic[gid] = nil
      self.structure.IDs[ID] = nil
    end
  end
  return self
end

--- [Internal] Dump structures to log for debug
-- @param #CLIENTMENUMANAGER self
-- @param #string Playername
-- @return #CLIENTMENUMANAGER self
function CLIENTMENUMANAGER:_CheckStructures(Playername)
  self:T(self.lid.."CheckStructures")
  self:I("Generic Structure")
  self:I("-----------------")
  for _id,_entry in UTILS.spairs(self.structure.generic) do
    local ID = "none"
    if _entry and _entry.ID then
      ID = _entry.ID
    end
    self:I("ID= ".._id.." | EntryID = "..ID)
    if _id > 10 and _id < 14 then
      self:I(_entry.name)
    end
  end
  self:I("Reverse Structure")
  self:I("-----------------")
  for _id,_entry in UTILS.spairs(self.structure.IDs) do
    self:I("EntryID= ".._id.." | ID = ".._entry)
  end
  if Playername then
    self:I("Player Structure")
    self:I("-----------------")
    for _id,_entry in UTILS.spairs(self.structure[Playername]) do
      local ID = "none"
      if _entry and _entry.ID then
        ID = _entry.ID
      end
      local _lid = _id or "none"
      self:I("ID= ".._lid.." | EntryID = "..ID)
    end
  end
  return self
end

----------------------------------------------------------------------------------------------------------------
--
-- End ClientMenu
--
----------------------------------------------------------------------------------------------------------------

