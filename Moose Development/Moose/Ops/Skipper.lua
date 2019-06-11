--- **ATC** - (R2.5) - Manage behavior of the Carrier Strike Group.
-- 2
-- **Main Features:**
--
--    * Nice stuff.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Skipper
-- @image OPS_Skipper.png


--- SKIPPER class.
-- @type SKIPPER
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string theatre The DCS map used in the mission.
-- @field #string lid Class id string for output to DCS log file.
-- @field Wrapper.Group#GROUP group The carrier strike group.
-- @field Wrapper.Unit#UNIT carrier The carrier unit.
-- @field #string carriername The name of the carrier unit.
-- @field #table waypoints Table of waypoint coordinates as defined in the mission editor.
-- @field #number currentwp Current waypoint, i.e. the one that was passed last. Counting starts a one. 
-- @field Ops.Airboss#AIRBOSS airboss The airboss of the carrier.
-- @field Functional.Warehouse#WAREHOUSE warehouse The warehouse of the carrier.
-- @field Functional.Artillery#ARTY arty The artillery object of the carrier.
-- @field Core.Zone#ZONE_UNIT zoneCCA Carrier Controlled Area, 50 NM zone around the carrier.
-- @field #table intruders Table of intruders, i.e. groups inside the CCA. Each element is of type #SKIPPPER.Intruder.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\SKIPPER\Skipper_Main.jpg)
--
-- # The SKIPPER Concept
-- 
-- 
-- 
-- @field #SKIPPER
SKIPPER = {
  ClassName      = "SKIPPER",
  Debug          = false,
  lid            =   nil,
  theatre        =   nil,
  carriername    =   nil,
  carrier        =   nil,
  group          =   nil,
  waypoints      =   nil,
  currentwp      =   nil,
  airboss        =   nil,
  warehouse      =   nil,
  arty           =   nil,
  zoneCCA        =   nil,
  zoneCCZ        =   nil,
  intruders      =    {},
}

--- Intruder.
-- @type SKIPPER.Intruder
-- @field Wrapper.Group#GROUP group Intruder group object.
-- @field #string groupname Name of the intruder group.
-- @field #number time0 Abs. mission time first detected inside CCA.
-- @field #number dist0 Distance first detected inside CCA.
-- @field DCS#Coalition.Side coalition Coalition side.
-- @field #number threadlevel Thread level of intruder.
-- @field #string threadtext Thread text.
-- @field #number category Group category.
-- @field #string categoryname Group category name.
-- @field #string typename Type name of group.

--- FlightControl class version.
-- @field #string version
SKIPPER.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- TODO: A lot!

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new SKIPPER class object for a specific aircraft carrier unit.
-- @param #SKIPPER self
-- @param #string carriername Name of the carrier.
-- @return #SKIPPER self
function SKIPPER:New(carriername)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #SKIPPER
  
  self.carriername=carriername
  self.carrier=UNIT:FindByName(carriername)
  
  if not self.carrier then
    BASE:E(string.format("ERROR: Could not find carrier %s!", carriername))
    return nil
  end
  
  self.group=self.carrier:GetGroup()
  
  self.arty=ARTY:New(self.group, carriername)
  
  self.warehouse=WAREHOUSE:New(carriername)
  
  self.airboss=AIRBOSS:New(carriername)
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("SKIPPER %s |", self.carriername)
  
  -- Current map.
  self.theatre=env.mission.theatre    
  
  -- 30 NM zone around the airbase.
  self.zoneCCA=ZONE_UNIT:New("CCA", self.carrier, UTILS.NMToMeters(50))
  
  -- Initialize ME waypoints.
  self:_InitWaypoints()
  
  -- Current waypoint.
  self.currentwp=1
  
  -- Patrol route.
  self:_PatrolRoute()
    
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("Stopped",       "Start",           "Running")     -- Start FSM.
  self:AddTransition("*",             "Status",          "*")           -- Update status.

  -- Debug trace.
  if true then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(3)
  end
  
  self.arty:GetAmmo(true)

  return self  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get carrier coalition.
-- @param #SKIPPER self
-- @return #number Coalition side of carrier.
function SKIPPER:GetCoalition()
  return self.carrier:GetCoalition()
end

