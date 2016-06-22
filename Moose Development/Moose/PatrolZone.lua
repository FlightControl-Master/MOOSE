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
--     * @{PatrolZone#PATROLZONE.SetGroup}(): Set the AI Patrol Group.
--     * @{PatrolZone#PATROLZONE.SetSpeed}(): Set the patrol speed of the AI, for the next patrol.
--     * @{PatrolZone#PATROLZONE.SetAltitude}(): Set altitude of the AI, for the next patrol.
-- 
-- 1.3) Manage the out of fuel in the PATROLZONE:
-- ----------------------------------------------
-- When the PatrolGroup is out of fuel, it is required that a new PatrolGroup is started, before the old PatrolGroup can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the PatrolGroup will continue for a given time its patrol task in orbit, while a new PatrolGroup is targetted to the PATROLZONE.
-- Once the time is finished, the old PatrolGroup will return to the base.
-- Use the method @{PatrolZone#PATROLZONE.ManageFuel}() to have this proces in place.
-- 
-- ===
-- 
-- @module PatrolZone
-- @author FlightControl


--- PATROLZONE class
-- @type PATROLZONE
-- @field Group#GROUP PatrolGroup The @{Group} patrolling.
-- @field Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @field DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @field DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @field DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Group} in km/h.
-- @field DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Group} in km/h.
-- @extends Base#BASE
PATROLZONE = {
  ClassName = "PATROLZONE",
}

--- Creates a new PATROLZONE object, taking a @{Group} object as a parameter. The GROUP needs to be alive.
-- @param #PATROLZONE self
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
function PATROLZONE:New( PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed )

  -- Inherits from BASE
  local self = BASE:Inherit( self, BASE:New() )
  
  self.PatrolZone = PatrolZone
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed

  return self
end

--- Set the @{Group} to act as the Patroller.
-- @param #PATROLZONE self
-- @param Group#GROUP PatrolGroup The @{Group} patrolling.
-- @return #PATROLZONE self
function PATROLZONE:SetGroup( PatrolGroup )

  self.PatrolGroup = PatrolGroup
  self.PatrolGroupTemplateName = PatrolGroup:GetName()
  self:NewPatrolRoute()

  if not self.PatrolOutOfFuelMonitor then
    self.PatrolOutOfFuelMonitor = SCHEDULER:New( nil, _MonitorOutOfFuelScheduled, { self }, 1, 120, 0 )
    self.SpawnPatrolGroup = SPAWN:New( self.PatrolGroupTemplateName )
  end

  return self  
end

--- Sets (modifies) the minimum and maximum speed of the patrol.
-- @param #PATROLZONE self
-- @param DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Group} in km/h.
-- @param DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Group} in km/h.
-- @return #PATROLZONE self
function PATROLZONE:SetSpeed( PatrolMinSpeed, PatrolMaxSpeed )
  self:F2( { PatrolMinSpeed, PatrolMaxSpeed } )
  
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
end

--- Sets the floor and ceiling altitude of the patrol.
-- @param #PATROLZONE self
-- @param DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @return #PATROLZONE self
function PATROLZONE:SetAltitude( PatrolFloorAltitude, PatrolCeilingAltitude )
  self:F2( { PatrolFloorAltitude, PatrolCeilingAltitude } )
  
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
end



--- @param Group#GROUP PatrolGroup
function _NewPatrolRoute( PatrolGroup )

  PatrolGroup:T( "NewPatrolRoute" )
  local PatrolZone = PatrolGroup:GetState( PatrolGroup, "PatrolZone" ) -- PatrolZone#PATROLZONE
  PatrolZone:NewPatrolRoute()
end

--- Defines a new patrol route using the @{PatrolZone} parameters and settings.
-- @param #PATROLZONE self
-- @return #PATROLZONE self
function PATROLZONE:NewPatrolRoute()

  self:F2()

  local PatrolRoute = {}
  
  if self.PatrolGroup:IsAlive() then
    --- Determine if the PatrolGroup is within the PatrolZone. 
    -- If not, make a waypoint within the to that the PatrolGroup will fly at maximum speed to that point.
    
