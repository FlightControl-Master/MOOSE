--- **Ops** - Airwing Warehouse.
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
-- @field #string lid Class id string for output to DCS log file.
-- @field #string warehousename The name of the warehouse unit/static.
-- @field #table menu Table of menu items.
-- @field #table squadrons Table of squadrons.
-- @field #table missionqueue Mission queue table.
-- @field #table missioncounter Running index counting the added missions.
-- @field #table payloads Playloads for specific aircraft and mission types. 
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
  lid            =   nil,
  warehousename  =   nil,
  menu           =   nil,
  squadrons      =   nil,
  missionqueue   =    {},
  missioncounter =   nil,
  payloads       =    {},
}

--- Squadron data.
-- @type AIRWING.Squadron
-- @field #string name Name of the squadron.
-- @field #table assets Assets of the squadron.
-- @field #table missiontypes Mission types that the squadron can do.
-- @field #string livery Livery of the squadron.
-- @field #table menu The squadron menu entries.
-- @field #string skill Skill of squadron team members.

--- Squadron asset.
-- @type AIRWING.SquadronAsset
-- @field #AIRWING.Missiondata mission The assigned mission.
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup The flightgroup object.
-- @extends Functional.Warehouse#WAREHOUSE.Assetitem

--- Mission data.
-- @type AIRWING.Missiondata
-- @field #string squadname Name of the assigned squadron.
-- @field #number nassets Number of required assets.
-- @extends Ops.FlightGroup#FLIGHTGROUP.Mission

--- Payload data.
-- @type AIRWING.Payload
-- @field #string aircrafttype Type of aircraft, which can use this payload.
-- @field #table missiontypes Mission types for which this payload can be used.
-- @field #table pylons Pylon data extracted for the unit template.
-- @field #number navail Number of available payloads of this type.


