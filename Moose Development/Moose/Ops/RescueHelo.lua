--- **Ops** - Rescue helicopter for carrier operations.
-- 
-- Recue helicopter for carrier operations.
--
-- **Main Features:**
--
--    * Close formation with carrier.
--    * No restrictions regarding carrier waypoints and heading.
--    * Automatic respawning on empty fuel for 24/7 operations.
--    * Automatic rescuing of crashed or ejected pilots in the vicinity of the carrier.
--    * Multiple helos at different carriers due to object oriented approach.
--    * Finite State Machine (FSM) implementation.
--    
-- ## Known (DCS) Issues
-- 
--    * CH-53E does only report 27.5% fuel even if fuel is set to 100% in the ME. See [bug report](https://forums.eagle.ru/showthread.php?t=223712)
--    * CH-53E does not accept USS Tarawa as landing airbase (even it can be spawned on it).
--    * Helos dont move away from their landing position on carriers.
--
-- ===
--
-- ### Author: **funkyfranky**
-- ### Contributions: Flightcontrol (@{AI.AI_Formation} class being used here)
--
-- @module Ops.RescueHelo
-- @image Ops_RescueHelo.png

--- RESCUEHELO class.
-- @type RESCUEHELO
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode on/off.
-- @field #string lid Log debug id text.
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
-- @field #boolean rtb If true, Helo will be return to base on the next status check.
-- @field #number hid Unit ID of the helo group. (Global) Running number.
-- @field #string alias Alias of the spawn group.
-- @field #number uid Unique ID of this helo.
-- @field #number modex Tail number of the helo.
-- @field #number dtFollow Follow time update interval in seconds. Default 1.0 sec.
-- @extends Core.Fsm#FSM

--- Rescue Helo
--
-- ===
--
-- # Recue Helo
--
-- The rescue helo will fly in close formation with another unit, which is typically an aircraft carrier.
-- It's mission is to rescue crashed or ejected pilots. Well, and to look cool...
-- 
-- # Simple Script
-- 
-- In the mission editor you have to set up a carrier unit, which will act as "mother". In the following, this unit will be named "*USS Stennis*".
-- 
-- Secondly, you need to define a rescue helicopter group in the mission editor and set it to "**LATE ACTIVATED**". The name of the group we'll use is "*Recue Helo*".
-- 
-- The basic script is very simple and consists of only two lines. 
-- 
--      RescueheloStennis=RESCUEHELO:New(UNIT:FindByName("USS Stennis"), "Rescue Helo")
--      RescueheloStennis:Start()
--
-- The first line will create a new @{#RESCUEHELO} object via @{#RESCUEHELO.New} and the second line starts the process by calling @{#RESCUEHELO.Start}.
-- 
-- **NOTE** that it is *very important* to define the RESCUEHELO object as **global** variable. Otherwise, the lua garbage collector will kill the formation for unknown reasons!
-- 
-- By default, the helo will be spawned on the *USS Stennis* with hot engines. Then it will take off and go on station on the starboard side of the boat.
-- 
-- Once the helo is out of fuel, it will return to the carrier. When the helo lands, it will be respawned immidiately and go back on station.
-- 
-- If a unit crashes or a pilot ejects within a radius of 30 km from the USS Stennis, the helo will automatically fly to the crash side and 
-- rescue to pilot. This will take around 5 minutes. After that, the helo will return to the Stennis, land there and bring back the poor guy.
-- When this is done, the helo will go back on station.
-- 
-- # Fine Tuning
-- 
-- The implementation allows to customize quite a few settings easily via user API functions.
-- 
-- ## Takeoff Type
-- 
-- By default, the helo is spawned with running engines on the carrier. The mission designer has set option to set the take off type via the @{#RESCUEHELO.SetTakeoff} function.
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
-- Spawning in air is not as realistic but can be useful do avoid DCS bugs and shortcomings like aircraft crashing into each other on the flight deck.
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
-- It is possible to define a "home base" other than the aircraft carrier using the @{#RESCUEHELO.SetHomeBase}(*airbase*) function, where *airbase* is
-- a @{Wrapper.Airbase#AIRBASE} object or simply the name of the airbase.
-- 
-- For example, one could imagine a strike group, and the helo will be spawned from another ship which has a helo pad.
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
-- ## Formation Position
-- 
-- The position of the helo relative to the mother ship can be tuned via the functions
-- 
--    * @{#RESCUEHELO.SetAltitude}(*altitude*), where *altitude* is the altitude the helo flies at in meters. Default is 70 meters.
--    * @{#RESCUEHELO.SetOffsetX}(*distance*), where *distance is the distance in the direction of movement of the carrier. Default is 200 meters.
--    * @{#RESCUEHELO.SetOffsetZ}(*distance*), where *distance is the distance on the starboard side. Default is 100 meters.
--
-- ## Rescue Operations
--
-- By default the rescue helo will start a rescue operation if an aircraft crashes or a pilot ejects in the vicinity of the carrier.
-- This is restricted to aircraft of the same coalition as the rescue helo. Enemy (or neutral) pilots will be left on their own.
-- 
-- The standard "rescue zone" has a radius of 15 NM (~28 km) around the carrier. The radius can be adjusted via the @{#RESCUEHELO.SetRescueZone}(*radius*) functions,
-- where *radius* is the radius of the zone in nautical miles. If you use multiple rescue helos in the same mission, you might want to ensure that the radii
-- are not overlapping so that two helos try to rescue the same pilot. But it should not hurt either way.
-- 
-- Once the helo reaches the crash site, the rescue operation will last 5 minutes. This time can be changed by @{#RESCUEHELO.SetRescueDuration(*time*),
-- where *time* is the duration in minutes.
-- 
-- During the rescue operation, the helo will hover (orbit) over the crash site at a speed of 5 knots. The speed can be set by @{#RESCUEHELO.SetRescueHoverSpeed}(*speed*),
-- where the *speed* is given in knots.
-- 
-- If no rescue operations should be carried out by the helo, this option can be completely disabled by using @{#RESCUEHELO.SetRescueOff}().
--
-- # Finite State Machine
-- 
-- The implementation uses a Finite State Machine (FSM). This allows the mission designer to hook in to certain events.
-- 
--    * @{#RESCUEHELO.Start}: This eventfunction starts the FMS process and initialized parameters and spawns the helo. DCS event handling is started.
--    * @{#RESCUEHELO.Status}: This eventfunction is called in regular intervals (~60 seconds) and checks the status of the helo and carrier. It triggers other events if necessary.
--    * @{#RESCUEHELO.Rescue}: This eventfunction commands the helo to go on a rescue operation at a certain coordinate.
--    * @{#RESCUEHELO.RTB}: This eventsfunction sends the helo to its home base (usually the carrier). This is called once the helo runs low on gas.
--    * @{#RESCUEHELO.Run}: This eventfunction is called when the helo resumes normal operations and goes back on station.  
--    * @{#RESCUEHELO.Stop}: This eventfunction stops the FSM by unhandling DCS events.
--
-- The mission designer can capture these events by RESCUEHELO.OnAfter*Eventname* functions, e.g. @{#RESCUEHELO.OnAfterRescue}.
--
-- # Debugging
-- 
-- In case you have problems, it is always a good idea to have a look at your DCS log file. You find it in your "Saved Games" folder, so for example in
--     C:\Users\<yourname>\Saved Games\DCS\Logs\dcs.log
-- All output concerning the @{#RESCUEHELO} class should have the string "RESCUEHELO" in the corresponding line.
-- Searching for lines that contain the string "error" or "nil" can also give you a hint what's wrong.
-- 
-- The verbosity of the output can be increased by adding the following lines to your script:
-- 
--     BASE:TraceOnOff(true)
--     BASE:TraceLevel(1)
--     BASE:TraceClass("RESCUEHELO")
-- 
-- To get even more output you can increase the trace level to 2 or even 3, c.f. @{Core.Base#BASE} for more details.
-- 
-- ## Debug Mode
-- 
-- You have the option to enable the debug mode for this class via the @{#RESCUEHELO.SetDebugModeON} function.
-- If enabled, text messages about the helo status will be displayed on screen and marks of the pattern created on the F10 map.
--
--
-- @field #RESCUEHELO
RESCUEHELO = {
  ClassName      = "RESCUEHELO",
  Debug          = false,
  lid            = nil,
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
  rtb            = nil,
  carrierstop    = nil,
  alias          = nil,
  uid            =   0,
  modex          = nil,
  dtFollow       = nil,
}

--- Unique ID (global).
-- @field #number uid Unique ID (global).
_RESCUEHELOID=0

--- Class version.
-- @field #string version
RESCUEHELO.version="1.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- NOPE: Add messages for rescue mission.
-- NOPE: Add option to stop carrier while rescue operation is in progress? Done but NOT working. Postponed...
-- DONE: Write documentation.
-- DONE: Add option to deactivate the rescuing.
-- DONE: Possibility to add already present/spawned aircraft, e.g. for warehouse.
-- DONE: Add rescue event when aircraft crashes.
-- DONE: Make offset input parameter.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new RESCUEHELO object. 
-- @param #RESCUEHELO self
-- @param Wrapper.Unit#UNIT carrierunit Carrier unit object or simply the unit name.
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
  
  -- Increase ID.
  _RESCUEHELOID=_RESCUEHELOID+1
  
  -- Unique ID of this helo.
  self.uid=_RESCUEHELOID
  
  -- Save self in static object. Easier to retrieve later.
  self.carrier:SetState(self.carrier, string.format("RESCUEHELO_%d", self.uid) , self)
  
  -- Set unique spawn alias.
  self.alias=string.format("%s_%s_%02d", self.carrier:GetName(), self.helogroupname, _RESCUEHELOID)
  
  -- Log ID.
  self.lid=string.format("RESCUEHELO %s | ", self.alias)
    
  -- Init defaults.  
  self:SetHomeBase(AIRBASE:FindByName(self.carrier:GetName()))
  self:SetTakeoffHot()
  self:SetLowFuelThreshold()
  self:SetAltitude()
  self:SetOffsetX()
  self:SetOffsetZ()
  self:SetRespawnOn()
  self:SetRescueOn()
  self:SetRescueZone()
  self:SetRescueHoverSpeed()
  self:SetRescueDuration()
  self:SetFollowTimeInterval()
  self:SetRescueStopBoatOff()
  
  -- Some more.
  self.rtb=false
  self.carrierstop=false
  
  -- Debug trace.
  if false then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end
  
  -----------------------
  --- FSM Transitions ---
  -----------------------
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->  Event    -->  To State
  self:AddTransition("Stopped",       "Start",      "Running")
  self:AddTransition("Running",       "Rescue",     "Rescuing")
  self:AddTransition("Running",       "RTB",        "Returning")
  self:AddTransition("Rescuing",      "RTB",        "Returning")
  self:AddTransition("Returning",     "Returned",   "Returned")
  self:AddTransition("Running",       "Run",        "Running")
  self:AddTransition("Returned",      "Run",        "Running")
  self:AddTransition("*",             "Status",     "*")
  self:AddTransition("*",             "Stop",       "Stopped")


  --- Triggers the FSM event "Start" that starts the rescue helo. Initializes parameters and starts event handlers.
  -- @function [parent=#RESCUEHELO] Start
  -- @param #RESCUEHELO self

  --- Triggers the FSM event "Start" that starts the rescue helo after a delay. Initializes parameters and starts event handlers.
  -- @function [parent=#RESCUEHELO] __Start
  -- @param #RESCUEHELO self
  -- @param #number delay Delay in seconds.

  --- On after "Start" event function. Called when FSM is started.
  -- @function [parent=#RESCUEHELO] OnAfterStart
  -- @param #RECOVERYTANKER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- Triggers the FSM event "Rescue" that sends the helo on a rescue mission to a specifc coordinate.
  -- @function [parent=#RESCUEHELO] Rescue
  -- @param #RESCUEHELO self
  -- @param Core.Point#COORDINATE RescueCoord Coordinate where the resue mission takes place.

  --- Triggers the delayed FSM event "Rescue" that sends the helo on a rescue mission to a specifc coordinate.
  -- @function [parent=#RESCUEHELO] __Rescue
  -- @param #RESCUEHELO self
  -- @param #number delay Delay in seconds.
  -- @param Core.Point#COORDINATE RescueCoord Coordinate where the resue mission takes place.

  --- On after "Rescue" event user function. Called when a the the helo goes on a rescue mission.
  -- @function [parent=#RESCUEHELO] OnAfterRescue
  -- @param #RESCUEHELO self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Core.Point#COORDINATE RescueCoord Crash site where the rescue operation takes place.


  --- Triggers the FSM event "RTB" that sends the helo home.
  -- @function [parent=#RESCUEHELO] RTB
  -- @param #RESCUEHELO self
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase to return to. Default is the home base.

  --- Triggers the FSM event "RTB" that sends the helo home after a delay.
  -- @function [parent=#RESCUEHELO] __RTB
  -- @param #RESCUEHELO self
  -- @param #number delay Delay in seconds.
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase to return to. Default is the home base.

  --- On after "RTB" event user function. Called when a the the helo returns to its home base.
  -- @function [parent=#RESCUEHELO] OnAfterRTB
  -- @param #RESCUEHELO self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase to return to. Default is the home base.


  --- Triggers the FSM event "Returned" after the helo has landed.
  -- @function [parent=#RESCUEHELO] Returned
  -- @param #RESCUEHELO self
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase the helo has landed.

  --- Triggers the delayed FSM event "Returned" after the helo has landed.
  -- @function [parent=#RESCUEHELO] __Returned
  -- @param #RESCUEHELO self
  -- @param #number delay Delay in seconds.
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase the helo has landed.

  --- On after "Returned" event user function. Called when a the the helo has landed at an airbase.
  -- @function [parent=#RESCUEHELO] OnAfterReturned
  -- @param #RESCUEHELO self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param Wrapper.Airbase#AIRBASE airbase The airbase the helo has landed.


  --- Triggers the FSM event "Run".
  -- @function [parent=#RESCUEHELO] Run
  -- @param #RESCUEHELO self

  --- Triggers the delayed FSM event "Run".
  -- @function [parent=#RESCUEHELO] __Run
  -- @param #RESCUEHELO self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Status" that updates the helo status.
  -- @function [parent=#RESCUEHELO] Status
  -- @param #RESCUEHELO self

  --- Triggers the delayed FSM event "Status" that updates the helo status.
  -- @function [parent=#RESCUEHELO] __Status
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

--- Set home airbase of the helo. This is the airbase where the helo is spawned (if not in air) and will go when it is out of fuel.
-- @param #RESCUEHELO self
-- @param Wrapper.Airbase#AIRBASE airbase The home airbase. Can be the airbase name (passed as a string) or a Moose AIRBASE object.
-- @return #RESCUEHELO self
function RESCUEHELO:SetHomeBase(airbase)
  if type(airbase)=="string" then
    self.airbase=AIRBASE:FindByName(airbase)
  else
    self.airbase=airbase
  end
  if not self.airbase then
    self:E(self.lid.."ERROR: Airbase is nil!")
  end
  return self
end

--- Set rescue zone radius. Crashed or ejected units inside this radius of the carrier will be rescued if possible.
-- @param #RESCUEHELO self
-- @param #number radius Radius of rescue zone in nautical miles. Default is 15 NM.
-- @return #RESCUEHELO self
function RESCUEHELO:SetRescueZone(radius)
  radius=UTILS.NMToMeters(radius or 15)
  self.rescuezone=ZONE_UNIT:New("Rescue Zone", self.carrier, radius)
  return self
end

--- Set rescue hover speed.
-- @param #RESCUEHELO self
-- @param #number speed Speed in knots. Default 5 kts.
-- @return #RESCUEHELO self
function RESCUEHELO:SetRescueHoverSpeed(speed)
  self.rescuespeed=UTILS.KnotsToMps(speed or 5)
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

--- Set offset parallel to orientation of carrier.
-- @param #RESCUEHELO self
-- @param #number distance Offset distance in meters. Default 200 m (~660 ft).
-- @return #RESCUEHELO self
function RESCUEHELO:SetOffsetX(distance)
  self.offsetX=distance or 200
  return self
end

--- Set offset perpendicular to orientation to carrier.
-- @param #RESCUEHELO self
-- @param #number distance Offset distance in meters. Default 240 m (~780 ft).
-- @return #RESCUEHELO self
function RESCUEHELO:SetOffsetZ(distance)
  self.offsetZ=distance or 240
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

--- Set modex (tail number) of the helo.
-- @param #RESCUEHELO self
-- @param #number modex Tail number.
-- @return #RESCUEHELO self
function RESCUEHELO:SetModex(modex)
  self.modex=modex
  return self
end

--- Set follow time update interval.
-- @param #RESCUEHELO self
-- @param #number dt Time interval in seconds. Default 1.0 sec.
-- @return #RESCUEHELO self
function RESCUEHELO:SetFollowTimeInterval(dt)
  self.dtFollow=dt or 1.0
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

--- Activate debug mode. Display debug messages on screen.
-- @param #RESCUEHELO self
-- @return #RESCUEHELO self
function RESCUEHELO:SetDebugModeON()
  self.Debug=true
  return self
end

--- Deactivate debug mode. This is also the default setting.
-- @param #RESCUEHELO self
-- @return #RESCUEHELO self
function RESCUEHELO:SetDebugModeOFF()
  self.Debug=false
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

--- Check if FMS was stopped.
-- @param #RESCUEHELO self
-- @return #boolean If true, is stopped. 
function RESCUEHELO:IsStopped()
  return self:is("Stopped")
end

--- Alias of helo spawn group.
-- @param #RESCUEHELO self
-- @return #string Alias of the helo. 
function RESCUEHELO:GetAlias()
  return self.alias
end

--- Get unit name of the spawned helo.
-- @param #RESCUEHELO self
-- @return #string Name of the helo unit or nil if it does not exist. 
function RESCUEHELO:GetUnitName()
  local unit=self.helo:GetUnit(1)
  if unit then
    return unit:GetName()
  end
  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EVENT functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Handle landing event of rescue helo.
-- @param #RESCUEHELO self
-- @param Core.Event#EVENTDATA EventData Event data.
function RESCUEHELO:OnEventLand(EventData)
  local group=EventData.IniGroup --Wrapper.Group#GROUP
  
  if group and group:IsAlive() then
  
    -- Group name that landed.
    local groupname=group:GetName()
  
    -- Check that it was our helo that landed.
    if groupname==self.helo:GetName() then
    
      local airbase=nil --Wrapper.Airbase#AIRBASE
      local airbasename="unknown"
      if EventData.Place then
        airbase=EventData.Place
        airbasename=airbase:GetName()
      end
    
      -- Respawn the Helo.
      local text=string.format("Rescue helo group %s landed at airbase %s.", groupname, airbasename)
      MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
      self:T(self.lid..text)
      
      -- Helo has rescued someone.
      -- TODO: Add "Rescued" event.
      if self:IsRescuing() then        
        self:T(self.lid..string.format("Rescue helo %s returned from rescue operation.", groupname))
      end
      
      -- Check if takeoff air or respawn in air is set. Landing event should not happen unless the helo was on a rescue mission.
      if self.takeoff==SPAWN.Takeoff.Air or self.respawninair then
        
        if not self:IsRescuing() then

          self:E(self.lid..string.format("WARNING: Rescue helo %s landed. This should not happen for Takeoff=Air or respawninair=true and no rescue operation in progress.", groupname))
          
        end              
      end
      
      -- Trigger returned event. Respawn at current airbase.
      self:__Returned(3, airbase)
            
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
      local text=string.format("Unit %s crashed or ejected.", unitname)
      MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
      self:T(self.lid..text)

      -- Get coordinate of unit.      
      --local coord=unit:GetCoordinate()
      local Vec3 = EventData.IniDCSUnit:getPoint() -- Vec3
      local coord = COORDINATE:NewFromVec3(Vec3)
      
      if coord and self.rescuezone:IsCoordinateInZone(coord) then
      
      -- This does not seem to work any more. Is:Alive returns flase on ejection.
      -- Unit "alive" and in our rescue zone.
      --if unit:IsAlive() and unit:IsInZone(self.rescuezone) then
        -- Get coordinate of crashed unit.
        --local coord=unit:GetCoordinate()
        
        -- Debug mark on map.
        if self.Debug then
          coord:MarkToCoalition(self.lid..string.format("Crash site of unit %s.", unitname), self.helo:GetCoalition())
        end
        
        -- Check that coalition is the same.
        local rightcoalition=EventData.IniGroup:GetCoalition()==self.helo:GetCoalition()
      
        -- Only rescue if helo is "running" and not, e.g., rescuing already.
        if self:IsRunning() and self.rescueon and rightcoalition then 
          self:Rescue(coord)
        end
      
      end
      
    else
    
      -- Error message.
      self:E(self.lid..string.format("Rescue helo %s crashed!", unitname))
      
      -- Stop FSM.
      self:Stop()
      
      -- Restart.
      if self.respawn then
        self:__Start(5)
      end
    
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
  local text=string.format("Starting Rescue Helo Formation v%s for carrier unit %s of type %s.", RESCUEHELO.version, self.carrier:GetName(), self.carriertype)
  self:I(self.lid..text)
  
  -- Handle events.
  self:HandleEvent(EVENTS.Land)
  self:HandleEvent(EVENTS.Crash,    self._OnEventCrashOrEject)
  self:HandleEvent(EVENTS.Ejection, self._OnEventCrashOrEject)
  
  -- Delay before formation is started.
  local delay=120
    
  -- Spawn helo. We need to introduce an alias in case this class is used twice. This would confuse the spawn routine.
  local Spawn=SPAWN:NewWithAlias(self.helogroupname, self.alias)
  
  -- Set modex for spawn.
  Spawn:InitModex(self.modex)

  -- Spawn in air or at airbase.
  if self.takeoff==SPAWN.Takeoff.Air then
  
    -- Carrier heading
    local hdg=self.carrier:GetHeading()
    
    -- Spawn distance in front of carrier.
    local dist=UTILS.NMToMeters(0.2)
    
    -- Coordinate behind the carrier. Altitude at least 100 meters for spawning because it drops down a bit.
    local Carrier=self.carrier:GetCoordinate():Translate(dist, hdg):SetAltitude(math.max(100, self.altitude))
    
    -- Orientation of spawned group.
    Spawn:InitHeading(hdg)
    
    -- Spawn at coordinate.
    self.helo=Spawn:SpawnFromCoordinate(Carrier)
    
    -- Start formation in 1 seconds
    delay=1
    
  else  
 
    -- Check if an uncontrolled helo group was requested.
    if self.uncontrolledac then
    
      -- Use an uncontrolled aircraft group.
      self.helo=GROUP:FindByName(self.helogroupname)
      
      if self.helo and self.helo:IsAlive() then
      
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
      self.helo=Spawn:SpawnAtAirbase(self.airbase, self.takeoff, nil, AIRBASE.TerminalType.HelicopterUsable)
      
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
  
  -- Set follow time interval.
  self.formation:SetFollowTimeInterval(self.dtFollow)
  
  -- Formation mode.
  self.formation:SetFlightModeFormation(self.helo)
  
  -- Start formation FSM.
  self.formation:__Start(delay)
  
  -- Init status check
  self:__Status(1)
  
  return self
end

--- On after Status event. Checks player status.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RESCUEHELO:onafterStatus(From, Event, To)

  -- Get current time.
  local time=timer.getTime()

  -- Check if helo is running and not RTBing already or rescuing.
  if self.helo and self.helo:IsAlive() then

    -------------------
    -- HELO is ALIVE --
    ------------------- 

    -- Get (relative) fuel wrt to initial fuel of helo (DCS bug https://forums.eagle.ru/showthread.php?t=223712)
    local fuel=self.helo:GetFuel()*100
    local fuelrel=fuel/self.HeloFuel0
    local life=self.helo:GetUnit(1):GetLife()
    local life0=self.helo:GetUnit(1):GetLife0()
    local lifeR=self.helo:GetUnit(1):GetLifeRelative()
  
    -- Report current fuel.
    local text=string.format("Rescue Helo %s: state=%s fuel=%.1f, rel.fuel=%.1f, life=%.1f/%.1f=%d", self.helo:GetName(), self:GetState(), fuel, fuelrel, life, life0, lifeR*100)
    MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
    self:T(self.lid..text)
  
    if self:IsRunning() then
    
      -- Check if fuel is low.
      if fuel<self.lowfuel then
      
        -- Check if spawn in air is activated.
        if self.takeoff==SPAWN.Takeoff.Air or self.respawninair then
        
          -- Check if respawn is enabled.
          if self.respawn then
          
            -- Set modex for respawn.
            self.helo:InitModex(self.modex)
            
            -- Respawn helo in air.
            self.helo=self.helo:Respawn(nil, true)
            
            -- XXX: ATTENTION: if helo automatically RTBs on low fuel, it goes a bit crazy. The formation is not stopped and he partially dives into the water.
            -- Also trying to find a ship to land on he flies right through it.            
            --self.helo:OptionRTBBingoFuel(false)
            
          end
          
        else
        
          -- Send helo back to base.
          self:RTB(self.airbase)
        
        end
      
      end
      
    elseif self:IsRescuing() then
    
      -- Helo is on a rescue mission.
    
    end

    -- Call status again in 30 seconds.
    if not self:IsStopped() then
      self:__Status(-30)
    end

  else
  
    ------------------
    -- HELO is DEAD --
    ------------------
    
    if not self:IsStopped() then
    
      self:E(self.lid.."Rescue helo is NOT alive (and not stopped)!")
    
      -- Stop FSM.
      self:Stop()
      
      -- Restart FSM after 5 seconds.
      if self.respawn then
        self:__Start(5)
      end
      
    end
  end
    
end

--- On after "Run" event. FSM will go to "Running" state. If formation is stopped, it will be started again.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RESCUEHELO:onafterRun(From, Event, To)
  
  -- Restart formation if stopped.
  if self.formation:Is("Stopped") then
    -- Debug info.
    local text=string.format("Restarting formation of rescue helo %s.", self.helo:GetName())
    MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
    self:T(self.lid..text)
    
    -- Start formation.
    self.formation:Start()
  end
  
end


--- Task to send the helo RTB.
-- @param #RESCUEHELO self
-- @return DCS#Task DCS Task table.
function RESCUEHELO:_TaskRTB()
  
  -- Set RTB switch so on next status update, the helo is respawned with RTB waypoints.
  --rescuehelo.rtb=true

  -- Name of the warehouse (static) object.
  local carriername=self.carrier:GetName()

  -- Task script.
  local DCSScript = {}
  DCSScript[#DCSScript+1] = string.format('local mycarrier = UNIT:FindByName(\"%s\") ', carriername)                       -- The carrier unit that holds the self object.
  DCSScript[#DCSScript+1] = string.format('local myhelo    = mycarrier:GetState(mycarrier, \"RESCUEHELO_%d\") ', self.uid) -- Get the RESCUEHELO self object.
  DCSScript[#DCSScript+1] = string.format('myhelo:RTB()')                                                                  -- Call the function, e.g. myhelo.(self)

  -- Create task.
  local DCSTask = CONTROLLABLE.TaskWrappedAction(self, CONTROLLABLE.CommandDoScript(self, table.concat(DCSScript)))

  return DCSTask
  
  -- This made DCS crash to desktop!
  --rescuehelo:RTB()
end

--- On after "Rescue" event. Helo will fly to the given coordinate, orbit there for 5 minutes and then return to the carrier.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Point#COORDINATE RescueCoord Coordinate where the rescue should happen.
function RESCUEHELO:onafterRescue(From, Event, To, RescueCoord)

  -- Debug message.
  local text=string.format("Helo %s is send to rescue mission.", self.helo:GetName())
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:I(self.lid..text)
  
  -- Waypoint array.
  local wp={}
  
  --local RescueTask=self.helo:TaskControlled(self.helo:TaskOrbitCircle(20, 2, RescueCoord), self.helo:TaskCondition(nil, nil, nil, nil, 5*60, nil))
   
  -- Rescue task: Orbit at crash site for ~5 minutes at 20 meters altitude and ~10 km/h.
  local RescueTask={}
  RescueTask.id="ControlledTask"
  RescueTask.params={}
  RescueTask.params.task=self.helo:TaskOrbit(RescueCoord, 20, self.rescuespeed)
  RescueTask.params.stopCondition={duration=self.rescueduration}
  
  -- Passing waypoint taskfunction
  --local TaskRTB=self.helo:TaskFunction("RESCUEHELO._TaskRTB", self)
  local TaskRTB=self:_TaskRTB()
  
  -- Rescue speed 90% of max possible.
  local speed=self.helo:GetSpeedMax()*0.9
  
  -- Set Waypoints:
  
  -- Current position.
  wp[1]=self.helo:GetCoordinate():WaypointAirTurningPoint(nil, speed, {}, "Current Position")
  
  -- Go to crash site and hover a bit.
  wp[2]=RescueCoord:SetAltitude(50):WaypointAirTurningPoint(nil, speed, {RescueTask, TaskRTB}, "Crash Site")
  
  -- Route helo back home and respawn next status update.
  wp[3]=self.airbase:GetCoordinate():SetAltitude(50):WaypointAirTurningPoint(nil, speed, {}, "RTB")
  
  -- Unfortunately not possible reliably due to DCS bug that units dont land or just land on any nearby base.
  --wp[3]=self.airbase:GetCoordinate():SetAltitude(70):WaypointAirLanding(200, self.airbase, {}, "Land at Home Base")

  -- Initialize WP and route helo.
  self.helo:WayPointInitialize(wp)

  -- Set task.
  self.helo:Route(wp, 1)
  
  -- Stop formation.
  self.formation:Stop()
  
end

--- On after RTB event. Send helo back to carrier.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The base to return to. Default is the home base.
function RESCUEHELO:onafterRTB(From, Event, To, airbase)

  -- Set airbase.
  airbase=airbase or self.airbase

  -- Debug message.
  local text=string.format("Rescue helo %s is returning to airbase %s.", self.helo:GetName(), airbase:GetName())
  MESSAGE:New(text, 10, "DEBUG"):ToAllIf(self.Debug)
  self:T(self.lid..text)
  
  -- Stop formation.
  if From=="Running" then
    self.formation:Stop()
  end
    
  -- Route helo back home. It is respawned! But this is the only way to ensure that it actually lands at the airbase.
  self:RouteRTB(airbase)
end

--- On after Returned event. Helo has landed.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Airbase#AIRBASE airbase The base to which the helo has returned.
function RESCUEHELO:onafterReturned(From, Event, To, airbase)

  if airbase then
    local airbasename=airbase:GetName()
    self:I(self.lid..string.format("Helo returned to airbase %s", tostring(airbasename)))
  else
    self:E(self.lid..string.format("WARNING: Helo landed but airbase (EventData.Place) is nil!"))
  end
  
  -- Respawn helo at current airbase.
  if self.respawn then
  
    -- Set modex for respawn.
    self.helo:InitModex(self.modex)
  
    -- Respawn helo at current airbase.
    if self.helo and self.helo:IsAlive() then
      self:ScheduleOnce(5, self.helo.RespawnAtCurrentAirbase, self.helo)
    end
    
    -- Restart the formation.
    self:__Run(10)
  end  

end

--- On after Stop event. Unhandle events and stop status updates. If helo is alive, it is despawned.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RESCUEHELO:onafterStop(From, Event, To)

  -- Stop formation
  self.formation:Stop()
    
  -- Unhandle events.
  self:UnHandleEvent(EVENTS.Land)
  self:UnHandleEvent(EVENTS.Crash)
  self:UnHandleEvent(EVENTS.Ejection)
  
  -- Clear all pending FSM events.
  self.CallScheduler:Clear()

  -- If helo is alive, despawn it.
  if self.helo and self.helo:IsAlive() then
    self:I(self.lid.."Stopping FSM and despawning helo.")
    self.helo:Destroy()
  else
    self:I(self.lid.."Stopping FSM. Helo was not alive.")
  end
  
end


--- Route helo back to its home base.
-- @param #RESCUEHELO self
-- @param Wrapper.Airbase#AIRBASE RTBAirbase
-- @param #number Speed Speed.
function RESCUEHELO:RouteRTB(RTBAirbase, Speed)

  -- If speed is not given take 80% of max speed.
  local Speed=Speed or self.helo:GetSpeedMax()*0.8
  
  -- Curent (from) waypoint.
  local coord=self.helo:GetCoordinate()
  local PointFrom=coord:WaypointAirTurningPoint(nil, Speed, {}, "Current")
  
  -- Airbase coordinate.
  --local PointAirbase=RTBAirbase:GetCoordinate():SetAltitude(100):WaypointAirTurningPoint(nil ,Speed)
  
  -- Landing waypoint. More general than prev version since it should also work with FAPRS and ships.
  local PointLanding=RTBAirbase:GetCoordinate():SetAltitude(20):WaypointAirLanding(Speed, RTBAirbase, {}, "Landing")
  
  -- Waypoint table.
  local Points={PointFrom, PointLanding}
  
  -- Get group template.
  local Template=self.helo:GetTemplate()
  
  -- Set route points.
  Template.route.points=Points
  
  -- Set modex for respawn.
  self.helo:InitModex(self.modex)          
    
  -- Respawn the group.
  self.helo=self.helo:Respawn(Template, true)
  
  -- Route the group or this will not work.
  self.helo:Route(Points, 1)
  
  return self
end


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
