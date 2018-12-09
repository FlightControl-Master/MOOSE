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
-- ===
--
-- ### Author: **funkyfranky** 
--
-- @module Ops.RescueHelo
-- @image MOOSE.JPG

--- RESCUEHELO class.
-- @type RESCUEHELO
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode on/off.
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
-- @field #boolean respawn If true, helo be respawned (default). If false, no respawning will happen.
-- @field #boolean respawninair If true, helo will always be respawned in air. This has no impact on the initial spawn setting.
-- @field #boolean uncontrolledac If true, use and uncontrolled helo group already present in the mission.
-- @field #boolean rescueon If true, helo will rescue crashed pilots. If false, no recuing will happen.
-- @field #number rescueduration Time the rescue helicopter hovers over the crash site in seconds.
-- @field #number rescuespeed Speed in m/s the rescue helicopter hovers at over the crash site.
-- @field #boolean rescuestopboat If true, stop carrier during rescue operations.
-- @field #boolean carrierstop If true, route of carrier was stopped.
-- @field #number HeloFuel0 Initial fuel of helo in percent. Necessary due to DCS bug that helo with full tank does not return fuel via API function.
-- @extends Core.Fsm#FSM

--- Rescue Helo
--
-- ===
--
-- ![Banner Image](..\Presentations\RESCUEHELO\RescueHelo_Main.jpg)
--
-- # Recue Helo
--
-- The rescue helo will fly in close formation with another unit, which is typically an aircraft carrier.
-- It's mission is to rescue crashed units or ejected pilots. Well, and to look cool...
-- 
-- # Simple Script
-- 
-- In the mission editor you have to set up a carrier unit, which will act as "mother". In the following, this unit will be named "USS Stennis".
-- 
-- Secondly, you need to define a recue helicopter group in the mission editor and set it to "LATE ACTIVATED". The name of the group we'll use is "Recue Helo".
-- 
-- The basic script is very simple and consists of only two lines. 
-- 
--      RescueheloStennis=RESCUEHELO:New(UNIT:FindByName("USS Stennis"), "Rescue Helo")
--      RescueheloStennis:Start()
--
-- The first line will create a new RESCUEHELO object and the second line starts the process.
-- 
-- **NOTE** that it is *very important* to define the RESCUEHELO object as **global** variable. Otherwise, the lua garbage collector will kill the formation!
-- 
-- By default, the helo will be spawned on the USS Stennis with hot engines. Then it will take off and go on station on the starboard side of the boat.
-- 
-- Once the helo is out of fuel, it will return to the carrier. When the helo lands, it will be respawned immidiately and go back on station.
-- 
-- If a unit crashes or a pilot ejects within a radius of 100 km from the USS Stennis, the helo will automatically fly to the crash side and 
-- rescue to pilot. This will take around 5 minutes. After that, the helo will return to the Stennis, land there and bring back the poor guy.
-- When this is done, the helo will go back on station.
-- 
-- # Fine Tuning
-- 
-- The implementation allows to customize quite a few settings easily
-- 
-- ## Takeoff Type
-- 
-- By default, the helo is spawned with running engies on the carrier. The mission designer has set option to set the take off type via the @{#RESCUEHELO.SetTakeoff} function.
-- Or via shortcuts
-- 
--    * @{#RESCUEHELO.SetTakeoffHot}(): Will set the takeoff to hot, which is also the default.
--    * @{#RESCUEHELO.SetTakeoffCold}(): Will set the takeoff type to cold, i.e. with engines off.
--    * @{#RESCUEHELO.SetTakeoffAir}(): Will set the takeoff type to air, i.e. the helo will be spawned in air near the unit which he follows.  
-- 
-- For example,
--      RescueheloStennis=RESCUEHELO:New(UNIT:FindByName("USS Stennis"), "Rescue Helo")
--      RescueheloStennis:SetTakeoffAir()
--      RescueheloStennis:Start()
-- will spawn the helo near the USS Stennis in air.
-- 
-- Spawning in air is not as realsitic but can be useful do avoid DCS bugs and shortcomings like aircraft crashing into each other on the flight deck.
-- 
-- **Note** that when spawning in air is set, the helo will also not return to the boat, once it is out of fuel. Instead it will be respawned in air.
-- 
-- If only the first spawning should happen on the carrier, one use the @{#RESCUEHELO.SetRespawnInAir}() function to command that all subsequent spawning
-- will happen in air.
-- 
-- If the helo should no be respawned at all, one can set @{#RESCUEHELO.SetRespawnOff}(). 
-- 
-- ## Home Base
-- 
-- It is possible to define a "home base" other than the aircaft carrier. For example, one could imagine a strike group, and the helo will be spawned from
-- another ship which has a helo pad.
-- 
--      RescueheloStennis=RESCUEHELO:New(UNIT:FindByName("USS Stennis"), "Rescue Helo")
--      RescueheloStennis:SetHomeBase(AIRBASE:FindByName("USS Normandy"))
--      RescueheloStennis:Start()
-- 
-- In this case, the helo will be spawned on the USS Normandy and then make its way to the USS Stennis to establish the formation.
-- Note that the distance to the mother ship should be rather small since the helo will go there very slowly.
-- 
-- Once the helo runs out of fuel, it will return to the USS Normandy and not the Stennis for respawning.
-- 
-- 
-- ## Formation Positon
-- 
-- The position of the helo relative to the mother ship can be tuned via the functions
-- 
--    * @{#RESCUEHELO.SetAltitude}(*altitude*), where *altitude* is the altitude the helo flies at in meters. Default is 70 meters.
--    * @{#RESCUEHELO.SetOffsetX}(*distance*)}, where *distance is the distance in the direction of movement of the carrier. Default is 200 meters.
--    * @{#RESCUEHELO.SetOffsetZ}(*distance*)}, where *distance is the distance on the starboard side. Default is 200 meters.
--
--
-- @field #RESCUEHELO
RESCUEHELO = {
  ClassName      = "RESCUEHELO",
  Debug          = false,
  carrier        = nil,
  carriertype    = nil,
  helogroupname  = nil,
  helo           = nil,
  airbase        = nil,
  takeoff        = nil,
  followset      = nil,
  formation      = nil,
  lowfuel        = nil,
  altitude       = nil,
  offsetX        = nil,
  offsetZ        = nil,
  rescuezone     = nil,
  respawn        = nil,
  respawninair   = nil,
  uncontrolledac = nil,
  rescueon       = nil,
  rescueduration = nil,
  rescuespeed    = nil,
  rescuestopboat = nil,
  HeloFuel0      = nil,
  carrierstop    = false,
}

--- Class version.
-- @field #string version
RESCUEHELO.version="0.9.5"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Write documenation.
-- TODO: Add option to stop carrier while rescue operation is in progress? Done but NOT working!
-- DONE: Add option to deactivate the rescueing.
-- DONE: Possibility to add already present/spawned aircraft, e.g. for warehouse.
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
  self:SetRescueOn()
  self:SetRescueZone()
  self:SetRescueHoverSpeed()
  self:SetRescueDuration()
  self:SetRescueStopBoatOff()

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

--- Set rescue hover speed.
-- @param #RESCUEHELO self
-- @param #number speed Speed in km/h. Default 25 km/h.
-- @return #RESCUEHELO self
function RESCUEHELO:SetRescueHoverSpeed(speed)
  self.rescuespeed=UTILS.KmphToMps(speed or 25)
  return self
end

--- Set rescue duration. This is the time it takes to rescue a pilot at the crash site.
-- @param #RESCUEHELO self
-- @param #number duration Duration in minutes. Default 5 min.
-- @return #RESCUEHELO self
function RESCUEHELO:SetRescueDuration(duration)
  self.rescueduration=(duration or 5)*60
  return self
end

--- Activate rescue option. Crashed and ejected pilots will be rescued. This is the default setting.
-- @param #RESCUEHELO self
-- @return #RESCUEHELO self
function RESCUEHELO:SetRescueOn()
  self.rescueon=true
  return self
end

--- Deactivate rescue option. Crashed and ejected pilots will not be rescued.
-- @param #RESCUEHELO self
-- @return #RESCUEHELO self
function RESCUEHELO:SetRescueOff()
  self.rescueon=false
  return self
end

--- Stop carrier during rescue operations. NOT WORKING!
-- @param #RESCUEHELO self
-- @return #RESCUEHELO self
function RESCUEHELO:SetRescueStopBoatOn()
  self.rescuestopboat=true
  return self
end

--- Do not stop carrier during rescue operations. This is the default setting.
-- @param #RESCUEHELO self
-- @return #RESCUEHELO self
function RESCUEHELO:SetRescueStopBoatOff()
  self.rescuestopboat=false
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


--- Enable respawning of helo. Note that this is the default behaviour. 
-- @param #RESCUEHELO self 
-- @return #RESCUEHELO self
function RESCUEHELO:SetRespawnOn()
  self.respawn=true
  return self
end

--- Disable respawning of helo.
-- @param #RESCUEHELO self 
-- @return #RESCUEHELO self
function RESCUEHELO:SetRespawnOff()
  self.respawn=false
  return self
end

--- Set whether helo shall be respawned or not.
-- @param #RESCUEHELO self
-- @param #boolean switch If true (or nil), helo will be respawned. If false, helo will not be respawned. 
-- @return #RESCUEHELO self
function RESCUEHELO:SetRespawnOnOff(switch)
  if switch==nil or switch==true then
    self.respawn=true
  else
    self.respawn=false
  end
  return self
end

--- Helo will be respawned in air, even it was initially spawned on the carrier.
-- So only the first spawn will be on the carrier while all subsequent spawns will happen in air.
-- This allows for undisrupted operations and less problems on the carrier deck.
-- @param #RESCUEHELO self
-- @return #RESCUEHELO self
function RESCUEHELO:SetRespawnInAir()
  self.respawninair=true
  return self
end

--- Use an uncontrolled aircraft already present in the mission rather than spawning a new helo as initial rescue helo.
-- This can be useful when interfaced with, e.g., a warehouse.
-- The group name is the one specified in the @{#RESCUEHELO.New} function.
-- @param #RESCUEHELO self
-- @return #RESCUEHELO self
function RESCUEHELO:SetUseUncontrolledAircraft()
  self.uncontrolledac=true
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
      
      if self.takeoff==SPAWN.Takeoff.Air or self.respawninair then
        
        self:E("ERROR: Rescue helo %s landed. This should not happen for Takeoff=Air or respawninair=true!", groupname)
      
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
        if self:IsRunning() and self.rescueon then
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
 
    -- Check if an uncontrolled helo group was requested.
    if self.useuncontrolled then
    
      -- Use an uncontrolled aircraft group.
      self.helo=GROUP:FindByName(self.helogroupname)
      
      if self.helo:IsAlive() then
      
        -- Start uncontrolled group.
        self.helo:StartUncontrolled()
        
        -- Delay before formation is started.
        delay=60
        
      else
        -- No group of that name!
        self:E(string.format("ERROR: No uncontrolled (alive) rescue helo group with name %s could be found!", self.helogroupname))
        return
      end
       
    else

      -- Spawn at airbase.
      self.helo=Spawn:SpawnAtAirbase(self.airbase, self.takeoff)
      
      -- Delay before formation is started.
      if self.takeoff==SPAWN.Takeoff.Runway then
        delay=5
      elseif self.takeoff==SPAWN.Takeoff.Hot then
        delay=30
      elseif self.takeoff==SPAWN.Takeoff.Cold then
        delay=60
      end
      
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
  self:T(text)

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
    self:I(string.format("Restarting formation of rescue helo %s.", self.helo:GetName()))
    self.formation:Start()
  end
  
  -- Restart route of carrier if it was stopped.
  if self.carrierstop then
    self:I("Carrier resuming route after rescue operation.")
    self.carrier:RouteResume()
    self.carrierstop=false
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
  RescueTask.params.task=self.helo:TaskOrbit(RescueCoord, 20, self.rescuespeed)
  RescueTask.params.stopCondition={duration=self.rescueduration}
  
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
  
  -- Stop carrier.
  if self.rescuestopboat then
    self:I("Stopping carrier for rescue operation.")
    self.carrier:RouteStop()
    self.carrierstop=true
  end
end


--- On before RTB event. Check if takeoff type is air and if so respawn the helo and deny RTB transition.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean If true, transition is allowed.
function RESCUEHELO:onbeforeRTB(From, Event, To)

  -- For takeoff in air, we just respawn the helo with full fuel.
  if (self.takeoff==SPAWN.Takeoff.Air or self.respawninair) and self.respawn then
    
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
