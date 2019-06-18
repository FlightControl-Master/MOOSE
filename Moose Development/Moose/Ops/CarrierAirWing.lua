--- **CVW** - (R2.5) - Carrier Air Wing (CVW) Warehouse.
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
-- @field #string cid Class id string for output to DCS log file.
-- @field #string carriername The name of the carrier unit.
-- @field Wrapper.Group#GROUP group The carrier strike group.
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
  group          =   nil,
  menu           =   nil,
  squadrons      =   nil,
}

--- Squadron
-- @type CVW.Squadron
-- @field #string name Name of the squadron.
-- @field #table assets Assets of the squadron.
-- @field DCS#Coalition.Side coalition Coalition side.
-- @field #number threadlevel Thread level of intruder.
-- @field #string threadtext Thread text.
-- @field #number category Group category.
-- @field #string categoryname Group category name.
-- @field #string typename Type name of group.
-- @field #table menu The defence menu entries.

--- FlightControl class version.
-- @field #string version
CVW.version="0.0.2"

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
-- @param #string alias Skipper alias.
-- @return #CVW self
function CVW:New(carriername, alias)

  -- Inherit everything from WAREHOUSE class.
  local self=BASE:Inherit(self, WAREHOUSE:New(carriername, alias)) -- #CVW
  
  if not self.carrier then
    BASE:E(string.format("ERROR: Could not find carrier %s!", carriername))
    return nil
  end
    
  self.carriername=carriername
  
  self.group=self.carrier:GetGroup()
  
  self.squadrons={}
  
  
  -- Set some string id for output to DCS.log file.
  self.sid=string.format("CVW %s |", self.carriername)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "AirwingStatus",    "*")           -- CVW status update.
  self:AddTransition("*",             "RequestCAP",       "*")           -- Request CAP flight.
  self:AddTransition("*",             "RequestIntercept", "*")           -- Request Intercept.
  self:AddTransition("*",             "RequestCAS",       "*")           -- Request Intercept.
  self:AddTransition("*",             "RequestSEAD",      "*")           -- Request Intercept.
  
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

--- Add squadron
-- @param #CVW self
-- @param #string name Name of the squadron, e.g. VFA-37.
-- @return #CVW self
function CVW:AddSquadron(name)

  local squadron={} --#CVW.Squadron
  
  squadron.name=name
  squadron.assets={}

  table.insert(self.squadrons, squadron)
end

--- Add flight group to squadron.
-- @param #CVW self
-- @param #CVW.Squadron squadron Air wing squadron
-- @param Wrapper.Group#GROUP flightgroup Flight group.
-- @param #number ngroups Number of groups to be added.
-- @param #string livery Livery for group.
-- @return #CVW self
function CVW:AddFlightToSquadron(squadron, flightgroup, ngroups, livery)

  self:AddAsset(flightgroup, ngroups, nil, nil, nil, nil, nil, {livery}, squadron.name)
  
  function self:OnAfterNewAsset(From,Event,To,asset,assignment)
    if assignment==squadron.name then
      table.insert(squadron.assets, asset)
    end
  end

end

--- Get squadron by name
-- @param #CVW self
-- @param #string name Name of the squadron, e.g. VFA-37.
-- @return #CVW self
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

