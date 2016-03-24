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
-- @type
--
ESCORT = {
  ClassName = "ESCORT",
  EscortName = nil, -- The Escort Name
  Targets = {}, -- The identified targets
}

--- ESCORT class constructor for an AI group
-- @param self
-- @param #CLIENT EscortClient The client escorted by the EscortGroup.
-- @param #GROUP EscortGroup The group AI escorting the EscortClient.
-- @param #string EscortName Name of the escort.
-- @return #ESCORT self
function ESCORT:New( EscortClient, EscortGroup, EscortName )
  local self = BASE:Inherit( self, BASE:New() )
  self:T( { EscortClient, EscortGroup, EscortName } )
  
  self.EscortClient = EscortClient
  self.EscortGroup = EscortGroup
  self.EscortName = EscortName
  self.ReportTargets = true
 
   -- Escort Navigation  
  self.EscortMenu = MENU_SUB_GROUP:New( self.EscortClient, "Escort" .. self.EscortName )
  self.EscortMenuHoldPosition = MENU_COMMAND_GROUP:New( self.EscortClient, "Hold Position and Stay Low", self.EscortMenu, ESCORT._HoldPosition, { ParamSelf = self } )

  -- Report Targets
  self.EscortMenuReportNearbyTargets = MENU_SUB_GROUP:New( self.EscortClient, "Report Targets", self.EscortMenu )
  self.EscortMenuReportNearbyTargetsOn = MENU_COMMAND_GROUP:New( self.EscortClient, "Report Targets On", self.EscortMenuReportNearbyTargets, ESCORT._ReportNearbyTargets, { ParamSelf = self, ParamReportTargets = true } )
  self.EscortMenuReportNearbyTargetsOff = MENU_COMMAND_GROUP:New( self.EscortClient, "Report Targets Off", self.EscortMenuReportNearbyTargets, ESCORT._ReportNearbyTargets, { ParamSelf = self, ParamReportTargets = false, } )

  -- Attack Targets
  self.EscortMenuAttackNearbyTargets = MENU_SUB_GROUP:New( self.EscortClient, "Attack nearby targets", self.EscortMenu )
  self.EscortMenuAttackTargets =  {} 
  self.Targets = {}

  -- Rules of Engagement
  self.EscortMenuROE = MENU_SUB_GROUP:New( self.EscortClient, "ROE", self.EscortMenu )
  self.EscortMenuROEHoldFire = MENU_COMMAND_GROUP:New( self.EscortClient, "Hold Fire", self.EscortMenuROE, ESCORT._ROEHoldFire, { ParamSelf = self, } )
  self.EscortMenuROEReturnFire = MENU_COMMAND_GROUP:New( self.EscortClient, "Return Fire", self.EscortMenuROE, ESCORT._ROEReturnFire, { ParamSelf = self, } )
  self.EscortMenuROEOpenFire = MENU_COMMAND_GROUP:New( self.EscortClient, "Open Fire", self.EscortMenuROE, ESCORT._ROEOpenFire, { ParamSelf = self, } )
  self.EscortMenuROEWeaponFree = MENU_COMMAND_GROUP:New( self.EscortClient, "Weapon Free", self.EscortMenuROE, ESCORT._ROEWeaponFree, { ParamSelf = self, } )
  
  -- Reaction to Threats
  self.EscortMenuEvasion = MENU_SUB_GROUP:New( self.EscortClient, "Evasion", self.EscortMenu )
  self.EscortMenuEvasionNoReaction = MENU_COMMAND_GROUP:New( self.EscortClient, "Fight until death", self.EscortMenuEvasion, ESCORT._EvasionNoReaction, { ParamSelf = self, } )
  self.EscortMenuEvasionPassiveDefense = MENU_COMMAND_GROUP:New( self.EscortClient, "Use flares, chaff and jammers", self.EscortMenuEvasion, ESCORT._EvasionPassiveDefense, { ParamSelf = self, } )
  self.EscortMenuEvasionEvadeFire = MENU_COMMAND_GROUP:New( self.EscortClient, "Evade enemy fire", self.EscortMenuEvasion, ESCORT._EvasionEvadeFire, { ParamSelf = self, } )
  self.EscortMenuEvasionVertical = MENU_COMMAND_GROUP:New( self.EscortClient, "Go below radar and evade fire", self.EscortMenuEvasion, ESCORT._EvasionVertical, { ParamSelf = self, } )
  
  
  self.ScanForTargetsFunction = routines.scheduleFunction( self._ScanForTargets, { self }, timer.getTime() + 1, 30 )
