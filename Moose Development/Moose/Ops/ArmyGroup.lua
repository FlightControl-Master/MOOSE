--- **Ops** - Enhanced Ground Group.
-- 
-- **Main Features:**
--
--    * Dynamically add and remove waypoints.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.ArmyGroup
-- @image OPS_ArmyGroup.png


--- ARMYGROUP class.
-- @type ARMYGROUP
-- @field #boolean adinfinitum Resume route at first waypoint when final waypoint is reached.
-- @field #boolean formationPerma Formation that is used permanently and overrules waypoint formations.
-- @extends Ops.OpsGroup#OPSGROUP

--- *Your soul may belong to Jesus, but your ass belongs to the marines.* -- Eugene B. Sledge
--
-- ===
--
-- ![Banner Image](..\Presentations\OPS\ArmyGroup\_Main.png)
--
-- # The ARMYGROUP Concept
-- 
-- This class enhances naval groups.
-- 
-- @field #ARMYGROUP
ARMYGROUP = {
  ClassName       = "ARMYGROUP",
  formationPerma  = nil,
}

--- Army group element.
-- @type ARMYGROUP.Element
-- @field #string name Name of the element, i.e. the unit.
-- @field #string typename Type name.

--- Army Group version.
-- @field #string version
ARMYGROUP.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 
-- TODO: A lot.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new ARMYGROUP class object.
-- @param #ARMYGROUP self
-- @param #string GroupName Name of the group.
-- @return #ARMYGROUP self
function ARMYGROUP:New(GroupName)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, OPSGROUP:New(GroupName)) -- #ARMYGROUP
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("ARMYGROUP %s | ", self.groupname)
  
  -- Defaults
  self:SetDefaultROE()
  self:SetDefaultAlarmstate()
  self:SetDetection()
  self:SetPatrolAdInfinitum(false)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "FullStop",         "Holding")     -- Hold position.
  self:AddTransition("*",             "Cruise",           "Cruising")    -- Hold position.
  
  self:AddTransition("*",             "Detour",           "OnDetour")    -- Make a detour to a coordinate and resume route afterwards.
  self:AddTransition("OnDetour",      "DetourReached",    "Cruising")    -- Group reached the detour coordinate.
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Stop". Stops the ARMYGROUP and all its event handlers.
  -- @param #ARMYGROUP self

  --- Triggers the FSM event "Stop" after a delay. Stops the ARMYGROUP and all its event handlers.
  -- @function [parent=#ARMYGROUP] __Stop
  -- @param #ARMYGROUP self
  -- @param #number delay Delay in seconds.
  
  -- TODO: Add pseudo functions.


  -- Init waypoints.
  self:InitWaypoints()
  
  -- Initialize the group.
  self:_InitGroup()

  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  
  -- Handle events:
  self:HandleEvent(EVENTS.Birth,      self.OnEventBirth)
  self:HandleEvent(EVENTS.Dead,       self.OnEventDead)
  self:HandleEvent(EVENTS.RemoveUnit, self.OnEventRemoveUnit)  
  
  -- Start the status monitoring.
  self:__Status(-1)
  
  -- Start queue update timer.
  self.timerQueueUpdate=TIMER:New(self._QueueUpdate, self):Start(2, 5)  
  
  -- Start check zone timer.
  self.timerCheckZone=TIMER:New(self._CheckInZones, self):Start(2, 30)
   
  return self  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Group patrols ad inifintum. If the last waypoint is reached, it will go to waypoint one and repeat its route.
-- @param #ARMYGROUP self
-- @param #boolean switch If true or nil, patrol until the end of time. If false, go along the waypoints once and stop.
-- @return #ARMYGROUP self
function ARMYGROUP:SetPatrolAdInfinitum(switch)
  if switch==false then
    self.adinfinitum=false
  else
    self.adinfinitum=true
  end
  return self
end

--- Get coordinate of the closest road.
-- @param #ARMYGROUP self
-- @return Core.Point#COORDINATE Coordinate of a road closest to the group.
function ARMYGROUP:GetClosestRoad()
  return self:GetCoordinate():GetClosestPointToRoad()
end


--- Add a *scheduled* task to fire at a given coordinate.
-- @param #ARMYGROUP self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the target.
-- @param #string Clock Time when to start the attack.
-- @param #number Radius Radius in meters. Default 100 m.
-- @param #number Nshots Number of shots to fire. Default 3.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #number Prio Priority of the task.
-- @return Ops.OpsGroup#OPSGROUP.Task The task table.
function ARMYGROUP:AddTaskFireAtPoint(Coordinate, Clock, Radius, Nshots, WeaponType, Prio)

  local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, Coordinate:GetVec2(), Radius, Nshots, WeaponType)

  local task=self:AddTask(DCStask, Clock, nil, Prio)

  return task
