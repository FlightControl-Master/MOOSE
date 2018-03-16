-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- **Functional** - Range Practice.
--  
-- ![Banner Image](..\Presentations\RANGE\RANGE_Main.png)
-- 
-- ====
-- 
-- The RANGE class enables easy set up of bombing and strafing ranges within DCS World.
-- 
-- Implementation is based on the [Simple Range Script](https://forums.eagle.ru/showthread.php?t=157991) by [Ciribob](https://forums.eagle.ru/member.php?u=112175), which itself was motivated
-- by a script by SNAFU [see here](https://forums.eagle.ru/showthread.php?t=109174).
-- 
-- ## Features
--
-- * Bomb and rocket impact point from closest range target is measured and distance reported to the player.
-- * Number of hits on strafing passes are counted.
-- * Results of all bombing and strafing runs are stored and top 10 results can be displayed. 
-- * Range targets can be marked by smoke.
-- * Range can be illuminated by illumination bombs for night practices.
-- * Rocket or bomb impact points can be marked by smoke.
-- * Direct hits on targets can trigger flares.
-- * Smoke and flare colors can be adjusted for each player via radio menu.
-- * Range information and weather report at the range can be reported via radio menu.
-- 
-- More information and examples can be found below.
-- 
-- ====
-- 
-- # Demo Missions
--
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [MOOSE YouTube Channel](https://www.youtube.com/playlist?list=PL7ZUrU4zZUl1jirWIo4t4YxqN-HxjqRkL)
-- 
-- ===
-- 
-- ### Author: **[funkyfranky](https://forums.eagle.ru/member.php?u=115026)**
-- 
-- ### Contributions: [FlightControl](https://forums.eagle.ru/member.php?u=89536), [Ciribob](https://forums.eagle.ru/member.php?u=112175)
-- 
-- ====
-- @module Range

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- RANGE class
-- @type RANGE
-- @field #string ClassName Name of the Class.
-- @field #boolean Debug If true, debug info is send as messages on the screen.
-- @field #string rangename Name of the range.
-- @field Core.Point#COORDINATE location Coordinate of the range.
-- @field #number rangeradius Radius of range defining its total size for e.g. smoking bomb impact points. Default 10 km.
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
-- @field #number Tmsg Time [sec] messages to players are displayed. Default 30 sec.
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
-- @extends Core.Base#BASE

---# RANGE class, extends @{Base#BASE}
-- The RANGE class enables a mission designer to easily set up practice ranges in DCS. A new RANGE object can be created with the @{#RANGE.New}(rangename) contructor.
-- The parameter "rangename" defindes the name of the range. It has to be unique since this is also the name displayed in the radio menu.
-- 
-- Generally, a range consits of strafe pits and bombing targets. For strafe pits the number of hits for each pass is counted and tabulated.
-- For bombing targets, the distance from the impact point of the bomb or rocket to the closest range target is measured and tabulated.
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
-- A strafe pit can be added to the range by the @{#RANGE.AddStrafepit}(unitnames, boxlength, boxwidth, heading, inverseheading, goodpass, foulline) function.
-- 
-- The first parameter defines the target. This has to be given as a lua table which contains the unit names of the targets as defined in the mission editor.
-- 
-- In order to perform a valid pass on the strafe pit, the pilot has to begin his run from the correct direction. Therefore, an "approach box" is defined in front
-- of the strafe targets. The parameters "boxlength" and "boxwidth" define the size of the box while the parameter "heading" defines its direction.
-- If the parameter heading is passed as **nil**, the heading is automatically taken from the heading of the first target unit as defined in the ME.
-- The parameter "inverseheading" turns the heading around by 180 degrees. This is sometimes useful, since the default heading of strafe target units point in the
-- wrong/opposite direction.
-- 
-- The parameter "goodpass" defines the number of hits a pilot has to achive during a run to be judges as a good pass.
-- 
-- The last parameter "foulline" sets the distance from the pit targets to the foul line. Hit from closer than this line are not counted.
-- 
-- Finally, a valid approach has to be performed below a certain maximum altitude. The default is 914 meters (3000 ft) AGL. This is a parameter valid for all
-- strafing pits of the range and can be adjusted by the @{#RANGE.SetMaxStrafeAlt}(maxalt) function.
-- 
-- ## Bombing targets
-- One ore multiple bombing targets can be added to the range by the @{#RANGE.AddBombingTargets}(unitnames goodhitrange,static) function.
-- 
-- The first parameter "unitnames" has to be a lua table, which contains the names of the units as defined in the mission editor.
-- 
-- The parameter "goodhitrange" specifies the radius around the target. If a bomb or rocket falls at a distance smaller than this number, the hit is considered to be "good".
-- 
-- The final (optional) parameter "static" can be enabled (set to true) if static bomb targets are used rather than alive units.
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
-- This example shows hot to set up the Barry M. Goldwater range. It consists of two strafe pits each has two targets plus three bombing targets.
-- 
--      -- Strafe pits. Each pit can consist of multiple targets. Here we have two pits and each of the pits has two targets. These are names of the corresponding units defined in the ME.
--      local strafepit_left={"GWR Strafe Pit Left 1", "GWR Strafe Pit Left 2"}
--      local strafepit_right={"GWR Strafe Pit Right 1", "GWR Strafe Pit Right 2"}
--      
--      -- Table of bombing target names. Again these are the names of the corresponding units as defined in the ME.
--      local bombtargets={"GWR Bomb Target Circle Left", "GWR Bomb Target Circle Right", "GWR Bomb Target Hard"}
--      
--      -- Create a range object.
--      local GoldwaterRange=RANGE:New("Goldwater Range")
--      
--      -- Distance between foul line and strafe target. Note that this could also be done manually by simply measuring the distance between the target and the foul line in the ME.
--      local strafe=UNIT:FindByName("GWR Strafe Pit Left 1")
--      local foul=UNIT:FindByName("GWR Foul Line Left")
--      local fouldist=strafe:GetCoordinate():Get2DDistance(foul:GetCoordinate())
--      
--      -- Add strafe pits. Each pit (left and right) consists of two targets.
--      GoldwaterRange:AddStrafePit(strafepit_left, 3000, 300, nil, true, 20, fouldist)
--      GoldwaterRange:AddStrafePit(strafepit_right, 3000, 300, nil, true, 20, fouldist)
--      
--      -- Add bombing targets. A good hit is if the bomb falls less then 50 m from the target.
--      GoldwaterRange:AddBombingTargets(bombtargets, 50)
--      
--      -- Start range.
--      GoldwaterRange:Start()
-- 
-- 
-- 
-- @field #RANGE
RANGE={
  ClassName = "RANGE",
  Debug=false,
  rangename=nil,
  location=nil,
  rangeradius=10000,
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
  Tmsg=30,
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
}

--- Some ID to identify who we are in output of the DCS.log file.
-- @field #string id
RANGE.id="RANGE | "

--- Range script version.
-- @field #number version
RANGE.version="1.0.0"

--TODO list
--TODO: Add statics for strafe pits.
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
  self.rangename=rangename or "Practice Range"
  
  -- Debug info.
  local text=string.format("RANGE script version %s. Creating new RANGE object. Range name: %s.", RANGE.version, self.rangename)
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
    --_target.name
    if _location==nil then
      _location=_target.point --Core.Point#COORDINATE
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
  
  -- Location of the range. We simply take the first unit/target we find.
  self.location=_location
  
  if self.location==nil then
    local text=string.format("ERROR! No range location found. Number of strafe targets = %d. Number of bomb targets = %d.", self.rangename, self.nstrafetargets, self.nbombtargets)
    self:E(RANGE.id..text)
    return nil
  end
  
  -- Starting range.
  local text=string.format("Starting RANGE %s. Number of strafe targets = %d. Number of bomb targets = %d.", self.rangename, self.nstrafetargets, self.nbombtargets)
  self:E(RANGE.id..text)
  MESSAGE:New(text,10):ToAllIf(self.Debug)
  
  -- Event handling.
  if self.eventmoose then
    -- Events are handled my MOOSE.
    self:T(RANGE.id.."Events are handled by MOOSE.")
    self:HandleEvent(EVENTS.Birth, self._OnBirth)
    self:HandleEvent(EVENTS.Hit,   self._OnHit)
    self:HandleEvent(EVENTS.Shot,  self._OnShot)
  else
    -- Events are handled directly by DCS.
    self:T(RANGE.id.."Events are handled directly by DCS.")
    world.addEventHandler(self)
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions

--- Set maximal strafing altitude. Player entering a strafe pit above that altitude are not registered for a valid pass.
-- @param #RANGE self
-- @param #number maxalt Maximum altitude AGL in meters. Default is 914 m= 3000 ft.
function RANGE:SetMaxStrafeAlt(maxalt)
  self.strafemaxalt=maxalt or 914
end

--- Set time interval for tracking bombs. A smaller time step increases accuracy but needs more CPU time.
-- @param #RANGE self
-- @param #number dt Time interval in seconds. Default is 0.005 s.
function RANGE:SetBombtrackTimestep(dt)
  self.dtBombtrack=dt or 0.005
end

--- Set time how long (most) messages are displayed.
-- @param #RANGE self
-- @param #number time Time in seconds. Default is 30 s.
function RANGE:SetMessageTimeDuration(time)
  self.Tmsg=time or 30
end

--- Set max number of player results that are displayed.
-- @param #RANGE self
-- @param #number nmax Number of results. Default is 10.
function RANGE:SetDisplayedMaxPlayerResults(nmax)
  self.ndisplayresult=nmax or 10
end

--- Set range radius. Defines the area in which e.g. bomb impacts are smoked.
-- @param #RANGE self
-- @param #number radius Radius in km. Default 10 km.
function RANGE:SetRangeRadius(radius)
  self.rangeradius=radius*1000 or 10000
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
  self.TdelaySmoke=delay or 3.0
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


--- Add new strafe pit. For a strafe pit, hits from guns are counted. One pit can consist of several units.
-- Note, an approach is only valid, if the player enters via a zone in front of the pit, which defined by boxlength and boxheading.
-- Furthermore, the player must not be too high and fly in the direction of the pit to make a valid target apporoach.
-- @param #RANGE self
-- @param #table unitnames Table of unit names defining the strafe targets. The first target in the list determines the approach zone (heading and box).
-- @param #number boxlength (Optional) Length of the approach box in meters. Default is 3000 m.
-- @param #number boxwidth (Optional) Width of the approach box in meters. Default is 300 m.
-- @param #number heading (Optional) Approach heading in Degrees. Default is heading of the unit as defined in the mission editor.
-- @param #boolean inverseheading (Optional) Take inverse heading (heading --> heading - 180 Degrees). Default is false.
-- @param #number goodpass (Optional) Number of hits for a "good" strafing pass. Default is 20.
-- @param #number foulline (Optional) Foul line distance. Hits from closer than this distance are not counted. Default 610 m = 2000 ft. Set to 0 for no foul line.
function RANGE:AddStrafePit(unitnames, boxlength, boxwidth, heading, inverseheading, goodpass, foulline)
  self:F({unitnames=unitnames, boxlength=boxlength, boxwidth=boxwidth, heading=heading, inverseheading=inverseheading, goodpass=goodpass, foulline=foulline})

  -- Create table if necessary.  
  if type(unitnames) ~= "table" then
    unitnames={unitnames}
  end
  
  -- Make targets
  local _targets={}
  local center=nil --Wrapper.Unit#UNIT
  local ntargets=0
  
  for _i,_name in ipairs(unitnames) do
  
    self:T(RANGE.id..string.format("Adding strafe target #%d %s", _i, _name))
    local unit=UNIT:FindByName(_name)
    
    if unit then
      table.insert(_targets, unit)
      -- Define center as the first unit we find
      if center==nil then
        center=unit
      end
      ntargets=ntargets+1
    else
      local text=string.format("ERROR! Could not find strafe target with name %s.", _name)
      self:E(RANGE.id..text)
      MESSAGE:New(text, 10):ToAllIf(self.Debug)
    end
    
  end

  -- Approach box dimensions.
  local l=boxlength or 3000
  local w=(boxwidth or 300)/2
  
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
  local goodpass=goodpass or 20
  
  -- Foule line distance.
  local foulline=foulline or 610
  
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
  table.insert(self.strafeTargets, {name=_name, polygon=_polygon, goodPass=goodpass, targets=_targets, foulline=foulline, smokepoints=p, heading=heading})
  
  -- Debug info
  local text=string.format("Adding new strafe target %s with %d targets: heading = %03d, box_L = %.1f, box_W = %.1f, goodpass = %d, foul line = %.1f", _name, ntargets, heading, boxlength, boxwidth, goodpass, foulline)  
  self:T(RANGE.id..text)
  MESSAGE:New(text, 5):ToAllIf(self.Debug)
end

--- Add bombing target(s) to range.
-- @param #RANGE self
-- @param #table unitnames Table containing the unit names acting as bomb targets.
-- @param #number goodhitrange (Optional) Max distance from target unit (in meters) which is considered as a good hit. Default is 25 m.
-- @param #boolean static (Optional) Target is static. Default false.
function RANGE:AddBombingTargets(unitnames, goodhitrange, static)
  self:F({unitnames=unitnames, goodhitrange=goodhitrange, static=static})

  -- Create a table if necessary.
  if type(unitnames) ~= "table" then
    unitnames={unitnames}
  end
  
  if static == nil or static == false then
    static=false
  else
    static=true
  end
  
  -- Default range is 25 m.
  goodhitrange=goodhitrange or 25
  
  for _,name in pairs(unitnames) do
    local _unit
    local _static
    
    if static then
     
      -- Add static object. Workaround since cargo objects are not yet in database because DCS function does not add those.
      local _DCSstatic=StaticObject.getByName(name)
      if _DCSstatic and _DCSstatic:isExist() then
        self:T(RANGE.id..string.format("Adding DCS static to database. Name = %s.", name))
        _DATABASE:AddStatic(name)
      else
        self:E(RANGE.id..string.format("ERROR! DCS static DOES NOT exist! Name = %s.", name))
      end
      
      -- Now we can find it...
      _static=STATIC:FindByName(name)
      if _static then
        self:AddBombingTargetUnit(_static, goodhitrange)
        self:T(RANGE.id..string.format("Adding static bombing target %s with hit range %d.", name, goodhitrange))
      else
        self:E(RANGE.id..string.format("ERROR! Cound not find static bombing target %s.", name))
      end
      
    else
    
      _unit=UNIT:FindByName(name)
      if _unit then
        self:AddBombingTargetUnit(_unit, goodhitrange)
        self:T(RANGE.id..string.format("Adding bombing target %s with hit range %d.", name, goodhitrange))
      else
        self:E(RANGE.id..string.fromat("ERROR! Could not find bombing target %s.", name))
      end
      
    end

  end
end

--- Add a unit as bombing target.
-- @param #RANGE self
-- @param Wrapper.Unit#UNIT unit Unit of the strafe target.
-- @param #number goodhitrange Max distance from unit which is considered as a good hit.
function RANGE:AddBombingTargetUnit(unit, goodhitrange)
  self:F({unit=unit, goodhitrange=goodhitrange})
  
  local coord=unit:GetCoordinate()
  local name=unit:GetName()
  
  -- Default range is 25 m.
  goodhitrange=goodhitrange or 25  
  
  -- Create a zone around the unit.
  local Vec2=coord:GetVec2()
  local Rzone=ZONE_RADIUS:New(name, Vec2, goodhitrange)
  
  -- Insert target to table.
  table.insert(self.bombingTargets, {name=name, point=coord, zone=Rzone, target=unit, goodhitrange=goodhitrange})
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Event Handling

--- General event handler.
-- @param #RANGE self
-- @param #table Event DCS event table.
function RANGE:onEvent(Event)
  self:F3(Event)

  if Event == nil or Event.initiator == nil or Unit.getByName(Event.initiator:getName()) == nil then
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
    EventData.TgtDCSGroup  = Event.target:getGroup()
    EventData.TgtGroupName = Event.target:getGroup():getName()
    EventData.TgtGroup     = GROUP:FindByName(EventData.TgtGroupName)
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
  self:T3(RANGE.id..string.format("EVENT: Tgt group  = %s" , tostring(EventData.IniGroupName)))
  self:T3(RANGE.id..string.format("EVENT: Wpn type   = %s" , tostring(EventData.WeapoinTypeName)))
    
  -- Call event Birth function.
  if Event.id==world.event.S_EVENT_BIRTH and _playername then
    self:_OnBirth(EventData)
  end
  
  -- Call event Shot function.
  if Event.id==world.event.S_EVENT_SHOT and _playername and Event.weapon then
    self:_OnShot(EventData)
  end
  
  -- Call event Hit function.
  if Event.id==world.event.S_EVENT_HIT and _playername and DCStgtunit then
    self:_OnHit(EventData)
  end
  
end


--- Range event handler for event birth.
-- @param #RANGE self
-- @param Core.Event#EVENTDATA EventData
function RANGE:_OnBirth(EventData)
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
function RANGE:_OnHit(EventData)
  self:F({eventhit = EventData})

  -- Player info
  local _unitName = EventData.IniUnitName
  local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
  local _unitID   = _unit:GetID()

  -- Target
  local target     = EventData.TgtUnit
  local targetname = EventData.TgtUnitName
  
  -- Debug info.
  self:T3(RANGE.id.."HIT: Ini unit   = "..tostring(EventData.IniUnitName))
  self:T3(RANGE.id.."HIT: Ini group  = "..tostring(EventData.IniGroupName))
  self:T3(RANGE.id.."HIT: Tgt target = "..tostring(EventData.TgtUnitName))
  self:T3(RANGE.id.."HIT: Tgt group  = "..tostring(EventData.TgtGroupName))
  
  -- Current strafe target of player.
  local _currentTarget = self.strafeStatus[_unitID]

  -- Player has rolled in on a strafing target.
  if _currentTarget then
  
    local playerPos = _unit:GetCoordinate()
    local targetPos = target:GetCoordinate()

    -- Loop over valid targets for this run.
    for _,_target in pairs(_currentTarget.zone.targets) do
    
      -- Check the the target is the same that was actually hit.
      if _target:GetName() == targetname then
      
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
  for _,_target in pairs(self.bombingTargets) do
  
    -- Check if one of the bomb targets was hit.
    if _target.name == targetname then      
      
      if _unit and _playername then
      
        local playerPos = _unit:GetCoordinate()
        local targetPos = target:GetCoordinate()
      
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
function RANGE:_OnShot(EventData)
  self:F({eventshot = EventData})
  
  -- Weapon data.
  local _weapon = EventData.Weapon:getTypeName()  -- should be the same as Event.WeaponTypeName
  local _weaponStrArray = self:_split(_weapon,"%.")
  local _weaponName = _weaponStrArray[#_weaponStrArray]
  
  -- Debug info.
  self:T3(RANGE.id.."EVENT SHOT: Ini unit    = "..EventData.IniUnitName)
  self:T3(RANGE.id.."EVENT SHOT: Ini group   = "..EventData.IniGroupName)
  self:T3(RANGE.id.."EVENT SHOT: Weapon type = ".._weapon)
  self:T3(RANGE.id.."EVENT SHOT: Weapon name = ".._weaponName)
  
  -- Monitor only bombs and rockets.
  if (string.match(_weapon, "weapons.bombs") or string.match(_weapon, "weapons.nurs")) then

    -- Weapon
    local _ordnance =  EventData.weapon

    -- Tracking info and init of last bomb position.
    self:T(RANGE.id..string.format("Tracking %s - %s.", _weapon, _ordnance:getName()))
    
    -- Init bomb position.
    local _lastBombPos = {x=0,y=0,z=0}

    -- Get unit name.
    local _unitName = EventData.IniUnitName
        
    -- Function monitoring the position of a bomb until impact.
    local function trackBomb(_previousPos)
      
      -- Get player unit and name.
      local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
      local _callsign=self:_myname(_unitName)

      if _unit and _playername then

        -- When the pcall returns a failure the weapon has hit.
        local _status,_bombPos =  pcall(
        function()
          return _ordnance:getPoint()
        end)

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
  
            -- Distance between bomb and target.
            local _temp = impactcoord:Get2DDistance(_bombtarget.point)
  
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

            -- Sendmessage.
            self:_DisplayMessageToGroup(_unit, _message, nil, true)
          else
            -- Sendmessage
            local _message=string.format("%s, weapon fell more than %.1f km away from nearest range target. No score!", _callsign, self.scorebombdistance/1000)
            self:_DisplayMessageToGroup(_unit, _message, nil, true)
          end
  
        end -- _status
          
      end -- end unit ~= nil
      
      return nil --Terminate the timer
    end -- end function bombtrack

    timer.scheduleFunction(trackBomb, nil, timer.getTime() + 1)
    
  end --if string.match
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
  self:F(_unitName)

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
      self:T(RANGE.id..text)
    
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
    
          -- Message text.      
          local _text=string.format("%s, %s with %d hits on target %s.", self:_myname(_unitName), _result.text, _result.hits, _result.zone.name)
          
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
        self:T(RANGE.id..text)
        
        -- Player is inside zone.
        if unitinzone then

          -- Init strafe status for this player.
          self.strafeStatus[_unitID] = {hits = 0, zone = _targetZone, time = 1, pastfoulline=false }
  
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
  
        -- Main F10 menu: F10/On the Range
        local _rootPath     = missionCommands.addSubMenuForGroup(_gid, "On the Range")
        local _rangePath    = missionCommands.addSubMenuForGroup(_gid, self.rangename, _rootPath)
        local _statsPath    = missionCommands.addSubMenuForGroup(_gid, "Statistics",   _rangePath)
        local _markPath     = missionCommands.addSubMenuForGroup(_gid, "Mark Targets", _rangePath)
        local _settingsPath = missionCommands.addSubMenuForGroup(_gid, "My Settings",  _rangePath)
        -- F10/On the Range/My Settings/
        local _mysmokePath  = missionCommands.addSubMenuForGroup(_gid, "Smoke Color", _settingsPath)
        local _myflarePath  = missionCommands.addSubMenuForGroup(_gid, "Flare Color", _settingsPath)


        --TODO: Convert to MOOSE menu.
        -- F10/On the Range/Mark Targets/
        missionCommands.addCommandForGroup(_gid, "Mark On Map",         _markPath, self._MarkTargetsOnMap, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Illuminate Range",    _markPath, self._IlluminateBombTargets, self, _unitName)        
        missionCommands.addCommandForGroup(_gid, "Smoke Strafe Pits",   _markPath, self._SmokeStrafeTargetBoxes, self, _unitName)        
        missionCommands.addCommandForGroup(_gid, "Smoke Strafe Tgts",   _markPath, self._SmokeStrafeTargets, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Smoke Bomb Tgts",     _markPath, self._SmokeBombTargets, self, _unitName)
        -- F10/On the Range/Stats/
        missionCommands.addCommandForGroup(_gid, "All Strafe Results",  _statsPath, self._DisplayStrafePitResults, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "All Bombing Results", _statsPath, self._DisplayBombingResults, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "My Strafe Results",   _statsPath, self._DisplayMyStrafePitResults, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "My Bomb Results",     _statsPath, self._DisplayMyBombingResults, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Reset All Stats",     _statsPath, self._ResetRangeStats, self, _unitName)
        -- F10/On the Range/My Settings/Smoke Color/
        missionCommands.addCommandForGroup(_gid, "Blue Smoke",          _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.Blue)
        missionCommands.addCommandForGroup(_gid, "Green Smoke",         _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.Green)
        missionCommands.addCommandForGroup(_gid, "Orange Smoke",        _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.Orange)
        missionCommands.addCommandForGroup(_gid, "Red Smoke",           _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.Red)
        missionCommands.addCommandForGroup(_gid, "White Smoke",         _mysmokePath, self._playersmokecolor, self, _unitName, SMOKECOLOR.White)
        -- F10/On the Range/My Settings/Flare Color/
        missionCommands.addCommandForGroup(_gid, "Green Flares",        _myflarePath, self._playerflarecolor, self, _unitName, FLARECOLOR.Green)
        missionCommands.addCommandForGroup(_gid, "Red Flares",          _myflarePath, self._playerflarecolor, self, _unitName, FLARECOLOR.Red)
        missionCommands.addCommandForGroup(_gid, "White Flares",        _myflarePath, self._playerflarecolor, self, _unitName, FLARECOLOR.White)
        missionCommands.addCommandForGroup(_gid, "Yellow Flares",       _myflarePath, self._playerflarecolor, self, _unitName, FLARECOLOR.Yellow)
        -- F10/On the Range/My Settings/
        missionCommands.addCommandForGroup(_gid, "Smoke Delay On/Off",  _settingsPath, self._SmokeBombDelayOnOff, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Smoke Impact On/Off",  _settingsPath, self._SmokeBombImpactOnOff, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Flare Hits On/Off",    _settingsPath, self._FlareDirectHitsOnOff, self, _unitName)        
        -- F10/On the Range/
        missionCommands.addCommandForGroup(_gid, "Range Information",   _rangePath, self._DisplayRangeInfo, self, _unitName)
        missionCommands.addCommandForGroup(_gid, "Weather Report",      _rangePath, self._DisplayRangeWeather, self, _unitName)
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

--- Mark targets on F10 map.
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
function RANGE:_MarkTargetsOnMap(_unitName)
  self:F(_unitName)

  -- Get group.
  local group=UNIT:FindByName(_unitName):GetGroup()

  if group then
  
    -- Mark bomb targets.
    for _,_target in pairs(self.bombingTargets) do
      local coord=_target.point --Core.Point#COORDINATE
      coord:MarkToGroup("Bomb target ".._target.name, group)
    end
    
    -- Mark strafe targets.
    for _,_strafepit in pairs(self.strafeTargets) do
      for _,_target in pairs(_strafepit.targets) do
        local coord=_target:GetCoordinate() --Core.Point#COORDINATE
        coord:MarkToGroup("Strafe target ".._target:GetName(), group)
      end
    end
    
    if _unitName then
      local _unit, _playername = self:_GetPlayerUnitAndName(_unitName)
      local text=string.format("%s, %s, range targets are now marked on F10 map.", self.rangename, _playername)
      self:_DisplayMessageToGroup(_unit, text, 5)
    end
    
  end
end

--- Illuminate targets. Fires illumination bombs at one random bomb and one random strafe target at a random altitude between 400 and 800 m.
-- @param #RANGE self
-- @param #string _unitName (Optional) Name of the player unit.
function RANGE:_IlluminateBombTargets(_unitName)
  self:F(_unitName)

  -- All bombing target coordinates.
  local bomb={}

  for _,_target in pairs(self.bombingTargets) do
    local coord=_target.point --Core.Point#COORDINATE
    table.insert(bomb, coord)
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
      local coord=_target:GetCoordinate() --Core.Point#COORDINATE
      table.insert(strafe, coord)
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
  
  if _gid then
    if _clear == true then
      trigger.action.outTextForGroup(_gid, _text, _time, _clear)
    else
      trigger.action.outTextForGroup(_gid, _text, _time)
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
  
  for _,_target in pairs(self.bombingTargets) do
    local coord = _target.point --Core.Point#COORDINATE
    coord:Smoke(self.BombSmokeColor)
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
    for _,_unit in pairs(_target.targets) do
      local coord = _unit:GetCoordinate() --Core.Point#COORDINATE
      coord:Smoke(self.StrafeSmokeColor)
    end
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

--- Returns the unit of a player and the player name. If the unit does not belong to a player, nil is returned. 
-- @param #RANGE self
-- @param #string _unitName Name of the player unit.
-- @return Wrapper.Unit#UNIT Unit of player.
-- @return #string Name of the player.
-- @return nil If player does not exist.
function RANGE:_GetPlayerUnitAndName(_unitName)
  self:F(_unitName)

  if _unitName ~= nil then
    local DCSunit=Unit.getByName(_unitName)
    local playername=DCSunit:getPlayerName()
    local unit=UNIT:Find(DCSunit)
    
    self:T({DCSunit=DCSunit, unit=unit, playername=playername})
    if DCSunit and unit and playername then
      return unit, playername
    end
  end
    
  return nil,nil
end

--- Returns a string which consits of this callsign and the player name.  
-- @param #RANGE self
-- @param #string unitname Name of the player unit.
function RANGE:_myname(unitname)
  self:F(unitname)
  
  local unit=UNIT:FindByName(unitname)
  local pname=unit:GetPlayerName()
  local csign=unit:GetCallsign()
  
  return string.format("%s (%s)", csign, pname)
end

--- http://stackoverflow.com/questions/1426954/split-string-in-lua
-- @param #RANGE self
-- @param #string str Sting to split.
-- @param #string sep Speparator for split.
-- @return #table Split text.
function RANGE:_split(str, sep)
  self:F({str=str, sep=sep})
  
  local result = {}
  local regex = ("([^%s]+)"):format(sep)
  for each in str:gmatch(regex) do
      table.insert(result, each)
  end
  
  return result
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
