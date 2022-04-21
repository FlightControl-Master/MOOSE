--- **Ops** - AWACS
--
-- ===
--
-- ## Main Features:
--
--  * TBD
--
-- ===
--
-- ## Example Missions:
-- 
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/).
--       
-- ===
-- 
-- ### Author: **applevangelist**
-- Last Update April 2022
--
-- ===
-- @module Ops.AWACS
-- @image MOOSE.JPG

do
--- Ops AWACS Class
-- @type AWACS
-- @field #string ClassName Name of this class.
-- @field #string version Versioning.
-- @field #string lid LID for log entries.
-- @field #number coalition Colition side.
-- @field #string coalitiontxt = "blue"
-- @field Core.Zone#ZONE OpsZone,
-- @field Core.Zone#ZONE AnchorZone,
-- @field #number Frequency
-- @field #number Modulation
-- @field Wrapper.Airbase#AIRBASE Airbase
-- @field Ops.AirWing#AIRWING AirWing
-- @field #number AwacsAngels
-- @field Core.Zone#ZONE OrbitZone
-- @field #number CallSign
-- @field #number CallSignNo
-- @field #boolean debug
-- @field #number verbose
-- @field #table ManagedGrps
-- @field #number ManagedGrpID
-- @field #number ManagedTaskID
-- @field Utilities.FiFo#FIFO AnchorStacks
-- @field Utilities.FiFo#FIFO CAPIdleAI
-- @field Utilities.FiFo#FIFO CAPIdleHuman
-- @field Utilities.FiFo#FIFO TaskedCAPAI
-- @field Utilities.FiFo#FIFO TaskedCAPHuman
-- @field Utilities.FiFo#FIFO OpenTasks
-- @field Utilities.FiFo#FIFO ManagedTasks
-- @field Utilities.FiFo#FIFO PictureAO
-- @field Utilities.FiFo#FIFO PictureEWR
-- @field Utilities.FiFo#FIFO Contacts
-- @field #table CatchAllMissions
-- @field #table CatchAllFGs
-- @field #number Countactcounter
-- @field Utilities.FiFo#FIFO ContactsAO
-- @field Utilities.FiFo#FIFO RadioQueue
-- @field Utilities.FiFo#FIFO CAPAirwings
-- @field #number AwacsTimeOnStation
-- @field #number AwacsTimeStamp
-- @field #number EscortsTimeOnStation
-- @field #number EscortsTimeStamp
-- @field #string AwacsROE
-- @field #string AwacsROT
-- @field Ops.Auftrag#AUFTRAG AwacsMission
-- @field Ops.Auftrag#AUFTRAG EscortMission
-- @field Ops.Auftrag#AUFTRAG AwacsMissionReplacement
-- @field Ops.Auftrag#AUFTRAG EscortMissionReplacement
-- @field Utilities.FiFo#FIFO AICAPMissions FIFO for Ops.Auftrag#AUFTRAG for AI CAP
-- @field #boolean MenuStrict
-- @field #number MaxAIonCAP
-- @field #number AIonCAP
-- @field #boolean ShiftChangeAwacsFlag
-- @field #boolean ShiftChangeEscortsFlag
-- @field #boolean ShiftChangeAwacsRequested
-- @field #boolean ShiftChangeEscortsRequested
-- @field #AWACS.MonitoringData MonitoringData
-- @field #boolean MonitoringOn
-- @field Core.Set#SET_GROUP clientset
-- @field Utilities.FiFo#FIFO FlightGroups
-- @extends Core.Fsm#FSM

---
--
-- @field #AWACS
AWACS = {
  ClassName = "AWACS", -- #string
  version = "alpha 0.0.6", -- #string
  lid = "", -- #string
  coalition = coalition.side.BLUE, -- #number
  coalitiontxt = "blue", -- #string
  OpsZone = nil,
  AnchorZone = nil,
  AirWing = nil,
  Frequency = 271, -- #number
  Modulation = radio.modulation.AM, -- #number
  Airbase = nil,
  AwacsAngels = 25, -- orbit at 25'000 ft
  OrbitZone = nil,
  CallSign = CALLSIGN.AWACS.Magic, -- #number
  CallSignNo = 1, -- #number
  debug = true,
  verbose = true,
  ManagedGrps = {},
  ManagedGrpID = 0, -- #number
  ManagedTaskID = 0, -- #number
  AnchorStacks = {}, -- Utilities.FiFo#FIFO
  CAPIdleAI = {},
  CAPIdleHuman = {},
  TaskedCAPAI = {},
  TaskedCAPHuman = {},
  OpenTasks = {}, -- Utilities.FiFo#FIFO
  ManagedTasks = {}, -- Utilities.FiFo#FIFO
  PictureAO = {}, -- Utilities.FiFo#FIFO
  PictureEWR = {}, -- Utilities.FiFo#FIFO
  Contacts = {}, -- Utilities.FiFo#FIFO
  Countactcounter = 0,
  ContactsAO = {}, -- Utilities.FiFo#FIFO
  RadioQueue = {}, -- Utilities.FiFo#FIFO
  AwacsTimeOnStation = 1,
  AwacsTimeStamp = 0,
  EscortsTimeOnStation = 0.5,
  EscortsTimeStamp = 0,
  CAPTimeOnStation = 4,
  AwacsROE = "",
  AwacsROT = "",
  MenuStrict = true,
  MaxAIonCAP = 4,
  AIonCAP = 0,
  AICAPMissions = {}, -- Utilities.FiFo#FIFO
  ShiftChangeAwacsFlag = false,
  ShiftChangeEscortsFlag = false,
  ShiftChangeAwacsRequested = false,
  ShiftChangeEscortsRequested = false,
  CAPAirwings = {},  -- Utilities.FiFo#FIFO
  MonitoringData = {},
  MonitoringOn = true,
  FlightGroups = {},
  AwacsMission = nil,
  AwacsInZone = false, -- not yet arrived or gone again
  AwacsReady = false,
  CatchAllMissions = {},
  CatchAllFGs = {},
}

---
--@field CallSignClear
AWACS.CallSignClear = {
    [1]="Overlord",
    [2]="Magic",
    [3]="Wizard",
    [4]="Focus",
    [5]="Darkstar",
}

---
-- @field AnchorNames
AWACS.AnchorNames = {
  [1] = "One",
  [2] = "Two",
  [3] = "Three",
  [4] = "Four",
  [5] = "Five",
  [6] = "Six",
  [7] = "Seven",
  [8] = "Eight",
  [9] = "Nine",
  [10] = "Ten",
}

---
-- @field Phonetic
AWACS.Phonetic =
{
  [1] = 'Alpha',
  [2] = 'Bravo',
  [3] = 'Charlie',
  [4] = 'Delta',
  [5] = 'Echo',
  [6] = 'Foxtrot',
  [7] = 'Golf',
  [8] = 'Hotel',
  [9] = 'India',
  [10] = 'Juliett',
  [11] = 'Kilo',
  [12] = 'Lima',
  [13] = 'Mike',
  [14] = 'November',
  [15] = 'Oscar',
  [16] = 'Papa',
  [17] = 'Quebec',
  [18] = 'Romeo',
  [19] = 'Sierra',
  [20] = 'Tango',
  [21] = 'Uniform',
  [22] = 'Victor',
  [23] = 'Whiskey',
  [24] = 'Xray',
  [25] = 'Yankee',
  [26] = 'Zulu',
}

---
-- @field Shipsize
AWACS.Shipsize =
{
  [1] = "Singleton",
  [2] = "Two-Ship",
  [3] = "Heavy",
}

---
-- @field ROE
AWACS.ROE = {
  POLICE = "Police",
  VID = "Visual ID",
  IFF = "IFF",
  BVR = "Beyond Visual Range",
}

---
-- @field AWACS.ROT
AWACS.ROT = {
    PASSIVE = "Passive Defense",
    ACTIVE = "Active Defense",
    LOCK = "Lock",
    RETURNFIRE = "Return Fire",
    OPENFIRE = "Open Fire",
 }
 
---
--@field THREATLEVEL -- can be 1-10, thresholds
AWACS.THREATLEVEL = {
  GREEN = 3,
  AMBER = 7,
  RED = 10,
}

---
-- @type AWACS.MonitoringData
-- @field #string AwacsStateMission
-- @field #string AwacsStateFG
-- @field #boolean AwacsShiftChange 
-- @field #string EscortsStateMission
-- @field #string EscortsStateFG
-- @field #boolean EscortsShiftChange
-- @field #number AICAPMax
-- @field #number AICAPCurrent
-- @field #number Airwings
-- @field #number Players
-- @field #number PlayersCheckedin

---
-- @type AWACS.MenuStructure
-- @field #boolean menuset
-- @field #string groupname
-- @field Core.Menu#MENU_GROUP basemenu
-- @field Core.Menu#MENU_GROUP_COMMAND checkin
-- @field Core.Menu#MENU_GROUP_COMMAND checkout
-- @field Core.Menu#MENU_GROUP_COMMAND picture
-- @field Core.Menu#MENU_GROUP_COMMAND bogeydope
-- @field Core.Menu#MENU_GROUP_COMMAND declare
-- @field Core.Menu#MENU_GROUP_COMMAND showtask

---
-- @type AWACS.ManagedGroup
-- @field Wrapper.Group#GROUP Group
-- @field #string GroupName
-- @field Ops.FlightGroup#FLIGHTGROUP FlightGroup for AI
-- @field #boolean IsPlayer
-- @field #boolean IsAI
-- @field #string CallSign
-- @field #number CurrentAuftrag
-- @field #number CurrentTask
-- @field #boolean HasAssignedTask
-- @field #number GID
-- @field #number AnchorStackNo
-- @field #number AnchorStackAngels
-- @field #number ContactCID

--- Contact Data
-- @type AWACS.ManagedContact
-- @field #number CID
-- @field Ops.Intelligence#INTEL.Contact Contact
-- @field Ops.Intelligence#INTEL.Cluster Cluster
-- @field #string IFF -- ID'ed or not
-- @field Ops.Target#TARGET Target
-- @field #number LinkedTask --> TID
-- @field #number LinkedGroup --> GID
-- @field #string Status - AWACS.TaskStatus....
-- @field #string TargetGroupNaming

---
-- @type AWACS.TaskDescription
AWACS.TaskDescription = {
  ANCHOR = "Anchor",
  REANCHOR = "Re-Anchor",
  VID = "VID",
  IFF = "IFF",
  INTERCEPT = "Intercept",
  SWEEP = "Sweep",
  RTB = "RTB",
}

---
-- @type AWACS.TaskStatus
AWACS.TaskStatus = {
  IDLE = "Idle",
  UNASSIGNED = "Unassigned",
  REQUESTED = "Requested",
  ASSIGNED = "Assigned",
  EXECUTING = "Executing",
  SUCCESS = "Success",
  FAILED = "Failed",
  DEAD = "Dead",
}

---
-- @type AWACS.ManagedTask
-- @field #number TID
-- @field #number AssignedGroupID
-- @field #boolean IsPlayerTask
-- @field #boolean IsUnassigned
-- @field Ops.Target#TARGET Target
-- @field Ops.Auftrag#AUFTRAG Auftrag
-- @field #AWACS.TaskStatus Status
-- @field #AWACS.TaskDescription ToDo
-- @field #string ScreenText Long descrition
-- @field Ops.Intelligence#INTEL.Contact Contact
-- @field Ops.Intelligence#INTEL.Cluster Cluster
-- @field #number CurrentAuftrag

---
-- @type AWACS.AnchorAssignedEntry
-- @field #number ID
-- @field #number Angels

---
-- @type AWACS.AnchorData
-- @field #number AnchorBaseAngels
-- @field #boolean AnchorZone
-- @field Core.Point#COORDINATE AnchorZoneCoordinate
-- @field #boolean AnchorZoneCoordinateText
-- @field Utilities.FiFo#FIFO AnchorAssignedID FiFo of #AWACS.AnchorAssignedEntry
-- @field Utilities.FiFo#FIFO Anchors FiFo of available stacks

---
--@type RadioEntry
--@field #string TextTTS
--@field #string TextScreen
--@field #boolean IsNew
--@field #boolean IsGroup
--@field #boolean GroupID
--@field #number Duration
--@field #boolean ToScreen
--@field #boolean FromAI

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO-List
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DEBUG - Escorts via AirWing not staying on
-- TODO - Link (multiple) AWs to the AWACS Controller
-- DONE - Use AO as Anchor of Bulls, AO as default
-- DONE - SRS TTS output
-- DONE - Check-In/Out Humans
-- DONE - Check-In/Out AI
-- DONE - Picture
-- TODO - TripWire
-- DONE - Radio Menu
-- DONE - Intel Detection
-- TODO - CHIEF / COMMANDER / AIRWING connection?
-- TODO - LotATC / IFF
-- DONE - ROE
-- TODO - Player & AI tasking
-- DONE - Anchor Stack Management
-- TODO - Reporting
-- TODO - Missile launch callout
-- TODO - Localization
-- DONE - Shift Length AWACS/AI
-- DEBUG - Shift Change, Change on asset RTB or dead or mission done
-- TODO - Borders for INTEL
-- TODO - FIFO for checkin/checkout and tasking
-- TODO - Event detection
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO Constructor

