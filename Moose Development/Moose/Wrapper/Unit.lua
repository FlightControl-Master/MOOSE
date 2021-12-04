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
-- ### Contributions: **funkyfranky**
-- 
-- ===
-- 
-- @module Wrapper.Unit
-- @image Wrapper_Unit.JPG


--- @type UNIT
-- @field #string ClassName Name of the class.
-- @field #string UnitName Name of the unit.
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
-- If you want to obtain the complete **3D position** including orientation and direction vectors, consult the @{#UNIT.GetPositionVec3}() method respectively.
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
	UnitName=nil,
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
-- @return #UNIT self
function UNIT:Register( UnitName )

  -- Inherit CONTROLLABLE.
  local self = BASE:Inherit( self, CONTROLLABLE:New( UnitName ) )
  
  -- Set unit name.
  self.UnitName = UnitName
  
  -- Set event prio.
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

--- Get the DCS unit object.
-- @param #UNIT self
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
-- @return #boolean `true` if Unit is activated. `nil` The DCS Unit is not existing or alive.  
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
-- @return #boolean `true` if Unit is alive and active. `false` if Unit is alive but not active. `nil` if the Unit is not existing or is not alive.
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

--- Check if an (air) unit is a client or player slot. Information is retrieved from the group template.
-- @param #UNIT self
-- @return #boolean If true, unit is associated with a client or player slot.
function UNIT:IsPlayer()
  
  -- Get group.
  local group=self:GetGroup()
    
  -- Units of template group.
  local units=group:GetTemplate().units
  
  -- Get numbers.
  for _,unit in pairs(units) do
      
    -- Check if unit name matach and skill is Client or Player.
    if unit.name==self:GetName() and (unit.skill=="Client" or unit.skill=="Player") then
      return true
    end

  end
  
  return false
end


--- Returns name of the player that control the unit or nil if the unit is controlled by A.I.
-- @param #UNIT self
-- @return #string Player Name
-- @return #nil The DCS Unit is not existing or alive.  
function UNIT:GetPlayerName()
  self:F( self.UnitName )

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

--- Checks is the unit is a *Player* or *Client* slot.  
-- @param #UNIT self
-- @return #boolean If true, unit is a player or client aircraft  
function UNIT:IsClient()

  if _DATABASE.CLIENTS[self.UnitName] then
    return true
  end

  return false
end

--- Get the CLIENT of the unit  
-- @param #UNIT self
-- @return Wrapper.Client#CLIENT  
function UNIT:GetClient()

  local client=_DATABASE.CLIENTS[self.UnitName]

  if client then
    return client
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

  return 0
end

--- Returns the unit's max range in meters derived from the DCS descriptors.
-- For ground units it will return a range of 10,000 km as they have no real range.
-- @param #UNIT self
-- @return #number Range in meters.
function UNIT:GetRange()
  self:F2( self.UnitName )

  local Desc = self:GetDesc()
  
  if Desc then
    local Range = Desc.range --This is in kilometers (not meters) for some reason. But should check again!
    if Range then
      Range=Range*1000 -- convert to meters.
    else
      Range=10000000 --10.000 km if no range
    end
    return Range
  end

  return nil
end

--- Check if the unit is refuelable. Also retrieves the refuelling system (boom or probe) if applicable.
-- @param #UNIT self
-- @return #boolean If true, unit is refuelable (checks for the attribute "Refuelable").
-- @return #number Refueling system (if any): 0=boom, 1=probe.
function UNIT:IsRefuelable()
  self:F2( self.UnitName )

  local refuelable=self:HasAttribute("Refuelable")
  
  local system=nil
  
  local Desc=self:GetDesc()
  if Desc and Desc.tankerType then
    system=Desc.tankerType
  end

  return refuelable, system
end

--- Check if the unit is a tanker. Also retrieves the refuelling system (boom or probe) if applicable.
-- @param #UNIT self
-- @return #boolean If true, unit is refuelable (checks for the attribute "Refuelable").
-- @return #number Refueling system (if any): 0=boom, 1=probe.
function UNIT:IsTanker()
  self:F2( self.UnitName )

  local tanker=self:HasAttribute("Tankers")
  
  local system=nil
  
  if tanker then
  
    local Desc=self:GetDesc()
    if Desc and Desc.tankerType then
      system=Desc.tankerType
    end
    
    local typename=self:GetTypeName()
    
    -- Some hard coded data as this is not in the descriptors...
    if typename=="IL-78M" then
      system=1 --probe
    elseif typename=="KC130" then
      system=1 --probe
    elseif typename=="KC135BDA" then
      system=1 --probe
    elseif typename=="KC135MPRS" then
      system=1 --probe
    elseif typename=="S-3B Tanker" then
      system=1 --probe
    end
    
  end

  return tanker, system
end


--- Returns the unit's group if it exist and nil otherwise.
-- @param Wrapper.Unit#UNIT self
-- @return Wrapper.Group#GROUP The Group of the Unit or `nil` if the unit does not exist.  
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
-- @return DCS#Unit.Ammo Table with ammuntion of the unit (or nil). This can be a complex table!  
function UNIT:GetAmmo()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitAmmo = DCSUnit:getAmmo()
    return UnitAmmo
  end
  
  return nil
end

--- Sets the Unit's Internal Cargo Mass, in kg
-- @param #UNIT self
-- @param #number mass to set cargo to
-- @return #UNIT self
function UNIT:SetUnitInternalCargo(mass)
  local DCSUnit = self:GetDCSObject()
  if DCSUnit then
    trigger.action.setUnitInternalCargo(DCSUnit:getName(), mass)
  end
  return self
end

--- Get the number of ammunition and in particular the number of shells, rockets, bombs and missiles a unit currently has.
-- @param #UNIT self
-- @return #number Total amount of ammo the unit has left. This is the sum of shells, rockets, bombs and missiles.
-- @return #number Number of shells left.
-- @return #number Number of rockets left.
-- @return #number Number of bombs left.
-- @return #number Number of missiles left.
function UNIT:GetAmmunition()

  -- Init counter.
  local nammo=0
  local nshells=0
  local nrockets=0
  local nmissiles=0
  local nbombs=0

  local unit=self

  -- Get ammo table.
  local ammotable=unit:GetAmmo()

  if ammotable then

    local weapons=#ammotable
    
    -- Loop over all weapons.
    for w=1,weapons do

      -- Number of current weapon.
      local Nammo=ammotable[w]["count"]

      -- Type name of current weapon.
      local Tammo=ammotable[w]["desc"]["typeName"]

      --local _weaponString = UTILS.Split(Tammo,"%.")
      --local _weaponName   = _weaponString[#_weaponString]

      -- Get the weapon category: shell=0, missile=1, rocket=2, bomb=3
      local Category=ammotable[w].desc.category

      -- Get missile category: Weapon.MissileCategory AAM=1, SAM=2, BM=3, ANTI_SHIP=4, CRUISE=5, OTHER=6
      local MissileCategory=nil
      if Category==Weapon.Category.MISSILE then
        MissileCategory=ammotable[w].desc.missileCategory
      end

      -- We are specifically looking for shells or rockets here.
      if Category==Weapon.Category.SHELL then

        -- Add up all shells.
        nshells=nshells+Nammo

      elseif Category==Weapon.Category.ROCKET then

        -- Add up all rockets.
        nrockets=nrockets+Nammo

      elseif Category==Weapon.Category.BOMB then

        -- Add up all rockets.
        nbombs=nbombs+Nammo
        
      elseif Category==Weapon.Category.MISSILE then
        
        
        -- Add up all  missiles (category 5)
        if MissileCategory==Weapon.MissileCategory.AAM then
          nmissiles=nmissiles+Nammo
        elseif MissileCategory==Weapon.MissileCategory.ANTI_SHIP then
          nmissiles=nmissiles+Nammo
        elseif MissileCategory==Weapon.MissileCategory.BM then
          nmissiles=nmissiles+Nammo
        elseif MissileCategory==Weapon.MissileCategory.OTHER then
          nmissiles=nmissiles+Nammo
        elseif MissileCategory==Weapon.MissileCategory.SAM then
          nmissiles=nmissiles+Nammo
        elseif MissileCategory==Weapon.MissileCategory.CRUISE then
          nmissiles=nmissiles+Nammo
        end

      end

    end
  end

  -- Total amount of ammunition.
  nammo=nshells+nrockets+nmissiles+nbombs

  return nammo, nshells, nrockets, nbombs, nmissiles
end



--- Returns the unit sensors.
-- @param #UNIT self
-- @return DCS#Unit.Sensors Table of sensors.  
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
-- @return #number The relative amount of fuel (from 0.0 to 1.0) or *nil* if the DCS Unit is not existing or alive. 
function UNIT:GetFuel()
  self:F3( self.UnitName )

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
  self:F3( { self.UnitName } )
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
-- @return #number The Unit's health value or -1 if unit does not exist any more.
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
-- @return #number The Unit's initial health value or 0 if unit does not exist any more.  
function UNIT:GetLife0()
  self:F2( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
    local UnitLife0 = DCSUnit:getLife0()
    return UnitLife0
  end
  
  return 0
end

--- Returns the unit's relative health.
-- @param #UNIT self
-- @return #number The Unit's relative health value, i.e. a number in [0,1] or -1 if unit does not exist any more.
function UNIT:GetLifeRelative()
  self:F2(self.UnitName)

  if self and self:IsAlive() then
    local life0=self:GetLife0()
    local lifeN=self:GetLife()
    return lifeN/life0
  end
  
  return -1
end

--- Returns the unit's relative damage, i.e. 1-life.
-- @param #UNIT self
-- @return #number The Unit's relative health value, i.e. a number in [0,1] or 1 if unit does not exist any more.
function UNIT:GetDamageRelative()
  self:F2(self.UnitName)

  if self and self:IsAlive() then
    return 1-self:GetLifeRelative()
  end
  
  return 1
end

--- Returns the category of the #UNIT from descriptor. Returns one of
-- 
-- * Unit.Category.AIRPLANE
-- * Unit.Category.HELICOPTER
-- * Unit.Category.GROUND_UNIT
-- * Unit.Category.SHIP
-- * Unit.Category.STRUCTURE
-- 
-- @param #UNIT self
-- @return #number Unit category from `getDesc().category`.
function UNIT:GetUnitCategory()
  self:F3( self.UnitName )

  local DCSUnit = self:GetDCSObject()
  if DCSUnit then
    return DCSUnit:getDesc().category    
  end
  
  return nil
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
-- Depending on the era and the type of unit, the following threat levels are foreseen:
-- 
-- **Modern**:
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
-- 
-- **Cold**:
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
--   * Threat level  10: Unit is a Medium Range SAM, radar guided.
--  
-- **Korea**:
-- 
--   * Threat level  0: Unit is unarmed.
--   * Threat level  1: Unit is infantry.
--   * Threat level  2: Unit is an infantry vehicle.
--   * Threat level  3: Unit is ground artillery.
--   * Threat level  5: Unit is a tank.
--   * Threat level  6: Unit is a AAA.
--   * Threat level  7: Unit is a SAM or manpad, IR guided.
--   * Threat level  10: Unit is a Short Range SAM, radar guided.
--  
-- **WWII**:
-- 
--   * Threat level  0: Unit is unarmed.
--   * Threat level  1: Unit is infantry.
--   * Threat level  2: Unit is an infantry vehicle.
--   * Threat level  3: Unit is ground artillery.
--   * Threat level  5: Unit is a tank.
--   * Threat level  7: Unit is FLAK.
--   * Threat level  10: Unit is AAA.
--  
-- 
-- @param #UNIT self
-- @return #number Number between 0 (low threat level) and 10 (high threat level).
-- @return #string Some text.
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

--- Triggers an explosion at the coordinates of the unit.
-- @param #UNIT self
-- @param #number power Power of the explosion in kg TNT. Default 100 kg TNT.
-- @param #number delay (Optional) Delay of explosion in seconds.
-- @return #UNIT self
function UNIT:Explode(power, delay)

  -- Default.
  power=power or 100
  
  local DCSUnit = self:GetDCSObject()
  if DCSUnit then
  
    -- Check if delay or not.
    if delay and delay>0 then
      -- Delayed call.
      SCHEDULER:New(nil, self.Explode, {self, power}, delay)
    else
      -- Create an explotion at the coordinate of the unit.
      self:GetCoordinate():Explosion(power)
    end
  
    return self
  end
  
  return nil
end

-- Is functions



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
-- @param #boolean NoHeloCheck If true, no additonal checks for helos are performed.
-- @return #boolean Return true if in the air or #nil if the UNIT is not existing or alive.   
function UNIT:InAir(NoHeloCheck)
  self:F2( self.UnitName )

  -- Get DCS unit object.
  local DCSUnit = self:GetDCSObject() --DCS#Unit
  
  if DCSUnit then

    -- Get DCS result of whether unit is in air or not.
    local UnitInAir = DCSUnit:inAir()

    -- Get unit category.
    local UnitCategory = DCSUnit:getDesc().category

    -- If DCS says that it is in air, check if this is really the case, since we might have landed on a building where inAir()=true but actually is not.
    -- This is a workaround since DCS currently does not acknoledge that helos land on buildings.
    -- Note however, that the velocity check will fail if the ground is moving, e.g. on an aircraft carrier!    
    if UnitInAir==true and UnitCategory == Unit.Category.HELICOPTER and (not NoHeloCheck) then
      local VelocityVec3 = DCSUnit:getVelocity()
      local Velocity = UTILS.VecNorm(VelocityVec3)
      local Coordinate = DCSUnit:getPoint()
      local LandHeight = land.getHeight( { x = Coordinate.x, y = Coordinate.z } )
      local Height = Coordinate.y - LandHeight
      if Velocity < 1 and Height <= 60   then
        UnitInAir = false
      end
    end
    
    self:T3( UnitInAir )
    return UnitInAir
  end
  
  return nil
end

do -- Event Handling

  --- Subscribe to a DCS Event.
  -- @param #UNIT self
  -- @param Core.Event#EVENTS EventID Event ID.
  -- @param #function EventFunction (Optional) The function to be called when the event occurs for the unit.
  -- @return #UNIT self
  function UNIT:HandleEvent(EventID, EventFunction)
  
    self:EventDispatcher():OnEventForUnit(self:GetName(), EventFunction, self, EventID)
    
    return self
  end
  
  --- UnSubscribe to a DCS event.
  -- @param #UNIT self
  -- @param Core.Event#EVENTS EventID Event ID.
  -- @return #UNIT self
  function UNIT:UnHandleEvent(EventID)
  
    --self:EventDispatcher():RemoveForUnit( self:GetName(), self, EventID )
    
    -- Fixes issue #1365 https://github.com/FlightControl-Master/MOOSE/issues/1365
    self:EventDispatcher():RemoveEvent(self, EventID)
    
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

  --- Forces the unit to become aware of the specified target, without the unit manually detecting the other unit itself.
  -- Applies only to a Unit Controller. Cannot be used at the group level.
  -- @param #UNIT self
  -- @param #UNIT TargetUnit The unit to be known.
  -- @param #boolean TypeKnown The target type is known. If *false*, the type is not known.
  -- @param #boolean DistanceKnown The distance to the target is known. If *false*, distance is unknown.
  function UNIT:KnowUnit(TargetUnit, TypeKnown, DistanceKnown)

    -- Defaults.
    if TypeKnown~=false then
      TypeKnown=true
    end
    if DistanceKnown~=false then
      DistanceKnown=true
    end
  
    local DCSControllable = self:GetDCSObject()
  
    if DCSControllable then
  
      local Controller = DCSControllable:getController()  --self:_GetController()
      
      if Controller then
      
        local object=TargetUnit:GetDCSObject()
        
        if object then
          
          self:I(string.format("Unit %s now knows target unit %s. Type known=%s, distance known=%s", self:GetName(), TargetUnit:GetName(), tostring(TypeKnown), tostring(DistanceKnown)))
      
          Controller:knowTarget(object, TypeKnown, DistanceKnown)
          
        end
        
      end
  
    end
    
  end

end

--- Get the unit table from a unit's template.
-- @param #UNIT self
-- @return #table Table of the unit template (deep copy) or #nil.
function UNIT:GetTemplate()

  local group=self:GetGroup()
  
  local name=self:GetName()
  
  if group then
    local template=group:GetTemplate()
    
    if template then
    
      for _,unit in pairs(template.units) do
      
        if unit.name==name then
          return UTILS.DeepCopy(unit) 
        end
      end
      
    end     
  end
  
  return nil
end


--- Get the payload table from a unit's template.
-- The payload table has elements:
-- 
--    * pylons
--    * fuel
--    * chaff
--    * gun
--    
-- @param #UNIT self
-- @return #table Payload table (deep copy) or #nil.
function UNIT:GetTemplatePayload()

  local unit=self:GetTemplate()
  
  if unit then
    return unit.payload
  end
  
  return nil
end

--- Get the pylons table from a unit's template. This can be a complex table depending on the weapons the unit is carrying.
-- @param #UNIT self
-- @return #table Table of pylons (deepcopy) or #nil.
function UNIT:GetTemplatePylons()

  local payload=self:GetTemplatePayload()
  
  if payload then
    return payload.pylons
  end

  return nil
end

--- Get the fuel of the unit from its template.
-- @param #UNIT self
-- @return #number Fuel of unit in kg.
function UNIT:GetTemplateFuel()

  local payload=self:GetTemplatePayload()
  
  if payload then
    return payload.fuel
  end

  return nil
end

--- GROUND - Switch on/off radar emissions of a unit.
-- @param #UNIT self
-- @param #boolean switch If true, emission is enabled. If false, emission is disabled. 
-- @return #UNIT self
function UNIT:EnableEmission(switch)
  self:F2( self.UnitName )
  
  local switch = switch or false
  
  local DCSUnit = self:GetDCSObject()
  
  if DCSUnit then
  
    DCSUnit:enableEmission(switch)

  end

  return self
end

--- Get skill from Unit.
-- @param #UNIT self
-- @return #string Skill String of skill name.
function UNIT:GetSkill()
  self:F2( self.UnitName )
  local name = self.UnitName
  local skill = _DATABASE.Templates.Units[name].Template.skill or "Random"
  return skill
end