end

--- Add a *waypoint* task to fire at a given coordinate.
-- @param #ARMYGROUP self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the target.
-- @param Ops.OpsGroup#OPSGROUP.Waypoint Waypoint Where the task is executed. Default is next waypoint.
-- @param #number Radius Radius in meters. Default 100 m.
-- @param #number Nshots Number of shots to fire. Default 3.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #number Prio Priority of the task.
function ARMYGROUP:AddTaskWaypointFireAtPoint(Coordinate, Waypoint, Radius, Nshots, WeaponType, Prio)

  Waypoint=Waypoint or self:GetWaypointNext()

  local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, Coordinate:GetVec2(), Radius, Nshots, WeaponType)

  self:AddTaskWaypoint(DCStask, Waypoint, nil, Prio)

end

--- Add a *scheduled* task.
-- @param #ARMYGROUP self
-- @param Wrapper.Group#GROUP TargetGroup Target group.
-- @param #number WeaponExpend How much weapons does are used.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #string Clock Time when to start the attack.
-- @param #number Prio Priority of the task.
function ARMYGROUP:AddTaskAttackGroup(TargetGroup, WeaponExpend, WeaponType, Clock, Prio)

  local DCStask=CONTROLLABLE.TaskAttackGroup(nil, TargetGroup, WeaponType, WeaponExpend, AttackQty, Direction, Altitude, AttackQtyLimit, GroupAttack)

  self:AddTask(DCStask, Clock, nil, Prio)

end

--- Check if the group is currently holding its positon.
-- @param #ARMYGROUP self
-- @return #boolean If true, group was ordered to hold.
function ARMYGROUP:IsHolding()
  return self:Is("Holding")
end

--- Check if the group is currently cruising.
-- @param #ARMYGROUP self
-- @return #boolean If true, group cruising.
function ARMYGROUP:IsCruising()
  return self:Is("Cruising")
end

--- Check if the group is currently on a detour.
-- @param #ARMYGROUP self
-- @return #boolean If true, group is on a detour
function ARMYGROUP:IsOnDetour()
  return self:Is("OnDetour")
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

---- Update status.
-- @param #ARMYGROUP self
function ARMYGROUP:onbeforeStatus(From, Event, To)

  if self:IsDead() then  
    self:T(self.lid..string.format("Onbefore Status DEAD ==> false"))
    return false   
  elseif self:IsStopped() then
    self:T(self.lid..string.format("Onbefore Status STOPPED ==> false"))
    return false
  end

  return true
end

