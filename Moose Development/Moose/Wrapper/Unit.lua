--- **Wrapper** - UNIT is a wrapper class for the DCS Class Unit.
-- 
-- ===
-- 
-- The @{#UNIT} class is a wrapper class to handle the DCS Unit objects:
-- 
--  * Support all DCS Unit APIs.
--  * Enhance with Unit specific APIs not in the DCS Unit API set.
--  * Handle local Unit Controller.
--  * Manage the "state" of the DCS Unit.
--  
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Wrapper.Unit
-- @image Wrapper_Unit.JPG


--- @type UNIT
-- @extends Wrapper.Controllable#CONTROLLABLE

--- For each DCS Unit object alive within a running mission, a UNIT wrapper object (instance) will be created within the _@{DATABASE} object.
-- This is done at the beginning of the mission (when the mission starts), and dynamically when new DCS Unit objects are spawned (using the @{SPAWN} class).
--  
-- The UNIT class **does not contain a :New()** method, rather it provides **:Find()** methods to retrieve the object reference
-- using the DCS Unit or the DCS UnitName.
-- 
-- Another thing to know is that UNIT objects do not "contain" the DCS Unit object. 
-- The UNIT methods will reference the DCS Unit object by name when it is needed during API execution.
-- If the DCS Unit object does not exist or is nil, the UNIT methods will return nil and log an exception in the DCS.log file.
--  
-- The UNIT class provides the following functions to retrieve quickly the relevant UNIT instance:
-- 
--  * @{#UNIT.Find}(): Find a UNIT instance from the _DATABASE object using a DCS Unit object.
--  * @{#UNIT.FindByName}(): Find a UNIT instance from the _DATABASE object using a DCS Unit name.
--  
-- IMPORTANT: ONE SHOULD NEVER SANATIZE these UNIT OBJECT REFERENCES! (make the UNIT object references nil).
-- 
-- ## DCS UNIT APIs
-- 
-- The DCS Unit APIs are used extensively within MOOSE. The UNIT class has for each DCS Unit API a corresponding method.
-- To be able to distinguish easily in your code the difference between a UNIT API call and a DCS Unit API call,
-- the first letter of the method is also capitalized. So, by example, the DCS Unit method @{DCS#Unit.getName}()
-- is implemented in the UNIT class as @{#UNIT.GetName}().
-- 
-- ## Smoke, Flare Units
-- 
-- The UNIT class provides methods to smoke or flare units easily. 
-- The @{#UNIT.SmokeBlue}(), @{#UNIT.SmokeGreen}(),@{#UNIT.SmokeOrange}(), @{#UNIT.SmokeRed}(), @{#UNIT.SmokeRed}() methods
-- will smoke the unit in the corresponding color. Note that smoking a unit is done at the current position of the DCS Unit. 
-- When the DCS Unit moves for whatever reason, the smoking will still continue!
-- The @{#UNIT.FlareGreen}(), @{#UNIT.FlareRed}(), @{#UNIT.FlareWhite}(), @{#UNIT.FlareYellow}() 
-- methods will fire off a flare in the air with the corresponding color. Note that a flare is a one-off shot and its effect is of very short duration.
-- 
-- ## Location Position, Point
-- 
-- The UNIT class provides methods to obtain the current point or position of the DCS Unit.
-- The @{#UNIT.GetPointVec2}(), @{#UNIT.GetVec3}() will obtain the current **location** of the DCS Unit in a Vec2 (2D) or a **point** in a Vec3 (3D) vector respectively.
-- If you want to obtain the complete **3D position** including ori�ntation and direction vectors, consult the @{#UNIT.GetPositionVec3}() method respectively.
-- 
-- ## Test if alive
-- 
-- The @{#UNIT.IsAlive}(), @{#UNIT.IsActive}() methods determines if the DCS Unit is alive, meaning, it is existing and active.
-- 
-- ## Test for proximity
-- 
-- The UNIT class contains methods to test the location or proximity against zones or other objects.
-- 
-- ### Zones range
-- 
-- To test whether the Unit is within a **zone**, use the @{#UNIT.IsInZone}() or the @{#UNIT.IsNotInZone}() methods. Any zone can be tested on, but the zone must be derived from @{Core.Zone#ZONE_BASE}. 
-- 
-- ### Unit range
-- 
--   * Test if another DCS Unit is within a given radius of the current DCS Unit, use the @{#UNIT.OtherUnitInRadius}() method.
--   
-- ## Test Line of Sight
-- 
--   * Use the @{#UNIT.IsLOS}() method to check if the given unit is within line of sight.
-- 
-- 
-- @field #UNIT UNIT
UNIT = {
	ClassName="UNIT",
}


--- Unit.SensorType
-- @type Unit.SensorType
-- @field OPTIC
-- @field RADAR
-- @field IRST
-- @field RWR


-- Registration.
	
--- Create a new UNIT from DCSUnit.
-- @param #UNIT self
-- @param #string UnitName The name of the DCS unit.
-- @return #UNIT
function UNIT:Register( UnitName )
  local self = BASE:Inherit( self, CONTROLLABLE:New( UnitName ) )
  self.UnitName = UnitName
  
  self:SetEventPriority( 3 )
  return self
end

-- Reference methods.

--- Finds a UNIT from the _DATABASE using a DCSUnit object.
-- @param #UNIT self
-- @param DCS#Unit DCSUnit An existing DCS Unit object reference.
-- @return #UNIT self
function UNIT:Find( DCSUnit )
  if DCSUnit then
    local UnitName = DCSUnit:getName()
    local UnitFound = _DATABASE:FindUnit( UnitName )
    return UnitFound
  end
  return nil
end

--- Find a UNIT in the _DATABASE using the name of an existing DCS Unit.
-- @param #UNIT self
-- @param #string UnitName The Unit Name.
-- @return #UNIT self
function UNIT:FindByName( UnitName )
  
  local UnitFound = _DATABASE:FindUnit( UnitName )
  return UnitFound
end

--- Return the name of the UNIT.
-- @param #UNIT self
-- @return #string The UNIT name.
function UNIT:Name()
  
  return self.UnitName
end


--- @param #UNIT self
-- @return DCS#Unit
function UNIT:GetDCSObject()

  local DCSUnit = Unit.getByName( self.UnitName )

  if DCSUnit then
    return DCSUnit
  end

  return nil
end




--- Respawn the @{Wrapper.Unit} using a (tweaked) template of the parent Group.
-- 
-- This function will:
-- 
--  * Get the current position and heading of the group.
--  * When the unit is alive, it will tweak the template x, y and heading coordinates of the group and the embedded units to the current units positions.
--  * Then it will respawn the re-modelled group.
--  
-- @param #UNIT self
-- @param Core.Point#COORDINATE Coordinate The position where to Spawn the new Unit at.
-- @param #number Heading The heading of the unit respawn.
function UNIT:ReSpawnAt( Coordinate, Heading )

  self:T( self:Name() )
  local SpawnGroupTemplate = UTILS.DeepCopy( _DATABASE:GetGroupTemplateFromUnitName( self:Name() ) )
  self:T( SpawnGroupTemplate )

  local SpawnGroup = self:GetGroup()
  self:T( { SpawnGroup = SpawnGroup } )
  
  if SpawnGroup then
  
    local Vec3 = SpawnGroup:GetVec3()
    SpawnGroupTemplate.x = Coordinate.x
    SpawnGroupTemplate.y = Coordinate.z
    
    self:F( #SpawnGroupTemplate.units )
    for UnitID, UnitData in pairs( SpawnGroup:GetUnits() ) do
      local GroupUnit = UnitData -- #UNIT
      self:F( GroupUnit:GetName() )
      if GroupUnit:IsAlive() then
        local GroupUnitVec3 = GroupUnit:GetVec3()
        local GroupUnitHeading = GroupUnit:GetHeading()
        SpawnGroupTemplate.units[UnitID].alt = GroupUnitVec3.y
        SpawnGroupTemplate.units[UnitID].x = GroupUnitVec3.x
        SpawnGroupTemplate.units[UnitID].y = GroupUnitVec3.z
        SpawnGroupTemplate.units[UnitID].heading = GroupUnitHeading
        self:F( { UnitID, SpawnGroupTemplate.units[UnitID], SpawnGroupTemplate.units[UnitID] } )
      end
    end
  end
  
  for UnitTemplateID, UnitTemplateData in pairs( SpawnGroupTemplate.units ) do
    self:T( { UnitTemplateData.name, self:Name() } )
    SpawnGroupTemplate.units[UnitTemplateID].unitId = nil
    if UnitTemplateData.name == self:Name() then
      self:T("Adjusting")
      SpawnGroupTemplate.units[UnitTemplateID].alt = Coordinate.y
      SpawnGroupTemplate.units[UnitTemplateID].x = Coordinate.x
      SpawnGroupTemplate.units[UnitTemplateID].y = Coordinate.z
      SpawnGroupTemplate.units[UnitTemplateID].heading = Heading
      self:F( { UnitTemplateID, SpawnGroupTemplate.units[UnitTemplateID], SpawnGroupTemplate.units[UnitTemplateID] } )
    else
      self:F( SpawnGroupTemplate.units[UnitTemplateID].name )
      local GroupUnit = UNIT:FindByName( SpawnGroupTemplate.units[UnitTemplateID].name ) -- #UNIT
      if GroupUnit and GroupUnit:IsAlive() then
        local GroupUnitVec3 = GroupUnit:GetVec3()
        local GroupUnitHeading = GroupUnit:GetHeading()
        UnitTemplateData.alt = GroupUnitVec3.y
        UnitTemplateData.x = GroupUnitVec3.x
        UnitTemplateData.y = GroupUnitVec3.z
        UnitTemplateData.heading = GroupUnitHeading
      else
        if SpawnGroupTemplate.units[UnitTemplateID].name ~= self:Name() then
          self:T("nilling")
          SpawnGroupTemplate.units[UnitTemplateID].delete = true
        end
      end
    end
  end

  -- Remove obscolete units from the group structure
  local i = 1
  while i <= #SpawnGroupTemplate.units do

    local UnitTemplateData = SpawnGroupTemplate.units[i]
    self:T( UnitTemplateData.name )

    if UnitTemplateData.delete then
      table.remove( SpawnGroupTemplate.units, i )
    else
      i = i + 1
    end
  end
  
  SpawnGroupTemplate.groupId = nil
  
  self:T( SpawnGroupTemplate )

  _DATABASE:Spawn( SpawnGroupTemplate )
end



--- Returns if the unit is activated.
-- @param #UNIT self
-- @return #boolean true if Unit is activated.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:IsActive()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
  
    local UnitIsActive = DCSUnit:isActive()
    return UnitIsActive 
  end

  return nil
end

--- Returns if the Unit is alive.  
-- If the Unit is not alive, nil is returned.  
-- If the Unit is alive and active, true is returned.    
-- If the Unit is alive but not active, false is returned.  
-- @param #UNIT self
-- @return #boolean true if Unit is alive and active.
-- @return #boolean false if Unit is alive but not active.
-- @return #nil if the Unit is not existing or is not alive.  
function UNIT:IsAlive()
  self:F3( self.UnitName )

  local DCSUnit = self:GetDCSObject() -- DCS#Unit
  
  if DCSUnit then
    local UnitIsAlive  = DCSUnit:isExist() and DCSUnit:isActive()
    return UnitIsAlive
  end 
  
  return nil
end



--- Returns the Unit's callsign - the localized string.
-- @param #UNIT self
-- @return #string The Callsign of the Unit.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetCallsign()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitCallSign = DCSUnit:getCallsign()
    if UnitCallSign == "" then
      UnitCallSign = DCSUnit:getName()
    end
    return UnitCallSign
  end
  
  self:F( self.ClassName .. " " .. self.UnitName .. " not found!" )
  return nil
end


--- Returns name of the player that control the unit or nil if the unit is controlled by A.I.
-- @param #UNIT self
-- @return #string Player Name
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetPlayerName()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject() -- DCS#Unit
  
  if DCSUnit then
  
    local PlayerName = DCSUnit:getPlayerName()
    -- TODO Workaround DCS-BUG-3 - https://github.com/FlightControl-Master/MOOSE/issues/696
--    if PlayerName == nil or PlayerName == "" then
--      local PlayerCategory = DCSUnit:getDesc().category
--      if PlayerCategory == Unit.Category.GROUND_UNIT or PlayerCategory == Unit.Category.SHIP then
--        PlayerName = "Player" .. DCSUnit:getID()
--      end
--    end
--    -- Good code
--    if PlayerName == nil then 
--      PlayerName = nil
--    else
--      if PlayerName == "" then
--        PlayerName = "Player" .. DCSUnit:getID()
--      end
--    end
    return PlayerName
  end

  return nil

end

--- Returns the unit's number in the group. 
-- The number is the same number the unit has in ME. 
-- It may not be changed during the mission. 
-- If any unit in the group is destroyed, the numbers of another units will not be changed.
-- @param #UNIT self
-- @return #number The Unit number. 
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetNumber()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitNumber = DCSUnit:getNumber()
    return UnitNumber
  end

  return nil
end


--- Returns the unit's max speed in km/h derived from the DCS descriptors.
-- @param #UNIT self
-- @return #number Speed in km/h. 
function UNIT:GetSpeedMax()
  self:F2( self.UnitName )

  local Desc = self:GetDesc()
  
  if Desc then
    local SpeedMax = Desc.speedMax
    return SpeedMax*3.6
  end

  return nil
end

--- Returns the unit's max range in meters derived from the DCS descriptors.
-- For ground units it will return a range of 10,000 km as they have no real range.
-- @param #UNIT self
-- @return #number Range in meters.
function UNIT:GetRange()
  self:F2( self.UnitName )

  local Desc = self:GetDesc()
  
  if Desc then
    local Range = Desc.range --This is in nautical miles for some reason. But should check again!
    if Range then
      Range=UTILS.NMToMeters(Range)
    else
      Range=10000000 --10.000 km if no range
    end
    return Range
  end

  return nil
end

--- Returns the unit's group if it exist and nil otherwise.
-- @param Wrapper.Unit#UNIT self
-- @return Wrapper.Group#GROUP The Group of the Unit.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetGroup()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitGroup = GROUP:FindByName( DCSUnit:getGroup():getName() )
    return UnitGroup
  end

  return nil
end


-- Need to add here functions to check if radar is on and which object etc.

--- Returns the prefix name of the DCS Unit. A prefix name is a part of the name before a '#'-sign.
-- DCS Units spawned with the @{SPAWN} class contain a '#'-sign to indicate the end of the (base) DCS Unit name. 
-- The spawn sequence number and unit number are contained within the name after the '#' sign. 
-- @param #UNIT self
-- @return #string The name of the DCS Unit.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetPrefix()
	self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject()
	
  if DCSUnit then
  	local UnitPrefix = string.match( self.UnitName, ".*#" ):sub( 1, -2 )
  	self:T3( UnitPrefix )
  	return UnitPrefix
  end
  
  return nil
end

--- Returns the Unit's ammunition.
-- @param #UNIT self
-- @return DCS#Unit.Ammo
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetAmmo()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitAmmo = DCSUnit:getAmmo()
    return UnitAmmo
  end
  
  return nil
end

--- Returns the unit sensors.
-- @param #UNIT self
-- @return DCS#Unit.Sensors
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetSensors()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitSensors = DCSUnit:getSensors()
    return UnitSensors
  end
  
  return nil
end

-- Need to add here a function per sensortype
--  unit:hasSensors(Unit.SensorType.RADAR, Unit.RadarType.AS)

--- Returns if the unit has sensors of a certain type.
-- @param #UNIT self
-- @return #boolean returns true if the unit has specified types of sensors. This function is more preferable than Unit.getSensors() if you don't want to get information about all the unit's sensors, and just want to check if the unit has specified types of sensors. 
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:HasSensors( ... )
  self:F2( arg )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local HasSensors = DCSUnit:hasSensors( unpack( arg ) )
    return HasSensors
  end
  
  return nil
end

--- Returns if the unit is SEADable.
-- @param #UNIT self
-- @return #boolean returns true if the unit is SEADable. 
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:HasSEAD()
  self:F2()

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitSEADAttributes = DCSUnit:getDesc().attributes
    
    local HasSEAD = false
    if UnitSEADAttributes["RADAR_BAND1_FOR_ARM"] and UnitSEADAttributes["RADAR_BAND1_FOR_ARM"] == true or
       UnitSEADAttributes["RADAR_BAND2_FOR_ARM"] and UnitSEADAttributes["RADAR_BAND2_FOR_ARM"] == true then
       HasSEAD = true
    end
    return HasSEAD
  end
  
  return nil
end

--- Returns two values:
-- 
--  * First value indicates if at least one of the unit's radar(s) is on.
--  * Second value is the object of the radar's interest. Not nil only if at least one radar of the unit is tracking a target.
-- @param #UNIT self
-- @return #boolean  Indicates if at least one of the unit's radar(s) is on.
-- @return DCS#Object The object of the radar's interest. Not nil only if at least one radar of the unit is tracking a target.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetRadar()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitRadarOn, UnitRadarObject = DCSUnit:getRadar()
    return UnitRadarOn, UnitRadarObject
  end
  
  return nil, nil
end

--- Returns relative amount of fuel (from 0.0 to 1.0) the UNIT has in its internal tanks. If there are additional fuel tanks the value may be greater than 1.0.
-- @param #UNIT self
-- @return #number The relative amount of fuel (from 0.0 to 1.0).
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetFuel()
  self:F( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitFuel = DCSUnit:getFuel()
    return UnitFuel
  end
  
  return nil
end

--- Returns a list of one @{Wrapper.Unit}.
-- @param #UNIT self
-- @return #list<Wrapper.Unit#UNIT> A list of one @{Wrapper.Unit}.
function UNIT:GetUnits()
  self:F2( { self.UnitName } )
  local DCSUnit = self:GetDCSObject()

  local Units = {}
  
  if DCSUnit then
    Units[1] = UNIT:Find( DCSUnit )
    self:T3( Units )
    return Units
  end

  return nil
end


--- Returns the unit's health. Dead units has health <= 1.0.
-- @param #UNIT self
-- @return #number The Unit's health value.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetLife()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitLife = DCSUnit:getLife()
    return UnitLife
  end
  
  return -1
end

--- Returns the Unit's initial health.
-- @param #UNIT self
-- @return #number The Unit's initial health value.
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetLife0()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitLife0 = DCSUnit:getLife0()
    return UnitLife0
  end
  
  return 0
end

--- Returns the category name of the #UNIT.
-- @param #UNIT self
-- @return #string Category name = Helicopter, Airplane, Ground Unit, Ship
function UNIT:GetCategoryName()
  self:F3( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  if DCSUnit then
    local CategoryNames = {
      [Unit.Category.AIRPLANE] = "Airplane",
      [Unit.Category.HELICOPTER] = "Helicopter",
      [Unit.Category.GROUND_UNIT] = "Ground Unit",
      [Unit.Category.SHIP] = "Ship",
      [Unit.Category.STRUCTURE] = "Structure",
    }
    local UnitCategory = DCSUnit:getDesc().category
    self:T3( UnitCategory )

    return CategoryNames[UnitCategory]
  end

  return nil
end


--- Returns the Unit's A2G threat level on a scale from 1 to 10 ...
-- The following threat levels are foreseen:
-- 
--   * Threat level  0: Unit is unarmed.
--   * Threat level  1: Unit is infantry.
--   * Threat level  2: Unit is an infantry vehicle.
--   * Threat level  3: Unit is ground artillery.
--   * Threat level  4: Unit is a tank.
--   * Threat level  5: Unit is a modern tank or ifv with ATGM.
--   * Threat level  6: Unit is a AAA.
--   * Threat level  7: Unit is a SAM or manpad, IR guided.
--   * Threat level  8: Unit is a Short Range SAM, radar guided.
--   * Threat level  9: Unit is a Medium Range SAM, radar guided.
--   * Threat level 10: Unit is a Long Range SAM, radar guided.
--   @param #UNIT self
function UNIT:GetThreatLevel()


  local ThreatLevel = 0
  local ThreatText = ""

  local Descriptor = self:GetDesc()
  
  if Descriptor then 
  
    local Attributes = Descriptor.attributes
  
    if self:IsGround() then
    
      local ThreatLevels = {
        "Unarmed", 
        "Infantry", 
        "Old Tanks & APCs", 
        "Tanks & IFVs without ATGM",   
        "Tanks & IFV with ATGM",
        "Modern Tanks",
        "AAA",
        "IR Guided SAMs",
        "SR SAMs",
        "MR SAMs",
        "LR SAMs"
      }
      
      
      if     Attributes["LR SAM"]                                                     then ThreatLevel = 10
      elseif Attributes["MR SAM"]                                                     then ThreatLevel = 9
      elseif Attributes["SR SAM"] and
             not Attributes["IR Guided SAM"]                                          then ThreatLevel = 8
      elseif ( Attributes["SR SAM"] or Attributes["MANPADS"] ) and
             Attributes["IR Guided SAM"]                                              then ThreatLevel = 7
      elseif Attributes["AAA"]                                                        then ThreatLevel = 6
      elseif Attributes["Modern Tanks"]                                               then ThreatLevel = 5
      elseif ( Attributes["Tanks"] or Attributes["IFV"] ) and
             Attributes["ATGM"]                                                       then ThreatLevel = 4
      elseif ( Attributes["Tanks"] or Attributes["IFV"] ) and
             not Attributes["ATGM"]                                                   then ThreatLevel = 3
      elseif Attributes["Old Tanks"] or Attributes["APC"] or Attributes["Artillery"]  then ThreatLevel = 2
      elseif Attributes["Infantry"]                                                   then ThreatLevel = 1
      end
      
      ThreatText = ThreatLevels[ThreatLevel+1]
    end
    
    if self:IsAir() then
    
      local ThreatLevels = {
        "Unarmed", 
        "Tanker", 
        "AWACS", 
        "Transport Helicopter",   
        "UAV",
        "Bomber",
        "Strategic Bomber",
        "Attack Helicopter",
        "Battleplane",
        "Multirole Fighter",
        "Fighter"
      }
      
      
      if     Attributes["Fighters"]                                 then ThreatLevel = 10
      elseif Attributes["Multirole fighters"]                       then ThreatLevel = 9
      elseif Attributes["Battleplanes"]                             then ThreatLevel = 8
      elseif Attributes["Attack helicopters"]                       then ThreatLevel = 7
      elseif Attributes["Strategic bombers"]                        then ThreatLevel = 6
      elseif Attributes["Bombers"]                                  then ThreatLevel = 5
      elseif Attributes["UAVs"]                                     then ThreatLevel = 4
      elseif Attributes["Transport helicopters"]                    then ThreatLevel = 3
      elseif Attributes["AWACS"]                                    then ThreatLevel = 2
      elseif Attributes["Tankers"]                                  then ThreatLevel = 1
      end
  
      ThreatText = ThreatLevels[ThreatLevel+1]
    end
    
    if self:IsShip() then
  
  --["Aircraft Carriers"] = {"Heavy armed ships",},
  --["Cruisers"] = {"Heavy armed ships",},
  --["Destroyers"] = {"Heavy armed ships",},
  --["Frigates"] = {"Heavy armed ships",},
  --["Corvettes"] = {"Heavy armed ships",},
  --["Heavy armed ships"] = {"Armed ships", "Armed Air Defence", "HeavyArmoredUnits",},
  --["Light armed ships"] = {"Armed ships","NonArmoredUnits"},
  --["Armed ships"] = {"Ships"},
  --["Unarmed ships"] = {"Ships","HeavyArmoredUnits",},
    
      local ThreatLevels = {
        "Unarmed ship", 
        "Light armed ships", 
        "Corvettes",
        "",
        "Frigates",
        "",
        "Cruiser",
        "",
        "Destroyer",
        "",
        "Aircraft Carrier"
      }
      
      
      if     Attributes["Aircraft Carriers"]                        then ThreatLevel = 10
      elseif Attributes["Destroyers"]                               then ThreatLevel = 8
      elseif Attributes["Cruisers"]                                 then ThreatLevel = 6
      elseif Attributes["Frigates"]                                 then ThreatLevel = 4
      elseif Attributes["Corvettes"]                                then ThreatLevel = 2
      elseif Attributes["Light armed ships"]                        then ThreatLevel = 1
      end
  
      ThreatText = ThreatLevels[ThreatLevel+1]
    end
  end

  return ThreatLevel, ThreatText

end


-- Is functions

--- Returns true if the unit is within a @{Zone}.
-- @param #UNIT self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the unit is within the @{Core.Zone#ZONE_BASE}
function UNIT:IsInZone( Zone )
  self:F2( { self.UnitName, Zone } )

  if self:IsAlive() then
    local IsInZone = Zone:IsVec3InZone( self:GetVec3() )
  
    return IsInZone 
  end
  return false
end

--- Returns true if the unit is not within a @{Zone}.
-- @param #UNIT self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the unit is not within the @{Core.Zone#ZONE_BASE}
function UNIT:IsNotInZone( Zone )
  self:F2( { self.UnitName, Zone } )

  if self:IsAlive() then
    local IsInZone = not Zone:IsVec3InZone( self:GetVec3() )
    
    self:T( { IsInZone } )
    return IsInZone 
  else
    return false
  end
end


--- Returns true if there is an **other** DCS Unit within a radius of the current 2D point of the DCS Unit.
-- @param #UNIT self
-- @param #UNIT AwaitUnit The other UNIT wrapper object.
-- @param Radius The radius in meters with the DCS Unit in the centre.
-- @return true If the other DCS Unit is within the radius of the 2D point of the DCS Unit. 
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:OtherUnitInRadius( AwaitUnit, Radius )
	self:F2( { self.UnitName, AwaitUnit.UnitName, Radius } )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
  	local UnitVec3 = self:GetVec3()
  	local AwaitUnitVec3 = AwaitUnit:GetVec3()
  
  	if  (((UnitVec3.x - AwaitUnitVec3.x)^2 + (UnitVec3.z - AwaitUnitVec3.z)^2)^0.5 <= Radius) then
  		self:T3( "true" )
  		return true
  	else
  		self:T3( "false" )
  		return false
  	end
  end

	return nil
end







--- Returns if the unit is a friendly unit.
-- @param #UNIT self
-- @return #boolean IsFriendly evaluation result.
function UNIT:IsFriendly( FriendlyCoalition )
  self:F2()
  
  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitCoalition = DCSUnit:getCoalition()
    self:T3( { UnitCoalition, FriendlyCoalition } )
    
    local IsFriendlyResult = ( UnitCoalition == FriendlyCoalition )
  
    self:F( IsFriendlyResult )
    return IsFriendlyResult
  end
  
  return nil
end

--- Returns if the unit is of a ship category.
-- If the unit is a ship, this method will return true, otherwise false.
-- @param #UNIT self
-- @return #boolean Ship category evaluation result.
function UNIT:IsShip()
  self:F2()
  
  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitDescriptor = DCSUnit:getDesc()
    self:T3( { UnitDescriptor.category, Unit.Category.SHIP } )
    
    local IsShipResult = ( UnitDescriptor.category == Unit.Category.SHIP )
  
    self:T3( IsShipResult )
    return IsShipResult
  end
  
  return nil
end

--- Returns true if the UNIT is in the air.
-- @param #UNIT self
-- @return #boolean true if in the air.
-- @return #nil The UNIT is not existing or alive.  
function UNIT:InAir()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject() --DCS#Unit
  
  if DCSUnit then
--    Implementation of workaround. The original code is below.
--    This to simulate the landing on buildings.

    local UnitInAir = true

    local UnitCategory = DCSUnit:getDesc().category
    if UnitCategory == Unit.Category.HELICOPTER then
      local VelocityVec3 = DCSUnit:getVelocity()
      local Velocity = ( VelocityVec3.x ^ 2 + VelocityVec3.y ^ 2 + VelocityVec3.z ^ 2 ) ^ 0.5 -- in meters / sec
      local Coordinate = DCSUnit:getPoint()
      local LandHeight = land.getHeight( { x = Coordinate.x, y = Coordinate.z } )
      local Height = Coordinate.y - LandHeight
      if Velocity < 1 and Height <= 60   then
        UnitInAir = false
      end
    else
      UnitInAir = DCSUnit:inAir()
    end


    self:T3( UnitInAir )
    return UnitInAir
  end
  
  return nil
end

do -- Event Handling

  --- Subscribe to a DCS Event.
  -- @param #UNIT self
  -- @param Core.Event#EVENTS Event
  -- @param #function EventFunction (optional) The function to be called when the event occurs for the unit.
  -- @return #UNIT
  function UNIT:HandleEvent( Event, EventFunction )
  
    self:EventDispatcher():OnEventForUnit( self:GetName(), EventFunction, self, Event )
    
    return self
  end
  
  --- UnSubscribe to a DCS event.
  -- @param #UNIT self
  -- @param Core.Event#EVENTS Event
  -- @return #UNIT
  function UNIT:UnHandleEvent( Event )
  
    self:EventDispatcher():RemoveForUnit( self:GetName(), self, Event )
    
    return self
  end
  
  --- Reset the subscriptions.
  -- @param #UNIT self
  -- @return #UNIT
  function UNIT:ResetEvents()
  
    self:EventDispatcher():Reset( self )
    
    return self
  end

end

do -- Detection

  --- Returns if a unit is detecting the TargetUnit.
  -- @param #UNIT self
  -- @param #UNIT TargetUnit
  -- @return #boolean true If the TargetUnit is detected by the unit, otherwise false.
  function UNIT:IsDetected( TargetUnit ) --R2.1

    local TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity = self:IsTargetDetected( TargetUnit:GetDCSObject() )  
    
    return TargetIsDetected
  end
  
  --- Returns if a unit has Line of Sight (LOS) with the TargetUnit.
  -- @param #UNIT self
  -- @param #UNIT TargetUnit
  -- @return #boolean true If the TargetUnit has LOS with the unit, otherwise false.
  function UNIT:IsLOS( TargetUnit ) --R2.1

    local IsLOS = self:GetPointVec3():IsLOS( TargetUnit:GetPointVec3() )

    return IsLOS
  end
  

end