--    --- Calculate the current route point.
--    local CurrentVec2 = self.PatrolGroup:GetPointVec2()
--    local CurrentAltitude = self.PatrolGroup:GetUnit(1):GetAltitude()
--    local CurrentPointVec3 = POINT_VEC3:New( CurrentVec2.x, CurrentAltitude, CurrentVec2.y )
--    local CurrentRoutePoint = CurrentPointVec3:RoutePointAir( 
--        POINT_VEC3.RoutePointAltType.BARO, 
--        POINT_VEC3.RoutePointType.TurningPoint, 
--        POINT_VEC3.RoutePointAction.TurningPoint, 
--        ToPatrolZoneSpeed, 
--        true 
--      )
--    
--    PatrolRoute[#PatrolRoute+1] = CurrentRoutePoint
    
    self:T2( PatrolRoute )
  
    if self.PatrolGroup:IsNotInZone( self.PatrolZone ) then
      --- Find a random 2D point in PatrolZone.
      local ToPatrolZoneVec2 = self.PatrolZone:GetRandomVec2()
      self:T2( ToPatrolZoneVec2 )
      
      --- Define Speed and Altitude.
      local ToPatrolZoneAltitude = math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude )
      local ToPatrolZoneSpeed = self.PatrolMaxSpeed
      
      --- Obtain a 3D @{Point} from the 2D point + altitude.
      self:T2( ToPatrolZoneVec2.x )
      self:T2( ToPatrolZoneVec2.y )
      local ToPatrolZonePointVec3 = POINT_VEC3:New( ToPatrolZoneVec2.x, ToPatrolZoneAltitude, ToPatrolZoneVec2.y )
      
      --- Create a route point of type air.
      local ToPatrolZoneRoutePoint = ToPatrolZonePointVec3:RoutePointAir( 
        POINT_VEC3.RoutePointAltType.BARO, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        ToPatrolZoneSpeed, 
        true 
      )

    PatrolRoute[#PatrolRoute+1] = ToPatrolZoneRoutePoint

    end
    
    --- Define a random point in the @{Zone}. The AI will fly to that point within the zone.
    
      --- Find a random 2D point in PatrolZone.
    local ToTargetVec2 = self.PatrolZone:GetRandomVec2()
    self:T2( ToTargetVec2 )

    --- Define Speed and Altitude.
    local ToTargetAltitude = math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude )
    local ToTargetSpeed = math.random( self.PatrolMinSpeed, self.PatrolMaxSpeed )
    
    --- Obtain a 3D @{Point} from the 2D point + altitude.
    local ToTargetPointVec3 = POINT_VEC3:New( ToTargetVec2.x, ToTargetAltitude, ToTargetVec2.y )
    
    --- Create a route point of type air.
    local ToTargetRoutePoint = ToTargetPointVec3:RoutePointAir( 
      POINT_VEC3.RoutePointAltType.BARO, 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      ToTargetSpeed, 
      true 
    )
    
    --ToTargetPointVec3:SmokeRed()

    PatrolRoute[#PatrolRoute+1] = ToTargetRoutePoint
    
    --- Now we're going to do something special, we're going to call a function from a waypoint action at the PatrolGroup...
    self.PatrolGroup:WayPointInitialize( PatrolRoute )
    
    --- Do a trick, link the NewPatrolRoute function of the PATROLGROUP object to the PatrolGroup in a temporary variable ...
    self.PatrolGroup:SetState( self.PatrolGroup, "PatrolZone", self )
    self.PatrolGroup:WayPointFunction( #PatrolRoute, 1, "_NewPatrolRoute" )

    --- NOW ROUTE THE GROUP!
    self.PatrolGroup:WayPointExecute( 1, 2 )
  end
  
end

--- When the PatrolGroup is out of fuel, it is required that a new PatrolGroup is started, before the old PatrolGroup can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the PatrolGroup will continue for a given time its patrol task in orbit, while a new PatrolGroup is targetted to the PATROLZONE.
-- Once the time is finished, the old PatrolGroup will return to the base.
-- @param #PATROLZONE self
-- @param #number PatrolFuelTresholdPercentage The treshold in percentage (between 0 and 1) when the PatrolGroup is considered to get out of fuel.
-- @param #number PatrolOutOfFuelOrbitTime The amount of seconds the out of fuel PatrolGroup will orbit before returning to the base.
-- @return #PATROLZONE self
function PATROLZONE:ManageFuel( PatrolFuelTresholdPercentage, PatrolOutOfFuelOrbitTime )

  self.PatrolManageFuel = true
  self.PatrolFuelTresholdPercentage = PatrolFuelTresholdPercentage
  self.PatrolOutOfFuelOrbitTime = PatrolOutOfFuelOrbitTime
  
  if self.PatrolGroup then
    self.PatrolOutOfFuelMonitor = SCHEDULER:New( self, self._MonitorOutOfFuelScheduled, {}, 1, 120, 0 )
    self.SpawnPatrolGroup = SPAWN:New( self.PatrolGroupTemplateName )
  end
  return self
end

--- @param #PATROLZONE self
function _MonitorOutOfFuelScheduled( self )
  self:F2( "_MonitorOutOfFuelScheduled" )

  if self.PatrolGroup and self.PatrolGroup:IsAlive() then
  
    local Fuel = self.PatrolGroup:GetUnit(1):GetFuel()
    if Fuel < self.PatrolFuelTresholdPercentage then
      local OldPatrolGroup = self.PatrolGroup
      local PatrolGroupTemplate = self.PatrolGroup:GetTemplate()
      
      local OrbitTask = OldPatrolGroup:TaskOrbitCircle( math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude ), self.PatrolMinSpeed )
      local TimedOrbitTask = OldPatrolGroup:TaskControlled( OrbitTask, OldPatrolGroup:TaskCondition(nil,nil,nil,nil,self.PatrolOutOfFuelOrbitTime,nil ) )
      OldPatrolGroup:SetTask( TimedOrbitTask, 10 )
      
      local NewPatrolGroup = self.SpawnPatrolGroup:Spawn()
      self.PatrolGroup = NewPatrolGroup
      self:NewPatrolRoute()
    end
  else
    self.PatrolOutOfFuelMonitor:Stop()
  end
end