-------------------------------------------------------------------------
-- Easy CAP/GCI Class, based on OPS classes
-------------------------------------------------------------------------
-- Documentation
-- 
-- https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.EasyGCICAP.html
-- 
-------------------------------------------------------------------------
-- Date: September 2023
-------------------------------------------------------------------------
---@diagnostic disable: cast-local-type
--- **Ops** - Easy GCI & CAP Manager
--
-- ===
--
-- **Main Features:**
--
--    * Automatically create and manage A2A CAP/GCI defenses using an @{Ops.AirWing#AIRWING} and Squadrons for one coalition
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
-- @module Ops.EasyGCICAP
-- @image AI_Combat_Air_Patrol.JPG


--- EASYGCICAP Class
-- @type EASYGCICAP
-- @field #string ClassName
-- @field #number overhead
-- @field #number engagerange
-- @field #number capgrouping
-- @field #string airbasename
-- @field Wrapper.Airbase#AIRBASE airbase
-- @field #number coalition
-- @field #string alias
-- @field #table wings
-- @field Ops.Intelligence#INTEL Intel
-- @field #number resurrection
-- @field #number capspeed
-- @field #number capalt
-- @field #number capdir
-- @field #number capleg
-- @field #number capgrouping
-- @field #number maxinterceptsize
-- @field #number missionrange
-- @field #number noaltert5
-- @field #table ManagedAW
-- @field #table ManagedSQ
-- @field #table ManagedCP
-- @field #table ManagedTK
-- @field #number MaxAliveMissions
-- @field #boolean debug
-- @extends Core.Fsm#FSM

--- *“Airspeed, altitude, and brains. Two are always needed to successfully complete the flight.”* -- Unknown.
--
-- ===
--
-- # The EasyGCICAP Concept
-- 
-- The idea of this class is partially to make the OPS classes easier operational for an A2A CAP/GCI defense network, and to replace the legacy AI_A2A_Dispatcher system - not to it's
-- full extent, but make a basic system work very quickly.
--
-- # Setup
-- 
-- ## Basic understanding
-- 
-- The basics are, there is **one** and only **one** AirWing per airbase. Each AirWing has **at least** one Squadron, who will do both CAP and GCI tasks. Squadrons will be randomly chosen for the task at hand.
-- Each AirWing has **at least** one CAP Point that it manages. CAP Points will be covered by the AirWing automatically as long as airframes are available. Detected intruders will be assigned to **one**
-- AirWing based on proximity (that is, if you have more than one). 
-- 
-- ## Assignment of tasks for intruders
-- 
-- Either a CAP Plane or a newly spawned GCI plane will take care of the intruders. Standard overhead is 0.75, i.e. a group of 3 intrudes will
-- be managed by 2 planes from the assigned AirWing. There is an maximum missions limitation per AirWing, so we do not spam the skies.
-- 
-- ## Basic set-up code
-- 
-- ### Prerequisites
-- 
-- You have to put a STATIC object on the airbase with the UNIT name according to the name of the airbase. E.g. for Kuitaisi this has to have the name Kutaisi. This object symbolizes the AirWing HQ.
-- Next put a late activated template group for your CAP/GCI Squadron on the map. Last, put a zone on the map for the CAP operations, let's name it "Blue Zone 1". Size of the zone plays no role.
-- Put an EW radar system on the map and name it aptly, like "Blue EWR".
-- 
-- ### Code it
-- 
--          -- Set up a basic system for the blue side, we'll reside on Kutaisi, and use GROUP objects with "Blue EWR" in the name as EW Radar Systems.
--          local mywing = EASYGCICAP:New("Blue CAP Operations",AIRBASE.Caucasus.Kutaisi,"blue","Blue EWR")
--          
--          -- Add a CAP patrol point belonging to our airbase, we'll be at 30k ft doing 400 kn, initial direction 90 degrees (East), leg 20NM
--          mywing:AddPatrolPointCAP(AIRBASE.Caucasus.Kutaisi,ZONE:FindByName("Blue Zone 1"):GetCoordinate(),30000,400,90,20)
--          
--          -- Add a Squadron with template "Blue Sq1 M2000c", 20 airframes, skill good, Modex starting with 102 and skin "Vendee Jeanne"
--          mywing:AddSquadron("Blue Sq1 M2000c","CAP Kutaisi",AIRBASE.Caucasus.Kutaisi,20,AI.Skill.GOOD,102,"ec1.5_Vendee_Jeanne_clean")
--          
--          -- Add a couple of zones
--          -- We'll defend our border
--          mywing:AddAcceptZone(ZONE_POLYGON:New( "Blue Border", GROUP:FindByName( "Blue Border" ) ))
--          -- We'll attack intruders also here
--          mywing:AddAcceptZone(ZONE_POLYGON:New("Red Defense Zone", GROUP:FindByName( "Red Defense Zone" )))
--          -- We'll leave the reds alone on their turf
--          mywing:AddRejectZone(ZONE_POLYGON:New( "Red Border", GROUP:FindByName( "Red Border" ) ))
--          
--          -- Optional - Draw the borders on the map so we see what's going on
--          -- Set up borders on map
--          local BlueBorder = ZONE_POLYGON:New( "Blue Border", GROUP:FindByName( "Blue Border" ) )
--          BlueBorder:DrawZone(-1,{0,0,1},1,FillColor,FillAlpha,1,true)
--          local BlueNoGoZone = ZONE_POLYGON:New("Red Defense Zone", GROUP:FindByName( "Red Defense Zone" ))
--          BlueNoGoZone:DrawZone(-1,{1,1,0},1,FillColor,FillAlpha,2,true)
--          local BlueNoGoZone2 = ZONE_POLYGON:New( "Red Border", GROUP:FindByName( "Red Border" ) )
--          BlueNoGoZone2:DrawZone(-1,{1,0,0},1,FillColor,FillAlpha,4,true)
--          
-- ### Add a second airwing with squads and own CAP point (optional)
--          
--          -- Set this up at Sukhumi
--          mywing:AddAirwing(AIRBASE.Caucasus.Sukhumi_Babushara,"Blue CAP Sukhumi")
--          -- CAP Point "Blue Zone 2"
--          mywing:AddPatrolPointCAP(AIRBASE.Caucasus.Sukhumi_Babushara,ZONE:FindByName("Blue Zone 2"):GetCoordinate(),30000,400,90,20)
--          
--          -- This one has two squadrons to choose from
--          mywing:AddSquadron("Blue Sq3 F16","CAP Sukhumi II",AIRBASE.Caucasus.Sukhumi_Babushara,20,AI.Skill.GOOD,402,"JASDF 6th TFS 43-8526 Skull Riders")
--          mywing:AddSquadron("Blue Sq2 F15","CAP Sukhumi I",AIRBASE.Caucasus.Sukhumi_Babushara,20,AI.Skill.GOOD,202,"390th Fighter SQN")
--          
-- ### Add a tanker (optional)
--        
--        -- **Note** If you need different tanker types, i.e. Boom and Drogue, set them up at different AirWings!
--        -- Add a tanker point
--        mywing:AddPatrolPointTanker(AIRBASE.Caucasus.Kutaisi,ZONE:FindByName("Blue Zone Tanker"):GetCoordinate(),20000,280,270,50)
--        -- Add a tanker squad
--        mywing:AddTankerSquadron("Blue Tanker","Tanker Ops Kutaisi",AIRBASE.Caucasus.Kutaisi,20,AI.Skill.EXCELLENT,602)
--
-- # Fine-Tuning
--
-- ## Change Defaults
-- 
-- * @{#EASYGCICAP.SetDefaultResurrection}: Set how many seconds the AirWing stays inoperable after the AirWing STATIC HQ ist destroyed, default 900 secs. 
-- * @{#EASYGCICAP.SetDefaultCAPSpeed}: Set how many knots the CAP flights should do (will be altitude corrected), default 300 kn.
-- * @{#EASYGCICAP.SetDefaultCAPAlt}: Set at which altitude (ASL) the CAP planes will fly, default 25,000 ft.
-- * @{#EASYGCICAP.SetDefaultCAPDirection}: Set the initial direction from the CAP point the planes will fly in degrees, default is 90°.
-- * @{#EASYGCICAP.SetDefaultCAPLeg}: Set the length of the CAP leg, default is 15 NM.
-- * @{#EASYGCICAP.SetDefaultCAPGrouping}: Set how many planes will be spawned per mission (CVAP/GCI), defaults to 2.
-- * @{#EASYGCICAP.SetDefaultMissionRange}: Set how many NM the planes can go from the home base, defaults to 100.
-- * @{#EASYGCICAP.SetDefaultNumberAlter5Standby}: Set how many planes will be spawned on cold standby (Alert5), default 2.
-- * @{#EASYGCICAP.SetDefaultEngageRange}: Set max engage range for CAP flights if they detect intruders, defaults to 50.
-- * @{#EASYGCICAP.SetMaxAliveMissions}: Set max parallel missions can be done (CAP+GCI+Alert5+Tanker), defaults to 6.
--
--
-- @field #EASYGCICAP
EASYGCICAP = {
  ClassName = "EASYGCICAP",
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
  capgrouping = 2,
  maxinterceptsize = 2,
  missionrange = 100,
  noaltert5 = 4,
  ManagedAW = {},
  ManagedSQ = {},
  ManagedCP = {},
  ManagedTK = {},
  MaxAliveMissions = 6,
  debug = true,
  engagerange = 50,
}

--- Internal Squadron data type
-- @type EASYGCICAP.Squad
-- @field #string TemplateName
-- @field #string SquadName
-- @field #string AirbaseName
-- @field #number AirFrames
-- @field #string Skill
-- @field #string Modex
-- @field #string Livery
-- @field #boolean Tanker

--- Internal Wing data type
-- @type EASYGCICAP.Wing
-- @field #string AirbaseName
-- @field #string Alias
-- @field #string CapZoneName

--- Internal CapPoint data type
-- @type EASYGCICAP.CapPoint
-- @field #string AirbaseName
-- @field Core.Point#COORDINATE Coordinate
-- @field #number Altitude
-- @field #number Speed
-- @field #number Heading
-- @field #number LegLength

--- EASYGCICAP class version.
-- @field #string version
EASYGCICAP.version="0.0.4"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: TBD

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new GCICAP Manager
-- @param #EASYGCICAP self
-- @param #string Alias
-- @param #string AirbaseName
-- @param #string Coalition
-- @param #string EWRName
-- @return #EASYGCICAP self
function EASYGCICAP:New(Alias, AirbaseName, Coalition, EWRName)
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #EASYGCICAP
  
  -- defaults
  self.alias = Alias or AirbaseName.." CAP Wing"
  self.coalitionname = string.lower(Coalition) or "blue"
  self.coalition = self.coaltitionname == "blue" and coalition.side.BLUE or coalition.side.RED
  self.wings = {}
  self.EWRName = EWRName or self.coalitionname.." EWR"
  --self.CapZoneName = CapZoneName
  self.airbasename = AirbaseName
  self.airbase = AIRBASE:FindByName(self.airbasename)
  self.BlueGoZoneSet = SET_ZONE:New()
  self.BlueNoGoZoneSet = SET_ZONE:New()
  self.resurrection = 900
  self.capspeed = 300
  self.capalt = 25000
  self.capdir = 90
  self.capleg = 15
  self.capgrouping = 2
  self.missionrange = 100
  self.noaltert5 = 2
  self.MaxAliveMissions = 6
  self.engagerange = 50
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("EASYGCICAP %s | ", self.alias)

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


--- Set Maximum of alive missions to stop airplanes spamming the map
-- @param #EASYGCICAP self
-- @param #number Maxiumum Maxmimum number of parallel missions allowed. Count is Cap-Missions + Intercept-Missions + Alert5-Missionsm default is 6
-- @return #EASYGCICAP self 
function EASYGCICAP:SetMaxAliveMissions(Maxiumum)
  self:I(self.lid.."SetDefaultResurrection")
  self.MaxAliveMissions = Maxiumum or 6
  return self
end

--- Add default time to resurrect Airwing building if destroyed
-- @param #EASYGCICAP self
-- @param #number Seconds Seconds, defaults to 900
-- @return #EASYGCICAP self 
function EASYGCICAP:SetDefaultResurrection(Seconds)
  self:I(self.lid.."SetDefaultResurrection")
  self.resurrection = Seconds or 900
  return self
end

--- Set default CAP Speed in knots
-- @param #EASYGCICAP self
-- @param #number Speed Speed defaults to 300
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultCAPSpeed(Speed)
  self:I(self.lid.."SetDefaultSpeed")
  self.capspeed = Speed or 300
  return self
end

--- Set default CAP Altitude in feet
-- @param #EASYGCICAP self
-- @param #number Altitude Altitude defaults to 25000
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultCAPAlt(Altitude)
  self:I(self.lid.."SetDefaultAltitude")
  self.capalt = Altitude or 25000
  return self
end

--- Set default CAP lieg initial direction in degrees
-- @param #EASYGCICAP self
-- @param #number Direction Direction defaults to 90 (East)
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultCAPDirection(Direction)
  self:I(self.lid.."SetDefaultDirection")
  self.capdir = Direction or 90
  return self
end

--- Set default leg length in NM
-- @param #EASYGCICAP self
-- @param #number Leg Leg defaults to 15
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultCAPLeg(Leg)
  self:I(self.lid.."SetDefaultLeg")
 self.capleg = Leg or 15
 return self
end

--- Set default grouping, i.e. how many airplanes per CAP point
-- @param #EASYGCICAP self
-- @param #number Grouping Grouping defaults to 2
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultCAPGrouping(Grouping)
 self:I(self.lid.."SetDefaultCAPGrouping")
 self.capgrouping = Grouping or 2
 return self
end

--- Set default range planes can fly from their homebase in NM
-- @param #EASYGCICAP self
-- @param #number Range Range defaults to 100 NM
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultMissionRange(Range)
  self:I(self.lid.."SetDefaultMissionRange")
  self.missionrange = Range or 100
  return self
end

--- Set default number of airframes standing by for intercept tasks (visible on the airfield)
-- @param #EASYGCICAP self
-- @param #number Airframes defaults to 2
-- @return #EASYGCICAP selfAirframes
function EASYGCICAP:SetDefaultNumberAlter5Standby(Airframes)
  self:I(self.lid.."SetDefaultNumberAlter5Standby")
  self.noaltert5 = math.abs(Airframes) or 2
  return self
end

--- Set default engage range for intruders detected by CAP flights in NM.
-- @param #EASYGCICAP self
-- @param #number Range defaults to 50NM
-- @return #EASYGCICAP selfAirframes
function EASYGCICAP:SetDefaultEngageRange(Range)
  self:I(self.lid.."SetDefaultNumberAlter5Standby")
  self.engagerange = Range or 50
  return self
end

--- Add an AirWing to the manager
-- @param #EASYGCICAP self
-- @param #string Airbasename
-- @param #string Alias
-- @return #EASYGCICAP self 
function EASYGCICAP:AddAirwing(Airbasename, Alias)
  self:I(self.lid.."AddAirwing "..Airbasename)
  
  -- Create Airwing data entry
  local AWEntry = {} -- #EASYGCICAP.Wing
  AWEntry.AirbaseName = Airbasename
  AWEntry.Alias = Alias
  --AWEntry.CapZoneName = CapZoneName
  
  self.ManagedAW[Airbasename] = AWEntry
  
  return self  
end

--- (Internal) Create actual AirWings from the list
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self 
function EASYGCICAP:_CreateAirwings()
  self:I(self.lid.."_CreateAirwings")
  for airbase,data in pairs(self.ManagedAW) do
    local wing = data -- #EASYGCICAP.Wing
    local afb = wing.AirbaseName
    local alias = wing.Alias
    --local cz = wing.CapZoneName
    self:_AddAirwing(airbase,alias)
  end
  return self
end

--- (internal) Create and add another AirWing to the manager
-- @param #EASYGCICAP self
-- @param #string Airbasename
-- @param #string Alias
-- @return #EASYGCICAP self 
function EASYGCICAP:_AddAirwing(Airbasename, Alias)
  self:I(self.lid.."_AddAirwing "..Airbasename)
  
  -- Create Airwing
  local CAP_Wing = AIRWING:New(Airbasename,Alias)
  CAP_Wing:SetReportOff()
  CAP_Wing:SetMarker(false)
  CAP_Wing:SetAirbase(AIRBASE:FindByName(Airbasename))
  CAP_Wing:SetRespawnAfterDestroyed()
  CAP_Wing:SetNumberCAP(self.capgrouping)
  CAP_Wing:SetNumberTankerBoom(1)
  CAP_Wing:SetNumberTankerProbe(1)
  --local PatrolCoordinateKutaisi = ZONE:New(CapZoneName):GetCoordinate()
  --CAP_Wing:AddPatrolPointCAP(PatrolCoordinateKutaisi,self.capalt,UTILS.KnotsToAltKIAS(self.capspeed,self.capalt),self.capdir,self.capleg)
  CAP_Wing:SetTakeoffHot()
  CAP_Wing:SetLowFuelThreshold(0.3)
  CAP_Wing.RandomAssetScore = math.random(50,100)
  CAP_Wing:Start()

  local Intel = self.Intel
  
  function CAP_Wing:OnAfterFlightOnMission(From, Event, To, Flightgroup, Mission)
    local flightgroup = Flightgroup -- Ops.FlightGroup#FLIGHTGROUP
    --flightgroup:SetDespawnAfterLanding()
    flightgroup:SetDespawnAfterHolding()
    flightgroup:SetDestinationbase(AIRBASE:FindByName(Airbasename))
    flightgroup:GetGroup():CommandEPLRS(true,5)
    flightgroup:SetEngageDetectedOn(self.engagerange,{"Air"},self.BlueGoZoneSet,self.BlueNoGoZoneSet)
    flightgroup:GetGroup():OptionROTEvadeFire()
    flightgroup:SetOutOfAAMRTB()
    flightgroup:SetFuelLowRTB(true)
    Intel:AddAgent(flightgroup)
    --function flightgroup:OnAfterHolding(From,Event,To)
      --self:ClearToLand(5)
    --end 
    
  end
  
  if self.noaltert5 > 0 then  
    local alert = AUFTRAG:NewALERT5(AUFTRAG.Type.INTERCEPT) 
    alert:SetRequiredAssets(self.noaltert5)
    alert:SetRepeat(99) 
    CAP_Wing:AddMission(alert)
  end
    
  self.wings[Airbasename] = { CAP_Wing, AIRBASE:FindByName(Airbasename):GetZone(), Airbasename }
  
  return self 
end

--- Add a CAP patrol point to a Wing
-- @param #EASYGCICAP self
-- @param #string AirbaseName Name of the Wing's airbase
-- @param Core.Point#COORDINATE Coordinate.
-- @param #number Altitude Defaults to 25000 feet.
-- @param #number Speed  Defaults to 300 knots.
-- @param #number Heading Defaults to 90 degrees (East).
-- @param #number LegLength Defaults to 15 NM.
-- @return #EASYGCICAP self
function EASYGCICAP:AddPatrolPointCAP(AirbaseName,Coordinate,Altitude,Speed,Heading,LegLength)
  self:I(self.lid.."AddPatrolPointCAP "..Coordinate:ToStringLLDDM())
  local EntryCAP = {} -- #EASYGCICAP.CapPoint
  EntryCAP.AirbaseName = AirbaseName
  EntryCAP.Coordinate = Coordinate
  EntryCAP.Altitude = Altitude or 25000
  EntryCAP.Speed = Speed or 300
  EntryCAP.Heading = Heading or 90
  EntryCAP.LegLength = LegLength or 15
  self.ManagedCP[#self.ManagedCP+1] = EntryCAP
  if self.debug then
    local mark = MARKER:New(Coordinate,self.lid.."Patrol Point"):ToAll()
  end
  return self
end

--- Add a TANKER patrol point to a Wing
-- @param #EASYGCICAP self
-- @param #string AirbaseName Name of the Wing's airbase
-- @param Core.Point#COORDINATE Coordinate.
-- @param #number Altitude Defaults to 25000 feet.
-- @param #number Speed  Defaults to 300 knots.
-- @param #number Heading Defaults to 90 degrees (East).
-- @param #number LegLength Defaults to 15 NM.
-- @return #EASYGCICAP self
function EASYGCICAP:AddPatrolPointTanker(AirbaseName,Coordinate,Altitude,Speed,Heading,LegLength)
  self:I(self.lid.."AddPatrolPointTanker "..Coordinate:ToStringLLDDM())
  local EntryCAP = {} -- #EASYGCICAP.CapPoint
  EntryCAP.AirbaseName = AirbaseName
  EntryCAP.Coordinate = Coordinate
  EntryCAP.Altitude = Altitude or 25000
  EntryCAP.Speed = Speed or 300
  EntryCAP.Heading = Heading or 90
  EntryCAP.LegLength = LegLength or 15
  self.ManagedTK[#self.ManagedTK+1] = EntryCAP
  if self.debug then
    local mark = MARKER:New(Coordinate,self.lid.."Patrol Point Tanker"):ToAll()
  end
  return self
end

--- (Internal) Set actual Tanker Points from the list
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self 
function EASYGCICAP:_SetTankerPatrolPoints()
  self:I(self.lid.."_SetTankerPatrolPoints")
  for _,_data in pairs(self.ManagedTK) do
    local data = _data --#EASYGCICAP.CapPoint
    local Wing = self.wings[data.AirbaseName][1] -- Ops.AirWing#AIRWING
    local Coordinate = data.Coordinate
    local Altitude = data.Altitude
    local Speed = data.Speed 
    local Heading = data.Heading
    local LegLength = data.LegLength
    Wing:AddPatrolPointTANKER(Coordinate,Altitude,Speed,Heading,LegLength)
  end
  
  return self
end

--- (Internal) Set actual PatrolPoints from the list
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self 
function EASYGCICAP:_SetCAPPatrolPoints()
  self:I(self.lid.."_SetCAPPatrolPoints")
  for _,_data in pairs(self.ManagedCP) do
    local data = _data --#EASYGCICAP.CapPoint
    local Wing = self.wings[data.AirbaseName][1] -- Ops.AirWing#AIRWING
    local Coordinate = data.Coordinate
    local Altitude = data.Altitude
    local Speed = data.Speed 
    local Heading = data.Heading
    local LegLength = data.LegLength
    Wing:AddPatrolPointCAP(Coordinate,Altitude,Speed,Heading,LegLength)
  end
  
  return self
end

--- (Internal) Add a CAP patrol point to a Wing
-- @param #EASYGCICAP self
-- @param #string AirbaseName Name of the Wing's airbase
-- @param Core.Point#COORDINATE Coordinate.
-- @param #number Altitude Defaults to 25000 feet.
-- @param #number Speed  Defaults to 300 knots.
-- @param #number Heading Defaults to 90 degrees (East).
-- @param #number LegLength Defaults to 15 NM.
-- @return #EASYGCICAP self
function EASYGCICAP:_AddPatrolPointCAP(AirbaseName,Coordinate,Altitude,Speed,Heading,LegLength)
  self:I(self.lid.."_AddPatrolPointCAP")
  local airbasename = AirbaseName or self.airbasename
  local coordinate = Coordinate
  local Altitude = Altitude or 25000
  local Speed = Speed or 300
  local Heading = Heading or 90
  local LegLength = LegLength or 15
  local wing = self.wings[airbasename][1] -- Ops.AirWing#AIRWING
  wing:AddPatrolPointCAP(coordinate,Altitude,Speed,Heading,LegLength)
  return self
end

--- (Internal) Create actual Squadrons from the list
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self 
function EASYGCICAP:_CreateSquads()
  self:I(self.lid.."_CreateSquads")
  for name,data in pairs(self.ManagedSQ) do
    local squad = data -- #EASYGCICAP.Squad
    local SquadName = name
    local TemplateName = squad.TemplateName
    local AirbaseName = squad.AirbaseName
    local AirFrames = squad.AirFrames
    local Skill = squad.Skill
    local Modex = squad.Modex
    local Livery = squad.Livery
    if squad.Tanker then
      self:_AddTankerSquadron(TemplateName,SquadName,AirbaseName,AirFrames,Skill,Modex,Livery)
    else
      self:_AddSquadron(TemplateName,SquadName,AirbaseName,AirFrames,Skill,Modex,Livery)
    end
  end
  return self
end

--- Add a Squadron to an Airwing of the manager
-- @param #EASYGCICAP self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYGCICAP self 
function EASYGCICAP:AddSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:I(self.lid.."AddSquadron "..SquadName)
  -- Add Squadron Data
  local EntrySQ = {} -- #EASYGCICAP.Squad
  EntrySQ.TemplateName = TemplateName
  EntrySQ.SquadName = SquadName
  EntrySQ.AirbaseName = AirbaseName
  EntrySQ.AirFrames = AirFrames or 20
  EntrySQ.Skill = Skill or AI.Skill.AVERAGE
  EntrySQ.Modex = Modex or 402
  EntrySQ.Livery = Livery
  
  self.ManagedSQ[SquadName] = EntrySQ
  
  return self
end

--- Add a Tanker Squadron to an Airwing of the manager
-- @param #EASYGCICAP self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYGCICAP self 
function EASYGCICAP:AddTankerSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:I(self.lid.."AddTankerSquadron "..SquadName)
  -- Add Squadron Data
  local EntrySQ = {} -- #EASYGCICAP.Squad
  EntrySQ.TemplateName = TemplateName
  EntrySQ.SquadName = SquadName
  EntrySQ.AirbaseName = AirbaseName
  EntrySQ.AirFrames = AirFrames or 20
  EntrySQ.Skill = Skill or AI.Skill.AVERAGE
  EntrySQ.Modex = Modex or 402
  EntrySQ.Livery = Livery
  EntrySQ.Tanker = true
  
  self.ManagedSQ[SquadName] = EntrySQ
  
  return self
end

--- (Internal) Add a Squadron to an Airwing of the manager
-- @param #EASYGCICAP self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYGCICAP self 
function EASYGCICAP:_AddSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:I(self.lid.."_AddSquadron "..SquadName)
  -- Add Squadrons
  local Squadron_One = SQUADRON:New(TemplateName,AirFrames,SquadName)
  Squadron_One:AddMissionCapability({AUFTRAG.Type.CAP, AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ALERT5})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(10,20)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  
  local wing = self.wings[AirbaseName][1] -- Ops.AirWing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.CAP, AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ALERT5},75)
  
  return self
end

--- (Internal) Add a Tanker Squadron to an Airwing of the manager
-- @param #EASYGCICAP self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYGCICAP self 
function EASYGCICAP:_AddTankerSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:I(self.lid.."_AddTankerSquadron "..SquadName)
  -- Add Squadrons
  local Squadron_One = SQUADRON:New(TemplateName,AirFrames,SquadName)
  Squadron_One:AddMissionCapability({AUFTRAG.Type.TANKER})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(10,20)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  
  local wing = self.wings[AirbaseName][1] -- Ops.AirWing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.TANKER},75)
  
  return self
end

--- Add a zone to the accepted zones set.
-- @param #EASYGCICAP self
-- @param Core.Zone#ZONE_BASE Zone
-- @return #EASYGCICAP self 
function EASYGCICAP:AddAcceptZone(Zone)
  self:I(self.lid.."AddAcceptZone0")
  self.BlueGoZoneSet:AddZone(Zone)
  return self
end

--- Add a zone to the rejected zones set.
-- @param #EASYGCICAP self
-- @param Core.Zone#ZONE_BASE Zone
-- @return #EASYGCICAP self 
function EASYGCICAP:AddRejectZone(Zone)
  self:I(self.lid.."AddRejectZone")
  self.BlueNoGoZoneSet:AddZone(Zone)
  return self
end

--- (Internal) Start detection.
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self
function EASYGCICAP:_StartIntel()
  self:I(self.lid.."_StartIntel")
  -- Border GCI Detection
  local BlueAir_DetectionSetGroup = SET_GROUP:New()
  BlueAir_DetectionSetGroup:FilterPrefixes( { self.EWRName } )
  BlueAir_DetectionSetGroup:FilterStart()
  
  -- Intel type detection
  local BlueIntel = INTEL:New(BlueAir_DetectionSetGroup,self.coalitionname, self.EWRName)
  BlueIntel:SetClusterAnalysis(true,false,false)
  BlueIntel:SetForgetTime(300)
  BlueIntel:SetAcceptZones(self.BlueGoZoneSet)
  BlueIntel:SetRejectZones(self.BlueNoGoZoneSet)
  BlueIntel:SetVerbosity(0)
  BlueIntel:Start()
  
  if self.debug then 
    BlueIntel.debug = true
  end
  
  -- Here, we'll decide if we need to launch an intercepting flight, and from where
  
  local overhead = self.overhead
  local capspeed = self.capspeed + 100
  local capalt = self.capalt
  local maxsize = self.maxinterceptsize
  
  local wings = self.wings
  local ctlpts = self.ManagedCP
  local MaxAliveMissions = self.MaxAliveMissions * self.capgrouping
  
  function BlueIntel:OnAfterNewCluster(From,Event,To,Cluster)
    -- Aircraft?
    if Cluster.ctype ~= INTEL.Ctype.AIRCRAFT then return end
    -- Threatlevel 0..10
    local contact = self:GetHighestThreatContact(Cluster)
    local name = contact.groupname --#string
    local threat = contact.threatlevel --#number
    local position = self:CalcClusterFuturePosition(Cluster,300)
    -- calculate closest zone
    local bestdistance = 2000*1000 -- 2000km
    local targetairwing = nil -- Ops.AirWing#AIRWING
    local targetawname = "" -- #string
    local clustersize = self:ClusterCountUnits(Cluster) or 1
    local wingsize = math.abs(overhead * (clustersize+1))
    if wingsize > maxsize then wingsize = maxsize end
    if (not Cluster.mission) and (wingsize > 0) then
     MESSAGE:New(string.format("**** %s Interceptors need wingsize %d", UTILS.GetCoalitionName(self.coalition), wingsize),15,"CAPGCI"):ToAllIf(self.debug):ToLog()
      for _,_data in pairs (wings) do
        local airwing = _data[1] -- Ops.AirWing#AIRWING
        local zone = _data[2] -- Core.Zone#ZONE
        local zonecoord = zone:GetCoordinate()
        local name = _data[3] -- #string
        local distance = position:DistanceFromPointVec2(zonecoord)
        local airframes = airwing:CountAssets(true)
        if distance < bestdistance and airframes >= wingsize then
          bestdistance = distance
          targetairwing = airwing
          targetawname = name
        end
      end
      for _,_data in pairs (ctlpts) do
        --local airwing = _data[1] -- Ops.AirWing#AIRWING
        --local zone = _data[2] -- Core.Zone#ZONE
        --local zonecoord = zone:GetCoordinate()
        --local name = _data[3] -- #string
        
        local data = _data -- #EASYGCICAP.CapPoint
        local name = data.AirbaseName
        local zonecoord = data.Coordinate
        local airwing = wings[name][1]
        
        local distance = position:DistanceFromPointVec2(zonecoord)
        local airframes = airwing:CountAssets(true)
        if distance < bestdistance and airframes >= wingsize then
          bestdistance = distance
          targetairwing = airwing
          targetawname = name
        end
      end
      local text = string.format("Closest Airwing is %s", targetawname)
      local m = MESSAGE:New(text,10,"CAPGCI"):ToAll():ToLog()
      -- Do we have a matching airwing?
      if targetairwing then
        local AssetCount = targetairwing:CountAssetsOnMission(MissionTypes,Cohort)
        --local AssetCount = targetairwing:GetAssetsOnMission({AUFTRAG.Type.INTERCEPT})
        -- Enough airframes on mission already?
        self:I(self.lid.." Assets on Mission "..AssetCount)
        if AssetCount <= MaxAliveMissions then
          local repeats = math.random(1,2)
          local InterceptAuftrag = AUFTRAG:NewINTERCEPT(contact.group)
            :SetMissionRange(150)
            :SetPriority(1,true,1)
            :SetRequiredAssets(wingsize)
            :SetRepeatOnFailure(repeats)
            :SetMissionSpeed(UTILS.KnotsToAltKIAS(capspeed,capalt))
            :SetMissionAltitude(capalt)
          targetairwing:AddMission(InterceptAuftrag)
          Cluster.mission = InterceptAuftrag
        end
      else
        MESSAGE:New("**** Not enough airframes available or max mission limit reached!",15,"CAPGCI"):ToAllIf(self.debug):ToLog()
      end
   end
  end
self.Intel = BlueIntel  
return self
end

-------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------

--- (Internal) FSM Function onafterStart
-- @param #EASYGCICAP self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #EASYGCICAP self
function EASYGCICAP:onafterStart(From,Event,To)
  self:I({From,Event,To})
  self:_StartIntel()
  self:_CreateAirwings()
  self:_CreateSquads()
  self:_SetCAPPatrolPoints()
  self:_SetTankerPatrolPoints()
  self:__Status(-10)
  return self
end

--- (Internal) FSM Function onbeforeStatus
-- @param #EASYGCICAP self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #EASYGCICAP self
function EASYGCICAP:onbeforeStatus(From,Event,To)
  self:T({From,Event,To})
  if self:GetState() == "Stopped" then return false end
  return self
end

--- (Internal) FSM Function onafterStatus
-- @param #EASYGCICAP self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #EASYGCICAP self
function EASYGCICAP:onafterStatus(From,Event,To)
  self:I({From,Event,To})
  -- Gather Some Stats
  local function counttable(tbl)
    local count = 0
    for _,_data in pairs(tbl) do
      count = count + 1
    end
    return count
  end
  local wings = counttable(self.ManagedAW)
  local squads = counttable(self.ManagedSQ)
  local caps = counttable(self.ManagedCP)
  local assets = 0
  local instock = 0
  for _,_wing in pairs(self.wings) do
    local count = _wing[1]:CountAssetsOnMission(MissionTypes,Cohort)
    local count2 = _wing[1]:CountAssets(true,MissionTypes,Attributes)
    assets = assets + count
    instock = instock + count2
  end
  if self.debug then
    self:I(self.lid.."Wings: "..wings.." | Squads: "..squads.." | CapPoints: "..caps.." | Assets on Mission: "..assets.." | Assets in Stock: "..instock)
  end
  self:__Status(30)
  return self
end

--- (Internal) FSM Function onafterStop
-- @param #EASYGCICAP self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #EASYGCICAP self
function EASYGCICAP:onafterStop(From,Event,To)
  self:I({From,Event,To})
  self.Intel:Stop()
  return self
end
