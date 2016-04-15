--- Taking the lead of AI escorting your flight.
-- The ESCORT class allows you to interact with escorting AI on your flight and take the lead.
-- Each escorting group can be commanded with a whole set of radio commands (radio menu in your flight, and then F10).
-- 
-- The radio commands will vary according the category of the group. The richest set of commands are with Helicopters and AirPlanes.
-- Ships and Ground troops will have a more limited set, but they can provide support through the bombing of targets designated by the other escorts.
-- 
-- Find a summary below of the current available commands:
-- 
-- **1. Navigation ...:** Escort group navigation functions:
-- 
-- * **"Hold Position and Stay Low":** Stops the escort group and they will hover 30 meters above the ground at the position they stopped.
-- * **"Join-Up and Hold Position NearBy":** The escort group will stop nearby you, and then the group will hover.
-- * **"Join-Up and Follow at 100":** The escort group fill follow you at about 100 meters, and they will follow you.
-- * **"Join-Up and Follow at 200":** The escort group fill follow you at about 200 meters, and they will follow you.
-- * **"Join-Up and Follow at 400":** The escort group fill follow you at about 400 meters, and they will follow you.
-- * **"Join-Up and Follow at 800":** The escort group fill follow you at about 800 meters, and they will follow you.
-- * **"Flare":** Provides menu commands to let the escort group shoot a flare in the air in a color.
-- * **"Smoke":** Provides menu commands to let the escort group smoke the air in a color. Note that smoking is only available for ground and naval troops.
-- 
-- **2. Report targets ...:** Report targets will make the escort group to report any target that it identifies within a 8km range. Any detected target can be attacked using the 4. Attack nearby targets function. (see below).
-- 
-- * **"Report now":** Will report the current detected targets.
-- * **"Report targets on":** Will make the escort group to report detected targets and will fill the "Attack nearby targets" menu list.
-- * **"Report targets off":** Will stop detecting targets.
-- 
-- **3. Scan targets ...:** Menu items to pop-up the escort group for target scanning. After scanning, the escort group will resume with the mission or defined task.
-- 
-- * **"Scan targets 30 seconds":** Scan 30 seconds for targets.
-- * **"Scan targets 60 seconds":** Scan 60 seconds for targets.
-- 
-- **4. Attack targets ...:** This menu item will list all detected targets within a 15km range. Depending on the level of detection (known/unknown) and visuality, the targets type will also be listed.
-- 
-- **5. Request assistance from ...:** This menu item will list all detected targets within a 15km range, as with the menu item **Attack Targets**.
-- This menu item allows to request attack support from other escorts supporting the current client group.
-- eg. the function allows a player to request support from the Ship escort to attack a target identified by the Plane escort with its Tomahawk missiles.
-- eg. the function allows a player to request support from other Planes escorting to bomb the unit with illumination missiles or bombs, so that the main plane escort can attack the area.
-- 
-- **6. ROE ...:** Defines the Rules of Engagement of the escort group when in flight.
-- 
-- * **"Hold Fire":** The escort group will hold fire.
-- * **"Return Fire":** The escort group will return fire.
-- * **"Open Fire":** The escort group will open fire on designated targets.
-- * **"Weapon Free":** The escort group will engage with any target.
-- 
-- **7. Evasion ...:** Will define the evasion techniques that the escort group will perform during flight or combat.
-- 
-- * **"Fight until death":** The escort group will have no reaction to threats.
-- * **"Use flares, chaff and jammers":** The escort group will use passive defense using flares and jammers. No evasive manoeuvres are executed.
-- * **"Evade enemy fire":** The rescort group will evade enemy fire before firing.
-- * **"Go below radar and evade fire":** The escort group will perform evasive vertical manoeuvres.
-- 
-- **8. Resume Mission ...:** Escort groups can have their own mission. This menu item will allow the escort group to resume their Mission from a given waypoint. 
-- Note that this is really fantastic, as you now have the dynamic of taking control of the escort groups, and allowing them to resume their path or mission.
-- 
-- **9. Abort Current Task:** Cancel the current task and rejoin formation.
-- 
-- 1. ESCORT object construction methods.
-- --------------------------------------
-- Create a new SPAWN object with the @{#ESCORT.New} method:
-- 
--  * @{#ESCORT.New}: Creates a new ESCORT object from a @{Group#GROUP} for a @{Client#CLIENT}, with an optional briefing text.
--  
-- 2. ESCORT object initialization methods.
-- ----------------------------------------
-- None.
-- 
-- 
-- @module Escort
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
-- @field #number FollowScheduler The id of the _FollowScheduler function.
-- @field #boolean ReportTargets If true, nearby targets are reported.
-- @Field DCSTypes#AI.Option.Air.val.ROE OptionROE Which ROE is set to the EscortGroup.
-- @field DCSTypes#AI.Option.Air.val.REACTION_ON_THREAT OptionReactionOnThreat Which REACTION_ON_THREAT is set to the EscortGroup.
-- @field Menu#MENU_CLIENT EscortMenuResumeMission
ESCORT = {
  ClassName = "ESCORT",
  EscortName = nil, -- The Escort Name
  EscortClient = nil,
  EscortGroup = nil,
  Targets = {}, -- The identified targets
  FollowScheduler = nil,
  ReportTargets = true,
  OptionROE = AI.Option.Air.val.ROE.OPEN_FIRE,
  OptionReactionOnThreat = AI.Option.Air.val.REACTION_ON_THREAT.ALLOW_ABORT_MISSION,
  TaskPoints = {}
}

--- MENUPARAM type
-- @type MENUPARAM
-- @field #ESCORT ParamSelf
-- @field #Distance ParamDistance
-- @field #function ParamFunction
-- @field #string ParamMessage

--- ESCORT class constructor for an AI group
-- @param #ESCORT self
-- @param Client#CLIENT EscortClient The client escorted by the EscortGroup.
-- @param Group#GROUP EscortGroup The group AI escorting the EscortClient.
-- @param #string EscortName Name of the escort.
-- @return #ESCORT self
function ESCORT:New( EscortClient, EscortGroup, EscortName, EscortBriefing )
  local self = BASE:Inherit( self, BASE:New() )
	self:F( { EscortClient, EscortGroup, EscortName } )
  
  self.EscortClient = EscortClient -- Client#CLIENT
  self.EscortGroup = EscortGroup -- Group#GROUP
  self.EscortName = EscortName
  self.EscortBriefing = EscortBriefing
  
  self:T( EscortGroup:GetClassNameAndID() )
 
  -- Set EscortGroup known at EscortClient.
  if not self.EscortClient._EscortGroups then
     self.EscortClient._EscortGroups = {}
  end

  if not self.EscortClient._EscortGroups[EscortGroup:GetName()] then
     self.EscortClient._EscortGroups[EscortGroup:GetName()] = {}
     self.EscortClient._EscortGroups[EscortGroup:GetName()].EscortGroup = self.EscortGroup
     self.EscortClient._EscortGroups[EscortGroup:GetName()].EscortName = self.EscortName
     self.EscortClient._EscortGroups[EscortGroup:GetName()].Targets = {}
     
  end
  
  
  self.EscortMenu = MENU_CLIENT:New( self.EscortClient, self.EscortName )
  
  self.EscortMenuReportNavigation = MENU_CLIENT:New( self.EscortClient, "Navigation", self.EscortMenu )
  if EscortGroup:IsHelicopter() or EscortGroup:IsAirPlane() then
     -- Escort Navigation  
    self.EscortMenuHoldPosition = MENU_CLIENT_COMMAND:New( self.EscortClient, "Hold Position and Stay Low", self.EscortMenuReportNavigation, ESCORT._HoldPosition, { ParamSelf = self } )
    self.EscortMenuJoinUpAndHoldPosition = MENU_CLIENT_COMMAND:New( self.EscortClient, "Join-Up and Hold Position NearBy", self.EscortMenuReportNavigation, ESCORT._HoldPositionNearBy, { ParamSelf = self } )  
    self.EscortMenuJoinUpAndFollow50Meters = MENU_CLIENT_COMMAND:New( self.EscortClient, "Join-Up and Follow at 100", self.EscortMenuReportNavigation, ESCORT._JoinUpAndFollow, { ParamSelf = self, ParamDistance = 100 } )  
    self.EscortMenuJoinUpAndFollow100Meters = MENU_CLIENT_COMMAND:New( self.EscortClient, "Join-Up and Follow at 200", self.EscortMenuReportNavigation, ESCORT._JoinUpAndFollow, { ParamSelf = self, ParamDistance = 200 } )  
    self.EscortMenuJoinUpAndFollow150Meters = MENU_CLIENT_COMMAND:New( self.EscortClient, "Join-Up and Follow at 400", self.EscortMenuReportNavigation, ESCORT._JoinUpAndFollow, { ParamSelf = self, ParamDistance = 400 } )  
    self.EscortMenuJoinUpAndFollow200Meters = MENU_CLIENT_COMMAND:New( self.EscortClient, "Join-Up and Follow at 800", self.EscortMenuReportNavigation, ESCORT._JoinUpAndFollow, { ParamSelf = self, ParamDistance = 800 } )  
  end
  self.EscortMenuFlare = MENU_CLIENT:New( self.EscortClient, "Flare", self.EscortMenuReportNavigation, ESCORT._Flare, { ParamSelf = self } )  
  self.EscortMenuFlareGreen  = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release green flare",  self.EscortMenuFlare, ESCORT._Flare, { ParamSelf = self, ParamColor = UNIT.FlareColor.Green,  ParamMessage = "Released a green flare!"   } )  
  self.EscortMenuFlareRed    = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release red flare",    self.EscortMenuFlare, ESCORT._Flare, { ParamSelf = self, ParamColor = UNIT.FlareColor.Red,    ParamMessage = "Released a red flare!"     } )  
  self.EscortMenuFlareWhite  = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release white flare",  self.EscortMenuFlare, ESCORT._Flare, { ParamSelf = self, ParamColor = UNIT.FlareColor.White,  ParamMessage = "Released a white flare!"   } )  
  self.EscortMenuFlareYellow = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release yellow flare", self.EscortMenuFlare, ESCORT._Flare, { ParamSelf = self, ParamColor = UNIT.FlareColor.Yellow, ParamMessage = "Released a yellow flare!"  } )  

  if EscortGroup:IsGround() or EscortGroup:IsShip() then
    self.EscortMenuSmoke = MENU_CLIENT:New( self.EscortClient, "Smoke", self.EscortMenuReportNavigation, ESCORT._Smoke, { ParamSelf = self } )  
    self.EscortMenuSmokeGreen  = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release green smoke",  self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.Green,  ParamMessage = "Releasing green smoke!"   } )  
    self.EscortMenuSmokeRed    = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release red smoke",    self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.Red,    ParamMessage = "Releasing red smoke!"     } )  
    self.EscortMenuSmokeWhite  = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release white smoke",  self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.White,  ParamMessage = "Releasing white smoke!"   } )  
    self.EscortMenuSmokeOrange = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release orange smoke", self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.Orange, ParamMessage = "Releasing orange smoke!"  } )  
    self.EscortMenuSmokeBlue   = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release blue smoke",   self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.Blue,   ParamMessage = "Releasing blue smoke!"   } )  
  end
  
  if EscortGroup:IsHelicopter() or EscortGroup:IsAirPlane() or EscortGroup:IsGround() or EscortGroup:IsShip() then
    -- Report Targets
    self.EscortMenuReportNearbyTargets = MENU_CLIENT:New( self.EscortClient, "Report targets", self.EscortMenu )
    self.EscortMenuReportNearbyTargetsNow = MENU_CLIENT_COMMAND:New( self.EscortClient, "Report targets now!", self.EscortMenuReportNearbyTargets, ESCORT._ReportNearbyTargetsNow, { ParamSelf = self } )
    self.EscortMenuReportNearbyTargetsOn = MENU_CLIENT_COMMAND:New( self.EscortClient, "Report targets on", self.EscortMenuReportNearbyTargets, ESCORT._SwitchReportNearbyTargets, { ParamSelf = self, ParamReportTargets = true } )
    self.EscortMenuReportNearbyTargetsOff = MENU_CLIENT_COMMAND:New( self.EscortClient, "Report targets off", self.EscortMenuReportNearbyTargets, ESCORT._SwitchReportNearbyTargets, { ParamSelf = self, ParamReportTargets = false, } )
  end

  if EscortGroup:IsHelicopter() then
    -- Scanning Targets
    self.EscortMenuScanForTargets = MENU_CLIENT:New( self.EscortClient, "Scan targets", self.EscortMenu )
    self.EscortMenuReportNearbyTargetsOn = MENU_CLIENT_COMMAND:New( self.EscortClient, "Scan targets 30 seconds", self.EscortMenuScanForTargets, ESCORT._ScanTargets, { ParamSelf = self, ParamScanDuration = 30 } )
    self.EscortMenuReportNearbyTargetsOn = MENU_CLIENT_COMMAND:New( self.EscortClient, "Scan targets 60 seconds", self.EscortMenuScanForTargets, ESCORT._ScanTargets, { ParamSelf = self, ParamScanDuration = 60 } )
  end
  
  -- Attack Targets
  self.EscortMenuAttackNearbyTargets = MENU_CLIENT:New( self.EscortClient, "Attack targets", self.EscortMenu )

  -- Request assistance from other escorts. 
  -- This is very useful to let f.e. an escorting ship attack a target detected by an escorting plane...
  self.EscortMenuTargetAssistance = MENU_CLIENT:New( self.EscortClient, "Request assistance from", self.EscortMenu )
 

  -- Rules of Engagement
  self.EscortMenuROE = MENU_CLIENT:New( self.EscortClient, "ROE", self.EscortMenu )
  if EscortGroup:OptionROEHoldFirePossible() then
    self.EscortMenuROEHoldFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Hold Fire", self.EscortMenuROE, ESCORT._ROE, { ParamSelf = self, ParamFunction = EscortGroup:OptionROEHoldFire(), ParamMessage = "Holding weapons!" } )
  end
  if EscortGroup:OptionROEReturnFirePossible() then
    self.EscortMenuROEReturnFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Return Fire", self.EscortMenuROE, ESCORT._ROE, { ParamSelf = self, ParamFunction = EscortGroup:OptionROEReturnFire(), ParamMessage = "Returning fire!" } )
  end
  if EscortGroup:OptionROEOpenFirePossible() then
    self.EscortMenuROEOpenFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Open Fire", self.EscortMenuROE, ESCORT._ROE, { ParamSelf = self, ParamFunction = EscortGroup:OptionROEOpenFire(), ParamMessage = "Opening fire on designated targets!!" } )
  end
  if EscortGroup:OptionROEWeaponFreePossible() then
    self.EscortMenuROEWeaponFree = MENU_CLIENT_COMMAND:New( self.EscortClient, "Weapon Free", self.EscortMenuROE, ESCORT._ROE, { ParamSelf = self, ParamFunction = EscortGroup:OptionROEWeaponFree(), ParamMessage = "Opening fire on targets of opportunity!" } )
  end

  -- Reaction to Threats
  self.EscortMenuEvasion = MENU_CLIENT:New( self.EscortClient, "Evasion", self.EscortMenu )
  if EscortGroup:OptionROTNoReactionPossible() then
    self.EscortMenuEvasionNoReaction = MENU_CLIENT_COMMAND:New( self.EscortClient, "Fight until death", self.EscortMenuEvasion, ESCORT._ROT, { ParamSelf = self, ParamFunction = EscortGroup:OptionROTNoReaction(), ParamMessage = "Fighting until death!" } )
  end
  if EscortGroup:OptionROTPassiveDefensePossible() then
    self.EscortMenuEvasionPassiveDefense = MENU_CLIENT_COMMAND:New( self.EscortClient, "Use flares, chaff and jammers", self.EscortMenuEvasion, ESCORT._ROT, { ParamSelf = self, ParamFunction = EscortGroup:OptionROTPassiveDefense(), ParamMessage = "Defending using jammers, chaff and flares!" } )
  end
  if EscortGroup:OptionROTEvadeFirePossible() then
    self.EscortMenuEvasionEvadeFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Evade enemy fire", self.EscortMenuEvasion, ESCORT._ROT, { ParamSelf = self, ParamFunction = EscortGroup:OptionROTEvadeFire(), ParamMessage = "Evading on enemy fire!" } )
  end
  if EscortGroup:OptionROTVerticalPossible() then
    self.EscortMenuOptionEvasionVertical = MENU_CLIENT_COMMAND:New( self.EscortClient, "Go below radar and evade fire", self.EscortMenuEvasion, ESCORT._ROT, { ParamSelf = self, ParamFunction = EscortGroup:OptionROTVertical(), ParamMessage = "Evading on enemy fire with vertical manoeuvres!" } )
  end
  
  -- Mission Resume Menu Root
  self.EscortMenuResumeMission = MENU_CLIENT:New( self.EscortClient, "Resume the escort mission", self.EscortMenu )

  -- Initialize the EscortGroup
  
  self.EscortGroup:WayPointInitialize(1)
  
  self.EscortGroup:OptionROTVertical()
  self.EscortGroup:OptionROEOpenFire()
  
  
  self.ReportTargetsScheduler = routines.scheduleFunction( self._ReportTargetsScheduler, { self }, timer.getTime() + 1, 30 )
  
  EscortGroup:MessageToClient( EscortGroup:GetCategoryName() .. " '" .. EscortName .. "' (" .. EscortGroup:GetCallsign() .. ") reporting! " ..
                               "We're escorting your flight. " .. 
                               "Use the Radio Menu and F10 and use the options under + " .. EscortName .. "\n",
                               60, EscortClient 
                             )
end


--- @param #MENUPARAM MenuParam
function ESCORT._HoldPosition( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  
  routines.removeFunction( self.FollowScheduler )

  EscortGroup:SetTask( EscortGroup:TaskHoldPosition( 300 ) )
  EscortGroup:MessageToClient( "Holding Position.", 10, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._HoldPositionNearBy( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  
  --MenuParam.ParamSelf.EscortGroup:TaskOrbitCircleAtVec2( MenuParam.ParamSelf.EscortClient:GetPointVec2(), 300, 30, 0 )

  routines.removeFunction( self.FollowScheduler )
  
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
  
  EscortGroup:SetTask( EscortGroup:TaskRoute( Points ) )
  EscortGroup:MessageToClient( "Rejoining to your location. Please hold at your location.", 10, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._JoinUpAndFollow( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  
  local Distance = MenuParam.ParamDistance
  
  self:JoinUpAndFollow( EscortGroup, EscortClient, Distance )
end

--- JoinsUp and Follows a CLIENT.
-- @param Escort#ESCORT self
-- @param Group#GROUP EscortGroup
-- @param Client#CLIENT EscortClient
-- @param DCSTypes#Distance Distance
function ESCORT:JoinUpAndFollow( EscortGroup, EscortClient, Distance )
  self:F( { EscortGroup, EscortClient, Distance } )

  if self.FollowScheduler then
    routines.removeFunction( self.FollowScheduler )
  end
  
  EscortGroup:OptionROEHoldFire()
  EscortGroup:OptionROTPassiveDefense()
  
  self.CT1 = 0
  self.GT1 = 0
  self.FollowScheduler = routines.scheduleFunction( self._FollowScheduler, { self, Distance }, timer.getTime() + 1, .5 )
  EscortGroup:MessageToClient( "Rejoining and Following at " .. Distance .. "!", 30, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._Flare( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  
  local Color = MenuParam.ParamColor
  local Message = MenuParam.ParamMessage

  EscortGroup:GetUnit(1):Flare( Color )
  EscortGroup:MessageToClient( Message, 10, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._Smoke( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  local Color = MenuParam.ParamColor
  local Message = MenuParam.ParamMessage
  
  EscortGroup:GetUnit(1):Smoke( Color )
  EscortGroup:MessageToClient( Message, 10, EscortClient )
end


--- @param #MENUPARAM MenuParam
function ESCORT._ReportNearbyTargetsNow( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  self:_ReportTargetsScheduler()
  
end

function ESCORT._SwitchReportNearbyTargets( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  
  self.ReportTargets = MenuParam.ParamReportTargets
  
  if self.ReportTargets then
    if not self.ReportTargetsScheduler then
      self.ReportTargetsScheduler = routines.scheduleFunction( self._ReportTargetsScheduler, { self }, timer.getTime() + 1, 30 )
    end
  else
    routines.removeFunction( self.ReportTargetsScheduler )
    self.ReportTargetsScheduler = nil
  end
end

--- @param #MENUPARAM MenuParam
function ESCORT._ScanTargets( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  
  local ScanDuration = MenuParam.ParamScanDuration

  if self.FollowScheduler then
    routines.removeFunction( self.FollowScheduler )
  end
  
  self:T( { "FollowScheduler after removefunction: ", self.FollowScheduler } )
  
  if EscortGroup:IsHelicopter() then
    routines.scheduleFunction( EscortGroup.PushTask,
                               { EscortGroup,
                                 EscortGroup:TaskControlled( 
                                   EscortGroup:TaskOrbitCircle( 200, 20 ), 
                                   EscortGroup:TaskCondition( nil, nil, nil, nil, ScanDuration, nil )
                                 ) 
                               },
                               timer.getTime() + 1
                             )
  elseif EscortGroup:IsAirPlane() then
    routines.scheduleFunction( EscortGroup.PushTask,
                               { EscortGroup,
                                 EscortGroup:TaskControlled( 
                                   EscortGroup:TaskOrbitCircle( 1000, 500 ), 
                                   EscortGroup:TaskCondition( nil, nil, nil, nil, ScanDuration, nil )
                                 ) 
                               },
                               timer.getTime() + 1
                             )
  end  
  
  EscortGroup:MessageToClient( "Scanning targets for " .. ScanDuration .. " seconds.", ScanDuration, EscortClient )

  if self.FollowScheduler then
    self.FollowScheduler = routines.scheduleFunction( self._FollowScheduler, { self, Distance }, timer.getTime() + ScanDuration, 1 )
  end

end

--- @param #MENUPARAM MenuParam
function ESCORT._AttackTarget( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  local AttackUnit = MenuParam.ParamUnit -- Unit#UNIT

  if self.FollowScheduler then
    routines.removeFunction( self.FollowScheduler )
  end
  
  self:T( AttackUnit )
  
  if EscortGroup:IsAir() then
    EscortGroup:OptionROEOpenFire()
    EscortGroup:OptionROTVertical()
    routines.scheduleFunction( 
      EscortGroup.PushTask, 
      { EscortGroup, 
        EscortGroup:TaskCombo(
          { EscortGroup:TaskAttackUnit( AttackUnit ),
            EscortGroup:TaskOrbitCircle( 500, 350 )
          }
        )
      }, timer.getTime() + 10
    )
  else
    routines.scheduleFunction( 
      EscortGroup.PushTask, 
      { EscortGroup, 
        EscortGroup:TaskCombo(
          { EscortGroup:TaskFireAtPoint( AttackUnit:GetPointVec2(), 50 )
          }
        )
      }, timer.getTime() + 10 
    )
  end  
  EscortGroup:MessageToClient( "Engaging Designated Unit!", 10, EscortClient )


  if self.FollowScheduler then
    self.FollowScheduler = routines.scheduleFunction( self._FollowScheduler, { self, Distance }, timer.getTime() + ScanDuration, 1 )
  end

end

--- @param #MENUPARAM MenuParam
function ESCORT._AssistTarget( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  local EscortGroupAttack = MenuParam.ParamEscortGroup
  local AttackUnit = MenuParam.ParamUnit -- Unit#UNIT

  if self.FollowScheduler then
    routines.removeFunction( self.FollowScheduler )
  end
  
  
  self:T( AttackUnit )
  
  if EscortGroupAttack:IsAir() then
    EscortGroupAttack:OptionROEOpenFire()
    EscortGroupAttack:OptionROTVertical()
    routines.scheduleFunction( 
      EscortGroupAttack.PushTask, 
      { EscortGroupAttack, 
        EscortGroupAttack:TaskCombo(
          { EscortGroupAttack:TaskAttackUnit( AttackUnit ),
            EscortGroupAttack:TaskOrbitCircle( 500, 350 )
          }
        )
      }, timer.getTime() + 10 
    )
  else
    routines.scheduleFunction( 
      EscortGroupAttack.PushTask, 
      { EscortGroupAttack, 
        EscortGroupAttack:TaskCombo(
          { EscortGroupAttack:TaskFireAtPoint( AttackUnit:GetPointVec2(), 50 )
          }
        )
      }, timer.getTime() + 10 
    )
  end  
  EscortGroupAttack:MessageToClient( "Assisting with the destroying the enemy unit!", 10, EscortClient )

end

--- @param #MENUPARAM MenuParam
function ESCORT._ROE( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  
  local EscortROEFunction = MenuParam.ParamFunction
  local EscortROEMessage = MenuParam.ParamMessage
  
  pcall( function() EscortROEFunction() end )
  EscortGroup:MessageToClient( EscortROEMessage, 10, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._ROT( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  local EscortROTFunction = MenuParam.ParamFunction
  local EscortROTMessage = MenuParam.ParamMessage

  pcall( function() EscortROTFunction() end )
  EscortGroup:MessageToClient( EscortROTMessage, 10, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT._ResumeMission( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  
  local WayPoint = MenuParam.ParamWayPoint
  
  routines.removeFunction( self.FollowScheduler )
  self.FollowScheduler = nil

  local WayPoints = EscortGroup:GetTaskRoute()
  self:T( WayPoint, WayPoints )
  
  for WayPointIgnore = 1, WayPoint do
    table.remove( WayPoints, 1 )
  end
  
  routines.scheduleFunction( EscortGroup.SetTask, {EscortGroup, EscortGroup:TaskRoute( WayPoints ) }, timer.getTime() + 1 )
  
  EscortGroup:MessageToClient( "Resuming mission from waypoint " .. WayPoint .. ".", 10, EscortClient )
end

--- Registers the waypoints
-- @param #ESCORT self
-- @return #table
function ESCORT:RegisterRoute()
  self:F()

  local EscortGroup = self.EscortGroup -- Group#GROUP
  
  local TaskPoints = EscortGroup:GetTaskRoute()
  
  self:T( TaskPoints )

  return TaskPoints
end

--- @param Escort#ESCORT self
function ESCORT:_FollowScheduler( FollowDistance )
  self:F( { FollowDistance })

  if self.EscortGroup:IsAlive() and self.EscortClient:IsAlive() then
  
    local ClientUnit = self.EscortClient:GetClientGroupUnit()
    local GroupUnit = self.EscortGroup:GetUnit( 1 )

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
      self.CT1 = CT2
      self.CV1 = CV2
      
      local CD = ( ( CV2.x - CV1.x )^2 + ( CV2.y - CV1.y )^2 + ( CV2.z - CV1.z )^2 ) ^ 0.5
      local CT = CT2 - CT1
      
      local CS = ( 3600 / CT ) * ( CD / 1000 )
      
      self:T2( { "Client:", CS, CD, CT, CV2, CV1, CT2, CT1 } )
      
      local GT1 = self.GT1
      local GT2 = timer.getTime()
      local GV1 = self.GV1
      local GV2 = GroupUnit:GetPositionVec3()
      self.GT1 = GT2
      self.GV1 = GV2
      
      local GD = ( ( GV2.x - GV1.x )^2 + ( GV2.y - GV1.y )^2 + ( GV2.z - GV1.z )^2 ) ^ 0.5
      local GT = GT2 - GT1
      
      local GS = ( 3600 / GT ) * ( GD / 1000 )
      
      self:T2( { "Group:", GS, GD, GT, GV2, GV1, GT2, GT1 } )
      
      -- Calculate the group direction vector
      local GV = { x = GV2.x - CV2.x, y = GV2.y - CV2.y, z = GV2.z - CV2.z }
      
      -- Calculate GH2, GH2 with the same height as CV2.
      local GH2 = { x = GV2.x, y = CV2.y, z = GV2.z }
      
      -- Calculate the angle of GV to the orthonormal plane
      local alpha = math.atan2( GV.z, GV.x )
      
      -- Now we calculate the intersecting vector between the circle around CV2 with radius FollowDistance and GH2.
      -- From the GeoGebra model: CVI = (x(CV2) + FollowDistance cos(alpha), y(GH2) + FollowDistance sin(alpha), z(CV2))
      local CVI = { x = CV2.x + FollowDistance * math.cos(alpha), 
                    y = GH2.y,
                    z = CV2.z + FollowDistance * math.sin(alpha),   
                  }
                  
      -- Calculate the direction vector DV of the escort group. We use CVI as the base and CV2 as the direction.
      local DV = { x = CV2.x - CVI.x, y = CV2.y - CVI.y, z = CV2.z - CVI.z }
      
      -- We now calculate the unary direction vector DVu, so that we can multiply DVu with the speed, which is expressed in meters / s.
      -- We need to calculate this vector to predict the point the escort group needs to fly to according its speed.
      -- The distance of the destination point should be far enough not to have the aircraft starting to swipe left to right...
      local DVu = { x = DV.x / FollowDistance, y = DV.y / FollowDistance, z = DV.z / FollowDistance }
      
      -- Now we can calculate the group destination vector GDV.
      local GDV = { x = DVu.x * CS * 8 + CVI.x, y = CVI.y, z = DVu.z * CS * 8 + CVI.z }
      self:T2( { "CV2:", CV2 } )
      self:T2( { "CVI:", CVI } )
      self:T2( { "GDV:", GDV } )
      
      -- Measure distance between client and group
      local CatchUpDistance = ( ( GDV.x - GV2.x )^2 + ( GDV.y - GV2.y )^2 + ( GDV.z - GV2.z )^2 ) ^ 0.5
      
      -- The calculation of the Speed would simulate that the group would take 30 seconds to overcome 
      -- the requested Distance).
      local Time = 10
      local CatchUpSpeed = ( CatchUpDistance - ( CS * 8.4 ) ) / Time 
      
      local Speed = CS + CatchUpSpeed
      if Speed < 0 then 
        Speed = 0
      end 

      self:T( { "Client Speed, Escort Speed, Speed, FlyDistance, Time:", CS, GS, Speed, Distance, Time } )

      -- Now route the escort to the desired point with the desired speed.
      self.EscortGroup:TaskRouteToVec3( GDV, Speed / 3.6 ) -- DCS models speed in Mps (Miles per second)
    end
  else
    routines.removeFunction( self.FollowScheduler )
  end

end


--- Report Targets Scheduler.
-- @param #ESCORT self
function ESCORT:_ReportTargetsScheduler()
	self:F( self.EscortGroup:GetName() )

  if self.EscortGroup:IsAlive() and self.EscortClient:IsAlive() then
    local EscortGroupName = self.EscortGroup:GetName()
    local EscortTargets = self.EscortGroup:GetDetectedTargets()
    
    local ClientEscortTargets = self.EscortClient._EscortGroups[EscortGroupName].Targets
    
    local EscortTargetMessages = ""
    for EscortTargetID, EscortTarget in pairs( EscortTargets ) do
      local EscortObject = EscortTarget.object
      self:T( EscortObject )
      if EscortObject and EscortObject:isExist() and EscortObject.id_ < 50000000 then
        
          local EscortTargetUnit = UNIT:New( EscortObject )
          local EscortTargetUnitName = EscortTargetUnit:GetName()
        
        
        
--          local EscortTargetIsDetected, 
--                EscortTargetIsVisible, 
--                EscortTargetLastTime, 
--                EscortTargetKnowType, 
--                EscortTargetKnowDistance, 
--                EscortTargetLastPos, 
--                EscortTargetLastVelocity
--                = self.EscortGroup:IsTargetDetected( EscortObject )
--        
--          self:T( { EscortTargetIsDetected, 
--                EscortTargetIsVisible, 
--                EscortTargetLastTime, 
--                EscortTargetKnowType, 
--                EscortTargetKnowDistance, 
--                EscortTargetLastPos, 
--                EscortTargetLastVelocity } )
        

          local EscortTargetUnitPositionVec3 = EscortTargetUnit:GetPositionVec3()
          local EscortPositionVec3 = self.EscortGroup:GetPositionVec3()
          local Distance = ( ( EscortTargetUnitPositionVec3.x - EscortPositionVec3.x )^2 + 
                             ( EscortTargetUnitPositionVec3.y - EscortPositionVec3.y )^2 + 
                             ( EscortTargetUnitPositionVec3.z - EscortPositionVec3.z )^2 
                           ) ^ 0.5 / 1000

          self:T( { self.EscortGroup:GetName(), EscortTargetUnit:GetName(), Distance, EscortTarget } )

          if Distance <= 15 then

            if not ClientEscortTargets[EscortTargetUnitName] then
              ClientEscortTargets[EscortTargetUnitName] = {}
            end 
            ClientEscortTargets[EscortTargetUnitName].AttackUnit = EscortTargetUnit        
            ClientEscortTargets[EscortTargetUnitName].visible = EscortTarget.visible
            ClientEscortTargets[EscortTargetUnitName].type = EscortTarget.type
            ClientEscortTargets[EscortTargetUnitName].distance = EscortTarget.distance
          else
             if ClientEscortTargets[EscortTargetUnitName] then
               ClientEscortTargets[EscortTargetUnitName] = nil
             end
          end
      end
    end
    
    self:T( { "Sorting Targets Table:", ClientEscortTargets } )
    table.sort( ClientEscortTargets, function( a, b ) return a.Distance < b.Distance end )
    self:T( { "Sorted Targets Table:", ClientEscortTargets } )

    -- Remove the sub menus of the Attack menu of the Escort for the EscortGroup.
    self.EscortMenuAttackNearbyTargets:RemoveSubMenus()
    self.EscortMenuTargetAssistance:RemoveSubMenus()
    
    --for MenuIndex = 1, #self.EscortMenuAttackTargets do
    --  self:T( { "Remove Menu:", self.EscortMenuAttackTargets[MenuIndex] } )
    --  self.EscortMenuAttackTargets[MenuIndex] = self.EscortMenuAttackTargets[MenuIndex]:Remove()
    --end

  
    if ClientEscortTargets then
      for ClientEscortTargetUnitName, ClientEscortTargetData in pairs( ClientEscortTargets ) do
  
        for ClientEscortGroupName, EscortGroupData in pairs( self.EscortClient._EscortGroups ) do
  
          if ClientEscortTargetData and ClientEscortTargetData.AttackUnit:IsAlive() then
  
            local EscortTargetMessage = ""
            local EscortTargetCategoryName = ClientEscortTargetData.AttackUnit:GetCategoryName()
            local EscortTargetCategoryType = ClientEscortTargetData.AttackUnit:GetTypeName()
            if ClientEscortTargetData.type then
              EscortTargetMessage = EscortTargetMessage .. EscortTargetCategoryName .. " (" .. EscortTargetCategoryType .. ") at "
            else
              EscortTargetMessage = EscortTargetMessage .. "Unknown target at "
            end
              
            local EscortTargetUnitPositionVec3 = ClientEscortTargetData.AttackUnit:GetPositionVec3()
            local EscortPositionVec3 = self.EscortGroup:GetPositionVec3()
            local Distance = ( ( EscortTargetUnitPositionVec3.x - EscortPositionVec3.x )^2 + 
                               ( EscortTargetUnitPositionVec3.y - EscortPositionVec3.y )^2 + 
                               ( EscortTargetUnitPositionVec3.z - EscortPositionVec3.z )^2 
                             ) ^ 0.5 / 1000
  
            self:T( { self.EscortGroup:GetName(), ClientEscortTargetData.AttackUnit:GetName(), Distance, ClientEscortTargetData.AttackUnit } )
            if ClientEscortTargetData.visible == false then
              EscortTargetMessage = EscortTargetMessage .. string.format( "%.2f", Distance ) .. " estimated km"
            else
              EscortTargetMessage = EscortTargetMessage .. string.format( "%.2f", Distance ) .. " km"
            end
  
            if ClientEscortTargetData.visible then
              EscortTargetMessage = EscortTargetMessage .. ", visual"
            end
            
            if ClientEscortGroupName == EscortGroupName then
  
              MENU_CLIENT_COMMAND:New( self.EscortClient,
                                       EscortTargetMessage,
                                       self.EscortMenuAttackNearbyTargets,
                                       ESCORT._AttackTarget,
                                       { ParamSelf = self,
                                         ParamUnit = ClientEscortTargetData.AttackUnit 
                                       }
                                     )
              EscortTargetMessages = EscortTargetMessages .. "\n - " .. EscortTargetMessage 
            else
              local MenuTargetAssistance = MENU_CLIENT:New( self.EscortClient, EscortGroupData.EscortName, self.EscortMenuTargetAssistance )
              MENU_CLIENT_COMMAND:New( self.EscortClient,
                                       EscortTargetMessage,
                                       MenuTargetAssistance,
                                       ESCORT._AssistTarget,
                                       { ParamSelf = self,
                                         ParamEscortGroup = EscortGroupData.EscortGroup,
                                         ParamUnit = ClientEscortTargetData.AttackUnit 
                                       }
                                     )
            end
          else
            ClientEscortTargetData = nil
          end
        end
      end
  
      if EscortTargetMessages ~= "" and self.ReportTargets == true then
        self.EscortGroup:MessageToClient( "Detected targets within 15 km range:" .. EscortTargetMessages:gsub("\n$",""), 20, self.EscortClient )
      else
        self.EscortGroup:MessageToClient( "No targets detected!", 20, self.EscortClient )
      end
    end

    self.EscortMenuResumeMission:RemoveSubMenus()
    
--    if self.EscortMenuResumeWayPoints then
--      for MenuIndex = 1, #self.EscortMenuResumeWayPoints do
--        self:T( { "Remove Menu:", self.EscortMenuResumeWayPoints[MenuIndex] } )
--        self.EscortMenuResumeWayPoints[MenuIndex] = self.EscortMenuResumeWayPoints[MenuIndex]:Remove()
--      end
--    end

    local TaskPoints = self:RegisterRoute()
    for WayPointID, WayPoint in pairs( TaskPoints ) do
      local EscortPositionVec3 = self.EscortGroup:GetPositionVec3()
      local Distance = ( ( WayPoint.x - EscortPositionVec3.x )^2 + 
                         ( WayPoint.y - EscortPositionVec3.z )^2
                       ) ^ 0.5 / 1000
      MENU_CLIENT_COMMAND:New( self.EscortClient, "Waypoint " .. WayPointID .. " at " .. string.format( "%.2f", Distance ).. "km", self.EscortMenuResumeMission, ESCORT._ResumeMission, { ParamSelf = self, ParamWayPoint = WayPointID } )
    end

  else
    routines.removeFunction( self.ReportTargetsScheduler )
    self.ReportTargetsScheduler = nil
  end
end
