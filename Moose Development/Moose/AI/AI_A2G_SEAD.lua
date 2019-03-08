--- **AI** -- Models the process of air to ground SEAD engagement for airplanes and helicopters.
--
-- This is a class used in the @{AI_A2G_Dispatcher}.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_A2G_SEAD
-- @image AI_Air_To_Ground_Engage.JPG



--- @type AI_A2G_SEAD
-- @extends AI.AI_A2G_Patrol#AI_A2G_PATROL


--- Implements the core functions to SEAD intruders. Use the Engage trigger to intercept intruders.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia3.JPG)
-- 
-- The AI_A2G_SEAD is assigned a @{Wrapper.Group} and this must be done before the AI_A2G_SEAD process can be started using the **Start** event.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia4.JPG)
-- 
-- The AI will fly towards the random 3D point within the patrol zone, using a random speed within the given altitude and speed limits.
-- Upon arrival at the 3D point, a new random 3D point will be selected within the patrol zone using the given limits.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia5.JPG)
-- 
-- This cycle will continue.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia6.JPG)
-- 
-- During the patrol, the AI will detect enemy targets, which are reported through the **Detected** event.
--
-- ![Process](..\Presentations\AI_GCI\Dia9.JPG)
-- 
-- When enemies are detected, the AI will automatically engage the enemy.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia10.JPG)
-- 
-- Until a fuel or damage treshold has been reached by the AI, or when the AI is commanded to RTB.
-- When the fuel treshold has been reached, the airplane will fly towards the nearest friendly airbase and will land.
-- 
-- ![Process](..\Presentations\AI_GCI\Dia13.JPG)
-- 
-- ## 1. AI_A2G_SEAD constructor
--   
--   * @{#AI_A2G_SEAD.New}(): Creates a new AI_A2G_SEAD object.
--
-- ## 3. Set the Range of Engagement
-- 
-- ![Range](..\Presentations\AI_GCI\Dia11.JPG)
-- 
-- An optional range can be set in meters, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- The range can be beyond or smaller than the range of the Patrol Zone.
-- The range is applied at the position of the AI.
-- Use the method @{AI.AI_GCI#AI_A2G_SEAD.SetEngageRange}() to define that range.
--
-- ## 4. Set the Zone of Engagement
-- 
-- ![Zone](..\Presentations\AI_GCI\Dia12.JPG)
-- 
-- An optional @{Zone} can be set, 
-- that will define when the AI will engage with the detected airborne enemy targets.
-- Use the method @{AI.AI_Cap#AI_A2G_SEAD.SetEngageZone}() to define that Zone.
--  
-- ===
-- 
-- @field #AI_A2G_SEAD
AI_A2G_SEAD = {
  ClassName = "AI_A2G_SEAD",
}



--- Creates a new AI_A2G_SEAD object
-- @param #AI_A2G_SEAD self
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
-- @return #AI_A2G_SEAD
function AI_A2G_SEAD:New( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType )

  -- Inherits from BASE
  local self = BASE:Inherit( self, AI_A2G_PATROL:New( AIGroup, EngageMinSpeed, EngageMaxSpeed, EngageFloorAltitude, EngageCeilingAltitude, PatrolZone, PatrolFloorAltitude, PatrolCeilingAltitude, PatrolMinSpeed, PatrolMaxSpeed, PatrolAltType ) ) -- #AI_A2G_SEAD

  local RTBSpeedMax = AIGroup:GetSpeedMax() or 9999

  self:SetRTBSpeed( RTBSpeedMax * 0.50, RTBSpeedMax * 0.75 )

  return self
end



--- @param #AI_A2G_SEAD self
-- @param Wrapper.Group#GROUP DefenderGroup The GroupGroup managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2G_SEAD:onafterEngage( DefenderGroup, From, Event, To, AttackSetUnit )

  self:F( { DefenderGroup, From, Event, To, AttackSetUnit} )
  
  local DefenderGroupName = DefenderGroup:GetName()

  local AttackCount = AttackSetUnit:Count()
  
  if AttackCount > 0 then

    if DefenderGroup:IsAlive() then
    
      -- Determine the distance to the target.
      -- If it is less than 50km, then attack without a route.
      -- Otherwise perform a route attack.

      local EngageAltitude = math.random( self.EngageFloorAltitude or 500, self.EngageCeilingAltitude or 1000 )
      local EngageSpeed = math.random( self.EngageMinSpeed, self.EngageMaxSpeed )

      local DefenderCoord = DefenderGroup:GetPointVec3()
      DefenderCoord:SetY( EngageAltitude ) -- Ground targets don't have an altitude.

      local TargetCoord = AttackSetUnit:GetFirst():GetPointVec3()
      TargetCoord:SetY( EngageAltitude  ) -- Ground targets don't have an altitude.
      
      local TargetDistance = DefenderCoord:Get2DDistance( TargetCoord )
      local EngageDistance = ( DefenderGroup:IsHelicopter() and 5000 ) or ( DefenderGroup:IsAirPlane() and 25000 )

      local EngageRoute = {}
      local AttackTasks = {}
      
      local FromWP = DefenderCoord:WaypointAir( 
        self.PatrolAltType or "RADIO", 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        EngageSpeed, 
        false 
      )
      EngageRoute[#EngageRoute+1] = FromWP

      self:SetTargetDistance( TargetCoord ) -- For RTB status check

      local FromEngageAngle = DefenderCoord:GetAngleDegrees( DefenderCoord:GetDirectionVec3( TargetCoord ) )
      local ToWP = DefenderCoord:Translate( EngageDistance, FromEngageAngle, true ):WaypointAir( 
        self.PatrolAltType or "RADIO", 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        EngageSpeed, 
        true 
      )
      EngageRoute[#EngageRoute+1] = ToWP

      if TargetDistance <= EngageDistance * 3 then
    
        local AttackUnitTasks = {}
    
        local AttackSetUnitPerThreatLevel = AttackSetUnit:GetSetPerThreatLevel( 10, 0 )
        for AttackUnitID, AttackUnit in ipairs( AttackSetUnitPerThreatLevel ) do
          if AttackUnit then
            if AttackUnit:IsAlive() and AttackUnit:IsGround() then
              local HasRadar = AttackUnit:HasSEAD() 
              if HasRadar then
                self:F( { "SEAD Unit:", AttackUnit:GetName() } )
                AttackUnitTasks[#AttackUnitTasks+1] = DefenderGroup:TaskAttackUnit( AttackUnit, true, false, nil, nil, EngageAltitude )
              end
            end
          end
        end
          
        if #AttackUnitTasks == 0 then
          self:E( DefenderGroupName .. ": No targets found -> Going RTB")
          self:Return()
          self:__RTB( self.TaskDelay )
        else
          DefenderGroup:OptionROEOpenFire()
          DefenderGroup:OptionROTVertical()
          DefenderGroup:OptionKeepWeaponsOnThreat()
          --DefenderGroup:OptionRTBAmmo( Weapon.flag.AnyASM )
  
          AttackTasks[#AttackTasks+1] = DefenderGroup:TaskCombo( AttackUnitTasks )
        end
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

