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
-- @field #table menu Table of menu items.
-- @field #table squadrons Table of squadrons.
-- @field #table missionqueue Mission queue table.
-- @field #table payloads Playloads for specific aircraft and mission types. 
-- @field #number payloadcounter Running index of payloads.
-- @field Core.Set#SET_ZONE zonesetCAP Set of CAP zones.
-- @field Core.Set#SET_ZONE zonesetTANKER Set of TANKER zones.
-- @field Core.Set#SET_ZONE zonesetAWACS Set of AWACS zones.
-- @field #number nflightsCAP Number of CAP flights constantly in the air.
-- @field #number nflightsTANKER Number of TANKER flights constantly in the air.
-- @field #number nflightsAWACS Number of AWACS flights constantly in the air.
-- @field #table cappoints Table of CAP points.
-- @field Ops.WingCommander#WINGCOMMANDER wingcommander The wing commander responsible for this airwing.
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
  Debug          = false,
  lid            =   nil,
  menu           =   nil,
  squadrons      =    {},
  missionqueue   =    {},
  payloads       =    {},
  cappoints      =    {},
  wingcommander  =   nil,
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
-- @field #AIRWING.Payload payload The payload of the asset.
-- @field Ops.FlightGroup#FLIGHTGROUP flightgroup The flightgroup object.
-- @extends Functional.Warehouse#WAREHOUSE.Assetitem

--- Payload data.
-- @type AIRWING.Payload
-- @field #string unitname Name of the unit this pylon was extracted from.
-- @field #string aircrafttype Type of aircraft, which can use this payload.
-- @field #table missiontypes Mission types for which this payload can be used.
-- @field #table pylons Pylon data extracted for the unit template.
-- @field #number navail Number of available payloads of this type.
-- @field #boolean unlimited If true, this payload is unlimited and does not get consumed.

--- CAP data.
-- @type AIRWING.PatrolData
-- @field Core.Point#COORDINATE coord CAP coordinate.
-- @field #number heading heading
-- @field #number leg Leg.
-- @field #number speed Speed.
-- @field #boolean occupied Is currently occupied.

--- AIRWING class version.
-- @field #string version
AIRWING.version="0.1.4"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- DONE: Add squadrons to warehouse.
-- TODO: Make special request to transfer squadrons to anther airwing (or warehouse).
-- DONE: Build mission queue.
-- DONE: Find way to start missions.
-- TODO: Check if missions are done/cancelled.
-- DONE: Payloads as resources.
-- TODO: Spawn in air or hot.
-- TODO: Define CAP zones.
-- TODO: Define TANKER zones for refuelling.
-- TODO: Border zone or even multiple zones.
-- TODO: Check that airbase has enough parking spots if a request is BIG. Alternatively, split requests.

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

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("AIRWING %s | ", self.alias)

  -- Add FSM transitions.
  --                 From State  -->   Event      -->     To State
  self:AddTransition("*",             "MissionRequest",   "*")           -- Add a (mission) request to the warehouse.
  self:AddTransition("*",             "MissionCancel",    "*")           -- Cancel mission.

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


  -- Debug trace.
  if false then
    self.Debug=true
    self:TraceOnOff(true)
    self:TraceClass(self.ClassName)
    self:TraceLevel(1)
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a squadron to the air wing.
-- @param #AIRWING self
-- @param #string SquadronName Name of the squadron, e.g. "VFA-37".
-- @param #table MissionTypes Table of mission types this squadron is able to perform.
-- @param #string Livery The livery for all added flight group. Default is the livery of the template group.
-- @param #string Skill The skill of all squadron members.
-- @return #AIRWING.Squadron The squadron object.
function AIRWING:AddSquadron(SquadronName, MissionTypes, Livery, Skill)

  -- Ensure Missiontypes is a table.
  if MissionTypes and type(MissionTypes)~="table" then
    MissionTypes={MissionTypes}
  end
  
  -- TODO: Mission types that anyone can do! ORBIT, Ferry, ???
  if not self:CheckMissionType(AUFTRAG.Type.ORBIT, MissionTypes) then
    table.insert(MissionTypes, AUFTRAG.Type.ORBIT)
  end

  -- Set up new squadron data.
  local squadron={} --#AIRWING.Squadron
  squadron.name=SquadronName
  squadron.assets={}
  squadron.missiontypes=MissionTypes
  squadron.livery=Livery
  squadron.skill=Skill

  self.squadrons[SquadronName]=squadron
  
  return squadron
