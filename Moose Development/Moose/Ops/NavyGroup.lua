--- **Ops** - Enhanced Naval Group.
-- 
-- **Main Features:**
--
--    * Dynamically add and remove waypoints
--    * Let the group steam into the wind.
--    * Command a full stop.
--    * Let a submarine dive and surface.
--     
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.NavyGroup
-- @image OPS_NavyGroup.png


--- NAVYGROUP class.
-- @type NAVYGROUP
-- @extends Ops.OpsGroup#OPSGROUP

--- *Something must be left to chance; nothing is sure in a sea fight above all.* -- Horatio Nelson
--
-- ===
--
-- ![Banner Image](..\Presentations\NAVYGROUP\NavyGroup_Main.jpg)
--
-- # The NAVYGROUP Concept
-- 
-- This class enhances naval groups.
-- 
-- @field #NAVYGROUP
NAVYGROUP = {
  ClassName      = "NAVYGROUP",
}

--- Navy group element.
-- @type NAVYGROUP.Element
-- @field #string name Name of the element, i.e. the unit.
-- @field #string typename Type name.

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
  local self=BASE:Inherit(self, OPSGROUP:New(GroupName)) -- #NAVYGROUP
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("NAVYGROUP %s | ", self.groupname)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "FullStop",         "Holding")     -- Hold position.
  self:AddTransition("*",             "TurnIntoWind",     "*")           -- Hold position.
  self:AddTransition("*",             "Cruise",           "Cruising")    -- Hold position.
  
  self:AddTransition("*",             "Dive",             "Diving")      -- Hold position.
  self:AddTransition("Diving",        "Surface",          "Cruising")    -- Hold position.
  
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
  
  -- Handle events:
  self:HandleEvent(EVENTS.Birth,      self.OnEventBirth)
  self:HandleEvent(EVENTS.Dead,       self.OnEventDead)
  self:HandleEvent(EVENTS.RemoveUnit, self.OnEventRemoveUnit)  
  
  -- Initialize the group.
  self:_InitGroup()
  
  -- Defaults
  self:SetDefaultROE()
  self:SetDetection()
  
  -- Start the status monitoring.
  self:__CheckZone(-1)
  self:__Status(-2)
  self:__QueueUpdate(-3)
   
  return self  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a *scheduled* task.
-- @param #NAVYGROUP self
-- @param Core.Point#COORDINATE Coordinate Coordinate of the target.
-- @param #number Nshots Number of shots to fire. Default 3.
-- @param #number WeaponType Type of weapon. Default auto.
-- @param #string Clock Time when to start the attack.
-- @param #number Prio Priority of the task.
function NAVYGROUP:AddTaskFireAtPoint(Coordinate, Radius, Nshots, WeaponType, Clock, Prio)

  local DCStask=CONTROLLABLE.TaskFireAtPoint(nil, Coordinate:GetVec2(), Radius, Nshots, WeaponType)

  

