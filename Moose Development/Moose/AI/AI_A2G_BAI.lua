--- **AI** -- Models the process of air to ground BAI engagement for airplanes and helicopters.
--
-- This is a class used in the @{AI_A2G_Dispatcher}.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_A2G_BAI
-- @image AI_Air_To_Ground_Engage.JPG



--- @type AI_A2G_BAI
-- @extends AI.AI_A2A_Engage#AI_A2A_Engage


--- Implements the core functions to intercept intruders. Use the Engage trigger to intercept intruders.
-- 
-- ===
-- 
-- @field #AI_A2G_BAI
AI_A2G_BAI = {
  ClassName = "AI_A2G_BAI",
}



--- Creates a new AI_A2G_BAI object
-- @param #AI_A2G_BAI self
-- @param Wrapper.Group#GROUP AIGroup
-- @param DCS#Speed  EngageMinSpeed The minimum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Speed  EngageMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h when engaging a target.
-- @param DCS#Altitude EngageFloorAltitude The lowest altitude in meters where to execute the engagement.
-- @param DCS#Altitude EngageCeilingAltitude The highest altitude in meters where to execute the engagement.
-- @param Core.Zone#ZONE_BASE PatrolZone The @{Zone} where the patrol needs to be executed.
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Group} in km/h.
-- @param DCS#AltitudeType PatrolAltType The altitude type ("RADIO"=="AGL", "BARO"=="ASL"). Defaults to RADIO
-- @return #AI_A2G_BAI
function AI_A2G_BAI:New( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_A2G_PATROL:New( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType ) ) -- #AI_A2G_BAI

  local RTBSpeedMax = AIGroup:GetSpeedMax() or 9999

  self:SetRTBSpeed( RTBSpeedMax * 0.50, RTBSpeedMax * 0.75 )

  return self
end


--- @param #AI_A2G_BAI self
-- @param Wrapper.Group#GROUP DefenderGroup The GroupGroup managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_BAI:onafterEngage( DefenderGroup, From, Event, To, AttackSetUnit )

  self:F( { DefenderGroup, From, Event, To, AttackSetUnit} )
  
  local DefenderGroupName = DefenderGroup:GetName()

  local AttackCount = AttackSetUnit:Count()
  
  if AttackCount > 0 then

    if DefenderGroup:IsAlive() then

      local EngageAltitude = math.random( self.EngageFloorAltitude, self.EngageCeilingAltitude )
      local EngageSpeed = math.random( self.EngageMinSpeed, self.EngageMaxSpeed )

      -- Determine the distance to the target.
      -- If it is less than 10km, then attack without a route.
      -- Otherwise perform a route attack.

      local DefenderCoord = DefenderGroup:GetPointVec3()
      DefenderCoord:SetY( EngageAltitude ) -- Ground targets don't have an altitude.

      local TargetCoord = AttackSetUnit:GetFirst():GetPointVec3()
      TargetCoord:SetY( EngageAltitude ) -- Ground targets don't have an altitude.
      
      local TargetDistance = DefenderCoord:Get2DDistance( TargetCoord )
      local EngageDistance = ( DefenderGroup:IsHelicopter() and 5000 ) or ( DefenderGroup:IsAirPlane() and 10000 ) 
      
      local EngageRoute = {}
      local AttackTasks = {}
      
      --- Calculate the target route point.
      
      local FromWP = DefenderCoord:WaypointAir( 
        self.PatrolAltType or "RADIO", 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        EngageSpeed, 
        true 
      )
      
      EngageRoute[#EngageRoute+1] = FromWP

      self:SetTargetDistance( TargetCoord ) -- For RTB status check
      
      local FromEngageAngle = TargetCoord:GetAngleDegrees( TargetCoord:GetDirectionVec3( DefenderCoord ) )
      local ToWP = TargetCoord:Translate( EngageDistance, FromEngageAngle, true ):WaypointAir( 
        self.PatrolAltType or "RADIO", 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        EngageSpeed, 
        true 
      )

      EngageRoute[#EngageRoute+1] = ToWP

      local AttackUnitTasks = {}

      local AttackSetUnitPerThreatLevel = AttackSetUnit:GetSetPerThreatLevel( 10, 0 )
      for AttackUnitIndex, AttackUnit in ipairs( AttackSetUnitPerThreatLevel or {} ) do
        if AttackUnit then
          if AttackUnit:IsAlive() and AttackUnit:IsGround() then
            self:T( { "BAI Unit:", AttackUnit:GetName() } )
            AttackUnitTasks[#AttackUnitTasks+1] = DefenderGroup:TaskAttackUnit( AttackUnit, true, false, nil, nil, EngageAltitude )
          end
        end
      end
      
      if #AttackUnitTasks == 0 then
        self:E( DefenderGroupName .. ": No targets found -> Going RTB")
        self:Return()
        self:__RTB( self.TaskDelay )
      else
        DefenderGroup:OptionROEOpenFire()
        DefenderGroup:OptionROTEvadeFire()
        DefenderGroup:OptionKeepWeaponsOnThreat()

        AttackTasks[#AttackTasks+1] = DefenderGroup:TaskCombo( AttackUnitTasks )
      end

      AttackTasks[#AttackTasks+1] = DefenderGroup:TaskFunction( "AI_A2G_ENGAGE.___Engage", self, AttackSetUnit )
      EngageRoute[#EngageRoute].task = DefenderGroup:TaskCombo( AttackTasks )
      
      DefenderGroup:Route( EngageRoute, self.TaskDelay )
    end
  else
    self:E( DefenderGroupName .. ": No targets found -> Going RTB")
    self:Return()
    self:__RTB( self.TaskDelay )
  end
end
