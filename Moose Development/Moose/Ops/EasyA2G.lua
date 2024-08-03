-------------------------------------------------------------------------
-- Easy A2G Class, based on OPS classes
-------------------------------------------------------------------------
-- Documentation
-- 
-- https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.EasyA2G.html
-- 
-------------------------------------------------------------------------
-- Date: December 2023
-------------------------------------------------------------------------
--
--- **Ops** - Easy A2G Manager
--
-- ===
--
-- **Main Features:**
--
--    * Automatically create and manage A2G CAS/BAI/SEAD defenses using an AirWing and Squadrons for one coalition
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
-- @module Ops.EasyA2G
-- @image AI_Air_To_Ground_Dispatching.JPG


--- EASYA2G Class
-- @type EASYA2G
-- @field #string ClassName
-- @field #number overhead
-- @field #number engagerange
-- @field #number casgrouping
-- @field #string airbasename
-- @field Wrapper.Airbase#AIRBASE airbase
-- @field #number coalition
-- @field #string alias
-- @field #table wings
-- @field Ops.Intelligence#INTEL Intel
-- @field #number resurrection
-- @field #number casspeed
-- @field #number casalt
-- @field #number casdir
-- @field #number casleg
-- @field #number maxinterceptsize
-- @field #number missionrange
-- @field #number noaltert5
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
-- @field #boolean Monitor
-- @field #boolean TankerInvisible
-- @field #number CasFormation
-- @extends Core.Fsm#FSM

