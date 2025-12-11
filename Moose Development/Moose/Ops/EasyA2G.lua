-------------------------------------------------------------------------
-- Easy A2G Engagement Class, based on OPS classes
-------------------------------------------------------------------------
-- 
-- ## Documentation:
-- 
-- https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.EasyAG.html
-- 
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops/EasyAG).
-- 
-------------------------------------------------------------------------
-- Date: Dec 2025
-- Last Update: Dec 2025
-------------------------------------------------------------------------
--
--- **Ops** - Easy A2G Manager
--
-- ===
--
-- **Main Features:**
--
--    * Automatically create and manage A2G defenses using an AirWing and Squadrons for one coalition
--    * Easy set-up
--    * Add additional AirWings on other airbases
--    * Each wing can have more than one Squadron - tasking to Squadrons is done on a random basis per AirWing
--    * Create borders and zones of engagement
--    * Detection can be ground based and/or via AWACS
--
-- ===
-- 
-- ### AUTHOR: **applevangelist**
--
-- @module Ops.EasyAG
-- @image AI_Air_To_Ground_Dispatching.JPG


--- EASYA2G Class
-- @type EASYA2G
-- @field #string ClassName
-- @field #number overhead
-- @field #number engagerange
-- @field #number capgrouping
-- @field #string airbasename
-- @field Wrapper.Airbase#AIRBASE airbase
-- @field #number coalition
-- @field #string alias
-- @field #table wings
-- @field Ops.Intel#INTEL Intel
-- @field #number resurrection
-- @field #number capspeed
-- @field #number capalt
-- @field #number capdir
-- @field #number capleg
-- @field #number maxinterceptsize
-- @field #number missionrange
-- @field #number noalert5
-- @field #table ManagedAW
-- @field #table ManagedSQ
-- @field #table ManagedCP
-- @field #table ManagedTK
-- @field #table ManagedEWR
-- @field #table ManagedREC
-- @field #number MaxAliveMissions
-- @field #boolean debug
-- @field #number repeatsonfailure
-- @field Core.Set#SET_ZONE GoZoneSet
-- @field Core.Set#SET_ZONE NoGoZoneSet
-- @field Core.Set#SET_ZONE ConflictZoneSet
-- @field #boolean Monitor
-- @field #boolean TankerInvisible
-- @field #number CapFormation
-- @field #table ReadyFlightGroups
-- @field #boolean DespawnAfterLanding
-- @field #boolean DespawnAfterHolding
-- @field #list<Ops.Auftrag#AUFTRAG> ListOfAuftrag
-- @field #string defaulttakeofftype Take off type
-- @field #number FuelLowThreshold
-- @field #number FuelCriticalThreshold
-- @field #boolean showpatrolpointmarks
-- @field #table EngageTargetTypes
-- @extends Ops.EasyGCIA2G#EASYGCICAP

