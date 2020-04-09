--- **Wrapper** - Markers On the F10 map.
-- 
-- 
--
-- **Main Features:**
--
--    * Manage aircraft recovery.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Wrapper.Marker
-- @image Wrapper_Marker.png


--- Marker class.
-- @type MARKER
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #number mid Marker ID.
-- @field Core.Point#COORDINATE coordinate Coordinate of the mark.
-- @field #string text Text displayed in the mark panel.
-- @field #string message Message dispayed when the mark is added.
-- @field #boolean readonly Marker is read-only.
-- @field #number coalition Coalition to which the marker is displayed.
-- @extends Core.Fsm#FSM

--- **Ground Control**: Airliner X, Good news, you are clear to taxi to the active.
--  **Pilot**: Roger, What's the bad news?
--  **Ground Control**: No bad news at the moment, but you probably want to get gone before I find any.
--
-- ===
--
-- ![Banner Image](..\Presentations\MARKER\Marker_Main.jpg)
--
-- # The MARKER Concept
-- 
-- 
-- 
-- @field #MARKER
MARKER = {
  ClassName      = "MARKER",
  Debug          = false,
  lid            =   nil,
  mid            =   nil,
  coordinate     =   nil,
  text           =   nil,
  message        =   nil,
  readonly       =   nil,
  coalition      =   nil,
}

--- Holding point
-- @type MARKER.HoldingPoint
-- @field Core.Point#COORDINATE pos0 First poosition of racetrack holding point.
-- @field Core.Point#COORDINATE pos1 Second position of racetrack holding point.
-- @field #number angelsmin Smallest holding altitude in angels.
-- @field #number angelsmax Largest holding alitude in angels.


--- Marker class version.
-- @field #string version
MARKER.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- TODO: Handle events.
-- TODO: Some more...

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new MARKER class object.
-- @param #MARKER self
-- @param Core.Point#COORDINATE Coordinate Coordinate where to place the marker.
-- @param #string Text Text displayed on the mark panel. 
-- @return #MARKER self
function MARKER:New(Coordinate, Text)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #MARKER
  
  self.coordinate=Coordinate
  
  self.text=Text
  
  -- Defaults
  self.readonly=false
  self.message=""
  
  -- Get ID.
  self.mid=UTILS.GetMarkID()
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "Added",           "Shown")     -- Marker was added.
  self:AddTransition("*",             "Removed",         "Shown")     -- Marker was added.
  
  self:AddTransition("*",             "Change",          "*")         -- Update status.

  -- Handle events.
  self:HandleEvent(EVENTS.MarkAdded)
  self:HandleEvent(EVENTS.MarkRemoved)
  self:HandleEvent(EVENTS.MarkChange)
  
  return self  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User API Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Marker is readonly.
-- @param #MARKER self
-- @return #MARKER self
function MARKER:ReadOnly()

  self.readonly=true
  
  return self
end

--- Marker is readonly.
-- @param #MARKER self
-- @param #string Text Message displayed when the marker is added.
-- @return #MARKER self
function MARKER:Message(Text)

  self.message=Text or ""
  
  return self
end

--- Place marker visible for everyone.
-- @param #MARKER self
-- @return #MARKER self
function MARKER:ToAll()

  self.toall=true

  -- First remove an existing mark.
  if self.shown then    
    self:Remove()    
  end  

  -- Call DCS function.
  trigger.action.markToAll(self.mid, self.text, self.coordinate:GetVec3(), self.readonly, self.message)

  return self
end

--- Place marker visible for a specific coalition only.
-- @param #MARKER self
-- @param #number Coalition Coalition 1=Red, 2=Blue, 0=Neutral. See `coaliton.side.RED`.
-- @return #MARKER self
function MARKER:ToCoalition(Coalition)

  self.coalition=Coalition
  
  self.tocoaliton=true
  
  -- First remove an existing mark.
  if self.shown then    
    self:Remove()    
  end  
  
  -- Call DCS function.
  trigger.action.markToCoalition(self.mid, self.text, self.coordinate:GetVec3(), self.coalition, self.readonly, self.message)
  
  return self
end

--- Place marker visible for the blue coalition only.
-- @param #MARKER self
-- @return #MARKER self
function MARKER:ToBlue()
  self:ToCoalition(coalition.side.BLUE)
  return self
end

--- Place marker visible for the blue coalition only.
-- @param #MARKER self
-- @return #MARKER self
function MARKER:ToRed()
  self:ToCoalition(coalition.side.RED)
  return self
end

--- Place marker visible for the neutral coalition only.
-- @param #MARKER self
-- @return #MARKER self
function MARKER:ToNeutral()
  self:ToCoalition(coalition.side.NEUTRAL)
  return self
end


--- Place marker visible for a specific group only.
-- @param #MARKER self
-- @param Wrapper.Group#GROUP Group The group to which te
-- @return #MARKER self
function MARKER:ToGroup(Group)

  -- Check if group exists.
  if Group and Group:IsAlive()~=nil then

    self.groupid=Group:GetID()
    
    if self.groupid then

      self.groupname=Group:GetName()
          
      self.togroup=true
      
      -- First remove an existing mark.
      if self.shown then    
        self:Remove()    
      end  
    
      -- Call DCS function.
      trigger.action.markToGroup(self.mid, self.text, self.coordinate:GetVec3(), self.groupid, self.readonly, self.message)
      
    end
    
  else
    --TODO: Warning!    
  end
  
  return self
end

--- Update the text displayed on the mark panel.
-- @param #MARKER self
-- @param #string Text Updated text.
-- @return #MARKER self
function MARKER:UpdateText(Text)

  self.text=Text
  
  self:Refresh()

end

--- Update the coordinate where the marker is displayed.
-- @param #MARKER self
-- @param Core.Point#COORDINATE Coordinate The new coordinate.
-- @return #MARKER self
function MARKER:UpdateCoordinate(Coordinate)

  self.coordinate=Coordinate
  
  self:Refresh()

end

--- Refresh the marker.
-- @param #MARKER self
-- @return #MARKER self
function MARKER:Refresh()

  if self.toall then
  
    self:ToAll()
 
  elseif self.tocoaliton then
  
    self:ToCoalition(self.coalition)
  
  elseif self.togroup then
  
    local group=GROUP:FindByName(self.groupname)
  
    self:ToGroup(group)
  
  end

end

--- Remove a marker.
-- @param #MARKER self
-- @return #MARKER self
function MARKER:Remove()

  -- Call DCS function.
  trigger.action.removeMark(self.mid)

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event function when a MARKER is added.
-- @param #MARKER self
-- @param Core.Event#EVENTDATA EventData
function MARKER:OnEventMarkAdded(EventData)

  local MarkID=EventData.MarkID
  
  if MarkID==self.mid then
  
    self.shown=true
  
  end

end

--- Event function when a MARKER is removed.
-- @param #MARKER self
-- @param Core.Event#EVENTDATA EventData
function MARKER:OnEventMarkRemoved(EventData)

  local MarkID=EventData.MarkID
  
  if MarkID==self.mid then
  
    self.shown=false
  
  end

end

--- Event function when a MARKER changed.
-- @param #MARKER self
-- @param Core.Event#EVENTDATA EventData
function MARKER:OnEventMarkChange(EventData)

  local MarkID=EventData.MarkID
  
  if MarkID==self.mid then
  
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