end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Update status.
-- @param #NAVYGROUP self
function NAVYGROUP:onafterStatus(From, Event, To)

  -- FSM state.
  local fsmstate=self:GetState()
  

  -- Current heading and position of the carrier.
  local hdg=self:GetHeading()
  local pos=self:GetCoordinate()
  local speed=self.group:GetVelocityKNOTS()

  -- Check water is ahead.
  local collision=self:_CheckCollisionCoord(pos:Translate(self.collisiondist or 5000, hdg))

    -- Info text.
  local text=string.format("State %s: Speed=%.1f knots Heading=%03d collision=%s", fsmstate, speed, hdg, tostring(collision))
  self:I(self.lid..text)

  self:__Status(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "ElementSpawned" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #NAVYGROUP.Element Element The group element.
function NAVYGROUP:onafterElementSpawned(From, Event, To, Element)
  self:I(self.lid..string.format("Element spawned %s", Element.name))

  -- Set element status.
  self:_UpdateStatus(Element, OPSGROUP.ElementStatus.SPAWNED)

end

--- On after "Spawned" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterSpawned(From, Event, To)
  self:I(self.lid..string.format("Group spawned!"))

  if self.ai then
  
    -- Set default ROE and ROT options.
    self:SetOptionROE()
    
  end
  
  -- Update route.
  self:__Cruise(-1)
  
end

--- On after "UpdateRoute" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint number. Default is next waypoint.
-- @param #number Speed Speed in knots. Default cruise speed.
-- @param #number Depth Depth in meters. Default 0 meters.
function NAVYGROUP:onafterUpdateRoute(From, Event, To, n, Speed, Depth)

  -- Update route from this waypoint number onwards.
  n=n or self.currentwp+1
  
  -- Update waypoint tasks, i.e. inject WP tasks into waypoint table.
  self:_UpdateWaypointTasks()

  -- Waypoints.
  local waypoints={}
    
  -- Speed.
  local speed=Speed and UTILS.KnotsToKmph(Speed) or self.speedCruise
  
  -- Depth for submarines.
  local depth=Depth or 0
  
  local current=self:GetCoordinate():WaypointNaval(speed, depth)
  table.insert(waypoints, current)
  
  -- Add remaining waypoints to route.
  for i=n, #self.waypoints do
    local wp=self.waypoints[i]
    
    -- Set speed.
    wp.speed=UTILS.KmphToMps(speed)
    
    -- Add waypoint.
    table.insert(waypoints, wp)
  end

  
  if #waypoints>1 then

    -- Route group to all defined waypoints remaining.
    self.group:Route(waypoints, 1)
    
  else
  
    ---
    -- No waypoints left
    ---
  
    self:UpdateRoute(1)
          
  end

end

--- On after "TurnIntoWind" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Duration Duration in seconds.
-- @param #number Speed Speed in knots.
-- @param #boolean Uturn Return to the place we came from.
function NAVYGROUP:onafterTurnIntoWind(From, Event, To, Duration, Speed, Uturn)

  self.turnintowind=timer.getAbsTime()
  
  local headingTo=self:GetCoordinate():GetWind(50)
  
  local distance=UTILS.NMToMeters(1000)
  
  local wp={}
  
  local coord=self:GetCoordinate()
  local Coord=coord:Translate(distance, headingTo)
  
  wp[1]=coord:WaypointNaval(Speed)
  wp[2]=Coord:WaypointNaval(Speed)

  self.group:Route(wp, 1)
  
end

--- On after "FullStop" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterFullStop(From, Event, To)

  -- Get current position.
  local pos=self:GetCoordinate()
  
  -- Create a new waypoint.
  local wp=pos:WaypointNaval(0)
  
  -- Create new route consisting of only this position ==> Stop!
  self.group:Route({wp})

end

--- On after "Cruise" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function NAVYGROUP:onafterCruise(From, Event, To)

  self:UpdateRoute()

end

--- On after "Dive" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Depth Dive depth in meters.
function NAVYGROUP:onafterDive(From, Event, To, Depth)

  self:UpdateRoute(nil, nil, Depth)

end

--- On after "Surface" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number Depth Dive depth in meters.
function NAVYGROUP:onafterSurface(From, Event, To)

  self:UpdateRoute(nil, nil, 0)

end

--- On after "PassingWaypoint" event.
-- @param #NAVYGROUP self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number n Waypoint passed.
-- @param #number N Total number of waypoints.
function NAVYGROUP:onafterPassingWaypoint(From, Event, To, n, N)
  self:I(self.lid..string.format("Passed waypoint %d of %d", n, N))
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Events DCS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Event function handling the birth of a unit.
-- @param #NAVYGROUP self
-- @param Core.Event#EVENTDATA EventData Event data.
function NAVYGROUP:OnEventBirth(EventData)

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
  
  -- Ships are always AI.
  self.ai=true
  
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
  self.radioOn=true  -- Radio is always on for ships.
  self.radioFreq=tonumber(self.template.units[1].frequency)/1000000
  self.radioModu=tonumber(self.template.units[1].modulation)/1000000
  
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
  
  local units=self.group:GetUnits()
  
  for _,_unit in pairs(units) do
    local unit=_unit --Wrapper.Unit#UNIT
    
    local element={} --#NAVYGROUP.Element
    element.name=unit:GetName()
    element.typename=unit:GetTypeName()
    element.status=OPSGROUP.ElementStatus.INUTERO
    table.insert(self.elements, element)
    
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
    local text=string.format("Initialized Navy Group %s:\n", self.groupname)
    text=text..string.format("AC type      = %s\n", self.actype)
    text=text..string.format("Speed max    = %.1f Knots\n", UTILS.KmphToKnots(self.speedmax))
    text=text..string.format("Speed cruise = %.1f Knots\n", UTILS.KmphToKnots(self.speedCruise))
    text=text..string.format("Elements     = %d\n", #self.elements)
    text=text..string.format("Waypoints    = %d\n", #self.waypoints)
    text=text..string.format("Radio        = %.1f MHz %s %s\n", self.radioFreq, UTILS.GetModulationName(self.radioModu), tostring(self.radioOn))
    --text=text..string.format("Ammo         = %d (G=%d/R=%d/B=%d/M=%d)\n", self.ammo.Total, self.ammo.Guns, self.ammo.Rockets, self.ammo.Bombs, self.ammo.Missiles)
    text=text..string.format("FSM state    = %s\n", self:GetState())
    text=text..string.format("Is alive     = %s\n", tostring(self.group:IsAlive()))
    text=text..string.format("LateActivate = %s\n", tostring(self:IsLateActivated()))
    self:I(self.lid..text)
    
    -- Init done.
    self.groupinitialized=true
    
  end
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check for possible collisions between two coordinates.
-- @param #NAVYGROUP self
-- @param Core.Point#COORDINATE coordto Coordinate to which the collision is check.
-- @param Core.Point#COORDINATE coordfrom Coordinate from which the collision is check.
-- @return #boolean If true, surface type ahead is not deep water.
-- @return #number Max free distance in meters.
function NAVYGROUP:_CheckCollisionCoord(coordto, coordfrom)

  -- Increment in meters.
  local dx=100

  -- From coordinate. Default 500 in front of the carrier.
  local d=0
  if coordfrom then
    d=0
  else
    d=250
    coordfrom=self:GetCoordinate():Translate(d, self:GetHeading())
  end

  -- Distance between the two coordinates.
  local dmax=coordfrom:Get2DDistance(coordto)

  -- Direction.
  local direction=coordfrom:HeadingTo(coordto)

  -- Scan path between the two coordinates.
  local clear=true
  while d<=dmax do

    -- Check point.
    local cp=coordfrom:Translate(d, direction)

    -- Check if surface type is water.
    if not cp:IsSurfaceTypeWater() then

      -- Debug mark points.
      if self.Debug or true then
        local st=cp:GetSurfaceType()
        cp:MarkToAll(string.format("Collision check surface type %d", st))
      end

      -- Collision WARNING!
      clear=false
      break
    end

    -- Increase distance.
    d=d+dx
  end

  local text=""
  if clear then
    text=string.format("Path into direction %03d° is clear for the next %.1f NM.", direction, UTILS.MetersToNM(d))
  else
    text=string.format("Detected obstacle at distance %.1f NM into direction %03d°.", UTILS.MetersToNM(d), direction)
  end
  self:T(self.lid..text)

  return not clear, d
end

--- Check if group is turning.
-- @param #NAVYGROUP self
function NAVYGROUP:_CheckTurning()

  -- Current orientation of carrier.
  local vNew=self.group:GetOrientationX()

  -- Last orientation from 30 seconds ago.
  local vLast=self.Corientlast

  -- We only need the X-Z plane.
  vNew.y=0 ; vLast.y=0

  -- Angle between current heading and last time we checked ~30 seconds ago.
  local deltaLast=math.deg(math.acos(UTILS.VecDot(vNew,vLast)/UTILS.VecNorm(vNew)/UTILS.VecNorm(vLast)))

  -- Last orientation becomes new orientation
  self.Corientlast=vNew

  -- Carrier is turning when its heading changed by at least one degree since last check.
  local turning=math.abs(deltaLast)>=1

  -- Check if turning stopped. (Carrier was turning but is not any more.)
  if self.turning and not turning then

    -- Get final bearing.
    local FB=self:GetFinalBearing(true)

    -- Marshal radio call: "99, new final bearing XYZ degrees."
    self:_MarshalCallNewFinalBearing(FB)

  end

  -- Check if turning started. (Carrier was not turning and is now.)
  if turning and not self.turning then

    -- Get heading.
    local hdg
    if self.turnintowind then
      -- We are now steaming into the wind.
      hdg=self:GetHeadingIntoWind(false)
    else
      -- We turn towards the next waypoint.
      hdg=self:GetCoordinate():HeadingTo(self:_GetNextWaypoint())
    end

    -- Magnetic!
    hdg=hdg-self.magvar
    if hdg<0 then
      hdg=360+hdg
    end

  end

  -- Update turning.
  self.turning=turning
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
