--- **Functional** - (R2.5) - Rescue helo.
-- 
-- Recue helicopter for carrier operations.
--
-- Features:
--
--    * Close formation with carrier.
--    * Carrier can have any number of waypoints.
--    * Automatic respawning on empty fuel for 24/7 operations.
--    * Automatic rescuing of crashed or ejected units in the vicinity.
--
-- Please not that his class is work in progress and in an **alpha** stage.
--
-- ===
--
-- ### Author: **funkyfranky** 
--
-- @module Ops.RescueHelo
-- @image MOOSE.JPG

--- RESCUEHELO class.
-- @type RESCUEHELO
-- @field #string ClassName Name of the class.
-- @field Wrapper.Unit#UNIT carrier The carrier the helo is attached to.
-- @field #string carriertype Carrier type.
-- @field #string helogroupname Name of the late activated helo template group.
-- @field Wrapper.Group#GROUP helo Helo group.
-- @field #number takeoff Takeoff type.
-- @field Wrapper.Airbase#AIRBASE airbase The airbase object acting as home base of the helo.
-- @field Core.Set#SET_GROUP followset Follow group set.
-- @field AI.AI_Formation#AI_FORMATION formation AI_FORMATION object.
-- @field #number lowfuel Low fuel threshold of helo in percent.
-- @field #number altitude Altitude of helo in meters.
-- @field #number offsetX Offset in meters to carrier in longitudinal direction.
-- @field #number offsetZ Offset in meters to carrier in latitudinal direction.
-- @field Core.Zone#ZONE_RADIUS rescuezone Zone around the carrier in which helo will rescue crashed or ejected units.
-- @extends Core.Fsm#FSM

--- Rescue Helo
--
-- ===
--
-- ![Banner Image](..\Presentations\RESCUEHELO\RescueHelo_Main.jpg)
--
-- # Recue helo
--
-- bla bla
--
-- @field #RESCUEHELO
RESCUEHELO = {
  ClassName     = "RESCUEHELO",
  carrier       = nil,
  carriertype   = nil,
  helogroupname = nil,
  helo          = nil,
  airbase       = nil,
  takeoff       = nil,
  followset     = nil,
  formation     = nil,
  lowfuel       = nil,
  altitude      = nil,
  offsetX       = nil,
  offsetZ       = nil,
  rescuezone    = nil,
}