--- *“Airspeed, altitude, and brains. Two are always needed to successfully complete the flight.”* -- Unknown.
--
-- ===
--
-- # The EASYA2G Concept
-- 
-- The idea of this class is partially to make the OPS classes easier operational for an A2G defense network, and to replace the legacy AI_A2G_Dispatcher system - not to it's
-- full extent, but make a basic system work very quickly.
--
-- # Setup
-- 
-- ## Basic understanding
-- 
-- The basics are, there is **one** and only **one** AirWing per airbase. Each AirWing has **at least** one Squadron, who will do CAS, SEAS and BAI tasks. Squadrons will be randomly chosen for the task at hand.
-- Each AirWing has **at least** one Recon Point that it manages. Recon Points will be covered by the AirWing automatically as long as airframes are available. Detected intruders will be assigned to **one**
-- AirWing based on proximity (that is, if you have more than one). 
-- 
-- ## Assignment of tasks for intruders
-- 
-- Either a A2G Plane or a newly spawned plane will take care of the intruders. Standard overhead is 0.20, i.e. a group of 5 intrudes will
-- be managed by 1 plane from the assigned AirWing. There is an maximum missions limitation per AirWing, so we do not spam the skies.
-- 
-- ## Basic set-up code
-- 
-- ### Prerequisites
-- 
-- You have to put a STATIC object on the airbase with the UNIT name according to the name of the airbase. E.g. for Kuitaisi this has to have the name Kutaisi. This object symbolizes the AirWing HQ.
-- Next put a late activated template group for your A2G Squadron on the map. Last, put a zone on the map for the CAP operations, let's name it "Blue Zone 1". Size of the zone plays no role.
-- Put an EW radar system on the map and name it aptly, like "Blue EWR".
-- 
-- ### Code it
-- 
--          -- Set up a basic system for the blue side, we'll reside on Kutaisi, and use GROUP objects with "Blue EWR" in the name as EW Radar Systems.
--          local mywing = EASYA2G:New("Blue A2G Operations",AIRBASE.Caucasus.Kutaisi,"blue","Blue EWR")
--          
--          -- Add a Recon patrol point belonging to our airbase, we'll be at 30k ft doing 400 kn, initial direction 90 degrees (East), leg 20NM
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
--          mywing:AddAirwing(AIRBASE.Caucasus.Sukhumi_Babushara,"Blue A2G Sukhumi")
--          -- Recon Point "Blue Zone 2"
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
--        -- Add an AWACS squad - Radio 251 AM, TACAN 51Y
--        mywing:AddTankerSquadron("Blue Tanker","Tanker Ops Kutaisi",AIRBASE.Caucasus.Kutaisi,20,AI.Skill.EXCELLENT,602,nil,251,radio.modulation.AM,51)
--        
-- ### Add an AWACS (optional)
--        
--        -- Add an AWACS point
--        mywing:AddPatrolPointAwacs(AIRBASE.Caucasus.Kutaisi,ZONE:FindByName("Blue Zone AWACS"):GetCoordinate(),25000,300,270,50)
--        -- Add a tanker squad - Radio 251 AM, TACAN 51Y
--        mywing:AddAWACSSquadron("Blue AWACS","AWACS Ops Kutaisi",AIRBASE.Caucasus.Kutaisi,20,AI.Skill.AVERAGE,702,nil,271,radio.modulation.AM)        
--
-- # Fine-Tuning
--
-- ## Change Defaults
-- 
-- * @{#EASYA2G.SetDefaultResurrection}: Set how many seconds the AirWing stays inoperable after the AirWing STATIC HQ ist destroyed, default 900 secs. 
-- * @{#EASYA2G.SetDefaultCAPSpeed}: Set how many knots the CAP flights should do (will be altitude corrected), default 300 kn.
-- * @{#EASYA2G.SetDefaultCAPAlt}: Set at which altitude (ASL) the CAP planes will fly, default 25,000 ft.
-- * @{#EASYA2G.SetDefaultCAPDirection}: Set the initial direction from the CAP point the planes will fly in degrees, default is 90°.
-- * @{#EASYA2G.SetDefaultCAPLeg}: Set the length of the CAP leg, default is 15 NM.
-- * @{#EASYA2G.SetDefaultCAPGrouping}: Set how many planes will be spawned per mission (CVAP/GCI), defaults to 2.
-- * @{#EASYA2G.SetDefaultMissionRange}: Set how many NM the planes can go from the home base, defaults to 100.
-- * @{#EASYA2G.SetDefaultNumberAlter5Standby}: Set how many planes will be spawned on cold standby (Alert5), default 2.
-- * @{#EASYA2G.SetDefaultEngageRange}: Set max engage range for CAP flights if they detect intruders, defaults to 50.
-- * @{#EASYA2G.SetMaxAliveMissions}: Set max parallel missions can be done (CAP+GCI+Alert5+Tanker+AWACS), defaults to 8.
-- * @{#EASYA2G.SetDefaultRepeatOnFailure}: Set max repeats on failure for intercepting/killing intruders, defaults to 3.
-- * @{#EASYA2G.SetTankerAndAWACSInvisible}: Set Tanker and AWACS to be invisible to enemy AI eyes. Is set to `true` by default.
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
  overhead = 0.2,
  casgrouping = 2,
  airbasename = nil,
  airbase = nil,
  coalition = "blue",
  alias = nil,
  wings = {},
  Intel = nil,
  resurrection = 900,
  casspeed = 250,
  casalt = 10000,
  casdir = 45,
  casleg = 15,
  maxinterceptsize = 2,
  missionrange = 100,
  noaltert5 = 0,
  ManagedAW = {},
  ManagedSQ = {},
  ManagedCP = {},
  ManagedTK = {},
  ManagedEWR = {},
  ManagedREC = {},
  MaxAliveMissions = 10,
  debug = true,
  engagerange = 50,
  repeatsonfailure = 10,
  GoZoneSet = nil,
  NoGoZoneSet = nil,
  Monitor = true,
  TankerInvisible = true,
  CasFormation = nil,
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

--- Internal CasPoint data type
-- @type EASYA2G.CasPoint
-- @field #string AirbaseName
-- @field Core.Point#COORDINATE Coordinate
-- @field #number Altitude
-- @field #number Speed
-- @field #number Heading
-- @field #number LegLength

--- EASYA2G class version.
-- @field #string version
EASYA2G.version="0.0.9"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: TBD

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new GCICAP Manager
-- @param #EASYA2G self
-- @param #string Alias
-- @param #string AirbaseName
-- @param #string Coalition
-- @param #string EWRName
-- @return #EASYA2G self
function EASYA2G:New(Alias, AirbaseName, Coalition, EWRName)
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #EASYA2G
  
  -- defaults
  self.alias = Alias or AirbaseName.." A2G Wing"
  self.coalitionname = string.lower(Coalition) or "blue"
  self.coalition = self.coaltitionname == "blue" and coalition.side.BLUE or coalition.side.RED
  self.wings = {}
  self.EWRName = EWRName or self.coalitionname.." EWR"
  --self.CapZoneName = CapZoneName
  self.airbasename = AirbaseName
  self.airbase = AIRBASE:FindByName(self.airbasename)
  self.GoZoneSet = SET_ZONE:New()
  self.NoGoZoneSet = SET_ZONE:New()
  self.resurrection = 900
  self.casspeed = 250
  self.casalt = 10000
  self.casdir = 90
  self.casleg = 15
  self.casgrouping = 2
  self.missionrange = 100
  self.noaltert5 = 2
  self.MaxAliveMissions = 8
  self.engagerange = 50
  self.repeatsonfailure = 3
  self.Monitor = false
  self.TankerInvisible = true
  self.CasFormation = ENUMS.Formation.FixedWing.BomberElement.Group
  
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

--- Set CAP formation.
-- @param #EASYA2G self
-- @param #number Formation Formation to fly, defaults to ENUMS.Formation.FixedWing.FingerFour.Group
-- @return #EASYA2G self
function EASYA2G:SetA2GFormation(Formation)
  self.CasFormation = Formation
  return self
end

--- Set Tanker and AWACS to be invisible to enemy AI eyes
-- @param #EASYA2G self
-- @param #boolean Switch Set to true or false, by default this is set to true already
-- @return #EASYA2G self 
function EASYA2G:SetTankerAndAWACSInvisible(Switch)
  self:T(self.lid.."SetTankerAndAWACSInvisible")
  self.TankerInvisible = Switch
  return self
end

--- Set Maximum of alive missions to stop airplanes spamming the map
-- @param #EASYA2G self
-- @param #number Maxiumum Maxmimum number of parallel missions allowed. Count is Cap-Missions + Intercept-Missions + Alert5-Missionsm default is 6
-- @return #EASYA2G self 
function EASYA2G:SetMaxAliveMissions(Maxiumum)
  self:T(self.lid.."SetDefaultResurrection")
  self.MaxAliveMissions = Maxiumum or 8
  return self
end

--- Add default time to resurrect Airwing building if destroyed
-- @param #EASYA2G self
-- @param #number Seconds Seconds, defaults to 900
-- @return #EASYA2G self 
function EASYA2G:SetDefaultResurrection(Seconds)
  self:T(self.lid.."SetDefaultResurrection")
  self.resurrection = Seconds or 900
  return self
end

--- Add default repeat attempts if an Intruder intercepts fails.
-- @param #EASYA2G self
-- @param #number Retries Retries, defaults to 3
-- @return #EASYA2G self 
function EASYA2G:SetDefaultRepeatOnFailure(Retries)
  self:T(self.lid.."SetDefaultRepeatOnFailure")
  self.repeatsonfailure = Retries or 3
  return self
end

--- Set default A2G Speed in knots
-- @param #EASYA2G self
-- @param #number Speed Speed defaults to 250
-- @return #EASYA2G self
function EASYA2G:SetDefaultA2GSpeed(Speed)
  self:T(self.lid.."SetDefaultSpeed")
  self.casspeed = Speed or 250
  return self
end

--- Set default A2G Altitude in feet
-- @param #EASYA2G self
-- @param #number Altitude Altitude defaults to 25000
-- @return #EASYA2G self
function EASYA2G:SetDefaultA2GAlt(Altitude)
  self:T(self.lid.."SetDefaultAltitude")
  self.casalt = Altitude or 25000
  return self
end

--- Set default A2G leg initial direction in degrees
-- @param #EASYA2G self
-- @param #number Direction Direction defaults to 90 (East)
-- @return #EASYA2G self
function EASYA2G:SetDefaultA2GDirection(Direction)
  self:T(self.lid.."SetDefaultDirection")
  self.casdir = Direction or 90
  return self
end

--- Set default leg length in NM
-- @param #EASYA2G self
-- @param #number Leg Leg defaults to 15
-- @return #EASYA2G self
function EASYA2G:SetDefaultA2GLeg(Leg)
  self:T(self.lid.."SetDefaultLeg")
 self.casleg = Leg or 15
 return self
end

--- Set default grouping, i.e. how many airplanes per A2G point
-- @param #EASYA2G self
-- @param #number Grouping Grouping defaults to 2
-- @return #EASYA2G self
function EASYA2G:SetDefaultA2GGrouping(Grouping)
 self:T(self.lid.."SetDefaultA2GGrouping")
 self.casgrouping = Grouping or 2
 return self
end

--- Set default range planes can fly from their homebase in NM
-- @param #EASYA2G self
-- @param #number Range Range defaults to 100 NM
-- @return #EASYA2G self
function EASYA2G:SetDefaultMissionRange(Range)
  self:T(self.lid.."SetDefaultMissionRange")
  self.missionrange = Range or 100
  return self
end

--- Set default number of airframes standing by for intercept tasks (visible on the airfield)
-- @param #EASYA2G self
-- @param #number Airframes defaults to 2
-- @return #EASYA2G selfAirframes
function EASYA2G:SetDefaultNumberAlter5Standby(Airframes)
  self:T(self.lid.."SetDefaultNumberAlter5Standby")
  self.noaltert5 = math.abs(Airframes) or 2
  return self
end

--- Set default engage range for intruders detected by A2G flights in NM.
-- @param #EASYA2G self
-- @param #number Range defaults to 50NM
-- @return #EASYA2G selfAirframes
function EASYA2G:SetDefaultEngageRange(Range)
  self:T(self.lid.."SetDefaultNumberAlter5Standby")
  self.engagerange = Range or 50
  return self
end

--- Add an AirWing to the manager
-- @param #EASYA2G self
-- @param #string Airbasename
-- @param #string Alias
-- @return #EASYA2G self 
function EASYA2G:AddAirwing(Airbasename, Alias)
  self:T(self.lid.."AddAirwing "..Airbasename)
  
  -- Create Airwing data entry
  local AWEntry = {} -- #EASYA2G.Wing
  AWEntry.AirbaseName = Airbasename
  AWEntry.Alias = Alias
  --AWEntry.CapZoneName = CapZoneName
  
  self.ManagedAW[Airbasename] = AWEntry
  
  return self  
end

--- (Internal) Create actual AirWings from the list
-- @param #EASYA2G self
-- @return #EASYA2G self 
function EASYA2G:_CreateAirwings()
  self:T(self.lid.."_CreateAirwings")
  for airbase,data in pairs(self.ManagedAW) do
    local wing = data -- #EASYA2G.Wing
    local afb = wing.AirbaseName
    local alias = wing.Alias
    --local cz = wing.CapZoneName
    self:_AddAirwing(airbase,alias)
  end
  return self
end

--- (internal) Create and add another AirWing to the manager
-- @param #EASYA2G self
-- @param #string Airbasename
-- @param #string Alias
-- @return #EASYA2G self 
function EASYA2G:_AddAirwing(Airbasename, Alias)
  self:T(self.lid.."_AddAirwing "..Airbasename)
  
  local CasFormation = self.CasFormation
  
  -- Create Airwing
  local CAP_Wing = AIRWING:New(Airbasename,Alias)
  CAP_Wing:SetVerbosityLevel(0)
  CAP_Wing:SetReportOff()
  CAP_Wing:SetMarker(true)
  CAP_Wing:SetAirbase(AIRBASE:FindByName(Airbasename))
  CAP_Wing:SetRespawnAfterDestroyed()
  CAP_Wing:SetNumberCAS(self.casgrouping)
  --CAP_Wing:SetCapCloseRaceTrack(true)
  if CasFormation then
    CAP_Wing:SetCASFormation(CasFormation)
  end
  if #self.ManagedTK > 0 then
    CAP_Wing:SetNumberTankerBoom(1)
    CAP_Wing:SetNumberTankerProbe(1)
  end
  if #self.ManagedEWR > 0 then
    CAP_Wing:SetNumberAWACS(1)
  end
  if #self.ManagedREC > 0 then
    CAP_Wing:SetNumberRecon(1)
  end
  --local PatrolCoordinateKutaisi = ZONE:New(CapZoneName):GetCoordinate()
  --CAP_Wing:AddPatrolPointCAP(PatrolCoordinateKutaisi,self.casalt,UTILS.KnotsToAltKIAS(self.casspeed,self.casalt),self.casdir,self.casleg)
  CAP_Wing:SetTakeoffHot()
  CAP_Wing:SetLowFuelThreshold(0.3)
  CAP_Wing.RandomAssetScore = math.random(50,100)
  CAP_Wing:Start()

  local Intel = self.Intel
  
  local TankerInvisible = self.TankerInvisible
  
  function CAP_Wing:OnAfterFlightOnMission(From, Event, To, Flightgroup, Mission)
    local flightgroup = Flightgroup -- Ops.FlightGroup#FLIGHTGROUP
    --flightgroup:SetDespawnAfterLanding()
    flightgroup:SetDespawnAfterHolding()
    flightgroup:SetDestinationbase(AIRBASE:FindByName(Airbasename))
    flightgroup:GetGroup():CommandEPLRS(true,5)
    if Mission.type ~= AUFTRAG.Type.TANKER and Mission.type ~= AUFTRAG.Type.AWACS and Mission.type ~= AUFTRAG.Type.RECON then
      flightgroup:SetDetection(true)
      flightgroup:SetEngageDetectedOn(self.engagerange,nil,self.GoZoneSet,self.NoGoZoneSet)
      flightgroup:SetOutOfAGMRTB(switch)
      if CasFormation then
        flightgroup:GetGroup():SetOption(AI.Option.Air.id.FORMATION,CasFormation)
      end
    end
    if Mission.type == AUFTRAG.Type.TANKER or Mission.type == AUFTRAG.Type.AWACS or Mission.type == AUFTRAG.Type.RECON then
      if TankerInvisible then
        flightgroup:GetGroup():SetCommandInvisible(true)
      end
      if Mission.type == AUFTRAG.Type.RECON then
        flightgroup:SetDetection(true)
      end
    end
    flightgroup:GetGroup():OptionROTEvadeFire()   
    flightgroup:SetFuelLowRTB(true)
    Intel:AddAgent(flightgroup)
    function flightgroup:OnAfterHolding(From,Event,To)
      self:ClearToLand(5)
    end 
    
  end
  
  if self.noaltert5 > 0 then  
    local alert = AUFTRAG:NewALERT5(AUFTRAG.Type.CASENHANCED) 
    alert:SetRequiredAssets(self.noaltert5)
    alert:SetRepeat(99) 
    CAP_Wing:AddMission(alert)
  end
  
  self.wings[Airbasename] = { CAP_Wing, AIRBASE:FindByName(Airbasename):GetZone(), Airbasename }
  
  return self 
end

--- Add a A2G patrol point to a Wing
-- @param #EASYA2G self
-- @param #string AirbaseName Name of the Wing's airbase
-- @param Core.Point#COORDINATE Coordinate.
-- @param #number Altitude Defaults to 25000 feet ASL.
-- @param #number Speed  Defaults to 300 knots TAS.
-- @param #number Heading Defaults to 90 degrees (East).
-- @param #number LegLength Defaults to 15 NM.
-- @return #EASYA2G self
function EASYA2G:AddPatrolPointA2G(AirbaseName,Coordinate,Altitude,Speed,Heading,LegLength)
  self:T(self.lid.."AddPatrolPointA2G "..Coordinate:ToStringLLDDM())
  local EntryCAP = {} -- #EASYA2G.CasPoint
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

--- Add a RECON patrol point to a Wing
-- @param #EASYA2G self
-- @param #string AirbaseName Name of the Wing's airbase
-- @param Core.Point#COORDINATE Coordinate.
-- @param #number Altitude Defaults to 25000 feet.
-- @param #number Speed  Defaults to 300 knots.
-- @param #number Heading Defaults to 90 degrees (East).
-- @param #number LegLength Defaults to 15 NM.
-- @return #EASYA2G self
function EASYA2G:AddPatrolPointRecon(AirbaseName,Coordinate,Altitude,Speed,Heading,LegLength)
  self:T(self.lid.."AddPatrolPointRecon "..Coordinate:ToStringLLDDM())
  local EntryCAP = {} -- #EASYA2G.CasPoint
  EntryCAP.AirbaseName = AirbaseName
  EntryCAP.Coordinate = Coordinate
  EntryCAP.Altitude = Altitude or 25000
  EntryCAP.Speed = Speed or 300
  EntryCAP.Heading = Heading or 90
  EntryCAP.LegLength = LegLength or 15
  self.ManagedREC[#self.ManagedREC+1] = EntryCAP
  if self.debug then
    local mark = MARKER:New(Coordinate,self.lid.."Patrol Point Recon"):ToAll()
  end
  return self
end

--- Add a TANKER patrol point to a Wing
-- @param #EASYA2G self
-- @param #string AirbaseName Name of the Wing's airbase
-- @param Core.Point#COORDINATE Coordinate.
-- @param #number Altitude Defaults to 25000 feet.
-- @param #number Speed  Defaults to 300 knots.
-- @param #number Heading Defaults to 90 degrees (East).
-- @param #number LegLength Defaults to 15 NM.
-- @return #EASYA2G self
function EASYA2G:AddPatrolPointTanker(AirbaseName,Coordinate,Altitude,Speed,Heading,LegLength)
  self:T(self.lid.."AddPatrolPointTanker "..Coordinate:ToStringLLDDM())
  local EntryCAP = {} -- #EASYA2G.CasPoint
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

--- Add an AWACS patrol point to a Wing
-- @param #EASYA2G self
-- @param #string AirbaseName Name of the Wing's airbase
-- @param Core.Point#COORDINATE Coordinate.
-- @param #number Altitude Defaults to 25000 feet.
-- @param #number Speed  Defaults to 300 knots.
-- @param #number Heading Defaults to 90 degrees (East).
-- @param #number LegLength Defaults to 15 NM.
-- @return #EASYA2G self
function EASYA2G:AddPatrolPointAwacs(AirbaseName,Coordinate,Altitude,Speed,Heading,LegLength)
  self:T(self.lid.."AddPatrolPointAwacs "..Coordinate:ToStringLLDDM())
  local EntryCAP = {} -- #EASYA2G.CasPoint
  EntryCAP.AirbaseName = AirbaseName
  EntryCAP.Coordinate = Coordinate
  EntryCAP.Altitude = Altitude or 25000
  EntryCAP.Speed = Speed or 300
  EntryCAP.Heading = Heading or 90
  EntryCAP.LegLength = LegLength or 15
  self.ManagedEWR[#self.ManagedEWR+1] = EntryCAP
  if self.debug then
    local mark = MARKER:New(Coordinate,self.lid.."Patrol Point AWACS"):ToAll()
  end
  return self
end

--- (Internal) Set actual Tanker Points from the list
-- @param #EASYA2G self
-- @return #EASYA2G self 
function EASYA2G:_SetTankerPatrolPoints()
  self:T(self.lid.."_SetTankerPatrolPoints")
  for _,_data in pairs(self.ManagedTK) do
    local data = _data --#EASYA2G.CasPoint
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

--- (Internal) Set actual Awacs Points from the list
-- @param #EASYA2G self
-- @return #EASYA2G self 
function EASYA2G:_SetAwacsPatrolPoints()
  self:T(self.lid.."_SetAwacsPatrolPoints")
  for _,_data in pairs(self.ManagedEWR) do
    local data = _data --#EASYA2G.CasPoint
    local Wing = self.wings[data.AirbaseName][1] -- Ops.AirWing#AIRWING
    local Coordinate = data.Coordinate
    local Altitude = data.Altitude
    local Speed = data.Speed 
    local Heading = data.Heading
    local LegLength = data.LegLength
    Wing:AddPatrolPointAWACS(Coordinate,Altitude,Speed,Heading,LegLength)
  end
  
  return self
end

--- (Internal) Set actual PatrolPoints from the list
-- @param #EASYA2G self
-- @return #EASYA2G self 
function EASYA2G:_SetA2GPatrolPoints()
  self:T(self.lid.."_SetA2GPatrolPoints")
  for _,_data in pairs(self.ManagedCP) do
    local data = _data --#EASYA2G.CasPoint
    local Wing = self.wings[data.AirbaseName][1] -- Ops.AirWing#AIRWING
    local Coordinate = data.Coordinate
    local Altitude = data.Altitude
    local Speed = data.Speed 
    local Heading = data.Heading
    local LegLength = data.LegLength
    local caszone = ZONE_RADIUS:New("EasyA2G-"..math.random(1,100000),Coordinate:GetVec2(),5000,false)
    Wing:AddPatrolPointCAS(caszone,Altitude,Speed,100,self.NoGoZoneSet)
  end
  
  return self
end

--- (Internal) Set actual PatrolPoints from the list
-- @param #EASYA2G self
-- @return #EASYA2G self 
function EASYA2G:_SetReconPatrolPoints()
  self:T(self.lid.."_SetReconPatrolPoints")
  for _,_data in pairs(self.ManagedREC) do
    local data = _data --#EASYA2G.CasPoint
    local Wing = self.wings[data.AirbaseName][1] -- Ops.AirWing#AIRWING
    local Coordinate = data.Coordinate
    local Altitude = data.Altitude
    local Speed = data.Speed 
    local Heading = data.Heading
    local LegLength = data.LegLength
    Wing:AddPatrolPointRecon(Coordinate,Altitude,Speed,Heading,LegLength)
  end
  
  return self
end

--- (Internal) Create actual Squadrons from the list
-- @param #EASYA2G self
-- @return #EASYA2G self 
function EASYA2G:_CreateSquads()
  self:T(self.lid.."_CreateSquads")
  for name,data in pairs(self.ManagedSQ) do
    local squad = data -- #EASYA2G.Squad
    local SquadName = name
    local TemplateName = squad.TemplateName
    local AirbaseName = squad.AirbaseName
    local AirFrames = squad.AirFrames
    local Skill = squad.Skill
    local Modex = squad.Modex
    local Livery = squad.Livery
    local Frequency = squad.Frequency
    local Modulation = squad.Modulation
    local TACAN = squad.TACAN
    if squad.Tanker then
      self:_AddTankerSquadron(TemplateName,SquadName,AirbaseName,AirFrames,Skill,Modex,Livery,Frequency,Modulation,TACAN)
    elseif squad.AWACS then
      self:_AddAWACSSquadron(TemplateName,SquadName,AirbaseName,AirFrames,Skill,Modex,Livery,Frequency,Modulation)
    elseif squad.RECON then
      self:_AddReconSquadron(TemplateName,SquadName,AirbaseName,AirFrames,Skill,Modex,Livery)
    elseif squad.BOMBING then
      self:_AddSquadronBOMBING(TemplateName,SquadName,AirbaseName,AirFrames,Skill,Modex,Livery,Frequency,Modulation)
    elseif squad.SEAD then
      self:_AddSquadronSEAD(TemplateName,SquadName,AirbaseName,AirFrames,Skill,Modex,Livery,Frequency,Modulation)
    elseif squad.ANTISHIP then
      self:_AddSquadronANTISHIP(TemplateName,SquadName,AirbaseName,AirFrames,Skill,Modex,Livery,Frequency,Modulation)
    else
      self:_AddSquadron(TemplateName,SquadName,AirbaseName,AirFrames,Skill,Modex,Livery)
    end
  end
  return self
end

--- Add a CAS Squadron to an Airwing of the manager
-- @param #EASYA2G self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYA2G self 
function EASYA2G:AddSquadronCAS(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:T(self.lid.."AddSquadronCAS "..SquadName)
  -- Add Squadron Data
  local EntrySQ = {} -- #EASYA2G.Squad
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

--- Add a SEAD Squadron to an Airwing of the manager
-- @param #EASYA2G self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYA2G self 
function EASYA2G:AddSquadronSEAD(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:T(self.lid.."AddSquadronSEAD "..SquadName)
  -- Add Squadron Data
  local EntrySQ = {} -- #EASYA2G.Squad
  EntrySQ.TemplateName = TemplateName
  EntrySQ.SquadName = SquadName
  EntrySQ.AirbaseName = AirbaseName
  EntrySQ.AirFrames = AirFrames or 20
  EntrySQ.Skill = Skill or AI.Skill.AVERAGE
  EntrySQ.Modex = Modex or 402
  EntrySQ.Livery = Livery
  EntrySQ.SEAD= true  
  self.CanSEAD = true
  
  self.ManagedSQ[SquadName] = EntrySQ
  
  return self
end

--- Add an ANTISHIP Squadron to an Airwing of the manager
-- @param #EASYA2G self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYA2G self 
function EASYA2G:AddSquadronANTISHIP(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:T(self.lid.."AddSquadronANTISHIP "..SquadName)
  -- Add Squadron Data
  local EntrySQ = {} -- #EASYA2G.Squad
  EntrySQ.TemplateName = TemplateName
  EntrySQ.SquadName = SquadName
  EntrySQ.AirbaseName = AirbaseName
  EntrySQ.AirFrames = AirFrames or 20
  EntrySQ.Skill = Skill or AI.Skill.AVERAGE
  EntrySQ.Modex = Modex or 402
  EntrySQ.Livery = Livery
  EntrySQ.ANTISHIP = true
  self.CanAntiShip = true
  
  self.ManagedSQ[SquadName] = EntrySQ
  
  return self
end

--- Add a BOMBING Squadron to an Airwing of the manager
-- @param #EASYA2G self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYA2G self 
function EASYA2G:AddSquadronBOMBING(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:T(self.lid.."AddSquadronBOMBING "..SquadName)
  -- Add Squadron Data
  local EntrySQ = {} -- #EASYA2G.Squad
  EntrySQ.TemplateName = TemplateName
  EntrySQ.SquadName = SquadName
  EntrySQ.AirbaseName = AirbaseName
  EntrySQ.AirFrames = AirFrames or 20
  EntrySQ.Skill = Skill or AI.Skill.AVERAGE
  EntrySQ.Modex = Modex or 402
  EntrySQ.Livery = Livery
  EntrySQ.BOMBING = true
  self.CanBombing = true
  
  self.ManagedSQ[SquadName] = EntrySQ
  
  return self
end

--- Add a Recon Squadron to an Airwing of the manager
-- @param #EASYA2G self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYA2G self 
function EASYA2G:AddReconSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:T(self.lid.."AddReconSquadron "..SquadName)
  -- Add Squadron Data
  local EntrySQ = {} -- #EASYA2G.Squad
  EntrySQ.TemplateName = TemplateName
  EntrySQ.SquadName = SquadName
  EntrySQ.AirbaseName = AirbaseName
  EntrySQ.AirFrames = AirFrames or 20
  EntrySQ.Skill = Skill or AI.Skill.AVERAGE
  EntrySQ.Modex = Modex or 402
  EntrySQ.Livery = Livery
  EntrySQ.RECON = true
    
  self.ManagedSQ[SquadName] = EntrySQ
  
  return self
end

--- Add a Tanker Squadron to an Airwing of the manager
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
-- @param #number TACAN (optional)  TACAN channel, e.g. 71, resulting in Channel 71Y
-- @return #EASYA2G self 
function EASYA2G:AddTankerSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation, TACAN)
  self:T(self.lid.."AddTankerSquadron "..SquadName)
  -- Add Squadron Data
  local EntrySQ = {} -- #EASYA2G.Squad
  EntrySQ.TemplateName = TemplateName
  EntrySQ.SquadName = SquadName
  EntrySQ.AirbaseName = AirbaseName
  EntrySQ.AirFrames = AirFrames or 20
  EntrySQ.Skill = Skill or AI.Skill.AVERAGE
  EntrySQ.Modex = Modex or 602
  EntrySQ.Livery = Livery
  EntrySQ.Frequency = Frequency
  EntrySQ.Modulation = Livery
  EntrySQ.TACAN = TACAN
  EntrySQ.Tanker = true
  
  self.ManagedSQ[SquadName] = EntrySQ
  
  return self
end

--- Add an AWACS Squadron to an Airwing of the manager
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
function EASYA2G:AddAWACSSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation)
  self:T(self.lid.."AddAWACSSquadron "..SquadName)
  -- Add Squadron Data
  local EntrySQ = {} -- #EASYA2G.Squad
  EntrySQ.TemplateName = TemplateName
  EntrySQ.SquadName = SquadName
  EntrySQ.AirbaseName = AirbaseName
  EntrySQ.AirFrames = AirFrames or 20
  EntrySQ.Skill = Skill or AI.Skill.AVERAGE
  EntrySQ.Modex = Modex or 702
  EntrySQ.Livery = Livery
  EntrySQ.Frequency = Frequency
  EntrySQ.Modulation = Livery
  EntrySQ.AWACS = true
  
  self.ManagedSQ[SquadName] = EntrySQ
  
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
  Squadron_One:AddMissionCapability({AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.PATROLRACETRACK, AUFTRAG.Type.ALERT5})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(10,20)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  
  local wing = self.wings[AirbaseName][1] -- Ops.AirWing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.PATROLRACETRACK, AUFTRAG.Type.ALERT5},75)
  
  return self
end

--- (Internal) Add a SEAD Squadron to an Airwing of the manager
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
function EASYA2G:_AddSquadronSEAD(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation)
  self:T(self.lid.."_AddSquadronSEAD "..SquadName)
  -- Add Squadrons
  local Squadron_One = SQUADRON:New(TemplateName,AirFrames,SquadName)
  Squadron_One:AddMissionCapability({AUFTRAG.Type.SEAD, AUFTRAG.Type.PATROLRACETRACK, AUFTRAG.Type.ALERT5})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(10,20)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  
  local wing = self.wings[AirbaseName][1] -- Ops.AirWing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.SEAD, AUFTRAG.Type.PATROLRACETRACK, AUFTRAG.Type.ALERT5},75)
  
  return self
end

--- (Internal) Add an ANTISHIP Squadron to an Airwing of the manager
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
function EASYA2G:_AddSquadronANTISHIP(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation)
  self:T(self.lid.."_AddSquadronANTISHIP "..SquadName)
  -- Add Squadrons
  local Squadron_One = SQUADRON:New(TemplateName,AirFrames,SquadName)
  Squadron_One:AddMissionCapability({AUFTRAG.Type.ANTISHIP, AUFTRAG.Type.PATROLRACETRACK, AUFTRAG.Type.ALERT5})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(10,20)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  
  local wing = self.wings[AirbaseName][1] -- Ops.AirWing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.ANTISHIP, AUFTRAG.Type.PATROLRACETRACK, AUFTRAG.Type.ALERT5},75)
  
  return self
end

--- (Internal) Add an BOMBING Squadron to an Airwing of the manager
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
function EASYA2G:_AddSquadronBOMBING(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation)
  self:T(self.lid.."_AddSquadronBOMBING "..SquadName)
  -- Add Squadrons
  local Squadron_One = SQUADRON:New(TemplateName,AirFrames,SquadName)
  Squadron_One:AddMissionCapability({AUFTRAG.Type.BOMBING, AUFTRAG.Type.PATROLRACETRACK, AUFTRAG.Type.ALERT5})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(10,20)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  
  local wing = self.wings[AirbaseName][1] -- Ops.AirWing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.BOMBING, AUFTRAG.Type.PATROLRACETRACK, AUFTRAG.Type.ALERT5},75)
  
  return self
end

--- (Internal) Add a Recon Squadron to an Airwing of the manager
-- @param #EASYA2G self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYA2G self 
function EASYA2G:_AddReconSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:T(self.lid.."_AddReconSquadron "..SquadName)
  -- Add Squadrons
  local Squadron_One = SQUADRON:New(TemplateName,AirFrames,SquadName)
  Squadron_One:AddMissionCapability({AUFTRAG.Type.RECON})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(10,20)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  
  local wing = self.wings[AirbaseName][1] -- Ops.AirWing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.RECON},75)
  
  return self
end

--- (Internal) Add a Tanker Squadron to an Airwing of the manager
-- @param #EASYA2G self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @param #number Frequency (optional) Radio frequency of the Tanker
-- @param #number Modulation (Optional) Radio modulation of the Tanker
-- @param #number TACAN (Optional) TACAN Channel to be used, will always be an "Y" channel
-- @return #EASYA2G self 
function EASYA2G:_AddTankerSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation, TACAN)
  self:T(self.lid.."_AddTankerSquadron "..SquadName)
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
  Squadron_One:SetRadio(Frequency,Modulation)
  Squadron_One:AddTacanChannel(TACAN,TACAN)
  
  local wing = self.wings[AirbaseName][1] -- Ops.AirWing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.TANKER},75)
  
  return self
end

--- (Internal) Add a AWACS Squadron to an Airwing of the manager
-- @param #EASYA2G self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @param #number Frequency (optional) Radio frequency of the AWACS
-- @param #number Modulation (Optional) Radio modulation of the AWACS
-- @return #EASYA2G self 
function EASYA2G:_AddAWACSSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation)
  self:T(self.lid.."_AddAWACSSquadron "..SquadName)
  -- Add Squadrons
  local Squadron_One = SQUADRON:New(TemplateName,AirFrames,SquadName)
  Squadron_One:AddMissionCapability({AUFTRAG.Type.AWACS})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(10,20)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  Squadron_One:SetRadio(Frequency,Modulation)
  local wing = self.wings[AirbaseName][1] -- Ops.AirWing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.AWACS},75)
  
  return self
