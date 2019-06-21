--- **Ops** - (R2.5) - Manage behavior of the Carrier Strike Group.
-- 
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
-- @field #string sid Class id string for output to DCS log file.
-- @field #string carriername The name of the carrier unit.
-- @field Wrapper.Group#GROUP group The carrier strike group.
-- @field #table menu Table of menu items.
-- @field Functional.Warehouse#WAREHOUSE warehouse The warehouse of the carrier.
-- @field Functional.Artillery#ARTY arty The artillery object of the carrier.
-- @field #table intruders Table of intruders, i.e. groups inside the CCA. Each element is of type #SKIPPPER.Intruder.
-- @extends Ops.Airboss#AIRBOSS

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
  sid            =   nil,
  carriername    =   nil,
  group          =   nil,
  menu           =   nil,
  warehouse      =   nil,
  arty           =   nil,
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
-- @field #table menu The defence menu entries.

--- FlightControl class version.
-- @field #string version
SKIPPER.version="0.0.5"

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
-- @param #string alias Skipper alias.
-- @return #SKIPPER self
function SKIPPER:New(carriername, alias)

  -- Inherit everything from FSM class.
  --local self=BASE:Inherit(self, FSM:New()) -- #SKIPPER
  local self=BASE:Inherit(self, AIRBOSS:New(carriername, alias)) -- #SKIPPER
  
  if not self.carrier then
    BASE:E(string.format("ERROR: Could not find carrier %s!", carriername))
    return nil
  end
  
  --self.alias=alias or carriername
  
  --self:
  
  self.carriername=carriername
  
  self.group=self.carrier:GetGroup()
  
  self.arty=ARTY:New(self.group, carriername, self.alias)
  
  self.warehouse=WAREHOUSE:New(carriername, self.alias)
  
  local skipper=self
  
  --- Function for WAREHOUSE self request events.
  function self.warehouse:OnAfterSelfRequest(From,Event,To,groupset,request)
    env.info("FF Warehous self request!")
    skipper:_SelfRequest(self, groupset, request)
  end
  
  
  -- Set some string id for output to DCS.log file.
  self.sid=string.format("SKIPPER %s |", self.carriername)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "SkipperStatus",   "*")           -- Skipper status update.
  self:AddTransition("*",             "IntruderAlert",   "*")           -- New intruder detected.
  
  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the SKIPPER. Initializes parameters and starts event handlers.
  -- @function [parent=#SKIPPER] Start
  -- @param #SKIPPER self

  --- Triggers the FSM event "Start" after a delay. Starts the SKIPPER. Initializes parameters and starts event handlers.
  -- @function [parent=#SKIPPER] __Start
  -- @param #SKIPPER self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the SKIPPER and all its event handlers.
  -- @param #SKIPPER self

  --- Triggers the FSM event "Stop" after a delay. Stops the SKIPPER and all its event handlers.
  -- @function [parent=#SKIPPER] __Stop
  -- @param #SKIPPER self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "SkipperStatus".
  -- @function [parent=#SKIPPER] SkipperStatus
  -- @param #SKIPPER self

  --- Triggers the FSM event "SkipperStatus" after a delay.
  -- @function [parent=#SKIPPER] __SkipperStatus
  -- @param #SKIPPER self
  -- @param #number delay Delay in seconds.  

  --- Triggers the FSM event "IntruderAlert".
  -- @function [parent=#SKIPPER] IntruderAlert
  -- @param #SKIPPER self
  -- @param #SKIPPER.Intruder Intruder data table.

  --- Triggers the FSM delayed event "IntruderAlert".
  -- @function [parent=#SKIPPER] __IntruderAlert
  -- @param #SKIPPER self
  -- @param #number delay Delay in seconds before the function is called.
  -- @param #SKIPPER.Intruder Intruder data table.

  --- On after "IntruderAlert" event user function. Called when a missile was launched.
  -- @function [parent=#SKIPPER] OnAfterIntruderAlert
  -- @param #SKIPPER self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #SKIPPER.Intruder Intruder data table.


  -- Debug trace.
  if true then
    self.Debug=true
    BASE:TraceOnOff(true)
    BASE:TraceClass(self.ClassName)
    BASE:TraceLevel(1)
    self.arty:GetAmmo(true)
  end
   
  return self  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Optimized F10 radio menu for a single carrier. The menu entries will be stored directly under F10 Other/Skipper/ and not F10 Other/Skipper/"Carrier Alias"/.
-- **WARNING**: If you use this with two SKIPPER objects/carriers, the radio menu will be screwed up!
-- @param #SKIPPER self
-- @param #boolean switch If true or nil single menu is enabled. If false, menu is for multiple carriers in the mission.
-- @return #SKIPPER self
function SKIPPER:SetMenuSingleCarrier(switch)
  if switch==true or switch==nil then
    self.menusingle=true
  else
    self.menusingle=false
  end
  return self
end


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
function SKIPPER:onafterStart(From, Event, To)

  -- Start parent airboss.
  self:GetParent(self).onafterStart(self, From, Event, To)

  -- Info.
  self:I(self.sid..string.format("Starting SKIPPER v%s for carrier %s on map %s.", SKIPPER.version, self.carriername, self.theatre))
  
  -- Start ARTY.
  self.arty:Start()
  
  -- Start Warehouse.
  self.warehouse:Start()
  
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
  self:__SkipperStatus(-1)
end

--- Update status.
-- @param #SKIPPER self
function SKIPPER:onafterSkipperStatus(From, Event, To)

  local fsmstate=self:GetState()

  -- Check zone for flights inbound.
  self:_CheckIntruder()

    -- Info text.
  local text=string.format("State %s", fsmstate)
  self:I(self.sid..text)

  self:__SkipperStatus(-30)
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
  self:T(self.sid..string.format("Scanning Carrier Controlled Area. Radius=%.1f NM.", UTILS.MetersToNM(RCCZ)))
  
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
  
  -- Intruder menu needs update.
  local updateintrudermenu=false
  
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
    
    -- Intruder is gone!
    if not gotit then
    
      -- Remove from table.
      table.remove(self.intruders, i)
      
      -- Menu update required.
      updateintrudermenu=true
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

      -- Create a new intruder table.
      local intruder={} --#SKIPPER.Intruder      
      intruder.coalition=group:GetCoalition()
      intruder.group=group
      intruder.threadlevel, intruder.threadtext=group:GetUnit(1):GetThreatLevel()
      intruder.time0=timer.getAbsTime()
      intruder.dist0=self:GetCoordinate():Get2DDistance(group:GetCoordinate())
      intruder.groupname=groupname
      intruder.typename=group:GetTypeName()
      intruder.category=group:GetCategory()
      intruder.categoryname=group:GetCategoryName()

      -- Add intruder to list.
      table.insert(self.intruders, intruder)
      
      -- Trigger alert!
      self:IntruderAlert(intruder)
      
      -- Menu update required.
      updateintrudermenu=true
    end    
  end
  
  -- Update intruder menu if necessary.
  if updateintrudermenu then
    self:_SortIntruders()
    self:_UpdateIntruderMenu()
  end
  
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Menu Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Patrol carrier.
-- @param #SKIPPER self
-- @return #SKIPPER self
function SKIPPER:_SetMenuCoalition()

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
      menu.Skipper=MENU_COALITION:New(Coalition, "Skipper")
    end
  else
    -- F10/Skipper/<Carrier Alias>/...
    if not menu.Root then
      menu.Root=MENU_COALITION:New(Coalition, "Skipper")
    end
    menu.Skipper=MENU_COALITION:New(Coalition, self.alias, menu.Root)
  end  

  ------------------
  -- Defence Menu --
  ------------------
  
  menu.SetSpeed     = MENU_COALITION:New(Coalition, "Set Speed", menu.Skipper)
  menu.SetSpeed_00  = MENU_COALITION_COMMAND:New(Coalition, "Hold Position", menu.SetSpeed, self._SetSpeed, self, 0)
  menu.SetSpeed_05  = MENU_COALITION_COMMAND:New(Coalition, "5 knots",       menu.SetSpeed, self._SetSpeed, self, 5)
  menu.SetSpeed_10  = MENU_COALITION_COMMAND:New(Coalition, "10 knots",      menu.SetSpeed, self._SetSpeed, self, 10)
  menu.SetSpeed_15  = MENU_COALITION_COMMAND:New(Coalition, "15 knots",      menu.SetSpeed, self._SetSpeed, self, 15)
  menu.SetSpeed_20  = MENU_COALITION_COMMAND:New(Coalition, "20 knots",      menu.SetSpeed, self._SetSpeed, self, 20)
  menu.SetSpeed_25  = MENU_COALITION_COMMAND:New(Coalition, "25 knots",      menu.SetSpeed, self._SetSpeed, self, 25)
  menu.SetSpeed_30  = MENU_COALITION_COMMAND:New(Coalition, "30 knots",      menu.SetSpeed, self._SetSpeed, self, 30)
  menu.SetSpeed_99  = MENU_COALITION_COMMAND:New(Coalition, "Restore Route", menu.SetSpeed, self.CarrierResume, self)
  
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
  menu.Rstop    = MENU_COALITION_COMMAND:New(Coalition, "Pause/Unpause",  menu.Recovery, self._Rpause, self)
  menu.Rstop    = MENU_COALITION_COMMAND:New(Coalition, "Stop Recovery",  menu.Recovery, self._Rstop, self)  


  ------------------
  -- Defence Menu --
  ------------------  
  
  menu.Defence               = MENU_COALITION:New(Coalition, "Defence", menu.Skipper)
  menu.Defence_SetROE        = MENU_COALITION:New(Coalition, "Set ROE", menu.Defence)
  menu.Defence_SetROE_Hold   = MENU_COALITION_COMMAND:New(Coalition, "Weapon Hold", menu.Defence_SetROE, self._SetROE, self, "Hold")
  menu.Defence_SetROE_Free   = MENU_COALITION_COMMAND:New(Coalition, "Weapon Free", menu.Defence_SetROE, self._SetROE, self, "Free")
  menu.Defence_SetROE_Return = MENU_COALITION_COMMAND:New(Coalition, "Return Fire", menu.Defence_SetROE, self._SetROE, self, "Return")

  menu.Defence_Intruders     = MENU_COALITION:New(Coalition, "Intruders", menu.Defence)
  menu.Defence_Ammo          = MENU_COALITION_COMMAND:New(Coalition, "Report Ammo", menu.Defence, self.arty.GetAmmo, self.arty, true)
  menu.Defence_IntruderR     = MENU_COALITION_COMMAND:New(Coalition, "Report Intruders", menu.Defence, self._ListIntruders, self)
  menu.Defence_LaunchCAP     = MENU_COALITION_COMMAND:New(Coalition, "Lauch CAP", menu.Defence, self.LaunchCAP, self)

  --------------------
  -- Warehouse Menu --
  --------------------

  if self.warehouse then
    menu.Warehouse=MENU_COALITION:New(Coalition, "Warehouse", menu.Skipper)
    menu.Warehouse_Assets = MENU_COALITION_COMMAND:New(Coalition, "Reports On/Off", menu.Warehouse, self.WarehouseReportsToggle, self)
    menu.Warehouse_Assets = MENU_COALITION_COMMAND:New(Coalition, "Report Assets",  menu.Warehouse, self.ReportWarehouseStock, self)
  end
  
end

--- Warehouse reports on/off.
-- @param #SKIPPER self
function SKIPPER:WarehouseReportsToggle()
  self.warehouse.Report=not self.warehouse.Report 
  MESSAGE:New(string.format("Warehouse reports are now %s", tostring(self.warehouse.Report)), 10, "SKIPPER", true):ToCoalition(self:GetCoalition())
end


--- Report warehouse stock.
-- @param #SKIPPER self
function SKIPPER:ReportWarehouseStock()
  local text=self.warehouse:_GetStockAssetsText(false)
  MESSAGE:New(text, 10, "SKIPPER", true):ToCoalition(self:GetCoalition())
end

--- Handle self requests from carrier warehouse.
-- @param #SKIPPER self
-- @param Functional.Warehouse#WAREHOUSE warehouse The (carrier) warehouse object.
-- @param Core.Set#SET_GROUP groupset Group set.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem request Request.
function SKIPPER:_SelfRequest(warehouse, groupset, request)

  local assignment=request.assignment
  
  env.info(string.format("FF warehouse self request assignment %s", tostring(assignment)))
  
end

--- Launch a Intercept flight.
-- @param #SKIPPER self
-- @param #SKIPPER.Intruder intruder Intruder group.
function SKIPPER:LaunchIntercept(intruder)

  --local n=self.warehouse:GetNumberOfAssets(WAREHOUSE.Descriptor.ASSIGNMENT, WAREHOUSE.Attribute.AIR_FIGHTER, false)
  local n=self.warehouse:GetNumberOfAssets(WAREHOUSE.Descriptor.ASSIGNMENT, "Intercept", false)
  
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
    MESSAGE:New("No INTERCEPT fighters currently available", 5, "SKIPPER"):ToCoalition(self:GetCoalition())
  end
end


--- Launch a CAP flight.
-- @param #SKIPPER self
function SKIPPER:LaunchCAP()

  --local n=self.warehouse:GetNumberOfAssets(WAREHOUSE.Descriptor.ASSIGNMENT, WAREHOUSE.Attribute.AIR_FIGHTER, false)
  local n=self.warehouse:GetNumberOfAssets(WAREHOUSE.Descriptor.ASSIGNMENT, "CAP", false)
  
  if n>0 then

    self.warehouse:AddRequest(self.warehouse, WAREHOUSE.Descriptor.ATTRIBUTE, WAREHOUSE.Attribute.AIR_FIGHTER, 1, nil, nil, nil, "CAP")
    
    local capcoord=self.zoneCCA:GetRandomCoordinate(self.zoneCCA:GetRadius()/2)
    
    capcoord:MarkToAll("CAP coord")
    
    function self.warehouse.OnAfterSelfRequest(warehouse, From, Event, To, Groupset, Request)
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
    MESSAGE:New("No CAP fighters currently available", 5, "SKIPPER"):ToCoalition(self:GetCoalition())
  end
end


--- Enage an intruder by ARTY.
-- @param #SKIPPER self
-- @param #SKIPPER.Intruder intruder The intruder data.
-- @param #number weapontype Type of weapon.
function SKIPPER:EngageArty(intruder, weapontype)

  weapontype=weapontype or ARTY.WeaponType.Auto

  if intruder.group and intruder.group:IsAlive() then
  
    -- Current position.
    local coord=intruder.group:GetCoordinate()
  
    if intruder.category==Group.Category.GROUND or intruder.category==Group.Category.TRAIN then
      self.arty:AssignTargetCoord(coord, 50, 100, 5, 1, nil, weapontype, intruder.groupname, false)
    elseif intruder.category==Group.Category.SHIP then
      self.arty:AssignAttackGroup(intruder.group, 50, 100, 5, 1, nil, weapontype, intruder.groupname, false)
    elseif intruder.category==Group.Category.AIRPLANE or intruder.category==Group.Category.HELICOPTER then    
      self.arty:AssignAttackGroup(intruder.group, 50, 100, 5, 1, nil, weapontype, intruder.groupname, false)
    end
    
  end
end

--- Sort intruders table.
-- @param #SKIPPER self
function SKIPPER:_SortIntruders()

  -- Sort potential section members wrt to distance to lead.
  local function _sort(_a,_b)
    local a=_a --#SKIPPER.Intruder
    local b=_b --#SKIPPER.Intruder
    return a.threadlevel>b.threadlevel
  end
  
  table.sort(self.intruders, _sort)
end

--- Add sub menu for this intruder.
-- @param #SKIPPER self
-- @param #SKIPPER.Intruder intruder The intruder data.
-- @param #boolean removed If true, an intruder was removed. If false or nil, a new intruder was added.
function SKIPPER:_UpdateIntruderMenu()

  for _,_intruder in ipairs(self.intruders) do
    local intruder=_intruder --#SKIPPER.Intruder    
    self:_AddIntruderMenu(intruder)
  end

end

--- Add sub menu for this intruder.
-- @param #SKIPPER self
-- @param #SKIPPER.Intruder intruder The intruder data.
function SKIPPER:_AddIntruderMenu(intruder)

  local Coalition=self:GetCoalition()

  local root=self.menu[Coalition].Defence_Intruders
  
  local menu=MENU_COALITION:New(Coalition, intruder.typename, root)
  
  if intruder.category==Group.Category.GROUND then
    MENU_COALITION_COMMAND:New(Coalition, "Engage Shells", menu, self.EngageArty, self, intruder, ARTY.WeaponType.Cannon)
    MENU_COALITION_COMMAND:New(Coalition, "Engage Cruise M", menu, self.EngageArty, self, intruder, ARTY.WeaponType.CruiseMissile)
  elseif intruder.category==Group.Category.SHIP then
    MENU_COALITION_COMMAND:New(Coalition, "Engage", menu, self.EngageArty, self, intruder)
  elseif intruder.category==Group.Category.AIRPLANE or intruder.category==Group.Category.HELICOPTER then
    MENU_COALITION_COMMAND:New(Coalition, "Engage A2A", menu, self.LaunchIntercept, self, intruder)
  end
  
  -- Set menu.
  intruder.menu=menu

end

--- Remove sub menu for this intruder.
-- @param #SKIPPER self
-- @param #SKIPPER.Intruder intruder The intruder data.
function SKIPPER:_RemoveIntruderMenu(intruder)

  if intruder.menu then
    local menu=intruder.menu --Core.Menu#MENU_COALITION
    
    menu:Remove()
    
    intruder.menu=nil
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
  
  --[[
  self.skipperTime=self.skipperTime or 30
  self.skipperSpeed=self.skipperSpeed or 25    
  if self.skipperUturn==nil then
    self.skipperUturn=false
  end
  ]]

  -- Inform player.
  local text=string.format("Case %d recovery will start in 5 min for %d min. Wind on deck %d knots. U-turn=%s.", case, self.skipperTime, self.skipperSpeed, tostring(self.skipperUturn))
  
  if self:IsRecovering() then
    text="negative, carrier is already recovering."
    MESSAGE:New(string.format(text), 5, self.ClassName):ToCoalition(self:GetCoalition())
    return
  end

  -- Recovery staring in 5 min for 30 min.
  local t0=timer.getAbsTime()+5*60
  local t9=t0+self.skipperTime*60
  local C0=UTILS.SecondsToClock(t0)
  local C9=UTILS.SecondsToClock(t9)

  -- Carrier will turn into the wind. Wind on deck 25 knots. U-turn on.
  self:AddRecoveryWindow(C0, C9, case, 30, true, self.skipperSpeed, self.skipperUturn)
  
  MESSAGE:New(string.format(text), 5, self.ClassName):ToCoalition(self:GetCoalition())

end



--- Toggle recovery U-turn option.
-- @param #SKIPPER self
function SKIPPER:_SetUturn()

  self.skipperUturn=not self.skipperUturn
    
  MESSAGE:New(string.format("Recovery U-turn is now %s.", tostring(self.skipperUturn)), 5, self.ClassName):ToCoalition(self:GetCoalition())
end

--- Set manual recovery duration.
-- @param #SKIPPER self
-- @param #number time Duration in minutes.
function SKIPPER:_SetRtime(time)

  self.skipperTime=time
  
  MESSAGE:New(string.format("Recovery duration set to %d min.", time), 5, self.ClassName):ToCoalition(self:GetCoalition())
end


--- Set wind on deck for manual recovery start.
-- @param #SKIPPER self
-- @param #number speed Speed in knots.
function SKIPPER:_SetWoD(speed)

  self.skipperSpeed=speed
  
  MESSAGE:New(string.format("Wind on Deck set to %d knots.", speed), 5, self.ClassName):ToCoalition(self:GetCoalition())
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

--- Set alarm state. (Not useful/working for ships.)
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
