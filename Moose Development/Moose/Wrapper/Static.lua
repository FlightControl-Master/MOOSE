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
function STATIC:ReSpawn()

  local SpawnStatic = SPAWNSTATIC:NewFromStatic( self.StaticName )
  
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