--- Update status.
-- @param #ARMYGROUP self
function ARMYGROUP:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  
  if self:IsAlive() then

    ---
    -- Detection
    ---
    
    -- Check if group has detected any units.
    if self.detectionOn then
      self:_CheckDetectedUnits()
    end

    -- Update position etc.    
    self:_UpdatePosition()
    
    -- Check if group got stuck.
    self:_CheckStuck()
    
    if self.verbose>=1 then
  
      -- Get number of tasks and missions.
      local nTaskTot, nTaskSched, nTaskWP=self:CountRemainingTasks()
      local nMissions=self:CountRemainingMissison()
      
      local roe=self:GetROE()
      local alarm=self:GetAlarmstate()
      local speed=UTILS.MpsToKnots(self.velocity)
      local speedEx=UTILS.MpsToKnots(self:GetExpectedSpeed())
      local formation=self.option.Formation
    
      -- Info text.
      local text=string.format("%s: Wp=%d/%d-->%d Speed=%.1f (%d) Heading=%03d ROE=%d Alarm=%d Formation=%s Tasks=%d Missions=%d", 
      fsmstate, self.currentwp, #self.waypoints, self:GetWaypointIndexNext(), speed, speedEx, self.heading, roe, alarm, formation, nTaskTot, nMissions)
      self:I(self.lid..text)
      
    end
    
  else

    -- Info text.
    local text=string.format("State %s: Alive=%s", fsmstate, tostring(self:IsAlive()))
    self:T2(self.lid..text)
  
  end


  ---
  -- Tasks & Missions
  ---

  self:_PrintTaskAndMissionStatus()


  -- Next status update.
  self:__Status(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "ElementSpawned" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #ARMYGROUP.Element Element The group element.
function ARMYGROUP:onafterElementSpawned(From, Event, To, Element)
  self:T(self.lid..string.format("Element spawned %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.SPAWNED)

end

--- On after "Spawned" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterSpawned(From, Event, To)
  self:T(self.lid..string.format("Group spawned!"))

  -- Update position.
  self:_UpdatePosition()

  if self.ai then
  
    -- Set default ROE.
    self:SwitchROE(self.option.ROE)
    
    -- Set default Alarm State.
    self:SwitchAlarmstate(self.option.Alarm)
    
    -- Turn TACAN beacon on.
    if self.tacan.On then
      self:_SwitchTACAN(self.tacan)
    end

    -- Turn on the radio.
    if self.radioLast then
      self:SwitchRadio(self.radioLast.Freq, self.radioLst.Modu)
    end
    
  end
  
  -- Update route.
  self:Cruise()
  
end

--- On after "UpdateRoute" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number. Default is next waypoint.
-- @param #number Speed Speed in knots. Default cruise speed.
-- @param #number Formation Formation of the group.
function ARMYGROUP:onafterUpdateRoute(From, Event, To, n, Speed, Formation)

  -- Update route from this waypoint number onwards.
  n=n or self:GetWaypointIndexNext(self.adinfinitum)
  
  -- Update waypoint tasks, i.e. inject WP tasks into waypoint table.
  self:_UpdateWaypointTasks(n)

  -- Waypoints.
  local waypoints={}
  
  -- Total number of waypoints
  local N=#self.waypoints

  -- Add remaining waypoints to route.
  for i=n, N do
  
    -- Copy waypoint.
    local wp=UTILS.DeepCopy(self.waypoints[i]) --Ops.OpsGroup#OPSGROUP.Waypoint
    
    if i==n then
    
      ---
      -- Next Waypoint
      ---
    
      if Speed then
        wp.speed=UTILS.KnotsToMps(Speed)
      else
        -- Take default waypoint speed.
      end
      
      if self.formationPerma then
        --if self.formationPerma==ENUMS.Formation.Vehicle.OnRoad then
          wp.action=self.formationPerma
        --end
      elseif Formation then 
        wp.action=Formation
      end
      
      -- Current set formation.
      self.option.Formation=wp.action
      
      -- Current set speed in m/s.
      self.speedWp=wp.speed
    
    else

      ---
      -- Later Waypoint(s)
      ---
    
      if self.formationPerma then
        wp.action=self.formationPerma
      else
        -- Take default waypoint speed.
      end
      
    end
    
    if wp.roaddist>100 and wp.action==ENUMS.Formation.Vehicle.OnRoad then
    
      -- Waypoint is actually off road!
      wp.action=ENUMS.Formation.Vehicle.OffRoad

      -- Add "On Road" waypoint in between.
      local wproad=wp.roadcoord:WaypointGround(wp.speed, ENUMS.Formation.Vehicle.OnRoad)
      table.insert(waypoints, wproad)     
    end    
     
    -- Debug info.
    self:T(string.format("WP %d %s: Speed=%d m/s, alt=%d m, Action=%s", i, wp.type, wp.speed, wp.alt, wp.action))
        
    -- Add waypoint.
    table.insert(waypoints, wp)
  end


  -- Current waypoint.
  local current=self:GetCoordinate():WaypointGround(UTILS.MpsToKmph(self.speedWp), self.option.Formation)
  table.insert(waypoints, 1, current)
  table.insert(waypoints, 1, current)  -- Seems to be better to add this twice. Otherwise, the passing waypoint functions is triggered to early!

  if #waypoints>2 then
  
    self:T(self.lid..string.format("Updateing route: WP %d-->%d-->%d (#%d), Speed=%.1f knots, Formation=%s", 
    self.currentwp, n, #self.waypoints, #waypoints-2, UTILS.MpsToKnots(self.speedWp), tostring(self.option.Formation)))

    -- Route group to all defined waypoints remaining.
    self:Route(waypoints)
    
  else
  
    ---
    -- No waypoints left
    ---
  
    self:E(self.lid..string.format("WARNING: No waypoints left ==> Full Stop!"))    
    self:FullStop()
        
  end

end

--- On after "Detour" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE Coordinate Coordinate where to go.
-- @param #number Speed Speed in knots. Default cruise speed.
-- @param #number Formation Formation of the group.
-- @param #number ResumeRoute If true, resume route after detour point was reached. If false, the group will stop at the detour point and wait for futher commands.
function ARMYGROUP:onafterDetour(From, Event, To, Coordinate, Speed, Formation, ResumeRoute)

  -- Speed in knots.
  Speed=Speed or self:GetSpeedCruise()
  
  -- ID of current waypoint.
  local uid=self:GetWaypointCurrent().uid
  
  -- Add waypoint after current.
  local wp=self:AddWaypoint(Coordinate, Speed, uid, Formation, true)
  
  -- Set if we want to resume route after reaching the detour waypoint.
  if ResumeRoute then
    wp.detour=1
  else
    wp.detour=0
  end

end

--- On after "DetourReached" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterDetourReached(From, Event, To)
  self:I(self.lid.."Group reached detour coordinate.")
end


--- On after "FullStop" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterFullStop(From, Event, To)

  -- Get current position.
  local pos=self:GetCoordinate()
  
  -- Create a new waypoint.
  local wp=pos:WaypointGround(0)
  
  -- Create new route consisting of only this position ==> Stop!
  self:Route({wp})

end

--- On after "Cruise" event.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Speed Speed in knots.
-- @param #number Formation Formation.
function ARMYGROUP:onafterCruise(From, Event, To, Speed, Formation)

  self:__UpdateRoute(-1, nil, Speed, Formation)

end

--- On after Start event. Starts the ARMYGROUP FSM and event handlers.
-- @param #ARMYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function ARMYGROUP:onafterStop(From, Event, To)

  -- Handle events:
  self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.Dead)
  self:UnHandleEvent(EVENTS.RemoveUnit)
  
  -- Call OPSGROUP function.
  self:GetParent(self).onafterStop(self, From, Event, To)  
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Events DCS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event function handling the birth of a unit.
-- @param #ARMYGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function ARMYGROUP:OnEventBirth(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName
    
    if self.respawning then
    
      local function reset()
        self.respawning=nil
      end
      
      -- Reset switch in 1 sec. This should allow all birth events of n>1 groups to have passed.
      -- TODO: Can I do this more rigorously?
      self:ScheduleOnce(1, reset)
    
    else
          
      -- Get element.
      local element=self:GetElementByName(unitname)

      -- Set element to spawned state.
      self:T3(self.lid..string.format("EVENT: Element %s born ==> spawned", element.name))            
      self:ElementSpawned(element)
      
    end    
    
  end

end

--- Event function handling the crash of a unit.
-- @param #ARMYGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function ARMYGROUP:OnEventDead(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    self:T(self.lid..string.format("EVENT: Unit %s dead!", EventData.IniUnitName))
    
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:T(self.lid..string.format("EVENT: Element %s dead ==> destroyed", element.name))
      self:ElementDestroyed(element)
    end
    
  end

end

--- Event function handling the crash of a unit.
-- @param #ARMYGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function ARMYGROUP:OnEventRemoveUnit(EventData)

  -- Check that this is the right group.
  if EventData and EventData.IniGroup and EventData.IniUnit and EventData.IniGroupName and EventData.IniGroupName==self.groupname then
    local unit=EventData.IniUnit
    local group=EventData.IniGroup
    local unitname=EventData.IniUnitName

    -- Get element.
    local element=self:GetElementByName(unitname)

    if element then
      self:T(self.lid..string.format("EVENT: Element %s removed ==> dead", element.name))
      self:ElementDead(element)
    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Routing
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add an a waypoint to the route.
-- @param #ARMYGROUP self
-- @param Core.Point#COORDINATE Coordinate The coordinate of the waypoint. Use COORDINATE:SetAltitude(altitude) to define the altitude.
-- @param #number Speed Speed in knots. Default is default cruise speed or 70% of max speed.
-- @param #number AfterWaypointWithID Insert waypoint after waypoint given ID. Default is to insert as last waypoint.
-- @param #number Formation Formation the group will use.
-- @param #boolean Updateroute If true or nil, call UpdateRoute. If false, no call.
-- @return Ops.OpsGroup#OPSGROUP.Waypoint Waypoint table.
function ARMYGROUP:AddWaypoint(Coordinate, Speed, AfterWaypointWithID, Formation, Updateroute)

  -- Set waypoint index.
  local wpnumber=self:GetWaypointIndexAfterID(AfterWaypointWithID)

  -- Check if final waypoint is still passed.  
  if wpnumber>self.currentwp then
    self.passedfinalwp=false
  end
  
  -- Speed in knots.
  Speed=Speed or self:GetSpeedCruise()

  -- Create a Naval waypoint.
  local wp=Coordinate:WaypointGround(UTILS.KnotsToKmph(Speed), Formation)
  
  -- Create waypoint data table.
  local waypoint=self:_CreateWaypoint(wp)
  
  -- Add waypoint to table.
  self:_AddWaypoint(waypoint, wpnumber)
  
  -- Get closest point to road.
  waypoint.roadcoord=Coordinate:GetClosestPointToRoad(false)
  if waypoint.roadcoord then
    waypoint.roaddist=Coordinate:Get2DDistance(waypoint.roadcoord)
  else
    waypoint.roaddist=1000*1000 --1000 km.
  end
  
  -- Debug info.
  self:T(self.lid..string.format("Adding waypoint UID=%d (index=%d), Speed=%.1f knots, Dist2Road=%d m, Action=%s", waypoint.uid, wpnumber, Speed, waypoint.roaddist, waypoint.action))
  
  -- Update route.
  if Updateroute==nil or Updateroute==true then
    self:_CheckGroupDone(1)
  end
  
  return waypoint
end

--- Initialize group parameters. Also initializes waypoints if self.waypoints is nil.
-- @param #ARMYGROUP self
-- @return #ARMYGROUP self
function ARMYGROUP:_InitGroup()

  -- First check if group was already initialized.
  if self.groupinitialized then
    self:E(self.lid.."WARNING: Group was already initialized!")
    return
  end

  -- Get template of group.
  self.template=self.group:GetTemplate()

  -- Define category.
  self.isAircraft=false
  self.isNaval=false
  self.isGround=true
  
  -- Ships are always AI.
  self.ai=true
  
  -- Is (template) group late activated.
  self.isLateActivated=self.template.lateActivation
  
  -- Ground groups cannot be uncontrolled.
  self.isUncontrolled=false
  
  -- Max speed in km/h.
  self.speedMax=self.group:GetSpeedMax()
  
  -- Cruise speed in km/h
  self.speedCruise=self.speedMax*0.7
  
  -- Group ammo.
  self.ammo=self:GetAmmoTot()
  
  -- Radio parameters from template.
  self.radio.On=false  -- Radio is always OFF for ground.
  self.radio.Freq=133
  self.radio.Modu=radio.modulation.AM
  
  -- Set default radio.
  self:SetDefaultRadio(self.radio.Freq, self.radio.Modu, self.radio.On)
  
  -- Set default formation from first waypoint.
  self.option.Formation=self:GetWaypoint(1).action
  self.optionDefault.Formation=self.option.Formation
  
  -- Units of the group.
  local units=self.group:GetUnits()
  
  for _,_unit in pairs(units) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    local element={} --#ARMYGROUP.Element
    element.name=unit:GetName()
    element.typename=unit:GetTypeName()
    element.status=OPSGROUP.ElementStatus.INUTERO
    element.unit=unit
    table.insert(self.elements, element)
    
    self:GetAmmoUnit(unit, false)
    
    if unit:IsAlive() then      
      self:ElementSpawned(element)
    end
    
  end

  -- Get first unit. This is used to extract other parameters.
  local unit=self.group:GetUnit(1)
  
  if unit then
    
    self.descriptors=unit:GetDesc()
    
    self.actype=unit:GetTypeName()
    
    -- Debug info.
    if self.verbose>=1 then
      local text=string.format("Initialized Army Group %s:\n", self.groupname)
      text=text..string.format("Unit type    = %s\n", self.actype)
      text=text..string.format("Speed max    = %.1f Knots\n", UTILS.KmphToKnots(self.speedMax))
      text=text..string.format("Speed cruise = %.1f Knots\n", UTILS.KmphToKnots(self.speedCruise))
      text=text..string.format("Elements     = %d\n", #self.elements)
      text=text..string.format("Waypoints    = %d\n", #self.waypoints)
      text=text..string.format("Radio        = %.1f MHz %s %s\n", self.radio.Freq, UTILS.GetModulationName(self.radio.Modu), tostring(self.radio.On))
      text=text..string.format("Ammo         = %d (G=%d/R=%d/M=%d)\n", self.ammo.Total, self.ammo.Guns, self.ammo.Rockets, self.ammo.Missiles)
      text=text..string.format("FSM state    = %s\n", self:GetState())
      text=text..string.format("Is alive     = %s\n", tostring(self:IsAlive()))
      text=text..string.format("LateActivate = %s\n", tostring(self:IsLateActivated()))
      self:I(self.lid..text)
    end
    
    -- Init done.
    self.groupinitialized=true
    
  end
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Option Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Switch to a specific formation.
-- @param #ARMYGROUP self
-- @param #number Formation New formation the group will fly in. Default is the setting of `SetDefaultFormation()`.
-- @param #boolean Permanently If true, formation always used from now on.
-- @return #ARMYGROUP self
function ARMYGROUP:SwitchFormation(Formation, Permanently)

  if self:IsAlive() then
  
    Formation=Formation or self.optionDefault.Formation

    if Permanently then
      self.formationPerma=Formation
    else
      self.formationPerma=nil
    end    
    
    -- Set current formation.
    self.option.Formation=Formation
    
    -- Update route with the new formation.
    self:__UpdateRoute(-1, nil, nil, Formation)
    
    -- Debug info.
    self:T(self.lid..string.format("Switching formation to %s (permanently=%s)", self.option.Formation, tostring(Permanently)))

  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
