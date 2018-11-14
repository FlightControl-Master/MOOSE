--- **Wrapper** -- STATIC wraps the DCS StaticObject class.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Wrapper.Static
-- @image Wrapper_Static.JPG


--- @type STATIC
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
-- For each DCS Static will have a STATIC wrapper object (instance) within the _@{DATABASE} object.
-- This is done at the beginning of the mission (when the mission starts).
--  
-- The STATIC class does not contain a :New() method, rather it provides :Find() methods to retrieve the object reference
-- using the Static Name.
-- 
-- Another thing to know is that STATIC objects do not "contain" the DCS Static object. 
-- The STATIc methods will reference the DCS Static object by name when it is needed during API execution.
-- If the DCS Static object does not exist or is nil, the STATIC methods will return nil and log an exception in the DCS.log file.
--  
-- The STATIc class provides the following functions to retrieve quickly the relevant STATIC instance:
-- 
--  * @{#STATIC.FindByName}(): Find a STATIC instance from the _DATABASE object using a DCS Static name.
--  
-- IMPORTANT: ONE SHOULD NEVER SANATIZE these STATIC OBJECT REFERENCES! (make the STATIC object references nil).
-- 
-- @field #STATIC
STATIC = {
	ClassName = "STATIC",
}


function STATIC:Register( StaticName )
  local self = BASE:Inherit( self, POSITIONABLE:New( StaticName ) )
  self.StaticName = StaticName
  return self
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
-- @return #STATIC
function STATIC:FindByName( StaticName, RaiseError )
  local StaticFound = _DATABASE:FindStatic( StaticName )

  self.StaticName = StaticName
  
  if StaticFound then
    StaticFound:F3( { StaticName } )
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
  end

  return nil
end



function STATIC:GetDCSObject()
  local DCSStatic = StaticObject.getByName( self.StaticName )
  
  if DCSStatic then
    return DCSStatic
  end
    
  return nil
end

--- Returns a list of one @{Static}.
-- @param #STATIC self
-- @return #list<Wrapper.Static#STATIC> A list of one @{Static}.
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




function STATIC:GetThreatLevel()

  return 1, "Static"
end

--- Respawn the @{Wrapper.Unit} using a (tweaked) template of the parent Group.
-- @param #STATIC self
-- @param Core.Point#COORDINATE Coordinate The coordinate where to spawn the new Static.
-- @param #number Heading The heading of the unit respawn.
function STATIC:SpawnAt( Coordinate, Heading )

  local SpawnStatic = SPAWNSTATIC:NewFromStatic( self.StaticName )
  
  SpawnStatic:SpawnFromPointVec2( Coordinate, Heading, self.StaticName )
end


--- Respawn the @{Wrapper.Unit} at the same location with the same properties.
-- This is useful to respawn a cargo after it has been destroyed.
-- @param #STATIC self
-- @param DCS#country.id countryid The country ID used for spawning the new static.
function STATIC:ReSpawn(countryid)

  local SpawnStatic = SPAWNSTATIC:NewFromStatic( self.StaticName, countryid )
  
  SpawnStatic:ReSpawn()
end


--- Respawn the @{Wrapper.Unit} at a defined Coordinate with an optional heading.
-- @param #STATIC self
-- @param Core.Point#COORDINATE Coordinate The coordinate where to spawn the new Static.
-- @param #number Heading The heading of the unit respawn.
function STATIC:ReSpawnAt( Coordinate, Heading )

  local SpawnStatic = SPAWNSTATIC:NewFromStatic( self.StaticName )
  
  SpawnStatic:ReSpawnAt( Coordinate, Heading )
end


--- Returns true if the unit is within a @{Zone}.
-- @param #STATIC self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the unit is within the @{Core.Zone#ZONE_BASE}
function STATIC:IsInZone( Zone )
  self:F2( { self.StaticName, Zone } )

  if self:IsAlive() then
    local IsInZone = Zone:IsVec3InZone( self:GetVec3() )
  
    return IsInZone 
  end
  return false
end

--- Returns true if the unit is not within a @{Zone}.
-- @param #STATIC self
-- @param Core.Zone#ZONE_BASE Zone The zone to test.
-- @return #boolean Returns true if the unit is not within the @{Core.Zone#ZONE_BASE}
function STATIC:IsNotInZone( Zone )
  self:F2( { self.StaticName, Zone } )

  if self:IsAlive() then
    local IsInZone = not Zone:IsVec3InZone( self:GetVec3() )
    
    self:T( { IsInZone } )
    return IsInZone 
  else
    return false
  end
end
