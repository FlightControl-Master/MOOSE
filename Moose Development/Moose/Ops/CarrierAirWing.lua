--- **Ops** - (R2.5) - Carrier Air Wing (CVW) Warehouse.
--
-- **Main Features:**
--
--    * Nice stuff.
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.CVW
-- @image OPS_CarrierAirWing.png


--- CVW class.
-- @type CVW
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
-- ![Banner Image](..\Presentations\CarrierAirWing\CVW_Main.jpg)
--
-- # The CVW Concept
--
--
--
-- @field #CVW
CVW = {
  ClassName      = "CVW",
  sid            =   nil,
  carriername    =   nil,
  menu           =   nil,
  squadrons      =   nil,
}

--- Squadron
-- @type CVW.Squadron
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
-- @type CVW.Task
-- @param #string INTERCEPT Intercept task.
-- @param #string CAP Combat Air Patrol task.s
-- @param #string BAI Battlefield Air Interdiction task.
-- @param #string SEAD Suppression/destruction of enemy air defences.
-- @param #string STRIKE Strike task.
-- @param #string AWACS AWACS task.
-- @param #string TANKER Tanker task.
CVW.Task={
  INTERCEPT="Intercept",
  CAP="CAP",
  BAI="BAI",
  SEAD="SEAD",
  STRIKE="Strike",
  CAS="CAS",
  AWACS="AWACS",
  TANKER="Tanker",
}