--- Class version.
-- @field #string version
RESCUEHELO.version="0.9.2"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Add option to stop carrier while rescue operation is in progress.
-- TODO: Possibility to add already present/spawned aircraft, e.g. for warehouse.
-- TODO: Write documenation.
-- DONE: Add rescue event when aircraft crashes.
-- DONE: Make offset input parameter.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new RESCUEHELO object. 
-- @param #RESCUEHELO self
-- @param Wrapper.Unit#UNIT carrierunit Carrier unit.
-- @param #string helogroupname Name of the late activated rescue helo template group.
-- @return #RESCUEHELO RESCUEHELO object.
function RESCUEHELO:New(carrierunit, helogroupname)

  -- Inherit everthing from FSM class.
  local self = BASE:Inherit(self, FSM:New()) -- #RESCUEHELO
  
  -- Catch case when just the unit name is passed.
  if type(carrierunit)=="string" then
    self.carrier=UNIT:FindByName(carrierunit)
  else
    self.carrier=carrierunit
  end
  
  -- Carrier type.
  self.carriertype=self.carrier:GetTypeName()
  
  -- Helo group name.
  self.helogroupname=helogroupname
    
  -- Init defaults.  
  self:SetHomeBase(AIRBASE:FindByName(self.carrier:GetName()))
  self:SetTakeoffHot()
  self:SetLowFuelThreshold()
  self:SetAltitude()
  self:SetOffsetX()
  self:SetOffsetZ()
  self:SetRescueZone()

  -----------------------
  --- FSM Transitions ---
  -----------------------
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event   -->   To State
  self:AddTransition("Stopped",       "Start",      "Running")
  self:AddTransition("Running",       "Rescue",     "Rescuing")
  self:AddTransition("Running",       "RTB",        "Returning")
  self:AddTransition("*",             "Run",        "Running")
  self:AddTransition("*",             "Status",     "*")
  self:AddTransition("*",             "Stop",       "Stopped")


  --- Triggers the FSM event "Start" that starts the rescue helo. Initializes parameters and starts event handlers.
  -- @function [parent=#RESCUEHELO] Start
  -- @param #RESCUEHELO self

  --- Triggers the FSM event "Start" that starts the rescue helo after a delay. Initializes parameters and starts event handlers.
  -- @function [parent=#RESCUEHELO] __Start
  -- @param #RESCUEHELO self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Rescue" that sends the helo on a rescue mission to a specifc coordinate.
  -- @function [parent=#RESCUEHELO] Rescue
  -- @param #RESCUEHELO self
  -- @param Core.Point#COORDINATE RescueCoord Coordinate where the resue mission takes place.

  --- Triggers the delayed FSM event "Rescue" that sends the helo on a rescue mission to a specifc coordinate.
  -- @function [parent=#RESCUEHELO] __Rescue
  -- @param #RESCUEHELO self
  -- @param #number delay Delay in seconds.
  -- @param Core.Point#COORDINATE RescueCoord Coordinate where the resue mission takes place.

  --- Triggers the FSM event "RTB" that sends the helo home.
  -- @function [parent=#RESCUEHELO] RTB
  -- @param #RESCUEHELO self

  --- Triggers the FSM event "RTB" that sends the helo home after a delay.
  -- @function [parent=#RESCUEHELO] __RTB
  -- @param #RESCUEHELO self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Run".
  -- @function [parent=#RESCUEHELO] Run
  -- @param #RESCUEHELO self

  --- Triggers the delayed FSM event "Run".
  -- @function [parent=#RESCUEHELO] __Run
  -- @param #RESCUEHELO self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop" that stops the rescue helo. Event handlers are stopped.
  -- @function [parent=#RESCUEHELO] Stop
  -- @param #RESCUEHELO self

  --- Triggers the FSM event "Stop" that stops the rescue helo after a delay. Event handlers are stopped.
  -- @function [parent=#RESCUEHELO] __Stop
  -- @param #RESCUEHELO self
  -- @param #number delay Delay in seconds.
  
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set low fuel state of helo. When fuel is below this threshold, the helo will RTB or be respawned if takeoff type is in air.
-- @param #RESCUEHELO self
-- @param #number threshold Low fuel threshold in percent. Default 5%.
-- @return #RESCUEHELO self
function RESCUEHELO:SetLowFuelThreshold(threshold)
  self.lowfuel=threshold or 5
  return self
end

--- Set home airbase of the helo. Default is the carrier.
-- @param #RESCUEHELO self
-- @param Wrapper.Airbase#AIRBASE airbase Homebase of helo.
-- @return #RESCUEHELO self
function RESCUEHELO:SetHomeBase(airbase)
  self.airbase=airbase
  return self
end

--- Set rescue zone radius. Crashed or ejected units inside this radius of the carrier will be rescued.
-- @param #RESCUEHELO self
-- @param #number radius Radius of rescue zone in meters. Default is 100000 m = 100 km.
-- @return #RESCUEHELO self
function RESCUEHELO:SetRescueZone(radius)
  self.rescuezone=ZONE_UNIT:New("Rescue Zone", self.carrier, radius or 100000)
  return self
end

--- Set takeoff type.
-- @param #RESCUEHELO self
-- @param #number takeofftype Takeoff type. Default SPAWN.Takeoff.Hot.
-- @return #RESCUEHELO self
function RESCUEHELO:SetTakeoff(takeofftype)
  self.takeoff=takeofftype or SPAWN.Takeoff.Hot
  return self
end

--- Set takeoff with engines running (hot).
-- @param #RESCUEHELO self
-- @return #RESCUEHELO self
function RESCUEHELO:SetTakeoffHot()
  self:SetTakeoff(SPAWN.Takeoff.Hot)
  return self
end

--- Set takeoff with engines off (cold).
-- @param #RESCUEHELO self
-- @return #RESCUEHELO self
function RESCUEHELO:SetTakeoffCold()
  self:SetTakeoff(SPAWN.Takeoff.Cold)
  return self
end

--- Set takeoff in air near the carrier.
-- @param #RESCUEHELO self
-- @return #RESCUEHELO self
function RESCUEHELO:SetTakeoffAir()
  self:SetTakeoff(SPAWN.Takeoff.Air)
  return self
end

--- Set altitude of helo.
-- @param #RESCUEHELO self
-- @param #number alt Altitude in meters. Default 70 m.
-- @return #RESCUEHELO self
function RESCUEHELO:SetAltitude(alt)
  self.altitude=alt or 70
  return self
end

--- Set latitudinal offset to carrier.
-- @param #RESCUEHELO self
-- @param #number distance Latitual offset distance in meters. Default 200 m.
-- @return #RESCUEHELO self
function RESCUEHELO:SetOffsetX(distance)
  self.offsetX=distance or 200
  return self
end

--- Set longitudal offset to carrier.
-- @param #RESCUEHELO self
-- @param #number distance Longitual offset distance in meters. Default 200 m.
-- @return #RESCUEHELO self
function RESCUEHELO:SetOffsetZ(distance)
  self.offsetZ=distance or 200
  return self
end


--- Check if helo is returning to base.
-- @param #RESCUEHELO self
-- @return #boolean If true, helo is returning to base. 
function RESCUEHELO:IsReturning()
  return self:is("Returning")
end

--- Check if helo is operating.
-- @param #RESCUEHELO self
-- @return #boolean If true, helo is operating. 
function RESCUEHELO:IsRunning()
  return self:is("Running")
end

--- Check if helo is on a rescue mission.
-- @param #RESCUEHELO self
-- @return #boolean If true, helo is rescuing somebody. 
function RESCUEHELO:IsRescuing()
  return self:is("Rescuing")
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EVENT functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Handle landing event of rescue helo.
-- @param #RESCUEHELO self
-- @param Core.Event#EVENTDATA EventData Event data.
function RESCUEHELO:OnEventLand(EventData)
  local group=EventData.IniGroup --Wrapper.Group#GROUP
  
  if group:IsAlive() then
    local groupname=group:GetName()
  
    if groupname:match(self.helogroupname) then
    
      -- Respawn the Helo.
      self:I(string.format("Respawning rescue helo group %s at home base.", groupname))
      
      if self.takeoff==SPAWN.Takeoff.Air then
        
        self:E("ERROR: Rescue helo %s landed. This should not happen for Takeoff=Air!", groupname)
      
      else
      
        -- Respawn helo at current airbase.
        self.helo=group:RespawnAtCurrentAirbase()
        
      end
      
      -- Restart the formation.
      self:__Run(10)
    end
  end
end

--- A unit crashed or a player ejected.
-- @param #RESCUEHELO self
-- @param Core.Event#EVENTDATA EventData Event data.
function RESCUEHELO:_OnEventCrashOrEject(EventData)
  self:F2({eventdata=EventData})
  
  -- NOTE: Careful here. Eject and crash events will probably happen for the same unit!
  
  -- Check that there is an initiating unit in the event data.
  if EventData and EventData.IniUnit then

    -- Crashed or ejected unit.
    local unit=EventData.IniUnit  
    local unitname=tostring(EventData.IniUnitName)
    
    -- Check that it was not the rescue helo itself that crashed.
    if EventData.IniGroupName~=self.helo:GetName() then
    
      -- Debug.
      self:T(string.format("Unit %s crashed or ejected.", unitname))
    
      -- Unit "alive" and in our rescue zone.
      if unit:IsAlive() and unit:IsInZone(self.rescuezone) then
      
        -- Get coordinate of crashed unit.
        local coord=unit:GetCoordinate()
        
        -- Debug mark on map.
        coord:MarkToCoalition(string.format("Crash site of unit %s.", unitname), self.helo:GetCoalition())
      
        -- Only rescue if helo is "running" and not, e.g., rescuing already.
        if self:IsRunning() then
          self:Rescue(coord)
        end
      
      end
      
    else
    
      self:I(string.format("Rescue helo %s crashed!", unitname))
    
    end
    
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM states
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the warehouse. Addes event handlers and schedules status updates of reqests and queue.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RESCUEHELO:onafterStart(From, Event, To)

  -- Events are handled my MOOSE.
  self:I(string.format("Starting Rescue Helo Formation v%s for carrier unit %s of type %s.", RESCUEHELO.version, self.carrier:GetName(), self.carriertype))
  
  -- Handle events.
  --self:HandleEvent(EVENTS.Birth)
  self:HandleEvent(EVENTS.Land)
  self:HandleEvent(EVENTS.Crash, self._OnEventCrashOrEject)
  self:HandleEvent(EVENTS.Ejection, self._OnEventCrashOrEject)
  
  -- Delay before formation is started.
  local delay=120  
  
  -- Spawn helo.
  local Spawn=SPAWN:New(self.helogroupname):InitUnControlled(false)
  
  -- Spawn in air or at airbase.
  if self.takeoff==SPAWN.Takeoff.Air then
  
    -- Carrier heading
    local hdg=self.carrier:GetHeading()
    
    -- Spawn distance behind carrier.
    local dist=UTILS.NMToMeters(0.2)
    
    -- Coordinate behind the carrier
    local Carrier=self.carrier:GetCoordinate():SetAltitude(math.min(100, self.altitude)):Translate(dist, hdg)
    
    -- Orientation of spawned group.
    Spawn:InitHeading(hdg)
    
    -- Spawn at coordinate.
    self.helo=Spawn:SpawnFromCoordinate(Carrier)
    
    -- Start formation in 1 seconds
    delay=1
    
  else  
  
    -- Spawn at airbase.
    self.helo=Spawn:SpawnAtAirbase(self.airbase, self.takeoff)
    
    if self.takeoff==SPAWN.Takeoff.Runway then
      delay=5
    elseif self.takeoff==SPAWN.Takeoff.Hot then
      delay=30
    elseif self.takeoff==SPAWN.Takeoff.Cold then
      delay=60
    end
    
  end
  
  -- Set of group(s) to follow Mother.
  self.followset=SET_GROUP:New()
  self.followset:AddGroup(self.helo)
  
  -- Get initial fuel.
  self.HeloFuel0=self.helo:GetFuel()
  
  -- Define AI Formation object.
  self.formation=AI_FORMATION:New(self.carrier, self.followset, "Helo Formation with Carrier", "Follow Carrier at given parameters.")
  
  -- Formation parameters.
  self.formation:FormationCenterWing(-self.offsetX, 50, math.abs(self.altitude), 50, self.offsetZ, 50)
  
  -- Start formation FSM.
  self.formation:__Start(delay)
  
  -- Start uncontrolled helo.
  --HeloSpawn:StartUncontrolled(120)
  
  -- Init status check
  self:__Status(1)
  
end

--- On after Status event. Checks player status.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RESCUEHELO:onafterStatus(From, Event, To)

  -- Get current time.
  local time=timer.getTime()

  -- Get relative fuel wrt to initial fuel of helo (DCS bug https://forums.eagle.ru/showthread.php?t=223712)
  local fuel=self.helo:GetFuel()/self.HeloFuel0*100

  -- Report current fuel.
  local text=string.format("Rescue Helo %s: state=%s fuel=%.1f", self.helo:GetName(), self:GetState(), fuel)
  self:I(text)

  -- If fuel < threshold ==> send helo to home base!  
  if fuel<self.lowfuel and self:IsRunning() then
    self:RTB()
  end
  
  -- Call status again in one minute.
  self:__Status(-60)
end

--- On after "Run" event. FSM will go to "Running" state. If formation is topped, it will be started again.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RESCUEHELO:onafterRun(From, Event, To)
  
  -- Restart formation if stopped.
  if self.formation:Is("Stopped") then
    self.formation:Start()
  end
  
end

--- On after "Rescue" event. Helo will fly to the given coordinate, orbit there for 5 minutes and then return to the carrier.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE RescueCoord Coordinate where the rescue should happen
function RESCUEHELO:onafterRescue(From, Event, To, RescueCoord)

  -- Debug message.
  local text=string.format("Helo %s is send to rescue mission.", self.helo:GetName())
  self:I(text)
  
  -- Waypoint array.
  local wp={}
  
  --local RescueTask=self.helo:TaskControlled(self.helo:TaskOrbitCircle(20, 2, RescueCoord), self.helo:TaskCondition(nil, nil, nil, nil, 5*60, nil))
   
  -- Rescue task: Orbit at crash site for 5 minutes.
  local RescueTask={}
  RescueTask.id="ControlledTask"
  RescueTask.params={}
  RescueTask.params.task=self.helo:TaskOrbit(RescueCoord, 20, 2)
  RescueTask.params.stopCondition={duration=300}
  
  -- Set Waypoints.
  wp[1]=self.helo:GetCoordinate():WaypointAirTurningPoint(nil, 200, {}, "Current Position")
  wp[2]=RescueCoord:SetAltitude(50):WaypointAirTurningPoint(nil, 200, {RescueTask}, "Crash Site")
  wp[3]=self.airbase:GetCoordinate():SetAltitude(70):WaypointAirLanding(200, self.airbase, {}, "Land at Home Base")

  -- Initialize WP and route tanker.
  self.helo:WayPointInitialize(wp)

  -- Set task.
  self.helo:Route(wp, 1)
  
  -- Stop formation.
  self.formation:Stop()
end


--- On before RTB event. Check if takeoff type is air and if so respawn the helo and deny RTB transition.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean If true, transition is allowed.
function RESCUEHELO:onbeforeRTB(From, Event, To)

  if self.takeoff==SPAWN.Takeoff.Air then
    -- For takeoff in air, we just respawn the helo with full fuel.
  
    -- Debug message.
    local text=string.format("Respawning rescue helo group %s in air.", self.helo:GetName())
    self:I(text)  
    
    -- Respawn helo.
    self.helo:InitHeading(self.helo:GetHeading())
    self.helo=self.helo:Respawn(nil, true)
        
    -- Deny transition to RTB.
    return false
  end
  
  return true
end

--- On after RTB event. Send tanker back to carrier.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RESCUEHELO:onafterRTB(From, Event, To)

    -- Debug message.
    local text=string.format("Rescue helo %s is returning to airbase %s.", self.helo:GetName(), self.airbase:GetName())
    self:I(text)
    
    -- Waypoint array.
    local wp={}
    
    -- Set landing waypoint at home base.
    wp[1]=self.helo:GetCoordinate():WaypointAirTurningPoint(nil, 300, {}, "Current Position")
    wp[2]=self.airbase:GetCoordinate():SetAltitude(70):WaypointAirLanding(300, self.airbase, {}, "Landing at Home Base")

    -- Initialize WP and route tanker.
    self.helo:WayPointInitialize(wp)
  
    -- Set task.
    self.helo:Route(wp, 1)
    
    -- Stop formation.
    self.formation:Stop()
end

--- On after Stop event. Unhandle events and stop status updates.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RESCUEHELO:onafterStop(From, Event, To)
  self:UnHandleEvent(EVENTS.Land)
  self:UnHandleEvent(EVENTS.Crash)
  self:UnHandleEvent(EVENTS.Ejection)
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