end

--- Add a zone to the accepted zones set.
-- @param #EASYA2G self
-- @param Core.Zone#ZONE_BASE Zone
-- @return #EASYA2G self 
function EASYA2G:AddAcceptZone(Zone)
  self:T(self.lid.."AddAcceptZone0")
  self.GoZoneSet:AddZone(Zone)
  return self
end

--- Add a zone to the rejected zones set.
-- @param #EASYA2G self
-- @param Core.Zone#ZONE_BASE Zone
-- @return #EASYA2G self 
function EASYA2G:AddRejectZone(Zone)
  self:T(self.lid.."AddRejectZone")
  self.NoGoZoneSet:AddZone(Zone)
  return self
end

--- (Internal) Start detection.
-- @param #EASYA2G self
-- @return #EASYA2G self
function EASYA2G:_StartIntel()
  self:T(self.lid.."_StartIntel")
  -- Border GCI Detection
  local BlueAir_DetectionSetGroup = SET_GROUP:New()
  BlueAir_DetectionSetGroup:FilterPrefixes( { self.EWRName } )
  BlueAir_DetectionSetGroup:FilterStart()
  
  -- Intel type detection
  local BlueIntel = INTEL:New(BlueAir_DetectionSetGroup,self.coalitionname, self.EWRName)
  BlueIntel:SetClusterAnalysis(false,false,false)
  BlueIntel:SetForgetTime(300)
  BlueIntel:SetAcceptZones(self.GoZoneSet)
  BlueIntel:SetRejectZones(self.NoGoZoneSet)
  BlueIntel:SetVerbosity(0)
  BlueIntel:SetDetectStatics(true)
  BlueIntel:SetFilterCategory({Unit.Category.GROUND_UNIT, Unit.Category.SHIP, Unit.Category.STRUCTURE})
  --BlueIntel:SetDetectionTypes(false,true,true,true,false,true)
  BlueIntel:Start()
  
  if self.debug then 
    BlueIntel.debug = true
  end
  
  -- Here, we'll decide if we need to launch an A2G flight, and from where
  
  local overhead = self.overhead
  local casspeed = self.casspeed + 100
  local casalt = self.casalt
  local maxsize = self.maxinterceptsize
  local repeatsonfailure = self.repeatsonfailure
  
  local wings = self.wings
  local ctlpts = self.ManagedCP
  local MaxAliveMissions = self.MaxAliveMissions * self.casgrouping
  local nogozoneset = self.NoGoZoneSet
  
  function BlueIntel:OnAfterNewContact(From,Event,To,Contact)
    -- Aircraft?
    if Contact.ctype == INTEL.Ctype.AIRCRAFT then return end
    -- Threatlevel 0..10
    --local contact = self:GetHighestThreatContact(Cluster)
    local contact = Contact -- Ops.Intelligence#INTEL.Contact
    local name = contact.groupname --#string
    local threat = contact.threatlevel --#number
    --local position = self:CalcClusterFuturePosition(Cluster,300)
    local position = Contact.position
    -- calculate closest zone
    local bestdistance = 2000*1000 -- 2000km
    local targetairwing = nil -- Ops.AirWing#AIRWING
    local targetawname = "" -- #string
    local clustersize = contact.group.ClassName == "GROUP" and contact.group:CountAliveUnits() or 1
    local wingsize = math.abs(overhead * (clustersize+1))
    if wingsize > maxsize then wingsize = maxsize end
    -- existing mission, and if so - done?
    local retrymission = true
    if Contact.mission and (not Contact.mission:IsOver()) then 
      retrymission = false
    end
    if (retrymission) and (wingsize >= 1) then
     MESSAGE:New(string.format("**** %s A2G need wingsize %d", UTILS.GetCoalitionName(self.coalition), wingsize),15,"A2G"):ToAllIf(self.debug):ToLog()
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
        
        local data = _data -- #EASYA2G.CasPoint
        local name = data.AirbaseName
        local zonecoord = data.Coordinate
        local airwing = wings[name][1]
        
        local distance = position:DistanceFromPointVec2(zonecoord)
        local airframes = airwing:CountAssets(true)
        if distance < bestdistance and airframes >= wingsize then
          bestdistance = distance
          targetairwing = airwing -- Ops.AirWing#AIRWING
          targetawname = name
        end
      end
      local text = string.format("Closest Airwing is %s", targetawname)
      local m = MESSAGE:New(text,10,"A2G"):ToAllIf(self.debug):ToLog()
      -- Do we have a matching airwing?
      if targetairwing then
        local AssetCount = targetairwing:CountAssetsOnMission(MissionTypes,Cohort)
        -- Enough airframes on mission already?
        self:T(self.lid.." Assets on Mission "..AssetCount)
        if AssetCount <= MaxAliveMissions then
          local repeats = repeatsonfailure
          local caszone = ZONE_RADIUS:New("EasyA2G-"..math.random(1,100000),contact.position:GetVec2(),5000,false)
          --local InterceptAuftrag = AUFTRAG:NewCASENHANCED(caszone,casalt,casspeed,100,nogozoneset)
          local prio = 30
          local urgent = false
          local InterceptAuftrag = AUFTRAG:NewBAI(contact.group,casalt)
          if contact.isStatic and self.CanBombing then
            InterceptAuftrag = AUFTRAG:NewBOMBING(contact.group,casalt)
            prio = 50
          elseif contact.isship and self.CanAntiShip then
            InterceptAuftrag = AUFTRAG:NewANTISHIP(contact.group,casalt)
            urgent = true
          elseif self.CanSEAD and (contact.group:HasAttribute("RADAR_BAND1_FOR_ARM") or contact.group:HasAttribute("RADAR_BAND2_FOR_ARM") or contact.group:HasAttribute("Optical Tracker")) then
            InterceptAuftrag = AUFTRAG:NewSEAD(contact.group,casalt)
            prio = 1
            urgent = true
          end
          --local InterceptAuftrag = AUFTRAG:NewBAI(contact,casalt)
            InterceptAuftrag:SetMissionRange(100)
            InterceptAuftrag:SetPriority(prio,urgent)
            InterceptAuftrag:SetRequiredAssets(wingsize)
            InterceptAuftrag:SetRepeatOnFailure(repeats)
            InterceptAuftrag:SetMissionSpeed(UTILS.KnotsToAltKIAS(casspeed,casalt))
            InterceptAuftrag:SetMissionAltitude(casalt)
            
            if nogozoneset:Count() > 0 then
              InterceptAuftrag:AddConditionSuccess(
                function(group,zoneset)
                  local success = false
                  if group and group:IsAlive() then
                    local coord = group:GetCoordinate()
                    if coord and zoneset:IsCoordinateInZone(coord) then
                      success = true
                    end
                  end
                  return success
                end,
                contact.group,
                nogozoneset
              )
            end
            
          targetairwing:AddMission(InterceptAuftrag)
          Contact.mission = InterceptAuftrag
        end
      else
        MESSAGE:New("**** Not enough airframes available or max mission limit reached!",15,"A2G"):ToAllIf(self.debug):ToLog()
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
-- @param #EASYA2G self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #EASYA2G self
function EASYA2G:onafterStart(From,Event,To)
  self:T({From,Event,To})
  self:_StartIntel()
  self:_CreateAirwings()
  self:_CreateSquads()
  self:_SetA2GPatrolPoints()
  self:_SetTankerPatrolPoints()
  self:_SetAwacsPatrolPoints()
  self:_SetReconPatrolPoints()
  self:__Status(-10)
  return self