end

--- Add a **new** payload to air wing resources.
-- @param #AIRWING self
-- @param Wrapper.Unit#UNIT Unit The unit, the payload is extracted from. Can also be given as *#string* name of the unit.
-- @param #table MissionTypes Mission types this payload can be used for.
-- @param #number Npayloads Number of payloads to add to the airwing resources. Default 99 (which should be enough for most scenarios).
-- @param #boolean Unlimited If true, this payload is unlimited.
-- @return #AIRWING.Payload The payload table or nil if the unit does not exist.
function AIRWING:NewPayload(Unit, MissionTypes, Npayloads, Unlimited)

  if type(Unit)=="string" then
    Unit=UNIT:FindByName(Unit)
    if not Unit then
      Unit=GROUP:FindByName(Unit)
    end
  end

  -- If a GROUP object was given, get the first unit.
  if Unit:IsInstanceOf("GROUP") then
    Unit=Unit:GetUnit(1)
  end

  -- Ensure Missiontypes is a table.
  if MissionTypes and type(MissionTypes)~="table" then
    MissionTypes={MissionTypes}
  end
  
  if Unit then
    
    local payload={} --#AIRWING.Payload
    
    payload.unitname=Unit:GetName()
    payload.aircrafttype=Unit:GetTypeName()
    payload.missiontypes=MissionTypes or {}
    payload.pylons=Unit:GetTemplatePayload()
    payload.navail=Npayloads or 99
    payload.unlimited=Unlimited
    if Unlimited then
      payload.navail=1
    end
        
    -- Add payload
    table.insert(self.payloads, payload)
    
    -- Info
    self:I(self.lid..string.format("Adding new payload from unit %s for aircraft type %s: N=%d (unlimited=%s), missions:", payload.unitname, payload.aircrafttype, payload.navail, tostring(payload.unlimited)))
    self:I({MissionTypes=payload.missiontypes})
    
    return payload
  end

  return nil
end

--- Fetch a payload from the airwing resources for a given unit and mission type.
-- @param #AIRWING self
-- @param #string UnitType The type of the unit.
-- @param #string MissionType The mission type.
-- @return #AIRWING.Payload Payload table or *nil*.
function AIRWING:FetchPayloadFromStock(UnitType, MissionType)
  
  for _,_payload in pairs(self.payloads) do
    local payload=_payload --#AIRWING.Payload
    
    
    -- Check right type, mission and available.
    if payload.aircrafttype==UnitType and payload.navail>0 and self:CheckMissionType(MissionType, payload.missiontypes) then
    
      -- Consume if not unlimited.
      if not payload.unlimited then
        payload.navail=payload.navail-1
      end
      
      -- Return a copy of the table.
      return payload
    end
    
  end
  
  return nil
end

--- Return payload from asset back to stock.
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset asset The squadron asset.
function AIRWING:ReturnPayloadFromAsset(asset)

  local payload=asset.payload
  
  if payload then
  
    -- Increase count if not unlimited.
    if not payload.unlimited then
      payload.navail=payload.navail+1
    end

    -- Remove asset payload.
    asset.payload=nil
    
  else
    self:E(self.lid.."ERROR: asset had no payload attached!")
  end
    
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
    
      self:AddAsset(Group, Ngroups, nil, nil, nil, nil, squadron.skill, squadron.livery, squadron.name)
      
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
-- @return #AIRWING.Squadron Squadron table.
function AIRWING:GetSquadron(SquadronName)
  return self.squadrons[SquadronName]
end


