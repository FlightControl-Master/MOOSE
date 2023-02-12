--- **Core** - Tap into markers added to the F10 map by users.
--
-- **Main Features:**
--
--    * Create an easy way to tap into markers added to the F10 map by users.
--    * Recognize own tag and list of keywords.
--    * Matched keywords are handed down to functions.
-- ##Listen for your tag
--    myMarker = MARKEROPS_BASE:New("tag", {}, false)
--    function myMarker:OnAfterMarkChanged(From, Event, To, Text, Keywords, Coord, idx)
--
--    end
-- Make sure to use the "MarkChanged" event as "MarkAdded" comes in right after the user places a blank marker and your callback will never be called.
--
-- ===
--
-- ### Author: **Applevangelist**
-- 
-- Date: 5 May 2021
-- Last Update: Feb 2023
-- 
-- ===
---
-- @module Core.MarkerOps_Base
-- @image MOOSE_Core.JPG

--------------------------------------------------------------------------
-- MARKEROPS_BASE Class Definition.
--------------------------------------------------------------------------

--- MARKEROPS_BASE class.
-- @type MARKEROPS_BASE
-- @field #string ClassName Name of the class.
-- @field #string Tag Tag to identify commands.
-- @field #table Keywords Table of keywords to recognize.
-- @field #string version Version of #MARKEROPS_BASE.
-- @field #boolean Casesensitive Enforce case when identifying the Tag, i.e. tag ~= Tag
-- @extends Core.Fsm#FSM

--- *Fiat lux.* -- Latin proverb.
--
-- ===
--
-- # The MARKEROPS_BASE Concept
-- 
-- This class enable scripting text-based actions from markers.
-- 
-- @field #MARKEROPS_BASE
MARKEROPS_BASE = {
  ClassName = "MARKEROPS",
  Tag = "mytag",
  Keywords = {},
  version = "0.1.1",
  debug = false,
  Casesensitive = true,
}

