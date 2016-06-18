--- This module contains the PATROLZONE class.
-- 
-- ===
-- 
-- 1) @{Patrol#PATROLZONE} class, extends @{Base#BASE}
-- ===================================================
-- The @{Patrol#PATROLZONE} class implements the core functions to patrol a @{Zone}.
-- 
-- 1.1) PATROLZONE constructor:
-- ----------------------------
-- @{PatrolZone#PATROLZONE.New}(): Creates a new PATROLZONE object.
-- 
-- 1.2) Modify the PATROLZONE parameters:
-- --------------------------------------
-- The following methods are available to modify the parameters of a PATROLZONE object:
-- 
--     * @{PatrolZone#PATROLZONE.SetSpeed}(): Set the patrol speed of the AI, while patrolling.
--     * @{PatrolZone#PATROLZONE.SetAltitude}(): Set altitude of the AI, while patrolling.
-- 
-- ===
-- 
-- @module PatrolZone
-- @author FlightControl


--- PATROLZONE class
-- @type PATROLZONE
-- @extends Base#BASE
PATROLZONE = {
  ClassName = "PATROLZONE",
}

--- Creates a new PATROLZONE object, taking a @{Group} object as a parameter. The GROUP needs to be alive.
-- @param #PATROLZONE self
-- @param Group#GROUP PatrolGroup The @{Group} patrolling.
-- @param Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Group} in km/h.
-- @param DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Group} in km/h.
-- @return #PATROLZONE self
-- @usage
-- -- Define a new PATROLZONE Object. This PatrolArea will patrol a group within PatrolZone between 3000 and 6000 meters, with a variying speed between 600 and 900 km/h.
-- PatrolZone = ZONE:New( 'PatrolZone' )
-- PatrolGroup = GROUP:FindByName( "Patrol Group" )
-- PatrolArea = PATROLZONE:New( PatrolGroup, PatrolZone, 3000, 6000, 600, 900 )
function PATROLZONE:New( PatrolGroup, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.PatrolGroup = PatrolGroup
  self.PatrolZone = PatrolZone
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed

  return self
end