--- Add mission to queue.
-- @param #AIRWING self
-- @param Ops.Auftrag#AUFTRAG Mission for this group.
-- @return #AIRWING self
function AIRWING:AddMission(Mission)
  
  -- Set status to QUEUED. This also attaches the airwing to this mission.
  Mission:Queued(self)
  
  -- Add mission to queue.
  table.insert(self.missionqueue, Mission)
  
  -- Info text.
  local text=string.format("Added %s mission %s. Starting at %s. Stopping at %s", 
  tostring(Mission.type), tostring(Mission.name), UTILS.SecondsToClock(Mission.Tstart, true), Mission.Tstop and UTILS.SecondsToClock(Mission.Tstop, true) or "INF")
  self:I(self.lid..text)
  
  return self
end

--- Remove mission from queue.
-- @param #AIRWING self
-- @param Ops.Auftrag#AUFTRAG Mission Mission to be removed.
-- @return #AIRWING self
function AIRWING:RemoveMission(Mission)

  for i,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission.auftragsnummer==Mission.auftragsnummer then
      table.remove(self.missionqueue, i)
      break
    end
    
  end

  return self
end

--- Set number of CAP flights constantly carried out.
-- @param #AIRWING self
-- @param #number n Number of flights. Default 1.
-- @return #AIRWING self
function AIRWING:SetNumberCAP(n)
  self.nflightsCAP=n or 1
  return self
end

--- Set number of TANKER flights constantly in the air.
-- @param #AIRWING self
-- @param #number n Number of flights. Default 1.
-- @return #AIRWING self
function AIRWING:SetNumberTANKER(n)
  self.nflightsTANKER=n or 1
  return self
end

--- Set number of AWACS flights constantly in the air.
-- @param #AIRWING self
-- @param #number n Number of flights. Default 1.
-- @return #AIRWING self
function AIRWING:SetNumberAWACS(n)
  self.nflightsAWACS=n or 1
  return self
end


--- Add a patrol Point for CAP missions.
-- @param #AIRWING self
-- @param Core.Zone#ZONE AcceptZone Add a zone to the CAP zone set.
-- @return #AIRWING self
function AIRWING:AddPatrolPointCAP(Coordinate, Heading, Leg, Speed)
  
  local cappoint={}  --#AIRWING.PatrolData
  cappoint.coord=Coordinate
  cappoint.heading=Heading or 090
  cappoint.leg=Leg or 15
  cappoint.speed=Speed or 350

  table.insert(self.cappoints, cappoint)

  return self
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
  self:I(self.lid..string.format("Starting AIRWING v%s", AIRWING.version))

  -- Menu.
  if false then

    -- Add F10 radio menu.
    self:_SetMenuCoalition()
  
    for _,_squadron in pairs(self.squadrons) do
      local squadron=_squadron --#AIRWING.Squadron
      self:_AddSquadonMenu(squadron)
    end
    
  end

end

