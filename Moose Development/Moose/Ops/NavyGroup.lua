--- **Ops** - Control Naval Groups.
-- 
-- **Main Features:**
--
--    * Nice stuff.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.NavyGroup
-- @image OPS_NavyGroup.png


--- NAVYGROUP class.
-- @type NAVYGROUP
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string groupname The name of the NAVY group.
-- @field Wrapper.Group#GROUP group The group object.
-- @field #number currentwp Last waypoint passed.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\NAVYGROUP\NavyGroup_Main.jpg)
--
-- # The NAVYGROUP Concept
-- 
-- 
-- 
-- @field #NAVYGROUP
NAVYGROUP = {
  ClassName      = "NAVYGROUP",
  lid            =   nil,
  groupname      =   nil,
  group          =   nil,
  currentwp      =     1,
  elements       =    {},
}

--- NavyGroup version.
-- @field #string version
NAVYGROUP.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- TODO: Stop and resume route.
-- TODO: Add waypoints.
-- TODO: Add tasks.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new NAVYGROUP class object.
-- @param #NAVYGROUP self
-- @param #string GroupName Name of the group.
-- @return #NAVYGROUP self
function NAVYGROUP:New(GroupName)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #NAVYGROUP
  
  
  self.groupname=GroupName
  
  self.group=GROUP:FindByName(self.groupname)
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("NAVYGROUP %s |", self.groupname)
  
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",             "Cruising")    -- Status update.
  self:AddTransition("*",             "Status",            "*")           -- Status update.
  
  self:AddTransition("*",             "PassingWaypoint",   "*")           -- Passing waypoint.
  self:AddTransition("*",             "UpdateRoute",       "*")           -- Passing waypoint.
  self:AddTransition("*",             "Hold",              "Holding")     -- Hold position.
  self:AddTransition("*",             "TurnIntoWind",      "*")           -- Hold position.
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the NAVYGROUP. Initializes parameters and starts event handlers.
  -- @function [parent=#NAVYGROUP] Start
  -- @param #NAVYGROUP self

  --- Triggers the FSM event "Start" after a delay. Starts the NAVYGROUP. Initializes parameters and starts event handlers.
  -- @function [parent=#NAVYGROUP] __Start
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the NAVYGROUP and all its event handlers.
  -- @param #NAVYGROUP self

  --- Triggers the FSM event "Stop" after a delay. Stops the NAVYGROUP and all its event handlers.
  -- @function [parent=#NAVYGROUP] __Stop
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#NAVYGROUP] Status
  -- @param #NAVYGROUP self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#NAVYGROUP] __Status
  -- @param #NAVYGROUP self
  -- @param #number delay Delay in seconds.  

  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  
  self:_InitGroup()
  
  self:Start()
   
  return self  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get coalition.
-- @param #NAVYGROUP self
-- @return #number Coalition side of carrier.
function NAVYGROUP:GetCoalition()
  return self.group:GetCoalition()
end

--- Get coordinate.
-- @param #NAVYGROUP self
-- @return Core.Point#COORDINATE Carrier coordinate.
function NAVYGROUP:GetCoordinate()
  return self.group:GetCoordinate()
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start NAVYGROUP FSM. Handle events.
-- @param #NAVYGROUP self
function NAVYGROUP:onafterStart(From, Event, To)

  -- Info.
  self:I(self.lid..string.format("Starting NAVYGROUP v%s for %s", NAVYGROUP.version, self.groupname))
  
  -- Update route.
  --self:UpdateRoute()
  
  -- Init status updates.
  self:__Status(-1)
end

--- Update status.
-- @param #NAVYGROUP self
function NAVYGROUP:onafterStatus(From, Event, To)

  local fsmstate=self:GetState()
  
  local speed=self.group:GetVelocityKNOTS()

    -- Info text.
  local text=string.format("State %s: Speed=%.1f knots", fsmstate, speed)
  self:I(self.lid..text)

  self:__Status(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "UpdateRoute" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number. Default is next waypoint.
function NAVYGROUP:onafterUpdateRoute(From, Event, To, n)

  -- Update route from this waypoint number onwards.
  n=n or self.currentwp+1
  
  -- Update waypoint tasks, i.e. inject WP tasks into waypoint table.
  self:_UpdateWaypointTasks()

  -- Waypoints.
  local wp={}
  
  -- Current velocity.
  local speed=self.group and self.group:GetVelocityKMH() or 100 
  
  
  local current=self:GetCoordinate():WaypointNaval(speed, 0, {})
  table.insert(wp, current)
  
  -- Add remaining waypoints to route.
  for i=n, #self.waypoints do
    table.insert(wp, self.waypoints[i])
  end

  
  if #wp>1 then

    -- Route group to all defined waypoints remaining.
    self.group:Route(wp, 1)
    
  else
  
    ---
    -- No waypoints left
    ---
  
    --self:_CheckFlightDone()
          
  end

end

--- On after "TurnIntoWind" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Duraction Duration in seconds.
-- @param #number Speed Speed in knots.
-- @param #boolean Uturn Return to the place we came from.
function NAVYGROUP:onafterTurnIntoWind(From, Event, To, Duration, Speed, Uturn)

  self.turnintowind=true
  
  local headingTo=self:GetCoordinate():GetWind(50)
  
  local distance=UTILS.NMToMeters(1000)
  
  local wp={}
  
  local coord=self:GetCoordinate()
  local Coord=coord:Translate(distance, headingTo)
  
  wp[1]=coord:WaypointNaval(Speed)
  wp[2]=Coord:WaypointNaval(Speed)
  if Uturn then
    wp[3]=wp[1]
  end

  self.group:Route(wp, 1)
  
end

--- On after "Hold" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterHold(From, Event, To)

  -- Get current position.
  local pos=self:GetCoordinate()
  
  -- Create a new waypoint.
  local wp=pos:WaypointNaval(0, 0, {})
  
  -- Create new route consisting of only this position ==> Stop!
  self.group:Route({wp})

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Routing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Initialize group parameters. Also initializes waypoints if self.waypoints is nil.
-- @param #NAVYGROUP self
-- @return #NAVYGROUP self
function NAVYGROUP:_InitGroup()

  -- First check if group was already initialized.
  if self.groupinitialized then
    self:E(self.lid.."WARNING: Group was already initialized!")
    return
  end

  -- Get template of group.
  self.template=self.group:GetTemplate()

  -- Helo group.
  --self.isSubmarine=self.group:IsSubmarine()
  
  -- Is (template) group late activated.
  self.isLateActivated=self.template.lateActivation
  
  -- Max speed in km/h.
  self.speedmax=self.group:GetSpeedMax()
  
  -- Cruise speed: 70% of max speed but within limit.
  self.speedCruise=self.speedmax*0.7
  
  -- Group ammo.
  --self.ammo=self:GetAmmoTot()
  
  self.traveldist=0
  self.traveltime=timer.getAbsTime()
  self.position=self:GetCoordinate()
  
  -- Radio parameters from template.
  --self.radioOn=self.template.communication
  self.radioFreq=self.template.units[1].frequency
  self.radioModu=self.template.units[1].modulation
  
  -- If not set by the use explicitly yet, we take the template values as defaults.
  if not self.radioFreqDefault then
    self.radioFreqDefault=self.radioFreq
    self.radioModuDefault=self.radioModu
  end
  
  -- Set default formation.
  if not self.formationDefault then
    if self.ishelo then
      self.formationDefault=ENUMS.Formation.RotaryWing.EchelonLeft.D300
    else
      self.formationDefault=ENUMS.Formation.FixedWing.EchelonLeft.Group
    end
  end
  
  -- Get first unit. This is used to extract other parameters.
  local unit=self.group:GetUnit(1)
  
  if unit then
    
    self.descriptors=unit:GetDesc()
    
    self.actype=unit:GetTypeName()
  
    -- Init waypoints.
    if not self.waypoints then
      self:InitWaypoints()
    end
    
    -- Debug info.
    local text=string.format("Initialized Navy Group %s:\n", self.groupname)
    text=text..string.format("AC type      = %s\n", self.actype)
    text=text..string.format("Speed max    = %.1f Knots\n", UTILS.KmphToKnots(self.speedmax))
    text=text..string.format("Elements     = %d\n", #self.elements)
    text=text..string.format("Waypoints    = %d\n", #self.waypoints)
    text=text..string.format("Radio        = %.1f MHz %s %s\n", self.radioFreq, UTILS.GetModulationName(self.radioModu), tostring(self.radioOn))
    --text=text..string.format("Ammo         = %d (G=%d/R=%d/B=%d/M=%d)\n", self.ammo.Total, self.ammo.Guns, self.ammo.Rockets, self.ammo.Bombs, self.ammo.Missiles)
    text=text..string.format("FSM state    = %s\n", self:GetState())
    text=text..string.format("Is alive     = %s\n", tostring(self.group:IsAlive()))
    --text=text..string.format("LateActivate = %s\n", tostring(self:IsLateActivated()))
    self:I(self.lid..text)
    
    -- Init done.
    self.groupinitialized=true
    
  end
  
  return self
end

--- Initialize Mission Editor waypoints.
-- @param #NAVYGROUP self
-- @param #table waypoints Table of waypoints. Default is from group template.
-- @return #NAVYGROUP self
function NAVYGROUP:InitWaypoints(waypoints)

  -- Template waypoints.
  self.waypoints0=self.group:GetTemplateRoutePoints()

  -- Waypoints of group as defined in the ME.
  self.waypoints=waypoints or UTILS.DeepCopy(self.waypoints0)
  
  -- Debug info.
  self:T(self.lid..string.format("Initializing %d waypoints. Homebase %s ==> %s Destination", #self.waypoints, self.homebase and self.homebase:GetName() or "unknown", self.destbase and self.destbase:GetName() or "uknown"))
  
  -- Update route.
  if #self.waypoints>0 then
  
    -- Check if only 1 wp?
    if #self.waypoints==1 then
      self.passedfinalwp=true
    end
    
    -- Update route (when airborne).
    self:__UpdateRoute(-1)
  end

  return self
end

--- Initialize Mission Editor waypoints.
-- @param #NAVYGROUP self
function NAVYGROUP:_UpdateWaypointTasks()

  local waypoints=self.waypoints
  local nwaypoints=#waypoints

  for i,wp in pairs(waypoints) do
    
    if i>self.currentwp or nwaypoints==1 then
    
      -- Debug info.
      self:T2(self.lid..string.format("Updating waypoint task for waypoint %d/%d. Last waypoint passed %d.", i, nwaypoints, self.currentwp))
  
      -- Tasks of this waypoint
      local taskswp={}
    
      -- At each waypoint report passing.
      local TaskPassingWaypoint=self.group:TaskFunction("NAVYGROUP._PassingWaypoint", self, i)      
      table.insert(taskswp, TaskPassingWaypoint)      
          
      -- Waypoint task combo.
      wp.task=self.group:TaskCombo(taskswp)
      
    end
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Function called when a group is passing a waypoint.
--@param Wrapper.Group#GROUP group Group that passed the waypoint
--@param #NAVYGROUP navygroup Navy group object.
--@param #number i Waypoint number that has been reached.
function NAVYGROUP._PassingWaypoint(group, navygroup, i)

  local final=#navygroup.waypoints or 1

  -- Debug message.
  local text=string.format("Group passing waypoint %d of %d", i, final)
  navygroup:T3(navygroup.lid..text)

  -- Set current waypoint.
  navygroup.currentwp=i

  -- Trigger PassingWaypoint event.
  navygroup:PassingWaypoint(i, final)

end




--- Set rules of engagement.
-- @param #NAVYGROUP self
-- @param #string roe "Hold", "Free", "Return".
function NAVYGROUP:_SetROE(roe)

  if roe=="Hold" then
    self.group:OptionROEHoldFire()
  elseif roe=="Free" then
    self.group:OptionROEOpenFire()
  elseif roe=="Return" then  
    self.group:OptionROEReturnFire()
  end

  MESSAGE:New(string.format("ROE set to %s", roe), 5, self.ClassName):ToCoalition(self:GetCoalition())
end

--- Set alarm state. (Not useful/working for ships.)
-- @param #NAVYGROUP self
-- @param #string state "Green", "Red", "Auto".
function NAVYGROUP:_SetALS(state)

  if state=="Green" then
    self.group:OptionAlarmStateGreen()
  elseif state=="Red" then
    self.group:OptionAlarmStateRed()
  elseif state=="Auto" then
    self.group:OptionAlarmStateAuto()
  end
  
  MESSAGE:New(string.format("Alarm state set to %s", state), 5, self.ClassName):ToCoalition(self:GetCoalition())
end

--- Function to stop the carrier.
-- @param #NAVYGROUP self
function NAVYGROUP:CarrierHold()
  env.info("Carrier Hold!")

  -- Get current position.
  local pos=self:GetCoordinate()
  
  -- Create a new waypoint.
  local wp=pos:WaypointGround(0)
  
  -- Create new route consisting of only this position ==> Stop!
  self.group:Route({wp})
  
  MESSAGE:New(string.format("Carrier is holding current position."), 5, self.ClassName):ToCoalition(self:GetCoalition())
end

--- Function to stop the carrier.
-- @param #NAVYGROUP self
function NAVYGROUP:CarrierResume()
  env.info("Carrier Resume Route!")
  
  self:_InitWaypoints()
  
  local nextWP,n=self:_GetNextWaypoint()
  
  self:_PatrolRoute(n)
  
  MESSAGE:New(string.format("Carrier is resuming route to waypoint #%d.", n), 5, self.ClassName):ToCoalition(self:GetCoalition())
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