--- Set up a new AI AWACS.
-- @param #AWACS self
-- @param #string Name Name of this AWACS for the radio menu.
-- @param #string AirWing The core Ops.AirWing#AIRWING managing the AWACS, Escort and (optionally) AI CAP planes for us.
-- @param #number Coalition Coalition, e.g. coalition.side.BLUE. Can also be passed as "blue", "red" or "neutral".
-- @param #string AirbaseName Name of the home airbase.
-- @param #string AwacsOrbit Name of the round, mission editor created zone where this AWACS orbits.
-- @param #string OpsZone Name of the round, mission editor created operations zone this AWACS controls. Can be passed as #ZONE_POLYGON
-- @param #string AnchorZone Name of the round, mission editor created anchor zone where CAP groups will be stacked.
-- @param #number Frequency Radio frequency, e.g. 271.
-- @param #number Modulation Radio modulation, e.g. radio.modulation.AM or radio.modulation.FM.
-- @return #AWACS self
function AWACS:New(Name,AirWing,Coalition,AirbaseName,AwacsOrbit,OpsZone,AnchorZone,Frequency,Modulation)
    -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New())
  
  --set Coalition
  if Coalition and type(Coalition)=="string" then
    if Coalition=="blue" then
      self.coalition=coalition.side.BLUE
      self.coalitiontxt = Coalition
    elseif Coalition=="red" then
      self.coalition=coalition.side.RED
      self.coalitiontxt = Coalition
    elseif Coalition=="neutral" then
      self.coalition=coalition.side.NEUTRAL
      self.coalitiontxt = Coalition
    else
      self:E("ERROR: Unknown coalition in AWACS!")
    end
  else
    self.coalition = Coalition
    self.coalitiontxt = string.lower(UTILS.GetCoalitionName(self.coalition))
  end
  
  -- base setup
  self.Name = Name -- #string
  self.AirWing = AirWing -- Ops.AirWing#AIRWING object
  
  AirWing:SetUsingOpsAwacs(self)
  
  self.CAPAirwings = FIFO:New() -- Utilities.FiFo#FIFO
  self.CAPAirwings:Push(AirWing,1)
  
  self.AwacsFG = nil
  --self.AwacsPayload = PayLoad -- Ops.AirWing#AIRWING.Payload
  self.ModernEra = true -- use of EPLRS
  self.RadarBlur = 10 -- 10% detection precision i.e. 90-110 reported group size
  if type(OpsZone) == "string" then
    self.OpsZone = ZONE:New(OpsZone) -- Core.Zone#ZONE
  elseif type(OpsZone) == "table" and OpsZone.ClassName and OpsZone.ClassName == "ZONE_POLYGON" then
    self.OpsZone = OpsZone
  else
    self:E("AWACS - Invalid OpsZone passed!")
    return
  end
  
  self.AOCoordinate = self.OpsZone:GetCoordinate()
  self.UseBullsAO = false
  self.ControlZoneRadius = 100 -- nm
  self.AnchorZone = ZONE:New(AnchorZone) -- Core.Zone#ZONE
  self.Frequency = Frequency or 271 -- #number
  self.Modulation = Modulation or radio.modulation.AM
  self.Airbase = AIRBASE:FindByName(AirbaseName)
  self.AwacsAngels = 25 -- orbit at 25'000 ft
  self.OrbitZone = ZONE:New(AwacsOrbit) -- Core.Zone#ZONE
  self.CallSign = CALLSIGN.AWACS.Magic -- #number
  self.CallSignNo = 1 -- #number
  self.NoHelos = true
  self.MaxAIonCAP = 4
  self.AIRequested = 0
  self.AIonCAP = 0
  self.AICAPMissions = FIFO:New() -- Utilities.FiFo#FIFO
  self.FlightGroups = FIFO:New() -- Utilities.FiFo#FIFO
  self.Countactcounter = 0
  
  local speed = 250
  self.SpeedBase = speed
  self.Speed = UTILS.KnotsToAltKIAS(speed,self.AwacsAngels*1000)
  self.CapSpeedBase = 220
  self.Heading = 0 -- north
  self.Leg = 50 -- nm
  self.invisible = true
  self.immortal = true
  self.callsigntxt = "AWACS"
  
  self.AwacsTimeOnStation = 2
  self.AwacsTimeStamp = 0
  self.EscortsTimeOnStation = 2
  self.EscortsTimeStamp = 0
  self.ShiftChangeTime = 0.25 -- 15mins
  self.ShiftChangeAwacsFlag = false
  self.ShiftChangeEscortsFlag = false
  self.CAPTimeOnStation = 4
  
  self.AwacsMission = nil
  self.AwacsInZone = false -- not yet arrived or gone again
  self.AwacsReady = false
  
  self.AwacsROE = AWACS.ROE.POLICE
  self.AwacsROT = AWACS.ROT.PASSIVE
  
  self.MenuStrict = true
  
  -- Escorts
  self.HasEscorts = false
  self.EscortTemplate = ""
  
  -- SRS
  self.PathToSRS = "C:\\Program Files\\DCS-SimpleRadio-Standalone"
  self.Gender = "male"
  self.Culture = "en-US"
  self.Voice = nil
  self.Port = 5002
  self.RadioQueue = FIFO:New() -- Utilities.FiFo#FIFO
  self.maxspeakentries = 3
  
  self.CAPGender = "male"
  self.CAPCulture = "en-US"
  self.CAPVoice = nil
  
  -- Client SET  
  self.clientset = SET_GROUP:New():FilterCategoryAirplane():FilterCoalitions(self.coalitiontxt):FilterStart()
  
  -- managed groups
  self.ManagedGrps = {} -- #table of #AWACS.ManagedGroup entries
  self.ManagedGrpID = 0  
  
  self.AICAPCAllName = CALLSIGN.Aircraft.Colt
  self.AICAPCAllNumber = 0
  
  -- Anchor stacks init
  self.AnchorStacks = FIFO:New() -- Utilities.FiFo#FIFO
  self.AnchorBaseAngels = 22
  self.AnchorStackDistance = 2
  self.AnchorMaxStacks = 4
  self.AnchorMaxAnchors = 2
  self.AnchorMaxZones = 6
  self.AnchorCurrZones = 1
  self.AnchorTurn = -(360/self.AnchorMaxZones)

  self:_CreateAnchorStack()

  -- Task lists
  self.ManagedTasks = FIFO:New() -- Utilities.FiFo#FIFO
  --self.OpenTasks = FIFO:New() -- Utilities.FiFo#FIFO
  
  -- Monitoring, init
  local MonitoringData = {} -- #AWACS.MonitoringData
  MonitoringData.AICAPCurrent = 0
  MonitoringData.AICAPMax = self.MaxAIonCAP
  MonitoringData.Airwings = 1
  MonitoringData.PlayersCheckedin = 0
  MonitoringData.Players = 0 
  MonitoringData.AwacsShiftChange = false
  MonitoringData.AwacsStateFG = "unknown"
  MonitoringData.AwacsStateMission = "unknown"
  MonitoringData.EscortsShiftChange = false
  MonitoringData.EscortsStateFG= "unknown"
  MonitoringData.EscortsStateMission = "unknown"
  self.MonitoringOn = true -- #boolean
  self.MonitoringData = MonitoringData
  
  self.CatchAllMissions = {}
  self.CatchAllFGs = {}
  
  -- Picture, Contacts, Bogeys
  self.PictureAO = FIFO:New() -- Utilities.FiFo#FIFO
  self.PictureEWR = FIFO:New() -- Utilities.FiFo#FIFO
  self.Contacts = FIFO:New() -- Utilities.FiFo#FIFO
  self.ManagedContacts = FIFO:New()
  self.CID = 0
  self.ContactsAO = FIFO:New() -- Utilities.FiFo#FIFO

  -- SET for Intel Detection
  self.DetectionSet=SET_GROUP:New()
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("%s (%s) | ", self.Name, self.coalition and UTILS.GetCoalitionName(self.coalition) or "unknown")
  
    -- Start State.
  self:SetStartState("Stopped")
  
  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "StartUp")     -- Start FSM.
  self:AddTransition("StartUp",       "Started",            "Running")    
  self:AddTransition("*",             "Status",             "*")           -- Status update.
  self:AddTransition("*",             "CheckedIn",          "*") 
  self:AddTransition("*",             "CheckedOut",         "*") 
  self:AddTransition("*",             "AssignAnchor",       "*") 
  self:AddTransition("*",             "AssignedAnchor",     "*")
  self:AddTransition("*",             "NewCluster",         "*")
  self:AddTransition("*",             "NewContact",         "*")
  self:AddTransition("*",             "LostCluster",        "*")
  self:AddTransition("*",             "LostContact",        "*")
  self:AddTransition("*",             "CheckRadioQueue",    "*")
  self:AddTransition("*",             "EscortShiftChange",  "*")
  self:AddTransition("*",             "AwacsShiftChange",   "*")
  self:AddTransition("*",             "FlightOnMission",    "*")
  --
  self:AddTransition("*",             "Stop",               "Stopped")     -- Stop FSM.
  
  -- self:__Start(math.random(2,5))
  
  local text = string.format("%sAWACS Version %s Initiated",self.lid,self.version)
  
  self:I(text)
  
  -- debug zone markers
  if self.debug then
    self.OpsZone:DrawZone(-1,{1,0,0},1,{1,0,0},0.2,5,true)
    MARKER:New(self.OpsZone:GetCoordinate(),"AO Zone"):ToAll()
    self.AnchorZone:DrawZone(-1,{0,0,1},1,{0,0,1},0.2,5,true)
    MARKER:New(self.AnchorZone:GetCoordinate(),"Anchor Zone"):ToAll()
    self.OrbitZone:DrawZone(-1,{0,1,0},1,{0,1,0},0.2,5,true)
    MARKER:New(self.OrbitZone:GetCoordinate(),"Orbit Zone"):ToAll()
  end
  
  return self
end

-- TODO Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- [User] Get AWACS Name
-- @param #AWACS self
-- @return #string Name of this instance
function AWACS:GetName()
  return self.Name or "not set"
end

--- [User] Set AWACS flight details
-- @param #AWACS self
-- @param #number CallSign Defaults to CALLSIGN.AWACS.Magic
-- @param #number CallSignNo Defaults to 1
-- @param #number Angels Defaults to 25 (i.e. 25000 ft)
-- @param #number Speed Defaults to 250kn
-- @param #number Heading Defaults to 0 (North)
-- @param #number Leg Defaults to 25nm
-- @return #AWACS self
function AWACS:SetAwacsDetails(CallSign,CallSignNo,Angels,Speed,Heading,Leg)
  self:T(self.lid.."SetAwacsDetails")
  self.CallSign = CallSign or CALLSIGN.AWACS.Magic
  self.CallSignNo = CallSignNo or 1
  self.Angels = Angels or 25
  local speed = Speed or 250
  self.SpeedBase = speed
  self.Speed = UTILS.KnotsToAltKIAS(speed,self.Angels*1000)
  self.Heading = Heading or 0
  self.Leg = Leg or 25
  return self
end

--- [User] Add a radar GROUP object to the INTEL detection SET_GROUP
-- @param Wrapper.Group#GROUP Group The GROUP to be added. Can be passed as SET_GROUP.
-- @return #AWACS self
function AWACS:AddGroupToDetection(Group)
  self:T(self.lid.."AddGroupToDetection")
  if Group and Group.ClassName and Group.ClassName == "GROUP" then
    self.DetectionSet:AddGroup(Group)
  elseif Group and Group.ClassName and Group.ClassName == "SET_GROUP" then
    self.DetectionSet:AddSet(Group)
  end
  return self
end