--- *“High-Threat Close-Air-Support is a Myth.”* -- Mike “Starbaby” Pietrucha.
--
-- ===
--
-- # The EasyAG Concept
-- 
-- The idea of this class is partially to make the OPS classes easier operational for an A2Gdefense network, and to replace the legacy AI_A2G_Dispatcher system - not to it's
-- full extent, but make a basic system work very quickly.
--
-- # Setup
-- 
-- ## Basic understanding
-- 
-- The basics are, there is **one** and only **one** AirWing per airbase. Each AirWing has **at least** one Squadron, who will do A2G tasks. Squadrons will be randomly chosen for the task at hand.
-- Each AirWing has **at least** one Defense Point that it manages. Defense Points will be covered by the AirWing automatically as long as airframes are available. Detected enemy ground forces will be assigned to **one**
-- AirWing based on proximity (that is, if you have more than one). 
-- 
-- ## Assignment of tasks for enemies
-- 
-- An exisiting plane or a newly spawned plane will take care of the intruders. Standard overhead is 0.75, i.e. a group of 3 intrudes will
-- be managed by 2 planes from the assigned AirWing. There is an maximum missions limitation per AirWing, so we do not spam the skies.
-- 
-- ## Basic set-up code
-- 
-- ### Prerequisites
-- 
-- You have to put a **STATIC WAREHOUSE** object on the airbase with the UNIT name according to the name of the airbase. **Do not put any other static type or it creates a conflict with the airbase name!** 
-- E.g. for Kuitaisi this has to have the unit name Kutaisi. This object symbolizes the AirWing HQ.
-- Next put a late activated template group for your A2G Squadron on the map. Last, put a zone on the map for the Defense operations, let's name it "Blue Zone 1". Size of the zone plays no role.
-- Put a scout system on the map and name it aptly, like "Blue SCOUT".
-- 
-- ### Zones
-- 
-- For our example, you create a RED and a BLUE border, as a closed polygonal zone representing the borderlines. You can also have conflict zone, where - for our example - BLUE will attack
-- RED groups, despite being on RED territory. Think of a no-fly zone or an limited area of engagement. Conflict zones take precedence over borders, i.e. they can overlap all borders.
-- 
-- ### Code it
-- 
--          -- Set up a basic system for the blue side, we'll reside on Kutaisi, and use GROUP objects with "Blue SCOUT" in the name as Detecting Systems.
--          local mywing = EASYA2G:New("Blue A2G Operations",AIRBASE.Caucasus.Kutaisi,"blue","Blue SCOUT")
--          
--          -- Add a patrol point belonging to our airbase, we'll be at 15k ft doing 200 kn, initial direction 90 degrees (East), leg 20NM
--          mywing:AddPatrolPointA2G(AIRBASE.Caucasus.Kutaisi,ZONE:FindByName("Blue Zone 1"):GetCoordinate(),15000,200,90,20)
--          
--          -- Add a Squadron with template "Blue Sq1 M2000c", 20 airframes, skill good, Modex starting with 102 and skin "Vendee Jeanne"
--          mywing:AddSquadron("Blue Sq1 M2000c","A2G Kutaisi",AIRBASE.Caucasus.Kutaisi,20,AI.Skill.GOOD,102,"ec1.5_Vendee_Jeanne_clean")
--          
--          -- Add a couple of zones
--          -- We'll defend our own border
--          mywing:AddAcceptZone(ZONE_POLYGON:New( "Blue Border", GROUP:FindByName( "Blue Border" ) ))
--          -- We'll attack intruders also here - conflictzones can overlap borders(!) - limited zone of engagement
--          mywing:AddConflictZone(ZONE_POLYGON:New("Red Defense Zone", GROUP:FindByName( "Red Defense Zone" )))
--          -- We'll leave the reds alone on their turf
--          mywing:AddRejectZone(ZONE_POLYGON:New( "Red Border", GROUP:FindByName( "Red Border" ) ))
--          
--          -- Optional - Draw the borders on the map so we see what's going on
--          -- Set up borders on map
--          local BlueBorder = ZONE_POLYGON:New( "Blue Border", GROUP:FindByName( "Blue Border" ) )
--          BlueBorder:DrawZone(-1,{0,0,1},1,FillColor,FillAlpha,1,true)
--          local ConflictZone = ZONE_POLYGON:New("Red Defense Zone", GROUP:FindByName( "Red Defense Zone" ))
--          ConflictZone:DrawZone(-1,{1,1,0},1,FillColor,FillAlpha,2,true)
--          local BlueNoGoZone = ZONE_POLYGON:New( "Red Border", GROUP:FindByName( "Red Border" ) )
--          BlueNoGoZone:DrawZone(-1,{1,0,0},1,FillColor,FillAlpha,4,true)
--          
-- ### Add a second airwing with squads and own patrol point (optional)
--          
--          -- Set this up at Sukhumi
--          mywing:AddAirwing(AIRBASE.Caucasus.Sukhumi_Babushara,"Blue A2G Sukhumi")
--          -- A2G Point "Blue Zone 2"
--          mywing:AddPatrolPointA2G(AIRBASE.Caucasus.Sukhumi_Babushara,ZONE:FindByName("Blue Zone 2"):GetCoordinate(),30000,400,90,20)
--          
--          -- This one has two squadrons to choose from
--          mywing:AddSquadron("Blue Sq3 F16","A2G Sukhumi II",AIRBASE.Caucasus.Sukhumi_Babushara,20,AI.Skill.GOOD,402,"JASDF 6th TFS 43-8526 Skull Riders")
--          mywing:AddSquadron("Blue Sq2 F15","A2G Sukhumi I",AIRBASE.Caucasus.Sukhumi_Babushara,20,AI.Skill.GOOD,202,"390th Fighter SQN")
--          
-- ### Add a tanker (optional)
--        
--        -- **Note** If you need different tanker types, i.e. Boom and Drogue, set them up at different AirWings!
--        -- Add a tanker point
--        mywing:AddPatrolPointTanker(AIRBASE.Caucasus.Kutaisi,ZONE:FindByName("Blue Zone Tanker"):GetCoordinate(),20000,280,270,50)
--        -- Add a tanker squad - Radio 251 AM, TACAN 51Y
--        mywing:AddTankerSquadron("Blue Tanker","Tanker Ops Kutaisi",AIRBASE.Caucasus.Kutaisi,20,AI.Skill.EXCELLENT,602,nil,251,radio.modulation.AM,51)
--        
-- ### Add an AWACS (optional)
--        
--        -- Add an AWACS point
--        mywing:AddPatrolPointAwacs(AIRBASE.Caucasus.Kutaisi,ZONE:FindByName("Blue Zone AWACS"):GetCoordinate(),25000,300,270,50)
--        -- Add an AWACS squad - Radio 251 AM, TACAN 51Y
--        mywing:AddAWACSSquadron("Blue AWACS","AWACS Ops Kutaisi",AIRBASE.Caucasus.Kutaisi,20,AI.Skill.AVERAGE,702,nil,271,radio.modulation.AM)        
--
-- # Fine-Tuning
--
-- ## Change Defaults
-- 
-- * @{#EASYA2G.SetDefaultResurrection}: Set how many seconds the AirWing stays inoperable after the AirWing STATIC HQ ist destroyed, default 900 secs. 
-- * @{#EASYA2G.SetDefaultA2GSpeed}: Set how many knots the A2G flights should do (will be altitude corrected), default 300 kn.
-- * @{#EASYA2G.SetDefaultA2GAlt}: Set at which altitude (ASL) the A2G planes will fly, default 25,000 ft.
-- * @{#EASYA2G.SetDefaultA2GDirection}: Set the initial direction from the A2G point the planes will fly in degrees, default is 90°.
-- * @{#EASYA2G.SetDefaultA2GLeg}: Set the length of the A2G leg, default is 15 NM.
-- * @{#EASYA2G.SetDefaultA2GGrouping}: Set how many planes will be spawned per mission (CVAP/GCI), defaults to 2.
-- * @{#EASYA2G.SetDefaultMissionRange}: Set how many NM the planes can go from the home base, defaults to 100.
-- * @{#EASYA2G.SetDefaultNumberAlert5Standby}: Set how many planes will be spawned on cold standby (Alert5), default 2.
-- * @{#EASYA2G.SetDefaultEngageRange}: Set max engage range for A2G flights if they detect intruders, defaults to 50.
-- * @{#EASYA2G.SetMaxAliveMissions}: Set max parallel missions can be done (A2G+GCI+Alert5+Tanker+AWACS), defaults to 8.
-- * @{#EASYA2G.SetDefaultRepeatOnFailure}: Set max repeats on failure for intercepting/killing intruders, defaults to 3.
-- * @{#EASYA2G.SetTankerAndScoutsInvisible}: Set Tanker and Scouts to be invisible to enemy AI eyes. Is set to `true` by default.
-- 
-- ## Debug and Monitor
-- 
--          mywing.debug = true -- log information
--          mywing.Monitor = true -- show some statistics on screen
--
--
-- @field #EASYA2G
EASYA2G = {
  ClassName = "EASYA2G",
  overhead = 0.75,
  capgrouping = 2,
  airbasename = nil,
  airbase = nil,
  coalition = "blue",
  alias = nil,
  wings = {},
  Intel = nil,
  resurrection = 900,
  capspeed = 300,
  capalt = 25000,
  capdir = 45,
  capleg = 15,
  maxinterceptsize = 2,
  missionrange = 100,
  noalert5 = 4,
  ManagedAW = {},
  ManagedSQ = {},
  ManagedCP = {},
  ManagedTK = {},
  ManagedEWR = {},
  ManagedREC = {},
  MaxAliveMissions = 8,
  debug = false,
  engagerange = 50,
  repeatsonfailure = 3,
  GoZoneSet = nil,
  NoGoZoneSet = nil,
  ConflictZoneSet = nil,
  Monitor = false,
  TankerInvisible = true,
  CapFormation = nil,
  ReadyFlightGroups = {},
  DespawnAfterLanding = false,
  DespawnAfterHolding = true,
  ListOfAuftrag = {},
  defaulttakeofftype = "hot",
  FuelLowThreshold = 25,
  FuelCriticalThreshold = 10,
  showpatrolpointmarks = false,
  EngageTargetTypes = {"Ground"},
}

--- Internal Squadron data type
-- @type EASYA2G.Squad
-- @field #string TemplateName
-- @field #string SquadName
-- @field #string AirbaseName
-- @field #number AirFrames
-- @field #string Skill
-- @field #string Modex
-- @field #string Livery
-- @field #boolean Tanker
-- @field #boolean AWACS
-- @field #boolean RECON
-- @field #number Frequency
-- @field #number Modulation
-- @field #number TACAN

--- Internal Wing data type
-- @type EASYA2G.Wing
-- @field #string AirbaseName
-- @field #string Alias
-- @field #string CapZoneName

--- Internal CapPoint data type
-- @type EASYA2G.CapPoint
-- @field #string AirbaseName
-- @field Core.Point#COORDINATE Coordinate
-- @field #number Altitude
-- @field #number Speed
-- @field #number Heading
-- @field #number LegLength
-- @field Core.Zone#ZONE_BASE Zone

--- EASYA2G class version.
-- @field #string version
EASYA2G.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: TBD

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new GCIA2G Manager
-- @param #EASYA2G self
-- @param #string Alias A Name for this A2G Setup
-- @param #string AirbaseName Name of the Home Airbase
-- @param #string Coalition Coalition, e.g. "blue" or "red"
-- @param #string ScoutName (Partial) group name of the detection system of the coalition, e.g. "Red SCOUT", can be handed in as table of names, e.g.{"SCOUT","DRONE","SAM"}
-- @return #EASYA2G self
function EASYA2G:New(Alias, AirbaseName, Coalition, ScoutName)
  -- Inherit everything from FSM class.
  
  local self=BASE:Inherit(self, EASYGCICAP:New(Alias, AirbaseName, Coalition, ScoutName)) -- #EASYA2G
  
  -- defaults
  self.alias = Alias or AirbaseName.." A2G Wing"
  self.coalitionname = string.lower(Coalition) or "blue"
  self.coalition = self.coalitionname == "blue" and coalition.side.BLUE or coalition.side.RED
  self.wings = {}
  if type(ScoutName) == "string" then EWRName = {EWRName} end
  self.EWRName = ScoutName --or self.coalitionname.." EWR"
  --self.CapZoneName = CapZoneName
  self.airbasename = AirbaseName
  self.airbase = AIRBASE:FindByName(self.airbasename)
  self.GoZoneSet = SET_ZONE:New()
  self.NoGoZoneSet = SET_ZONE:New()
  self.ConflictZoneSet = SET_ZONE:New()
  self.resurrection = 900
  self.capspeed = 225
  self.capalt = 15000
  self.capdir = 90
  self.capleg = 15
  self.capgrouping = 2
  self.missionrange = 100
  self.noalert5 = 2
  self.MaxAliveMissions = 8
  self.engagerange = 50
  self.repeatsonfailure = 3
  self.Monitor = false
  self.TankerInvisible = true
  self.CapFormation = ENUMS.Formation.FixedWing.FingerFour.Group
  self.DespawnAfterLanding = false
  self.DespawnAfterHolding = true
  self.ListOfAuftrag = {}
  self.defaulttakeofftype = "hot"
  self.FuelLowThreshold = 25
  self.FuelCriticalThreshold = 10
  self.showpatrolpointmarks = false
  self.EngageTargetTypes = {"Ground"}
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("EASYA2G %s | ", self.alias)

  -- Add FSM transitions.
  --               From State  -->   Event      -->      To State
  self:SetStartState("Stopped")
  self:AddTransition("Stopped", "Start",  "Running")
  self:AddTransition("Running", "Stop",   "Stopped")
  self:AddTransition("*",       "Status", "*")  
  
  self:AddAirwing(self.airbasename,self.alias,self.CapZoneName)
  
  self:I(self.lid.."Created new instance (v"..self.version..")")
  
  self:__Start(math.random(6,12))
  
  return self
end

-------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------

--- Set Tanker and Scouts to be invisible to enemy AI eyes
-- @param #EASYA2G self
-- @param #boolean Switch Set to true or false, by default this is set to true already
-- @return #EASYA2G self 
function EASYA2G:SetTankerAndScoutsInvisible(Switch)
  self:T(self.lid.."SetTankerAndScoutsInvisible")
  self.TankerInvisible = Switch
  return self
end

--- Set default A2G Speed in knots
-- @param #EASYA2G self
-- @param #number Speed Speed defaults to 300
-- @return #EASYA2G self
function EASYA2G:SetDefaultA2GSpeed(Speed)
  self:T(self.lid.."SetDefaultSpeed")
  self.capspeed = Speed or 300
  return self
end

--- Set A2G Flight formation.
-- @param #EASYA2G self
-- @param #number Formation Formation to fly, defaults to ENUMS.Formation.FixedWing.FingerFour.Group
-- @return #EASYA2G self
function EASYA2G:SetA2GFormation(Formation)
  self:T(self.lid.."SetA2GFormation")
  self.CapFormation = Formation
  return self
end

--- Set default A2G Altitude in feet
-- @param #EASYA2G self
-- @param #number Altitude Altitude defaults to 25000
-- @return #EASYA2G self
function EASYA2G:SetDefaultA2GAlt(Altitude)
  self:T(self.lid.."SetDefaultAltitude")
  self.capalt = Altitude or 25000
  return self
end

--- Set default A2G lieg initial direction in degrees
-- @param #EASYA2G self
-- @param #number Direction Direction defaults to 90 (East)
-- @return #EASYA2G self
function EASYA2G:SetDefaultA2GDirection(Direction)
  self:T(self.lid.."SetDefaultDirection")
  self.capdir = Direction or 90
  return self
end

--- Set default leg length in NM
-- @param #EASYA2G self
-- @param #number Leg Leg defaults to 15
-- @return #EASYA2G self
function EASYA2G:SetDefaultA2GLeg(Leg)
  self:T(self.lid.."SetDefaultLeg")
 self.capleg = Leg or 15
 return self
end

--- Set default grouping, i.e. how many airplanes per A2G point
-- @param #EASYA2G self
-- @param #number Grouping Grouping defaults to 2
-- @return #EASYA2G self
function EASYA2G:SetDefaultA2GGrouping(Grouping)
 self:T(self.lid.."SetDefaultA2GGrouping")
 self.capgrouping = Grouping or 2
 return self
end

--- Set A2G mission start to vary randomly between Start end End seconds.
-- @param #EASYA2G self
-- @param #number Start
-- @param #number End 
-- @return #EASYA2G self
function EASYA2G:SetA2GStartTimeVariation(Start, End)
  self.capOptionVaryStartTime = Start or 5
  self.capOptionVaryEndTime = End or 60
  return self
end

--- Set which target types A2G flights will prefer to engage, defaults to {"Ground"}
-- @param #EASYA2G self
-- @param #table types Table of comma separated #string entries, defaults to {"Ground"} (everything that is ground and is not a weapon). Useful other options are e.g. {"Armored vehicles"}, {"Tanks"}, 
-- or {"APC"} or combinations like {"APC", "Tanks", "Artillery"}. See [Hoggit Wiki](https://wiki.hoggitworld.com/view/DCS_enum_attributes).
-- @return #EASYA2G self
function EASYA2G:SetA2GEngageTargetTypes(types)
  self.EngageTargetTypes = types or {"Ground"}
  return self
end

--- Add a A2G patrol point to a Wing
-- @param #EASYA2G self
-- @param #string AirbaseName Name of the Wing's airbase
-- @param Core.Point#COORDINATE Coordinate. Can be handed as a Core.Zone#ZONE object (e.g. in case you want  the point to align with a moving zone).
-- @param #number Altitude Defaults to 25000 feet ASL.
-- @param #number Speed  Defaults to 300 knots TAS.
-- @param #number Heading Defaults to 90 degrees (East).
-- @param #number LegLength Defaults to 15 NM.
-- @return #EASYA2G self
function EASYA2G:AddPatrolPointA2G(AirbaseName,Coordinate,Altitude,Speed,Heading,LegLength)
  self:T(self.lid.."AddPatrolPointA2G")--..Coordinate:ToStringLLDDM())
  local coordinate = Coordinate
  local EntryCAP = {} -- #EASYGCICAP.CapPoint  
  if Coordinate:IsInstanceOf("ZONE_BASE") then
    -- adjust coordinate and get the coordinate from the zone
    coordinate = Coordinate:GetCoordinate()
    EntryCAP.Zone = Coordinate
  end
  EntryCAP.AirbaseName = AirbaseName
  EntryCAP.Coordinate = coordinate
  EntryCAP.Altitude = Altitude or 25000
  EntryCAP.Speed = Speed or 300
  EntryCAP.Heading = Heading or 90
  EntryCAP.LegLength = LegLength or 15
  self.ManagedCP[#self.ManagedCP+1] = EntryCAP
  if self.debug then
    local mark = MARKER:New(coordinate,self.lid.."Patrol Point"):ToAll()
  end
  return self
end

--- (Internal) Add a Squadron to an Airwing of the manager
-- @param #EASYA2G self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @param #number Frequency (optional) Radio Frequency to be used. 
-- @param #number Modulation (optional) Radio Modulation to be used, e.g. radio.modulation.AM or radio.modulation.FM
-- @return #EASYA2G self 
function EASYA2G:_AddSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation)
  self:T(self.lid.."_AddSquadron "..SquadName)
  -- Add Squadrons
  local Squadron_One = SQUADRON:New(TemplateName,AirFrames,SquadName)
  Squadron_One:AddMissionCapability({AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.ALERT5, AUFTRAG.Type.BOMBING, AUFTRAG.Type.STRIKE})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(10,20)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  
  local wing = self.wings[AirbaseName][1] -- Ops.Airwing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{{AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.ALERT5, AUFTRAG.Type.BOMBING, AUFTRAG.Type.STRIKE}},75)
  
  return self
end

--- (Internal) Try to assign the intercept to a FlightGroup already in air and ready.
-- @param #EASYA2G self
-- @param #table ReadyFlightGroups ReadyFlightGroups
-- @param Ops.Auftrag#AUFTRAG Auftrag The Auftrag
-- @param Wrapper.Group#GROUP Group The Target
-- @param #number WingSize Calculated number of Flights
-- @return #boolean assigned
-- @return #number leftover
function EASYA2G:_TryAssignMission(ReadyFlightGroups,Auftrag,Group,WingSize)
  self:T("_TryAssignMission for size "..WingSize or 1)
  local assigned = false
  local wingsize = WingSize or 1
  local mindist = 0
  local disttable = {}
  if Group and Group:IsAlive() then
    local gcoord = Group:GetCoordinate() or COORDINATE:New(0,0,0)
    self:T(self.lid..string.format("Assignment for %s",Group:GetName()))
    for _name,_FG in pairs(ReadyFlightGroups or {}) do
      local FG = _FG -- Ops.FlightGroup#FLIGHTGROUP
      local fcoord = FG:GetCoordinate()
      local dist = math.floor(UTILS.Round(fcoord:Get2DDistance(gcoord)/1000,1))
      self:T(self.lid..string.format("FG %s Distance %dkm",_name,dist))
      disttable[#disttable+1] = { FG=FG, dist=dist}
      if dist>mindist then mindist=dist end
    end
    
    local function sortDistance(a, b)
      return a.dist < b.dist
    end
    
    table.sort(disttable, sortDistance)
    
    for _,_entry in ipairs(disttable) do
      local FG = _entry.FG -- Ops.FlightGroup#FLIGHTGROUP
      FG:AddMission(Auftrag)
      local cm = FG:GetMissionCurrent()
      if cm then cm:Cancel() end
      wingsize = wingsize - 1
      self:T(self.lid..string.format("Assigned to FG %s Distance %dkm",FG:GetName(),_entry.dist))
      if wingsize == 0 then 
        assigned = true
        break 
      end
    end
  end
  
  return assigned, wingsize
end

--- Here, we'll decide if we need to launch an attacking flight, and from where
-- @param #EASYA2G self
-- @param Ops.Intel#INTEL.Cluster Cluster
-- @return #EASYA2G self 
function EASYA2G:_AssignMission(Cluster)
   -- Here, we'll decide if we need to launch an attacking flight, and from where
  local overhead = self.overhead
  local capspeed = self.capspeed + 100
  local capalt = self.capalt
  local maxsize = self.maxinterceptsize
  local repeatsonfailure = self.repeatsonfailure
  
  local wings = self.wings
  local ctlpts = self.ManagedCP
  local MaxAliveMissions = self.MaxAliveMissions --* self.capgrouping
  local nogozoneset = self.NoGoZoneSet
  local conflictzoneset = self.ConflictZoneSet
  local ReadyFlightGroups = self.ReadyFlightGroups
  
  -- Aircraft?
  if Cluster.ctype ~= INTEL.Ctype.AIRCRAFT then return end
  -- Threatlevel 0..10
  local contact = self.Intel:GetHighestThreatContact(Cluster)
  local name = contact.groupname --#string
  local threat = contact.threatlevel --#number
  local position = self.Intel:CalcClusterFuturePosition(Cluster,300)
  -- calculate closest zone
  local bestdistance = 2000*1000 -- 2000km
  local targetairwing = nil -- Ops.Airwing#AIRWING
  local targetawname = "" -- #string
  local clustersize = self.Intel:ClusterCountUnits(Cluster) or 1
  local wingsize = math.abs(overhead * (clustersize+1))
  if wingsize > maxsize then wingsize = maxsize end
  -- existing mission, and if so - done?
  local retrymission = true
  if Cluster.mission and (not Cluster.mission:IsOver()) then 
    retrymission = false
  end
  if (retrymission) and (wingsize >= 1) then
   MESSAGE:New(string.format("**** %s Interceptors need wingsize %d", UTILS.GetCoalitionName(self.coalition), wingsize),15,"CAPGCI"):ToAllIf(self.debug):ToLog()
    for _,_data in pairs (wings) do
      local airwing = _data[1] -- Ops.Airwing#AIRWING
      local zone = _data[2] -- Core.Zone#ZONE
      local zonecoord = zone:GetCoordinate()
      local name = _data[3] -- #string
      local coa = AIRBASE:FindByName(name):GetCoalition()
      local distance = position:DistanceFromPointVec2(zonecoord)
      local airframes = airwing:CountAssets(true)
      local samecoalitionab = coa == self.coalition and true or false
      if distance < bestdistance and airframes >= wingsize and samecoalitionab == true then
        bestdistance = distance
        targetairwing = airwing
        targetawname = name
      end
    end
    for _,_data in pairs (ctlpts) do
      --local airwing = _data[1] -- Ops.Airwing#AIRWING
      --local zone = _data[2] -- Core.Zone#ZONE
      --local zonecoord = zone:GetCoordinate()
      --local name = _data[3] -- #string
      
      local data = _data -- #EASYGCICAP.CapPoint
      local name = data.AirbaseName
      local zonecoord = data.Coordinate
      if data.Zone then
            -- refresh coordinate in case we have a (moving) zone
            zonecoord = data.Zone:GetCoordinate()
      end
      local airwing = wings[name][1]
      local coa = AIRBASE:FindByName(name):GetCoalition()
      local samecoalitionab = coa == self.coalition and true or false
      local distance = position:DistanceFromPointVec2(zonecoord)
      local airframes = airwing:CountAssets(true)
      if distance < bestdistance and airframes >= wingsize and samecoalitionab == true then
        bestdistance = distance
        targetairwing = airwing -- Ops.Airwing#AIRWING
        targetawname = name
      end
    end
    local text = string.format("Closest Airwing is %s", targetawname)
    local m = MESSAGE:New(text,10,"EasyA2G"):ToAllIf(self.debug):ToLog()
    -- Do we have a matching airwing?
    if targetairwing then
      local AssetCount = targetairwing:CountAssetsOnMission(MissionTypes,Cohort)
      local missioncount = self:_CountAliveAuftrags()
      -- Enough airframes on mission already?
      self:T(self.lid.." Assets on Mission "..AssetCount)
      if missioncount < MaxAliveMissions then
        local repeats = repeatsonfailure
        local InterceptAuftrag = AUFTRAG:NewBAI(contact.group,capalt)
          :SetMissionRange(150)
          :SetPriority(1,true,1)
          --:SetRequiredAssets(wingsize)
          :SetRepeatOnFailure(repeats)
          :SetMissionSpeed(UTILS.KnotsToAltKIAS(capspeed,capalt))
          :SetMissionAltitude(capalt)
          
          if nogozoneset:Count() > 0 then
            InterceptAuftrag:AddConditionSuccess(
              function(group,zoneset,conflictset)
                local success = false
                if group and group:IsAlive() then
                  local coord = group:GetCoordinate()
                  if coord and zoneset:Count() > 0 and zoneset:IsCoordinateInZone(coord) then
                    success = true
                  end
                  if coord and conflictset:Count() > 0 and conflictset:IsCoordinateInZone(coord) then
                    success = false
                  end
                else
                  success = true -- target dead
                end
                return success
              end,
              contact.group,
              nogozoneset,
              conflictzoneset
            )
          end
          
        table.insert(self.ListOfAuftrag,InterceptAuftrag)
        local assigned, rest = self:_TryAssignMission(ReadyFlightGroups,InterceptAuftrag,contact.group,wingsize)
        if not assigned  then
          InterceptAuftrag:SetRequiredAssets(rest)
          targetairwing:AddMission(InterceptAuftrag)
        end
        Cluster.mission = InterceptAuftrag
      end
    else
      MESSAGE:New("**** Not enough airframes available or max mission limit reached!",15,"EasyA2G"):ToAllIf(self.debug):ToLog()
    end
   end
end

--- (Internal) Start detection.
-- @param #EASYA2G self
-- @return #EASYA2G self
function EASYA2G:_StartIntel()
  self:T(self.lid.."_StartIntel")
  -- Border GCI Detection
  local BlueAir_DetectionSetGroup = SET_GROUP:New()
  BlueAir_DetectionSetGroup:FilterPrefixes( self.EWRName )
  BlueAir_DetectionSetGroup:FilterStart()
  
  -- Intel type detection
  local BlueIntel = INTEL:New(BlueAir_DetectionSetGroup,self.coalitionname, self.alias)
  BlueIntel:SetClusterAnalysis(true,false,false)
  BlueIntel:SetForgetTime(300)
  BlueIntel:SetAcceptZones(self.GoZoneSet)
  BlueIntel:SetRejectZones(self.NoGoZoneSet)
  BlueIntel:SetConflictZones(self.ConflictZoneSet)
  BlueIntel:SetVerbosity(0)
  BlueIntel:Start()
  
  if self.debug then 
    BlueIntel.debug = true
  end
  
  local function AssignCluster(Cluster)
    self:_AssignMission(Cluster)
  end
  
  function BlueIntel:onbeforeNewCluster(From,Event,To,Cluster)
    AssignCluster(Cluster)
  end
  
  self.Intel = BlueIntel  
  return self
end