--- Get carrier coordinate.
-- @param #SKIPPER self
-- @return Core.Point#COORDINATE Carrier coordinate.
function SKIPPER:GetCoordinate()
  return self.carrier:GetCoordinate()
end


--- Get AIRBOSS object associated with the carrier.
-- @param #SKIPPER self
-- @return Ops.Airboss#AIRBOSS Airboss object.
function SKIPPER:GetAirboss()
  return self.airboss
end

--- Get WAREHOUSE object associated with the carrier.
-- @param #SKIPPER self
-- @return Functional.Warehouse#WAREHOUSE Warehouse object.
function SKIPPER:GetWarehouseCarrier()
  return self.warehouse
end

--- Get ARTY object associated with the carrier strike group.
-- @param #SKIPPER self
-- @return Functional.Artillery#ARTY Arty object.
function SKIPPER:GetArty()
  return self.arty
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start SKIPPER FSM. Handle events.
-- @param #SKIPPER self
function SKIPPER:onafterStart()

  -- Events are handled my MOOSE.
  self:I(self.lid..string.format("Starting SKIPPER v%s for carrier %s on map %s.", SKIPPER.version, self.carriername, self.theatre))
  
  -- Start ARTY.
  self.arty:Start()
  
  -- Start Warehouse.
  self.warehouse:Start()
  
  -- Start Airboss.
  self.airboss:Start()
  
  -- Add F10 radio menu.
  self:_SetMenuCoalition()

  -- Handle events.
  self:HandleEvent(EVENTS.Birth)
  self:HandleEvent(EVENTS.EngineStartup)
  self:HandleEvent(EVENTS.Takeoff)
  self:HandleEvent(EVENTS.Land)
  self:HandleEvent(EVENTS.EngineShutdown)
  self:HandleEvent(EVENTS.Crash)
  
  -- Init status updates.
  self:__Status(-1)
end

