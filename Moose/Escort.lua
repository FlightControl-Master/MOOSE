--- Taking the lead of AI escorting your flight.
-- The ESCORT class allows you to interact with escoring AI on your flight and take the lead.
-- The following commands will be available:
-- 
-- * Pop-up and Scan Area
-- * Re-Join Formation
-- * Hold Position in x km
-- * Report identified targets
-- * Perform tasks per identified target: Report vector to target, paint target, kill target
-- 
-- @module ESCORT
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Database" )
Include.File( "Group" )
Include.File( "Zone" )

--- ESCORT class
-- @type ESCORT
-- @extends Base#BASE
-- @field Client#CLIENT EscortClient
-- @field Group#GROUP EscortGroup
-- @field #string EscortName
ESCORT = {
  ClassName = "ESCORT",
  EscortName = nil, -- The Escort Name
  EscortClient = nil,
  EscortGroup = nil,
  Targets = {}, -- The identified targets
}

--- MENUPARAM type
-- @type MENUPARAM
-- @field #ESCORT ParamSelf

--- ESCORT class constructor for an AI group
-- @param self
-- @param Client#CLIENT EscortClient The client escorted by the EscortGroup.
-- @param Group#GROUP EscortGroup The group AI escorting the EscortClient.
-- @param #string EscortName Name of the escort.
-- @return #ESCORT self
function ESCORT:New( EscortClient, EscortGroup, EscortName )
  local self = BASE:Inherit( self, BASE:New() )
	self:F( { EscortClient, EscortGroup, EscortName } )
  
  self.EscortClient = EscortClient
  self.EscortGroup = EscortGroup
  self.EscortName = EscortName
  self.ReportTargets = true

  self.EscortMenu = MENU_CLIENT:New( self.EscortClient, "Escort" .. self.EscortName )
 
   -- Escort Navigation  
  self.EscortMenuReportNavigation = MENU_CLIENT:New( self.EscortClient, "Navigation", self.EscortMenu )
  self.EscortMenuHoldPosition = MENU_CLIENT_COMMAND:New( self.EscortClient, "Hold Position and Stay Low", self.EscortMenuReportNavigation, ESCORT._HoldPosition, { ParamSelf = self } )
  self.EscortMenuJoinUpAndHoldPosition = MENU_CLIENT_COMMAND:New( self.EscortClient, "Join-Up and Hold Position NearBy", self.EscortMenuReportNavigation, ESCORT._HoldPositionNearBy, { ParamSelf = self } )  
  self.EscortMenuJoinUpAndFollow = MENU_CLIENT_COMMAND:New( self.EscortClient, "Join-Up and Follow", self.EscortMenuReportNavigation, ESCORT._JoinUpAndFollow, { ParamSelf = self } )  

  -- Report Targets
  self.EscortMenuReportNearbyTargets = MENU_CLIENT:New( self.EscortClient, "Report targets", self.EscortMenu )
  self.EscortMenuReportNearbyTargetsOn = MENU_CLIENT_COMMAND:New( self.EscortClient, "Report targets on", self.EscortMenuReportNearbyTargets, ESCORT._ReportNearbyTargets, { ParamSelf = self, ParamReportTargets = true } )
  self.EscortMenuReportNearbyTargetsOff = MENU_CLIENT_COMMAND:New( self.EscortClient, "Report targets off", self.EscortMenuReportNearbyTargets, ESCORT._ReportNearbyTargets, { ParamSelf = self, ParamReportTargets = false, } )

  -- Scanning Targets
  self.EscortMenuScanForTargets = MENU_CLIENT:New( self.EscortClient, "Scan targets", self.EscortMenu )
  self.EscortMenuReportNearbyTargetsOn = MENU_CLIENT_COMMAND:New( self.EscortClient, "Scan targets 30 seconds", self.EscortMenuScanForTargets, ESCORT._ScanTargets30Seconds, { ParamSelf = self, ParamScanDuration = 30 } )
  self.EscortMenuReportNearbyTargetsOn = MENU_CLIENT_COMMAND:New( self.EscortClient, "Scan targets 60 seconds", self.EscortMenuScanForTargets, ESCORT._ScanTargets60Seconds, { ParamSelf = self, ParamScanDuration = 30 } )

  -- Attack Targets
  self.EscortMenuAttackNearbyTargets = MENU_CLIENT:New( self.EscortClient, "Attack nearby targets", self.EscortMenu )
  self.EscortMenuAttackTargets =  {} 
  self.Targets = {}

  -- Rules of Engagement
  self.EscortMenuROE = MENU_CLIENT:New( self.EscortClient, "ROE", self.EscortMenu )
  self.EscortMenuROEHoldFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Hold Fire", self.EscortMenuROE, ESCORT._ROEHoldFire, { ParamSelf = self, } )
  self.EscortMenuROEReturnFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Return Fire", self.EscortMenuROE, ESCORT._ROEReturnFire, { ParamSelf = self, } )
  self.EscortMenuROEOpenFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Open Fire", self.EscortMenuROE, ESCORT._ROEOpenFire, { ParamSelf = self, } )
  self.EscortMenuROEWeaponFree = MENU_CLIENT_COMMAND:New( self.EscortClient, "Weapon Free", self.EscortMenuROE, ESCORT._ROEWeaponFree, { ParamSelf = self, } )
  
  -- Reaction to Threats
  self.EscortMenuEvasion = MENU_CLIENT:New( self.EscortClient, "Evasion", self.EscortMenu )
  self.EscortMenuEvasionNoReaction = MENU_CLIENT_COMMAND:New( self.EscortClient, "Fight until death", self.EscortMenuEvasion, ESCORT._EvasionNoReaction, { ParamSelf = self, } )
  self.EscortMenuEvasionPassiveDefense = MENU_CLIENT_COMMAND:New( self.EscortClient, "Use flares, chaff and jammers", self.EscortMenuEvasion, ESCORT._EvasionPassiveDefense, { ParamSelf = self, } )
  self.EscortMenuEvasionEvadeFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Evade enemy fire", self.EscortMenuEvasion, ESCORT._EvasionEvadeFire, { ParamSelf = self, } )
  self.EscortMenuEvasionVertical = MENU_CLIENT_COMMAND:New( self.EscortClient, "Go below radar and evade fire", self.EscortMenuEvasion, ESCORT._EvasionVertical, { ParamSelf = self, } )
  
  -- Cancel current Task
  self.EscortMenuCancelTask = MENU_CLIENT_COMMAND:New( self.EscortClient, "Cancel current task", self.EscortMenu, ESCORT._CancelCurrentTask, { ParamSelf = self, } )
  
  
  self.ScanForTargetsFunction = routines.scheduleFunction( self._ScanForTargets, { self }, timer.getTime() + 1, 30 )
