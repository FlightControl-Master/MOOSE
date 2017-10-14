--- **Wrapper** -- STATIC wraps the DCS StaticObject class.
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- 
-- ### Contributions: 
-- 
-- ====
-- 
-- @module Static


--- @type STATIC
-- @extends Wrapper.Positionable#POSITIONABLE

--- # STATIC class, extends @{Positionable#POSITIONABLE}
-- 
-- Statics are **Static Units** defined within the Mission Editor.
-- Note that Statics are almost the same as Units, but they don't have a controller.
-- The @{Static#STATIC} class is a wrapper class to handle the DCS Static objects:
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

function STATIC:Register( StaticName )
  local self = BASE:Inherit( self, POSITIONABLE:New( StaticName ) )
  self.StaticName = StaticName
  return self
end


function STATIC:GetDCSObject()
  local DCSStatic = StaticObject.getByName( self.StaticName )
  
  if DCSStatic then
    return DCSStatic
  end
    
  return nil
end

function STATIC:GetThreatLevel()

  return 1, "Static"
end

--- Respawn the @{Unit} using a (tweaked) template of the parent Group.
-- @param #UNIT self
-- @param Core.Point#COORDINATE Coordinate The coordinate where to spawn the new Static.
-- @param #number Heading The heading of the unit respawn.
function STATIC:ReSpawn( Coordinate, Heading )


  -- todo: need to fix country
  local SpawnStatic = SPAWNSTATIC:NewFromStatic( self.StaticName, country.id.USA )
  
  SpawnStatic:SpawnFromPointVec2( Coordinate, Heading, self.StaticName )
end