--- Function to instantiate a new #MARKEROPS_BASE object.
-- @param #MARKEROPS_BASE self
-- @param #string Tagname Name to identify us from the event text.
-- @param #table Keywords Table of keywords  recognized from the event text.
-- @param #boolean Casesensitive (Optional) Switch case sensitive identification of Tagname. Defaults to true.
-- @return #MARKEROPS_BASE self
function MARKEROPS_BASE:New(Tagname,Keywords,Casesensitive)
   -- Inherit FSM
  local self=BASE:Inherit(self, FSM:New()) -- #MARKEROPS_BASE
  
    -- Set some string id for output to DCS.log file.
  self.lid=string.format("MARKEROPS_BASE %s | ", tostring(self.version))
  
  self.Tag = Tagname or "mytag"-- #string
  self.Keywords = Keywords or {} -- #table - might want to use lua regex here, too
  self.debug = false
  self.Casesensitive = true
  
  if Casesensitive and Casesensitive == false then
    self.Casesensitive = false
  end
  
  -----------------------
  --- FSM Transitions ---
  -----------------------
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event   -->   To State
  self:AddTransition("Stopped", "Start",        "Running")        -- Start the FSM.
  self:AddTransition("*",       "MarkAdded",    "*")        -- Start the FSM.
  self:AddTransition("*",       "MarkChanged",   "*")        -- Start the FSM.
  self:AddTransition("*",       "MarkDeleted",  "*")        -- Start the FSM.
  self:AddTransition("Running", "Stop",         "Stopped")        -- Stop the FSM.
  
  self:HandleEvent(EVENTS.MarkAdded, self.OnEventMark)
  self:HandleEvent(EVENTS.MarkChange, self.OnEventMark)
  self:HandleEvent(EVENTS.MarkRemoved, self.OnEventMark)
  
  -- start
  self:I(self.lid..string.format("started for %s",self.Tag))
  self:__Start(1)
  return self
  
  -------------------
  -- PSEUDO Functions
  -------------------
  
   --- On after "MarkAdded" event. Triggered when a Marker is added to the F10 map.
   -- @function [parent=#MARKEROPS_BASE] OnAfterMarkAdded
   -- @param #MARKEROPS_BASE self
   -- @param #string From The From state
   -- @param #string Event The Event called
   -- @param #string To The To state
   -- @param #string Text The text on the marker
   -- @param #table Keywords Table of matching keywords found in the Event text
   -- @param Core.Point#COORDINATE Coord Coordinate of the marker.
   
   --- On after "MarkChanged" event. Triggered when a Marker is changed on the F10 map.
   -- @function [parent=#MARKEROPS_BASE] OnAfterMarkChanged
   -- @param #MARKEROPS_BASE self
   -- @param #string From The From state
   -- @param #string Event The Event called
   -- @param #string To The To state
   -- @param #string Text The text on the marker
   -- @param #table Keywords Table of matching keywords found in the Event text
   -- @param Core.Point#COORDINATE Coord Coordinate of the marker.
   -- @param #number idx DCS Marker ID

   --- On after "MarkDeleted" event. Triggered when a Marker is deleted from the F10 map.
   -- @function [parent=#MARKEROPS_BASE] OnAfterMarkDeleted
   -- @param #MARKEROPS_BASE self
   -- @param #string From The From state
   -- @param #string Event The Event called
   -- @param #string To The To state
   
      --- "Stop" trigger. Used to stop the function an unhandle events
   -- @function [parent=#MARKEROPS_BASE] Stop

end

--- (internal) Handle events.
-- @param #MARKEROPS_BASE self
-- @param Core.Event#EVENTDATA Event
function MARKEROPS_BASE:OnEventMark(Event)
  self:T({Event})
    if Event == nil or Event.idx == nil then
      self:E("Skipping onEvent. Event or Event.idx unknown.")
      return true
    end
    --position
    local vec3={y=Event.pos.y, x=Event.pos.x, z=Event.pos.z}
    local coord=COORDINATE:NewFromVec3(vec3)
    if self.debug then
      local coordtext = coord:ToStringLLDDM()
      local text = tostring(Event.text)
      local m = MESSAGE:New(string.format("Mark added at %s with text: %s",coordtext,text),10,"Info",false):ToAll()
    end
    -- decision
    if Event.id==world.event.S_EVENT_MARK_ADDED then
      self:T({event="S_EVENT_MARK_ADDED", carrier=self.groupname, vec3=Event.pos})
      -- Handle event
      local Eventtext = tostring(Event.text)
      if Eventtext~=nil then
        if self:_MatchTag(Eventtext) then
         local matchtable = self:_MatchKeywords(Eventtext)
         self:MarkAdded(Eventtext,matchtable,coord)
        end
      end
    elseif Event.id==world.event.S_EVENT_MARK_CHANGE then
      self:T({event="S_EVENT_MARK_CHANGE", carrier=self.groupname, vec3=Event.pos})
      -- Handle event.
      local Eventtext = tostring(Event.text)
      if Eventtext~=nil then
        if self:_MatchTag(Eventtext) then
         local matchtable = self:_MatchKeywords(Eventtext)
         self:MarkChanged(Eventtext,matchtable,coord,Event.idx)
        end
      end
    elseif Event.id==world.event.S_EVENT_MARK_REMOVED then
      self:T({event="S_EVENT_MARK_REMOVED", carrier=self.groupname, vec3=Event.pos})
      -- Hande event.
      local Eventtext = tostring(Event.text)
      if Eventtext~=nil then
        if self:_MatchTag(Eventtext) then
         self:MarkDeleted()
        end
      end
    end
end

--- (internal) Match tag.
-- @param #MARKEROPS_BASE self
-- @param #string Eventtext Text added to the marker.
-- @return #boolean
function MARKEROPS_BASE:_MatchTag(Eventtext)
  local matches = false
  if not self.Casesensitive then
    local type = string.lower(self.Tag) -- #string
    if string.find(string.lower(Eventtext),type) then
      matches = true --event text contains tag
    end
  else
    local type = self.Tag -- #string
    if string.find(Eventtext,type) then
      matches = true --event text contains tag
    end
  end
  return matches
end

--- (internal) Match keywords table.
-- @param #MARKEROPS_BASE self
-- @param #string Eventtext Text added to the marker.
-- @return #table
function MARKEROPS_BASE:_MatchKeywords(Eventtext)
  local matchtable = {}
  local keytable = self.Keywords
  for _index,_word in pairs (keytable) do
    if string.find(string.lower(Eventtext),string.lower(_word))then
      table.insert(matchtable,_word)
    end
  end
  return matchtable
end

--- On before "MarkAdded" event. Triggered when a Marker is added to the F10 map.
 -- @param #MARKEROPS_BASE self
 -- @param #string From The From state
 -- @param #string Event The Event called
 -- @param #string To The To state
 -- @param #string Text The text on the marker
 -- @param #table Keywords Table of matching keywords found in the Event text
 -- @param Core.Point#COORDINATE Coord Coordinate of the marker.
function MARKEROPS_BASE:onbeforeMarkAdded(From,Event,To,Text,Keywords,Coord)
  self:T({self.lid,From,Event,To,Text,Keywords,Coord:ToStringLLDDM()})
end

--- On before "MarkChanged" event. Triggered when a Marker is changed on the F10 map.
 -- @param #MARKEROPS_BASE self
 -- @param #string From The From state
 -- @param #string Event The Event called
 -- @param #string To The To state
 -- @param #string Text The text on the marker
 -- @param #table Keywords Table of matching keywords found in the Event text
 -- @param Core.Point#COORDINATE Coord Coordinate of the marker.
function MARKEROPS_BASE:onbeforeMarkChanged(From,Event,To,Text,Keywords,Coord)
  self:T({self.lid,From,Event,To,Text,Keywords,Coord:ToStringLLDDM()})
end

--- On before "MarkDeleted" event. Triggered when a Marker is removed from the F10 map.
 -- @param #MARKEROPS_BASE self
 -- @param #string From The From state
 -- @param #string Event The Event called
 -- @param #string To The To state
function MARKEROPS_BASE:onbeforeMarkDeleted(From,Event,To)
  self:T({self.lid,From,Event,To})
end

--- On enter "Stopped" event. Unsubscribe events.
 -- @param #MARKEROPS_BASE self
 -- @param #string From The From state
 -- @param #string Event The Event called
 -- @param #string To The To state
function MARKEROPS_BASE:onenterStopped(From,Event,To)
  self:T({self.lid,From,Event,To})
  -- unsubscribe from events
  self:UnHandleEvent(EVENTS.MarkAdded)
  self:UnHandleEvent(EVENTS.MarkChange)
  self:UnHandleEvent(EVENTS.MarkRemoved)
end

--------------------------------------------------------------------------
-- MARKEROPS_BASE Class Definition End.
--------------------------------------------------------------------------
