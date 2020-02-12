--- **Ops** - (R2.5) - Airwing Warehouse.
--
-- **Main Features:**
--
--    * Manage squadrons.
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Airwing
-- @image OPS_AirWing.png


--- AIRWING class.
-- @type AIRWING
-- @field #string ClassName Name of the class.
-- @field #boolean Debug Debug mode. Messages to all about status.
-- @field #string sid Class id string for output to DCS log file.
-- @field #string carriername The name of the carrier unit.
-- @field #table menu Table of menu items.
-- @field #table squadrons Table of squadrons.
-- @extends Functional.Warehouse#WAREHOUSE

--- Be surprised!
--
-- ===
--
-- ![Banner Image](..\Presentations\CarrierAirWing\AIRWING_Main.jpg)
--
-- # The AIRWING Concept
--
--
--
-- @field #AIRWING
AIRWING = {
  ClassName      = "AIRWING",
  sid            =   nil,
  carriername    =   nil,
  menu           =   nil,
  squadrons      =   nil,
  taskqueue      =    {},
}

--- Squadron
-- @type AIRWING.Squadron
-- @field #string name Name of the squadron.
-- @field #table assets Assets of the squadron.
-- @field #table tasks Task(s) of the squadron.
-- @field #string livery Livery of the squadron.
-- @field DCS#Coalition.Side coalition Coalition side.
-- @field #number threadlevel Thread level of intruder.
-- @field #string threadtext Thread text.
-- @field #number category Group category.
-- @field #string categoryname Group category name.
-- @field #string typename Type name of group.
-- @field #table menu The squadron menu entries.


--- Squadron tasks.
-- @type AIRWING.Task
-- @param #string INTERCEPT Intercept task.
-- @param #string CAP Combat Air Patrol task.s
-- @param #string BAI Battlefield Air Interdiction task.
-- @param #string SEAD Suppression/destruction of enemy air defences.
-- @param #string STRIKE Strike task.
-- @param #string AWACS AWACS task.
-- @param #string TANKER Tanker task.
AIRWING.Task={
  INTERCEPT="Intercept",
  CAP="CAP",
  BAI="BAI",
  SEAD="SEAD",
  STRIKE="Strike",
  CAS="CAS",
  AWACS="AWACS",
  TANKER="Tanker",
}

--- Mission.
-- @type AIRWING.Mission
-- @field #string type Mission type.
-- @field #string squadname Name of the assigned squadron.
-- @field #number nassets Number of required assets.