--- AIRWING class version.
-- @field #string version
AIRWING.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Add squadrons to warehouse.
-- TODO: Make special request to transfer squadrons to anther airwing (or warehouse).
-- TODO: Build mission queue.
-- TODO: Find way to start missions.
-- TODO: Check if missions are accomplished. 
-- TODO: Paylods as assets.
-- TODO: Cargo as assets.

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
  
  self.missioncounter=0


  -- Set some string id for output to DCS.log file.
  self.lid=string.format("AIRWING %s |", airwingname)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "AirwingStatus",    "*")           -- AIRWING status update.
  
  self:AddTransition("*",             "AddMission",        "*")          -- Add a new mission.
  
  self:AddTransition("*",             "RequestMission",   "*")           -- Request CAP flight.

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

  --- Triggers the FSM event "AirwingStatus".
  -- @function [parent=#AIRWING] AirwingStatus
  -- @param #AIRWING self

  --- Triggers the FSM event "AirwingStatus" after a delay.
  -- @function [parent=#AIRWING] __AirwingStatus
  -- @param #AIRWING self
  -- @param #number delay Delay in seconds.

  -- Debug trace.
  if false then
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

--- Add a squadron to the air wing.
-- @param #AIRWING self
-- @param #string name Name of the squadron, e.g. "VFA-37".
-- @param #table tasks Table of tasks the squadron is supposed to do.
-- @param #string livery The livery for all added flight group. Default is the livery of the template group.
-- @return #AIRWING.Squadron The squadron object.
function AIRWING:AddSquadron(SquadronName, MissionTypes, Livery)

  local squadron={} --#AIRWING.Squadron

  squadron.name=SquadronName
  squadron.assets={}
  squadron.missiontypes=MissionTypes or {}
  squadron.livery=Livery

  self.squadrons[SquadronName]=squadron
  
  return squadron
end

--- Add a payload to air wing resources.
-- @param #AIRWING self
-- @param #string UnitName Name of the (template) unit from which the payload is extracted.
-- @param #number Npayloads Number of payloads to add to the airwing resources. Default 999.
-- @param #table MissionTypes Mission types this payload can be used for.
function AIRWING:AddPayload(UnitName, Npayloads, MissionTypes)

    local payload=self:GetPayloadByName(UnitName)
    
    if payload then
    
      -- Payload already exists. Increase the number.
      payload.navail=payload.navail+Npayloads
      
      --TODO: maybe check if mission types given now are different from before.
      
    else
    
      local unit=UNIT:FindByName(UnitName)
      
      if unit then
    
        payload={} --#AIRWING.Payload
        
        payload.navail=Npayloads
        payload.missiontypes=MissionTypes
        payload.aircrafttype=unit:GetTypeName()
        payload.pylons=unit:GetTemplatePylons()
        
        --TODO: maybe add fuel, chaff and gun?
        
        --table.insert(self.payloads, payload)
        self.payloads[UnitName]=payload
        
      end
    
    end

end

--- Add a payload to air wing resources.
-- @param #AIRWING self
-- @param #string UnitName Name of the unit from which the payload was extracted.
-- @return #AIRWING.Payload
function AIRWING:GetPayloadByName(UnitName)
  return self.payloads[UnitName]
end


--- Add flight group(s) to squadron.
-- @param #AIRWING self
-- @param #AIRWING.Squadron SquadronName Name of the squadron.
-- @param Wrapper.Group#GROUP Group The group object.
-- @param #number Ngroups Number of groups to add.
-- @return #AIRWING self
function AIRWING:AddAssetToSquadron(SquadronName, Group, Ngroups)

  local squadron=self:GetSquadron(SquadronName)

  if squadron then
  
    if type(Group)=="string" then
      Group=GROUP:FindByName(Group)
    end
    
    if Group then

      local text=string.format("FF Adding asset %s to squadron %s", Group:GetName(), squadron.name)
      env.info(text)
    
      self:AddAsset(Group, Ngroups, nil, nil, nil, nil, AI.Skill.EXCELLENT, squadron.livery, squadron.name)
      
    else
      self:E("ERROR: Group does not exist!")
    end
    
  else
    self:E("ERROR: Squadron does not exit!")
  end

  return self
end

--- Get squadron by name.
-- @param #AIRWING self
-- @param #string SquadronName Name of the squadron, e.g. "VFA-37".
-- @return #AIRWING self or nil.
function AIRWING:GetSquadron(SquadronName)
  return self.squadrons[SquadronName]
end

--- Check if there is a squadron that can execute a given mission type. Optionally, the number of required assets can be specified.
-- @param #AIRWING self
-- @param #AIRWING.Squadron Squadron The Squadron.
-- @param #string MissionType Type of mission.
-- @param #number Nassets Number of required assets for the mission. Use *nil* or 0 for none. Then only the general capability is checked.
-- @return #boolean If true, Squadron can do that type of mission. Available assets are not checked.
-- @return #number Number of available assets that dont have a mission assigned.
function AIRWING:SquadronCanMission(Squadron, MissionType, Nassets)

  local cando=false
  local n=0

  local gotit=false
  for _,canmission in pairs(Squadron.missiontypes) do
    if canmission==MissionType then
      gotit=true
      break
    end   
  end
  
  if not gotit then
    -- This squad cannot do this mission.
    cando=false
    n=0
  else

    for _,_asset in pairs(Squadron.assets) do
      local asset=_asset --#AIRWING.SquadronAsset
      
      -- Check if has already a mission assigned.
      if asset.mission==nil then
        n=n+1
      end
      
    end
  
  end
  
  -- Check if required assets are present.
  if Nassets then
    if Nassets<n then 
      cando=false
    end
  end
    
  return cando, n
end

--- Check if assets for a given mission type are available.
-- @param #AIRWING self
-- @param #string MissionType Type of mission.
-- @param #number Nassets Amount of assets required for the mission. Default 1.
-- @return #boolean If true, enough assets are available.
-- @return #number Number of assets available for the mission type.
function AIRWING:CanMission(MissionType, Nassets)

  local Can=false
  local N=0

  local n=0
  for squadname,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --#AIRWING.Squadron

    -- Check if this squadron can.
    local can, n=self:SquadronCanMission(squadron, MissionType, Nassets)
    
    -- If anyone can, we Can.
    if can then
      Can=true
    end
    
    -- Total number.
    N=N+n

  end
  
  return Can, N
end

--- Create a CAP mission.
-- @param #AIRWING self
-- @param #number Altitude Orbit altitude in feet. Default 10000 ft.
-- @param #number SpeedOrbit Orbit speed in knots. Default 350 kts.
-- @param #number Heading Heading in degrees. Default 270° (East to West).
-- @param #number Leg Length of race-track in NM. Default 10 NM.
-- @return #AIRWING.MissionCAP The CAP mission table.
function AIRWING:CreateMissionCAP(Altitude, SpeedOrbit, Heading, Leg)

  local mission={} --#AIRWING.Missiondata
  
  mission.type=FLIGHTGROUP.MissionType.CAP
  mission.altitude=UTILS.FeetToMeters(Altitude or 10000)
  mission.speedOrbit=UTILS.KnotsToMps(SpeedOrbit or 350)
  mission.heading=Heading or 270
  mission.leg=UTILS.NMToMeters(Leg or 10)

  return mission
end

--- Add mission to queue.
-- @param #AIRWING self
-- @param AIRWING.Missiondata Mission for this group.
-- @param Core.Zone#ZONE Zone The mission zone.
-- @param #number WaypointIndex The waypoint index.
-- @param #string ClockStart Time the mission is started, e.g. "05:00" for 5 am. If specified as a #number, it will be relative (in seconds) to the current mission time. Default is 5 seconds after mission was added.
-- @param #string ClockStop Time the mission is stopped, e.g. "13:00" for 1 pm. If mission could not be started at that time, it will be removed from the queue. If specified as a #number it will be relative (in seconds) to the current mission time.
-- @param #number Prio Priority of the mission, i.e. a number between 1 and 100. Default 50.
-- @param #string Name Mission name. Default "Aerial Refueling #00X", where "#00X" is a running mission counter index starting at "#001".
-- @return #AIRWING.Missiondata The mission table.
function AIRWING:AddMission(Mission, Zone, WaypointIndex, ClockStart, ClockStop, Prio, Name)

  -- TODO: need to check that this call increases the correct mission counter and adds it to the mission queue.
  local mission=FLIGHTGROUP.AddMission(self, Mission, Zone, WaypointIndex, ClockStart, ClockStop, Prio, Name)

  -- Mission needs the correct MID.
  mission.mid=nil
  mission.MID=self.missioncounter
  
  return mission
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
  self:I(self.lid..string.format("Starting AIRWING v%s %s (%s)", AIRWING.version, self.alias, self.warehousename))

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
  self:I(self.lid..text)
  
  local text="Squadrons:"
  for i,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --#AIRWING.Squadron
    
    -- Squadron text
    text=text..string.format("\n* %s", squadron.name)
    
    -- Loop over all assets.
    for j,_asset in pairs(squadron.assets) do
      local asset=_asset --#AIRWING.SquadronAsset
      local assignment=asset.assignment or "none"
      local name=asset.templatename
      local task=asset.mission and asset.mission.name or "none"
      local spawned=tostring(asset.spawned)
      local groupname=asset.spawngroupname
      local group=nil --Wrapper.Group#GROUP
      local typename=asset.unittype
      local fuel=100
      if groupname then
        group=GROUP:FindByName(groupname)
        if group then
          fuel=group:GetFuelMin()
        end
      end
      
      text=text..string.format("\n  -[%d] %s*%d: spawned=%s, mission=%s, fuel=%d", j, typename, asset.nunits, spawned, task, fuel)
      
    end
  end
  self:I(self.lid..text)
  
  --------------
  -- Mission ---
  --------------
  
  -- Get next mission.
  local mission=self:_GetNextMission()

  -- Request mission execution.  
  if mission then
    self:RequestMission(mission)
  end

  self:__AirwingStatus(-30)
end

--- Get next mission.
-- @param #AIRWING self
-- @return #AIRWING.Missiondata Next mission or *nil*.
function AIRWING:_GetNextMission()

  -- Number of missions.
  local Nmissions=#self.missionqueue

  -- Treat special cases.
  if Nmissions==0 then
    return nil
  end

  -- Sort results table wrt times they have already been engaged.
  local function _sort(a, b)
    local taskA=a --#AIRWING.Mission
    local taskB=b --#AIRWING.Mission
    --TODO: probably sort by prio first and then by time as only missions for T>Tstart are executed. That would ensure that the highest prio mission is carried out first!
    return (taskA.Tstart<taskB.Tstart) or (taskA.Tstart==taskB.Tstart and taskA.prio<taskB.prio)
  end
  table.sort(self.missionqueue, _sort)
  
  -- Current time.
  local time=timer.getAbsTime()

  -- Look for first task that is not accomplished.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --#AIRWING.Missiondata
    
    -- Check that mission is still scheduled, time has passed and enough assets are available.
    if mission.status==FLIGHTGROUP.MissionStatus.SCHEDULED and time>=mission.Tstart and self:CanMission(mission.type, mission.nassets) then
      return mission
    end
  end

  return nil
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "NewAsset" event. An asset has been added to the airwing stock.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset The asset that has just been added.
-- @param #string assignment The (optional) assignment for the asset.
function AIRWING:onafterNewAsset(From, Event, To, asset, assignment)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterNewAsset(self, From, Event, To, asset, assignment)
  
  local squad=self:GetSquadron(assignment)  

  if squad then

    local text=string.format("FF assignment=%s, squadron=%s", assignment, squad.name)
    env.info(text)
    
    table.insert(squad.assets, asset)
        
  end
end


--- On before "NewAsset" event.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #AIRWING.Mission Mission
-- @return #boolean Allowed transition?
function AIRWING:onbeforeAddMission(From, Event, To, Mission)
  
  local allowed=true
  
  -- Check if any squadron can to this type of mission.
  -- TODO: well, could be that new squadrons with the capability are added at a later time.
  local cando=self:CanMission(Mission.type)  
  if not cando then
    allowed=false
  end  
    
  return allowed
end

--- On after "NewAsset" event.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #AIRWING.Mission Mission
function AIRWING:onafterAddMission(From, Event, To, Mission)

  -- Add Mission to queue.
  table.insert(self.missionqueue, Mission)

end

--- On after "RequestMission" event.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #AIRWING.Missiondata Mission The requested mission.
function AIRWING:onafterRequestMission(From, Event, To, Mission)

  Mission.status=FLIGHTGROUP.MissionStatus.ASSIGNED

  --TODO: request descriptor/attribute for given mission type! AWACS, Tankers, Fighters.
  --TODO: also check that mission prio is same as warehouse prio (small=high or the other way around).
  self:AddRequest(self, WAREHOUSE.Descriptor.ASSIGNMENT, Mission.squadname, Mission.nassets, nil, nil, Mission.prio, tostring(Mission.mid))  

end

--- On after "Request" event. Spawns the necessary cargo and transport assets.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Functional.Warehouse#WAREHOUSE.Queueitem Request Information table of the request.
function AIRWING:onafterRequest(From, Event, To, Request)

  -- Modify the cargo assets.
  local assets=Request.cargoassets
  
  local Mission=self:GetMissionByID(Request.assignment)
  
  for _,_asset in pairs(assets) do
    local asset=_asset --#AIRWING.SquadronAsset
    
    asset.payload=Mission.payload
    
  end

  
end

--- On after "AssetSpawned" event triggered when an asset group is spawned into the cruel world.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP group The group spawned.
-- @param #AIRWING.SquadronAsset asset The asset that was spawned.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem request The request of the dead asset.
function AIRWING:onafterAssetSpawned(From, Event, To, group, asset, request)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterAssetSpawned(self, From, Event, To, group, asset, request)
  
  local mid=tonumber(request.assignment)
  
  -- Set mission.
  asset.mission=self:GetMissionByID(mid)
  
  -- Create flightgroup.
  local flightgroup=FLIGHTGROUP:New(group:GetName())
  
  asset.flightgroup=flightgroup
  
  -- Add mission to flightgroup queue.
  asset.flightgroup:AddMission(asset.mission)
  
  --[[
  local airwing=self
  
  function flightgroup:OnAfterMissionStart(From, Event, To, Mission)
    local mission=Mission --#AIRWING.Missiondata
   
    
    --mission.status.FLIGHTGROUP
  
  end
  
  function flightgroup:OnAfterMissionDone(From, Event, To, Mission)
  
  end
  ]]
 
end

--- On after "SelfRequest" event.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Set#SET_GROUP groupset The set of asset groups that was delivered to the warehouse itself.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem request Pending self request.
function AIRWING:onafterSelfRequest(From, Event, To, groupset, request)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterSelfRequest(self, From, Event, To, groupset, request)
  
  local mid=tonumber(request.assignment)
  
  local mission=self:GetMissionByID(mid)

  
  for _,_asset in pairs(request.assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem    
  end
  
  
  for _,_group in pairs(groupset:GetSet()) do
    local group=_group --Wrapper.Group#GROUP
      
  end

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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Patrol carrier.
-- @param #AIRWING self
-- @param #number mid Mission ID.
-- @return #AIRWING.Missiondata Mission table.
function AIRWING:GetMissionByID(mid)

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --#AIRWING.Missiondata
    
    if mission.MID==mid then
      return mission
    end
    
  end

  --return self.missionqueue[mid]

  return nil
end


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
  
  self:I(self.lid..text)
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