end


--- @param #MENUPARAM MenuParam
function ESCORT._HoldPosition( MenuParam )

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient
  
  EscortGroup:PushTask( EscortGroup:TaskHoldPosition( 300 ) )
  MESSAGE:New( "Holding Position at ... for 5 minutes.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/TaskHoldPosition" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._HoldPositionNearBy( MenuParam )

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient
  
  --MenuParam.ParamSelf.EscortGroup:TaskOrbitCircleAtVec2( MenuParam.ParamSelf.EscortClient:GetPointVec2(), 300, 30, 0 )
  
  local PointFrom = {}
  local GroupPoint = EscortGroup:GetPointVec2()
  PointFrom = {}
  PointFrom.x = GroupPoint.x
  PointFrom.y = GroupPoint.y
  PointFrom.speed = 250
  PointFrom.type = AI.Task.WaypointType.TURNING_POINT
  PointFrom.alt = EscortClient:GetAltitude()
  PointFrom.alt_type = AI.Task.AltitudeType.BARO

  local ClientPoint = MenuParam.ParamSelf.EscortClient:GetPointVec2()
  local PointTo = {}
  PointTo.x = ClientPoint.x
  PointTo.y = ClientPoint.y
  PointTo.speed = 250
  PointTo.type = AI.Task.WaypointType.TURNING_POINT
  PointTo.alt = EscortClient:GetAltitude()
  PointTo.alt_type = AI.Task.AltitudeType.BARO
  PointTo.task = EscortGroup:TaskOrbitCircleAtVec2( EscortClient:GetPointVec2(), 300, 30, 0 )
  
  local Points = { PointFrom, PointTo }
  
  
  EscortGroup:PushTask( EscortGroup:TaskMission( Points ) )
  MESSAGE:New( "Rejoining to your location. Please hold at your location.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/HoldPositionNearBy" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._JoinUpAndFollow( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient
  
  self.CT1 = 0
  self.GT1 = 0
  self.FollowFunction = routines.scheduleFunction( self._Follower, { self }, timer.getTime() + 1, 1 )
  EscortGroup:MessageToClient( "Rejoining and following orders ...", 10, EscortClient )
end


function ESCORT._ReportNearbyTargets( MenuParam )
  MenuParam.ParamSelf:T()
  
  MenuParam.ParamSelf.ReportTargets = MenuParam.ParamReportTargets

end

--- @param #MENUPARAM MenuParam
function ESCORT._ScanTargets30Seconds( MenuParam )
  MenuParam.ParamSelf:T()

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient

  EscortGroup:PushTask( 
    EscortGroup:TaskControlled( 
      EscortGroup:TaskOrbitCircle( 200, 20 ), 
      EscortGroup:TaskCondition( nil, nil, nil, nil, 30, nil ) 
      ) 
  )
  MESSAGE:New( "Scanning targets for 30 seconds.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/ScanTargets30Seconds" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._ScanTargets60Seconds( MenuParam )
  MenuParam.ParamSelf:T()

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient

  EscortGroup:PushTask( 
    EscortGroup:TaskControlled( 
      EscortGroup:TaskOrbitCircle( 200, 20 ), 
      EscortGroup:TaskCondition( nil, nil, nil, nil, 60, nil ) 
      ) 
  )
  MESSAGE:New( "Scanning targets for 60 seconds.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/ScanTargets60Seconds" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._AttackTarget( MenuParam )

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient
  local AttackUnit = MenuParam.ParamUnit 
  
  EscortGroup:OpenFire()
  EscortGroup:EvasionVertical()
  EscortGroup:PushTask( EscortGroup:TaskAttackUnit( AttackUnit ) )
  MESSAGE:New( "Attacking Unit", MenuParam.ParamSelf.EscortName, 10, "ESCORT/AttackTarget" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._ROEHoldFire( MenuParam )

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient

  EscortGroup:HoldFire()
  MESSAGE:New( "Holding weapons.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/ROEHoldFire" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._ROEReturnFire( MenuParam )

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient

  EscortGroup:ReturnFire()
  MESSAGE:New( "Returning enemy fire.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/ROEReturnFire" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._ROEOpenFire( MenuParam )

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient

  EscortGroup:OpenFire()
  MESSAGE:New( "Open fire on ordered targets.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/ROEOpenFire" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._ROEWeaponFree( MenuParam )

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient

  EscortGroup:WeaponFree()
  MESSAGE:New( "Engaging targets.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/ROEWeaponFree" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._EvasionNoReaction( MenuParam )

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient

  EscortGroup:EvasionNoReaction()
  MESSAGE:New( "We'll fight until death.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/EvasionNoReaction" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._EvasionPassiveDefense( MenuParam )

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient

  EscortGroup:EvasionPassiveDefense()
  MESSAGE:New( "We will use flares, chaff and jammers.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/EvasionPassiveDefense" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._EvasionEvadeFire( MenuParam )

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient

  EscortGroup:EvasionEvadeFire()
  MESSAGE:New( "We'll evade enemy fire.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/EvasionEvadeFire" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._EvasionVertical( MenuParam )

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient

  EscortGroup:EvasionVertical()
  MESSAGE:New( "We'll perform vertical evasive manoeuvres.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/EvasionVertical" ):ToClient( EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._CancelCurrentTask( MenuParam )

  local EscortGroup = MenuParam.ParamSelf.EscortGroup
  local EscortClient = MenuParam.ParamSelf.EscortClient

  EscortGroup:PopCurrentTask()
  MESSAGE:New( "Cancelling with current orders, continuing our mission.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/CancelCurrentTask" ):ToClient( EscortClient )
end

--- @param Escort#ESCORT self
function ESCORT:_Follower()
  self:F()

  local ClientUnit = self.EscortClient:GetClientGroupUnit()
  local GroupUnit = self.EscortGroup:GetUnit( 1 )

  if self.EscortGroup:IsAlive() and ClientUnit:IsAlive() then
    if self.CT1 == 0 and self.GT1 == 0 then
      self.CV1 = ClientUnit:GetPositionVec3()
      self.CT1 = timer.getTime()
      self.GV1 = GroupUnit:GetPositionVec3()
      self.GT1 = timer.getTime()
      
    else
      local CT1 = self.CT1
      local CT2 = timer.getTime()
      local CV1 = self.CV1
      local CV2 = ClientUnit:GetPositionVec3()
      
      local CD = ( ( CV2.x - CV1.x )^2 + ( CV2.y - CV1.y )^2 + ( CV2.z - CV1.z )^2 ) ^ 0.5
      local CT = CT2 - CT1
      
      local CS = ( 3600 / CT ) * ( CD / 1000 )
      
      self:T( { "Client:", CS, CD, CT, CV2, CV1, CT2, CT1 } )
      
      local GT1 = self.GT1
      local GT2 = timer.getTime()
      local GV1 = self.GV1
      local GV2 = GroupUnit:GetPositionVec3()
      
      local GD = ( ( GV2.x - GV1.x )^2 + ( GV2.y - GV1.y )^2 + ( GV2.z - GV1.z )^2 ) ^ 0.5
      local GT = GT2 - GT1
      
      local GS = ( 3600 / GT ) * ( GD / 1000 )
      
      self:T( { "Group:", GS, GD, GT, GV2, GV1, GT2, GT1 } )
      
      -- Measure distance between client and group
      local D = ( ( CV2.x - GV2.x )^2 + ( CV2.y - GV2.y )^2 + ( CV2.z - GV2.z )^2 ) ^ 0.5 - 200
      
      local S = ( 3600 / 30 ) * ( D / 1000 ) -- We use a 2 second buffer to adjust the speed
      local A = ( CS - GS ) + S -- Accelleration required = Client Speed - Group Speed + Speed to overcome distance (with 10 second time buffer)
      local Speed = A -- Final speed is the current Group speed + Accelleration

      self:T( { "Speed:", S, A, Speed } )

      -- Now route the escort to the desired point with the desired speed.
      self.EscortGroup:TaskRouteToVec3( CV2, Speed )
    end
  else
    routines.removeFunction( self.FollowFunction )
  end

end


function ESCORT:_ScanForTargets()
	self:F()

  self.Targets = {}
  
  if self.EscortGroup:IsAlive() then
    local EscortTargets = self.EscortGroup:GetDetectedTargets()
    
    local EscortTargetMessages = ""
    for EscortTargetID, EscortTarget in pairs( EscortTargets ) do
      local EscortObject = EscortTarget.object
      self:T( EscortObject )
      if EscortObject and EscortObject:isExist() and EscortObject.id_ < 50000000 then
        
          local EscortTargetMessage = ""
        
          local EscortTargetUnit = UNIT:New( EscortObject )
        
          local EscortTargetCategoryName = EscortTargetUnit:GetCategoryName()
          local EscortTargetCategoryType = EscortTargetUnit:GetTypeName()
        
        
  --        local EscortTargetIsDetected, 
  --              EscortTargetIsVisible, 
  --              EscortTargetLastTime, 
  --              EscortTargetKnowType, 
  --              EscortTargetKnowDistance, 
  --              EscortTargetLastPos, 
  --              EscortTargetLastVelocity
  --              = self.EscortGroup:IsTargetDetected( EscortObject )
  --      
  --        self:T( { EscortTargetIsDetected, 
  --              EscortTargetIsVisible, 
  --              EscortTargetLastTime, 
  --              EscortTargetKnowType, 
  --              EscortTargetKnowDistance, 
  --              EscortTargetLastPos, 
  --              EscortTargetLastVelocity } )
        
          if EscortTarget.distance then
            local EscortTargetUnitPositionVec3 = EscortTargetUnit:GetPositionVec3()
            local EscortPositionVec3 = self.EscortGroup:GetPositionVec3()
            local Distance = routines.utils.get3DDist( EscortTargetUnitPositionVec3, EscortPositionVec3 ) / 1000
            self:T( { self.EscortGroup:GetName(), EscortTargetUnit:GetName(), Distance, EscortTarget.visible } )

            if Distance <= 8 then

              if EscortTarget.type then
                EscortTargetMessage = EscortTargetMessage .. " - " .. EscortTargetCategoryName .. " (" .. EscortTargetCategoryType .. ") at "
              else
                EscortTargetMessage = EscortTargetMessage .. " - Unknown target at "
              end

              EscortTargetMessage = EscortTargetMessage .. string.format( "%.2f", Distance ) .. " km"

              if EscortTarget.visible then
                EscortTargetMessage = EscortTargetMessage .. ", visual"
              end

              local TargetIndex = Distance*1000
              self.Targets[TargetIndex] = {}           
              self.Targets[TargetIndex].AttackMessage = EscortTargetMessage
              self.Targets[TargetIndex].AttackUnit = EscortTargetUnit        
            end
          end
  
          if EscortTargetMessage ~= "" then
            EscortTargetMessages = EscortTargetMessages .. EscortTargetMessage .. "\n"
          end
      end
    end
    
    if EscortTargetMessages ~= "" and self.ReportTargets == true then
      self.EscortClient:Message( EscortTargetMessages:gsub("\n$",""), 20, "/ESCORT.DetectedTargets", self.EscortName .. " reporting detected targets within 8 km range:", 0 )
    end

    self:T()
  
    self:T( { "Sorting Targets Table:", self.Targets } )
    table.sort( self.Targets )
    self:T( { "Sorted Targets Table:", self.Targets } )
    
    for MenuIndex = 1, #self.EscortMenuAttackTargets do
      self:T( { "Remove Menu:", self.EscortMenuAttackTargets[MenuIndex] } )
      self.EscortMenuAttackTargets[MenuIndex] = self.EscortMenuAttackTargets[MenuIndex]:Remove()
    end
    
    local MenuIndex = 1
    for TargetID, TargetData in pairs( self.Targets ) do
      self:T( { "Adding menu:", TargetID, "for Unit", self.Targets[TargetID].AttackUnit } )
      if MenuIndex <= 10 then
        self.EscortMenuAttackTargets[MenuIndex] = 
          MENU_CLIENT_COMMAND:New( self.EscortClient,
                                  self.Targets[TargetID].AttackMessage,
                                  self.EscortMenuAttackNearbyTargets,
                                  ESCORT._AttackTarget,
                                  { ParamSelf = self,
                                    ParamUnit = self.Targets[TargetID].AttackUnit 
                                  }
                                )
          self:T( { "New Menu:", self.EscortMenuAttackTargets[TargetID] } )
          MenuIndex = MenuIndex + 1
      else
        break
      end
    end

  else
    routines.removeFunction( self.ScanForTargetsFunction )
  end
end
