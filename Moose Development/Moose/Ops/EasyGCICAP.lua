--- **Ops** - Create your A2A Defenses.
--
-- **Main Features:**
--
--    * Automatically create and manage A2A defenses using an AirWing and Squadrons for one coalition
--    * Easy set-up
--
-- ===
--
-------------------------------------------------------------------------
-- Easy CAP/GCI Class, based on OPS classes
-------------------------------------------------------------------------
-- 
-- ## Documentation:
-- 
-- https://flightcontrol-master.github.io/MOOSE_DOCS_DEVELOP/Documentation/Ops.EasyGCICAP.html
-- 
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Ops/EasyGCICAP).
-- 
-------------------------------------------------------------------------
-- Date: September 2023
-- Last Update: Jan 2026
-------------------------------------------------------------------------
--
--- **Ops** - Easy GCI & CAP Manager
--
-- ===
--
-- **Main Features:**
--
--    * Automatically create and manage A2A CAP/GCI defenses using an AirWing and Squadrons for one coalition
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
-- @field #number maintenancetime
-- @field #number repairtime
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
-- You have to put a **STATIC WAREHOUSE** object on the airbase with the UNIT name according to the name of the airbase. **Do not put any other static type or it creates a conflict with the airbase name!** 
-- E.g. for Kutaisi this has to have the unit name Kutaisi. This object symbolizes the AirWing HQ.
-- Next put a late activated template group for your CAP/GCI Squadron on the map. Last, put a zone on the map for the CAP operations, let's name it "Blue Zone 1". Size of the zone plays no role.
-- Put an EW radar system on the map and name it aptly, like "Blue EWR".
-- 
-- ### Zones
-- 
-- For our example, you create a RED and a BLUE border, as a closed polygonal zone representing the borderlines. You can also have conflict zone, where - for our example - BLUE will attack
-- RED planes, despite being on RED territory. Think of a no-fly zone or an limited area of engagement. Conflict zones take precedence over borders, i.e. they can overlap all borders.
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
-- * @{#EASYGCICAP.SetDefaultResurrection}: Set how many seconds the AirWing stays inoperable after the AirWing STATIC HQ ist destroyed, default 900 secs. 
-- * @{#EASYGCICAP.SetDefaultCAPSpeed}: Set how many knots the CAP flights should do (will be altitude corrected), default 300 kn.
-- * @{#EASYGCICAP.SetDefaultCAPAlt}: Set at which altitude (ASL) the CAP planes will fly, default 25,000 ft.
-- * @{#EASYGCICAP.SetDefaultCAPDirection}: Set the initial direction from the CAP point the planes will fly in degrees, default is 90°.
-- * @{#EASYGCICAP.SetDefaultCAPLeg}: Set the length of the CAP leg, default is 15 NM.
-- * @{#EASYGCICAP.SetDefaultCAPGrouping}: Set how many planes will be spawned per mission (CVAP/GCI), defaults to 2.
-- * @{#EASYGCICAP.SetDefaultMissionRange}: Set how many NM the planes can go from the home base, defaults to 100.
-- * @{#EASYGCICAP.SetDefaultNumberAlert5Standby}: Set how many planes will be spawned on cold standby (Alert5), default 2.
-- * @{#EASYGCICAP.SetDefaultEngageRange}: Set max engage range for CAP flights if they detect intruders, defaults to 50.
-- * @{#EASYGCICAP.SetMaxAliveMissions}: Set max parallel missions can be done (CAP+GCI+Alert5+Tanker+AWACS), defaults to 8.
-- * @{#EASYGCICAP.SetDefaultRepeatOnFailure}: Set max repeats on failure for intercepting/killing intruders, defaults to 3.
-- * @{#EASYGCICAP.SetTankerAndAWACSInvisible}: Set Tanker and AWACS to be invisible to enemy AI eyes. Is set to `true` by default.
-- 
-- ## Debug and Monitor
-- 
--          mywing.debug = true -- log information
--          mywing.Monitor = true -- show some statistics on screen
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
  Intel = nil, -- Ops.Intel#INTEL
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
  EngageTargetTypes = {"Air"},
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
-- @field #boolean AWACS
-- @field #boolean RECON
-- @field #number Frequency
-- @field #number Modulation
-- @field #number TACAN

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
-- @field Core.Zone#ZONE_BASE Zone

--- EASYGCICAP class version.
-- @field #string version
EASYGCICAP.version="0.1.34"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: TBD

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new GCICAP Manager
-- @param #EASYGCICAP self
-- @param #string Alias A Name for this GCICAP
-- @param #string AirbaseName Name of the Home Airbase
-- @param #string Coalition Coalition, e.g. "blue" or "red"
-- @param #string EWRName (Partial) group name of the EWR system of the coalition, e.g. "Red EWR", can be handed in as table of names, e.g.{"EWR","Radar","SAM"}
-- @return #EASYGCICAP self
function EASYGCICAP:New(Alias, AirbaseName, Coalition, EWRName)
  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #EASYGCICAP
  
  -- defaults
  self.alias = Alias or AirbaseName.." CAP Wing"
      
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("EASYGCICAP %s | ", self.alias)
  
  self.coalitionname = string.lower(Coalition) or "blue"
  self.coalition = self.coalitionname == "blue" and coalition.side.BLUE or coalition.side.RED
  self.wings = {}
  if type(EWRName) == "string" then EWRName = {EWRName} end
  self.EWRName = EWRName --or self.coalitionname.." EWR"
  --self.CapZoneName = CapZoneName
  self.airbasename = AirbaseName
  self.airbase = AIRBASE:FindByName(self.airbasename)
  self.GoZoneSet = SET_ZONE:New()
  self.NoGoZoneSet = SET_ZONE:New()
  self.ConflictZoneSet = SET_ZONE:New()
  self.resurrection = 900
  self.capspeed = 300
  self.capalt = 25000
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
  self.EngageTargetTypes = {"Air"}
  self:SetDefaultTurnoverTime()
  
  -- Add FSM transitions.
  --               From State  -->   Event      -->      To State
  self:SetStartState("Stopped")
  self:AddTransition("Stopped", "Start",  "Running")
  self:AddTransition("Running", "Stop",   "Stopped")
  self:AddTransition("*",       "Status", "*")  
  
  self:AddAirwing(self.airbasename,self.alias,self.CapZoneName)
  
  self:I(self.lid.."Created new instance (v"..self.version..")")
  
  self:__Start(math.random(6,12))
  
  --- On Before "Start" event.
  -- @function [parent=#EASYGCICAP] OnBeforeStart
  -- @param #EASYGCICAP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "Start" event.
  -- @function [parent=#EASYGCICAP] OnAfterStart
  -- @param #EASYGCICAP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.

  --- On Before "Status" event.
  -- @function [parent=#EASYGCICAP] OnBeforeStatus
  -- @param #EASYGCICAP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  --- On After "Status" event.
  -- @function [parent=#EASYGCICAP] OnAfterStatus
  -- @param #EASYGCICAP self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  
  return self
end

-------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------

--- Get a specific managed AirWing by name
-- @param #EASYGCICAP self
-- @param #string AirbaseName Airbase name of the home of this wing.
-- @return Ops.AirWing#AIRWING Airwing or nil if not found
function EASYGCICAP:GetAirwing(AirbaseName)
  self:T(self.lid.."GetAirwing")
  if self.wings[AirbaseName] then
    return self.wings[AirbaseName][1]
  end
  return nil
end

--- Add an agent to the underlying INTEL detection - caution, we need to be started first for this to work! 
-- Normally this isn't necessary when the Group name is correctly filled (see EWRName in `New()`).
-- @param #EASYGCICAP self
-- @param Wrapper.Group#GROUP Group The group object to be added as Intel Agent.
-- @return #EASYGCICAP self
function EASYGCICAP:AddAgent(Group)
  self:T(self.lid.."AddAgent")
  if Group:IsInstanceOf("GROUP") and self.Intel ~= nil then
    self.Intel:AddAgent(Group)
    if self.TankerInvisible == true then
      Group:SetCommandInvisible(true)
      Group:OptionROEHoldFire()
      if Group:IsAir() then
        Group:OptionROTEvadeFire()
      else
        Group:OptionDisperseOnAttack(30)
      end
    end
  end
  return self
end

--- Get a table of all managed AirWings
-- @param #EASYGCICAP self
-- @return #table Table of Ops.AirWing#AIRWING Airwings
function EASYGCICAP:GetAirwingTable()
  self:T(self.lid.."GetAirwingTable")
  local Wingtable = {}
  for _,_object in pairs(self.wings or {}) do
    table.insert(Wingtable,_object[1])
  end
  return Wingtable
end

--- Set "fuel low" threshold for CAP and INTERCEPT flights.
-- @param #EASYGCICAP self
-- @param #number Percent RTB if fuel at this percent. Values: 1..100, defaults to 25.
-- @return #EASYGCICAP self
function EASYGCICAP:SetFuelLow(Percent)
  self:T(self.lid.."SetFuelLow")
  self.FuelLowThreshold = Percent or 25
  return self
end

--- Set markers on the map for Patrol Points.
-- @param #EASYGCICAP self
-- @param #boolean onoff Set to true to switch markers on.
-- @return #EASYGCICAP self
function EASYGCICAP:ShowPatrolPointMarkers(onoff)
  if onoff then
    self.showpatrolpointmarks = true
  else
    self.showpatrolpointmarks = false
  end
  return self
end

--- Set "fuel critical" threshold for CAP and INTERCEPT flights.
-- @param #EASYGCICAP self
-- @param #number Percent RTB if fuel at this percent. Values: 1..100, defaults to 10.
-- @return #EASYGCICAP self
function EASYGCICAP:SetFuelCritical(Percent)
  self:T(self.lid.."SetFuelCritical")
  self.FuelCriticalThreshold = Percent or 10
  return self
end

--- Set CAP formation.
-- @param #EASYGCICAP self
-- @param #number Formation Formation to fly, defaults to ENUMS.Formation.FixedWing.FingerFour.Group
-- @return #EASYGCICAP self
function EASYGCICAP:SetCAPFormation(Formation)
  self:T(self.lid.."SetCAPFormation")
  self.CapFormation = Formation
  return self
end

--- Set Tanker and AWACS to be invisible to enemy AI eyes
-- @param #EASYGCICAP self
-- @param #boolean Switch Set to true or false, by default this is set to true already
-- @return #EASYGCICAP self 
function EASYGCICAP:SetTankerAndAWACSInvisible(Switch)
  self:T(self.lid.."SetTankerAndAWACSInvisible")
  self.TankerInvisible = Switch
  return self
end

--- (internal) Count alive missions in our internal stack.
-- @param #EASYGCICAP self
-- @return #number count
function EASYGCICAP:_CountAliveAuftrags()
  local alive = 0
  for _,_auftrag in pairs(self.ListOfAuftrag) do
    local auftrag = _auftrag -- Ops.Auftrag#AUFTRAG
    if auftrag and (not (auftrag:IsCancelled() or auftrag:IsDone() or auftrag:IsOver())) then
       alive = alive + 1
    end
  end
  return alive
end

--- Set Maximum of alive missions created by this instance to stop airplanes spamming the map
-- @param #EASYGCICAP self
-- @param #number Maxiumum Maxmimum number of parallel missions allowed. Count is Intercept-Missions + Alert5-Missions, default is 8
-- @return #EASYGCICAP self 
function EASYGCICAP:SetMaxAliveMissions(Maxiumum)
  self:T(self.lid.."SetMaxAliveMissions")
  self.MaxAliveMissions = Maxiumum or 8
  return self
end

--- Add default time to resurrect Airwing building if destroyed
-- @param #EASYGCICAP self
-- @param #number Seconds Seconds, defaults to 900
-- @return #EASYGCICAP self 
function EASYGCICAP:SetDefaultResurrection(Seconds)
  self:T(self.lid.."SetDefaultResurrection")
  self.resurrection = Seconds or 900
  return self
end

--- Add default repeat attempts if an Intruder intercepts fails.
-- @param #EASYGCICAP self
-- @param #number Retries Retries, defaults to 3
-- @return #EASYGCICAP self 
function EASYGCICAP:SetDefaultRepeatOnFailure(Retries)
  self:T(self.lid.."SetDefaultRepeatOnFailure")
  self.repeatsonfailure = Retries or 3
  return self
end

--- Add default take off type for the airwings.
-- @param #EASYGCICAP self
-- @param #string Takeoff Can be "hot", "cold", or "air" - default is "hot".
-- @return #EASYGCICAP self 
function EASYGCICAP:SetDefaultTakeOffType(Takeoff)
  self:T(self.lid.."SetDefaultTakeOffType")
  self.defaulttakeofftype = Takeoff or "hot"
  return self
end

--- Set default CAP Speed in knots
-- @param #EASYGCICAP self
-- @param #number Speed Speed defaults to 300
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultCAPSpeed(Speed)
  self:T(self.lid.."SetDefaultSpeed")
  self.capspeed = Speed or 300
  return self
end

--- Set default CAP Altitude in feet
-- @param #EASYGCICAP self
-- @param #number Altitude Altitude defaults to 25000
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultCAPAlt(Altitude)
  self:T(self.lid.."SetDefaultAltitude")
  self.capalt = Altitude or 25000
  return self
end

--- Set default CAP lieg initial direction in degrees
-- @param #EASYGCICAP self
-- @param #number Direction Direction defaults to 90 (East)
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultCAPDirection(Direction)
  self:T(self.lid.."SetDefaultDirection")
  self.capdir = Direction or 90
  return self
end

--- Set default leg length in NM
-- @param #EASYGCICAP self
-- @param #number Leg Leg defaults to 15
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultCAPLeg(Leg)
  self:T(self.lid.."SetDefaultLeg")
 self.capleg = Leg or 15
 return self
end

--- Set default grouping, i.e. how many airplanes per CAP point
-- @param #EASYGCICAP self
-- @param #number Grouping Grouping defaults to 2
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultCAPGrouping(Grouping)
 self:T(self.lid.."SetDefaultCAPGrouping")
 self.capgrouping = Grouping or 2
 return self
end

--- Set default range planes can fly from their homebase in NM
-- @param #EASYGCICAP self
-- @param #number Range Range defaults to 100 NM
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultMissionRange(Range)
  self:T(self.lid.."SetDefaultMissionRange")
  self.missionrange = Range or 100
  return self
end

--- Set default turnover times for squadrons in minutes
-- @param #EASYGCICAP self
-- @param #number MaintenanceTime Time in minutes it takes until a flight is combat ready again. Default is 5 min.
-- @param #number RepairTime Time in minutes it takes to repair a flight for each life point taken. Default is 10 min.
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultTurnoverTime(MaintenanceTime,RepairTime)
  self:T(self.lid.."SetDefaultTurnoverTime")
  self.maintenancetime=MaintenanceTime or 5
  self.repairtime=RepairTime or 10
  return self
end

--- Set default number of airframes standing by for intercept tasks (visible on the airfield)
-- @param #EASYGCICAP self
-- @param #number Airframes defaults to 2
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultNumberAlert5Standby(Airframes)
  self:T(self.lid.."SetDefaultNumberAlert5Standby")
  self.noalert5 = math.abs(Airframes) or 2
  return self
end

--- Set default engage range for intruders detected by CAP flights in NM.
-- @param #EASYGCICAP self
-- @param #number Range defaults to 50NM
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultEngageRange(Range)
  self:T(self.lid.."SetDefaultEngageRange")
  self.engagerange = Range or 50
  return self
end

--- Set default overhead for intercept calculations
-- @param #EASYGCICAP self
-- @param #number Overhead The overhead to use.
-- @return #EASYGCICAP self
-- @usage Either a CAP Plane or a newly spawned GCI plane will take care of intruders. Standard overhead is 0.75, i.e. a group of 3 intrudes will
-- be managed by 2 planes from the assigned AirWing. There is an maximum missions limitation per AirWing, so we do not spam the skies.
function EASYGCICAP:SetDefaultOverhead(Overhead)
  self:T(self.lid.."SetDefaultOverhead")
  self.overhead = Overhead or 0.75
  return self
end

--- Set default despawning after landing.
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultDespawnAfterLanding()
  self:T(self.lid.."SetDefaultDespawnAfterLanding")
  self.DespawnAfterLanding = true
  self.DespawnAfterHolding = false
  return self
end

--- Set default despawning after holding (despawn in air close to AFB).
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self
function EASYGCICAP:SetDefaultDespawnAfterHolding()
  self:T(self.lid.."SetDefaultDespawnAfterLanding")
  self.DespawnAfterLanding = false
  self.DespawnAfterHolding = true
  return self
end

--- Set CAP mission start to vary randomly between Start end End seconds.
-- @param #EASYGCICAP self
-- @param #number Start
-- @param #number End 
-- @return #EASYGCICAP self
function EASYGCICAP:SetCapStartTimeVariation(Start, End)
  self.capOptionVaryStartTime = Start or 5
  self.capOptionVaryEndTime = End or 60
  return self
end

--- Set which target types CAP flights will prefer to engage, defaults to {"Air"}
-- @param #EASYGCICAP self
-- @param #table types Table of comma separated #string entries, defaults to {"Air"} (everything that flies and is not a weapon). Useful other options are e.g. {"Bombers"}, {"Fighters"}, 
-- or {"Helicopters"} or combinations like {"Bombers", "Fighters", "UAVs"}. See [Hoggit Wiki](https://wiki.hoggitworld.com/view/DCS_enum_attributes).
-- @return #EASYGCICAP self
function EASYGCICAP:SetCAPEngageTargetTypes(types)
  self.EngageTargetTypes = types or {"Air"}
  return self
end

--- Add an AirWing to the manager
-- @param #EASYGCICAP self
-- @param #string Airbasename
-- @param #string Alias
-- @return #EASYGCICAP self 
function EASYGCICAP:AddAirwing(Airbasename, Alias)
  self:T(self.lid.."AddAirwing "..Airbasename)
  
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
  self:T(self.lid.."_CreateAirwings")
  for airbase,data in pairs(self.ManagedAW) do
    local wing = data -- #EASYGCICAP.Wing
    local afb = wing.AirbaseName
    local alias = wing.Alias
    --local cz = wing.CapZoneName
    self:_AddAirwing(airbase,alias)
  end
  return self
end

--- (Internal) Create and add another AirWing to the manager
-- @param #EASYGCICAP self
-- @param #string Airbasename
-- @param #string Alias
-- @return #EASYGCICAP self 
function EASYGCICAP:_AddAirwing(Airbasename, Alias)
  self:T(self.lid.."_AddAirwing "..Airbasename)
  
  local CapFormation = self.CapFormation
  local DespawnAfterLanding = self.DespawnAfterLanding
  local DespawnAfterHolding = self.DespawnAfterHolding
  
  -- Check STATIC name
  local check = STATIC:FindByName(Airbasename,false) or UNIT:FindByName(Airbasename)
  if check == nil then
    MESSAGE:New(self.lid.."There's no warehouse static on the map (wrong naming?) for airbase "..tostring(Airbasename).."!",30,"CHECK"):ToAllIf(self.debug):ToLog()
    return
  end
  
  -- Create Airwing
  local CAP_Wing = AIRWING:New(Airbasename,Alias)
  CAP_Wing:SetVerbosityLevel(0)
  CAP_Wing:SetReportOff()
  CAP_Wing:SetMarker(false)
  CAP_Wing:SetAirbase(AIRBASE:FindByName(Airbasename))
  CAP_Wing:SetRespawnAfterDestroyed()
  CAP_Wing:SetNumberCAP(self.capgrouping)
  CAP_Wing:SetCapCloseRaceTrack(true)
    
  if self.showpatrolpointmarks then
    CAP_Wing:ShowPatrolPointMarkers(true)
  end
  
  if self.capOptionVaryStartTime then
    CAP_Wing:SetCapStartTimeVariation(self.capOptionVaryStartTime,self.capOptionVaryEndTime)
  end
  
  if CapFormation then
    CAP_Wing:SetCAPFormation(CapFormation)
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

  CAP_Wing:SetTakeoffType(self.defaulttakeofftype)
  CAP_Wing:SetLowFuelThreshold(0.3)
  CAP_Wing.RandomAssetScore = math.random(50,100)
  CAP_Wing:Start()

  local Intel = self.Intel
  
  local TankerInvisible = self.TankerInvisible
  local engagerange = self.engagerange
  local GoZoneSet = self.GoZoneSet
  local NoGoZoneSet = self.NoGoZoneSet
  local FuelLow = self.FuelLowThreshold or 25
  local FuelCritical = self.FuelCriticalThreshold or 10
  local EngageTypes = self.EngageTargetTypes or {"Air"}
  
  function CAP_Wing:onbeforeFlightOnMission(From, Event, To, Flightgroup, Mission)
    local flightgroup = Flightgroup -- Ops.FlightGroup#FLIGHTGROUP
    if DespawnAfterLanding then
      flightgroup:SetDespawnAfterLanding()
    elseif DespawnAfterHolding then
      flightgroup:SetDespawnAfterHolding()
    end
    flightgroup:SetDestinationbase(AIRBASE:FindByName(Airbasename))
    flightgroup:GetGroup():CommandEPLRS(true,5)
    flightgroup:GetGroup():SetOptionRadarUsingForContinousSearch()
    flightgroup:GetGroup():SetOptionLandingOverheadBreak()
    if Mission.type ~= AUFTRAG.Type.TANKER and Mission.type ~= AUFTRAG.Type.AWACS and Mission.type ~= AUFTRAG.Type.RECON then
      flightgroup:SetDetection(true)
      flightgroup:SetEngageDetectedOn(engagerange,EngageTypes,GoZoneSet,NoGoZoneSet)
      flightgroup:SetOutOfAAMRTB()
      flightgroup:SetFuelLowRTB(true)
      flightgroup:SetFuelLowThreshold(FuelLow)
      flightgroup:SetFuelCriticalRTB(true)
      flightgroup:SetFuelCriticalThreshold(FuelCritical)
      if CapFormation then
        flightgroup:GetGroup():SetOption(AI.Option.Air.id.FORMATION,CapFormation)
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
    if DespawnAfterHolding then
      function flightgroup:onbeforeHolding(From,Event,To)
        self:Despawn(1,true)
      end 
    end
  end
  
  if self.noalert5 > 0 then
    local alert
    if self.ClassName == "EASYGCICAP" then  
      alert = AUFTRAG:NewALERT5(AUFTRAG.Type.INTERCEPT) 
    elseif self.ClassName == "EASYA2G" then
      alert = AUFTRAG:NewALERT5(AUFTRAG.Type.BAI) 
    end
    alert:SetRequiredAssets(self.noalert5)
    alert:SetRepeat(99) 
    CAP_Wing:AddMission(alert)
    table.insert(self.ListOfAuftrag,alert)
  end
    
  self.wings[Airbasename] = { CAP_Wing, AIRBASE:FindByName(Airbasename):GetZone(), Airbasename }
  
  return self 
end

--- Add a CAP patrol point to a Wing
-- @param #EASYGCICAP self
-- @param #string AirbaseName Name of the Wing's airbase
-- @param Core.Point#COORDINATE Coordinate. Can be handed as a Core.Zone#ZONE object (e.g. in case you want  the point to align with a moving zone).
-- @param #number Altitude Defaults to 25000 feet ASL.
-- @param #number Speed  Defaults to 300 knots TAS.
-- @param #number Heading Defaults to 90 degrees (East).
-- @param #number LegLength Defaults to 15 NM.
-- @return #EASYGCICAP self
function EASYGCICAP:AddPatrolPointCAP(AirbaseName,Coordinate,Altitude,Speed,Heading,LegLength)
  self:T(self.lid.."AddPatrolPointCAP")--..Coordinate:ToStringLLDDM())
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

--- Add a RECON patrol point to a Wing
-- @param #EASYGCICAP self
-- @param #string AirbaseName Name of the Wing's airbase
-- @param Core.Point#COORDINATE Coordinate. Can be handed as a Core.Zone#ZONE object (e.g. in case you want  the point to align with a moving zone).
-- @param #number Altitude Defaults to 25000 feet.
-- @param #number Speed  Defaults to 300 knots.
-- @param #number Heading Defaults to 90 degrees (East).
-- @param #number LegLength Defaults to 15 NM.
-- @return #EASYGCICAP self
function EASYGCICAP:AddPatrolPointRecon(AirbaseName,Coordinate,Altitude,Speed,Heading,LegLength)
  self:T(self.lid.."AddPatrolPointRecon "..Coordinate:ToStringLLDDM())
  local EntryCAP = {} -- #EASYGCICAP.CapPoint
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
-- @param #EASYGCICAP self
-- @param #string AirbaseName Name of the Wing's airbase
-- @param Core.Point#COORDINATE Coordinate. Can be handed as a Core.Zone#ZONE object (e.g. in case you want  the point to align with a moving zone).
-- @param #number Altitude Defaults to 25000 feet.
-- @param #number Speed  Defaults to 300 knots.
-- @param #number Heading Defaults to 90 degrees (East).
-- @param #number LegLength Defaults to 15 NM.
-- @return #EASYGCICAP self
function EASYGCICAP:AddPatrolPointTanker(AirbaseName,Coordinate,Altitude,Speed,Heading,LegLength)
  self:T(self.lid.."AddPatrolPointTanker "..Coordinate:ToStringLLDDM())
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

--- Add an AWACS patrol point to a Wing
-- @param #EASYGCICAP self
-- @param #string AirbaseName Name of the Wing's airbase
-- @param Core.Point#COORDINATE Coordinate. Can be handed as a Core.Zone#ZONE object (e.g. in case you want  the point to align with a moving zone).
-- @param #number Altitude Defaults to 25000 feet.
-- @param #number Speed  Defaults to 300 knots.
-- @param #number Heading Defaults to 90 degrees (East).
-- @param #number LegLength Defaults to 15 NM.
-- @return #EASYGCICAP self
function EASYGCICAP:AddPatrolPointAwacs(AirbaseName,Coordinate,Altitude,Speed,Heading,LegLength)
  self:T(self.lid.."AddPatrolPointAwacs "..Coordinate:ToStringLLDDM())
  local EntryCAP = {} -- #EASYGCICAP.CapPoint
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
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self 
function EASYGCICAP:_SetTankerPatrolPoints()
  self:T(self.lid.."_SetTankerPatrolPoints")
  for _,_data in pairs(self.ManagedTK) do
    local data = _data --#EASYGCICAP.CapPoint
    self:T("Airbasename = "..data.AirbaseName)
    if not self.wings[data.AirbaseName] then
      MESSAGE:New(self.lid.."You are trying to create a TANKER point for which there is no wing! "..tostring(data.AirbaseName),30,"CHECK"):ToAllIf(self.debug):ToLog()
      return
    end
    local Wing = self.wings[data.AirbaseName][1] -- Ops.Airwing#AIRWING
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
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self 
function EASYGCICAP:_SetAwacsPatrolPoints()
  self:T(self.lid.."_SetAwacsPatrolPoints")
  for _,_data in pairs(self.ManagedEWR) do
    local data = _data --#EASYGCICAP.CapPoint
    self:T("Airbasename = "..data.AirbaseName)
    if not self.wings[data.AirbaseName] then
      MESSAGE:New(self.lid.."You are trying to create an AWACS point for which there is no wing! "..tostring(data.AirbaseName),30,"CHECK"):ToAllIf(self.debug):ToLog()
      return
    end
    local Wing = self.wings[data.AirbaseName][1] -- Ops.Airwing#AIRWING
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
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self 
function EASYGCICAP:_SetCAPPatrolPoints()
  self:T(self.lid.."_SetCAPPatrolPoints")
  for _,_data in pairs(self.ManagedCP) do
    local data = _data --#EASYGCICAP.CapPoint
    self:T("Airbasename = "..data.AirbaseName)
    if not self.wings[data.AirbaseName] then
      MESSAGE:New(self.lid.."You are trying to create a CAP point for which there is no wing! "..tostring(data.AirbaseName),30,"CHECK"):ToAllIf(self.debug):ToLog()
      return
    end
    local Wing = self.wings[data.AirbaseName][1] -- Ops.Airwing#AIRWING
    local Coordinate = data.Coordinate
    local Altitude = data.Altitude
    local Speed = data.Speed 
    local Heading = data.Heading
    local LegLength = data.LegLength
    local Zone = _data.Zone
    if Zone then
        Wing:AddPatrolPointCAP(Zone,Altitude,Speed,Heading,LegLength)
    else
        Wing:AddPatrolPointCAP(Coordinate,Altitude,Speed,Heading,LegLength)
    end
  end
  
  return self
end

--- (Internal) Set actual PatrolPoints from the list
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self 
function EASYGCICAP:_SetReconPatrolPoints()
  self:T(self.lid.."_SetReconPatrolPoints")
  for _,_data in pairs(self.ManagedREC) do
    local data = _data --#EASYGCICAP.CapPoint
    self:T("Airbasename = "..data.AirbaseName)
    if not self.wings[data.AirbaseName] then
      MESSAGE:New(self.lid.."You are trying to create a RECON point for which there is no wing! "..tostring(data.AirbaseName),30,"CHECK"):ToAllIf(self.debug):ToLog()
      return
    end
    local Wing = self.wings[data.AirbaseName][1] -- Ops.Airwing#AIRWING
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
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self 
function EASYGCICAP:_CreateSquads()
  self:T(self.lid.."_CreateSquads")
  for name,data in pairs(self.ManagedSQ) do
    local squad = data -- #EASYGCICAP.Squad
    local SquadName = name
    local TemplateName = squad.TemplateName
    local AirbaseName = squad.AirbaseName
    local AirFrames = squad.AirFrames
    local Skill = squad.Skill
    local Modex = squad.Modex
    local Livery = squad.Livery
    local Frequeny = squad.Frequency
    local Modulation = squad.Modulation
    local TACAN = squad.TACAN
    if squad.Tanker then
      self:_AddTankerSquadron(TemplateName,SquadName,AirbaseName,AirFrames,Skill,Modex,Livery,Frequeny,Modulation,TACAN)
    elseif squad.AWACS then
      self:_AddAWACSSquadron(TemplateName,SquadName,AirbaseName,AirFrames,Skill,Modex,Livery,Frequeny,Modulation)
    elseif squad.RECON then
      self:_AddReconSquadron(TemplateName,SquadName,AirbaseName,AirFrames,Skill,Modex,Livery)
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
-- @param #string Skill (optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYGCICAP self 
function EASYGCICAP:AddSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:T(self.lid.."AddSquadron "..SquadName)
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

--- Add a Recon Squadron to an Airwing of the manager
-- @param #EASYGCICAP self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYGCICAP self 
function EASYGCICAP:AddReconSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:T(self.lid.."AddReconSquadron "..SquadName)
  -- Add Squadron Data
  local EntrySQ = {} -- #EASYGCICAP.Squad
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
-- @param #EASYGCICAP self
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
-- @return #EASYGCICAP self 
function EASYGCICAP:AddTankerSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation, TACAN)
  self:T(self.lid.."AddTankerSquadron "..SquadName)
  -- Add Squadron Data
  local EntrySQ = {} -- #EASYGCICAP.Squad
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
-- @param #EASYGCICAP self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @param #number Frequency (optional) Radio Frequency to be used. 
-- @param #number Modulation (optional) Radio Modulation to be used, e.g. radio.modulation.AM or radio.modulation.FM
-- @return #EASYGCICAP self 
function EASYGCICAP:AddAWACSSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation)
  self:T(self.lid.."AddAWACSSquadron "..SquadName)
  -- Add Squadron Data
  local EntrySQ = {} -- #EASYGCICAP.Squad
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
-- @param #EASYGCICAP self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @param #number Frequency (optional) Radio Frequency to be used. 
-- @param #number Modulation (optional) Radio Modulation to be used, e.g. radio.modulation.AM or radio.modulation.FM
-- @return #EASYGCICAP self 
function EASYGCICAP:_AddSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation)
  self:T(self.lid.."_AddSquadron "..SquadName)
  -- Add Squadrons
  local Squadron_One = SQUADRON:New(TemplateName,AirFrames,SquadName)
  Squadron_One:AddMissionCapability({AUFTRAG.Type.CAP, AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.PATROLRACETRACK, AUFTRAG.Type.ALERT5})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(self.maintenancetime,self.repairtime)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  
  local wing = self.wings[AirbaseName][1] -- Ops.Airwing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.CAP, AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.PATROLRACETRACK, AUFTRAG.Type.ALERT5},75)
  
  return self
end

--- (Internal) Add a Recon Squadron to an Airwing of the manager
-- @param #EASYGCICAP self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @return #EASYGCICAP self 
function EASYGCICAP:_AddReconSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery)
  self:T(self.lid.."_AddReconSquadron "..SquadName)
  -- Add Squadrons
  local Squadron_One = SQUADRON:New(TemplateName,AirFrames,SquadName)
  Squadron_One:AddMissionCapability({AUFTRAG.Type.RECON})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(self.maintenancetime,self.repairtime)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  
  local wing = self.wings[AirbaseName][1] -- Ops.Airwing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.RECON},75)
  
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
-- @param #number Frequency (optional) Radio frequency of the Tanker
-- @param #number Modulation (Optional) Radio modulation of the Tanker
-- @param #number TACAN (Optional) TACAN Channel to be used, will always be an "Y" channel
-- @return #EASYGCICAP self 
function EASYGCICAP:_AddTankerSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation, TACAN)
  self:T(self.lid.."_AddTankerSquadron "..SquadName)
  -- Add Squadrons
  local Squadron_One = SQUADRON:New(TemplateName,AirFrames,SquadName)
  Squadron_One:AddMissionCapability({AUFTRAG.Type.TANKER})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(self.maintenancetime,self.repairtime)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  Squadron_One:SetRadio(Frequency,Modulation)
  if TACAN then
    Squadron_One:AddTacanChannel(TACAN,TACAN)
  end
  
  local wing = self.wings[AirbaseName][1] -- Ops.Airwing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.TANKER},75)
  
  return self
end

--- (Internal) Add a AWACS Squadron to an Airwing of the manager
-- @param #EASYGCICAP self
-- @param #string TemplateName Name of the group template.
-- @param #string SquadName Squadron name - must be unique!
-- @param #string AirbaseName Name of the airbase the airwing resides on, e.g. AIRBASE.Caucasus.Kutaisi
-- @param #number AirFrames Number of available airframes, e.g. 20.
-- @param #string Skill(optional) Skill level, e.g. AI.Skill.AVERAGE
-- @param #string Modex (optional) Modex to be used,e.g. 402.
-- @param #string Livery (optional) Livery name to be used.
-- @param #number Frequency (optional) Radio frequency of the AWACS
-- @param #number Modulation (Optional) Radio modulation of the AWACS
-- @return #EASYGCICAP self 
function EASYGCICAP:_AddAWACSSquadron(TemplateName, SquadName, AirbaseName, AirFrames, Skill, Modex, Livery, Frequency, Modulation)
  self:T(self.lid.."_AddAWACSSquadron "..SquadName)
  -- Add Squadrons
  local Squadron_One = SQUADRON:New(TemplateName,AirFrames,SquadName)
  Squadron_One:AddMissionCapability({AUFTRAG.Type.AWACS})
  --Squadron_One:SetFuelLowRefuel(true)
  Squadron_One:SetFuelLowThreshold(0.3)
  Squadron_One:SetTurnoverTime(self.maintenancetime,self.repairtime)
  Squadron_One:SetModex(Modex)
  Squadron_One:SetLivery(Livery)
  Squadron_One:SetSkill(Skill or AI.Skill.AVERAGE)
  Squadron_One:SetMissionRange(self.missionrange)
  Squadron_One:SetRadio(Frequency,Modulation)
  local wing = self.wings[AirbaseName][1] -- Ops.Airwing#AIRWING
  
  wing:AddSquadron(Squadron_One)
  wing:NewPayload(TemplateName,-1,{AUFTRAG.Type.AWACS},75)
  
  return self
end

--- Add a zone to the accepted zones set.
-- @param #EASYGCICAP self
-- @param Core.Zone#ZONE_BASE Zone
-- @return #EASYGCICAP self 
function EASYGCICAP:AddAcceptZone(Zone)
  self:T(self.lid.."AddAcceptZone")
  self.GoZoneSet:AddZone(Zone)
  return self
end

--- Add a zone to the rejected zones set.
-- @param #EASYGCICAP self
-- @param Core.Zone#ZONE_BASE Zone
-- @return #EASYGCICAP self 
function EASYGCICAP:AddRejectZone(Zone)
  self:T(self.lid.."AddRejectZone")
  self.NoGoZoneSet:AddZone(Zone)
  return self
end

--- Add a zone to the conflict zones set.
-- @param #EASYGCICAP self
-- @param Core.Zone#ZONE_BASE Zone
-- @return #EASYGCICAP self 
function EASYGCICAP:AddConflictZone(Zone)
  self:T(self.lid.."AddConflictZone")
  self.ConflictZoneSet:AddZone(Zone)
  self.GoZoneSet:AddZone(Zone)
  return self
end

--- Function to set corridor zones.
-- @param #EASYGCICAP self
-- @param Core.Set#SET_ZONE CorridorZones Can be handed in as SET\_ZONE or single ZONE object.
-- @return #EASYGCICAP self
function EASYGCICAP:SetCorridorZones(CorridorZones)
  self:T(self.lid .. "SetCorridorZones")
  if CorridorZones and CorridorZones:IsInstanceOf("SET_ZONE") then
    self.corridorzones = CorridorZones
    self.usecorridors = true
  elseif CorridorZones and CorridorZones:IsInstanceOf("ZONE_BASE") then
    if not self.corridorzones then self.corridorzones = SET_ZONE:New() end
    self.corridorzones:AddZone(CorridorZones)
    self.usecorridors = true
  end
  return self
end

--- Function to add one corridor zone.
-- @param #EASYGCICAP self
-- @param Core.Zone#ZONE CorridorZone The ZONE object to be added.
-- @return #EASYGCICAP self
function EASYGCICAP:AddCorridorZone(CorridorZone)
  self:T(self.lid .. "AddCorridorZone")
  self:SetCorridorZones(CorridorZone)
  return self
end

--- Function to set corridor zone floor and ceiling in FEET.
-- @param #EASYGCICAP self
-- @param #number Floor Floor altitude ASL in feet.
-- @param #number Ceiling Ceiling altitude ASL in feet.
-- @return #EASYGCICAP self
function EASYGCICAP:SetCorridorZoneFloorAndCeiling(Floor,Ceiling)
  self.corridorfloor = UTILS.FeetToMeters(Floor)
  self.corridorceiling = UTILS.FeetToMeters(Ceiling)
  return self
end

--- Function to set corridor zone floor and ceiling in METERS.
-- @param #EASYGCICAP self
-- @param #number Floor Floor altitude ASL in meters.
-- @param #number Ceiling Ceiling altitude ASL in meters.
-- @return #EASYGCICAP self
function EASYGCICAP:SetCorridorZoneFloorAndCeilingMeters(Floor,Ceiling)
  self.corridorfloor = Floor    
  self.corridorceiling = Ceiling
  return self
end

--- (Internal) Try to assign the intercept to a FlightGroup already in air and ready.
-- @param #EASYGCICAP self
-- @param #table ReadyFlightGroups ReadyFlightGroups
-- @param Ops.Auftrag#AUFTRAG InterceptAuftrag The Auftrag
-- @param Wrapper.Group#GROUP Group The Target
-- @param #number WingSize Calculated number of Flights
-- @return #boolean assigned
-- @return #number leftover
function EASYGCICAP:_TryAssignIntercept(ReadyFlightGroups,InterceptAuftrag,Group,WingSize)
  self:T("_TryAssignIntercept for size "..WingSize or 1)
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
      FG:AddMission(InterceptAuftrag)
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

--- Here, we'll decide if we need to launch an intercepting flight, and from where
-- @param #EASYGCICAP self
-- @param Ops.Intel#INTEL.Cluster Cluster
-- @return #EASYGCICAP self 
function EASYGCICAP:_AssignIntercept(Cluster)
   -- Here, we'll decide if we need to launch an intercepting flight, and from where
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
    local m = MESSAGE:New(text,10,"CAPGCI"):ToAllIf(self.debug):ToLog()
    -- Do we have a matching airwing?
    if targetairwing then
      local AssetCount = targetairwing:CountAssetsOnMission(MissionTypes,Cohort)
      local missioncount = self:_CountAliveAuftrags()
      -- Enough airframes on mission already?
      self:T(self.lid.." Assets on Mission "..AssetCount)
      if missioncount < MaxAliveMissions then
        local repeats = repeatsonfailure
        local InterceptAuftrag = AUFTRAG:NewINTERCEPT(contact.group)
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
                  success = true
                end
                return success
              end,
              contact.group,
              nogozoneset,
              conflictzoneset
            )
          end
          
          InterceptAuftrag:AddConditionFailure(
          function()
            local failure = false
            if InterceptAuftrag:CountOpsGroups()==0 and InterceptAuftrag:IsExecuting() then failure = true end
            return failure
          end          
          )
          
        table.insert(self.ListOfAuftrag,InterceptAuftrag)
        local assigned, rest = self:_TryAssignIntercept(ReadyFlightGroups,InterceptAuftrag,contact.group,wingsize)
        if not assigned  then
          InterceptAuftrag:SetRequiredAssets(rest)
          targetairwing:AddMission(InterceptAuftrag)
        end
        Cluster.mission = InterceptAuftrag
      end
    else
      MESSAGE:New("**** Not enough airframes available or max mission limit reached!",15,"CAPGCI"):ToAllIf(self.debug):ToLog()
    end
   end
end

--- (Internal) Start detection.
-- @param #EASYGCICAP self
-- @return #EASYGCICAP self
function EASYGCICAP:_StartIntel()
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
  
  if self.usecorridors == true then
    BlueIntel:SetCorridorZones(self.corridorzones)
    if self.corridorfloor or self.corridorceiling then
      BlueIntel:SetCorridorLimits(self.corridorfloor,self.corridorceiling)
    end
  end
  
  BlueIntel:Start()
  
  if self.debug then 
    BlueIntel.debug = true
  end
  
  local function AssignCluster(Cluster)
    self:_AssignIntercept(Cluster)
  end
  
  function BlueIntel:onbeforeNewCluster(From,Event,To,Cluster)
    AssignCluster(Cluster)
  end
  
  self.Intel = BlueIntel  
  return self
end

-------------------------------------------------------------------------
-- TODO FSM Functions
-------------------------------------------------------------------------

--- (Internal) FSM Function onafterStart
-- @param #EASYGCICAP self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #EASYGCICAP self
function EASYGCICAP:onafterStart(From,Event,To)
  self:T({From,Event,To})
  self:_StartIntel()
  self:_CreateAirwings()
  self:_CreateSquads()
  self:_SetCAPPatrolPoints()
  self:_SetTankerPatrolPoints()
  self:_SetAwacsPatrolPoints()
  self:_SetReconPatrolPoints()
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
  self:T({From,Event,To})
  -- cleanup
  local cleaned = false
  local cleanlist = {}
  for _,_auftrag in pairs(self.ListOfAuftrag) do
    local auftrag = _auftrag -- Ops.Auftrag#AUFTRAG
    if auftrag and (not (auftrag:IsCancelled() or auftrag:IsDone() or auftrag:IsOver())) then
      table.insert(cleanlist,auftrag)
      cleaned = true
    end
  end
  if cleaned == true then
    self.ListOfAuftrag = nil
    self.ListOfAuftrag = cleanlist
  end
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
  local interceptmission = 0
  local reconmission = 0
  local awacsmission = 0
  local tankermission = 0
  for _,_wing in pairs(self.wings) do
    local count = _wing[1]:CountAssetsOnMission(MissionTypes,Cohort)
    local count2 = _wing[1]:CountAssets(true,MissionTypes,Attributes)
    capmission = capmission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.GCICAP,AUFTRAG.Type.PATROLRACETRACK})
    interceptmission = interceptmission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.INTERCEPT})
    reconmission = reconmission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.RECON})
    awacsmission = awacsmission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.AWACS})
    tankermission = tankermission + _wing[1]:CountMissionsInQueue({AUFTRAG.Type.TANKER})
    assets = assets + count
    instock = instock + count2
    local assetsonmission = _wing[1]:GetAssetsOnMission({AUFTRAG.Type.ALERT5, AUFTRAG.Type.GCICAP,AUFTRAG.Type.PATROLRACETRACK})
    -- update ready groups
    self.ReadyFlightGroups = nil
    self.ReadyFlightGroups = {}
    for _,_asset in pairs(assetsonmission or {}) do
      local asset = _asset -- Functional.Warehouse#WAREHOUSE.Assetitem
      local FG = asset.flightgroup -- Ops.FlightGroup#FLIGHTGROUP
      if FG then
        local name = FG:GetName()
        local engage = FG:IsEngaging()
        local hasmissiles = FG:IsOutOfMissiles() == nil and true or false
        local isalert5 = (FG:GetMissionCurrent() ~= nil and FG:GetMissionCurrent().type == AUFTRAG.Type.ALERT5) and true or false 
        local ready = hasmissiles and FG:IsFuelGood() and (FG:IsAirborne() or isalert5)
        --self:T(string.format("Flightgroup %s Engaging = %s Ready = %s",tostring(name),tostring(engage),tostring(ready)))
        if ready then
          self.ReadyFlightGroups[name] = FG
        end
      end
    end
  end
  if self.Monitor then
    local threatcount = #self.Intel.Clusters or 0
    local text =  "GCICAP "..self.alias
    text = text.."\nWings: "..wings.."\nSquads: "..squads.."\nCapPoints: "..caps.."\nAssets on Mission: "..assets.."\nAssets in Stock: "..instock
    text = text.."\nThreats: "..threatcount
    text = text.."\nAirWing managed Missions: "..capmission+awacsmission+tankermission+reconmission
    text = text.."\n - CAP: "..capmission
    text = text.."\n - AWACS: "..awacsmission
    text = text.."\n - TANKER: "..tankermission
    text = text.."\n - Recon: "..reconmission
    text = text.."\nSelf managed Missions:"
    text = text.."\n - Mission Limit: "..self.MaxAliveMissions
    text = text.."\n - Alert5+Intercept "..self:_CountAliveAuftrags()
    MESSAGE:New(text,15,"GCICAP"):ToAll():ToLogIf(self.debug)
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
  self:T({From,Event,To})
  self.Intel:Stop()
  for _,_wing in pairs(self.wings or {}) do
    _wing:Stop()
  end
  return self
end