end

function ESCORT._HoldPosition( MenuParam )

  MenuParam.ParamSelf.EscortGroup:HoldPosition( 300 )
  MESSAGE:New( "Holding Position at ... for 5 minutes.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/HoldPosition" ):ToClient( MenuParam.ParamSelf.EscortClient )
end

function ESCORT._ReportNearbyTargets( MenuParam )
  MenuParam.ParamSelf:T()
  
  MenuParam.ParamSelf.ReportTargets = MenuParam.ParamReportTargets

end

function ESCORT._AttackTarget( MenuParam )

  MenuParam.ParamSelf.EscortGroup:AttackUnit( MenuParam.ParamUnit )
  MESSAGE:New( "Attacking Unit", MenuParam.ParamSelf.EscortName, 10, "ESCORT/AttackUnit" ):ToClient( MenuParam.ParamSelf.EscortClient )
end

function ESCORT._ROEHoldFire( MenuParam )

  MenuParam.ParamSelf.EscortGroup:HoldFire()
  MESSAGE:New( "Holding weapons.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/AttackUnit" ):ToClient( MenuParam.ParamSelf.EscortClient )
end

function ESCORT._ROEReturnFire( MenuParam )

  MenuParam.ParamSelf.EscortGroup:ReturnFire()
  MESSAGE:New( "Returning enemy fire.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/AttackUnit" ):ToClient( MenuParam.ParamSelf.EscortClient )
end

function ESCORT._ROEOpenFire( MenuParam )

  MenuParam.ParamSelf.EscortGroup:OpenFire()
  MESSAGE:New( "Open fire on ordered targets.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/AttackUnit" ):ToClient( MenuParam.ParamSelf.EscortClient )
end

function ESCORT._ROEWeaponFree( MenuParam )

  MenuParam.ParamSelf.EscortGroup:WeaponFree()
  MESSAGE:New( "Engaging targets.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/AttackUnit" ):ToClient( MenuParam.ParamSelf.EscortClient )
end

function ESCORT._EvasionNoReaction( MenuParam )

  MenuParam.ParamSelf.EscortGroup:EvasionNoReaction()
  MESSAGE:New( "We'll fight until death.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/AttackUnit" ):ToClient( MenuParam.ParamSelf.EscortClient )
end

function ESCORT._EvasionPassiveDefense( MenuParam )

  MenuParam.ParamSelf.EscortGroup:EvasionPassiveDefense()
  MESSAGE:New( "We will use flares, chaff and jammers.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/AttackUnit" ):ToClient( MenuParam.ParamSelf.EscortClient )
end

function ESCORT._EvasionEvadeFire( MenuParam )

  MenuParam.ParamSelf.EscortGroup:EvasionEvadeFire()
  MESSAGE:New( "We'll evade enemy fire.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/AttackUnit" ):ToClient( MenuParam.ParamSelf.EscortClient )
end

function ESCORT._EvasionVertical( MenuParam )

  MenuParam.ParamSelf.EscortGroup:EvasionVertical()
  MESSAGE:New( "We'll perform vertical evasive manoeuvres.", MenuParam.ParamSelf.EscortName, 10, "ESCORT/AttackUnit" ):ToClient( MenuParam.ParamSelf.EscortClient )
end


function ESCORT:_ScanForTargets()
  self:T()

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
          MENU_COMMAND_GROUP:New( self.EscortClient,
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