--- Update status.
-- @param #SKIPPER self
function SKIPPER:onafterStatus()

  local fsmstate=self:GetState()

  -- Check zone for flights inbound.
  self:_CheckIntruder()

  -- Check parking spots.
  --self:_CheckParking()
  
  -- Check waiting and landing queue.
  --self:_CheckQueues()
  
    -- Info text.
  local text=string.format("State %s", fsmstate)
  self:I(self.lid..text)

  self:__Status(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CCA Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Scan carrier zone for (new) units.
-- @param #SKIPPER self
function SKIPPER:_CheckIntruder()
  
  -- Carrier position.
  local coord=self:GetCoordinate()
  
  -- Scan radius = radius of the CCA.
  local RCCZ=self.zoneCCA:GetRadius()
  
  -- Debug info.
  self:T(self.lid..string.format("Scanning Carrier Controlled Area. Radius=%.1f NM.", UTILS.MetersToNM(RCCZ)))
  
  -- Scan units in carrier zone.
  local _,_,_,unitscan=coord:ScanObjects(RCCZ, true, false, false)

  
  -- Make a table with all groups currently in the CCA zone.
  local insideCCA={}
  for _,_unit in pairs(unitscan) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    -- Necessary conditions to be met:
    local airborne=unit:IsAir()
    local inzone=unit:IsInZone(self.zoneCCA)
    local friendly=self:GetCoalition()==unit:GetCoalition()
    
    -- Check if this an aircraft and that it is airborne and closing in.
    if inzone then
    
      local group=unit:GetGroup()
      local groupname=group:GetName()
      
      if insideCCA[groupname]==nil and groupname~=self.group:GetName() then
        insideCCA[groupname]=group
      end
      
    end
  end
  
  -- Find out if any known intruder is not in the CCA any more.
  for i=#self.intruders,1,-1 do
    local intruder=self.intruders[i] --#SKIPPER.Intruder
    
    -- Loop over current groups in CCA.
    local gotit=false
    for groupname,_group in pairs(insideCCA) do
      local group=_group --Wrapper.Group#GROUP
      
      if groupname==intruder.groupname then
        gotit=true
      end
    end
    
    if not gotit then
      table.remove(self.intruders, i)
    end
      
  end
  
  for groupname,_group in pairs(insideCCA) do
    local group=_group --Wrapper.Group#GROUP

    -- Find out if any known intruder is not in the CCA any more.
    local gotit=false
    for i=1,#self.intruders do
      local intruder=self.intruders[i] --#SKIPPER.Intruder
      if groupname==intruder.groupname then
        gotit=true
      end      
    end
    
    if not gotit then

      -- Get thread level.
      local tl, tt=group:GetThreatLevel()

      -- Create a new intruder table.
      local intruder={} --#SKIPPER.Intruder      
      intruder.coalition=group:GetCoalition()
      intruder.group=group
      intruder.threadlevel=tl
      intruder.threadtext=tt
      intruder.time0=timer.getAbsTime()
      intruder.dist0=self:GetCoordinate():Get2DDistance(group:GetCoordinate())
      intruder.groupname=groupname
      intruder.typename=group:GetTypeName()
      intruder.category=group:GetCategory()
      intruder.categoryname=group:GetCategoryName()

      -- Add intruder to list.
      table.insert(self.intruders, intruder)
      
    end    
  end
  
  
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Patrol carrier.
-- @param #SKIPPER self
-- @return #SKIPPER self
function SKIPPER:_InitWaypoints()

  -- Waypoints of group.
  local Waypoints=self.group:GetTemplateRoutePoints()

  -- Init array.
  self.waypoints={}

  -- Set waypoint table.
  for i,point in ipairs(Waypoints) do
  
    -- Coordinate of the waypoint
    local coord=COORDINATE:New(point.x, point.alt, point.y)
    
    -- Set velocity of the coordinate.
    coord:SetVelocity(point.speed)
    
    -- Add to table.
    table.insert(self.waypoints, coord)
    
    -- Debug info.
    if self.Debug then
      coord:MarkToAll(string.format("Carrier Waypoint %d, Speed=%.1f knots", i, UTILS.MpsToKnots(point.speed)))
    end
    
  end
  
  return self
end

--- Patrol carrier.
-- @param #SKIPPER self
-- @param #number n Next waypoint number.
-- @return #SKIPPER self
function SKIPPER:_PatrolRoute(n)

  -- Get next waypoint coordinate and number.
  local nextWP, N=self:_GetNextWaypoint()
  
  -- Default resume is to next waypoint.
  n=n or N

  -- Get carrier group.
  local CarrierGroup=self.group
  
  -- Waypoints table.
  local Waypoints={}
  
  -- Create a waypoint from the current coordinate.
  local wp=self:GetCoordinate():WaypointGround(CarrierGroup:GetVelocityKMH())
  
  -- Add current position as first waypoint.
  table.insert(Waypoints, wp)
  
  -- Loop over waypoints.
  for i=n,#self.waypoints do
    local coord=self.waypoints[i] --Core.Point#COORDINATE
  
    -- Create a waypoint from the coordinate.
    local wp=coord:WaypointGround(UTILS.MpsToKmph(coord.Velocity))
  
    -- Passing waypoint taskfunction
    local TaskPassingWP=CarrierGroup:TaskFunction("SKIPPER._PassingWaypoint", self, i, #self.waypoints)
    
    -- Call task function when carrier arrives at waypoint.
    CarrierGroup:SetTaskWaypoint(wp, TaskPassingWP)

    --     
    table.insert(Waypoints, wp)
  end

  -- Route carrier group.
  CarrierGroup:Route(Waypoints)
  
  return self
end

--- Function called when a group is passing a waypoint.
--@param Wrapper.Group#GROUP group Group that passed the waypoint.
--@param #SKIPPER skipper skipper object.
--@param #number i Waypoint number that has been reached.
--@param #number final Final waypoint number.
function SKIPPER._PassingWaypoint(group, skipper, i, final)

  -- Debug message.
  local text=string.format("Group %s passing waypoint %d of %d.", group:GetName(), i, final)
  
  -- Debug smoke and marker.
  if skipper.Debug and false then
    local pos=group:GetCoordinate()
    pos:SmokeRed()
    local MarkerID=pos:MarkToAll(string.format("Group %s reached waypoint %d", group:GetName(), i))
  end
  
  -- Debug message.
  MESSAGE:New(text,10):ToAllIf(skipper.Debug)
  skipper:T(skipper.lid..text)
  
  -- Set current waypoint.
  skipper.currentwp=i
  
  -- Passing Waypoint event.
  --skipper:PassingWaypoint(i)
  
  -- If final waypoint reached, do route all over again.
  if i==final and final>1 and skipper.adinfinitum then
    skipper:_PatrolRoute(i)
  end
end

--- Get next waypoint of the carrier.
-- @param #SKIPPER self
-- @return Core.Point#COORDINATE Coordinate of the next waypoint.
-- @return #number Number of waypoint.
function SKIPPER:_GetNextWaypoint()

  -- Next waypoint.  
  local Nextwp=nil
  if self.currentwp==#self.waypoints then
    Nextwp=1
  else
    Nextwp=self.currentwp+1
  end
  
  -- Debug output
  local text=string.format("Current WP=%d/%d, next WP=%d", self.currentwp, #self.waypoints, Nextwp)
  self:T2(self.lid..text)
  
  -- Next waypoint.
  local nextwp=self.waypoints[Nextwp] --Core.Point#COORDINATE

  return nextwp,Nextwp
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Menu Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Patrol carrier.
-- @param #SKIPPER self
-- @return #SKIPPER self
function SKIPPER:_SetMenuCoalition()

  local Coalition=self:GetCoalition()

  local menu={}

  menu.Skipper=MENU_COALITION:New(Coalition, "Skipper")
  
  menu.SetROE       = MENU_COALITION:New(Coalition, "Set ROE", menu.Skipper)
  menu.SetROE_Hold  = MENU_COALITION_COMMAND:New(Coalition, "Weapon Hold", menu.SetROE, self._SetROE, self, "Hold")
  menu.SetROE_Free  = MENU_COALITION_COMMAND:New(Coalition, "Weapon Free", menu.SetROE, self._SetROE, self, "Free")
  menu.SetROE_Return= MENU_COALITION_COMMAND:New(Coalition, "Return Fire", menu.SetROE, self._SetROE, self, "Return")
  
  -- Alarm state does not seem to apply for ships.
  --menu.SetROE_Green = MENU_COALITION_COMMAND:New(Coalition, "State Green", menu.SetROE, self._SetALS, self, "Green")
  --menu.SetROE_Red   = MENU_COALITION_COMMAND:New(Coalition, "State Red",   menu.SetROE, self._SetALS, self, "Red")
  --menu.SetROE_Auto  = MENU_COALITION_COMMAND:New(Coalition, "State Auto",  menu.SetROE, self._SetALS, self, "Auto")
    
  menu.SetSpeed     = MENU_COALITION:New(Coalition, "Set Speed", menu.Skipper)
  menu.SetSpeed_00  = MENU_COALITION_COMMAND:New(Coalition, "Hold Position", menu.SetSpeed, self._SetSpeed, self, 0)
  menu.SetSpeed_05  = MENU_COALITION_COMMAND:New(Coalition, "5 knots",       menu.SetSpeed, self._SetSpeed, self, 5)
  menu.SetSpeed_10  = MENU_COALITION_COMMAND:New(Coalition, "10 knots",      menu.SetSpeed, self._SetSpeed, self, 10)
  menu.SetSpeed_15  = MENU_COALITION_COMMAND:New(Coalition, "15 knots",      menu.SetSpeed, self._SetSpeed, self, 15)
  menu.SetSpeed_20  = MENU_COALITION_COMMAND:New(Coalition, "20 knots",      menu.SetSpeed, self._SetSpeed, self, 20)
  menu.SetSpeed_25  = MENU_COALITION_COMMAND:New(Coalition, "25 knots",      menu.SetSpeed, self._SetSpeed, self, 25)
  menu.SetSpeed_30  = MENU_COALITION_COMMAND:New(Coalition, "30 knots",      menu.SetSpeed, self._SetSpeed, self, 30)
  menu.SetSpeed_99  = MENU_COALITION_COMMAND:New(Coalition, "Restore Route", menu.SetSpeed, self.CarrierResume, self)
  
  menu.Defence           = MENU_COALITION:New(Coalition, "Defence", menu.Skipper)
  menu.Defence_Ammo      = MENU_COALITION_COMMAND:New(Coalition, "Report Ammo", menu.Defence, self.arty.GetAmmo, self.arty, true)
  menu.Defence_Intruders = MENU_COALITION_COMMAND:New(Coalition, "Report Intruders", menu.Defence, self._ListIntruders, self)
  
  if self.airboss then
    menu.Recovery=MENU_COALITION:New(Coalition, "Recovery", menu.Skipper)
    
    -- Set wind on deck.
    menu.SetWoD    = MENU_COALITION:New(Coalition, "Wind on Deck", menu.Recovery)
    menu.SetWoD_10 = MENU_COALITION_COMMAND:New(Coalition, "10 knots", menu.SetWoD, self._SetWoD, self, 10)
    menu.SetWoD_15 = MENU_COALITION_COMMAND:New(Coalition, "15 knots", menu.SetWoD, self._SetWoD, self, 15)
    menu.SetWoD_20 = MENU_COALITION_COMMAND:New(Coalition, "20 knots", menu.SetWoD, self._SetWoD, self, 20)
    menu.SetWoD_25 = MENU_COALITION_COMMAND:New(Coalition, "25 knots", menu.SetWoD, self._SetWoD, self, 25)
    menu.SetWoD_30 = MENU_COALITION_COMMAND:New(Coalition, "30 knots", menu.SetWoD, self._SetWoD, self, 30)
    
    -- Set Duration.
    menu.SetRtime    = MENU_COALITION:New(Coalition, "Duration", menu.Recovery)    
    menu.SetRtime_15 = MENU_COALITION_COMMAND:New(Coalition, "15 min", menu.SetRtime, self._SetRtime, self, 15)
    menu.SetRtime_30 = MENU_COALITION_COMMAND:New(Coalition, "30 min", menu.SetRtime, self._SetRtime, self, 30)
    menu.SetRtime_45 = MENU_COALITION_COMMAND:New(Coalition, "45 min", menu.SetRtime, self._SetRtime, self, 45)
    menu.SetRtime_60 = MENU_COALITION_COMMAND:New(Coalition, "60 min", menu.SetRtime, self._SetRtime, self, 60)
    menu.SetRtime_90 = MENU_COALITION_COMMAND:New(Coalition, "90 min", menu.SetRtime, self._SetRtime, self, 90)
    
    -- Start/Stop.
    menu.SetUturn = MENU_COALITION_COMMAND:New(Coalition, "U-turn On/Off",  menu.Recovery, self._SetUturn, self)
    menu.CaseI    = MENU_COALITION_COMMAND:New(Coalition, "Start CASE I",   menu.Recovery, self._StartCaseX, self, 1)
    menu.CaseII   = MENU_COALITION_COMMAND:New(Coalition, "Start CASE II",  menu.Recovery, self._StartCaseX, self, 2)
    menu.CaseIII  = MENU_COALITION_COMMAND:New(Coalition, "Start CASE III", menu.Recovery, self._StartCaseX, self, 3)
    menu.Rstop    = MENU_COALITION_COMMAND:New(Coalition, "Stop Recovery",  menu.Recovery, self._Rstop, self)
  end
  
end

--- Intruders.
-- @param #SKIPPER self
function SKIPPER:_ListIntruders()

  local text="Current Intruders:"
  
  for i,_intruder in pairs(self.intruders) do
    local intruder=_intruder --#SKIPPER.Intruder
    text=text..string.format("\n[%d] %s*%d, %s [%d/10]", i, intruder.typename, #intruder.group:GetUnits(), intruder.categoryname, intruder.threadlevel)
  end
  
  if #self.intruders==0 then
    text=text.." none."
  end
  
  MESSAGE:New(text, 10, self.ClassName):ToCoalition(self:GetCoalition())
end

--- Start Case X recovery.
-- @param #SKIPPER self
-- @param #number case Recovery case (1,2,3).
function SKIPPER:_StartCaseX(case)

  if self.airboss then
  
    self.airboss.skipperTime=self.airboss.skipperTime or 30
    self.airboss.skipperSpeed=self.airboss.skipperSpeed or 25    
    if self.airboss.skipperUturn==nil then
      self.airboss.skipperUturn=false
    end
  
    -- Inform player.
    local text=string.format("Case %d recovery will start in 5 min for %d min. Wind on deck %d knots. U-turn=%s.", case, self.airboss.skipperTime, self.airboss.skipperSpeed, tostring(self.airboss.skipperUturn))
    
    if self.airboss:IsRecovering() then
      text="negative, carrier is already recovering."
      MESSAGE:New(string.format(text), 5, self.ClassName):ToCoalition(self:GetCoalition())
      return
    end

    -- Recovery staring in 5 min for 30 min.
    local t0=timer.getAbsTime()+5*60
    local t9=t0+self.airboss.skipperTime*60
    local C0=UTILS.SecondsToClock(t0)
    local C9=UTILS.SecondsToClock(t9)
  
    -- Carrier will turn into the wind. Wind on deck 25 knots. U-turn on.
    self.airboss:AddRecoveryWindow(C0, C9, case, 30, true, self.airboss.skipperSpeed, self.airboss.skipperUturn)
    
    MESSAGE:New(string.format(text), 5, self.ClassName):ToCoalition(self:GetCoalition())
  end

end



--- Toggle recovery U-turn option.
-- @param #SKIPPER self
function SKIPPER:_SetUturn()

  if self.airboss then
    self.airboss.skipperUturn=not self.airboss.skipperUturn
    
    MESSAGE:New(string.format("Recovery U-turn is now %s.", tostring(self.airboss.skipperUturn)), 5, self.ClassName):ToCoalition(self:GetCoalition())
  end

end

--- Set manual recovery duration.
-- @param #SKIPPER self
-- @param #number time Duration in minutes.
function SKIPPER:_SetRtime(time)

  if self.airboss then
    self.airboss.skipperTime=time
    
    MESSAGE:New(string.format("Recovery duration set to %d min.", time), 5, self.ClassName):ToCoalition(self:GetCoalition())
  end

end


--- Set wind on deck for manual recovery start.
-- @param #SKIPPER self
-- @param #number speed Speed in knots.
function SKIPPER:_SetWoD(speed)

  if self.airboss then
    self.airboss.skipperSpeed=speed
    
    MESSAGE:New(string.format("Wind on Deck set to %d knots.", speed), 5, self.ClassName):ToCoalition(self:GetCoalition())
  end

end

--- Set new speed for all waypoints.
-- @param #SKIPPER self
-- @param #number speed Speed in knots.
function SKIPPER:_SetSpeed(speed)

  -- Loop over waypoints.
  for n=1,#self.waypoints do
    local coord=self.waypoints[n] --Core.Point#COORDINATE

    coord.Velocity=UTILS.KnotsToMps(speed)  
  end
  
  self:_PatrolRoute()

end

--- Set rules of engagement.
-- @param #SKIPPER self
-- @param #string roe "Hold", "Free", "Return".
function SKIPPER:_SetROE(roe)

  if roe=="Hold" then
    self.group:OptionROEHoldFire()
  elseif roe=="Free" then
    self.group:OptionROEOpenFire()
  elseif roe=="Return" then  
    self.group:OptionROEReturnFire()
  end

  MESSAGE:New(string.format("ROE set to %s", roe), 5, self.ClassName):ToCoalition(self:GetCoalition())
end

--- Set alaram state.
-- @param #SKIPPER self
-- @param #string state "Green", "Red", "Auto".
function SKIPPER:_SetALS(state)

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
-- @param #SKIPPER self
function SKIPPER:CarrierHold()
  env.info("Carrier Hold!")

  -- Get current position.
  local pos=self.group:GetCoordinate()
  
  -- Create a new waypoint.
  local wp=pos:WaypointGround(0)
  
  -- Create new route consisting of only this position ==> Stop!
  self.group:Route({wp})
  
  MESSAGE:New(string.format("Carrier is holding current position."), 5, self.ClassName):ToCoalition(self:GetCoalition())
end

--- Function to stop the carrier.
-- @param #SKIPPER self
function SKIPPER:CarrierResume()
  env.info("Carrier Resume Route!")
  
  self:_InitWaypoints()
  
  local nextWP,n=self:_GetNextWaypoint()
  
  self:_PatrolRoute(n)
  
  MESSAGE:New(string.format("Carrier is resuming route to waypoint #%d.", n), 5, self.ClassName):ToCoalition(self:GetCoalition())
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