--- Start CVW FSM. Handle events.
-- @param #CVW self
function CVW:onafterStart(From, Event, To)

  -- Start parent Warehouse.
  self:GetParent(self).onafterStart(self, From, Event, To)

  -- Info.
  self:I(self.sid..string.format("Starting CVW v%s for carrier %s on map %s.", CVW.version, self.carriername, self.theatre))
    
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
function CVW:onafterSkipperStatus(From, Event, To)

  local fsmstate=self:GetState()

  -- Check zone for flights inbound.
  self:_CheckIntruder()

    -- Info text.
  local text=string.format("State %s", fsmstate)
  self:I(self.sid..text)

  self:__AirwingStatus(-30)
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Update status.
-- @param #CVW self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #CVW.Squadon squadron
-- @param Core.Point#COORDINATE coordinate
function CVW:onafterRequestCAP(From, Event, To, squadron, coordinate)


  self:__AddRequest(1, self, WAREHOUSE.Descriptor.ASSIGNMENT, squadron.name, 1, nil, nil, nil, "CAP")

  function self:OnAfterSelfRequest(From,Event,To,Groupset,Request)
  
    if Request.assignment=="CAP" then
      
    end
  end

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
    if not menu.Skipper then
      menu.Skipper=MENU_COALITION:New(Coalition, "CVW")
    end
  else
    -- F10/Skipper/<Carrier Alias>/...
    if not menu.Root then
      menu.Root=MENU_COALITION:New(Coalition, "CVW")
    end
    menu.Skipper=MENU_COALITION:New(Coalition, self.alias, menu.Root)
  end  

  -------------------
  -- Squadron Menu --
  -------------------
  
  menu.Squadron={}
  menu.Squadron.Main= MENU_COALITION:New(Coalition, "Squadrons", menu.Skipper)
  
  menu.Warehouse=MENU_COALITION:New(Coalition, "Warehouse", menu.Skipper)
  menu.Warehouse_Reports = MENU_COALITION_COMMAND:New(Coalition, "Reports On/Off", menu.Warehouse, self.WarehouseReportsToggle, self)
  menu.Warehouse_Assets  = MENU_COALITION_COMMAND:New(Coalition, "Report Assets",  menu.Warehouse, self.ReportWarehouseStock, self)
  
end


--- Add sub menu for this intruder.
-- @param #CVW self
-- @param #CVW.Squadron squadron The squadron data.
function CVW:_AddSquadonMenu(squadron)

  local Coalition=self:GetCoalition()

  local root=self.menu[Coalition].Squadrons.Main
  
  local menu=MENU_COALITION:New(Coalition, squadron.name, root)
  
  MENU_COALITION_COMMAND:New(Coalition, "Report",    menu, self._Report, self, squadron)
  MENU_COALITION_COMMAND:New(Coalition, "Launch CAP", menu, self._LaunchCAP, self, squadron)
    
  -- Set menu.
  squadron.menu=menu

end


--- Warehouse reports on/off.
-- @param #CVW self
function CVW:WarehouseReportsToggle()
  self.warehouse.Report=not self.warehouse.Report 
  MESSAGE:New(string.format("Warehouse reports are now %s", tostring(self.warehouse.Report)), 10, "CVW", true):ToCoalition(self:GetCoalition())
end


--- Report warehouse stock.
-- @param #CVW self
function CVW:ReportWarehouseStock()
  local text=self.warehouse:_GetStockAssetsText(false)
  MESSAGE:New(text, 10, "CVW", true):ToCoalition(self:GetCoalition())
end

