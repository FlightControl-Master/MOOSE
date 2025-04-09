--- **Wrapper** - STATIC wraps the DCS StaticObject class.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: **funkyfranky**
-- 
-- ===
-- 
-- @module Wrapper.Static
-- @image Wrapper_Static.JPG


---
-- @type STATIC
-- @extends Wrapper.Positionable#POSITIONABLE

--- Wrapper class to handle Static objects.
-- 
-- Note that Statics are almost the same as Units, but they don't have a controller.
-- The @{Wrapper.Static#STATIC} class is a wrapper class to handle the DCS Static objects:
-- 
--  * Wraps the DCS Static objects.
--  * Support all DCS Static APIs.
--  * Enhance with Static specific APIs not in the DCS API set.
-- 
-- ## STATIC reference methods
-- 
-- For each DCS Static will have a STATIC wrapper object (instance) within the global _DATABASE object (an instance of @{Core.Database#DATABASE}).
-- This is done at the beginning of the mission (when the mission starts).
--  
-- The @{#STATIC} class does not contain a :New() method, rather it provides :Find() methods to retrieve the object reference
-- using the Static Name.
-- 
-- Another thing to know is that STATIC objects do not "contain" the DCS Static object. 
-- The @{#STATIC} methods will reference the DCS Static object by name when it is needed during API execution.
-- If the DCS Static object does not exist or is nil, the STATIC methods will return nil and log an exception in the DCS.log file.
--  
-- The @{#STATIC} class provides the following functions to retrieve quickly the relevant STATIC instance:
-- 
--  * @{#STATIC.FindByName}(): Find a STATIC instance from the global _DATABASE object (an instance of @{Core.Database#DATABASE}) using a DCS Static name.
--  
-- IMPORTANT: ONE SHOULD NEVER SANITIZE these STATIC OBJECT REFERENCES! (make the STATIC object references nil).
-- 
-- @field #STATIC
STATIC = {
  ClassName = "STATIC",
}


--- Register a static object.
-- @param #STATIC self
-- @param #string StaticName Name of the static object.
-- @return #STATIC self
function STATIC:Register( StaticName )
  local self = BASE:Inherit( self, POSITIONABLE:New( StaticName ) )
  self.StaticName = StaticName
  
  local DCSStatic = StaticObject.getByName( self.StaticName )
  if DCSStatic then
    local Life0 = DCSStatic:getLife() or 1
    self.Life0 = Life0
  else
    self:E(string.format("Static object %s does not exist!", tostring(self.StaticName)))
  end
  
  return self
end

--- Get initial life points
-- @param #STATIC self
-- @return #number lifepoints
function STATIC:GetLife0()
  return self.Life0 or 1
end

--- Get current life points
-- @param #STATIC self
-- @return #number lifepoints or nil
function STATIC:GetLife()
  local DCSStatic = StaticObject.getByName( self.StaticName )
  if DCSStatic then
    return DCSStatic:getLife() or 1
  end
  return nil
end

--- Finds a STATIC from the _DATABASE using a DCSStatic object.
-- @param #STATIC self
-- @param DCS#StaticObject DCSStatic An existing DCS Static object reference.
-- @return #STATIC self
function STATIC:Find( DCSStatic )

  local StaticName = DCSStatic:getName()
  local StaticFound = _DATABASE:FindStatic( StaticName )
  return StaticFound
end

--- Finds a STATIC from the _DATABASE using the relevant Static Name.
-- As an optional parameter, a briefing text can be given also.
-- @param #STATIC self
-- @param #string StaticName Name of the DCS **Static** as defined within the Mission Editor.
-- @param #boolean RaiseError Raise an error if not found.
-- @return #STATIC self or *nil*
function STATIC:FindByName( StaticName, RaiseError )

  -- Find static in DB.
  local StaticFound = _DATABASE:FindStatic( StaticName )

  -- Set static name.
  self.StaticName = StaticName
  
  if StaticFound then
    return StaticFound
  end
  
  if RaiseError == nil or RaiseError == true then 
    error( "STATIC not found for: " .. StaticName ) 
  end

  return nil
end

--- Destroys the STATIC.
-- @param #STATIC self
-- @param #boolean GenerateEvent (Optional) true if you want to generate a crash or dead event for the static.
-- @return #nil The DCS StaticObject is not existing or alive.  
-- @usage
-- -- Air static example: destroy the static Helicopter and generate a S_EVENT_CRASH.
-- Helicopter = STATIC:FindByName( "Helicopter" )
-- Helicopter:Destroy( true )
-- 
-- @usage
-- -- Ground static example: destroy the static Tank and generate a S_EVENT_DEAD.
-- Tanks = UNIT:FindByName( "Tank" )
-- Tanks:Destroy( true )
-- 
-- @usage
-- -- Ship static example: destroy the Ship silently.
-- Ship = STATIC:FindByName( "Ship" )
-- Ship:Destroy()
-- 
-- @usage
-- -- Destroy without event generation example.
-- Ship = STATIC:FindByName( "Boat" )
-- Ship:Destroy( false ) -- Don't generate an event upon destruction.
-- 
function STATIC:Destroy( GenerateEvent )
  self:F2( self.ObjectName )

  local DCSObject = self:GetDCSObject()
  
  if DCSObject then
  
    local StaticName = DCSObject:getName()
    self:F( { StaticName = StaticName } )
    
    if GenerateEvent and GenerateEvent == true then
      if self:IsAir() then
        self:CreateEventCrash( timer.getTime(), DCSObject )
      else
        self:CreateEventDead( timer.getTime(), DCSObject )
      end
    elseif GenerateEvent == false then
      -- Do nothing!
    else
      self:CreateEventRemoveUnit( timer.getTime(), DCSObject )
    end
    
    DCSObject:destroy()
    return true
  end

  return nil
end


--- Get DCS object of static of static.
-- @param #STATIC self
-- @return DCS static object
function STATIC:GetDCSObject()
  local DCSStatic = StaticObject.getByName( self.StaticName ) 
  
  if DCSStatic then
    return DCSStatic
  end
    
  return nil
end

--- Returns a list of one @{Wrapper.Static}.
-- @param #STATIC self
-- @return #list<Wrapper.Static#STATIC> A list of one @{Wrapper.Static}.
function STATIC:GetUnits()
  self:F2( { self.StaticName } )
  local DCSStatic = self:GetDCSObject()

  local Statics = {}
  
  if DCSStatic then
    Statics[1] = STATIC:Find( DCSStatic )
    self:T3( Statics )
    return Statics
  end

  return nil
end


--- Get threat level of static.
-- @param #STATIC self
-- @return #number Threat level 1.
-- @return #string "Static"
function STATIC:GetThreatLevel()
  return 1, "Static"
end

--- Spawn the @{Wrapper.Static} at a specific coordinate and heading.
-- @param #STATIC self
-- @param Core.Point#COORDINATE Coordinate The coordinate where to spawn the new Static.
-- @param #number Heading The heading of the static respawn in degrees. Default is 0 deg.
-- @param #number Delay Delay in seconds before the static is spawned.
function STATIC:SpawnAt(Coordinate, Heading, Delay)

  Heading=Heading or 0

  if Delay and Delay>0 then
    SCHEDULER:New(nil, self.SpawnAt, {self, Coordinate, Heading}, Delay)
  else

    local SpawnStatic=SPAWNSTATIC:NewFromStatic(self.StaticName)
  
    SpawnStatic:SpawnFromPointVec2( Coordinate, Heading, self.StaticName )
    
  end
  
  return self
end


--- Respawn the @{Wrapper.Static} at the same location with the same properties.
-- This is useful to respawn a cargo after it has been destroyed.
-- @param #STATIC self
-- @param DCS#country.id CountryID (Optional) The country ID used for spawning the new static. Default is same as currently.
-- @param #number Delay (Optional) Delay in seconds before static is respawned. Default now.
function STATIC:ReSpawn(CountryID, Delay)

  if Delay and Delay>0 then
    SCHEDULER:New(nil, self.ReSpawn, {self, CountryID}, Delay)
  else

    CountryID=CountryID or self:GetCountry()  
   
    local SpawnStatic=SPAWNSTATIC:NewFromStatic(self.StaticName, CountryID)
    
    SpawnStatic:Spawn(nil, self.StaticName)
    
  end
  
  return self
end


--- Respawn the @{Wrapper.Unit} at a defined Coordinate with an optional heading.
-- @param #STATIC self
-- @param Core.Point#COORDINATE Coordinate The coordinate where to spawn the new Static.
-- @param #number Heading (Optional) The heading of the static respawn in degrees. Default the current heading.
-- @param #number Delay (Optional) Delay in seconds before static is respawned. Default now.
function STATIC:ReSpawnAt(Coordinate, Heading, Delay)

  --Heading=Heading or 0

  if Delay and Delay>0 then
    SCHEDULER:New(nil, self.ReSpawnAt, {self, Coordinate, Heading}, Delay)
  else      
      
    local SpawnStatic=SPAWNSTATIC:NewFromStatic(self.StaticName, self:GetCountry())
    
    SpawnStatic:SpawnFromCoordinate(Coordinate, Heading, self.StaticName)
    
  end
  
  return self
end

--- Find the first(!) STATIC matching using patterns. Note that this is **a lot** slower than `:FindByName()`!
-- @param #STATIC self
-- @param #string Pattern The pattern to look for. Refer to [LUA patterns](http://www.easyuo.com/openeuo/wiki/index.php/Lua_Patterns_and_Captures_\(Regular_Expressions\)) for regular expressions in LUA.
-- @return #STATIC The STATIC.
-- @usage
--          -- Find a static with a partial static name
--          local grp = STATIC:FindByMatching( "Apple" )
--          -- will return e.g. a static named "Apple-1-1"
--
--          -- using a pattern
--          local grp = STATIC:FindByMatching( ".%d.%d$" )
--          -- will return the first static found ending in "-1-1" to "-9-9", but not e.g. "-10-1"
function STATIC:FindByMatching( Pattern )
  local GroupFound = nil

  for name,static in pairs(_DATABASE.STATICS) do
    if string.match(name, Pattern ) then
      GroupFound = static
      break
    end
  end

  return GroupFound
end

--- Find all STATIC objects matching using patterns. Note that this is **a lot** slower than `:FindByName()`!
-- @param #STATIC self
-- @param #string Pattern The pattern to look for. Refer to [LUA patterns](http://www.easyuo.com/openeuo/wiki/index.php/Lua_Patterns_and_Captures_\(Regular_Expressions\)) for regular expressions in LUA.
-- @return #table Groups Table of matching #STATIC objects found
-- @usage
--          -- Find all static with a partial static name
--          local grptable = STATIC:FindAllByMatching( "Apple" )
--          -- will return all statics with "Apple" in the name
--
--          -- using a pattern
--          local grp = STATIC:FindAllByMatching( ".%d.%d$" )
--          -- will return the all statics found ending in "-1-1" to "-9-9", but not e.g. "-10-1" or "-1-10"
function STATIC:FindAllByMatching( Pattern )
  local GroupsFound = {}

  for name,static in pairs(_DATABASE.STATICS) do
    if string.match(name, Pattern ) then
      GroupsFound[#GroupsFound+1] = static
    end
  end

  return GroupsFound
end

--- Get the Wrapper.Storage#STORAGE object of an static if it is used as cargo and has been set up as storage object.
-- @param #STATIC self
-- @return Wrapper.Storage#STORAGE Storage or `nil` if not fund or set up.
function STATIC:GetStaticStorage()
  local name = self:GetName()
  local storage = STORAGE:NewFromStaticCargo(name)
  return storage
end

--- Get the Cargo Weight of a static object in kgs. Returns -1 if not found.
-- @param #STATIC self
-- @return #number Mass Weight in kgs.
function STATIC:GetCargoWeight()
  local DCSObject = StaticObject.getByName(self.StaticName )
  local mass = -1
  if DCSObject then
     mass = DCSObject:getCargoWeight() or 0
     local masstxt = DCSObject:getCargoDisplayName() or "none"
     --BASE:I("GetCargoWeight "..tostring(mass).." MassText "..masstxt)
  end
  return mass
end