end

--- (Internal) FSM Function onbeforeStatus
-- @param #EASYA2G self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #EASYA2G self
function EASYA2G:onbeforeStatus(From,Event,To)
  self:T({From,Event,To})
  if self:GetState() == "Stopped" then return false end
  return self
end

--- (Internal) FSM Function onafterStatus
-- @param #EASYA2G self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #EASYA2G self
function EASYA2G:onafterStatus(From,Event,To)
  self:T({From,Event,To})
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
  local capmission = 0
  --local interceptmission = 0
  local reconmission = 0
  --local awacsmission = 0
  --local tankermission = 0
  local seadmission = 0
  local bombmission = 0
  local shipmission = 0
  for _,_wing in pairs(self.wings) do
    local count = _wing[1]:CountAssetsOnMission(MissionTypes,Cohort)
    local count2 = _wing[1]:CountAssets(true,MissionTypes,Attributes)
    capmission = capmission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.BAI})
    --interceptmission = interceptmission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.INTERCEPT})
    reconmission = reconmission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.RECON})
    --awacsmission = awacsmission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.AWACS})
    --tankermission = tankermission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.TANKER})
    seadmission = seadmission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.SEAD})
    bombmission = bombmission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.BOMBING})
    shipmission = shipmission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.ANTISHIP})
    assets = assets + count
    instock = instock + count2
  end
  if self.Monitor then
    local threatcount = #self.Intel.Contacts or 0
    local text =  "GCICAP "..self.alias
    text = text.."\nWings: "..wings.."\nSquads: "..squads.."\nCasPoints: "..caps.."\nAssets on Mission: "..assets.."\nAssets in Stock: "..instock
    text = text.."\nThreats: "..threatcount
    text = text.."\nMissions: "..capmission+reconmission+seadmission+bombmission+shipmission
    --text = text.."\n - Intercept: "..interceptmission
    --text = text.."\n - AWACS: "..awacsmission
    --text = text.."\n - TANKER: "..tankermission
    text = text.."\n - Recon: "..reconmission
    text = text.."\n - CAS/BAI: "..capmission
    if self.CanSEAD then
      text = text.."\n - SEAD: "..seadmission
    end
    if self.CanBombing then
      text = text.."\n - Bombing: "..bombmission
    end
    if self.CanAntiShip then
      text = text.."\n - Anti-Ship: "..shipmission
    end
    MESSAGE:New(text,15,"GCICAP"):ToAll():ToLogIf(self.debug)
  end
  self:__Status(30)
  return self
end

--- (Internal) FSM Function onafterStop
-- @param #EASYA2G self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #EASYA2G self
function EASYA2G:onafterStop(From,Event,To)
  self:T({From,Event,To})
  self.Intel:Stop()
  return self
end