--- Update status.
-- @param #AIRWING self
function AIRWING:onafterStatus(From, Event, To)

  -- Status of parent Warehouse.
  self:GetParent(self).onafterStatus(self, From, Event, To)

  local fsmstate=self:GetState()
  
  -- Check CAP missions.
  --self:CheckCAP()
  
  --self:CheckTANKER()
  
  --self:CheckAWACS()
  
  ------------------
  -- Mission Info --
  ------------------
  local text=string.format("Missions Total=%d:", #self.missionqueue)
  for i,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    text=text..string.format("\n[%d] %s: Status=%s, Nassets=%d, Prio=%d, ID=%d (%s)", i, mission.type, mission.status, mission.nassets, mission.prio, mission.auftragsnummer, mission.name)
  end
  self:I(self.lid..text)

  -------------------
  -- Squadron Info --
  -------------------
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
      local spawned=tostring(asset.spawned)
      local groupname=asset.spawngroupname
      local typename=asset.unittype
      
      local mission=self:GetAssetCurrentMission(asset)
      local missiontext=""
      if mission then
        missiontext=string.format(" [%s (%s): status=%s]", mission.type, mission.name, mission.status)
      end
            
      text=text..string.format("\n  -[%d] %s*%d: spawned=%s, mission=%s%s", j, typename, asset.nunits, spawned, tostring(self:IsAssetOnMission(asset)), missiontext)
      
      local payload=asset.payload
      if payload then
        text=text.." payload "..table.concat(payload.missiontypes, ", ")
      else
        text=text.." NO payload!"
      end
      
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
    self:MissionRequest(mission)
  end

end

--- Get patrol data
-- @param #AIRWING self
-- @param #table PatrolPoints Patrol data points.
-- @return #AIRWING.PatrolData
function AIRWING:_GetPatrolData(PatrolPoints)

  local function sort(a,b)
    return a.noccuied<b.noccuied
  end

  if PatrolPoints then
  
    -- Sort data wrt number of flights at that point.
    table.sort(PatrolPoints, sort)
    return PatrolPoints[1]

  else
  
    local point={} --#AIRWING.PatrolData
    
    point.coord=self:GetCoordinate()
    point.speed=math.random(250, 350)
    point.heading=math.random(360)
    point.occupied=false
  
  end


end

--- Get next mission.
-- @param #AIRWING self
-- @return Ops.Auftrag#AUFTRAG Next mission or *nil*.
function AIRWING:CheckCAP()

  local Ncap=self:CountAssetsOnMission(AUFTRAG.Type.PATROL)
  
  for i=1,self.nflightsCAP-Ncap do
  
    local patrol=self:_GetPatrolData(self.cappoints)
    
    local missionCAP=AUFTRAG:NewPATROL(patrol.coord, patrol.speed, patrol.heading, patrol.leg)
    
    missionCAP.patroldata=patrol
    
    self:AddMission(missionCAP)
      
  end
  
end


--- Get next mission.
-- @param #AIRWING self
-- @return Ops.Auftrag#AUFTRAG Next mission or *nil*.
function AIRWING:_GetNextMission()

  -- Number of missions.
  local Nmissions=#self.missionqueue

  -- Treat special cases.
  if Nmissions==0 then
    return nil
  end

  -- Sort results table wrt times they have already been engaged.
  local function _sort(a, b)
    local taskA=a --Ops.Auftrag#AUFTRAG
    local taskB=b --Ops.Auftrag#AUFTRAG
    return (taskA.prio<taskB.prio) or (taskA.prio==taskB.prio and taskA.Tstart<taskB.Tstart)
  end
  table.sort(self.missionqueue, _sort)
  
  -- Current time.
  local time=timer.getAbsTime()

  -- Look for first task that is not accomplished.
  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- Firstly, check if mission is due?
    if mission.status==AUFTRAG.Status.QUEUED and time>=mission.Tstart then
        
      -- Check if airwing can do the mission and gather required assets.
      local can, assets=self:CanMission(mission.type, mission.nassets)
      
      -- Debug output.
      self:T3({self.lid.."Mission check:", TstartPassed=time>=mission.Tstart, CanMission=can, Nassets=#assets})
      
      -- Check that mission is still scheduled, time has passed and enough assets are available.
       if can then
       
        -- Optimize the asset selection. Most useful assets will come first.
        -- TODO: This could be moved to AUFTRAG, right?
        --self:_OptimizeAssetSelection(assets, mission)
      
        -- Check that mission.assets table is clean.
        if mission.assets and #mission.assets>0 then
          self:E(self.lid..string.format("ERROR: mission %s of type %s has already assets attached!", mission.name, mission.type))
        end
        mission.assets={}
      
        -- Assign assets to mission.
        for i=1,mission.nassets do      
          local asset=assets[i] --#AIRWING.SquadronAsset
          
          -- Get payload for the asset.
          asset.payload=self:FetchPayloadFromStock(asset.unittype, mission.type)
          
          if not asset.payload then
            self:E("No payload for asset! This should not happen!")
          end
          
          mission:AddAsset(asset)
        end
        
        return mission
      end

    end -- mission due?
  end -- mission loop

  return nil
end

--- Optimize chosen assets for the mission at hand.
-- @param #AIRWING self
-- @param #table assets Table of (unoptimized) assets.
-- @param Ops.Auftrag#AUFTRAG Mission Next mission or *nil*.
function AIRWING:_OptimizeAssetSelection(assets, Mission)

  local TargetCoordinate=Mission:GetTargetCoordinate()

  local dStock=self:GetCoordinate():Get2DDistance(TargetCoordinate)
  
  for _,_asset in pairs(assets) do
    local asset=_asset --#AIRWING.SquadronAsset
    
    if asset.spawned then
      local group=GROUP:FindByName(asset.spawngroupname)
      asset.dist=group:GetCoordinate():Get2DDistance(TargetCoordinate)
    else
      asset.dist=dStock
    end    
    
  end
  
  -- Sort results table wrt distacance.
  local function optimize(a, b)
    local assetA=a --#AIRWING.SquadronAsset
    local assetB=b --#AIRWING.SquadronAsset
    
    --TODO: This could be vastly improved. Need to gather ideas during testing
    -- Calculate ETA? Assets on orbit missions should arrive faster even if they are further away.
    -- Max speed of assets.
    -- Fuel amount?
    -- Range of assets?
    
    --TODO: Need to define a scoring function, which gives a weighted result of more parameters.
    
    return (assetA.dist<assetB.dist) --or (dA==dB and taskA.prio<taskB.prio)
  end
  
  -- Optimize order of assets.
  table.sort(assets, optimize)
  
  -- Remove distance parameter.
  for _,asset in pairs(assets) do
    asset.dist=nil
  end  

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Events
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "MissionRequest" event. Performs a self request to the warehouse for the mission assets. Sets mission status to REQUESTED.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The requested mission.
function AIRWING:onafterMissionRequest(From, Event, To, Mission)

  -- Set mission status from QUEUED to REQUESTED. Ensures that it is not considered in the next selection.
  Mission:Requested()
  
  ---
  -- Some assets might already be spawned and even on a different mission (orbit).
  -- Need to dived to set into spawned and instock assets and handle the other
  ---

  -- Assets to be requested
  local Assetlist={}
  
  for _,_asset in pairs(Mission.assets) do
    local asset=_asset --#AIRWING.SquadronAsset
    
    if asset.spawned then
    
      if asset.flightgroup then
        --TODO: cancel current mission if there is any!
        asset.flightgroup:AddMission(Mission)
      else
        self:E(self.lid.."ERROR: flight group for asset does NOT exist!")
      end    
    
    else
      -- These assets need to be requested and spawned.
      table.insert(Assetlist, asset)
    end
  end

  -- Add request to airwing warehouse.
  if #Assetlist>0 then
  
    -- Add request to airwing warehouse.
    -- TODO: better Assignment string.
    self:AddRequest(self, WAREHOUSE.Descriptor.ASSETLIST, Assetlist, #Assetlist, nil, nil, Mission.prio, tostring(Mission.auftragsnummer))
    
    -- The queueid has been increased in the onafterAddRequest function. So we can simply use it here.
    Mission.requestID=self.queueid
  end

end

--- On after "MissionCancel" event. Cancels the missions of all flightgroups. Deletes request from warehouse queue.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.Auftrag#AUFTRAG Mission The mission to be cancelled.
function AIRWING:onafterMissionCancel(From, Event, To, Mission)
  
  self:I(self.lid..string.format("Cancel mission %s", Mission.name))
  
  for _,_asset in pairs(Mission.assets) do
    local asset=_asset --#AIRWING.SquadronAsset
    
    local flightgroup=asset.flightgroup
    
    if flightgroup then
      flightgroup:MissionCancel(Mission)
    end
  end
  
  -- Remove queued request (if any).
  if Mission.requestID then
    self:_DeleteQueueItemByID(Mission.requestID, self.queue)
  end
  
end

--- On after "NewAsset" event. Asset is added to the given squadron (asset assignment).
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Functional.Warehouse#WAREHOUSE.Assetitem asset The asset that has just been added.
-- @param #string assignment The (optional) assignment for the asset.
function AIRWING:onafterNewAsset(From, Event, To, asset, assignment)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterNewAsset(self, From, Event, To, asset, assignment)
  
  -- Debug text.
  local text=string.format("New asset %s with assignment %s and request assignment %s", asset.spawngroupname, tostring(asset.assignment), tostring(assignment))
  self:I(self.lid..text)
  
  -- Get squadron.
  local squad=self:GetSquadron(asset.assignment)

  -- Check if asset is already part of the squadron. If an asset returns, it will be added again! We check that asset.assignment is also assignment.
  if squad then

    if asset.assignment==assignment then
  
      -- Debug text.
      local text=string.format("Adding asset to squadron %s: assignment=%s, type=%s, attribute=%s", squad.name, assignment, asset.unittype, asset.attribute)
      self:I(self.lid..text)
      
      -- Add asset to squadron.
      table.insert(squad.assets, asset)
      
    else
    
      self:I(self.lid..string.format("Asset %s from squadron %s returned! asset.assignment=\"%s\", assignment=\"%s\"", asset.spawngroupname, squad.name, tostring(asset.assignment), tostring(assignment)))
      self:ReturnPayloadFromAsset(asset)
      
      -- Mission might already be removed from the queue!
      --[[
      local mission=self:GetMissionByID(assignment)
      
      if mission then
        local text=string.format("Asset %s returned from %s mission %s", asset.spawngroupname, mission.type, mission.name)
        self:I(self.lid..text)
        self:ReturnPayloadFromAsset(asset)
      else
        self:E(self.lid..string.format("ERROR: asset %s from squadron %s returned but could not find its mission! asset.assignment=\"%s\", assignment=\"%s\"", asset.spawngroupname, squad.name, tostring(asset.assignment), tostring(assignment)))
      end
      ]]
    
    end
        
  end
end




--- On after "AssetSpawned" event triggered when an asset group is spawned into the cruel world. 
-- Creates a new flightgroup element and adds the mission to the flightgroup queue.
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

  -- Create a flight group.
  asset.flightgroup=self:_CreateFlightGroup(asset)
  
  -- Get Mission (if any).
  local mission=self:GetMissionByID(request.assignment)  

  -- Add mission to flightgroup queue.
  if mission then
      
    -- Add mission to flightgroup queue.  
    asset.flightgroup:AddMission(mission)
  end
  
  -- Add group to the detection set of the WINGCOMMANDER.
  if self.wingcommander then
    self.wingcommander.detectionset:AddGroup(asset.flightgroup.group)
  end
  
end

--- On after "AssetDead" event triggered when an asset group died.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #AIRWING.SquadronAsset asset The asset that is dead.
-- @param Functional.Warehouse#WAREHOUSE.Pendingitem request The request of the dead asset.
function AIRWING:onafterAssetDead(From, Event, To, asset, request)

  -- Call parent warehouse function first.
  self:GetParent(self).onafterAssetDead(From, Event, To, asset, request)

  -- Add group to the detection set of the WINGCOMMANDER.
  if self.wingcommander then
    self.wingcommander.detectionset:RemoveGroupsByName({asset.spawngroupname})
  end  
end


--- On after "Request" event.
-- @param #AIRWING self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Functional.Warehouse#WAREHOUSE.Queueitem Request Information table of the request.
function AIRWING:onafterRequest(From, Event, To, Request)

  -- Assets
  local assets=Request.cargoassets
  
  -- Get Mission
  local Mission=self:GetMissionByID(Request.assignment)
  
  if Mission and assets then
  
    for _,_asset in pairs(assets) do
      local asset=_asset --#AIRWING.SquadronAsset      
      -- This would be the place to modify the asset table before the asset is spawned.
    end
    
  end

  -- Call parent warehouse function after assets have been adjusted.
  self:GetParent(self).onafterRequest(self, From, Event, To, Request)
  
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

  -- Get Mission
  local mission=self:GetMissionByID(request.assignment)
  
  for _,_asset in pairs(request.assets) do
    local asset=_asset --#AIRWING.SquadronAsset
  end
    
  for _,_group in pairs(groupset:GetSet()) do
    local group=_group --Wrapper.Group#GROUP      
  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new flight group after an asset was spawned.
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset asset The asset.
-- @return Ops.FlightGroup#FLIGHTGROUP The created flightgroup object.
function AIRWING:_CreateFlightGroup(asset)

  -- Create flightgroup.
  local flightgroup=FLIGHTGROUP:New(asset.spawngroupname)

  -- Set airwing.
  flightgroup:SetAirwing(self)  
  
  --- Check if out of missiles. For A2A missions ==> RTB.
  function flightgroup:OnAfterOutOfMissiles()  
    local airwing=flightgroup:GetAirWing()
    
  end
  
  --- Check if out of missiles. For A2G missions ==> RTB. But need to check A2G missiles, rockets as well.
  function flightgroup:OnAfterOutOfBombs()  
    local airwing=flightgroup:GetAirWing()
  
  end


  --- Mission started.
  function flightgroup:OnAfterMissionStart(From, Event, To, Mission)
    local airwing=flightgroup:GetAirWing()

    -- TODO: Add event? Set mission status!
    --airwing:MissionStart(Mission)
  
  end
  
  --- Flight is DEAD.
  function flightgroup:OnAfterFlightDead(From, Event, To)  
    local airwing=flightgroup:GetAirWing()
    
    -- TODO
    -- Mission failed ==> launch new mission?
    
  end
  
  return flightgroup
end


--- Check if there is a squadron that can execute a given mission type. Optionally, the number of required assets can be specified.
-- @param #AIRWING self
-- @param #AIRWING.Squadron Squadron The Squadron.
-- @param #string MissionType Type of mission.
-- @param #number Nassets Number of required assets for the mission. Use *nil* or 0 for none. Then only the general capability is checked.
-- @return #boolean If true, Squadron can do that type of mission. Available assets are not checked.
-- @return #table Assets that can do the required mission.
function AIRWING:SquadronCanMission(Squadron, MissionType, Nassets)

  local cando=true
  local assets={}

  -- WARNING: This assumes that all assets of the squad can do the same mission types!
  -- TODO: we could make the mission type as a parameter of the assets! Then we can have heterogenious squads as well!
  local gotit=self:CheckMissionType(MissionType, Squadron.missiontypes)
  
  if not gotit then
    -- This squad cannot do this mission.
    cando=false
  else

    for _,_asset in pairs(Squadron.assets) do
      local asset=_asset --#AIRWING.SquadronAsset
      
      -- Check if has already any missions in the queue.
      if self:IsAssetOnMission(asset) then

        ---
        -- This asset is already on a mission
        ---

        --TODO: This only checks if it has an ORBIT mission. It could have others as well!
        if self:IsAssetOnMission(asset, AUFTRAG.Type.ORBIT) and MissionType~=AUFTRAG.Type.ORBIT then

          -- Check if the payload of this asset is compatible with the mission.
          if self:CheckMissionType(MissionType, asset.payload.missiontypes) then
            -- TODO: Check if asset actually has weapons left. Difficult!
            table.insert(assets, asset)
          end
          
        end      
      
      else
      
        ---
        -- This asset as no current mission
        ---

        if asset.spawned then
          -- This asset is already spawned. Let's check if it has the right payload.
          if self:CheckMissionType(MissionType, asset.payload.missiontypes) then
            table.insert(assets, asset)
          end
        else
        
          -- Check if we got a payload and reserve it for this asset.
          local payload=self:FetchPayloadFromStock(asset.unittype, MissionType)
          if payload then
            asset.payload=payload
            table.insert(assets, asset)
          end
        end
        
      end
      
    end
  
  end
  
  -- Check if required assets are present.
  if Nassets and Nassets > #assets then
    cando=false
  end

  return cando, assets
end

--- Check if an asset is currently on a mission or has one in the queue.
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset asset The asset.
-- @param #table MissionTypes Types on mission to be checked. Default all.
-- @return #boolean If true, asset has at least one mission of that type in the queue.
function AIRWING:IsAssetOnMission(asset, MissionTypes)

  if MissionTypes then
    if type(MissionTypes)~="table" then
      MissionTypes={MissionTypes}
    end
  else
    -- Check all possible types.
    MissionTypes=AUFTRAG.Type
  end

  if asset.flightgroup then
  
    -- Loop over mission queue.
    for _,_mission in pairs(asset.flightgroup.missionqueue or {}) do
      local mission=_mission --Ops.Auftrag#AUFTRAG
      
      local status=mission:GetFlightStatus(asset.flightgroup)
      
      -- Only if mission is not already over.
      if status~=AUFTRAG.FlightStatus.DONE and status~=AUFTRAG.FlightStatus.CANCELLED and self:CheckMissionType(mission.type, MissionTypes) then
        return true
      end
      
    end
  
  end

  return false
end

--- Get the current mission of the asset.
-- @param #AIRWING self
-- @param #AIRWING.SquadronAsset asset The asset.
-- @return Ops.Auftrag#AUFTRAG Current mission or *nil*.
function AIRWING:GetAssetCurrentMission(asset)

  if asset.flightgroup then  
    return asset.flightgroup:GetMissionCurrent()  
  end

  return nil
end


--- Count assets on mission.
-- @param #AIRWING self
-- @param #table MissionTypes Types on mission to be checked. Default all.
-- @return #number Number of pending and queued assets.
-- @return #number Number of pending assets.
-- @return #number Number of queued assets.
function AIRWING:CountAssetsOnMission(MissionTypes)
  
  local Nq=0
  local Np=0

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    -- Check if this mission type is requested.
    if self:CheckMissionType(mission.type, MissionTypes) then
    
      for _,_asset in pairs(mission.assets or {}) do
        local asset=_asset --#AIRWING.SquadronAsset
        
        local request, isqueued=self:GetRequestByID(mission.requestID)
        
        if isqueued then
          Nq=Nq+1
        else
          Np=Np+1
        end
        
      end      
    end
  end

  return Np+Nq, Np, Nq
end

--- Check if assets for a given mission type are available.
-- @param #AIRWING self
-- @param #string MissionType Type of mission.
-- @param #number Nassets Amount of assets required for the mission. Default 1.
-- @return #boolean If true, enough assets are available.
-- @return #table Assets that can do the required mission.
function AIRWING:CanMission(MissionType, Nassets)

  -- Assume we CANNOT and NO assets are available.
  local Can=false
  local Assets={}

  for squadname,_squadron in pairs(self.squadrons) do
    local squadron=_squadron --#AIRWING.Squadron

    -- Check if this squadron can.
    local can, assets=self:SquadronCanMission(squadron, MissionType, Nassets)
    
    -- Debug output.
    local text=string.format("Mission=%s, squadron=%s, can=%s, assets=%d/%d", MissionType, squadron.name, tostring(can), #assets, Nassets)
    self:I(self.lid..text)
    
    -- If anyone can, we Can.
    if can then
      Can=true
    end
    
    -- Total number.
    for _,asset in pairs(assets) do
      table.insert(Assets, asset)
    end

  end


  -- Now clear all reserved payloads.
  for _,_asset in pairs(Assets) do
    local asset=_asset --#AIRWING.SquadronAsset
    -- Only unspawned payloads are returned.
    if not asset.spawned then
      self:ReturnPayloadFromAsset(asset)
    end
  end
  
  return Can, Assets
end


--- Returns the mission for a given mission ID (Autragsnummer).
-- @param #AIRWING self
-- @param #string MissionType The requested mission type.
-- @param #table PossibleTypes A table with possible mission types.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function AIRWING:CheckMissionType(MissionType, PossibleTypes)

  for _,canmission in pairs(PossibleTypes) do
    if canmission==MissionType then
      return true
    end   
  end

  return false
end

--- Returns the mission for a given mission ID (Autragsnummer).
-- @param #AIRWING self
-- @param #number mid Mission ID (Auftragsnummer).
-- @return Ops.Auftrag#AUFTRAG Mission table.
function AIRWING:GetMissionByID(mid)

  for _,_mission in pairs(self.missionqueue) do
    local mission=_mission --Ops.Auftrag#AUFTRAG
    
    if mission.auftragsnummer==tonumber(mid) then
      return mission
    end
    
  end
  
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