--- [User] Set AWACS SRS TTS details - see @{#MSRS} for details
-- @param #AWACS self
-- @param #string PathToSRS Defaults to "C:\\Program Files\\DCS-SimpleRadio-Standalone"
-- @param #string Gender Defaults to "male"
-- @param #string Culture Defaults to "en-US"
-- @param #number Port Defaults to 5002
-- @param #string Voice (Optional) Use a specifc voice with the @{#MSRS.SetVoice} function, e.g, `:SetVoice("Microsoft Hedda Desktop")`.
-- Note that this must be installed on your windows system.
-- @return #AWACS self
function AWACS:SetSRS(PathToSRS,Gender,Culture,Port,Voice)
  self:T(self.lid.."SetSRS")
  self.PathToSRS = PathToSRS or "C:\\Program Files\\DCS-SimpleRadio-Standalone"
  self.Gender = Gender or "male"
  self.Culture = Culture or "en-US"
  self.Port = Port or 5002
  self.Voice = Voice 
  return self
end

--- [User] Set AWACS Escorts Template
-- @param #AWACS self
-- @param #number EscortNumber Number of fighther planes to accompany this AWACS. 0 or nil means no escorts.
-- @return #AWACS self
function AWACS:SetEscort(EscortNumber)
  self:T(self.lid.."SetEscort")
  if EscortNumber and EscortNumber > 0 then
    self.HasEscorts = true
    self.EscortNumber = EscortNumber
  end
  return self
end

--- [Internal] Start AWACS Escorts FlightGroup
-- @param #AWACS self
-- @param #boolean Shiftchange This is a shift change call
-- @return #AWACS self
function AWACS:_StartEscorts(Shiftchange)
  self:I(self.lid.."_StartEscorts")
  
  local AwacsFG = self.AwacsFG -- Ops.FlightGroup#FLIGHTGROUP
  local group = AwacsFG:GetGroup()
  local mission = AUFTRAG:NewESCORT(group,{x=-100, y=0, z=200},30,{"Air"})
  self.CatchAllMissions[#self.CatchAllMissions+1] = mission
  
  mission:SetRequiredAssets(self.EscortNumber)
  
  local timeonstation = (self.EscortsTimeOnStation + self.ShiftChangeTime) * 3600 -- hours to seconds
  mission:SetTime(nil,timeonstation)
  
  self.AirWing:AddMission(mission)
  
  if Shiftchange then
    self.EscortMissionReplacement = mission
  else
    self.EscortMission = mission
  end
  
  return self
end

--- [Internal] AWACS further Start Settings
-- @param #AWACS self
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup
-- @param Ops.Auftrag#AUFTRAG Mission
-- @return #AWACS self
function AWACS:_StartSettings(FlightGroup,Mission)
  self:T(self.lid.."_StartSettings")
  
  local Mission = Mission -- Ops.Auftrag#AUFTRAG
  local AwacsFG = FlightGroup -- Ops.FlightGroup#FLIGHTGROUP
  
  -- Is this our Awacs mission?
  if self.AwacsMission:GetName() == Mission:GetName() then
    self:I("Setting up Awacs")
    AwacsFG:SetDefaultRadio(self.Frequency,self.Modulation,false)
    AwacsFG:SwitchRadio(self.Frequency,self.Modulation)
    AwacsFG:SetDefaultAltitude(self.AwacsAngels*1000)
    AwacsFG:SetHomebase(self.Airbase)
    AwacsFG:SetDefaultCallsign(self.CallSign,self.CallSignNo)
    AwacsFG:SetDefaultROE(ENUMS.ROE.WeaponHold)
    AwacsFG:SetDefaultAlarmstate(AI.Option.Ground.val.ALARM_STATE.GREEN)
    AwacsFG:SetDefaultEPLRS(self.ModernEra)
    AwacsFG:SetDespawnAfterLanding()
    AwacsFG:SetFuelLowRTB(true)
    AwacsFG:SetFuelLowThreshold(20)
    
    local group = AwacsFG:GetGroup() -- Wrapper.Group#GROUP
    
    group:SetCommandInvisible(self.invisible)
    group:SetCommandImmortal(self.immortal)
    group:CommandSetCallsign(self.CallSign,self.CallSignNo,2)
    -- Non AWACS does not seem take AWACS CS in DCS Group
    --group:CommandSetCallsign(CALLSIGN.Aircraft.Pig,self.CallSignNo,2)
    
    AwacsFG:SetSRS(self.PathToSRS,self.Gender,self.Culture,self.Voice,self.Port,nil)
    self.callsigntxt = string.format("%s %d %d",AWACS.CallSignClear[self.CallSign],1,self.CallSignNo)
    
    --local text = string.format("%s starting for AO %s control.",self.callsigntxt,self.OpsZone:GetName() or "AO")
    local text = string.format("%s. All stations, SUNRISE SUNRISE SUNRISE, %s.",self.callsigntxt,self.callsigntxt)
    self:T(self.lid..text)
    
    AwacsFG:RadioTransmission(text,1,false)
    
    self.AwacsFG = AwacsFG 
    
    self:__CheckRadioQueue(10)
    
    if self.HasEscorts then
      --mission:SetRequiredEscorts(self.EscortNumber)
      self:_StartEscorts()
    end
    
    self.AwacsTimeStamp = timer.getTime()
    self.EscortsTimeStamp = timer.getTime()
    
    self.AwacsReady = true
    -- set FSM to started
    self:Started()
    
  elseif self.ShiftChangeAwacsRequested and self.AwacsMissionReplacement and self.AwacsMissionReplacement:GetName() == Mission:GetName() then
    self:I("Setting up Awacs Replacement")
    -- manage AWACS Replacement
    AwacsFG:SetDefaultRadio(self.Frequency,self.Modulation,false)
    AwacsFG:SwitchRadio(self.Frequency,self.Modulation)
    AwacsFG:SetDefaultAltitude(self.AwacsAngels*1000)
    AwacsFG:SetHomebase(self.Airbase)
    self.CallSignNo = self.CallSignNo+1
    AwacsFG:SetDefaultCallsign(self.CallSign,self.CallSignNo)
    AwacsFG:SetDefaultROE(ENUMS.ROE.WeaponHold)
    AwacsFG:SetDefaultAlarmstate(AI.Option.Ground.val.ALARM_STATE.GREEN)
    AwacsFG:SetDefaultEPLRS(self.ModernEra)
    AwacsFG:SetDespawnAfterLanding()
    AwacsFG:SetFuelLowRTB(true)
    AwacsFG:SetFuelLowThreshold(20)
    
    local group = AwacsFG:GetGroup() -- Wrapper.Group#GROUP
    
    group:SetCommandInvisible(self.invisible)
    group:SetCommandImmortal(self.immortal)
    group:CommandSetCallsign(self.CallSign,self.CallSignNo,2)
    -- Non AWACS does not seem take AWACS CS in DCS Group
    -- group:CommandSetCallsign(CALLSIGN.Aircraft.Pig,self.CallSignNo,2)
    
    AwacsFG:SetSRS(self.PathToSRS,self.Gender,self.Culture,self.Voice,self.Port,nil)
    self.callsigntxt = string.format("%s %d %d",AWACS.CallSignClear[self.CallSign],1,self.CallSignNo)
    
    local text = string.format("%s shift change for AO %s control.",self.callsigntxt,self.OpsZone:GetName() or "AO")
    self:T(self.lid..text)
    
    AwacsFG:RadioTransmission(text,1,false)
    
    self.AwacsFG = AwacsFG 
    
    --self:__CheckRadioQueue(10)
    
    if self.HasEscorts then
      --mission:SetRequiredEscorts(self.EscortNumber)
      self:_StartEscorts(true)
    end
    
    self.AwacsTimeStamp = timer.getTime()
    self.EscortsTimeStamp = timer.getTime()
    
    self.AwacsReady = true
    
  end
  return self
end

--- [Internal] Check if a group has checked in
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to check
-- @return #number ID
-- @return #boolean CheckedIn
function AWACS:_GetManagedGrpID(Group)
  self:T(self.lid.."_GetManagedGrpID for "..Group:GetName())
  local GID = 0
  local Outcome = false
  local nametocheck = Group:GetName()
  local managedgrps = self.ManagedGrps or {}
  for _,_managed in pairs (managedgrps) do
    local managed = _managed -- #AWACS.ManagedGroup
    if managed.GroupName == nametocheck then
      GID = managed.GID
      Outcome = true
    end
  end
  return GID, Outcome
end

--- [Internal] AWACS Get TTS compatible callsign
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @param #number GID GID to use
-- @return #string Callsign
function AWACS:_GetCallSign(Group,GID)
  self:I(self.lid.."_GetCallSign - GID "..tostring(GID))
  
  if GID and type(GID) == "number" and GID > 0 then
    local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    self:T("Saved Callsign for TTS = " .. tostring(managedgroup.CallSign))
    return managedgroup.CallSign
  end
  
  local callsign = ""
  local shortcallsign = Group:GetCallsign() or "unknown11"-- e.g.Uzi11, but we want Uzi 1 1
  local callnumber = string.match(shortcallsign, "(%d+)$" ) or "unknown11"
  local callnumbermajor = string.char(string.byte(callnumber,1))
  local callnumberminor = string.char(string.byte(callnumber,2))
  callsign = string.gsub(shortcallsign,callnumber,"").." "..callnumbermajor.." "..callnumberminor
  self:I("Generated Callsign for TTS = " .. callsign)
  return callsign
end

--- [Internal] AWACS Speak Picture AO/EWR entries
-- @param #AWACS self
-- @param #boolean AO If true this is for AO, else EWR
-- @param #string Callsign Callsign to address
-- @param #number GID GroupID for comms
-- @return #AWACS self
function AWACS:_CreatePicture(AO,Callsign,GID)
  self:T(self.lid.."_CreatePicture AO="..tostring(AO).." for "..Callsign.." GID "..GID)
  
  local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
  local group = managedgroup.Group -- Wrapper.Group#GROUP
  local groupcoord = group:GetCoordinate()
  
  local fifo = self.PictureAO -- Utilities.FiFo#FIFO
  local maxentries = self.maxspeakentries
  local counter = 0
  
  if not AO then 
    fifo = self.PictureEWR 
  end
  
  local entries = fifo:GetSize()
  
  if entries < maxentries then maxentries = entries end
  
  local text = "First group."
  local textScreen = text
  
  while counter < maxentries do
    counter = counter + 1
    local cluster = fifo:Pull() -- Ops.Intelligence#INTEL.Cluster
    self:T({cluster})
    if cluster and cluster.coordinate then
      local clustercoord = cluster.coordinate -- Core.Point#COORDINATE
      --local refBRAA = clustercoord:ToStringBRA(groupcoord)
      local refBRAA = clustercoord:ToStringBRAANATO(groupcoord,true)
      text = text .. " "..refBRAA.."."
      textScreen = textScreen .." "..refBRAA..".\n"
      if counter < maxentries then
        text = text .. " Next group."
        textScreen = textScreen .. text .. "\n"
      end
    end
  end
  
  -- empty queue from leftovers
  fifo:Clear()
  
  local RadioEntry = {} -- #AWACS.RadioEntry
  RadioEntry.IsNew = true
  RadioEntry.TextTTS = text
  RadioEntry.TextScreen = textScreen
  RadioEntry.GroupID = GID
  RadioEntry.IsGroup = managedgroup.IsPlayer
  RadioEntry.ToScreen = managedgroup.IsPlayer 
  RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
  
  self.RadioQueue:Push(RadioEntry)
  
  return self
end

--- [Internal] AWACS Speak Bogey Dope entries
-- @param #AWACS self
-- @param #string Callsign Callsign to address
-- @param #number GID GroupID for comms
-- @return #AWACS self
function AWACS:_CreateBogeyDope(Callsign,GID)
  self:T(self.lid.."_CreateBogeyDope for "..Callsign.." GID "..GID)
  
  local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
  local group = managedgroup.Group -- Wrapper.Group#GROUP
  local groupcoord = group:GetCoordinate()
  
  local fifo = self.ContactsAO -- Utilities.FiFo#FIFO
  local maxentries = self.maxspeakentries
  local counter = 0
  
  local entries = fifo:GetSize()
  
  if entries < maxentries then maxentries = entries end
  
  local sortedIDs = fifo:GetIDStackSorted() -- sort by distance
  
  while counter < maxentries do
    counter = counter + 1
    local cluster = fifo:PullByID(sortedIDs[counter]) -- Ops.Intelligence#INTEL.Contact
    self:T({cluster})
    if cluster and cluster.position then
      self:_AnnounceContact(cluster,false,group,true)
    end
  end
  
  -- empty queue from leftovers
  fifo:Clear()
  
  return self
end

--- [Internal] AWACS Menu for Picture
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_Picture(Group)
  self:T(self.lid.."_Picture")
  local text = "Picture WIP"
  local textScreen = text
  local GID, Outcome = self:_GetManagedGrpID(Group)
    
  if not self.intel then
    -- no intel yet!
    text = string.format("%s. %s. Clear.",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
    textScreen = text
    local RadioEntry = {} -- #AWACS.RadioEntry
    RadioEntry.IsNew = true
    RadioEntry.TextTTS = text
    RadioEntry.TextScreen = text
    RadioEntry.ToScreen = true
    RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
    
    self.RadioQueue:Push(RadioEntry) 
    return self 
  end

  if Outcome then
    -- Pilot is checked in
    -- get clusters from Intel
    local clustertable = self.intel:GetClusterTable()
    -- sort into buckets
    for _,_cluster in pairs(clustertable) do
      local cluster = _cluster -- Ops.Intelligence#INTEL.Cluster
      local coordVec2 = cluster.coordinate:GetVec2()
      
      if self.OpsZone:IsVec2InZone(coordVec2) then
        self.PictureAO:Push(cluster)
      elseif self.ControlZone:IsVec2InZone(coordVec2) then
        self.PictureEWR:Push(cluster)
      end
    end
    
    local clustersAO = self.PictureAO:GetSize()
    local clustersEWR = self.PictureEWR:GetSize()
    
    if clustersAO == 0 and clustersEWR == 0 then
      -- clear
      text = string.format("%s. %s. Clear.",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
      textScreen = text
      local RadioEntry = {} -- #AWACS.RadioEntry
      RadioEntry.IsNew = true
      RadioEntry.TextTTS = text
      RadioEntry.TextScreen = textScreen
      RadioEntry.GroupID = GID
      RadioEntry.IsGroup = Outcome
      RadioEntry.ToScreen = true
      RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
      
      self.RadioQueue:Push(RadioEntry)
    else
    
      if clustersAO > 0 then
        text = string.format("%s. %s. Picture A O. ",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
        textScreen = string.format("%s. %s. Picture AO. ",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
        if clustersAO == 1 then
          text = text .. "One group. "
          textScreen = textScreen .. "One group.\n"
        else
          text = text .. clustersAO .. " groups. "
          textScreen = textScreen .. clustersAO .. " groups.\n"
        end
        local RadioEntry = {} -- #AWACS.RadioEntry
        RadioEntry.IsNew = true
        RadioEntry.TextTTS = text
        RadioEntry.TextScreen = text
        RadioEntry.GroupID = GID
        RadioEntry.IsGroup = Outcome
        RadioEntry.ToScreen = true
        RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8      
        self.RadioQueue:Push(RadioEntry)
        
        self:_CreatePicture(true,self:_GetCallSign(Group,GID) or "Unknown 1 1",GID)
      end
      
      if clustersEWR > 0 then
       text = string.format("%s. %s. Picture Early Warning. ",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
       textScreen = string.format("%s. %s. Picture EWR. ",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
       if clustersEWR == 1 then
          text = text .. "One group. "
          textScreen = textScreen .. "One group.\n"
        else
          text = text .. clustersEWR .. " groups. "
          textScreen = textScreen .. clustersAO .. " groups.\n"
        end
        local RadioEntry = {} -- #AWACS.RadioEntry
        RadioEntry.IsNew = true
        RadioEntry.TextTTS = text
        RadioEntry.TextScreen = textScreen
        RadioEntry.GroupID = GID
        RadioEntry.IsGroup = Outcome
        RadioEntry.ToScreen = true
        RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8     
        self.RadioQueue:Push(RadioEntry)
        
       self:_CreatePicture(false,self:_GetCallSign(Group,GID) or "Unknown 1 1",GID)
      end
    end
    
  elseif self.AwacsFG then
    -- no, unknown
    text = string.format("%s. Negative %s. You are not checked in.",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")  
    local RadioEntry = {} -- #AWACS.RadioEntry
    RadioEntry.IsNew = true
    RadioEntry.TextTTS = text
    RadioEntry.TextScreen = text
    RadioEntry.GroupID = GID
    RadioEntry.IsGroup = Outcome
    RadioEntry.ToScreen = true
    RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
    
    self.RadioQueue:Push(RadioEntry)
  end
  return self
end

--- [Internal] AWACS Menu for Bogey Dope
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_BogeyDope(Group)
  self:T(self.lid.."_BogeyDope")
  local text = "BogeyDope WIP"
  local textScreen = "BogeyDope WIP"
  local GID, Outcome = self:_GetManagedGrpID(Group)
    
  if not self.intel then
    -- no intel yet!
    text = string.format("%s. %s. Clear.",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
    textScreen = text
    local RadioEntry = {} -- #AWACS.RadioEntry
    RadioEntry.IsNew = true
    RadioEntry.TextTTS = text
    RadioEntry.TextScreen = textScreen
    RadioEntry.GroupID = 0
    RadioEntry.IsGroup = false
    RadioEntry.ToScreen = true
    RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
    
    self.RadioQueue:Push(RadioEntry) 
    return self 
  end

  if Outcome then
    -- Pilot is checked in
    
    local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    local pilotgroup = managedgroup.Group
    local pilotcoord = managedgroup.Group:GetCoordinate()
    
    -- get contacts from Intel
    local contactstable = self.intel:GetContactTable()
    
    -- sort into buckets - AO only for bogey dope!
    for _,_contact in pairs(contactstable) do
      local cluster = _contact -- Ops.Intelligence#INTEL.Contact
      local coordVec2 = cluster.position:GetVec2()
      
      -- Get distance for sorting
      local dist = pilotcoord:Get2DDistance(cluster.position)
      
      if self.OpsZone:IsVec2InZone(coordVec2) then
        self.ContactsAO:Push(cluster,dist)
      end     
    end
    
    local contactsAO = self.ContactsAO:GetSize()
    
    if contactsAO == 0 then
      -- clear
      text = string.format("%s. %s. Clear.",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
      textScreen = text
      local RadioEntry = {} -- #AWACS.RadioEntry
      RadioEntry.IsNew = true
      RadioEntry.TextTTS = text
      RadioEntry.TextScreen = textScreen
      RadioEntry.GroupID = GID
      RadioEntry.IsGroup = Outcome
      RadioEntry.ToScreen = Outcome
      RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
      
      self.RadioQueue:Push(RadioEntry)
    else
    
      if contactsAO > 0 then
        text = string.format("%s. %s. Bogey Dope. ",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
        if contactsAO == 1 then
          text = text .. "One group. "
          textScreen = text .. "\n"
        else
          text = text .. contactsAO .. " groups. "
          textScreen = textScreen .. contactsAO .. " groups.\n"
        end
        local RadioEntry = {} -- #AWACS.RadioEntry
        RadioEntry.IsNew = true
        RadioEntry.TextTTS = text
        RadioEntry.TextScreen = textScreen
        RadioEntry.GroupID = GID
        RadioEntry.IsGroup = Outcome
        RadioEntry.ToScreen = true
        RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8      
        self.RadioQueue:Push(RadioEntry)
        
        self:_CreateBogeyDope(self:_GetCallSign(Group,GID) or "Unknown 1 1",GID)
      end
    end
    
  elseif self.AwacsFG then
    -- no, unknown
    text = string.format("%s. Negative %s. You are not checked in.",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")  
    local RadioEntry = {} -- #AWACS.RadioEntry
    RadioEntry.IsNew = true
    RadioEntry.TextTTS = text
    RadioEntry.TextScreen = text
    RadioEntry.GroupID = GID
    RadioEntry.IsGroup = Outcome
    RadioEntry.ToScreen = true
    RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
    
    self.RadioQueue:Push(RadioEntry)
  end
  return self
end


--- [Internal] AWACS Menu for Declare
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_Declare(Group)
  self:T(self.lid.."_Declare")

  local GID, Outcome = self:_GetManagedGrpID(Group)
  local text = "Declare Not yet implemented"
  if Outcome then
    --[[ yes, known

    --]]
  elseif self.AwacsFG then
    -- no, unknown
    text = string.format("%s. Negative %s. You are not checked in.",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
  end
  
  local RadioEntry = {} -- #AWACS.RadioEntry
  RadioEntry.IsNew = true
  RadioEntry.TextTTS = text
  RadioEntry.TextScreen = text
  RadioEntry.GroupID = GID
  RadioEntry.IsGroup = Outcome
  RadioEntry.ToScreen = true
  RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
  
  self.RadioQueue:Push(RadioEntry)
  
  return self
end

--- [Internal] AWACS Menu for Showtask
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_Showtask(Group)
  self:T(self.lid.."_Showtask")

  local GID, Outcome = self:_GetManagedGrpID(Group)
  local text = "Showtask WIP"
  
  if Outcome then
   -- known group
   
   -- Do we have a task?
   local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
   
   if managedgroup.IsPlayer and self.TaskedCAPHuman:HasUniqueID(GID) then

    if managedgroup.CurrentAuftrag >0 and self.ManagedTasks:HasUniqueID(managedgroup.CurrentAuftrag) then
      -- get task structure
      local currenttask = self.ManagedTasks:ReadByID(managedgroup.CurrentAuftrag) -- #AWACS.ManagedTask
      if currenttask then
        local status = currenttask.Status
        local targettype = currenttask.Target:GetCategory()
        local targetstatus = currenttask.Target:GetState()
        local ToDo = currenttask.ToDo
        local description = currenttask.ScreenText
        local callsign = self:_GetCallSign(Group,GID)
        
        if self.debug then
          local taskreport = REPORT:New("AWACS Tasking Display")
          taskreport:Add("===============")
          taskreport:Add(string.format("Task for Callsign: %s",callsign))
          taskreport:Add(string.format("Task: %s with Status: %s",ToDo,status))
          taskreport:Add(string.format("Target of Type: %s",targettype))
          taskreport:Add(string.format("Target in State: %s",targetstatus))
          taskreport:Add("===============")
          self:I(taskreport:Text())
        end
        
        MESSAGE:New(description,30,"AWACS",true):ToGroup(Group)
        
      end
    end
   end
   
  elseif self.AwacsFG then
    -- no, unknown
    text = string.format("%s. Negative %s. You are not checked in.",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
  
    local RadioEntry = {} -- #AWACS.RadioEntry
    RadioEntry.IsNew = true
    RadioEntry.TextTTS = text
    RadioEntry.TextScreen = text
    RadioEntry.GroupID = GID
    RadioEntry.IsGroup = Outcome
    RadioEntry.ToScreen = true
    RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
    
    self.RadioQueue:Push(RadioEntry)
  end
  return self
end

--- [Internal] AWACS Menu for Check in
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @return #AWACS self
function AWACS:_CheckIn(Group)
  self:I(self.lid.."_CheckIn "..Group:GetName())
  -- check if already known
  local GID, Outcome = self:_GetManagedGrpID(Group)
  local text = ""
  if not Outcome then
    self.ManagedGrpID = self.ManagedGrpID + 1
    local managedgroup = {} -- #AWACS.ManagedGroup
      managedgroup.Group = Group
      managedgroup.GroupName = Group:GetName()
      managedgroup.IsPlayer = true
      managedgroup.IsAI = false
      managedgroup.CallSign = self:_GetCallSign(Group,GID) or "Unknown 1 1"
      managedgroup.CurrentAuftrag = 0
      managedgroup.HasAssignedTask = false
      managedgroup.GID = self.ManagedGrpID
      GID = managedgroup.GID
    self.ManagedGrps[self.ManagedGrpID]=managedgroup
    text = string.format("%s. Copy %s. Await tasking.",self.callsigntxt,managedgroup.CallSign)
    self:__CheckedIn(1,managedgroup.GID)
    self:__AssignAnchor(5,managedgroup.GID)
  elseif self.AwacsFG then
    text = string.format("%s. Negative %s. You are already checked in.",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
  end
  
  local RadioEntry = {} -- #AWACS.RadioEntry
  RadioEntry.IsNew = true
  RadioEntry.TextTTS = text
  RadioEntry.TextScreen = text
  RadioEntry.GroupID = GID
  RadioEntry.IsGroup = true
  RadioEntry.ToScreen = true
  RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
  
  self.RadioQueue:Push(RadioEntry)
  
  return self
end

--- [Internal] AWACS Menu for CheckInAI
-- @param #AWACS self
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup to use
-- @param Wrapper.Group#GROUP Group Group to use
-- @param #number AuftragsNr Ops.Auftrag#AUFTRAG.auftragsnummer
-- @return #AWACS self
function AWACS:_CheckInAI(FlightGroup,Group,AuftragsNr)
  self:I(self.lid.."_CheckInAI "..Group:GetName() .. " to Auftrag Nr "..AuftragsNr)
  -- check if already known
  local GID, Outcome = self:_GetManagedGrpID(Group)
  local text = ""
  if not Outcome then
    self.ManagedGrpID = self.ManagedGrpID + 1
    local managedgroup = {} -- #AWACS.ManagedGroup
      managedgroup.Group = Group
      managedgroup.GroupName = Group:GetName()
      managedgroup.FlightGroup = FlightGroup
      managedgroup.IsPlayer = false
      managedgroup.IsAI = true
      --managedgroup.CallSign = self:_GetCallSign(Group,GID) or "AI 1 1"
      --   self.AICAPCAllName = CALLSIGN.F16.Viper (number)
      -- self.AICAPCAllNumber
      local callsignstring = UTILS.GetCallsignName(self.AICAPCAllName)
      local callsignmajor = math.fmod(self.AICAPCAllNumber,9)
      local callsign = string.format("%s %d 1",callsignstring,callsignmajor)
      self:I("Assigned Callsign: ".. callsign)
      managedgroup.CallSign =  callsign
      managedgroup.CurrentAuftrag = AuftragsNr
      managedgroup.HasAssignedTask = false
      managedgroup.GID = self.ManagedGrpID
    
    -- SRS voice for CAP
    --FlightGroup:SetSRS(PathToSRS,Gender,Culture,Voice,Port,PathToGoogleKey)
    
    FlightGroup:SetDefaultRadio(self.Frequency,self.Modulation,false)
    FlightGroup:SwitchRadio(self.Frequency,self.Modulation)
    --FlightGroup:SetDefaultCallsign(self.AICAPCAllName,callsignmajor)
    
    FlightGroup:SetSRS(self.PathToSRS,self.CAPGender,self.CAPCulture,self.CAPVoice,self.Port,nil)
    
    text = string.format("%s. %s. Check in for CAP. Expected playtime %d hours.",managedgroup.CallSign, self.callsigntxt,self.CAPTimeOnStation)
    local RadioEntry = {} -- #AWACS.RadioEntry
    RadioEntry.IsNew = true
    RadioEntry.TextTTS = text
    RadioEntry.ToScreen = false
    RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
    RadioEntry.FromAI = true
    RadioEntry.GroupID = managedgroup.GID
    
    self.RadioQueue:Push(RadioEntry)
      
    self.ManagedGrps[self.ManagedGrpID]=managedgroup
    text = string.format("%s. Copy %s. Await tasking.",self.callsigntxt,managedgroup.CallSign)
    self:__CheckedIn(1,managedgroup.GID)
    self:__AssignAnchor(5,managedgroup.GID)
  else
    text = string.format("%s. Negative %s. You are already checked in.",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
  end
  
  local RadioEntry = {} -- #AWACS.RadioEntry
  RadioEntry.IsNew = true
  RadioEntry.TextTTS = text
  RadioEntry.ToScreen = false
  RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
  
  self.RadioQueue:Push(RadioEntry)
  
  return self
end

--- [Internal] AWACS Menu for Check Out
-- @param #AWACS self
-- @param Wrapper.Group#GROUP Group Group to use
-- @param #number GID GroupID
-- @return #AWACS self
function AWACS:_CheckOut(Group,GID)
  self:I(self.lid.."_CheckOut")

  -- check if already known
  local GID, Outcome = self:_GetManagedGrpID(Group)
  local text = ""
  if Outcome then
    -- yes, known
    text = string.format("%s. Copy %s. Have a safe flight home.",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
    self:I(text)
    -- grab some data before we nil the entry
    local AnchorAssigned = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    local Stack = AnchorAssigned.AnchorStackNo
    local Angels = AnchorAssigned.AnchorStackAngels
    self.ManagedGrps[GID] = nil
    self:__CheckedOut(1,GID,Stack,Angels)
  else
    -- no, unknown
    text = string.format("%s. Negative %s. You are not checked in.",self.callsigntxt,self:_GetCallSign(Group,GID) or "Unknown 1 1")
  end
  
  local RadioEntry = {} -- #AWACS.RadioEntry
  RadioEntry.IsNew = true
  RadioEntry.TextTTS = text
  RadioEntry.ToScreen = true
  RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
  
  self.RadioQueue:Push(RadioEntry)
  
  return self
end

--- [Internal] AWACS set client menus
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_SetClientMenus()
  self:T(self.lid.."_SetClientMenus")
  local clientset = self.clientset -- Core.Set#SET_GROUP
  local aliveset = clientset:GetAliveSet() -- #table of #GROUP objects
  --local aliveobjects = aliveset:GetSetObjects() or {}
  local clientmenus = {}
  local clientcount = 0
  local clientcheckedin = 0 
  for _,_group in pairs(aliveset) do
    -- go through set and build the menu
    local grp = _group -- Wrapper.Group#GROUP
    if self.MenuStrict then
      -- check if pilot has checked in
      if grp and grp:IsAlive() and grp:GetUnit(1):IsPlayer() then
        clientcount = clientcount + 1
        local GID, checkedin = self:_GetManagedGrpID(grp)
        if checkedin then
          -- full menu minus checkin
          clientcheckedin = clientcheckedin + 1
          local hasclientmenu = self.clientmenus[grp:GetName()] -- #AWACS.MenuStructure
          --local checkinmenu = hasclientmenu.checkin -- Core.Menu#MENU_GROUP_COMMAND 
          --checkinmenu:Remove(nil,grp:GetName())
          local basemenu = hasclientmenu.basemenu -- Core.Menu#MENU_GROUP
          --local basemenu = MENU_GROUP:New(grp.Name,nil)
          basemenu:RemoveSubMenus()
          local picture = MENU_GROUP_COMMAND:New(grp,"Picture",basemenu,self._Picture,self,grp)
          local bogeydope = MENU_GROUP_COMMAND:New(grp,"Bogey Dope",basemenu,self._BogeyDope,self,grp)
          local declare = MENU_GROUP_COMMAND:New(grp,"Declare",basemenu,self._Declare,self,grp)
          local showtask = MENU_GROUP_COMMAND:New(grp,"Showtask",basemenu,self._Showtask,self,grp)
          local checkout = MENU_GROUP_COMMAND:New(grp,"Check Out",basemenu,self._CheckOut,self,grp):Refresh()
          clientmenus[grp:GetName()] = { -- #AWACS.MenuStructure
            groupname =  grp:GetName(),
            menuset = true,
            basemenu = basemenu,
            --checkin = checkin,
            checkout= checkout,
            picture = picture,
            bogeydope = bogeydope,
            declare = declare,
            showtask = showtask,
          }
        elseif not clientmenus[grp:GetName()] then
          -- check in only
          local basemenu = MENU_GROUP:New(grp,self.Name,nil)
          local checkin = MENU_GROUP_COMMAND:New(grp,"Check In",basemenu,self._CheckIn,self,grp)
          checkin:SetTag(grp:GetName())
          checkin:Refresh()
          clientmenus[grp:GetName()] = { -- #AWACS.MenuStructure
            groupname =  grp:GetName(),
            menuset = true,
            basemenu = basemenu,
            checkin = checkin,
            --checkout= checkout,
            --picture = picture,
            --bogeydope = bogeydope,
            --declare = declare,
            --showtask = showtask,
          }
        end
      end
    else
      if grp and grp:IsAlive() and grp:GetUnit(1):IsPlayer() and not clientmenus[grp:GetName()] then
        local basemenu = MENU_COALITION:New(self.coalition,self.Name,nil)
        local picture = MENU_COALITION_COMMAND:New(self.coalition,"Picture",basemenu,self._Picture,self,grp)
        local bogeydope = MENU_COALITION_COMMAND:New(self.coalition,"Bogey Dope",basemenu,self._BogeyDope,self,grp)
        local declare = MENU_COALITION_COMMAND:New(self.coalition,"Declare",basemenu,self._Declare,self,grp)
        local showtask = MENU_COALITION_COMMAND:New(self.coalition,"Showtask",basemenu,self._Showtask,self,grp)
        local checkin = MENU_COALITION_COMMAND:New(self.coalition,"Check In",basemenu,self._CheckIn,self,grp)
        local checkout = MENU_COALITION_COMMAND:New(self.coalition,"Check Out",basemenu,self._CheckOut,self,grp):Refresh()
        clientmenus[grp:GetName()] = { -- #AWACS.MenuStructure
          groupname =  grp:GetName(),
          menuset = true,
          basemenu = basemenu,
          checkin = checkin,
          checkout= checkout,
          picture = picture,
          bogeydope = bogeydope,
          declare = declare,
          showtask = showtask,
        }
      end
    end
  end
  
  self.clientmenus = clientmenus
  self.MonitoringData.Players = clientcount or 0
  self.MonitoringData.PlayersCheckedin = clientcheckedin or 0
    
  return self
end

--- [Internal] AWACS Create a new Anchor Stack
-- @param #AWACS self
-- @return #boolean success
-- @return #nunber AnchorStackNo
function AWACS:_CreateAnchorStack()
  self:T(self.lid.."_CreateAnchorStack")
  local stackscreated = self.AnchorStacks:GetSize()
  if stackscreated == self.AnchorMaxAnchors  then
    -- only create self.AnchorMaxAnchors Anchors
    return false, 0
  end
  local AnchorStackOne = {} -- #AWACS.AnchorData
  AnchorStackOne.AnchorBaseAngels = self.AnchorBaseAngels
  AnchorStackOne.Anchors = FIFO:New() -- Utilities.FiFo#FIFO
  AnchorStackOne.AnchorAssignedID = FIFO:New() -- Utilities.FiFo#FIFO
  local newname = ""
  for i=1,self.AnchorMaxStacks do
    AnchorStackOne.Anchors:Push((i-1)*self.AnchorStackDistance+self.AnchorBaseAngels)
  end
  if self.debug then
    --AnchorStackOne.Anchors:Flush()
  end
  if stackscreated == 0 then
    AnchorStackOne.AnchorZone = self.AnchorZone
    AnchorStackOne.AnchorZoneCoordinate = self.AnchorZone:GetCoordinate()
    AnchorStackOne.AnchorZoneCoordinateText = self.AnchorZone:GetCoordinate():ToStringLLDDM()
    --push to AnchorStacks
    self.AnchorStacks:Push(AnchorStackOne,"One")
  else
    local newsubname = AWACS.AnchorNames[stackscreated+1] or tostring(stackscreated+1)
    newname = self.AnchorZone:GetName() .. "-"..newsubname
    local anchorbasecoord = self.OpsZone:GetCoordinate() -- Core.Point#COORDINATE
    -- OpsZone can be Polygon, so use distance to AnchorZone as radius
    local anchorradius = anchorbasecoord:Get2DDistance(self.AnchorZone:GetCoordinate())
    --local anchorradius = self.OpsZone:GetRadius() -- #number
    --anchorradius = anchorradius + self.AnchorZone:GetRadius()
    local angel = self.AnchorZone:GetCoordinate():GetAngleDegrees(self.OpsZone:GetVec3())
    self:T("Angel Radians= " .. angel)
    local turn = math.fmod(self.AnchorTurn*stackscreated,360) -- #number
    if self.AnchorTurn < 0 then turn = -turn end
    local newanchorbasecoord = anchorbasecoord:Translate(anchorradius,turn+angel) -- Core.Point#COORDINATE
    AnchorStackOne.AnchorZone = ZONE_RADIUS:New(newname, newanchorbasecoord:GetVec2(), self.AnchorZone:GetRadius())
    AnchorStackOne.AnchorZoneCoordinate = newanchorbasecoord
    AnchorStackOne.AnchorZoneCoordinateText = newanchorbasecoord:ToStringLLDDM()
    --push to AnchorStacks
    self.AnchorStacks:Push(AnchorStackOne,newname)
  end

  if self.debug then
    --self.AnchorStacks:Flush()
    AnchorStackOne.AnchorZone:DrawZone(-1,{0,0,1},1,{0,0,1},0.2,5,true)
    MARKER:New(AnchorStackOne.AnchorZone:GetCoordinate(),"Anchor Zone: "..newname):ToAll()
  end

  return true,self.AnchorStacks:GetSize()
  
end

--- [Internal] AWACS get free anchor stack for managed groups
-- @param #AWACS self
-- @return #number AnchorStackNo
-- @return #boolean free 
function AWACS:_GetFreeAnchorStack()
  self:T(self.lid.."_GetFreeAnchorStack")
  local AnchorStackNo, Free = 0, false
  --return AnchorStackNo, Free
  local availablestacks = self.AnchorStacks:GetPointerStack() or {} -- #table
  for _id,_entry in pairs(availablestacks) do
    local entry = _entry -- Utilities.FiFo#FIFO.IDEntry
    local data = entry.data -- #AWACS.AnchorData
    if data.Anchors:IsNotEmpty() then
      AnchorStackNo = _id
      Free = true
      break
    end
  end
  -- TODO - if extension of anchor stacks to max, send AI home
  if not Free then
    -- try to create another stack
    local created, number = self:_CreateAnchorStack()
    if created then
      -- we could create a new one - phew!
      self:_GetFreeAnchorStack()
    end
  end
  return AnchorStackNo, Free
end

--- [Internal] AWACS Assign Anchor Position to a Group
-- @param #AWACS self
-- @return #number GID Managed Group ID
-- @return #AWACS self
function AWACS:_AssignAnchorToID(GID)
  self:T(self.lid.."_AssignAnchorToID")
  local AnchorStackNo, Free = self:_GetFreeAnchorStack()
  if Free then
    -- get the Anchor from the stack
    local Anchor = self.AnchorStacks:PullByPointer(AnchorStackNo) -- #AWACS.AnchorData
    -- pull one free angels
    local freeangels = Anchor.Anchors:Pull()
    -- push GID on anchor
    Anchor.AnchorAssignedID:Push(GID)
    if self.debug then
      --Anchor.AnchorAssignedID:Flush()
      --Anchor.Anchors:Flush()
    end
    -- push back to AnchorStacks
    self.AnchorStacks:Push(Anchor)
    self:T({Anchor,freeangels})
    self:__AssignedAnchor(5,GID,Anchor,AnchorStackNo,freeangels)
  else
    self:E(self.lid .. "Cannot assing free anchor stack to GID ".. GID)
    -- try again ...
    self:__AssignAnchor(10,GID)
  end
  return self
end

--- [Internal] Remove GID (group) from Anchor Stack
-- @param #AWACS self
-- @param #AWACS.ManagedGroup.GID ID
-- @param #number AnchorStackNo
-- @param #number Angels
-- @return #AWACS self
function AWACS:_RemoveIDFromAnchor(GID,AnchorStackNo,Angels)
  local gid = GID or 0
  local stack = AnchorStackNo or 0
  local angels = Angels or 0
  local debugstring = string.format("%s_RemoveIDFromAnchor for GID=%d Stack=%d Angels=%d",self.lid,gid,stack,angels)
  self:I(debugstring)
  -- pull correct anchor
  if stack > 0 and angels > 0 then
    local AnchorStackNo = AnchorStackNo or 1
    local Anchor = self.AnchorStacks:ReadByPointer(AnchorStackNo) -- #AWACS.AnchorData
    -- pull GID from stack
    local removedID = Anchor.AnchorAssignedID:PullByID(GID)
    -- push free angels to stack
    Anchor.Anchors:Push(Angels)
    -- push back AnchorStack
    --self.AnchorStacks:Push(Anchor)
  end
  return self
end

--- [Internal] Start INTEL detection when we reach the AWACS Orbit Zone
-- @param #AWACS self
-- @param Wrapper.Group#GROUP awacs
-- @return #AWACS self
function AWACS:_StartIntel(awacs)
  self:T(self.lid.."_StartIntel")
  
  self.DetectionSet:AddGroup(awacs)
  
  local intel = INTEL:New(self.DetectionSet,self.coalition,self.callsigntxt)
  --intel:SetVerbosity(2)
  intel:SetClusterAnalysis(true,self.debug)
  if self.NoHelos then
    intel:SetFilterCategory({Unit.Category.AIRPLANE})
  else
    intel:SetFilterCategory({Unit.Category.AIRPLANE,Unit.Category.HELICOPTER})
  end
  
  -- Callbacks
  local function NewCluster(Cluster)
    self:__NewCluster(5,Cluster)
  end 
  function intel:OnAfterNewCluster(From,Event,To,Cluster)
    NewCluster(Cluster)
  end
  
  local function NewContact(Contact)
    self:__NewContact(5,Contact)
  end 
  function intel:OnAfterNewContact(From,Event,To,Contact)
   NewContact(Contact)
  end
  
  local function LostContact(Contact)
    self:__LostContact(5,Contact)
  end 
  function intel:OnAfterLostContact(From,Event,To,Contact)
    LostContact(Contact)
  end
  
  local function LostCluster(Cluster,Mission)
    self:__LostCluster(5,Cluster,Mission)
  end
  function intel:OnAfterLostCluster(From,Event,To,Cluster,Mission)
    LostCluster(Cluster,Mission)
  end
  
  intel:__Start(2)
  
  self.intel = intel -- Ops.Intelligence#INTEL
  return self
end

--- [Internal] Get blurred size of group or cluster
-- @param #AWACS self
-- @param #number size
-- @return #number adjusted size
-- @return #string AWACS.Shipsize entry for size 1..3
function AWACS:_GetBlurredSize(size)
  self:T(self.lid.."_GetBlurredSize")
  local threatsize = 0
  local blur = self.RadarBlur
  local blurmin = 100 - blur
  local blurmax = 100 + blur
  local actblur = math.random(blurmin,blurmax) / 100
  threatsize = math.floor(size * actblur)
  if threatsize == 0 then threatsize = 1 end
  if threatsize then end
  local threatsizetext = AWACS.Shipsize[1]
  if threatsize == 2  then 
    threatsizetext = AWACS.Shipsize[2]
  elseif threatsize >2 then 
    threatsizetext = AWACS.Shipsize[3]
  end
  return threatsize, threatsizetext
end

--- [Internal] Get threat level as clear test
-- @param #AWACS self
-- @param #number threatlevel
-- @return #string threattext
function AWACS:_GetThreatLevelText(threatlevel)
  self:T(self.lid.."_GetThreatLevelText")
  local threattext = "GREEN"
  if threatlevel <= AWACS.THREATLEVEL.GREEN then
   threattext = "GREEN"
  elseif threatlevel <= AWACS.THREATLEVEL.AMBER then
   threattext = "AMBER"
  else
    threattext = "RED"
  end
  return threattext
end

--- [Internal] Get BRA text for TTS
-- @param #AWACS self
-- @param Core.Point#COORDINATE clustercoordinate
-- @return #string BRAText
function AWACS:_GetBRAfromBullsOrAO(clustercoordinate)
  self:T(self.lid.."__GetBRAfromBullsOrAO")
  local refcoord = self.AOCoordinate -- Core.Point#COORDINATE
  local BRAText = ""
  if not self.UseBullsAO then
    -- get BR from AO
    BRAText = "AO "..refcoord:ToStringBR(clustercoordinate)
  else
    -- get BR from Bulls
    BRAText = clustercoordinate:ToStringBULLS(self.coalition)
  end
  return BRAText
end

--- [Internal] Register Task for Group by GID
-- @param #AWACS self
-- @param #number GroupID ManagedGroup ID
-- @param #AWACS.TaskDescription Description Short Description Task Type
-- @param #string ScreenText Long task description for screen output
-- @param #table Object Object for Ops.Target#TARGET assignment
-- @return #AWACS self
function AWACS:_CreateTaskForGroup(GroupID,Description,ScreenText,Object)
   self:I(self.lid.."_CreateTaskForGroup "..GroupID .." Description: "..Description)
   
   local managedgroup = self.ManagedGrps[GroupID] -- #AWACS.ManagedGroup
   local task = {} -- #AWACS.ManagedTask
   self.ManagedTaskID = self.ManagedTaskID + 1
   task.TID = self.ManagedTaskID
   task.AssignedGroupID = GroupID
   task.Status = AWACS.TaskStatus.ASSIGNED
   task.ToDo = Description
   task.Target = TARGET:New(Object)
   task.ScreenText = ScreenText
   if Description == AWACS.TaskDescription.ANCHOR or Description == AWACS.TaskDescription.REANCHOR then
    task.Target.Type = TARGET.ObjectType.ZONE
   end
   
   self.ManagedTasks:Push(task,task.TID)

   managedgroup.HasAssignedTask = true
   managedgroup.CurrentTask = task.TID

   self.ManagedGrps[GroupID] = managedgroup

   return self
end 

--- [Internal] Read registered Task for Group by its ID
-- @param #AWACS self
-- @param #number GroupID ManagedGroup ID
-- @return #AWACS.ManagedTask Task or nil if n/e
function AWACS:_ReadAssignedTaskFromGID(GroupID)
   self:T(self.lid.."_GetAssignedTaskFromGID "..GroupID)
   local managedgroup = self.ManagedGrps[GroupID] -- #AWACS.ManagedGroup
   if managedgroup and managedgroup.HasAssignedTask then
     local TaskID = managedgroup.CurrentTask
     if self.ManagedTasks:HasUniqueID(TaskID) then
      return self.ManagedTasks:ReadByID(TaskID)
     end
   end
   return nil
end

--- [Internal] Read assigned Group from a TaskID
-- @param #AWACS self
-- @param #number TaskID ManagedTask ID
-- @return #AWACS.ManagedGroup Group structure or nil if n/e
function AWACS:_ReadAssignedGroupFromTID(TaskID)
   self:T(self.lid.."_ReadAssignedGroupFromTID "..TaskID)
   if self.ManagedTasks:HasUniqueID(TaskID) then
    local task = self.ManagedTasks:ReadByID(TaskID) -- #AWACS.ManagedTask
    if task and task.AssignedGroupID and task.AssignedGroupID > 0 then
      return self.ManagedGrps[task.AssignedGroupID]
    end
   end
   return nil
end

--- [Internal] Create new idle task from contact to pick up later
-- @param #AWACS self
-- @param #string Description Task Type
-- @param #table Object Object of TARGET
-- @param Ops.Intelligence#INTEL.Contact Contact
-- @return #AWACS self
function AWACS:_CreateIdleTaskForContact(Description,Object,Contact)
   self:T(self.lid.."_CreateIdleTaskForContact "..Description)
   local task = {} -- #AWACS.ManagedTask
   self.ManagedTaskID = self.ManagedTaskID + 1
   task.TID = self.ManagedTaskID
   task.AssignedGroupID = 0
   task.Status = AWACS.TaskStatus.IDLE
   task.ToDo = Description
   task.Target = TARGET:New(Object)
   task.Contact = Contact
   --task.IsContact = true
   task.ScreenText = Description
   if Description == AWACS.TaskDescription.ANCHOR or Description == AWACS.TaskDescription.REANCHOR then
    task.Target.Type = TARGET.ObjectType.ZONE
   end
   self.ManagedTasks:Push(task,task.TID)
   return self
end  

--- [Internal] Create new idle task from cluster to pick up later
-- @param #AWACS self
-- @param #string Description Task Type
-- @param #table Object Object of TARGET
-- @param Ops.Intelligence#INTEL.Cluster Cluster
-- @return #AWACS self
function AWACS:_CreateIdleTaskForCluster(Description,Object,Cluster)
   self:T(self.lid.."_CreateIdleTaskForCluster "..Description)
   local task = {} -- #AWACS.ManagedTask
   self.ManagedTaskID = self.ManagedTaskID + 1
   task.TID = self.ManagedTaskID
   task.AssignedGroupID = 0
   task.Status = AWACS.TaskStatus.IDLE
   task.ToDo = Description
   --self:T({Cluster.Contacts})
   --task.Target = TARGET:New(Cluster.Contacts[1])
   task.Target = TARGET:New(self.intel:GetClusterCoordinate(Cluster))
   task.Cluster = Cluster
   --task.IsCluster = true
   task.ScreenText = Description
   if Description == AWACS.TaskDescription.ANCHOR or Description == AWACS.TaskDescription.REANCHOR then
    task.Target.Type = TARGET.ObjectType.ZONE
   end
   self.ManagedTasks:Push(task,task.TID)
   return self
end 

--- [Internal] Create radio entry to tell players that CAP is on station in Anchor
-- @param #AWACS self
-- @param #number GID Group ID 
-- @return #AWACS self
function AWACS:_MessageAIReadyForTasking(GID)
  self:I(self.lid.."_MessageAIReadyForTasking")
  -- obtain group details
  if GID >0  and self.ManagedGrps[GID] then
    local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
    local GFCallsign = self:_GetCallSign(managedgroup.Group)
    local TextTTS = string.format("%s. %s. On station over anchor %d at angels  %d. Ready for tasking.",GFCallsign,self.callsigntxt,managedgroup.AnchorStackNo or 1,managedgroup.AnchorStackAngels or 25)
    local RadioEntry = {} -- #AWACS.RadioEntry
    RadioEntry.TextTTS = TextTTS
    RadioEntry.TextScreen = ""
    RadioEntry.IsNew = true
    RadioEntry.IsGroup = false
    RadioEntry.GroupID = GID
    RadioEntry.Duration = STTS.getSpeechTime(TextTTS,1.2,false)+2 or 16
    RadioEntry.ToScreen = false
    RadioEntry.FromAI = true
    
    self.RadioQueue:Push(RadioEntry)
  end
  return self
end

--- [Internal] Check available tasks and status
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_CheckTaskQueue()
  self:T(self.lid.."_CheckTaskQueue")
  local opentasks = 0
  local assignedtasks = 0
  
  --- INTERNAL TASKS
  
  if self.ManagedTasks:IsNotEmpty() then
    opentasks = self.ManagedTasks:GetSize()
    self:T("Assigned Tasks: " .. opentasks)
    local taskstack = self.ManagedTasks:GetPointerStack()
    for _id,_entry in pairs(taskstack) do
      local data = _entry -- Utilities.FiFo#FIFO.IDEntry
      local entry = data.data -- #AWACS.ManagedTask
      local target = entry.Target -- Ops.Target#TARGET
      local description = entry.ToDo
      self:I("ToDo = "..description)
      if description == AWACS.TaskDescription.ANCHOR or description == AWACS.TaskDescription.REANCHOR then
        self:T("Open Tasks ANCHOR/REANCHOR")
        -- see if we have reached the anchor zone
        local managedgroup = self.ManagedGrps[entry.AssignedGroupID] -- #AWACS.ManagedGroup
        if managedgroup then
          local group = managedgroup.Group
          local groupcoord = group:GetCoordinate()
          local zone = target:GetObject() -- Core.Zone#ZONE
          self:T({zone})
          if group:IsInZone(zone) then
            self:I("Open Tasks ANCHOR/REANCHOR success for GroupID "..entry.AssignedGroupID)
            -- made it
            target:Stop()
            -- pull task from OpenTasks
            self.ManagedTasks:PullByPointer(_id)
            -- add group to idle stack
            if managedgroup.IsAI then
              -- message AI on station
              self:_MessageAIReadyForTasking(managedgroup.GID)
            elseif managedgroup.IsPlayer then
              --self.TaskedCAPHuman:PullByPointer(entry.AssignedGroupID)
              --self.CAPIdleHuman:Push(entry.AssignedGroupID)
            end
          else
            -- not there yet
          end
        end
      elseif description == AWACS.TaskDescription.INTERCEPT then
        -- TODO
      elseif description == AWACS.TaskDescription.RTB then
       -- TODO
      end
    end
  end
  
  return self
end

--- [Internal] Write stats to log
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_LogStatistics()
  self:T(self.lid.."_LogStatistics")
  local text = string.gsub(UTILS.OneLineSerialize(self.MonitoringData),",","\n")
  local text = string.gsub(text,"{","\n")
  local text = string.gsub(text,"}","")
  local text = string.gsub(text,"="," = ")
  self:T(text)
  if self.MonitoringOn then
    MESSAGE:New(text,20,"AWACS",true):ToAll()
  end
  return self 
end

--- [User] Add another AirWing for CAP Flights under management
-- @param #AWACS self
-- @param Ops.AirWing#AIRWING AirWing The AirWing to (also) obtain CAP flights from
-- @return #AWACS self
function AWACS:AddCAPAirWing(AirWing)
  self:I(self.lid.."AddCAPAirWing")
  if AirWing then
    -- TODO - Test Install callback
    -- DONE - add distance to AO as UniqueID
    AirWing:SetUsingOpsAwacs(self)
    local distance = self.AOCoordinate:Get2DDistance(AirWing:GetCoordinate())
    self.CAPAirwings:Push(AirWing,distance)
  end
  return self
end

--- Recruit assets for a given TARGET.
-- @param #AWACS self
-- @param #string MissionType Mission Type.
-- @param #number NassetsMin Min number of required assets.
-- @param #number NassetsMax Max number of required assets.
-- @return #boolean If `true` enough assets could be recruited.
-- @return #table Assets that have been recruited from all legions.
-- @return #table Legions that have recruited assets.
function AWACS:RecruitAssets(MissionType, NassetsMin, NassetsMax)

  -- Cohorts.
  local Cohorts={}
  local AWFiFo = self.CAPAirwings -- Utilities.FiFo#FIFO
  local AWStack = AWFiFo:GetPointerStack()
  local AirWingList = {}
  
  for _ID,_AWID in pairs(AWStack) do
    local SubAW = self.CAPAirwings:ReadByPointer(_ID)
    if SubAW then
      table.insert(AirWingList,SubAW)
    end
  end
  
  for _,_legion in pairs(AirWingList) do
    local legion=_legion --Ops.Legion#LEGION
    
    -- Check that runway is operational
    local Runway=legion:IsAirwing() and legion:IsRunwayOperational() or true
    
    if legion:IsRunning() and Runway then    
    
      -- Loops over cohorts.
      for _,_cohort in pairs(legion.cohorts) do
        local cohort=_cohort --Ops.Cohort#COHORT
        table.insert(Cohorts, cohort)
      end
      
    end
  end  

  -- Target position.
  local TargetVec2=self.OpsZone:GetVec2()
  
  -- Recruit assets.
  local recruited, assets, legions=LEGION.RecruitCohortAssets(Cohorts, MissionType, nil, NassetsMin, NassetsMax, TargetVec2)
  
  return recruited, assets, legions
end

--- [Internal] Announce a new contact
-- @param #AWACS self
-- @param Ops.Intelligence#INTEL.Contact Contact
-- @param #boolean IsNew
-- @param Wrapper.Group#GROUP Group Announce to Group if not nil
-- @param #boolean IsBogeyDope If true, this is a bogey dope announcement
-- @return #AWACS self
function AWACS:_AnnounceContact(Contact,IsNew,Group,IsBogeyDope)
  self:T(self.lid.."_AnnounceContact")
  -- do we have a group to talk to?
  local isGroup = false
  local GID = 0
  local grpcallsign = "Unknown 1 1"
  if Group and Group:IsAlive() then
    GID, isGroup = self:_GetManagedGrpID(Group)
    self:T("GID="..GID.." CheckedIn = "..tostring(isGroup))
    grpcallsign = self:_GetCallSign(Group,GID) or "Unknown 1 1"
  end
  local contact = Contact -- Ops.Intelligence#INTEL.Contact
  local intel = self.intel -- Ops.Intelligence#INTEL
  local size = contact.group:CountAliveUnits()
  local threatsize, threatsizetext = self:_GetBlurredSize(size)
  local threatlevel = contact.threatlevel
  local threattext = self:_GetThreatLevelText(threatlevel)
  local clustercoordinate = contact.position

  local BRAfromBulls = self:_GetBRAfromBullsOrAO(clustercoordinate)
  if isGroup then
    BRAfromBulls = clustercoordinate:ToStringBRA(Group:GetCoordinate())
  end
  
  local Warnlevel = "Early Warning."

  if self.OpsZone:IsVec2InZone(clustercoordinate:GetVec2()) and not IsBogeyDope then
    Warnlevel = "Warning."
  end
  
  if IsNew then
    Warnlevel = Warnlevel .. " New"
  end
  
  Warnlevel = string.format("%s %s", Warnlevel, threattext)
  
  if isGroup then
    Warnlevel = string.format("%s. %s",grpcallsign,Warnlevel)
  end
   
  -- TTS
  local TextTTS = string.format("%s. %s %s %s",self.callsigntxt,Warnlevel,threatsizetext,BRAfromBulls)
  
  -- TextOutput
  local TextScreen = string.format("%s. %s. %s\n%s\nThreatlevel %s",self.callsigntxt,Warnlevel,threatsizetext,BRAfromBulls,threattext)
  
  if IsBogeyDope then
    TextTTS = string.format("%s. %s. %s. %s.",self.callsigntxt,grpcallsign,threatsizetext,BRAfromBulls)
    TextScreen = string.format("%s. %s. %s.\n%s\nThreatlevel %s",self.callsigntxt,grpcallsign,threatsizetext,BRAfromBulls,threattext)
  end
  
  local RadioEntry = {} -- #AWACS.RadioEntry
  RadioEntry.TextTTS = TextTTS
  RadioEntry.TextScreen = TextScreen
  RadioEntry.IsNew = IsNew
  RadioEntry.IsGroup = isGroup
  RadioEntry.GroupID = GID
  RadioEntry.Duration = STTS.getSpeechTime(TextTTS,1.2,false)+2 or 16
  RadioEntry.ToScreen = true
  
  self.RadioQueue:Push(RadioEntry)

  return self
end

--- [Internal] Check for alive OpsGroup from Mission OpsGroups table
-- @param #AWACS self
-- @param #table OpsGroups
-- @return Ops.OpsGroup#OPSGROUP or nil
function AWACS:_GetAliveOpsGroupFromTable(OpsGroups)
  self:T(self.lid.."_GetAliveOpsGroupFromTable")
  local handback = nil 
  for _,_OG in pairs(OpsGroups or {}) do
    local OG = _OG -- Ops.OpsGroup#OPSGROUP
    if OG and OG:IsAlive() then
      handback = OG
      --self:I("Handing back OG: " .. OG:GetName())
      break
    end
  end 
  return handback
end

--- [Internal] Clean up mission stack
-- @param #AWACS self
-- @return #number CAPMissions
-- @return #number Alert5Missions
function AWACS:_CleanUpAIMissionStack()
  self:I(self.lid.."_CleanUpAIMissionStack")
  
  local CAPMissions = 0
  local Alert5Missions = 0
  
  local MissionStack = FIFO:New()
  
  self:I("Checking MissionStack")
  for _,_mission in pairs(self.CatchAllMissions) do
    -- looking for missions of type CAP and ALERT5
    local mission = _mission -- Ops.Auftrag#AUFTRAG
    local type = mission:GetType()
    if type == AUFTRAG.Type.ALERT5 then
      MissionStack:Push(mission,mission.auftragsnummer)
      Alert5Missions = Alert5Missions + 1
    elseif type == AUFTRAG.Type.CAP then
      MissionStack:Push(mission,mission.auftragsnummer)
      CAPMissions = CAPMissions + 1
    end
  end
  
  self.AICAPMissions = nil
  self.AICAPMissions = MissionStack
  
  return CAPMissions, Alert5Missions
  
end

function AWACS:_ConsistencyCheck()
  self:I(self.lid.."_ConsistencyCheck")
  if self.debug then
    self:I("CatchAllMissions")
    local catchallm = {}
    local report1 = REPORT:New("CatchAll")
    report1:Add("====================")
    report1:Add("CatchAllMissions")
    report1:Add("====================")
    for _,_mission in pairs(self.CatchAllMissions) do
      local mission = _mission -- Ops.Auftrag#AUFTRAG
      local nummer = mission.auftragsnummer or 0
      local type = mission:GetType()
      local state = mission:GetState()
      local FG = mission:GetOpsGroups()
      local OG = self:_GetAliveOpsGroupFromTable(FG)
      local OGName = "UnknownFromMission"
      if OG then
        OGName=OG:GetName()
      end
      report1:Add(string.format("Auftrag Nr %d Type %s State %s FlightGroup %s",nummer,type,state,OGName))
      if mission:IsNotOver() then
        catchallm[#catchallm+1] = mission
      end
    end
    
    self.CatchAllMissions = nil
    self.CatchAllMissions = catchallm
    
    local catchallfg = {}
    
    self:I("CatchAllFGs")
    report1:Add("====================")
    report1:Add("CatchAllFGs")
    report1:Add("====================")
    for _,_fg in pairs(self.CatchAllFGs) do
      local FG = _fg -- Ops.FlightGroup#FLIGHTGROUP
      local mission = FG:GetMissionCurrent()
      local OGName = FG:GetName() or "UnknownFromFG"
      local nummer = 0
      local type = "No Type"
      local state = "None"
      if mission then
        type = mission:GetType()
        nummer = mission.auftragsnummer or 0
        state = mission:GetState()
      end
      report1:Add(string.format("Auftrag Nr %d Type %s State %s FlightGroup %s",nummer,type,state,OGName))
      if FG:IsAlive() then
        catchallfg[#catchallfg+1] = FG
      end
    end
    report1:Add("====================")
    self:I(report1:Text())
    
    self.CatchAllFGs = nil
    self.CatchAllFGs = catchallfg
    
  end
  return self
end

--- [Internal] Check Enough AI CAP on Station
-- @param #AWACS self
-- @return #AWACS self
function AWACS:_CheckAICAPOnStation()
  self:I(self.lid.."_CheckAICAPOnStation")
  
  self:_ConsistencyCheck()
  
  local capmissions, alert5missions = self:_CleanUpAIMissionStack()
  self:I({capmissions, alert5missions})
  
  if self.MaxAIonCAP > 0 then
    local onstation = self.AICAPMissions:Count()
    -- control number of AI CAP Flights
    if self.AIRequested < self.MaxAIonCAP then
      -- not enough
      local AnchorStackNo,free = self:_GetFreeAnchorStack()
      if free then
        -- create Alert5 and assign to ONE of our AWs
        -- TODO better selection due to resource shortage?
        local mission = AUFTRAG:NewALERT5(AUFTRAG.Type.CAP)
        self.CatchAllMissions[#self.CatchAllMissions+1] = mission
        local availableAWS = self.CAPAirwings:Count()
        local AWS = self.CAPAirwings:GetDataTable()
        -- random
        local selectedAW = AWS[math.random(1,availableAWS)]
        selectedAW:AddMission(mission)
        self.AIRequested = self.AIRequested + 1
        self:I("CAP="..capmissions.." ALERT5="..alert5missions.." Requested="..self.AIRequested)
      end
    end

    if self.AIRequested > self.MaxAIonCAP then
      -- too many, send one home
      self:I(string.format("*** Onstation %d > MaxAIOnCAP %d",onstation,self.MaxAIonCAP))
      local mission = self.AICAPMissions:Pull() -- Ops.Auftrag#AUFTRAG
      local Groups = mission:GetOpsGroups()
      local OpsGroup = self:_GetAliveOpsGroupFromTable(Groups)
      local GID,checkedin = self:_GetManagedGrpID(OpsGroup)
      mission:__Cancel(30)
      self.AIRequested = self.AIRequested - 1
      if checkedin then
        self:_CheckOut(OpsGroup,GID)
      end
    end
    
    -- Check CAP Mission states
    if onstation > 0 then
      local missions = self.AICAPMissions:GetDataTable()
      -- get mission type and state
      for _,_Mission in pairs(missions) do
        --local mission = self.AICAPMissions:ReadByID(_MissionID) -- Ops.Auftrag#AUFTRAG
        local mission = _Mission -- Ops.Auftrag#AUFTRAG
        self:I("Looking at AuftragsNr " .. mission.auftragsnummer)
        local type = mission:GetType()
        local state = mission:GetState()
        --if type == AUFTRAG.Type.CAP or type == AUFTRAG.Type.ALERT5 or type == AUFTRAG.Type.ORBIT then
        if type == AUFTRAG.Type.ALERT5 then
          -- parked up for CAP
          local OpsGroups = mission:GetOpsGroups()
          local OpsGroup = self:_GetAliveOpsGroupFromTable(OpsGroups)
          local FGstate = mission:GetGroupStatus(OpsGroup)
          if OpsGroup then
             FGstate = OpsGroup:GetState()
             self:I("FG Object in state: " .. FGstate)
          end
          -- FG ready?
         -- if OpsGroup and (state == AUFTRAG.Status.STARTED or FGstate ==  AUFTRAG.Status.EXECUTING or FGstate ==  AUFTRAG.Status.SCHEDULED) then
          if OpsGroup and (FGstate == "Parking" or FGstate == "Cruising") then
            -- has this group checked in already? Avoid double tasking
            local GID, CheckedInAlready = self:_GetManagedGrpID(OpsGroup:GetGroup())
            if not CheckedInAlready then
              self:_SetAIROE(OpsGroup,OpsGroup:GetGroup())
              self:_CheckInAI(OpsGroup,OpsGroup:GetGroup(),mission.auftragsnummer)
            end
          end
        end
      end
    end
    
    -- cycle mission status
    if onstation > 0 then
      local report = REPORT:New("CAP Mission Status")
      report:Add("===============")
      --local missionIDs = self.AICAPMissions:GetIDStackSorted()
      local missions = self.AICAPMissions:GetDataTable()
      local i = 1
      for _,_Mission in pairs(missions) do 
      --for i=1,self.MaxAIonCAP do
        --local mission = self.AICAPMissions:ReadByID(_MissionID) -- Ops.Auftrag#AUFTRAG
        --local mission = self.AICAPMissions:ReadByPointer(i) -- Ops.Auftrag#AUFTRAG
        local mission = _Mission -- Ops.Auftrag#AUFTRAG
        if mission then
          i = i + 1
          report:Add(string.format("Entry %d",i))
          report:Add(string.format("Mission No %d",mission.auftragsnummer))
          report:Add(string.format("Mission Type %s",mission:GetType()))
          report:Add(string.format("Mission State %s",mission:GetState()))
          local OpsGroups = mission:GetOpsGroups()
          local OpsGroup = self:_GetAliveOpsGroupFromTable(OpsGroups) -- Ops.OpsGroup#OPSGROUP
          if OpsGroup then
            local OpsName = OpsGroup:GetName() or "Unknown"
            local OpsCallSign = OpsGroup:GetCallsignName() or "Unknown"
            report:Add(string.format("Mission FG %s",OpsName))
            report:Add(string.format("Callsign %s",OpsCallSign))
            report:Add(string.format("Mission FG State %s",OpsGroup:GetState()))
          else
            report:Add("***** Cannot obtain (yet) this missions OpsGroup!")
          end
          report:Add(string.format("Target Type %s",mission:GetTargetType()))
        end
        report:Add("===============") 
      end
      if self.debug then
        self:T(report:Text())
      end    
    end
  end
  return self
end

--- [Internal] Set ROE for AI CAP
-- @param #AWACS self
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup
-- @param Wrapper.Group#GROUP Group
-- @return #AWACS self
function AWACS:_SetAIROE(FlightGroup,Group)
  self:T(self.lid.."_SetAIROE")
  local ROE = self.AwacsROE or AWACS.ROE.POLICE
  local ROT = self.AwacsROT or AWACS.ROT.PASSIVE
  
  -- TODO adjust to AWACS set ROE
  -- for the time being set to be defensive
  Group:OptionAlarmStateGreen()
  Group:OptionECM_OnlyLockByRadar()
  Group:OptionROEHoldFire()
  Group:OptionROTEvadeFire()
  Group:OptionRTBBingoFuel(true)
  Group:OptionKeepWeaponsOnThreat()
  local callname = self.AICAPCAllName or CALLSIGN.Aircraft.Colt
  self.AICAPCAllNumber = self.AICAPCAllNumber + 1 
  Group:CommandSetCallsign(callname,math.fmod(self.AICAPCAllNumber,9))
  -- FG level
  FlightGroup:SetDefaultAlarmstate(AI.Option.Ground.val.ALARM_STATE.GREEN)
  FlightGroup:SetDefaultCallsign(callname,math.fmod(self.AICAPCAllNumber,9))
  FlightGroup:SetDefaultROE(ENUMS.ROE.WeaponHold)
  FlightGroup:SetDefaultROT(ENUMS.ROT.EvadeFire)
  FlightGroup:SetFuelLowRTB(true)
  FlightGroup:SetFuelLowThreshold(0.2)
  FlightGroup:SetEngageDetectedOff()
  FlightGroup:SetOutOfAAMRTB(true)
  return self
end

-- TODO FSMs
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- [Internal] onafterStart
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterStart(From, Event, To)
  self:I({From, Event, To})
  
  -- Set up control zone
  self.ControlZone = ZONE_RADIUS:New(self.OpsZone:GetName(),self.OpsZone:GetVec2(),UTILS.NMToMeters(self.ControlZoneRadius))
  if self.debug then
    self.ControlZone:DrawZone(-1,{0,1,0},1,{1,0,0},0.05,3,true)
    MARKER:New(self.ControlZone:GetCoordinate(),"Control Zone"):ToAll()
  end
  
  -- set up the AWACS and let it orbit
  local AwacsAW = self.AirWing -- Ops.AirWing#AIRWING
  local mission = AUFTRAG:NewORBIT_RACETRACK(self.OrbitZone:GetCoordinate(),self.AwacsAngels*1000,self.Speed,self.Heading,self.Leg)
  local timeonstation = (self.AwacsTimeOnStation + self.ShiftChangeTime) * 3600
  mission:SetTime(nil,timeonstation)
  self.CatchAllMissions[#self.CatchAllMissions+1] = mission
  
  AwacsAW:AddMission(mission)
  
  self.AwacsMission = mission
  self.AwacsInZone = false -- not yet arrived or gone again
  self.AwacsReady = false
  
  self:__Status(-30)
  return self
end

--- [Internal] onafterStatus
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterStatus(From, Event, To)
  self:I({From, Event, To})
  
  self:_SetClientMenus()
  
  local awacs = nil
  if self.AwacsFG then
    awacs = self.AwacsFG:GetGroup() -- Wrapper.Group#GROUP
  end
  
  local monitoringdata = self.MonitoringData -- #AWACS.MonitoringData
  
  if awacs and awacs:IsAlive() and not self.AwacsInZone then
    -- check if we arrived
    local orbitzone = self.OrbitZone -- Core.Zone#ZONE
    if awacs:IsInZone(orbitzone) then
      -- arrived
      self.AwacsInZone = true
      self:I(self.lid.."Arrived in Orbit Zone: " .. orbitzone:GetName())
      local text = string.format("%s on station for A O %s control.",self.callsigntxt,self.OpsZone:GetName() or "A O")

      local RadioEntry = {} -- #AWACS.RadioEntry
      RadioEntry.IsNew = true
      RadioEntry.TextTTS = text
      RadioEntry.TextScreen = text
      RadioEntry.ToScreen = true
      RadioEntry.Duration = STTS.getSpeechTime(text,1.1,false) or 8
      
      self.RadioQueue:Push(RadioEntry)
      self:_StartIntel(awacs)
      
    end
  end 
  
  --------------------------------
  --     AWACS
  --------------------------------
   
  if (awacs and awacs:IsAlive()) then
  
    -- Check on Awacs Mission Status
    local AWmission = self.AwacsMission -- Ops.Auftrag#AUFTRAG
    local awstatus = AWmission:GetState()
    local AWmissiontime = (timer.getTime() - self.AwacsTimeStamp)
    
    local AWTOSLeft = UTILS.Round((((self.AwacsTimeOnStation+self.ShiftChangeTime)*3600) - AWmissiontime),0) -- seconds
    
    AWTOSLeft = UTILS.Round(AWTOSLeft/60,0) -- minutes
    
    local ChangeTime = UTILS.Round(((self.ShiftChangeTime * 3600)/60),0)
    
    local Changedue = "No"
    
    if not self.ShiftChangeAwacsFlag and (AWTOSLeft <= ChangeTime or AWmission:IsOver()) then 
      Changedue = "Yes"
      self.ShiftChangeAwacsFlag = true
      self:__AwacsShiftChange(2) 
    end
    
    local report = REPORT:New("AWACS:")
    report:Add("====================")
    report:Add("AWACS:")
    report:Add(string.format("Auftrag Status: %s",awstatus))
    report:Add(string.format("TOS Left: %d min",AWTOSLeft))
    report:Add(string.format("Needs ShiftChange: %s",Changedue))
    
    local OpsGroups = AWmission:GetOpsGroups()
    local OpsGroup = self:_GetAliveOpsGroupFromTable(OpsGroups) -- Ops.OpsGroup#OPSGROUP
    if OpsGroup then
      local OpsName = OpsGroup:GetName() or "Unknown"
      local OpsCallSign = OpsGroup:GetCallsignName() or "Unknown"
      report:Add(string.format("Mission FG %s",OpsName))
      report:Add(string.format("Callsign %s",OpsCallSign))
      report:Add(string.format("Mission FG State %s",OpsGroup:GetState()))
    else
      report:Add("***** Cannot obtain (yet) this missions OpsGroup!")
    end
    
    -- Check for replacement mission - if any
    if self.ShiftChangeAwacsFlag and self.ShiftChangeAwacsRequested then -- Ops.Auftrag#AUFTRAG
      AWmission = self.AwacsMissionReplacement
      local esstatus = AWmission:GetState()
      local ESmissiontime = (timer.getTime() - self.AwacsTimeStamp)
      local ESTOSLeft = UTILS.Round((((self.AwacsTimeOnStation+self.ShiftChangeTime)*3600) - ESmissiontime),0) -- seconds
      ESTOSLeft = UTILS.Round(ESTOSLeft/60,0) -- minutes
      local ChangeTime = UTILS.Round(((self.ShiftChangeTime * 3600)/60),0)
      --local Changedue = "No"
      
      --report:Add("====================")
      report:Add("AWACS REPLACEMENT:")
      report:Add(string.format("Auftrag Status: %s",esstatus))
      report:Add(string.format("TOS Left: %d min",ESTOSLeft))
      --report:Add(string.format("Needs ShiftChange: %s",Changedue))
      
      local OpsGroups = AWmission:GetOpsGroups()
      local OpsGroup = self:_GetAliveOpsGroupFromTable(OpsGroups) -- Ops.OpsGroup#OPSGROUP
      if OpsGroup then
        local OpsName = OpsGroup:GetName() or "Unknown"
        local OpsCallSign = OpsGroup:GetCallsignName() or "Unknown"
        report:Add(string.format("Mission FG %s",OpsName))
        report:Add(string.format("Callsign %s",OpsCallSign))
        report:Add(string.format("Mission FG State %s",OpsGroup:GetState()))
      else
        report:Add("***** Cannot obtain (yet) this missions OpsGroup!")
      end
      
      if AWmission:IsExecuting() then
        -- make the actual change in the queue
        self.ShiftChangeAwacsFlag = false
        self.ShiftChangeAwacsRequested = false
        -- cancel old mission
        if self.AwacsMission and self.AwacsMission:IsNotOver() then
            self.AwacsMission:Cancel()
        end
        self.AwacsMission = self.AwacsMissionReplacement
        self.AwacsMissionReplacement = nil
        self.AwacsTimeStamp = timer.getTime()
        report:Add("*** Replacement DONE ***")
      end
      report:Add("====================")
    end
    
    --------------------------------
    --     ESCORTS
    --------------------------------
                       
    if self.HasEscorts then
      local ESmission = self.EscortMission -- Ops.Auftrag#AUFTRAG
      local esstatus = ESmission:GetState()
      local ESmissiontime = (timer.getTime() - self.EscortsTimeStamp)
      local ESTOSLeft = UTILS.Round((((self.EscortsTimeOnStation+self.ShiftChangeTime)*3600) - ESmissiontime),0) -- seconds
      ESTOSLeft = UTILS.Round(ESTOSLeft/60,0) -- minutes
      local ChangeTime = UTILS.Round(((self.ShiftChangeTime * 3600)/60),0)
      local Changedue = "No"
      
      if (ESTOSLeft <= ChangeTime and not self.ShiftChangeEscortsFlag) or (ESmission:IsOver() and not self.ShiftChangeEscortsFlag) then 
        Changedue = "Yes" 
        self.ShiftChangeEscortsFlag = true -- set this back when new Escorts arrived
        self:__EscortShiftChange(2)
      end
      
      report:Add("====================")
      report:Add("ESCORTS:")
      report:Add(string.format("Auftrag Status: %s",esstatus))
      report:Add(string.format("TOS Left: %d min",ESTOSLeft))
      report:Add(string.format("Needs ShiftChange: %s",Changedue))
      
      local OpsGroups = ESmission:GetOpsGroups()
      local OpsGroup = self:_GetAliveOpsGroupFromTable(OpsGroups) -- Ops.OpsGroup#OPSGROUP
      if OpsGroup then
        local OpsName = OpsGroup:GetName() or "Unknown"
        local OpsCallSign = OpsGroup:GetCallsignName() or "Unknown"
        report:Add(string.format("Mission FG %s",OpsName))
        report:Add(string.format("Callsign %s",OpsCallSign))
        report:Add(string.format("Mission FG State %s",OpsGroup:GetState()))
        monitoringdata.EscortsStateMission = esstatus
        monitoringdata.EscortsStateFG = OpsGroup:GetState()
      else
        report:Add("***** Cannot obtain (yet) this missions OpsGroup!")
      end
      
      report:Add("====================")
      
      -- Check for replacement mission - if any
      if self.ShiftChangeEscortsFlag and self.ShiftChangeEscortsRequested then -- Ops.Auftrag#AUFTRAG
        ESmission = self.EscortMissionReplacement
        local esstatus = ESmission:GetState()
        local ESmissiontime = (timer.getTime() - self.EscortsTimeStamp)
        local ESTOSLeft = UTILS.Round((((self.EscortsTimeOnStation+self.ShiftChangeTime)*3600) - ESmissiontime),0) -- seconds
        ESTOSLeft = UTILS.Round(ESTOSLeft/60,0) -- minutes
        local ChangeTime = UTILS.Round(((self.ShiftChangeTime * 3600)/60),0)
        --local Changedue = "No"
        
        --report:Add("====================")
        report:Add("ESCORTS REPLACEMENT:")
        report:Add(string.format("Auftrag Status: %s",esstatus))
        report:Add(string.format("TOS Left: %d min",ESTOSLeft))
        --report:Add(string.format("Needs ShiftChange: %s",Changedue))
        
        local OpsGroups = ESmission:GetOpsGroups()
        local OpsGroup = self:_GetAliveOpsGroupFromTable(OpsGroups) -- Ops.OpsGroup#OPSGROUP
        if OpsGroup then
          local OpsName = OpsGroup:GetName() or "Unknown"
          local OpsCallSign = OpsGroup:GetCallsignName() or "Unknown"
          report:Add(string.format("Mission FG %s",OpsName))
          report:Add(string.format("Callsign %s",OpsCallSign))
          report:Add(string.format("Mission FG State %s",OpsGroup:GetState()))
        else
          report:Add("***** Cannot obtain (yet) this missions OpsGroup!")
        end
        
        if ESmission:IsExecuting() then
          -- make the actual change in the queue
          self.ShiftChangeEscortsFlag = false
          self.ShiftChangeEscortsRequested = false
          -- cancel old mission
          if self.EscortMission and self.EscortMission:IsNotOver() then
              self.EscortMission:Cancel()
          end
          self.EscortMission = self.EscortMissionReplacement
          self.EscortMissionReplacement = nil
          self.EscortsTimeStamp = timer.getTime()
          report:Add("*** Replacement DONE ***")
        end
        report:Add("====================")
      end
    end
      
    if self.debug then  
      self:T(report:Text())
    end
    
    -- Check on AUFTRAG status for CAP AI
    if self:Is("Running") then
      self:_CheckAICAPOnStation()
    end
  
  else
   -- do other stuff
  
  end
  
  -- Check task queue (both)
  if self:Is("Running") then
    self:_CheckTaskQueue()
  end
  
  monitoringdata.AwacsShiftChange = self.ShiftChangeAwacsFlag
  if self.AwacsFG then
   monitoringdata.AwacsStateFG = self.AwacsFG:GetState()
  end
  monitoringdata.AwacsStateMission = self.AwacsMission:GetState()
  --monitoringdata.EscortsStateMission = self.Escor
  monitoringdata.EscortsShiftChange = self.ShiftChangeEscortsFlag
  monitoringdata.AICAPCurrent = self.AICAPMissions:Count()
  monitoringdata.AICAPMax = self.MaxAIonCAP
  --monitoringdata.Players = self.clientset:CountAlive()
  monitoringdata.Airwings = self.CAPAirwings:Count()
  
  self.MonitoringData = monitoringdata
  
  if self.debug then
    self:_LogStatistics()
  end
  
  self:__Status(30)
  
  return self
end

--- [Internal] onafterStop
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterStop(From, Event, To)
  self:T({From, Event, To})
  -- unhandle stuff, exit intel
  
  self.intel:Stop()
  
  local AWFiFo = self.CAPAirwings -- Utilities.FiFo#FIFO
  local AWStack = AWFiFo:GetPointerStack()
  for _ID,_AWID in pairs(AWStack) do
    local SubAW = self.CAPAirwings:ReadByPointer(_ID)
    if SubAW then
      SubAW:RemoveUsingOpsAwacs()
    end
  end
  
  return self
end

--- [Internal] onafterAssignAnchor
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param #number GID Group ID
-- @return #AWACS self
function AWACS:onafterAssignAnchor(From, Event, To, GID)
  self:T({From, Event, To, "GID = " .. GID})
  self:_AssignAnchorToID(GID)
  return self
end

--- [Internal] onafterCheckedOut
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param #AWACS.ManagedGroup.GID Group ID 
-- @param #number AnchorStackNo
-- @param #number Angels
-- @return #AWACS self
function AWACS:onafterCheckedOut(From, Event, To, GID, AnchorStackNo, Angels)
  self:T({From, Event, To, "GID = " .. GID})
  self:_RemoveIDFromAnchor(GID,AnchorStackNo,Angels)
  return self
end

--- [Internal] onafterAssignedAnchor
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param #number GID Managed Group ID
-- @param #AWACS.AnchorData Anchor
-- @param #number AnchorStackNo
-- @return #AWACS self
function AWACS:onafterAssignedAnchor(From, Event, To, GID, Anchor, AnchorStackNo, AnchorAngels)
  self:I({From, Event, To, "GID=" .. GID, "Stack=" .. AnchorStackNo})
  -- TODO
  local managedgroup = self.ManagedGrps[GID] -- #AWACS.ManagedGroup
  if not managedgroup then
    self:E(self.lid .. "**** GID "..GID.." Not Registered!")
    return self
  end
  managedgroup.AnchorStackNo = AnchorStackNo
  managedgroup.AnchorStackAngels = AnchorAngels
  self.ManagedGrps[GID] = managedgroup
  local isPlayer = managedgroup.IsPlayer
  local isAI = managedgroup.IsAI
  local Group = managedgroup.Group
  local CallSign = managedgroup.CallSign or "unknown 1 1"
  local AnchorName = Anchor.AnchorZone:GetName() or "unknown"
  local AnchorCoordTxt = Anchor.AnchorZoneCoordinateText or "unknown"
  local Angels = AnchorAngels or 25
  local AnchorSpeed = self.CapSpeedBase or 220
  local AuftragsNr = managedgroup.CurrentAuftrag

  local textTTS = string.format("%s. %s. Anchor at %s at angels %d doing %d knots. Wait for task assignment.",self.callsigntxt,CallSign,AnchorName,Angels,AnchorSpeed)
  local ROEROT = self.AwacsROE.." "..self.AwacsROT
  local textScreen = string.format("%s. %s.\nAnchor at %s\nAngels %d\nSpeed %d knots\nCoord %s\nROE %s\nWait for task assignment.",self.callsigntxt,CallSign,AnchorName,Angels,AnchorSpeed,AnchorCoordTxt,ROEROT)
  local TextTasking = string.format("%s. %s.\nAnchor at %s\nAngels %d\nSpeed %d knots\nCoord %s\nROE %s",self.callsigntxt,CallSign,AnchorName,Angels,AnchorSpeed,AnchorCoordTxt,ROEROT)
  
  local RadioEntry = {} -- #AWACS.RadioEntry
  RadioEntry.IsNew = true
  RadioEntry.TextTTS = textTTS
  RadioEntry.TextScreen = textScreen
  RadioEntry.GroupID = GID
  RadioEntry.IsGroup = isPlayer
  RadioEntry.Duration = STTS.getSpeechTime(textTTS,1.0,false) or 10
  RadioEntry.ToScreen = isPlayer
  
  self.RadioQueue:Push(RadioEntry)
      
  self:_CreateTaskForGroup(GID,AWACS.TaskDescription.ANCHOR,TextTasking,Anchor.AnchorZone)
  
 -- if isAI and AuftragsNr and AuftragsNr > 0 and self.AICAPMissions:HasUniqueID(AuftragsNr) then
 
  -- if it's a Alert5, we want to push CAP instead
  if isAI then
    local auftrag = managedgroup.FlightGroup:GetMissionCurrent() -- Ops.Auftrag#AUFTRAG
    if auftrag then
      local auftragtype = auftrag:GetType()
      if auftragtype == AUFTRAG.Type.ALERT5 then
        -- all correct
        local capauftrag = AUFTRAG:NewCAP(Anchor.AnchorZone,Angels*1000,AnchorSpeed,Anchor.AnchorZone:GetCoordinate(),0,15,{})
        capauftrag:SetTime(nil,((self.CAPTimeOnStation*3600)+(15*60)))
        self.CatchAllMissions[#self.CatchAllMissions+1] = capauftrag
        managedgroup.FlightGroup:AddMission(capauftrag)
        auftrag:Cancel()
      else
       self:E("**** AssignedAnchor but Auftrag NOT ALERT5!")
      end
    else
      self:E("**** AssignedAnchor but NO Auftrag!")
    end 
  end  
  return self
end

--- [Internal] onafterNewCluster
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.Intelligence#INTEL.Cluster Cluster
-- @return #AWACS self
function AWACS:onafterNewCluster(From,Event,To,Cluster)
  self:T({From, Event, To, Cluster})
  return self
end
  
--- [Internal] onafterNewContact
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.Intelligence#INTEL.Contact Contact
-- @return #AWACS self 
function AWACS:onafterNewContact(From,Event,To,Contact)
  self:T({From, Event, To, Contact})
  
  self.CID = self.CID + 1
  self.Countactcounter = self.Countactcounter + 1
  
  local managedcontact = {} -- #AWACS.ManagedContact
  managedcontact.CID = self.CID
  managedcontact.Contact = Contact
  -- TODO set as per tech age
  managedcontact.IFF = "Spades" -- no IFF yet
  managedcontact.Target = TARGET:New(Contact.group)
  managedcontact.LinkedGroup = 0
  managedcontact.LinkedTask = 0
  managedcontact.Status = AWACS.TaskStatus.IDLE
  local phoneid = math.fmod(self.Countactcounter,27)
  if phoneid == 0 then phoneid = 1 end
  managedcontact.TargetGroupNaming = AWACS.Phonetic[phoneid]
  
  self.Contacts:Push(Contact,self.CID)
  self.ManagedContacts:Push(Contact,self.CID)
  
  self:_AnnounceContact(Contact,true,nil,false)
  
  return self
end
  
--- [Internal] onafterLostContact
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.Intelligence#INTEL.Contact Contact
-- @return #AWACS self
function AWACS:onafterLostContact(From,Event,To,Contact)
  self:T({From, Event, To, Contact})
  -- TODO Check Idle, Assigned Tasks for status
  return self
end
  
--- [Internal] onafterLostCluster
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @param Ops.Intelligence#INTEL.Cluster Cluster
-- @param Ops.Auftrag#AUFTRAG Mission
-- @return #AWACS self
function AWACS:onafterLostCluster(From,Event,To,Cluster,Mission)
  self:T({From, Event, To})
  -- TODO Remove Cluster from Picture
  return self
end

--- [Internal] onafterCheckRadioQueue
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterCheckRadioQueue(From,Event,To)
 self:T({From, Event, To})
 -- do we have messages queued?
 
 local nextcall = 10
 if self.RadioQueue:IsNotEmpty() then
  local RadioEntry = self.RadioQueue:Pull() -- #AWACS.RadioEntry
  
  self:T({RadioEntry})
  
  if not RadioEntry.FromAI then
    -- AI AWACS Speaking
    self.AwacsFG:RadioTransmission(RadioEntry.TextTTS,1,false)
    self:I(RadioEntry.TextTTS)
  else
    -- CAP AI speaking
    if RadioEntry.GroupID and RadioEntry.GroupID ~= 0 then
      local managedgroup = self.ManagedGrps[RadioEntry.GroupID] -- #AWACS.ManagedGroup
      if managedgroup and managedgroup.FlightGroup and managedgroup.FlightGroup:IsAlive() then
        managedgroup.FlightGroup:RadioTransmission(RadioEntry.TextTTS,1,false)
        self:I(RadioEntry.TextTTS)
      end
    end
  end
  
  if RadioEntry.Duration then nextcall = RadioEntry.Duration end
  if RadioEntry.ToScreen and RadioEntry.TextScreen then
    if RadioEntry.GroupID and RadioEntry.GroupID ~= 0 then
      local managedgroup = self.ManagedGrps[RadioEntry.GroupID] -- #AWACS.ManagedGroup
      if managedgroup and managedgroup.Group and managedgroup.Group:IsAlive() then
        MESSAGE:New(RadioEntry.TextScreen,20,"AWACS"):ToGroup(managedgroup.Group)
        self:I(RadioEntry.TextScreen)
      end
    else
      MESSAGE:New(RadioEntry.TextScreen,20,"AWACS"):ToCoalition(self.coalition)
    end
  end
 end
 
 if self:Is("Running") then
  -- exit if stopped
  self:__CheckRadioQueue(nextcall+2)
 end
 return self
end

--- [Internal] onafterEscortShiftChange
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterEscortShiftChange(From,Event,To)
  self:I({From, Event, To})
  -- request new Escorts, check if AWACS-FG still alive first!
  if self.AwacsFG and self.ShiftChangeEscortsFlag and not self.ShiftChangeEscortsRequested then
    local awacs = self.AwacsFG:GetGroup() -- Wrapper.Group#GROUP
    if awacs and awacs:IsAlive() then
      -- ok we're good to re-request
      self.ShiftChangeEscortsRequested = true
      self.EscortsTimeStamp = timer.getTime()
      self:_StartEscorts(true)
    else
      -- should not happen
      self:E("**** AWACS group dead at onafterEscortShiftChange!")
    end
  end
  return self
end

--- [Internal] onafterAwacsShiftChange
-- @param #AWACS self
-- @param #string From 
-- @param #string Event
-- @param #string To
-- @return #AWACS self
function AWACS:onafterAwacsShiftChange(From,Event,To)
  self:I({From, Event, To})
  -- request new Escorts, check if AWACS-FG still alive first!
  if self.AwacsFG and self.ShiftChangeAwacsFlag and not self.ShiftChangeAwacsRequested then
    
    -- ok we're good to re-request
    self.ShiftChangeAwacsRequested = true
    self.AwacsTimeStamp = timer.getTime()
    
    -- set up the AWACS and let it orbit
    local AwacsAW = self.AirWing -- Ops.AirWing#AIRWING
    local mission = AUFTRAG:NewORBIT_RACETRACK(self.OrbitZone:GetCoordinate(),self.AwacsAngels*1000,self.Speed,self.Heading,self.Leg)
    self.CatchAllMissions[#self.CatchAllMissions+1] = mission
    local timeonstation = (self.AwacsTimeOnStation + self.ShiftChangeTime) * 3600
    mission:SetTime(nil,timeonstation)
  
    AwacsAW:AddMission(mission)
    
    self.AwacsMissionReplacement = mission
    
  end
  return self
end

--- On after "FlightOnMission".
-- @param #AWACS self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Ops.FlightGroup#FLIGHTGROUP FlightGroup on mission.
-- @param Ops.Auftrag#AUFTRAG Mission The requested mission.
-- @return #AWACS self
function AWACS:onafterFlightOnMission(From, Event, To, FlightGroup, Mission)
  self:I({From, Event, To})
  -- coming back from AW, set up the flight
  self:I("FlightGroup " .. FlightGroup:GetName() .. " Mission " .. Mission:GetName() .. " Type "..Mission:GetType())
  self.CatchAllFGs[#self.CatchAllFGs+1] = FlightGroup
  if not self:Is("Stopped") then
    if not self.AwacsReady or self.ShiftChangeAwacsFlag or self.ShiftChangeEscortsFlag then
     self:_StartSettings(FlightGroup,Mission)
    elseif Mission and (Mission:GetType() == AUFTRAG.Type.CAP or Mission:GetType() == AUFTRAG.Type.ALERT5 or Mission:GetType() == AUFTRAG.Type.ORBIT) then
        if not self.FlightGroups:HasUniqueID(FlightGroup:GetName()) then
          self:I("Pushing FG " .. FlightGroup:GetName() .. " to stack!")
          self.FlightGroups:Push(FlightGroup,FlightGroup:GetName())
        end
    end
  end
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- END AWACS
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
end -- end do

--- Testing
_SETTINGS:SetLocale("en")
_SETTINGS:SetImperial()
_SETTINGS:SetPlayerMenuOff()

-- We need an AirWing
local AwacsAW = AIRWING:New("AirForce WH-1","AirForce One")
AwacsAW:SetReportOn()
AwacsAW:SetMarker(true)
AwacsAW:SetAirbase(AIRBASE:FindByName(AIRBASE.Caucasus.Kutaisi))
AwacsAW:SetRespawnAfterDestroyed(900)
AwacsAW:__Start(2)

-- And a couple of Squads
-- AWACS itself
local Squad_One = SQUADRON:New("Awacs One",2,"Awacs North")
Squad_One:AddMissionCapability({AUFTRAG.Type.ORBIT},100)
Squad_One:SetFuelLowRefuel(false)
Squad_One:SetFuelLowThreshold(0.2)
Squad_One:SetTurnoverTime(10,20)
AwacsAW:AddSquadron(Squad_One)
AwacsAW:NewPayload("Awacs One One",-1,{AUFTRAG.Type.ORBIT},100)

-- Escorts
local Squad_Two = SQUADRON:New("Escorts",4,"Escorts North")
Squad_Two:AddMissionCapability({AUFTRAG.Type.ESCORT})
Squad_Two:SetFuelLowRefuel(true)
Squad_Two:SetFuelLowThreshold(0.3)
Squad_Two:SetTurnoverTime(10,20)
AwacsAW:AddSquadron(Squad_Two)
AwacsAW:NewPayload("Escorts",-1,{AUFTRAG.Type.ESCORT},100)

-- CAP
local Squad_Three = SQUADRON:New("CAP",2,"CAP North")
Squad_Three:AddMissionCapability({AUFTRAG.Type.ALERT5, AUFTRAG.Type.CAP, AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT},80)
Squad_Three:SetFuelLowRefuel(true)
Squad_Three:SetFuelLowThreshold(0.3)
Squad_Three:SetTurnoverTime(10,20)
AwacsAW:AddSquadron(Squad_Three)
AwacsAW:NewPayload("Aerial-1-2",-1,{AUFTRAG.Type.ALERT5,AUFTRAG.Type.CAP, AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT},100)

-- We need a secondary AirWing for testing
local AwacsAW2 = AIRWING:New("AirForce WH-2","AirForce Two")
AwacsAW2:SetReportOn()
AwacsAW2:SetMarker(true)
AwacsAW2:SetAirbase(AIRBASE:FindByName(AIRBASE.Caucasus.Batumi))
AwacsAW2:SetRespawnAfterDestroyed(900)
AwacsAW2:__Start(2)

-- CAP2
local Squad_ThreeOne = SQUADRON:New("CAP2",4,"CAP West")
Squad_ThreeOne:AddMissionCapability({AUFTRAG.Type.ALERT5, AUFTRAG.Type.CAP, AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT},80)
Squad_ThreeOne:SetFuelLowRefuel(true)
Squad_ThreeOne:SetFuelLowThreshold(0.3)
Squad_ThreeOne:SetTurnoverTime(10,20)
AwacsAW2:AddSquadron(Squad_ThreeOne)
AwacsAW2:NewPayload("CAP 2-1",-1,{AUFTRAG.Type.ALERT5,AUFTRAG.Type.CAP, AUFTRAG.Type.GCICAP, AUFTRAG.Type.INTERCEPT},100)

-- Get AWACS started
local testawacs = AWACS:New("AWACS North",AwacsAW,"blue",AIRBASE.Caucasus.Kutaisi,"Awacs Orbit",ZONE:FindByName("NW Zone"),"Anchor One",255,radio.modulation.AM )
testawacs:SetEscort(2)
testawacs:SetAwacsDetails(CALLSIGN.AWACS.Darkstar,1,300,300,60,20)
testawacs:SetSRS("E:\\Program Files\\DCS-SimpleRadio-Standalone","female","en-GB",5010,nil)
testawacs:AddCAPAirWing(AwacsAW2)
testawacs:__Start(5)
