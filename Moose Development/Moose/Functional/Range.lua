--- **Functional** - Range Practice.
--  
-- ===
-- 
-- The RANGE class enables easy set up of bombing and strafing ranges within DCS World.
-- 
-- Implementation is based on the [Simple Range Script](https://forums.eagle.ru/showthread.php?t=157991) by [Ciribob](https://forums.eagle.ru/member.php?u=112175), which itself was motivated
-- by a script by SNAFU [see here](https://forums.eagle.ru/showthread.php?t=109174).
-- 
-- [476th - Air Weapons Range Objects mod](http://www.476vfightergroup.com/downloads.php?do=file&id=287) is highly recommended for this class.
-- 
-- ## Features:
--
--   * Impact points of bombs, rockets and missils are recorded and distance to closest range target is measured and reported to the player.
--   * Number of hits on strafing passes are counted and reported. Also the percentage of hits w.r.t fired shots is evaluated. 
--   * Results of all bombing and strafing runs are stored and top 10 results can be displayed. 
--   * Range targets can be marked by smoke.
--   * Range can be illuminated by illumination bombs for night practices.
--   * Bomb, rocket and missile impact points can be marked by smoke.
--   * Direct hits on targets can trigger flares.
--   * Smoke and flare colors can be adjusted for each player via radio menu.
--   * Range information and weather report at the range can be reported via radio menu.
-- 
-- More information and examples can be found below.
-- 
-- ===
-- 
-- ### [MOOSE YouTube Channel](https://www.youtube.com/channel/UCjrA9j5LQoWsG4SpS8i79Qg) 
-- ### [MOOSE - On the Range - Demonstration Video](https://www.youtube.com/watch?v=kIXcxNB9_3M)
-- 
-- ===
-- 
-- ### Author: **[funkyfranky](https://forums.eagle.ru/member.php?u=115026)**
-- 
-- ### Contributions: [FlightControl](https://forums.eagle.ru/member.php?u=89536), [Ciribob](https://forums.eagle.ru/member.php?u=112175)
-- 
-- ===
-- @module Functional.Range
-- @image Range.JPG

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- RANGE class
-- @type RANGE
-- @field #string ClassName Name of the Class.
-- @field #boolean Debug If true, debug info is send as messages on the screen.
-- @field #string rangename Name of the range.
-- @field Core.Point#COORDINATE location Coordinate of the range location.
-- @field #number rangeradius Radius of range defining its total size for e.g. smoking bomb impact points and sending radio messages. Default 5 km.
-- @field Core.Zone#ZONE rangezone MOOSE zone object of the range. For example, no bomb impacts are smoked if bombs fall outside of the range zone. 
-- @field #table strafeTargets Table of strafing targets.
-- @field #table bombingTargets Table of targets to bomb.
-- @field #number nbombtargets Number of bombing targets.
-- @field #number nstrafetargets Number of strafing targets.
-- @field #table MenuAddedTo Table for monitoring which players already got an F10 menu.
-- @field #table planes Table for administration.
-- @field #table strafeStatus Table containing the current strafing target a player as assigned to.
-- @field #table strafePlayerResults Table containing the strafing results of each player.
-- @field #table bombPlayerResults Table containing the bombing results of each player.
-- @field #table PlayerSettings Indiviual player settings.
-- @field #number dtBombtrack Time step [sec] used for tracking released bomb/rocket positions. Default 0.005 seconds.
-- @field #number BombtrackThreshold Bombs/rockets/missiles are only tracked if player-range distance is smaller than this threashold [m]. Default 25000 m.
-- @field #number Tmsg Time [sec] messages to players are displayed. Default 30 sec.
-- @field #string examinergroupname Name of the examiner group which should get all messages.
-- @field #boolean examinerexclusive If true, only the examiner gets messages. If false, clients and examiner get messages.
-- @field #number strafemaxalt Maximum altitude above ground for registering for a strafe run. Default is 914 m = 3000 ft. 
-- @field #number ndisplayresult Number of (player) results that a displayed. Default is 10.
-- @field Utilities.Utils#SMOKECOLOR BombSmokeColor Color id used for smoking bomb targets.
-- @field Utilities.Utils#SMOKECOLOR StrafeSmokeColor Color id used to smoke strafe targets.
-- @field Utilities.Utils#SMOKECOLOR StrafePitSmokeColor Color id used to smoke strafe pit approach boxes. 
-- @field #number illuminationminalt Minimum altitude AGL in meters at which illumination bombs are fired. Default is 500 m.
-- @field #number illuminationmaxalt Maximum altitude AGL in meters at which illumination bombs are fired. Default is 1000 m.
-- @field #number scorebombdistance Distance from closest target up to which bomb hits are counted. Default 1000 m.
-- @field #number TdelaySmoke Time delay in seconds between impact of bomb and starting the smoke. Default 3 seconds.
-- @field #boolean eventmoose If true, events are handled by MOOSE. If false, events are handled directly by DCS eventhandler. Default true.
-- @field #boolean trackbombs If true (default), all bomb types are tracked and impact point to closest bombing target is evaluated.
-- @field #boolean trackrockets If true (default), all rocket types are tracked and impact point to closest bombing target is evaluated.
-- @field #boolean trackmissiles If true (default), all missile types are tracked and impact point to closest bombing target is evaluated.
-- @extends Core.Base#BASE

--- Enables a mission designer to easily set up practice ranges in DCS. A new RANGE object can be created with the @{#RANGE.New}(rangename) contructor.
-- The parameter "rangename" defindes the name of the range. It has to be unique since this is also the name displayed in the radio menu.
-- 
-- Generally, a range consists of strafe pits and bombing targets. For strafe pits the number of hits for each pass is counted and tabulated.
-- For bombing targets, the distance from the impact point of the bomb, rocket or missile to the closest range target is measured and tabulated.
-- Each player can display his best results via a function in the radio menu or see the best best results from all players.
-- 
-- When all targets have been defined in the script, the range is started by the @{#RANGE.Start}() command.
-- 
-- **IMPORTANT**
-- 
-- Due to a DCS bug, it is not possible to directly monitor when a player enters a plane. So in a mission with client slots, it is vital that
-- a player first enters as spector and **after that** jumps into the slot of his aircraft!
-- If that is not done, the script is not started correctly. This can be checked by looking at the radio menues. If the mission was entered correctly,
-- there should be an "On the Range" menu items in the "F10. Other..." menu. 
-- 
-- ## Strafe Pits
-- Each strafe pit can consist of multiple targets. Often one findes two or three strafe targets next to each other.
-- 
-- A strafe pit can be added to the range by the @{#RANGE.AddStrafePit}(*targetnames, boxlength, boxwidth, heading, inverseheading, goodpass, foulline*) function.
-- 
-- * The first parameter *targetnames* defines the target or targets. This has to be given as a lua table which contains the names of @{Wrapper.Unit} or @{Static} objects defined in the mission editor. 
-- * In order to perform a valid pass on the strafe pit, the pilot has to begin his run from the correct direction. Therefore, an "approach box" is defined in front
--   of the strafe targets. The parameters *boxlength* and *boxwidth* define the size of the box while the parameter *heading* defines its direction.
--   If the parameter *heading* is passed as **nil**, the heading is automatically taken from the heading of the first target unit as defined in the ME.
--   The parameter *inverseheading* turns the heading around by 180 degrees. This is sometimes useful, since the default heading of strafe target units point in the
--   wrong/opposite direction.
-- * The parameter *goodpass* defines the number of hits a pilot has to achive during a run to be judged as a "good" pass.
-- * The last parameter *foulline* sets the distance from the pit targets to the foul line. Hit from closer than this line are not counted!
-- 
-- Another function to add a strafe pit is @{#RANGE.AddStrafePitGroup}(*group, boxlength, boxwidth, heading, inverseheading, goodpass, foulline*). Here,
-- the first parameter *group* is a MOOSE @{Wrapper.Group} object and **all** units in this group define **one** strafe pit.
-- 
-- Finally, a valid approach has to be performed below a certain maximum altitude. The default is 914 meters (3000 ft) AGL. This is a parameter valid for all
-- strafing pits of the range and can be adjusted by the @{#RANGE.SetMaxStrafeAlt}(maxalt) function.
-- 
-- ## Bombing targets
-- One ore multiple bombing targets can be added to the range by the @{#RANGE.AddBombingTargets}(targetnames, goodhitrange, randommove) function.
-- 
-- * The first parameter *targetnames* has to be a lua table, which contains the names of @{Wrapper.Unit} and/or @{Static} objects defined in the mission editor.
--   Note that the @{Range} logic **automatically** determines, if a name belongs to a @{Wrapper.Unit} or @{Static} object now.
-- * The (optional) parameter *goodhitrange* specifies the radius around the target. If a bomb or rocket falls at a distance smaller than this number, the hit is considered to be "good".
-- * If final (optional) parameter "*randommove*" can be enabled to create moving targets. If this parameter is set to true, the units of this bombing target will randomly move within the range zone.
--   Note that there might be quirks since DCS units can get stuck in buildings etc. So it might be safer to manually define a route for the units in the mission editor if moving targets are desired. 
--   
-- Another possibility to add bombing targets is the @{#RANGE.AddBombingTargetGroup}(*group, goodhitrange, randommove*) function. Here the parameter *group* is a MOOSE @{Wrapper.Group} object
-- and **all** units in this group are defined as bombing targets.
-- 
-- ## Fine Tuning
-- Many range parameters have good default values. However, the mission designer can change these settings easily with the supplied user functions:
-- 
-- * @{#RANGE.SetMaxStrafeAlt}() sets the max altitude for valid strafing runs.
-- * @{#RANGE.SetMessageTimeDuration}() sets the duration how long (most) messages are displayed.
-- * @{#RANGE.SetDisplayedMaxPlayerResults}() sets the number of results displayed.
-- * @{#RANGE.SetRangeRadius}() defines the total range area. 
-- * @{#RANGE.SetBombTargetSmokeColor}() sets the color used to smoke bombing targets. 
-- * @{#RANGE.SetStrafeTargetSmokeColor}() sets the color used to smoke strafe targets.
-- * @{#RANGE.SetStrafePitSmokeColor}() sets the color used to smoke strafe pit approach boxes.
-- * @{#RANGE.SetSmokeTimeDelay}() sets the time delay between smoking bomb/rocket impact points after impact.
-- * @{#RANGE.TrackBombsON}() or @{#RANGE.TrackBombsOFF}() can be used to enable/disable tracking and evaluating of all bomb types a player fires.
-- * @{#RANGE.TrackRocketsON}() or @{#RANGE.TrackRocketsOFF}() can be used to enable/disable tracking and evaluating of all rocket types a player fires.
-- * @{#RANGE.TrackMissilesON}() or @{#RANGE.TrackMissilesOFF}() can be used to enable/disable tracking and evaluating of all missile types a player fires.
-- 
-- ## Radio Menu
-- Each range gets a radio menu with various submenus where each player can adjust his individual settings or request information about the range or his scores.
-- 
-- The main range menu can be found at "F10. Other..." --> "Fxx. On the Range..." --> "F1. Your Range Name...".
--
-- The range menu contains the following submenues:
-- 
-- * "F1. Mark Targets": Various ways to mark targets. 
-- * "F2. My Settings": Player specific settings.
-- * "F3. Stats" Player: statistics and scores.
-- * "Range Information": Information about the range, such as bearing and range. Also range and player specific settings are displayed.
-- * "Weather Report": Temperatur, wind and QFE pressure information is provided. 
-- 
-- ## Examples
-- 
-- ### Goldwater Range
-- This example shows hot to set up the [Barry M. Goldwater range](https://en.wikipedia.org/wiki/Barry_M._Goldwater_Air_Force_Range).
-- It consists of two strafe pits each has two targets plus three bombing targets.
-- 
--      -- Strafe pits. Each pit can consist of multiple targets. Here we have two pits and each of the pits has two targets.
--      -- These are names of the corresponding units defined in the ME.
--      local strafepit_left={"GWR Strafe Pit Left 1", "GWR Strafe Pit Left 2"}
--      local strafepit_right={"GWR Strafe Pit Right 1", "GWR Strafe Pit Right 2"}
--      
--      -- Table of bombing target names. Again these are the names of the corresponding units as defined in the ME.
--      local bombtargets={"GWR Bomb Target Circle Left", "GWR Bomb Target Circle Right", "GWR Bomb Target Hard"}
--      
--      -- Create a range object.
--      GoldwaterRange=RANGE:New("Goldwater Range")
--      
--      -- Distance between strafe target and foul line. You have to specify the names of the unit or static objects.
--      -- Note that this could also be done manually by simply measuring the distance between the target and the foul line in the ME.
--      GoldwaterRange:GetFoullineDistance("GWR Strafe Pit Left 1", "GWR Foul Line Left")
--      
--      -- Add strafe pits. Each pit (left and right) consists of two targets.
--      GoldwaterRange:AddStrafePit(strafepit_left, 3000, 300, nil, true, 20, fouldist)
--      GoldwaterRange:AddStrafePit(strafepit_right, nil, nil, nil, true, nil, fouldist)
--      
--      -- Add bombing targets. A good hit is if the bomb falls less then 50 m from the target.
--      GoldwaterRange:AddBombingTargets(bombtargets, 50)
--      
--      -- Start range.
--      GoldwaterRange:Start()
-- 
-- The [476th - Air Weapons Range Objects mod](http://www.476vfightergroup.com/downloads.php?do=file&id=287) is (implicitly) used in this example. 
-- 
-- ## Debugging
-- 
-- In case you have problems, it is always a good idea to have a look at your DCS log file. You find it in your "Saved Games" folder, so for example in
--      C:\Users\<yourname>\Saved Games\DCS\Logs\dcs.log
-- All output concerning the RANGE class should have the string "RANGE" in the corresponding line.
-- 
-- The verbosity of the output can be increased by adding the following lines to your script:
-- 
--      BASE:TraceOnOff(true)
--      BASE:TraceLevel(1)
--      BASE:TraceClass("RANGE")
-- 
-- To get even more output you can increase the trace level to 2 or even 3, c.f. @{BASE} for more details.
-- 
-- The function @{#RANGE.DebugON}() can be used to send messages on screen. It also smokes all defined strafe and bombing targets, the strafe pit approach boxes and the range zone.
-- 
-- Note that it can happen that the RANGE radio menu is not shown. Check that the range object is defined as a **global** variable rather than a local one.
-- The could avoid the lua garbage collection to accidentally/falsely deallocate the RANGE objects. 
-- 
-- 
-- 
-- @field #RANGE
RANGE={
  ClassName = "RANGE",
  Debug=false,
  rangename=nil,
  location=nil,
  rangeradius=5000,
  rangezone=nil,
  strafeTargets={},
  bombingTargets={},
  nbombtargets=0,
  nstrafetargets=0,
  MenuAddedTo = {},
  planes = {},
  strafeStatus = {},
  strafePlayerResults = {},
  bombPlayerResults = {},
  PlayerSettings = {},
  dtBombtrack=0.005,
  BombtrackThreshold=25000,
  Tmsg=30,
  examinergroupname=nil,
  examinerexclusive=nil,
  strafemaxalt=914,
  ndisplayresult=10,
  BombSmokeColor=SMOKECOLOR.Red,
  StrafeSmokeColor=SMOKECOLOR.Green,
  StrafePitSmokeColor=SMOKECOLOR.White,
  illuminationminalt=500,
  illuminationmaxalt=1000,
  scorebombdistance=1000,
  TdelaySmoke=3.0,
  eventmoose=true,
  trackbombs=true,
  trackrockets=true,
  trackmissiles=true,
}

--- Default range parameters.
-- @list Defaults
RANGE.Defaults={
  goodhitrange=25,
  strafemaxalt=914,
  dtBombtrack=0.005,
  Tmsg=30,
  ndisplayresult=10,
  rangeradius=5000,
  TdelaySmoke=3.0,
  boxlength=3000,
  boxwidth=300,
  goodpass=20,
  goodhitrange=25,
  foulline=610,
}

--- Global list of all defined range names.
-- @field #table Names
RANGE.Names={}

--- Main radio menu.
-- @field #table MenuF10
RANGE.MenuF10={}

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
RANGE.id="RANGE | "

--- Range script version.
-- @field #string version
RANGE.version="1.2.1"

--TODO list:
--TODO: Add custom weapons, which can be specified by the user.
--TODO: Check if units are still alive.
--DONE: Add statics for strafe pits.
--DONE: Add missiles.
--DONE: Convert env.info() to self:T()
--DONE: Add user functions.
--DONE: Rename private functions, i.e. start with _functionname.
--DONE: number of displayed results variable.
--DONE: Add tire option for strafe pits. ==> No really feasible since tires are very small and cannot be seen.
--DONE: Check that menu texts are short enough to be correctly displayed in VR.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- RANGE contructor. Creates a new RANGE object.
-- @param #RANGE self
-- @param #string rangename Name of the range. Has to be unique. Will we used to create F10 menu items etc.
-- @return #RANGE RANGE object.
function RANGE:New(rangename)
  BASE:F({rangename=rangename})

  -- Inherit BASE.
  local self=BASE:Inherit(self, BASE:New()) -- #RANGE
  
  -- Get range name.
  --TODO: make sure that the range name is not given twice. This would lead to problems in the F10 radio menu.
  self.rangename=rangename or "Practice Range"
  
  -- Debug info.
  local text=string.format("RANGE script version %s - creating new RANGE object of name: %s.", RANGE.version, self.rangename)
  self:E(RANGE.id..text)
  MESSAGE:New(text, 10):ToAllIf(self.Debug)
    
  -- Return object.
  return self
end

--- Initializes number of targets and location of the range. Starts the event handlers.
-- @param #RANGE self
function RANGE:Start()
  self:F()

  -- Location/coordinate of range.
  local _location=nil
  
  -- Count bomb targets.
  local _count=0
  for _,_target in pairs(self.bombingTargets) do
    _count=_count+1
    
    -- Get range location.
    if _location==nil then
      _location=_target.target:GetCoordinate() --Core.Point#COORDINATE
    end
  end
  self.nbombtargets=_count
  
  -- Count strafing targets.
  _count=0
  for _,_target in pairs(self.strafeTargets) do
    _count=_count+1
    
    for _,_unit in pairs(_target.targets) do
      if _location==nil then
        _location=_unit:GetCoordinate()
      end
    end
  end
  self.nstrafetargets=_count
  
  -- Location of the range. We simply take the first unit/target we find if it was not explicitly specified by the user.
  if self.location==nil then
    self.location=_location
  end
  
  if self.location==nil then
    local text=string.format("ERROR! No range location found. Number of strafe targets = %d. Number of bomb targets = %d.", self.rangename, self.nstrafetargets, self.nbombtargets)
    self:E(RANGE.id..text)
    return
  end
  
  -- Define a MOOSE zone of the range.
  if self.rangezone==nil then
    self.rangezone=ZONE_RADIUS:New(self.rangename, {x=self.location.x, y=self.location.z}, self.rangeradius)
  end
  
  -- Starting range.
  local text=string.format("Starting RANGE %s. Number of strafe targets = %d. Number of bomb targets = %d.", self.rangename, self.nstrafetargets, self.nbombtargets)
  self:E(RANGE.id..text)
  MESSAGE:New(text,10):ToAllIf(self.Debug)
  
  -- Event handling.
  if self.eventmoose then
    -- Events are handled my MOOSE.
    self:T(RANGE.id.."Events are handled by MOOSE.")
    self:HandleEvent(EVENTS.Birth)
    self:HandleEvent(EVENTS.Hit)
    self:HandleEvent(EVENTS.Shot)
  else
    -- Events are handled directly by DCS.
    self:T(RANGE.id.."Events are handled directly by DCS.")
    world.addEventHandler(self)
  end
  
  -- Make bomb target move randomly within the range zone.
  for _,_target in pairs(self.bombingTargets) do

    -- Check if it is a static object.
    local _static=self:_CheckStatic(_target.target:GetName())
    
    if _target.move and _static==false and _target.speed>1 then
      local unit=_target.target --Wrapper.Unit#UNIT
      _target.target:PatrolZones({self.rangezone}, _target.speed*0.75, "Off road")
    end
    
  end
  
  -- Debug mode: smoke all targets and range zone.
  if self.Debug then
    self:_MarkTargetsOnMap()
    self:_SmokeBombTargets()
    self:_SmokeStrafeTargets()
    self:_SmokeStrafeTargetBoxes()
    self.rangezone:SmokeZone(SMOKECOLOR.White)
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions

--- Set maximal strafing altitude. Player entering a strafe pit above that altitude are not registered for a valid pass.
-- @param #RANGE self
-- @param #number maxalt Maximum altitude AGL in meters. Default is 914 m= 3000 ft.
function RANGE:SetMaxStrafeAlt(maxalt)
  self.strafemaxalt=maxalt or RANGE.Defaults.strafemaxalt
end

--- Set time interval for tracking bombs. A smaller time step increases accuracy but needs more CPU time.
-- @param #RANGE self
-- @param #number dt Time interval in seconds. Default is 0.005 s.
function RANGE:SetBombtrackTimestep(dt)
  self.dtBombtrack=dt or RANGE.Defaults.dtBombtrack
end

--- Set time how long (most) messages are displayed.
-- @param #RANGE self
-- @param #number time Time in seconds. Default is 30 s.
function RANGE:SetMessageTimeDuration(time)
  self.Tmsg=time or RANGE.Defaults.Tmsg
end

--- Set messages to examiner. The examiner will receive messages from all clients.
-- @param #RANGE self
-- @param #string examinergroupname Name of the group of the examiner.
-- @param #boolean exclusively If true, messages are send exclusively to the examiner, i.e. not to the clients.
function RANGE:SetMessageToExaminer(examinergroupname, exclusively)
  self.examinergroupname=examinergroupname
  self.examinerexclusive=exclusively
end

--- Set max number of player results that are displayed.
-- @param #RANGE self
-- @param #number nmax Number of results. Default is 10.
function RANGE:SetDisplayedMaxPlayerResults(nmax)
  self.ndisplayresult=nmax or RANGE.Defaults.ndisplayresult
end

--- Set range radius. Defines the area in which e.g. bomb impacts are smoked.
-- @param #RANGE self
-- @param #number radius Radius in km. Default 5 km.
function RANGE:SetRangeRadius(radius)
  self.rangeradius=radius*1000 or RANGE.Defaults.rangeradius
end

--- Set bomb track threshold distance. Bombs/rockets/missiles are only tracked if player-range distance is less than this distance. Default 25 km.
-- @param #RANGE self
-- @param #number distance Threshold distance in km. Default 25 km.
function RANGE:SetBombtrackThreshold(distance)
  self.BombtrackThreshold=distance*1000 or 25*1000
end

--- Set range location. If this is not done, one (random) unit position of the range is used to determine the center of the range.  
-- @param #RANGE self
-- @param Core.Point#COORDINATE coordinate Coordinate of the center of the range.
function RANGE:SetRangeLocation(coordinate)
  self.location=coordinate
end

--- Set range zone. For example, no bomb impact points are smoked if a bomb falls outside of this zone.
-- If a zone is not explicitly specified, the range zone is determined by its location and radius.
-- @param #RANGE self
-- @param Core.Zone#ZONE zone MOOSE zone defining the range perimeters.
function RANGE:SetRangeLocation(zone)
  self.rangezone=zone
end

--- Set smoke color for marking bomb targets. By default bomb targets are marked by red smoke.
-- @param #RANGE self
-- @param Utilities.Utils#SMOKECOLOR colorid Color id. Default SMOKECOLOR.Red.
function RANGE:SetBombTargetSmokeColor(colorid)
  self.BombSmokeColor=colorid or SMOKECOLOR.Red
end

--- Set smoke color for marking strafe targets. By default strafe targets are marked by green smoke.
-- @param #RANGE self
-- @param Utilities.Utils#SMOKECOLOR colorid Color id. Default SMOKECOLOR.Green.
function RANGE:SetStrafeTargetSmokeColor(colorid)
  self.StrafeSmokeColor=colorid or SMOKECOLOR.Green
end

--- Set smoke color for marking strafe pit approach boxes. By default strafe pit boxes are marked by white smoke.
-- @param #RANGE self
-- @param Utilities.Utils#SMOKECOLOR colorid Color id. Default SMOKECOLOR.White.
function RANGE:SetStrafePitSmokeColor(colorid)
  self.StrafePitSmokeColor=colorid or SMOKECOLOR.White
end

--- Set time delay between bomb impact and starting to smoke the impact point.
-- @param #RANGE self
-- @param #number delay Time delay in seconds. Default is 3 seconds.
function RANGE:SetSmokeTimeDelay(delay)
  self.TdelaySmoke=delay or RANGE.Defaults.TdelaySmoke
end

--- Enable debug modus.
-- @param #RANGE self
function RANGE:DebugON()
  self.Debug=true
end

--- Disable debug modus.
-- @param #RANGE self
function RANGE:DebugOFF()
  self.Debug=false
end

--- Enables tracking of all bomb types. Note that this is the default setting.
-- @param #RANGE self
function RANGE:TrackBombsON()
  self.trackbombs=true
end

--- Disables tracking of all bomb types.
-- @param #RANGE self
function RANGE:TrackBombsOFF()
  self.trackbombs=false
end

--- Enables tracking of all rocket types. Note that this is the default setting.
-- @param #RANGE self
function RANGE:TrackRocketsON()
  self.trackrockets=true
end

--- Disables tracking of all rocket types.
-- @param #RANGE self
function RANGE:TrackRocketsOFF()
  self.trackrockets=false
end

--- Enables tracking of all missile types. Note that this is the default setting.
-- @param #RANGE self
function RANGE:TrackMissilesON()
  self.trackmissiles=true
end

--- Disables tracking of all missile types.
-- @param #RANGE self
function RANGE:TrackMissilesOFF()
  self.trackmissiles=false
end


--- Add new strafe pit. For a strafe pit, hits from guns are counted. One pit can consist of several units.
-- Note, an approach is only valid, if the player enters via a zone in front of the pit, which defined by boxlength and boxheading.
-- Furthermore, the player must not be too high and fly in the direction of the pit to make a valid target apporoach.
-- @param #RANGE self
-- @param #table targetnames Table of unit or static names defining the strafe targets. The first target in the list determines the approach zone (heading and box).
-- @param #number boxlength (Optional) Length of the approach box in meters. Default is 3000 m.
-- @param #number boxwidth (Optional) Width of the approach box in meters. Default is 300 m.
-- @param #number heading (Optional) Approach heading in Degrees. Default is heading of the unit as defined in the mission editor.
-- @param #boolean inverseheading (Optional) Take inverse heading (heading --> heading - 180 Degrees). Default is false.
-- @param #number goodpass (Optional) Number of hits for a "good" strafing pass. Default is 20.
-- @param #number foulline (Optional) Foul line distance. Hits from closer than this distance are not counted. Default 610 m = 2000 ft. Set to 0 for no foul line.
function RANGE:AddStrafePit(targetnames, boxlength, boxwidth, heading, inverseheading, goodpass, foulline)
  self:F({targetnames=targetnames, boxlength=boxlength, boxwidth=boxwidth, heading=heading, inverseheading=inverseheading, goodpass=goodpass, foulline=foulline})

  -- Create table if necessary.  
  if type(targetnames) ~= "table" then
    targetnames={targetnames}
  end
  
  -- Make targets
  local _targets={}
  local center=nil --Wrapper.Unit#UNIT
  local ntargets=0
  
  for _i,_name in ipairs(targetnames) do
  
    -- Check if we have a static or unit object.
    local _isstatic=self:_CheckStatic(_name)

    local unit=nil  
    if _isstatic==true then
    
      -- Add static object.
      self:T(RANGE.id..string.format("Adding STATIC object %s as strafe target #%d.", _name, _i))
      unit=STATIC:FindByName(_name, false)
    
    elseif _isstatic==false then
    
      -- Add unit object.
      self:T(RANGE.id..string.format("Adding UNIT object %s as strafe target #%d.", _name, _i))
      unit=UNIT:FindByName(_name)
      
    else
    
      -- Neither unit nor static object with this name could be found.
      local text=string.format("ERROR! Could not find ANY strafe target object with name %s.", _name)
      self:E(RANGE.id..text)
      MESSAGE:New(text, 10):ToAllIf(self.Debug)
          
    end
    
    -- Add object to targets.   
    if unit then
      table.insert(_targets, unit)
      -- Define center as the first unit we find
      if center==nil then
        center=unit
      end
      ntargets=ntargets+1
    end
    
  end
  
  -- Check if at least one target could be found.
  if ntargets==0 then
    local text=string.format("ERROR! No strafe target could be found when calling RANGE:AddStrafePit() for range %s", self.rangename)
    self:E(RANGE.id..text)
    MESSAGE:New(text, 10):ToAllIf(self.Debug)
    return   
  end

  -- Approach box dimensions.
  local l=boxlength or RANGE.Defaults.boxlength
  local w=(boxwidth or RANGE.Defaults.boxwidth)/2
  
  -- Heading: either manually entered or automatically taken from unit heading.
  local heading=heading or center:GetHeading()
  
  -- Invert the heading since some units point in the "wrong" direction. In particular the strafe pit from 476th range objects.
  if inverseheading ~= nil then
    if inverseheading then
      heading=heading-180
    end
  end
  if heading<0 then
    heading=heading+360
  end
  if heading>360 then
    heading=heading-360
  end
  
  -- Number of hits called a "good" pass.
  goodpass=goodpass or RANGE.Defaults.goodpass
  
  -- Foule line distance.
  foulline=foulline or RANGE.Defaults.foulline
  
  -- Coordinate of the range.
  local Ccenter=center:GetCoordinate()
  
  -- Name of the target defined as its unit name.
  local _name=center:GetName()

  -- Points defining the approach area.  
  local p={}
  p[#p+1]=Ccenter:Translate(  w, heading+90)
  p[#p+1]=  p[#p]:Translate(  l, heading)
  p[#p+1]=  p[#p]:Translate(2*w, heading-90)
  p[#p+1]=  p[#p]:Translate( -l, heading)
  
  local pv2={}
  for i,p in ipairs(p) do
    pv2[i]={x=p.x, y=p.z}
  end
  
  -- Create polygon zone.
  local _polygon=ZONE_POLYGON_BASE:New(_name, pv2)
  
  -- Create tires
  --_polygon:BoundZone()
    
  -- Add zone to table.
  table.insert(self.strafeTargets, {name=_name, polygon=_polygon, coordinate= Ccenter, goodPass=goodpass, targets=_targets, foulline=foulline, smokepoints=p, heading=heading})
  
  -- Debug info
  local text=string.format("Adding new strafe target %s with %d targets: heading = %03d, box_L = %.1f, box_W = %.1f, goodpass = %d, foul line = %.1f", _name, ntargets, heading, l, w, goodpass, foulline)  
  self:T(RANGE.id..text)
  MESSAGE:New(text, 5):ToAllIf(self.Debug)
end


--- Add all units of a group as one new strafe target pit.
-- For a strafe pit, hits from guns are counted. One pit can consist of several units.
-- Note, an approach is only valid, if the player enters via a zone in front of the pit, which defined by boxlength and boxheading.
-- Furthermore, the player must not be too high and fly in the direction of the pit to make a valid target apporoach.
-- @param #RANGE self
-- @param Wrapper.Group#GROUP group MOOSE group of unit names defining the strafe target pit. The first unit in the group determines the approach zone (heading and box).
-- @param #number boxlength (Optional) Length of the approach box in meters. Default is 3000 m.
-- @param #number boxwidth (Optional) Width of the approach box in meters. Default is 300 m.
-- @param #number heading (Optional) Approach heading in Degrees. Default is heading of the unit as defined in the mission editor.
-- @param #boolean inverseheading (Optional) Take inverse heading (heading --> heading - 180 Degrees). Default is false.
-- @param #number goodpass (Optional) Number of hits for a "good" strafing pass. Default is 20.
-- @param #number foulline (Optional) Foul line distance. Hits from closer than this distance are not counted. Default 610 m = 2000 ft. Set to 0 for no foul line.
function RANGE:AddStrafePitGroup(group, boxlength, boxwidth, heading, inverseheading, goodpass, foulline)
  self:F({group=group, boxlength=boxlength, boxwidth=boxwidth, heading=heading, inverseheading=inverseheading, goodpass=goodpass, foulline=foulline})

  if group and group:IsAlive() then
    
    -- Get units of group.
    local _units=group:GetUnits()
    
    -- Make table of unit names.
    local _names={}
    for _,_unit in ipairs(_units) do
    
      local _unit=_unit --Wrapper.Unit#UNIT
      
      if _unit and _unit:IsAlive() then
        local _name=_unit:GetName()
        table.insert(_names,_name)
      end
      
    end
    
    -- Add strafe pit.
    self:AddStrafePit(_names, boxlength, boxwidth, heading, inverseheading, goodpass, foulline)    
  end

end

--- Add bombing target(s) to range.
-- @param #RANGE self
-- @param #table targetnames Table containing names of unit or static objects serving as bomb targets.
-- @param #number goodhitrange (Optional) Max distance from target unit (in meters) which is considered as a good hit. Default is 25 m.
-- @param #boolean randommove If true, unit will move randomly within the range. Default is false.
function RANGE:AddBombingTargets(targetnames, goodhitrange, randommove)
  self:F({targetnames=targetnames, goodhitrange=goodhitrange, randommove=randommove})

  -- Create a table if necessary.
  if type(targetnames) ~= "table" then
    targetnames={targetnames}
  end
    
  -- Default range is 25 m.
  goodhitrange=goodhitrange or RANGE.Defaults.goodhitrange
  
  for _,name in pairs(targetnames) do
  
    -- Check if we have a static or unit object.
    local _isstatic=self:_CheckStatic(name)
    
    if _isstatic==true then
      local _static=STATIC:FindByName(name)
      self:T2(RANGE.id..string.format("Adding static bombing target %s with hit range %d.", name, goodhitrange, false))
      self:AddBombingTargetUnit(_static, goodhitrange)
    elseif _isstatic==false then
      local _unit=UNIT:FindByName(name)
      self:T2(RANGE.id..string.format("Adding unit bombing target %s with hit range %d.", name, goodhitrange, randommove))
      self:AddBombingTargetUnit(_unit, goodhitrange)
    else
      self:E(RANGE.id..string.format("ERROR! Could not find bombing target %s.", name))
    end
    
  end
end

--- Add a unit or static object as bombing target.
-- @param #RANGE self
-- @param Wrapper.Positionable#POSITIONABLE unit Positionable (unit or static) of the strafe target.
-- @param #number goodhitrange Max distance from unit which is considered as a good hit.
-- @param #boolean randommove If true, unit will move randomly within the range. Default is false.
function RANGE:AddBombingTargetUnit(unit, goodhitrange, randommove)
  self:F({unit=unit, goodhitrange=goodhitrange, randommove=randommove})
  
  -- Get name of positionable.  
  local name=unit:GetName()
  
  -- Check if we have a static or unit object.
  local _isstatic=self:_CheckStatic(name)
  
  -- Default range is 25 m.
  goodhitrange=goodhitrange or RANGE.Defaults.goodhitrange

  -- Set randommove to false if it was not specified.
  if randommove==nil or _isstatic==true then
    randommove=false
  end  
  
  -- Debug or error output.
  if _isstatic==true then
    self:T(RANGE.id..string.format("Adding STATIC bombing target %s with good hit range %d. Random move = %s.", name, goodhitrange, tostring(randommove)))
  elseif _isstatic==false then
    self:T(RANGE.id..string.format("Adding UNIT bombing target %s with good hit range %d. Random move = %s.", name, goodhitrange, tostring(randommove)))
  else
    self:E(RANGE.id..string.format("ERROR! No bombing target with name %s could be found. Carefully check all UNIT and STATIC names defined in the mission editor!", name))
  end
  
  -- Get max speed of unit in km/h.
  local speed=0
  if _isstatic==false then
    speed=self:_GetSpeed(unit)
  end
  
  -- Insert target to table.
  table.insert(self.bombingTargets, {name=name, target=unit, goodhitrange=goodhitrange, move=randommove, speed=speed})
end

--- Add all units of a group as bombing targets.
-- @param #RANGE self
-- @param Wrapper.Group#GROUP group Group of bombing targets.
-- @param #number goodhitrange Max distance from unit which is considered as a good hit.
-- @param #boolean randommove If true, unit will move randomly within the range. Default is false.
function RANGE:AddBombingTargetGroup(group, goodhitrange, randommove)
  self:F({group=group, goodhitrange=goodhitrange, randommove=randommove})
  
  if group then
  
    local _units=group:GetUnits()
    
    for _,_unit in pairs(_units) do
      if _unit and _unit:IsAlive() then
        self:AddBombingTargetUnit(_unit, goodhitrange, randommove)
      end
    end
  end
  
end

--- Measures the foule line distance between two unit or static objects.
-- @param #RANGE self
-- @param #string namepit Name of the strafe pit target object.
-- @param #string namefoulline Name of the fould line distance marker object.
-- @return #number Foul line distance in meters.
function RANGE:GetFoullineDistance(namepit, namefoulline)
  self:F({namepit=namepit, namefoulline=namefoulline})

  -- Check if we have units or statics.  
  local _staticpit=self:_CheckStatic(namepit)
  local _staticfoul=self:_CheckStatic(namefoulline)
  
  -- Get the unit or static pit object.
  local pit=nil
  if _staticpit==true then
    pit=STATIC:FindByName(namepit, false)
  elseif _staticpit==false then
    pit=UNIT:FindByName(namepit)
  else
    self:E(RANGE.id..string.format("ERROR! Pit object %s could not be found in GetFoullineDistance function. Check the name in the ME.", namepit))
  end
  
  -- Get the unit or static foul line object.
  local foul=nil
  if _staticfoul==true then
    foul=STATIC:FindByName(namefoulline, false)
  elseif _staticfoul==false then
    foul=UNIT:FindByName(namefoulline)
  else
    self:E(RANGE.id..string.format("ERROR! Foul line object %s could not be found in GetFoullineDistance function. Check the name in the ME.", namefoulline))
  end
  
  -- Get the distance between the two objects.
  local fouldist=0
  if pit~=nil and foul~=nil then
    fouldist=pit:GetCoordinate():Get2DDistance(foul:GetCoordinate())
  else
    self:E(RANGE.id..string.format("ERROR! Foul line distance could not be determined. Check pit object name %s and foul line object name %s in the ME.", namepit, namefoulline))
  end

  self:T(RANGE.id..string.format("Foul line distance = %.1f m.", fouldist))
  return fouldist
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Handling

--- General event handler.
-- @param #RANGE self
-- @param #table Event DCS event table.
function RANGE:onEvent(Event)
  self:F3(Event)

  if Event == nil or Event.initiator == nil then
    self:T3("Skipping onEvent. Event or Event.initiator unknown.")
    return true
  end
  if Unit.getByName(Event.initiator:getName()) == nil then
    self:T3("Skipping onEvent. Initiator unit name unknown.")
    return true
  end

  local DCSiniunit = Event.initiator
  local DCStgtunit = Event.target
  local DCSweapon  = Event.weapon

  local EventData={}
  local _playerunit=nil
  local _playername=nil
  
  if Event.initiator then
    EventData.IniUnitName  = Event.initiator:getName()
    EventData.IniDCSGroup  = Event.initiator:getGroup()
    EventData.IniGroupName = Event.initiator:getGroup():getName()
    -- Get player unit and name. This returns nil,nil if the event was not fired by a player unit. And these are the only events we are interested in. 
    _playerunit, _playername = self:_GetPlayerUnitAndName(EventData.IniUnitName)  
  end

  if Event.target then  
    EventData.TgtUnitName  = Event.target:getName()
    EventData.TgtUnit      = UNIT:FindByName(EventData.TgtUnitName)
  end
  
  if Event.weapon then
    EventData.Weapon         = Event.weapon
    EventData.weapon         = Event.weapon
    EventData.WeaponTypeName = Event.weapon:getTypeName()
  end  
  
  -- Event info.
  self:T3(RANGE.id..string.format("EVENT: Event in onEvent with ID = %s", tostring(Event.id)))
  self:T3(RANGE.id..string.format("EVENT: Ini unit   = %s" , tostring(EventData.IniUnitName)))
  self:T3(RANGE.id..string.format("EVENT: Ini group  = %s" , tostring(EventData.IniGroupName)))
  self:T3(RANGE.id..string.format("EVENT: Ini player = %s" , tostring(_playername)))
  self:T3(RANGE.id..string.format("EVENT: Tgt unit   = %s" , tostring(EventData.TgtUnitName)))
  self:T3(RANGE.id..string.format("EVENT: Wpn type   = %s" , tostring(EventData.WeaponTypeName)))
    
  -- Call event Birth function.
  if Event.id==world.event.S_EVENT_BIRTH and _playername then
    self:OnEventBirth(EventData)
  end
  
  -- Call event Shot function.
  if Event.id==world.event.S_EVENT_SHOT and _playername and Event.weapon then
    self:OnEventShot(EventData)
  end
  
  -- Call event Hit function.
  if Event.id==world.event.S_EVENT_HIT and _playername and DCStgtunit then
    self:OnEventHit(EventData)
  end
  
end


--- Range event handler for event birth.
-- @param #RANGE self
-- @param Core.Event#EVENTDATA EventData
function RANGE:OnEventBirth(EventData)
  self:F({eventbirth = EventData})
  
  local _unitName=EventData.IniUnitName  
  local _unit, _playername=self:_GetPlayerUnitAndName(_unitName)
  
  self:T3(RANGE.id.."BIRTH: unit   = "..tostring(EventData.IniUnitName))
  self:T3(RANGE.id.."BIRTH: group  = "..tostring(EventData.IniGroupName))
  self:T3(RANGE.id.."BIRTH: player = "..tostring(_playername)) 
      
  if _unit and _playername then
  
    local _uid=_unit:GetID()
    local _group=_unit:GetGroup()
    local _gid=_group:GetID()
    local _callsign=_unit:GetCallsign()
    
    -- Debug output.
    local text=string.format("Player %s, callsign %s entered unit %s (UID %d) of group %s (GID %d)", _playername, _callsign, _unitName, _uid, _group:GetName(), _gid)
    self:T(RANGE.id..text)
    MESSAGE:New(text, 5):ToAllIf(self.Debug)
    
    self:_GetAmmo(_unitName)
    
    -- Reset current strafe status.
    self.strafeStatus[_uid] = nil
  
    -- Add Menu commands.
    self:_AddF10Commands(_unitName)
    
    -- By default, some bomb impact points and do not flare each hit on target.
    self.PlayerSettings[_playername]={}
    self.PlayerSettings[_playername].smokebombimpact=true
    self.PlayerSettings[_playername].flaredirecthits=false
    self.PlayerSettings[_playername].smokecolor=SMOKECOLOR.Blue
    self.PlayerSettings[_playername].flarecolor=FLARECOLOR.Red
    self.PlayerSettings[_playername].delaysmoke=true
  
    -- Start check in zone timer.
    if self.planes[_uid] ~= true then
      SCHEDULER:New(nil, self._CheckInZone, {self, EventData.IniUnitName}, 1, 1)
      self.planes[_uid] = true
    end
  
  end 
end

--- Range event handler for event hit.
-- @param #RANGE self
-- @param Core.Event#EVENTDATA EventData
function RANGE:OnEventHit(EventData)
  self:F({eventhit = EventData})
  
  -- Debug info.
  self:T3(RANGE.id.."HIT: Ini unit   = "..tostring(EventData.IniUnitName))
  self:T3(RANGE.id.."HIT: Ini group  = "..tostring(EventData.IniGroupName))
  self:T3(RANGE.id.."HIT: Tgt target = "..tostring(EventData.TgtUnitName))

  -- Player info
  local _unitName = EventData.IniUnitName
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  if _unit==nil or _playername==nil then
    return
  end
  
  -- Unit ID
  local _unitID = _unit:GetID()

  -- Target
  local target     = EventData.TgtUnit
  local targetname = EventData.TgtUnitName
    
  -- Current strafe target of player.
  local _currentTarget = self.strafeStatus[_unitID]

  -- Player has rolled in on a strafing target.
  if _currentTarget and target:IsAlive() then
  
    local playerPos = _unit:GetCoordinate()
    local targetPos = target:GetCoordinate()

    -- Loop over valid targets for this run.
    for _,_target in pairs(_currentTarget.zone.targets) do
    
      -- Check the the target is the same that was actually hit.
      if  _target and _target:IsAlive() and _target:GetName() == targetname then
      
        -- Get distance between player and target.
        local dist=playerPos:Get2DDistance(targetPos)
        
        if dist > _currentTarget.zone.foulline then 
          -- Increase hit counter of this run.
          _currentTarget.hits =  _currentTarget.hits + 1
          
          -- Flare target.
          if _unit and _playername and self.PlayerSettings[_playername].flaredirecthits then
            targetPos:Flare(self.PlayerSettings[_playername].flarecolor)
          end
        else
          -- Too close to the target.
          if _currentTarget.pastfoulline==false and _unit and _playername then 
            local _d=_currentTarget.zone.foulline
            local text=string.format("%s, Invalid hit!\nYou already passed foul line distance of %d m for target %s.", self:_myname(_unitName), _d, targetname)
            self:_DisplayMessageToGroup(_unit, text, 10)
            self:T2(RANGE.id..text)
            _currentTarget.pastfoulline=true
          end
        end
        
      end
    end
  end
  
  -- Bombing Targets
  for _,_bombtarget in pairs(self.bombingTargets) do
  
    local _target=_bombtarget.target --Wrapper.Positionable#POSITIONABLE
  
    -- Check if one of the bomb targets was hit.
    if _target and _target:IsAlive() and _bombtarget.name == targetname then
      
      if _unit and _playername then
      
        -- Position of target.
        local targetPos = _target:GetCoordinate()
      
        -- Message to player.
        --local text=string.format("%s, direct hit on target %s.", self:_myname(_unitName), targetname)
        --self:DisplayMessageToGroup(_unit, text, 10, true)
      
        -- Flare target.
        if self.PlayerSettings[_playername].flaredirecthits then
          targetPos:Flare(self.PlayerSettings[_playername].flarecolor)
        end
        
      end
    end
  end
end

--- Range event handler for event shot (when a unit releases a rocket or bomb (but not a fast firing gun). 
-- @param #RANGE self
-- @param Core.Event#EVENTDATA EventData
function RANGE:OnEventShot(EventData)
  self:F({eventshot = EventData})
  
  -- Weapon data.
  local _weapon = EventData.Weapon:getTypeName()  -- should be the same as Event.WeaponTypeName
  local _weaponStrArray = self:_split(_weapon,"%.")
  local _weaponName = _weaponStrArray[#_weaponStrArray]
  
  -- Debug info.
  self:T(RANGE.id.."EVENT SHOT: Range "..self.rangename)
  self:T(RANGE.id.."EVENT SHOT: Ini unit    = "..EventData.IniUnitName)
  self:T(RANGE.id.."EVENT SHOT: Ini group   = "..EventData.IniGroupName)
  self:T(RANGE.id.."EVENT SHOT: Weapon type = ".._weapon)
  self:T(RANGE.id.."EVENT SHOT: Weapon name = ".._weaponName)
  
  -- Special cases:
  local _viggen=string.match(_weapon, "ROBOT") or string.match(_weapon, "RB75") or string.match(_weapon, "BK90") or string.match(_weapon, "RB15") or string.match(_weapon, "RB04")
  
  -- Tracking conditions for bombs, rockets and missiles.
  local _bombs=string.match(_weapon, "weapons.bombs") 
  local _rockets=string.match(_weapon, "weapons.nurs") 
  local _missiles=string.match(_weapon, "weapons.missiles") or _viggen
  
  -- Check if any condition applies here.
  local _track = (_bombs and self.trackbombs) or (_rockets and self.trackrockets) or (_missiles and self.trackmissiles)
    
  -- Get unit name.
  local _unitName = EventData.IniUnitName
  
  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)

  -- Set this to larger value than the threshold.
  local dPR=self.BombtrackThreshold*2
  
  -- Distance player to range. 
  if _unit and _playername then
    dPR=_unit:GetCoordinate():Get2DDistance(self.location)
    self:T(RANGE.id..string.format("Range %s, player %s, player-range distance = %d km.", self.rangename, _playername, dPR/1000))
  end

  -- Only track if distance player to range is < 25 km.
  if _track and dPR<=self.BombtrackThreshold then

    -- Tracking info and init of last bomb position.
    self:T(RANGE.id..string.format("RANGE %s: Tracking %s - %s.", self.rangename, _weapon, EventData.weapon:getName()))
    
    -- Init bomb position.
    local _lastBombPos = {x=0,y=0,z=0}
        
    -- Function monitoring the position of a bomb until impact.
    local function trackBomb(_ordnance)

      -- When the pcall returns a failure the weapon has hit.
      local _status,_bombPos =  pcall(
      function()
        return _ordnance:getPoint()
      end)

      self:T3(RANGE.id..string.format("Range %s: Bomb still in air: %s", self.rangename, tostring(_status)))
      if _status then
      
        -- Still in the air. Remember this position.
        _lastBombPos = {x = _bombPos.x, y = _bombPos.y, z= _bombPos.z }

        -- Check again in 0.005 seconds.
        return timer.getTime() + self.dtBombtrack
        
      else
      
        -- Bomb did hit the ground.
        -- Get closet target to last position.
        local _closetTarget = nil
        local _distance = nil
        local _hitquality = "POOR"
        
        -- Get callsign.
        local _callsign=self:_myname(_unitName)
                  
        -- Coordinate of impact point.
        local impactcoord=COORDINATE:NewFromVec3(_lastBombPos)
        
        -- Distance from range. We dont want to smoke targets outside of the range.
        local impactdist=impactcoord:Get2DDistance(self.location)
        
        -- Smoke impact point of bomb.
        if self.PlayerSettings[_playername].smokebombimpact and impactdist<self.rangeradius then
          if self.PlayerSettings[_playername].delaysmoke then
            timer.scheduleFunction(self._DelayedSmoke, {coord=impactcoord, color=self.PlayerSettings[_playername].smokecolor}, timer.getTime() + self.TdelaySmoke)
          else
            impactcoord:Smoke(self.PlayerSettings[_playername].smokecolor)
          end
        end
            
        -- Loop over defined bombing targets.
        for _,_bombtarget in pairs(self.bombingTargets) do

          local _target=_bombtarget.target --Wrapper.Positionable#POSITIONABLE
          
          if _target and _target:IsAlive() then
          
            -- Distance between bomb and target.
            local _temp = impactcoord:Get2DDistance(_target:GetCoordinate())
  
            -- Find closest target to last known position of the bomb.
            if _distance == nil or _temp < _distance then
              _distance = _temp
              _closetTarget = _bombtarget
              if _distance <= 0.5*_bombtarget.goodhitrange then
                _hitquality = "EXCELLENT"
              elseif _distance <= _bombtarget.goodhitrange then
                _hitquality = "GOOD"
              elseif _distance <= 2*_bombtarget.goodhitrange then
                _hitquality = "INEFFECTIVE"
              else
                _hitquality = "POOR"
              end
              
            end
          end
        end

        -- Count if bomb fell less than 1 km away from the target.
        if _distance <= self.scorebombdistance then

          -- Init bomb player results.
          if not self.bombPlayerResults[_playername] then
            self.bombPlayerResults[_playername]  = {}
          end

          -- Local results.
          local _results =  self.bombPlayerResults[_playername]
          
          -- Add to table.
          table.insert(_results, {name=_closetTarget.name, distance =_distance, weapon = _weaponName, quality=_hitquality })

          -- Send message to player.
          local _message = string.format("%s, impact %d m from bullseye of target %s. %s hit.", _callsign, _distance, _closetTarget.name, _hitquality)

          -- Send message.
          self:_DisplayMessageToGroup(_unit, _message, nil, true)
        elseif _distance <= self.rangeradius then
          -- Send message
          local _message=string.format("%s, weapon fell more than %.1f km away from nearest range target. No score!", _callsign, self.scorebombdistance/1000)
          self:_DisplayMessageToGroup(_unit, _message, nil, true)
        end
        
        --Terminate the timer
        self:T(RANGE.id..string.format("Range %s, player %s: Terminating bomb track timer.", self.rangename, _playername))
        return nil

      end -- _status check
      
    end -- end function trackBomb

    -- Weapon is not yet "alife" just yet. Start timer in one second.
    self:T(RANGE.id..string.format("Range %s, player %s: Tracking of weapon starts in one second.", self.rangename, _playername))
    timer.scheduleFunction(trackBomb, EventData.weapon, timer.getTime() + 1.0)
    
  end --if _track (string.match) and player-range distance < threshold.
  
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Display Messages

--- Start smoking a coordinate with a delay.
-- @param #table _args Argements passed.
function RANGE._DelayedSmoke(_args)
  trigger.action.smoke(_args.coord:GetVec3(), _args.color)
end

--- Display top 10 stafing results of a specific player.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
function RANGE:_DisplayMyStrafePitResults(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name
  local _unit,_playername = self:_GetPlayerUnitAndName(_unitName)
  
  if _unit and _playername then
  
    -- Message header.
    local _message = string.format("My Top %d Strafe Pit Results:\n", self.ndisplayresult)
  
    -- Get player results.
    local _results = self.strafePlayerResults[_playername]
  
    -- Create message.
    if _results == nil then
        -- No score yet.
        _message = string.format("%s: No Score yet.", _playername)
    else
  
      -- Sort results table wrt number of hits.
      local _sort = function( a,b ) return a.hits > b.hits end
      table.sort(_results,_sort)
  
      -- Prepare message of best results.
      local _bestMsg = ""
      local _count = 1
      
      -- Loop over results
      for _,_result in pairs(_results) do
  
        -- Message text.
        _message = _message..string.format("\n[%d] Hits %d - %s - %s", _count, _result.hits, _result.zone.name, _result.text)
      
        -- Best result.
        if _bestMsg == "" then 
          _bestMsg = string.format("Hits %d - %s - %s", _result.hits, _result.zone.name, _result.text)
        end
  
        -- 10 runs
        if _count == self.ndisplayresult then
          break
        end
    
        -- Increase counter
        _count = _count+1
      end
  
      -- Message text.
      _message = _message .."\n\nBEST: ".._bestMsg
    end

    -- Send message to group.  
    self:_DisplayMessageToGroup(_unit, _message, nil, true)
  end
end

--- Display top 10 strafing results of all players.
-- @param #RANGE self
-- @param #string _unitName Name fo the player unit.
function RANGE:_DisplayStrafePitResults(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit which is a player.
  if _unit and _playername then
  
    -- Results table.
    local _playerResults = {}
  
    -- Message text.
    local _message = string.format("Strafe Pit Results - Top %d Players:\n", self.ndisplayresult)
  
    -- Loop over player results.
    for _playerName,_results in pairs(self.strafePlayerResults) do
  
      -- Get the best result of the player.
      local _best = nil
      for _,_result in pairs(_results) do  
        if _best == nil or _result.hits > _best.hits then
          _best = _result
        end
      end
  
      -- Add best result to table. 
      if _best ~= nil then
        local text=string.format("%s: Hits %i - %s - %s", _playerName, _best.hits, _best.zone.name, _best.text)
        table.insert(_playerResults,{msg = text, hits = _best.hits})
      end
  
    end
  
    --Sort list!
    local _sort = function( a,b ) return a.hits > b.hits end
    table.sort(_playerResults,_sort)
  
    -- Add top 10 results.
    for _i = 1, math.min(#_playerResults, self.ndisplayresult) do
      _message = _message..string.format("\n[%d] %s", _i, _playerResults[_i].msg)
    end
    
    -- In case there are no scores yet.
    if #_playerResults<1 then
      _message = _message.."No player scored yet."
    end
  
    -- Send message.
    self:_DisplayMessageToGroup(_unit, _message, nil, true)
  end
end

--- Display top 10 bombing run results of specific player.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
function RANGE:_DisplayMyBombingResults(_unitName)
  self:F(_unitName)

  -- Get player unit and name.  
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  if _unit and _playername then
  
    -- Init message.
    local _message = string.format("My Top %d Bombing Results:\n", self.ndisplayresult)
  
    -- Results from player.
    local _results = self.bombPlayerResults[_playername]
  
    -- No score so far.
    if _results == nil then
      _message = _playername..": No Score yet."
    else
  
      -- Sort results wrt to distance.
      local _sort = function( a,b ) return a.distance < b.distance end
      table.sort(_results,_sort)
  
      -- Loop over results.
      local _bestMsg = ""
      local _count = 1
      for _,_result in pairs(_results) do
  
        -- Message with name, weapon and distance.
        _message = _message.."\n"..string.format("[%d] %d m - %s - %s - %s hit", _count, _result.distance, _result.name, _result.weapon, _result.quality)
  
        -- Store best/first result.
        if _bestMsg == "" then
            _bestMsg = string.format("%d m - %s - %s - %s hit",_result.distance,_result.name,_result.weapon, _result.quality)
        end
  
        -- Best 10 runs only.
        if _count == self.ndisplayresult then
          break
        end
  
        -- Increase counter.
        _count = _count+1
      end
  
      -- Message.
      _message = _message .."\n\nBEST: ".._bestMsg
    end
  
    -- Send message.
    self:_DisplayMessageToGroup(_unit, _message, nil, true)
  end
end

--- Display best bombing results of top 10 players.
-- @param #RANGE self
-- @param #string _unitName Name of player unit.
function RANGE:_DisplayBombingResults(_unitName)
  self:F(_unitName)
  
  -- Results table.
  local _playerResults = {}
  
  -- Get player unit and name.
  local _unit, _player = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check if we have a unit with a player.
  if _unit and _player then
  
    -- Message header.
    local _message = string.format("Bombing Results - Top %d Players:\n", self.ndisplayresult)
  
    -- Loop over players.
    for _playerName,_results in pairs(self.bombPlayerResults) do
  
      -- Find best result of player.
      local _best = nil
      for _,_result in pairs(_results) do
        if _best == nil or _result.distance < _best.distance then
            _best = _result
        end
      end
  
      -- Put best result of player into table.
      if _best ~= nil then
        local bestres=string.format("%s: %d m - %s - %s - %s hit", _playerName, _best.distance, _best.name, _best.weapon, _best.quality)
        table.insert(_playerResults, {msg = bestres, distance = _best.distance})
      end
  
    end
  
    -- Sort list of player results.
    local _sort = function( a,b ) return a.distance < b.distance end
    table.sort(_playerResults,_sort)
  
    -- Loop over player results.
    for _i = 1, math.min(#_playerResults, self.ndisplayresult) do  
      _message = _message..string.format("\n[%d] %s", _i, _playerResults[_i].msg)
    end
    
    -- In case there are no scores yet.
    if #_playerResults<1 then
      _message = _message.."No player scored yet."
    end
  
    -- Send message.
    self:_DisplayMessageToGroup(_unit, _message, nil, true)
  end
end

--- Report information like bearing and range from player unit to range.
-- @param #RANGE self
-- @param #string _unitname Name of the player unit.
function RANGE:_DisplayRangeInfo(_unitname)
  self:F(_unitname)

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Message text.
    local text=""
   
    -- Current coordinates.
    local coord=unit:GetCoordinate()
    
    if self.location then
    
      -- Direction vector from current position (coord) to target (position).
      local position=self.location --Core.Point#COORDINATE
      local rangealt=position:GetLandHeight()
      local vec3=coord:GetDirectionVec3(position)
      local angle=coord:GetAngleDegrees(vec3)
      local range=coord:Get2DDistance(position)
      
      -- Bearing string.
      local Bs=string.format('%03d°', angle)
      
      local texthit
      if self.PlayerSettings[playername].flaredirecthits then
        texthit=string.format("Flare direct hits: ON (flare color %s)\n", self:_flarecolor2text(self.PlayerSettings[playername].flarecolor))
      else
        texthit=string.format("Flare direct hits: OFF\n")
      end
      local textbomb
      if self.PlayerSettings[playername].smokebombimpact then
        textbomb=string.format("Smoke bomb impact points: ON (smoke color %s)\n", self:_smokecolor2text(self.PlayerSettings[playername].smokecolor))
      else
        textbomb=string.format("Smoke bomb impact points: OFF\n")
      end
      local textdelay
      if self.PlayerSettings[playername].delaysmoke then
        textdelay=string.format("Smoke bomb delay: ON (delay %.1f seconds)", self.TdelaySmoke)
      else
        textdelay=string.format("Smoke bomb delay: OFF")
      end
      
      -- Player unit settings.
      local settings=_DATABASE:GetPlayerSettings(playername) or _SETTINGS --Core.Settings#SETTINGS
      local trange=string.format("%.1f km", range/1000)
      local trangealt=string.format("%d m", rangealt)
      local tstrafemaxalt=string.format("%d m", self.strafemaxalt)
      if settings:IsImperial() then
        trange=string.format("%.1f NM", UTILS.MetersToNM(range))
        trangealt=string.format("%d feet", UTILS.MetersToFeet(rangealt))
        tstrafemaxalt=string.format("%d feet", UTILS.MetersToFeet(self.strafemaxalt))
      end
            
      -- Message.
      text=text..string.format("Information on %s:\n", self.rangename)
      text=text..string.format("-------------------------------------------------------\n")
      text=text..string.format("Bearing %s, Range %s\n", Bs, trange)
      text=text..string.format("Altitude ASL: %s\n", trangealt)
      text=text..string.format("Max strafing alt AGL: %s\n", tstrafemaxalt)
      text=text..string.format("# of strafe targets: %d\n", self.nstrafetargets)
      text=text..string.format("# of bomb targets: %d\n", self.nbombtargets)
      text=text..texthit
      text=text..textbomb
      text=text..textdelay
      
      -- Send message to player group.
      self:_DisplayMessageToGroup(unit, text, nil, true)
      
      -- Debug output.
      self:T2(RANGE.id..text)
    end
  end
end

--- Display bombing target locations to player.
-- @param #RANGE self
-- @param #string _unitname Name of the player unit.
function RANGE:_DisplayBombTargets(_unitname)
  self:F(_unitname)

  -- Get player unit and player name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if _unit and _playername then
  
    -- Player settings.
    local _settings=_DATABASE:GetPlayerSettings(_playername) or _SETTINGS --Core.Settings#SETTINGS
    
    -- Message text.
    local _text="Bomb Target Locations:"
  
    for _,_bombtarget in pairs(self.bombingTargets) do
      local _target=_bombtarget.target --Wrapper.Positionable#POSITIONABLE
      if _target and _target:IsAlive() then
      
        -- Core.Point#COORDINATE
        local coord=_target:GetCoordinate() --Core.Point#COORDINATE
        local mycoord=coord:ToStringA2G(_unit, _settings)
        _text=_text..string.format("\n- %s: %s",_bombtarget.name, mycoord)
      end
    end
    
    self:_DisplayMessageToGroup(_unit,_text, nil, true)
  end
end

--- Display pit location and heading to player.
-- @param #RANGE self
-- @param #string _unitname Name of the player unit.
function RANGE:_DisplayStrafePits(_unitname)
  self:F(_unitname)

  -- Get player unit and player name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if _unit and _playername then
  
    -- Player settings.
    local _settings=_DATABASE:GetPlayerSettings(_playername) or _SETTINGS --Core.Settings#SETTINGS
    
    -- Message text.
    local _text="Strafe Target Locations:"
  
    for _,_strafepit in pairs(self.strafeTargets) do
      local _target=_strafepit --Wrapper.Positionable#POSITIONABLE
      
      -- Pit parameters.
      local coord=_strafepit.coordinate --Core.Point#COORDINATE
      local heading=_strafepit.heading
      
      -- Turn heading around ==> approach heading.
      if heading>180 then
        heading=heading-180
      else
        heading=heading+180
      end

      local mycoord=coord:ToStringA2G(_unit, _settings)
      _text=_text..string.format("\n- %s: %s - heading %03d",_strafepit.name, mycoord, heading)
    end
    
    self:_DisplayMessageToGroup(_unit,_text, nil, true)
  end
end


--- Report weather conditions at range. Temperature, QFE pressure and wind data.
-- @param #RANGE self
-- @param #string _unitname Name of the player unit.
function RANGE:_DisplayRangeWeather(_unitname)
  self:F(_unitname)

  -- Get player unit and player name.
  local unit, playername = self:_GetPlayerUnitAndName(_unitname)
  
  -- Check if we have a player.
  if unit and playername then
  
    -- Message text.
    local text=""
   
    -- Current coordinates.
    local coord=unit:GetCoordinate()
    
    if self.location then
    
      -- Get atmospheric data at range location.
      local position=self.location --Core.Point#COORDINATE
      local T=position:GetTemperature()
      local P=position:GetPressure()
      local Wd,Ws=position:GetWind()
      
      -- Get Beaufort wind scale.
      local Bn,Bd=UTILS.BeaufortScale(Ws)  
      
      local WD=string.format('%03d°', Wd)
      local Ts=string.format("%d°C",T)
      
      local hPa2inHg=0.0295299830714
      local hPa2mmHg=0.7500615613030
      
      local settings=_DATABASE:GetPlayerSettings(playername) or _SETTINGS --Core.Settings#SETTINGS
      local tT=string.format("%d°C",T)
      local tW=string.format("%.1f m/s", Ws)
      local tP=string.format("%.1f mmHg", P*hPa2mmHg)
      if settings:IsImperial() then
        tT=string.format("%d°F", UTILS.CelciusToFarenheit(T))
        tW=string.format("%.1f knots", UTILS.MpsToKnots(Ws))
        tP=string.format("%.2f inHg", P*hPa2inHg)      
      end
      
             
      -- Message text.
      text=text..string.format("Weather Report at %s:\n", self.rangename)
      text=text..string.format("--------------------------------------------------\n")
      text=text..string.format("Temperature %s\n", tT)
      text=text..string.format("Wind from %s at %s (%s)\n", WD, tW, Bd)
      text=text..string.format("QFE %.1f hPa = %s", P, tP)
    else
      text=string.format("No range location defined for range %s.", self.rangename)
    end
    
    -- Send message to player group.
    self:_DisplayMessageToGroup(unit, text, nil, true)
    
    -- Debug output.
    self:T2(RANGE.id..text)
  else
    self:T(RANGE.id..string.format("ERROR! Could not find player unit in RangeInfo! Name = %s", _unitname))
  end      
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Timer Functions

--- Check if player is inside a strafing zone. If he is, we start looking for hits. If he was and left the zone again, the result is stored.
-- @param #RANGE self
-- @param #string _unitName Name of player unit.
function RANGE:_CheckInZone(_unitName)
  self:F2(_unitName)

  -- Get player unit and name.
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)

  if _unit and _playername then

    -- Current position of player unit.
    local _unitID  = _unit:GetID()

    -- Currently strafing? (strafeStatus is nil if not)
    local _currentStrafeRun = self.strafeStatus[_unitID]

    if _currentStrafeRun then  -- player has already registered for a strafing run.
    
      -- Get the current approach zone and check if player is inside.
      local zone=_currentStrafeRun.zone.polygon  --Core.Zone#ZONE_POLYGON_BASE
      
      local unitheading  = _unit:GetHeading()
      local pitheading   = _currentStrafeRun.zone.heading - 180
      local deltaheading = unitheading-pitheading
      local towardspit   = math.abs(deltaheading)<=90 or math.abs(deltaheading-360)<=90
      local unitalt=_unit:GetHeight()-_unit:GetCoordinate():GetLandHeight()       
      
      -- Check if unit is inside zone and below max height AGL.
      local unitinzone=_unit:IsInZone(zone) and unitalt <= self.strafemaxalt and towardspit
      
      -- Debug output
      local text=string.format("Checking stil in zone. Unit = %s, player = %s in zone = %s. alt = %d, delta heading = %d", _unitName, _playername, tostring(unitinzone), unitalt, deltaheading)
      self:T2(RANGE.id..text)
    
      -- Check if player is in strafe zone and below max alt.
      if unitinzone then 
        
        -- Still in zone, keep counting hits. Increase counter.
        _currentStrafeRun.time = _currentStrafeRun.time+1
    
      else
    
        -- Increase counter
        _currentStrafeRun.time = _currentStrafeRun.time+1
    
        if _currentStrafeRun.time <= 3 then
        
          -- Reset current run.
          self.strafeStatus[_unitID] = nil
    
          -- Message text.
          local _msg = string.format("%s left strafing zone %s too quickly. No Score.", _playername, _currentStrafeRun.zone.name)
          
          -- Send message.
          self:_DisplayMessageToGroup(_unit, _msg, nil, true)
          
        else
        
          -- Get current ammo.
          local _ammo=self:_GetAmmo(_unitName)
        
          -- Result.
          local _result = self.strafeStatus[_unitID]

          -- Judge this pass. Text is displayed on summary.
          if _result.hits >= _result.zone.goodPass*2 then
            _result.text = "EXCELLENT PASS"    
          elseif _result.hits >= _result.zone.goodPass then
            _result.text = "GOOD PASS"
          elseif _result.hits >= _result.zone.goodPass/2 then
            _result.text = "INEFFECTIVE PASS"
          else
            _result.text = "POOR PASS"
          end
          
          -- Calculate accuracy of run. Number of hits wrt number of rounds fired.
          local shots=_result.ammo-_ammo
          local accur=0
          if shots>0 then
            accur=_result.hits/shots*100
          end
              
          -- Message text.      
          local _text=string.format("%s, %s with %d hits on target %s.", self:_myname(_unitName), _result.text, _result.hits, _result.zone.name)
          if shots and accur then
            _text=_text..string.format("\nTotal rounds fired %d. Accuracy %.1f %%.", shots, accur)
          end
          
          -- Send message.
          self:_DisplayMessageToGroup(_unit, _text)
    
          -- Set strafe status to nil.
          self.strafeStatus[_unitID] = nil
    
          -- Save stats so the player can retrieve them.
          local _stats = self.strafePlayerResults[_playername] or {}
          table.insert(_stats, _result)
          self.strafePlayerResults[_playername] = _stats
        end
        
      end

    else
    
      -- Check to see if we're in any of the strafing zones (first time).
      for _,_targetZone in pairs(self.strafeTargets) do
        
        -- Get the current approach zone and check if player is inside.
        local zonenname=_targetZone.name
        local zone=_targetZone.polygon  --Core.Zone#ZONE_POLYGON_BASE
      
        -- Check if player is in zone and below max alt and flying towards the target.
        local unitheading  = _unit:GetHeading()
        local pitheading   = _targetZone.heading - 180
        local deltaheading = unitheading-pitheading
        local towardspit   = math.abs(deltaheading)<=90 or math.abs(deltaheading-360)<=90
        local unitalt      =_unit:GetHeight()-_unit:GetCoordinate():GetLandHeight()       
      
        -- Check if unit is inside zone and below max height AGL.
        local unitinzone=_unit:IsInZone(zone) and unitalt <= self.strafemaxalt and towardspit
           
        -- Debug info.
        local text=string.format("Checking zone %s. Unit = %s, player = %s in zone = %s. alt = %d, delta heading = %d", _targetZone.name, _unitName, _playername, tostring(unitinzone), unitalt, deltaheading)
        self:T2(RANGE.id..text)
        
        -- Player is inside zone.
        if unitinzone then
        
          -- Get ammo at the beginning of the run.
          local _ammo=self:_GetAmmo(_unitName)

          -- Init strafe status for this player.
          self.strafeStatus[_unitID] = {hits = 0, zone = _targetZone, time = 1, ammo=_ammo, pastfoulline=false }
  
          -- Rolling in!
          local _msg=string.format("%s, rolling in on strafe pit %s.", self:_myname(_unitName), _targetZone.name)
          
          -- Send message.
          self:_DisplayMessageToGroup(_unit, _msg, 10, true)

          -- We found our player. Skip remaining checks.
          break
          
        end -- unit in zone check 
        
      end -- loop over zones
    end
  end
  
end

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Menu Functions

--- Add menu commands for player.
-- @param #RANGE self
-- @param #string _unitName Name of player unit.
function RANGE:_AddF10Commands(_unitName)
  self:F(_unitName)
  
  -- Get player unit and name.
  local _unit, playername = self:_GetPlayerUnitAndName(_unitName)
  
  -- Check for player unit.
  if _unit and playername then

    -- Get group and ID.
    local group=_unit:GetGroup()
    local _gid=group:GetID()
  
    if group and _gid then
  
      if not self.MenuAddedTo[_gid] then
      
        -- Enable switch so we don't do this twice.
        self.MenuAddedTo[_gid] = true
  
        -- Main F10 menu: F10/On the Range/<Range Name>/
        if RANGE.MenuF10[_gid] == nil then
          RANGE.MenuF10[_gid]=missionCommands.addSubMenuForGroup(_gid, "On the Range")
        end
        local _rangePath    = missionCommands.addSubMenuForGroup(_gid, self.rangename, RANGE.MenuF10[_gid])
        local _statsPath    = missionCommands.addSubMenuForGroup(_gid, "Statistics",   _rangePath)
        local _markPath     = missionCommands.addSubMenuForGroup(_gid, "Mark Targets", _rangePath)
        local _settingsPath = missionCommands.addSubMenuForGroup(_gid, "My Settings",  _rangePath)
        local _infoPath     = missionCommands.addSubMenuForGroup(_gid, "Range Info",   _rangePath)
        -- F10/On the Range/<Range Name>/My Settings/
        local _mysmokePath  = missionCommands.addSubMenuForGroup(_gid, "Smoke Color", _settingsPath)
        local _myflarePath  = missionCommands.addSubMenuForGroup(_gid, "Flare Color", _settingsPath)

        -- F10/On the Range/<Range Name>/Mark Targets/
        missionCommands.addCommandForGroup(_gid, "Mark On Map",         _markPath, self._MarkTargetsOnMap, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Illuminate Range",    _markPath, self._IlluminateBombTargets, self, _unitName)        
        missionCommands.addCommandForGroup(_gid, "Smoke Strafe Pits",   _markPath, self._SmokeStrafeTargetBoxes, self, _unitName)        
        missionCommands.addCommandForGroup(_gid, "Smoke Strafe Tgts",   _markPath, self._SmokeStrafeTargets, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Smoke Bomb Tgts",     _markPath, self._SmokeBombTargets, self, _unitName)
        -- F10/On the Range/<Range Name>/Stats/
        missionCommands.addCommandForGroup(_gid, "All Strafe Results",  _statsPath, self._DisplayStrafePitResults, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "All Bombing Results", _statsPath, self._DisplayBombingResults, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "My Strafe Results",   _statsPath, self._DisplayMyStrafePitResults, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "My Bomb Results",     _statsPath, self._DisplayMyBombingResults, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Reset All Stats",     _statsPath, self._ResetRangeStats, self, _unitName)
        -- F10/On the Range/<Range Name>/My Settings/Smoke Color/
        missionCommands.addCommandForGroup(_gid, "Blue Smoke",          _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.Blue)
        missionCommands.addCommandForGroup(_gid, "Green Smoke",         _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.Green)
        missionCommands.addCommandForGroup(_gid, "Orange Smoke",        _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.Orange)
        missionCommands.addCommandForGroup(_gid, "Red Smoke",           _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.Red)
        missionCommands.addCommandForGroup(_gid, "White Smoke",         _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.White)
        -- F10/On the Range/<Range Name>/My Settings/Flare Color/
        missionCommands.addCommandForGroup(_gid, "Green Flares",        _myflarePath, self._playerflarecolor, self, _unitName, FLARECOLOR.Green)
        missionCommands.addCommandForGroup(_gid, "Red Flares",          _myflarePath, self._playerflarecolor, self, _unitName, FLARECOLOR.Red)
        missionCommands.addCommandForGroup(_gid, "White Flares",        _myflarePath, self._playerflarecolor, self, _unitName, FLARECOLOR.White)
        missionCommands.addCommandForGroup(_gid, "Yellow Flares",       _myflarePath, self._playerflarecolor, self, _unitName, FLARECOLOR.Yellow)
        -- F10/On the Range/<Range Name>/My Settings/
        missionCommands.addCommandForGroup(_gid, "Smoke Delay On/Off",  _settingsPath, self._SmokeBombDelayOnOff, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Smoke Impact On/Off",  _settingsPath, self._SmokeBombImpactOnOff, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Flare Hits On/Off",    _settingsPath, self._FlareDirectHitsOnOff, self, _unitName)        
        -- F10/On the Range/<Range Name>/Range Information
        missionCommands.addCommandForGroup(_gid, "General Info",        _infoPath, self._DisplayRangeInfo, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Weather Report",      _infoPath, self._DisplayRangeWeather, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Bombing Targets",     _infoPath, self._DisplayBombTargets, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Strafe Pits",         _infoPath, self._DisplayStrafePits, self, _unitName)
      end
    else
      self:T(RANGE.id.."Could not find group or group ID in AddF10Menu() function. Unit name: ".._unitName)
    end
  else
    self:T(RANGE.id.."Player unit does not exist in AddF10Menu() function. Unit name: ".._unitName)
  end

end
    
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Helper Functions

--- Get the number of shells a unit currently has.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
-- @return Number of shells left
function RANGE:_GetAmmo(unitname)
  self:F2(unitname)
  
  -- Init counter.
  local ammo=0
  
  local unit, playername = self:_GetPlayerUnitAndName(unitname)
  
  if unit and playername then
  
    local has_ammo=false
    
    local ammotable=unit:GetAmmo()
    self:T2({ammotable=ammotable})
    
    if ammotable ~= nil then
    
      local weapons=#ammotable
      self:T2(RANGE.id..string.format("Number of weapons %d.", weapons))
      
      for w=1,weapons do
      
        local Nammo=ammotable[w]["count"]
        local Tammo=ammotable[w]["desc"]["typeName"]
        
        -- We are specifically looking for shells here.
        if string.match(Tammo, "shell") then
        
          -- Add up all shells
          ammo=ammo+Nammo
        
          local text=string.format("Player %s has %d rounds ammo of type %s", playername, Nammo, Tammo)
          self:T(RANGE.id..text)
          MESSAGE:New(text, 10):ToAllIf(self.Debug)
        else
          local text=string.format("Player %s has %d ammo of type %s", playername, Nammo, Tammo)
          self:T(RANGE.id..text)
          MESSAGE:New(text, 10):ToAllIf(self.Debug)
        end
      end
    end
  end
      
  return ammo
end

--- Mark targets on F10 map.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
function RANGE:_MarkTargetsOnMap(_unitName)
  self:F(_unitName)

  -- Get group.
  local group=nil
  if _unitName then
    group=UNIT:FindByName(_unitName):GetGroup()
  end
  
  -- Mark bomb targets.
  for _,_bombtarget in pairs(self.bombingTargets) do
    local _target=_bombtarget.target --Wrapper.Positionable#POSITIONABLE
    if _target and _target:IsAlive() then
      local coord=_target:GetCoordinate() --Core.Point#COORDINATE
      if group then
        coord:MarkToGroup("Bomb target ".._bombtarget.name, group)
      else
        coord:MarkToAll("Bomb target ".._bombtarget.name)
      end
    end
  end
  
  -- Mark strafe targets.
  for _,_strafepit in pairs(self.strafeTargets) do
    for _,_target in pairs(_strafepit.targets) do
      local _target=_target --Wrapper.Positionable#POSITIONABLE
      if _target and _target:IsAlive() then
        local coord=_target:GetCoordinate() --Core.Point#COORDINATE
        if group then
          coord:MarkToGroup("Strafe target ".._target:GetName(), group)
        else
          coord:MarkToAll("Strafe target ".._target:GetName())
        end
      end
    end
  end
  
  if _unitName then
    local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
    local text=string.format("%s, %s, range targets are now marked on F10 map.", self.rangename, _playername)
    self:_DisplayMessageToGroup(_unit, text, 5)
  end
    
end

--- Illuminate targets. Fires illumination bombs at one random bomb and one random strafe target at a random altitude between 400 and 800 m.
-- @param #RANGE self
-- @param #string _unitName (Optional) Name of the player unit.
function RANGE:_IlluminateBombTargets(_unitName)
  self:F(_unitName)

  -- All bombing target coordinates.
  local bomb={}

  for _,_bombtarget in pairs(self.bombingTargets) do
    local _target=_bombtarget.target --Wrapper.Positionable#POSITIONABLE
    if _target and _target:IsAlive() then
      local coord=_target:GetCoordinate() --Core.Point#COORDINATE
      table.insert(bomb, coord)
    end
  end
  
  if #bomb>0 then
    local coord=bomb[math.random(#bomb)] --Core.Point#COORDINATE
    local c=COORDINATE:New(coord.x,coord.y+math.random(self.illuminationminalt,self.illuminationmaxalt),coord.z)
    c:IlluminationBomb()
  end
  
  -- All strafe target coordinates.
  local strafe={}
  
  for _,_strafepit in pairs(self.strafeTargets) do
    for _,_target in pairs(_strafepit.targets) do
      local _target=_target --Wrapper.Positionable#POSITIONABLE
      if _target and _target:IsAlive() then
        local coord=_target:GetCoordinate() --Core.Point#COORDINATE
        table.insert(strafe, coord)
      end
    end
  end
  
  -- Pick a random strafe target.
  if #strafe>0 then
    local coord=strafe[math.random(#strafe)] --Core.Point#COORDINATE
    local c=COORDINATE:New(coord.x,coord.y+math.random(self.illuminationminalt,self.illuminationmaxalt),coord.z)
    c:IlluminationBomb()
  end
  
  if _unitName then
    local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
    local text=string.format("%s, %s, range targets are illuminated.", self.rangename, _playername)
    self:_DisplayMessageToGroup(_unit, text, 5)
  end
end

--- Reset player statistics.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
function RANGE:_ResetRangeStats(_unitName)
  self:F(_unitName)

  -- Get player unit and name.  
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  
  if _unit and _playername then  
    self.strafePlayerResults[_playername] = nil
    self.bombPlayerResults[_playername] = nil
    local text=string.format("%s, %s, your range stats were cleared.", self.rangename, _playername)
    self:DisplayMessageToGroup(_unit, text, 5)
  end
end

--- Display message to group.
-- @param #RANGE self
-- @param Wrapper.Unit#UNIT _unit Player unit.
-- @param #string _text Message text.
-- @param #number _time Duration how long the message is displayed.
-- @param #boolean _clear Clear up old messages.
function RANGE:_DisplayMessageToGroup(_unit, _text, _time, _clear)
  self:F({unit=_unit, text=_text, time=_time, clear=_clear})
  
  _time=_time or self.Tmsg
  if _clear==nil then
    _clear=false
  end
  
  -- Group ID.
  local _gid=_unit:GetGroup():GetID()
  
  if _gid and not self.examinerexclusive then
    if _clear == true then
      trigger.action.outTextForGroup(_gid, _text, _time, _clear)
    else
      trigger.action.outTextForGroup(_gid, _text, _time)
    end
  end

  if self.examinergroupname~=nil then
    local _examinerid=GROUP:FindByName(self.examinergroupname):GetID()
    if _examinerid then
      if _clear == true then
        trigger.action.outTextForGroup(_examinerid, _text, _time, _clear)
      else
        trigger.action.outTextForGroup(_examinerid, _text, _time)
      end
    end  
  end
  
end

--- Toggle status of smoking bomb impact points.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_SmokeBombImpactOnOff(unitname)
  self:F(unitname)
  
  local unit, playername = self:_GetPlayerUnitAndName(unitname)
  if unit and playername then
    local text
    if self.PlayerSettings[playername].smokebombimpact==true then
      self.PlayerSettings[playername].smokebombimpact=false
      text=string.format("%s, %s, smoking impact points of bombs is now OFF.", self.rangename, playername)
    else
      self.PlayerSettigs[playername].smokebombimpact=true
      text=string.format("%s, %s, smoking impact points of bombs is now ON.", self.rangename, playername)
    end
    self:_DisplayMessageToGroup(unit, text, 5)
  end
  
end

--- Toggle status of time delay for smoking bomb impact points
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_SmokeBombDelayOnOff(unitname)
  self:F(unitname)
  
  local unit, playername = self:_GetPlayerUnitAndName(unitname)
  if unit and playername then
    local text
    if self.PlayerSettings[playername].delaysmoke==true then
      self.PlayerSettings[playername].delaysmoke=false
      text=string.format("%s, %s, delayed smoke of bombs is now OFF.", self.rangename, playername)
    else
      self.PlayerSettigs[playername].delaysmoke=true
      text=string.format("%s, %s, delayed smoke of bombs is now ON.", self.rangename, playername)
    end
    self:_DisplayMessageToGroup(unit, text, 5)
  end
  
end

--- Toggle status of flaring direct hits of range targets.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_FlareDirectHitsOnOff(unitname)
  self:F(unitname)
  
  local unit, playername = self:_GetPlayerUnitAndName(unitname)
  if unit and playername then
    local text
    if self.PlayerSettings[playername].flaredirecthits==true then
      self.PlayerSettings[playername].flaredirecthits=false
      text=string.format("%s, %s, flaring direct hits is now OFF.", self.rangename, playername)
    else
      self.PlayerSettings[playername].flaredirecthits=true
      text=string.format("%s, %s, flaring direct hits is now ON.", self.rangename, playername)
    end
    self:_DisplayMessageToGroup(unit, text, 5)
  end
  
end

--- Mark bombing targets with smoke.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_SmokeBombTargets(unitname)
  self:F(unitname)
  
  for _,_bombtarget in pairs(self.bombingTargets) do
    local _target=_bombtarget.target --Wrapper.Positionable#POSITIONABLE
    if _target and _target:IsAlive() then
      local coord = _target:GetCoordinate() --Core.Point#COORDINATE
      coord:Smoke(self.BombSmokeColor)
    end
  end
  
  if unitname then
    local unit, playername = self:_GetPlayerUnitAndName(unitname)
    local text=string.format("%s, %s, bombing targets are now marked with %s smoke.", self.rangename, playername, self:_smokecolor2text(self.BombSmokeColor))
    self:_DisplayMessageToGroup(unit, text, 5)
  end
  
end

--- Mark strafing targets with smoke.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_SmokeStrafeTargets(unitname)
  self:F(unitname)
  
  for _,_target in pairs(self.strafeTargets) do
    _target.coordinate:Smoke(self.StrafeSmokeColor)
  end
  
  if unitname then
    local unit, playername = self:_GetPlayerUnitAndName(unitname)
    local text=string.format("%s, %s, strafing tragets are now marked with %s smoke.", self.rangename, playername, self:_smokecolor2text(self.StrafeSmokeColor))
    self:_DisplayMessageToGroup(unit, text, 5)
  end
  
end

--- Mark approach boxes of strafe targets with smoke.
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_SmokeStrafeTargetBoxes(unitname)
  self:F(unitname)
  
  for _,_target in pairs(self.strafeTargets) do
    local zone=_target.polygon --Core.Zone#ZONE
    zone:SmokeZone(self.StrafePitSmokeColor)
    for _,_point in pairs(_target.smokepoints) do
      _point:SmokeOrange()  --Corners are smoked orange.
    end
  end
  
  if unitname then
    local unit, playername = self:_GetPlayerUnitAndName(unitname)
    local text=string.format("%s, %s, strafing pit approach boxes are now marked with %s smoke.", self.rangename, playername, self:_smokecolor2text(self.StrafePitSmokeColor))
    self:_DisplayMessageToGroup(unit, text, 5)
  end
    
end

--- Sets the smoke color used to smoke players bomb impact points.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
-- @param Utilities.Utils#SMOKECOLOR color ID of the smoke color.
function RANGE:_playersmokecolor(_unitName, color)
  self:F({unitname=_unitName, color=color})
  
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  if _unit and _playername then
    self.PlayerSettings[_playername].smokecolor=color
    local text=string.format("%s, %s, your bomb impacts are now smoked in %s.", self.rangename, _playername,  self:_smokecolor2text(color))
    self:_DisplayMessageToGroup(_unit, text, 5)
  end
  
end

--- Sets the flare color used when player makes a direct hit on target.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
-- @param Utilities.Utils#FLARECOLOR color ID of flare color.
function RANGE:_playerflarecolor(_unitName, color)
  self:F({unitname=_unitName, color=color})
  
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  if _unit and _playername then
    self.PlayerSettings[_playername].flarecolor=color
    local text=string.format("%s, %s, your direct hits are now flared in %s.", self.rangename, _playername, self:_flarecolor2text(color))
    self:_DisplayMessageToGroup(_unit, text, 5)
  end
  
end

--- Converts a smoke color id to text. E.g. SMOKECOLOR.Blue --> "blue".
-- @param #RANGE self
-- @param Utilities.Utils#SMOKECOLOR color Color Id.
-- @return #string Color text.
function RANGE:_smokecolor2text(color)
  self:F(color)
  
  local txt=""
  if color==SMOKECOLOR.Blue then
    txt="blue"
  elseif color==SMOKECOLOR.Green then
    txt="green"
  elseif color==SMOKECOLOR.Orange then
    txt="orange"
  elseif color==SMOKECOLOR.Red then
    txt="red"
  elseif color==SMOKECOLOR.White then
    txt="white"
  else
    txt=string.format("unkown color (%s)", tostring(color))
  end
  
  return txt
end

--- Sets the flare color used to flare players direct target hits.
-- @param #RANGE self
-- @param Utilities.Utils#FLARECOLOR color Color Id.
-- @return #string Color text.
function RANGE:_flarecolor2text(color)
  self:F(color)
  
  local txt=""
  if color==FLARECOLOR.Green then
    txt="green"
  elseif color==FLARECOLOR.Red then
    txt="red"
  elseif color==FLARECOLOR.White then
    txt="white"
  elseif color==FLARECOLOR.Yellow then
    txt="yellow"
  else
    txt=string.format("unkown color (%s)", tostring(color))
  end
  
  return txt
end

--- Checks if a static object with a certain name exists. It also added it to the MOOSE data base, if it is not already in there.
-- @param #RANGE self
-- @param #string name Name of the potential static object.
-- @return #boolean Returns true if a static with this name exists. Retruns false if a unit with this name exists. Returns nil if neither unit or static exist.
function RANGE:_CheckStatic(name)
  self:F2(name)

  -- Get DCS static object.
  local _DCSstatic=StaticObject.getByName(name)
  
  if _DCSstatic and _DCSstatic:isExist() then
  
    --Static does exist at least in DCS. Check if it also in the MOOSE DB.
    local _MOOSEstatic=STATIC:FindByName(name, false)
    
    -- If static is not yet in MOOSE DB, we add it. Can happen for cargo statics!
    if not _MOOSEstatic then
      self:T(RANGE.id..string.format("Adding DCS static to MOOSE database. Name = %s.", name))
      _DATABASE:AddStatic(name)
    end
    
    return true
  else
    self:T3(RANGE.id..string.format("No static object with name %s exists.", name))
  end
  
  -- Check if a unit has this name.
  if UNIT:FindByName(name) then
    return false
  else
    self:T3(RANGE.id..string.format("No unit object with name %s exists.", name))
  end

  -- If not unit or static exist, we return nil.
  return nil
end

--- Get max speed of controllable.
-- @param #RANGE self
-- @param Wrapper.Controllable#CONTROLLABLE controllable
-- @return Maximum speed in km/h.
function RANGE:_GetSpeed(controllable)
  self:F2(controllable)

  -- Get DCS descriptors
  local desc=controllable:GetDesc()
  
  -- Get speed
  local speed=0
  if desc then
    speed=desc.speedMax*3.6
    self:T({speed=speed})
  end
  
  return speed
end

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player.
-- @return #string Name of the player.
-- @return nil If player does not exist.
function RANGE:_GetPlayerUnitAndName(_unitName)
  self:F2(_unitName)

  if _unitName ~= nil then
  
    -- Get DCS unit from its name.
    local DCSunit=Unit.getByName(_unitName)
    
    if DCSunit then
    
      local playername=DCSunit:getPlayerName()
      local unit=UNIT:Find(DCSunit)
    
      self:T2({DCSunit=DCSunit, unit=unit, playername=playername})
      if DCSunit and unit and playername then
        return unit, playername
      end
      
    end
    
  end
  
  -- Return nil if we could not find a player.
  return nil,nil
end

--- Returns a string which consits of this callsign and the player name.  
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_myname(unitname)
  self:F2(unitname)
  
  local unit=UNIT:FindByName(unitname)
  local pname=unit:GetPlayerName()
  local csign=unit:GetCallsign()
  
  return string.format("%s (%s)", csign, pname)
end

--- Split string. Cf http://stackoverflow.com/questions/1426954/split-string-in-lua
-- @param #RANGE self
-- @param #string str Sting to split.
-- @param #string sep Speparator for split.
-- @return #table Split text.
function RANGE:_split(str, sep)
  self:F2({str=str, sep=sep})
  
  local result = {}
  local regex = ("([^%s]+)"):format(sep)
  for each in str:gmatch(regex) do
      table.insert(result, each)
  end
  
  return result
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
