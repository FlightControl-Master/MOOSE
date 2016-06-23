
local FACGroup = GROUP:FindByName( "FAC Group Lase" )

local FACDetection = DETECTION_BASE:New( FACGroup, 1000, 250 )


local LaseScheduler = SCHEDULER:New(nil,
  --- @param Group#GROUP FACGroup
  -- @param Detection#DETECTION_BASE FACDetection
  function( FACGroup, FACDetection )
    if FACDetection:GetDetectionUnitSetCount() > 0 then
      local DetectedUnitSet = FACDetection:GetDetectionUnitSet(1)
      if DetectedUnitSet then
        FACDetection:E( { "I have a unit set ", DetectedUnitSet } )
        local FACUnit = FACGroup:GetUnit(1)
        if FACUnit then
          FACDetection:E( FACUnit )
          local FACDCSUnit = FACUnit:GetDCSUnit()
          local FACUnitController = FACDCSUnit:getController()
          DetectedUnitSet:ForEachUnit(
            --- @param Unit#UNIT DetectedUnit
            function( DetectedUnit, FACDCSUnit )
              FACDetection:E( DetectedUnit:GetDCSUnit() )
              FACDetection:E( FACDCSUnit )
              local JTAC = Spot.createInfraRed( FACDCSUnit, {x = 0, y = 2.0, z = 0}, DetectedUnit:GetPointVec3(), 1337)
            end, FACDCSUnit
          )
        end
      end
    end
  end, { FACGroup, FACDetection },
  30
  )

local LaseScheduler2 = SCHEDULER:New(nil,
  --- @param Group#GROUP FACGroup
  -- @param Detection#DETECTION_BASE FACDetection
  function( FACGroup, FACDetection )
    if FACDetection:GetDetectionUnitSetCount() > 0 then
      local DetectedUnitSet = FACDetection:GetDetectionUnitSet(1)
      if DetectedUnitSet then
        FACDetection:E( { "I have a unit set ", DetectedUnitSet } )
        local FACUnit = FACGroup:GetUnit(1)
        if FACUnit then
          FACDetection:E( FACUnit )
          local FACDCSUnit = FACUnit:GetDCSUnit()
          local FACUnitController = FACDCSUnit:getController()
          DetectedUnitSet:ForEachUnit(
            --- @param Unit#UNIT DetectedUnit
            function( DetectedUnit, FACDCSUnit )
              FACDetection:E( DetectedUnit:GetDCSUnit() )
              FACDetection:E( FACDCSUnit )
              local TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity
                    = FACUnitController:isTargetDetected( DetectedUnit:GetDCSUnit(), Controller.Detection.IRST )
              FACDetection:E( { TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity } )
            end, FACDCSUnit
          )
        end
      end
    end
  end, { FACGroup, FACDetection },
  40
  )