--- Launch a Intercept flight.
-- @param #CVW self
-- @param #CVW.Intruder intruder Intruder group.
function CVW:LaunchIntercept(intruder)

  -- Get number of aircraft.
  local n=self:GetNumberOfAssets(WAREHOUSE.Descriptor.ASSIGNMENT, "Intercept", false)
  
  if n>0 then

    self.warehouse:AddRequest(self.warehouse, WAREHOUSE.Descriptor.ASSIGNMENT, "Intercept", 1, nil, nil, nil, "Intercept")
    
    local capcoord=intruder.group:GetCoordinate()
    
    capcoord:MarkToAll("Intruder coord")

    function self.warehouse.OnAfterSelfRequest(warehouse, From, Event, To, Groupset, Request)
      local request=Request --Functional.Warehouse#WAREHOUSE.Pendingitem
      local groupset=Groupset --Core.Set#SET_GROUP
      
      for _,_group in pairs(groupset:GetSet()) do
        local group=_group --Wrapper.Group#GROUP
      
        if request.assignment=="Intercept" then
        
          -- Task orbit.
          local tasks={}
          
          for _,unit in pairs(intruder.group:GetUnits()) do
            tasks[#tasks+1]=group:TaskAttackUnit(unit)
          end
          
          local speed=group:GetSpeedMax()
          local altitude=intruder.group:GetAltitude()
        
          -- Create waypoints.
          local wp={}
          wp[1]=self:GetCoordinate():WaypointAirTakeOffParking()
          wp[2]=self:GetCoordinate():SetAltitude(altitude):WaypointAirTurningPoint(COORDINATE.WaypointAltType.BARO, speed, {tasks}, "Attack Intruder")
          
          -- Start uncontrolled group.
          group:StartUncontrolled()
          
          --airboss:SetExcludeAI()
          
          -- Route group
          group:Route(wp)          
        end
        
      end

    end
        
  else
    MESSAGE:New("No INTERCEPT fighters currently available", 5, "CVW"):ToCoalition(self:GetCoalition())
  end
end


--- Launch a CAP flight.
-- @param #CVW self
function CVW:LaunchCAP()

  local n=self:GetNumberOfAssets(WAREHOUSE.Descriptor.ASSIGNMENT, "CAP", false)
  
  if n>0 then

    self:AddRequest(self, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.AIR_FIGHTER, 1, nil, nil, nil, "CAP")
    
    local capcoord=self.zoneCCA:GetRandomCoordinate(self.zoneCCA:GetRadius()/2)
    
    capcoord:MarkToAll("CAP coord")
    
    function self:OnAfterSelfRequest(From, Event, To, Groupset, Request)
      local request=Request --Functional.Warehouse#WAREHOUSE.Pendingitem
      local groupset=Groupset --Core.Set#SET_GROUP

      for _,_group in pairs(groupset:GetSet()) do
        local group=_group --Wrapper.Group#GROUP
    
        if request.assignment=="CAP" then
        
          local alt=UTILS.FeetToMeters(20000)
        
          -- Task orbit.
          local taskOrbit=group:TaskOrbit(capcoord, alt, UTILS.KnotsToMps(400), capcoord:Translate(UTILS.NMToMeters(15), 0))
        
          local wp={}
          wp[1]=self:GetCoordinate():WaypointAirTakeOffParking()
          wp[2]=self:GetCoordinate():SetAltitude(alt):WaypointAirTurningPoint(COORDINATE.WaypointAltType.BARO, UTILS.KnotsToKmph(350), {taskOrbit}, "CAP")
          
          -- Start uncontrolled group.
          group:StartUncontrolled()
          
          --airboss:SetExcludeAI()
          
          -- Route group.
          group:Route(wp)          
        end
      end      
    end
    
  else
    MESSAGE:New("No CAP fighters currently available", 5, "CVW"):ToCoalition(self:GetCoalition())
  end
end

--- Sort intruders table.
-- @param #CVW self
function CVW:_SortIntruders()

  -- Sort potential section members wrt to distance to lead.
  local function _sort(_a,_b)
    local a=_a --#CVW.Intruder
    local b=_b --#CVW.Intruder
    return a.threadlevel>b.threadlevel
  end
  
  table.sort(self.intruders, _sort)
end

--- Add sub menu for this intruder.
-- @param #CVW self
-- @param #CVW.Intruder intruder The intruder data.
-- @param #boolean removed If true, an intruder was removed. If false or nil, a new intruder was added.
function CVW:_UpdateIntruderMenu()

  for _,_intruder in ipairs(self.intruders) do
    local intruder=_intruder --#CVW.Intruder    
    self:_AddIntruderMenu(intruder)
  end

end



--- Remove sub menu for this intruder.
-- @param #CVW self
-- @param #CVW.Intruder intruder The intruder data.
function CVW:_RemoveIntruderMenu(intruder)

  if intruder.menu then
    local menu=intruder.menu --Core.Menu#MENU_COALITION
    
    menu:Remove()
    
    intruder.menu=nil
  end

end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
