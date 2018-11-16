--- **Functional** - (R2.5) - Rescue helo.
-- 
-- Recue helicopter on an aircraft carrier.
--
-- Features:
--
--    * Formation with carrier.
--    * Automatic respawning on empty fuel.
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
-- @field Wrapper.Airbase#AIRBASE airbase The airbase object of the carrier.
-- @field Core.Set#SET_GROUP followset Follow group set.
-- @field AI.AI_Formation#AI_FORMATION formation AI_FORMATION object.
-- @field #number lowfuel Low fuel threshold of helo in percent.
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
  ClassName = "RESCUEHELO",
  carrier       = nil,
  carriertype   = nil,
  helogroupname = nil,
  helo          = nil,
  airbase       = nil,
  takeoff       = nil,
  followset     = nil,
  formation     = nil,
  lowfuel       = nil,
}

--- Class version.
-- @field #string version
RESCUEHELO.version="0.9.0w"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Write documenation.
-- TODO: Add rescue event when aircraft crashes.
-- TODO: Make offset input parameter.

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
  
  if type(carrierunit)=="string" then
    self.carrier=UNIT:FindByName(carrierunit)
  else
    self.carrier=carrierunit
  end
  
  -- Carrier type.
  self.carriertype=self.carrier:GetTypeName()
  
  -- Helo group name.
  self.helogroupname=helogroupname
  
  -- Home airbase of helo
  self.airbase=AIRBASE:FindByName(self.carrier:GetName())
  
  -- Init defaults.  
  self:SetHomeBase(AIRBASE:FindByName(self.carrier:GetName()))
  self:SetTakeoffHot()
  self:SetLowFuelThreshold(10)

  -----------------------
  --- FSM Transitions ---
  -----------------------
  
  -- Start State.
  self:SetStartState("Stopped")

  -- Add FSM transitions.
  --                 From State  -->   Event   -->   To State
  self:AddTransition("Stopped",       "Start",      "Running")
  self:AddTransition("Running",       "RTB",        "Returning")
  self:AddTransition("Returning",     "Status",     "*")
  self:AddTransition("Running",       "Status",     "*")
  self:AddTransition("Running",       "Stop",       "Stopped")


  --- Triggers the FSM event "Start" that starts the rescue helo. Initializes parameters and starts event handlers.
  -- @function [parent=#RESCUEHELO] Start
  -- @param #RESCUEHELO self

  --- Triggers the FSM event "Start" that starts the rescue helo after a delay. Initializes parameters and starts event handlers.
  -- @function [parent=#RESCUEHELO] __Start
  -- @param #RESCUEHELO self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "RTB" that sends the helo home.
  -- @function [parent=#RESCUEHELO] RTB
  -- @param #RESCUEHELO self

  --- Triggers the FSM event "RTB" that sends the helo home after a delay.
  -- @function [parent=#RESCUEHELO] __RTB
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
-- @param #number threshold Low fuel threshold in percent. Default 10.
-- @return #RESCUEHELO self
function RESCUEHELO:SetLowFuelThreshold(threshold)
  self.lowfuel=threshold or 10
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

--- Set takeoff type.
-- @param #RESCUEHELO self
-- @param #number takeofftype Takeoff type.
-- @return #RESCUEHELO self
function RESCUEHELO:SetTakeoff(takeofftype)
  self.takeoff=takeofftype
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


--- Check if tanker is returning to base.
-- @param #RESCUEHELO self
-- @return #boolean If true, helo is returning to base. 
function RESCUEHELO:IsReturning()
  return self:is("Returning")
end

--- Check if tanker is operating.
-- @param #RESCUEHELO self
-- @return #boolean If true, helo is operating. 
function RESCUEHELO:IsRunning()
  return self:is("Running")
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
  --self:HandleEvent(EVENTS.Crash)
  
  -- Offset [meters] in the direction of travelling. Positive values are in front of Mother.
  local OffsetX=200
  -- Offset [meters] perpendicular to travelling. Positive = Starboard (right of Mother), negative = Port (left of Mother).
  local OffsetZ=200
  -- Offset altitude. Should (obviously) always be positve.
  local OffsetY=70
  
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
    local Carrier=self.carrier:GetCoordinate():SetAltitude(OffsetY):Translate(dist, hdg)
    
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
  self.formation:FormationCenterWing(-OffsetX, 50, math.abs(OffsetY), 50, OffsetZ, 50)
  
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
  if fuel<self.lowfuel then
    self:RTB()
  end
  
  -- Call status again in one minute.
  self:__Status(-60)
end

--- On after Stop event. Unhandle events and stop status updates.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function RESCUEHELO:onafterStop(From, Event, To)
  --self:UnHandleEvent(EVENTS.Birth)
  self:UnHandleEvent(EVENTS.Land)
end

--- Handle landing event of rescue helo.
-- @param #RESCUEHELO self
-- @param Core.Event#EVENTDATA EventData Event data.
function RESCUEHELO:OnEventLand(EventData)
  local group=EventData.IniGroup --Wrapper.Group#GROUP
  
  if group:IsAlive() then
    local groupname=group:GetName()
  
    if groupname:match(self.helogroupname) then
    
      -- Respawn the Helo.
      self:I(string.format("Respawning rescue helo group group %s at home base.", groupname))
      
      if self.takeoff==SPAWN.Takeoff.Air then
        
        self:E("ERROR: Rescue helo %s landed. This should not happen for Takeoff=Air!", groupname)
      
      else
      
        -- Respawn helo at current airbase.
        self.helo=group:RespawnAtCurrentAirbase()
        
      end
      
      -- Restart the formation.
      self.formation:__Start(10)
    end
  end
end

--- On before RTB event. Check if takeoff type is air and if so respawn the helo and deny RTB transition.
-- @param #RESCUEHELO self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean If true, transition is allowed.
function RESCUEHELO:onbeforeRTB(From, Event, To)

  if self.takeoff==SPAWN.Takeoff.Air then
  
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
    local text=string.format("Helo %s returning to airbase %s.", self.helo:GetName(), self.airbase:GetName())
    self:I(text)
    
    local waypoints={}
    
    -- Set landingwaypoint
    local wp=self.carrier:GetCoordinate():WaypointAirLanding(300, self.airbase, nil, "Landing")
    table.insert(waypoints, wp)

    -- Initialize WP and route tanker.
    self.helo:WayPointInitialize(waypoints)
  
    -- Set task.
    self.helo:Route(waypoints, 1)
    
    -- Stop formation.
    self.formation:Stop()
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