--- AIRWING class version.
-- @field #string version
AIRWING.version="0.0.5"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot!

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new AIRWING class object for a specific aircraft carrier unit.
-- @param #AIRWING self
-- @param #string warehousename Name of the warehouse static or unit object representing the warehouse.
-- @param #string airwingname Name of the air wing, e.g. "AIRWING-8".
-- @return #AIRWING self
function AIRWING:New(warehousename, airwingname)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, WAREHOUSE:New(warehousename, airwingname)) -- #AIRWING

  if not self then
    BASE:E(string.format("ERROR: Could not find warehouse %s!", warehousename))
    return nil
  end

  self.warehousename=warehousename

  self.squadrons={}


  -- Set some string id for output to DCS.log file.
  self.sid=string.format("AIRWING %s |", airwingname)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "AirwingStatus",    "*")           -- AIRWING status update.
  
  self:AddTransition("*",             "NewMission",        "*")           -- Request CAP flight.
  
  self:AddTransition("*",             "RequestCAP",       "*")           -- Request CAP flight.
  self:AddTransition("*",             "RequestIntercept", "*")           -- Request Intercept.
  self:AddTransition("*",             "RequestCAS",       "*")           -- Request CAS.
  self:AddTransition("*",             "RequestSEAD",      "*")           -- Request SEAD.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the AIRWING. Initializes parameters and starts event handlers.
  -- @function [parent=#AIRWING] Start
  -- @param #AIRWING self

  --- Triggers the FSM event "Start" after a delay. Starts the AIRWING. Initializes parameters and starts event handlers.
  -- @function [parent=#AIRWING] __Start
  -- @param #AIRWING self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the AIRWING and all its event handlers.
  -- @param #AIRWING self

  --- Triggers the FSM event "Stop" after a delay. Stops the AIRWING and all its event handlers.
  -- @function [parent=#AIRWING] __Stop
  -- @param #AIRWING self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "SkipperStatus".
  -- @function [parent=#AIRWING] AirwingStatus
  -- @param #AIRWING self

  --- Triggers the FSM event "SkipperStatus" after a delay.
  -- @function [parent=#AIRWING] __AirwingStatus
  -- @param #AIRWING self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "RequestCAP".
  -- @function [parent=#AIRWING] RequestCAP
  -- @param #AIRWING self
  -- @param Core.Point#COORDINATE coordinate
  -- @param #number altitude Altitude
  -- @param #number leg Race track length.
  -- @param #number heading Heading in degrees.
  -- @param #number speed Speed in knots.
  -- @param #AIRWING.Squadron squadron Explicitly request a specific squadron.


  -- Debug trace.
  if true then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a squadron to the carrier air wing.
-- @param #AIRWING self
-- @param #string name Name of the squadron, e.g. "VFA-37".
-- @param #table tasks Table of tasks the squadron is supposed to do.
-- @param #string livery The livery for all added flight group. Default is the livery of the template group.
-- @return #AIRWING.Squadron The squadron object.
function AIRWING:AddSquadron(name, tasks, livery)

  local squadron={} --#AIRWING.Squadron

  squadron.name=name
  squadron.assets={}
  squadron.tasks=tasks or {}
  squadron.livery=livery

  table.insert(self.squadrons, squadron)
  
  return squadron
end

--- Add flight group(s) to squadron.
-- @param #AIRWING self
-- @param #AIRWING.Squadron squadron The squadron object.
-- @param Wrapper.Group#GROUP flightgroup The flight group object.
-- @param #number ngroups Number of groups to add.
-- @return #AIRWING self
function AIRWING:AddFlightToSquadron(squadron, flightgroup, ngroups)

  local text=string.format("FF Adding asset %s to squadron %s", flightgroup:GetName(), squadron.name)
  env.info(text)

  self:AddAsset(flightgroup, ngroups, nil, nil, nil, nil, nil, {squadron.livery}, squadron.name)

  return self
end

--- Get squadron by name
-- @param #AIRWING self
-- @param #string name Name of the squadron, e.g. "VFA-37".
-- @return #AIRWING self or nil.
function AIRWING:GetSquadron(name)

  for _,_squadron in pairs(self.squadrons) do
    if _squadron.name==name then
      return _squadron
    end
  end

  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start AIRWING FSM.
-- @param #AIRWING self
function AIRWING:onafterStart(From, Event, To)

  -- Start parent Warehouse.
  self:GetParent(self).onafterStart(self, From, Event, To)

  -- Info.
  self:I(self.sid..string.format("Starting AIRWING v%s for carrier %s", AIRWING.version, self.carriername))

  -- Add F10 radio menu.
  self:_SetMenuCoalition()

  for _,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --#AIRWING.Squadron
    self:_AddSquadonMenu(squadron)
  end

  -- Init status updates.
  self:__AirwingStatus(-1)
end

--- Update status.
-- @param #AIRWING self
function AIRWING:onafterAirwingStatus(From, Event, To)

  local fsmstate=self:GetState()
  
    -- Info text.
  local text=string.format("State %s", fsmstate)
  self:I(self.sid..text)
  
  local text="Squadrons:"
  for i,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --#AIRWING.Squadron
    
    
    text=text..string.format("\n %s", squadron.name)
    
    for j,_asset in pairs(squadron.assets) do
      local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
      local assignment=asset.assignment or "none"
      local name=asset.templatename
      local task=asset.AIRWINGtask or "none"
      local spawned=tostring(asset.spawned)
      local groupname=asset.spawngroupname
      local group=nil --Wrapper.Group#GROUP
      local typename=asset.unittype
      local fuel=100
      if groupname then
        group=GROUP:FindByName(groupname)
        fuel=group:GetFuelMin()
      end
      
      text=text..string.format("\n-[%d] %s*%d: spawned=%s, task=%s, fuel=%d", j, typename, asset.nunits, task)
      
    end
  end

  self:__AirwingStatus(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "SelfRequest" event.
-- @param #AIRWING self
function AIRWING:onafterNewAsset(From, Event, To, asset, assignment)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterNewAsset(From, Event, To, asset, assignment)
  
  local squad=self:GetSquadron(assignment)  

  if squad then

    local text=string.format("FF assignment=%s, squadron=%s", assignment, squad.name)
    env.info(text)
    
    table.insert(squad.assets, asset)
        
  end
end


--- On after "SelfRequest" event.
-- @param #AIRWING self
function AIRWING:onafterSelfRequest(From, Event, To, Groupset, Request)
  local request=Request --Functional.Warehouse#WAREHOUSE.Pendingitem
  local groupset=Groupset --Core.Set#SET_GROUP


  -- Call parent warehouse function first.
  self:GetParent(self).onafterSelfRequest(From, Event, To, Groupset, Request)

  
  for _,_asset in pairs(request.assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    
    local a=asset.cargobay
  end
  
  if Request.assignment==AIRWING.Task.CAP then
  
    for _,_group in pairs(groupset:GetSet()) do
      local group=_group --Wrapper.Group#GROUP
      
      self:LaunchCAP(group, coordinate, altitude, leg, speed, heading)
    end
    
  end

end


--- Request CAP.
-- @param #AIRWING self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Core.Point#COORDINATE coordinate
-- @param #number altitude Altitude
-- @param #number leg Race track length.
-- @param #number heading Heading in degrees.
-- @param #number speed Speed in knots.
-- @param #AIRWING.Squadron squadron Explicitly request a specific squadron.
function AIRWING:onafterRequestCAP(From, Event, To, coordinate, altitude, leg, heading, speed, squadron)

  local n=self:GetNumberOfAssets(WAREHOUSE.Descriptor.ASSIGNMENT, squadron.name, false)

  if n>0 then

    self:AddRequest(self, WAREHOUSE.Descriptor.ASSIGNMENT, squadron.name, 1, nil, nil, nil, AIRWING.Task.CAP)
    
  else
    MESSAGE:New("No CAP planes currently available", 5, "AIRWING"):ToCoalition(self:GetCoalition())
    self:__RequestCAP(-30, coordinate, altitude, leg, heading, speed, squadron)
  end
  
end

--- Launch a CAP flight.
-- @param #AIRWING self
-- @param Ops.FlightGroup#FLIGHTGROUP flightgroup Flight group.
-- @param Core.Point#COORDINATE capcoord Coordinate of CAP.
-- @param #number alt Altitude in feet. Default 20000 ft.
-- @param #number leg Length of race track pattern leg. Default 15 NM.
-- @param #number heading Heading of race track in degrees. Default 180° i.e. from North to South.
-- @param #number speed Speed in knots.
function AIRWING:LaunchCAP(flightgroup, capcoord, alt, leg, heading, speed)

  alt=UTILS.FeetToMeters(alt or 20000)
  
  speed=speed or 350
  leg=leg or 15

  -- Task orbit.
  local taskOrbit=flightgroup.group:TaskOrbit(capcoord, alt, UTILS.KnotsToMps(speed+50), capcoord:Translate(UTILS.NMToMeters(leg), heading))
  
  flightgroup:AddWaypointAir(capcoord, 2, speed)
  flightgroup:AddTaskWaypoint(taskOrbit, 2, "Orbit", 50, 60*60)
  
  
  --TODO: flightcontrol would start up the aircraft.
  flightgroup:StartUncontrolled(5)

end

--- Create a new task name.
-- @param #AIRWING self
-- @param #string task Task of type @{#AIRWING.Task}.
-- @string Task name, e.g. Task0001_CAP, Task0002_BAI, Task0003_INTERCEPT, ...
function AIRWING:_NewTaskName(task)

  self.ntasks=self.ntasks+1
  
  local taskname=string.format("Task#%04d_%s", self.ntasks, task)
  
  return taskname
end


--- Request Intercept.
-- @param #AIRWING self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Group#GROUP bandits Group of bandits to intercept.
-- @param #AIRWING.Squadron squadron Explicitly request a specific squadron.
function AIRWING:onafterRequestIntercept(From, Event, To, bandits, squadron)

  local n=self:GetNumberOfAssets(WAREHOUSE.Descriptor.ASSIGNMENT, squadron.name, false)

  if n>0 then

    self:__AddRequest(1, self, WAREHOUSE.Descriptor.ASSIGNMENT, squadron.name, 1, nil, nil, nil, AIRWING.Task.INTERCEPT)

    function self:OnAfterSelfRequest(From,Event,To,Groupset,Request)
      local request=Request --Functional.Warehouse#WAREHOUSE.Pendingitem
      local groupset=Groupset --Core.Set#SET_GROUP

      if Request.assignment==AIRWING.Task.INTERCEPT then
      
        for _,_group in pairs(groupset:GetSet()) do
          local group=_group --Wrapper.Group#GROUP
          
          self:LaunchIntercept(group)
        end
        
      end
    end
    
  else
    MESSAGE:New("No INTERCEPT fighters currently available", 5, "AIRWING"):ToCoalition(self:GetCoalition())
  end
  
end



--- Launch a flight group to intercept an intruder.
-- @param #AIRWING self
-- @param Wrapper.Group#GROUP group Interceptor flight group.
-- @param Wrapper.Group#GROUP bandits Bandit group.
function AIRWING:LaunchIntercept(group, bandit)

  -- Task orbit.
  local tasks={}
  
  for _,unit in pairs(bandit:GetUnits()) do
    tasks[#tasks+1]=group:TaskAttackUnit(unit)
  end
  
  local speed=group:GetSpeedMax()
  local altitude=bandit:GetAltitude()
  
  -- Create waypoints.
  local wp={}
  wp[1]=self:GetCoordinate():WaypointAirTakeOffParking()
  wp[2]=self:GetCoordinate():SetAltitude(altitude):WaypointAirTurningPoint(COORDINATE.WaypointAltType.BARO, speed, {tasks}, "Intercept")
  
  -- Start uncontrolled group.
  group:StartUncontrolled()
  
  --airboss:SetExcludeAI()
  
  -- Route group
  group:Route(wp)
  
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Menu Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Patrol carrier.
-- @param #AIRWING self
-- @return #AIRWING self
function AIRWING:_SetMenuCoalition()

  -- Get coalition.
  local Coalition=self:GetCoalition()

  -- Init menu table.
  self.menu=self.menu or {}

  -- Init menu coalition table.
  self.menu[Coalition]=self.menu[Coalition] or {}

  -- Shortcut.
  local menu=self.menu[Coalition]

  if self.menusingle then
    -- F10/Skipper/...
    if not menu.AIRWING then
      menu.AIRWING=MENU_COALITION:New(Coalition, "AIRWING")
    end
  else
    -- F10/Skipper/<Carrier Alias>/...
    if not menu.Root then
      menu.Root=MENU_COALITION:New(Coalition, "AIRWING")
    end
    menu.AIRWING=MENU_COALITION:New(Coalition, self.alias, menu.Root)
  end

  -------------------
  -- Squadron Menu --
  -------------------

  menu.Squadron={}
  menu.Squadron.Main= MENU_COALITION:New(Coalition, "Squadrons", menu.AIRWING)

  menu.Warehouse={}
  menu.Warehouse.Main    = MENU_COALITION:New(Coalition, "Warehouse", menu.AIRWING)
  menu.Warehouse.Reports = MENU_COALITION_COMMAND:New(Coalition, "Reports On/Off", menu.Warehouse.Main, self.WarehouseReportsToggle, self)
  menu.Warehouse.Assets  = MENU_COALITION_COMMAND:New(Coalition, "Report Assets",  menu.Warehouse.Main, self.ReportWarehouseStock, self)
  
  menu.ReportSquadrons = MENU_COALITION_COMMAND:New(Coalition, "Report Squadrons",  menu.AIRWING, self.ReportSquadrons, self)

end

--- Report squadron status.
-- @param #AIRWING self
function AIRWING:ReportSquadrons()

  local text="Squadron Report:"
  
  for i,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --#AIRWING.Squadron
    
    local name=squadron.name
    
    local nspawned=0
    local nstock=0
    for _,_asset in pairs(squadron.assets) do
      local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
      --env.info(string.format("Asset name=%s", asset.spawngroupname))
      
      local n=asset.nunits
      
      if asset.spawned then
        nspawned=nspawned+n
      else
        nstock=nstock+n
      end
      
    end
    
    text=string.format("\n%s: AC on duty=%d, in stock=%d", name, nspawned, nstock)
    
  end
  
  self:I(self.sid..text)
  MESSAGE:New(text, 10, "AIRWING", true):ToCoalition(self:GetCoalition())

end


--- Add sub menu for this intruder.
-- @param #AIRWING self
-- @param #AIRWING.Squadron squadron The squadron data.
function AIRWING:_AddSquadonMenu(squadron)

  local Coalition=self:GetCoalition()

  local root=self.menu[Coalition].Squadron.Main

  local menu=MENU_COALITION:New(Coalition, squadron.name, root)

  MENU_COALITION_COMMAND:New(Coalition, "Report",    menu, self._ReportSq, self, squadron)
  MENU_COALITION_COMMAND:New(Coalition, "Launch CAP", menu, self._LaunchCAP, self, squadron)

  -- Set menu.
  squadron.menu=menu

end


--- Report squadron status.
-- @param #AIRWING self
-- @param #AIRWING.Squadron squadron The squadron object.
function AIRWING:_ReportSq(squadron)

  local text=string.format("%s: %s assets:", squadron.name, tostring(squadron.categoryname))
  for i,_asset in pairs(squadron.assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    text=text..string.format("%d.) ")
  end
end

--- Warehouse reports on/off.
-- @param #AIRWING self
function AIRWING:WarehouseReportsToggle()
  self.Report=not self.Report
  MESSAGE:New(string.format("Warehouse reports are now %s", tostring(self.Report)), 10, "AIRWING", true):ToCoalition(self:GetCoalition())
end


--- Report warehouse stock.
-- @param #AIRWING self
function AIRWING:ReportWarehouseStock()
  local text=self:_GetStockAssetsText(false)
  MESSAGE:New(text, 10, "AIRWING", true):ToCoalition(self:GetCoalition())
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