--- FlightControl class version.
-- @field #string version
CVW.version="0.0.4"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot!

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new CVW class object for a specific aircraft carrier unit.
-- @param #CVW self
-- @param #string carriername Name of the carrier.
-- @param #string squadronname Name of the squadron.
-- @return #CVW self
function CVW:New(carriername, squadronname)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, WAREHOUSE:New(carriername, squadronname)) -- #CVW

  if not self then
    BASE:E(string.format("ERROR: Could not find carrier %s!", carriername))
    return nil
  end

  self.carriername=carriername

  self.squadrons={}


  -- Set some string id for output to DCS.log file.
  self.sid=string.format("CVW %s |", self.carriername)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "AirwingStatus",    "*")           -- CVW status update.
  self:AddTransition("*",             "RequestCAP",       "*")           -- Request CAP flight.
  self:AddTransition("*",             "RequestIntercept", "*")           -- Request Intercept.
  self:AddTransition("*",             "RequestCAS",       "*")           -- Request CAS.
  self:AddTransition("*",             "RequestSEAD",      "*")           -- Request SEAD.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the CVW. Initializes parameters and starts event handlers.
  -- @function [parent=#CVW] Start
  -- @param #CVW self

  --- Triggers the FSM event "Start" after a delay. Starts the CVW. Initializes parameters and starts event handlers.
  -- @function [parent=#CVW] __Start
  -- @param #CVW self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the CVW and all its event handlers.
  -- @param #CVW self

  --- Triggers the FSM event "Stop" after a delay. Stops the CVW and all its event handlers.
  -- @function [parent=#CVW] __Stop
  -- @param #CVW self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "SkipperStatus".
  -- @function [parent=#CVW] AirwingStatus
  -- @param #CVW self

  --- Triggers the FSM event "SkipperStatus" after a delay.
  -- @function [parent=#CVW] __AirwingStatus
  -- @param #CVW self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "RequestCAP".
  -- @function [parent=#CVW] RequestCAP
  -- @param #CVW self
  -- @param Core.Point#COORDINATE coordinate
  -- @param #number altitude Altitude
  -- @param #number leg Race track length.
  -- @param #number heading Heading in degrees.
  -- @param #number speed Speed in knots.
  -- @param #CVW.Squadron squadron Explicitly request a specific squadron.


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

--- Optimized F10 radio menu for a single carrier. The menu entries will be stored directly under F10 Other/Skipper/ and not F10 Other/Skipper/"Carrier Alias"/.
-- **WARNING**: If you use this with two CVW objects/carriers, the radio menu will be screwed up!
-- @param #CVW self
-- @param #boolean switch If true or nil single menu is enabled. If false, menu is for multiple carriers in the mission.
-- @return #CVW self
function CVW:SetMenuSingleCarrier(switch)
  if switch==true or switch==nil then
    self.menusingle=true
  else
    self.menusingle=false
  end
  return self
end

--- Add a squadron to the carrier air wing.
-- @param #CVW self
-- @param #string name Name of the squadron, e.g. "VFA-37".
-- @param #table tasks Table of tasks the squadron is supposed to do.
-- @param #string livery The livery for all added flight group. Default is the livery of the template group.
-- @return #CVW.Squadron The squadron object.
function CVW:AddSquadron(name, tasks, livery)

  local squadron={} --#CVW.Squadron

  squadron.name=name
  squadron.assets={}
  squadron.tasks=tasks or {}
  squadron.livery=livery

  table.insert(self.squadrons, squadron)
  
  return squadron
end

--- Add flight group(s) to squadron.
-- @param #CVW self
-- @param #CVW.Squadron squadron The squadron object.
-- @param Wrapper.Group#GROUP flightgroup The flight group object.
-- @param #number ngroups Number of groups to add.
-- @return #CVW self
function CVW:AddFlightToSquadron(squadron, flightgroup, ngroups)

  self:AddAsset(flightgroup, ngroups, nil, nil, nil, nil, nil, {squadron.livery}, squadron.name)

  function self:OnAfterNewAsset(From, Event, To, asset, assignment)
    if assignment==squadron.name then
      table.insert(squadron.assets, asset)
    end
  end

  return self
end

--- Get squadron by name
-- @param #CVW self
-- @param #string name Name of the squadron, e.g. "VFA-37".
-- @return #CVW self or nil.
function CVW:GetSquadron(name)

  for _,_squadron in pairs(self.squadrons) do
    if _squadron.name==name then
      return _squadron
    end
  end

  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start CVW FSM.
-- @param #CVW self
function CVW:onafterStart(From, Event, To)

  -- Start parent Warehouse.
  self:GetParent(self).onafterStart(self, From, Event, To)

  -- Info.
  self:I(self.sid..string.format("Starting CVW v%s for carrier %s", CVW.version, self.carriername))

  -- Add F10 radio menu.
  self:_SetMenuCoalition()

  for _,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --#CVW.Squadron
    self:_AddSquadonMenu(squadron)
  end

  -- Init status updates.
  self:__AirwingStatus(-1)
end

--- Update status.
-- @param #CVW self
function CVW:onafterAirwingStatus(From, Event, To)

  local fsmstate=self:GetState()
  
    -- Info text.
  local text=string.format("State %s", fsmstate)
  self:I(self.sid..text)

  self:__AirwingStatus(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Request CAP.
-- @param #CVW self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Core.Point#COORDINATE coordinate
-- @param #number altitude Altitude
-- @param #number leg Race track length.
-- @param #number heading Heading in degrees.
-- @param #number speed Speed in knots.
-- @param #CVW.Squadron squadron Explicitly request a specific squadron.
function CVW:onafterRequestCAP(From, Event, To, coordinate, altitude, leg, heading, speed, squadron)

  local n=self:GetNumberOfAssets(WAREHOUSE.Descriptor.ASSIGNMENT, squadron.name, false)

  if n>0 then

    self:__AddRequest(1, self, WAREHOUSE.Descriptor.ASSIGNMENT, squadron.name, 1, nil, nil, nil, CVW.Task.CAP)

    function self:OnAfterSelfRequest(From,Event,To,Groupset,Request)
      local request=Request --Functional.Warehouse#WAREHOUSE.Pendingitem
      local groupset=Groupset --Core.Set#SET_GROUP

      if Request.assignment==CVW.Task.CAP then
      
        for _,_group in pairs(groupset:GetSet()) do
          local group=_group --Wrapper.Group#GROUP
          
          self:LaunchCAP(group, coordinate, altitude, leg, speed, heading)
        end
        
      end
    end
    
  else
    MESSAGE:New("No CAP planes currently available", 5, "CVW"):ToCoalition(self:GetCoalition())
  end
  
end

--- Launch a CAP flight.
-- @param #CVW self
-- @param Wrapper.Group#GROUP group Flight group.
-- @param Core.Point#COORDINATE capcoord Coordinate of CAP.
-- @param #number alt Altitude in feet. Default 20000 ft.
-- @param #number leg Length of race track pattern leg. Default 15 NM.
-- @param #number heading Heading of race track in degrees. Default 180° i.e. from North to South.
-- @param #number speed Speed in knots.
function CVW:LaunchCAP(group, capcoord, alt, leg, heading, speed)

  alt=UTILS.FeetToMeters(alt or 20000)
  
  speed=speed or 350
  leg=leg or 15

  -- Task orbit.
  local taskOrbit=group:TaskOrbit(capcoord, alt, UTILS.KnotsToMps(speed+50), capcoord:Translate(UTILS.NMToMeters(leg), heading))

  local wp={}
  wp[1]=self:GetCoordinate():WaypointAirTakeOffParking()
  wp[2]=self:GetCoordinate():SetAltitude(alt):WaypointAirTurningPoint(COORDINATE.WaypointAltType.BARO, UTILS.KnotsToKmph(speed), {taskOrbit}, "CAP")

  -- Start uncontrolled group.
  group:StartUncontrolled()

  --airboss:SetExcludeAI()

  -- Route group.
  group:Route(wp)
end



--- Request Intercept.
-- @param #CVW self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Group#GROUP bandits Group of bandits to intercept.
-- @param #CVW.Squadron squadron Explicitly request a specific squadron.
function CVW:onafterRequestIntercept(From, Event, To, bandits, squadron)

  local n=self:GetNumberOfAssets(WAREHOUSE.Descriptor.ASSIGNMENT, squadron.name, false)

  if n>0 then

    self:__AddRequest(1, self, WAREHOUSE.Descriptor.ASSIGNMENT, squadron.name, 1, nil, nil, nil, CVW.Task.INTERCEPT)

    function self:OnAfterSelfRequest(From,Event,To,Groupset,Request)
      local request=Request --Functional.Warehouse#WAREHOUSE.Pendingitem
      local groupset=Groupset --Core.Set#SET_GROUP

      if Request.assignment==CVW.Task.INTERCEPT then
      
        for _,_group in pairs(groupset:GetSet()) do
          local group=_group --Wrapper.Group#GROUP
          
          self:LaunchIntercept(group)
        end
        
      end
    end
    
  else
    MESSAGE:New("No INTERCEPT fighters currently available", 5, "CVW"):ToCoalition(self:GetCoalition())
  end
  
end

--- Launch a flight group to intercept an intruder.
-- @param #CVW self
-- @param Wrapper.Group#GROUP group Interceptor flight group.
-- @param Wrapper.Group#GROUP bandits Bandit group.
function CVW:LaunchIntercept(group, bandit)

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
-- @param #CVW self
-- @return #CVW self
function CVW:_SetMenuCoalition()

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
    if not menu.CVW then
      menu.CVW=MENU_COALITION:New(Coalition, "CVW")
    end
  else
    -- F10/Skipper/<Carrier Alias>/...
    if not menu.Root then
      menu.Root=MENU_COALITION:New(Coalition, "CVW")
    end
    menu.CVW=MENU_COALITION:New(Coalition, self.alias, menu.Root)
  end

  -------------------
  -- Squadron Menu --
  -------------------

  menu.Squadron={}
  menu.Squadron.Main= MENU_COALITION:New(Coalition, "Squadrons", menu.CVW)

  menu.Warehouse={}
  menu.Warehouse.Main    = MENU_COALITION:New(Coalition, "Warehouse", menu.CVW)
  menu.Warehouse.Reports = MENU_COALITION_COMMAND:New(Coalition, "Reports On/Off", menu.Warehouse.Main, self.WarehouseReportsToggle, self)
  menu.Warehouse.Assets  = MENU_COALITION_COMMAND:New(Coalition, "Report Assets",  menu.Warehouse.Main, self.ReportWarehouseStock, self)
  
  menu.ReportSquadrons = MENU_COALITION_COMMAND:New(Coalition, "Report Squadrons",  menu.CVW, self.ReportSquadrons, self)

end

--- Report squadron status.
-- @param #CVW self
function CVW:ReportSquadrons()

  local text="Squadron Report:"
  for i,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --#CVW.Squadron
    
    local name=squadron.name
    
    local nspawned=0
    local nstock=0
    for _,_asset in pairs(squadron.assets) do
      local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
      
      if asset.spawned then
        nspawned=nspawned+asset.nunits
      else
        nstock=nstock+asset.nunits
      end
      
    end
    
    text=string.format("\n%s: AC on duty=%d, in stock=%d", name, nspawned, nstock)
    
  end
  
  MESSAGE:New(text, 10, "CVW", true):ToCoalition(self:GetCoalition())

end


--- Add sub menu for this intruder.
-- @param #CVW self
-- @param #CVW.Squadron squadron The squadron data.
function CVW:_AddSquadonMenu(squadron)

  local Coalition=self:GetCoalition()

  local root=self.menu[Coalition].Squadron.Main

  local menu=MENU_COALITION:New(Coalition, squadron.name, root)

  MENU_COALITION_COMMAND:New(Coalition, "Report",    menu, self._ReportSq, self, squadron)
  MENU_COALITION_COMMAND:New(Coalition, "Launch CAP", menu, self._LaunchCAP, self, squadron)

  -- Set menu.
  squadron.menu=menu

end


--- Report squadron status.
-- @param #CVW self
-- @param 
function CVW:_ReportSq(squadron)

  for _,_asset in pairs(squadron.assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    
  end
end

--- Warehouse reports on/off.
-- @param #CVW self
function CVW:WarehouseReportsToggle()
  self.Report=not self.Report
  MESSAGE:New(string.format("Warehouse reports are now %s", tostring(self.Report)), 10, "CVW", true):ToCoalition(self:GetCoalition())
end


--- Report warehouse stock.
-- @param #CVW self
function CVW:ReportWarehouseStock()
  local text=self:_GetStockAssetsText(false)
  MESSAGE:New(text, 10, "CVW", true):ToCoalition(self:GetCoalition())
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
