--- Taking the lead of AI escorting your flight.
-- 
-- @{#ESCORT} class
-- ================
-- The @{#ESCORT} class allows you to interact with escorting AI on your flight and take the lead.
-- Each escorting group can be commanded with a whole set of radio commands (radio menu in your flight, and then F10).
--
-- The radio commands will vary according the category of the group. The richest set of commands are with Helicopters and AirPlanes.
-- Ships and Ground troops will have a more limited set, but they can provide support through the bombing of targets designated by the other escorts.
--
-- RADIO MENUs that can be created:
-- ================================
-- Find a summary below of the current available commands:
--
-- Navigation ...:
-- ---------------
-- Escort group navigation functions:
--
--   * **"Join-Up and Follow at x meters":** The escort group fill follow you at about x meters, and they will follow you.
--   * **"Flare":** Provides menu commands to let the escort group shoot a flare in the air in a color.
--   * **"Smoke":** Provides menu commands to let the escort group smoke the air in a color. Note that smoking is only available for ground and naval troops.
--
-- Hold position ...:
-- ------------------
-- Escort group navigation functions:
--
--   * **"At current location":** Stops the escort group and they will hover 30 meters above the ground at the position they stopped.
--   * **"At client location":** Stops the escort group and they will hover 30 meters above the ground at the position they stopped.
--
-- Report targets ...:
-- -------------------
-- Report targets will make the escort group to report any target that it identifies within a 8km range. Any detected target can be attacked using the 4. Attack nearby targets function. (see below).
--
--   * **"Report now":** Will report the current detected targets.
--   * **"Report targets on":** Will make the escort group to report detected targets and will fill the "Attack nearby targets" menu list.
--   * **"Report targets off":** Will stop detecting targets.
--
-- Scan targets ...:
-- -----------------
-- Menu items to pop-up the escort group for target scanning. After scanning, the escort group will resume with the mission or defined task.
--
--   * **"Scan targets 30 seconds":** Scan 30 seconds for targets.
--   * **"Scan targets 60 seconds":** Scan 60 seconds for targets.
--
-- Attack targets ...:
-- ------------------- 
-- This menu item will list all detected targets within a 15km range. Depending on the level of detection (known/unknown) and visuality, the targets type will also be listed.
--
-- Request assistance from ...:
-- ----------------------------
-- This menu item will list all detected targets within a 15km range, as with the menu item **Attack Targets**.
-- This menu item allows to request attack support from other escorts supporting the current client group.
-- eg. the function allows a player to request support from the Ship escort to attack a target identified by the Plane escort with its Tomahawk missiles.
-- eg. the function allows a player to request support from other Planes escorting to bomb the unit with illumination missiles or bombs, so that the main plane escort can attack the area.
--
-- ROE ...:
-- -------- 
-- Sets the Rules of Engagement (ROE) of the escort group when in flight.
--
--   * **"Hold Fire":** The escort group will hold fire.
--   * **"Return Fire":** The escort group will return fire.
--   * **"Open Fire":** The escort group will open fire on designated targets.
--   * **"Weapon Free":** The escort group will engage with any target.
--
-- Evasion ...:
-- ------------
-- Will define the evasion techniques that the escort group will perform during flight or combat.
--
--   * **"Fight until death":** The escort group will have no reaction to threats.
--   * **"Use flares, chaff and jammers":** The escort group will use passive defense using flares and jammers. No evasive manoeuvres are executed.
--   * **"Evade enemy fire":** The rescort group will evade enemy fire before firing.
--   * **"Go below radar and evade fire":** The escort group will perform evasive vertical manoeuvres.
--
-- Resume Mission ...:
-- -------------------
-- Escort groups can have their own mission. This menu item will allow the escort group to resume their Mission from a given waypoint.
-- Note that this is really fantastic, as you now have the dynamic of taking control of the escort groups, and allowing them to resume their path or mission.
--
-- ESCORT construction methods.
-- ============================
-- Create a new SPAWN object with the @{#ESCORT.New} method:
--
--  * @{#ESCORT.New}: Creates a new ESCORT object from a @{Group#GROUP} for a @{Client#CLIENT}, with an optional briefing text.
--
-- ESCORT initialization methods.
-- ==============================
-- The following menus are created within the RADIO MENU of an active unit hosted by a player:
--
-- * @{#ESCORT.MenuFollowAt}: Creates a menu to make the escort follow the client.
-- * @{#ESCORT.MenuHoldAtEscortPosition}: Creates a menu to hold the escort at its current position.
-- * @{#ESCORT.MenuHoldAtLeaderPosition}: Creates a menu to hold the escort at the client position.
-- * @{#ESCORT.MenuScanForTargets}: Creates a menu so that the escort scans targets.
-- * @{#ESCORT.MenuFlare}: Creates a menu to disperse flares.
-- * @{#ESCORT.MenuSmoke}: Creates a menu to disparse smoke.
-- * @{#ESCORT.MenuReportTargets}: Creates a menu so that the escort reports targets.
-- * @{#ESCORT.MenuReportPosition}: Creates a menu so that the escort reports its current position from bullseye.
-- * @{#ESCORT.MenuAssistedAttack: Creates a menu so that the escort supportes assisted attack from other escorts with the client.
-- * @{#ESCORT.MenuROE: Creates a menu structure to set the rules of engagement of the escort.
-- * @{#ESCORT.MenuEvasion: Creates a menu structure to set the evasion techniques when the escort is under threat.
-- * @{#ESCORT.MenuResumeMission}: Creates a menu structure so that the escort can resume from a waypoint.
-- 
-- 
-- @usage
-- -- Declare a new EscortPlanes object as follows:
-- 
-- -- First find the GROUP object and the CLIENT object.
-- local EscortClient = CLIENT:FindByName( "Unit Name" ) -- The Unit Name is the name of the unit flagged with the skill Client in the mission editor.
-- local EscortGroup = GROUP:FindByName( "Group Name" ) -- The Group Name is the name of the group that will escort the Escort Client.
-- 
-- -- Now use these 2 objects to construct the new EscortPlanes object.
-- EscortPlanes = ESCORT:New( EscortClient, EscortGroup, "Desert", "Welcome to the mission. You are escorted by a plane with code name 'Desert', which can be instructed through the F10 radio menu." )
-- 
--
--
-- @module Escort
-- @author FlightControl

--- ESCORT class
-- @type ESCORT
-- @extends Base#BASE
-- @field Client#CLIENT EscortClient
-- @field Group#GROUP EscortGroup
-- @field #string EscortName
-- @field #ESCORT.MODE EscortMode The mode the escort is in.
-- @field Scheduler#SCHEDULER FollowScheduler The instance of the SCHEDULER class.
-- @field #number FollowDistance The current follow distance.
-- @field #boolean ReportTargets If true, nearby targets are reported.
-- @Field DCSTypes#AI.Option.Air.val.ROE OptionROE Which ROE is set to the EscortGroup.
-- @field DCSTypes#AI.Option.Air.val.REACTION_ON_THREAT OptionReactionOnThreat Which REACTION_ON_THREAT is set to the EscortGroup.
-- @field Menu#MENU_CLIENT EscortMenuResumeMission
ESCORT = {
  ClassName = "ESCORT",
  EscortName = nil, -- The Escort Name
  EscortClient = nil,
  EscortGroup = nil,
  EscortMode = 1,
  MODE = {
    FOLLOW = 1,
    MISSION = 2,
  },
  Targets = {}, -- The identified targets
  FollowScheduler = nil,
  ReportTargets = true,
  OptionROE = AI.Option.Air.val.ROE.OPEN_FIRE,
  OptionReactionOnThreat = AI.Option.Air.val.REACTION_ON_THREAT.ALLOW_ABORT_MISSION,
  SmokeDirectionVector = false,
  TaskPoints = {}
}

--- ESCORT.Mode class
-- @type ESCORT.MODE
-- @field #number FOLLOW
-- @field #number MISSION

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
-- @param #string EscortBriefing A text showing the ESCORT briefing to the player. Note that if no EscortBriefing is provided, the default briefing will be shown.
-- @return #ESCORT self
-- @usage
-- -- Declare a new EscortPlanes object as follows:
-- 
-- -- First find the GROUP object and the CLIENT object.
-- local EscortClient = CLIENT:FindByName( "Unit Name" ) -- The Unit Name is the name of the unit flagged with the skill Client in the mission editor.
-- local EscortGroup = GROUP:FindByName( "Group Name" ) -- The Group Name is the name of the group that will escort the Escort Client.
-- 
-- -- Now use these 2 objects to construct the new EscortPlanes object.
-- EscortPlanes = ESCORT:New( EscortClient, EscortGroup, "Desert", "Welcome to the mission. You are escorted by a plane with code name 'Desert', which can be instructed through the F10 radio menu." )
function ESCORT:New( EscortClient, EscortGroup, EscortName, EscortBriefing )
  local self = BASE:Inherit( self, BASE:New() )
  self:F( { EscortClient, EscortGroup, EscortName } )

  self.EscortClient = EscortClient -- Client#CLIENT
  self.EscortGroup = EscortGroup -- Group#GROUP
  self.EscortName = EscortName
  self.EscortBriefing = EscortBriefing

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

  self.EscortGroup:WayPointInitialize(1)

  self.EscortGroup:OptionROTVertical()
  self.EscortGroup:OptionROEOpenFire()
  
  if not EscortBriefing then
    EscortGroup:MessageToClient( EscortGroup:GetCategoryName() .. " '" .. EscortName .. "' (" .. EscortGroup:GetCallsign() .. ") reporting! " ..
      "We're escorting your flight. " ..
      "Use the Radio Menu and F10 and use the options under + " .. EscortName .. "\n",
      60, EscortClient
    )
  else
    EscortGroup:MessageToClient( EscortGroup:GetCategoryName() .. " '" .. EscortName .. "' (" .. EscortGroup:GetCallsign() .. ") " .. EscortBriefing,
      60, EscortClient
    )
  end

  self.FollowDistance = 100
  self.CT1 = 0
  self.GT1 = 0
  self.FollowScheduler = SCHEDULER:New( self, self._FollowScheduler, {}, 1, .5, .01 )
  self.EscortMode = ESCORT.MODE.MISSION
  self.FollowScheduler:Stop()

  return self
end

--- This function is for test, it will put on the frequency of the FollowScheduler a red smoke at the direction vector calculated for the escort to fly to.
-- This allows to visualize where the escort is flying to.
-- @param #ESCORT self
-- @param #boolean SmokeDirection If true, then the direction vector will be smoked.
function ESCORT:TestSmokeDirectionVector( SmokeDirection )
  self.SmokeDirectionVector = ( SmokeDirection == true ) and true or false
end


--- Defines the default menus
-- @param #ESCORT self
-- @return #ESCORT
function ESCORT:Menus()
  self:F()

  self:MenuFollowAt( 100 )
  self:MenuFollowAt( 200 )
  self:MenuFollowAt( 300 )
  self:MenuFollowAt( 400 )

  self:MenuScanForTargets( 100, 60 )

  self:MenuHoldAtEscortPosition( 30 )
  self:MenuHoldAtLeaderPosition( 30 )

  self:MenuFlare()
  self:MenuSmoke()

  self:MenuReportTargets( 60 )
  self:MenuAssistedAttack()
  self:MenuROE()
  self:MenuEvasion()
  self:MenuResumeMission()


  return self
end



--- Defines a menu slot to let the escort Join and Follow you at a certain distance.
-- This menu will appear under **Navigation**.
-- @param #ESCORT self
-- @param DCSTypes#Distance Distance The distance in meters that the escort needs to follow the client.
-- @return #ESCORT
function ESCORT:MenuFollowAt( Distance )
  self:F(Distance)

  if self.EscortGroup:IsAir() then
    if not self.EscortMenuReportNavigation then
      self.EscortMenuReportNavigation = MENU_CLIENT:New( self.EscortClient, "Navigation", self.EscortMenu )
    end

    if not self.EscortMenuJoinUpAndFollow then
      self.EscortMenuJoinUpAndFollow = {}
    end

    self.EscortMenuJoinUpAndFollow[#self.EscortMenuJoinUpAndFollow+1] = MENU_CLIENT_COMMAND:New( self.EscortClient, "Join-Up and Follow at " .. Distance, self.EscortMenuReportNavigation, ESCORT._JoinUpAndFollow, { ParamSelf = self, ParamDistance = Distance } )

    self.EscortMode = ESCORT.MODE.FOLLOW
  end

  return self
end

--- Defines a menu slot to let the escort hold at their current position and stay low with a specified height during a specified time in seconds.
-- This menu will appear under **Hold position**.
-- @param #ESCORT self
-- @param DCSTypes#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCSTypes#Time Seconds Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #ESCORT
-- TODO: Implement Seconds parameter. Challenge is to first develop the "continue from last activity" function.
function ESCORT:MenuHoldAtEscortPosition( Height, Seconds, MenuTextFormat )
  self:F( { Height, Seconds, MenuTextFormat } )

  if self.EscortGroup:IsAir() then

    if not self.EscortMenuHold then
      self.EscortMenuHold = MENU_CLIENT:New( self.EscortClient, "Hold position", self.EscortMenu )
    end

    if not Height then
      Height = 30
    end

    if not Seconds then
      Seconds = 0
    end

    local MenuText = ""
    if not MenuTextFormat then
      if Seconds == 0 then
        MenuText = string.format( "Hold at %d meter", Height )
      else
        MenuText = string.format( "Hold at %d meter for %d seconds", Height, Seconds )
      end
    else
      if Seconds == 0 then
        MenuText = string.format( MenuTextFormat, Height )
      else
        MenuText = string.format( MenuTextFormat, Height, Seconds )
      end
    end

    if not self.EscortMenuHoldPosition then
      self.EscortMenuHoldPosition = {}
    end

    self.EscortMenuHoldPosition[#self.EscortMenuHoldPosition+1] = MENU_CLIENT_COMMAND
      :New(
        self.EscortClient,
        MenuText,
        self.EscortMenuHold,
        ESCORT._HoldPosition,
        { ParamSelf = self,
          ParamOrbitGroup = self.EscortGroup,
          ParamHeight = Height,
          ParamSeconds = Seconds
        }
      )
  end

  return self
end


--- Defines a menu slot to let the escort hold at the client position and stay low with a specified height during a specified time in seconds.
-- This menu will appear under **Navigation**.
-- @param #ESCORT self
-- @param DCSTypes#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCSTypes#Time Seconds Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain one or two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #ESCORT
-- TODO: Implement Seconds parameter. Challenge is to first develop the "continue from last activity" function.
function ESCORT:MenuHoldAtLeaderPosition( Height, Seconds, MenuTextFormat )
  self:F( { Height, Seconds, MenuTextFormat } )

  if self.EscortGroup:IsAir() then

    if not self.EscortMenuHold then
      self.EscortMenuHold = MENU_CLIENT:New( self.EscortClient, "Hold position", self.EscortMenu )
    end

    if not Height then
      Height = 30
    end

    if not Seconds then
      Seconds = 0
    end

    local MenuText = ""
    if not MenuTextFormat then
      if Seconds == 0 then
        MenuText = string.format( "Rejoin and hold at %d meter", Height )
      else
        MenuText = string.format( "Rejoin and hold at %d meter for %d seconds", Height, Seconds )
      end
    else
      if Seconds == 0 then
        MenuText = string.format( MenuTextFormat, Height )
      else
        MenuText = string.format( MenuTextFormat, Height, Seconds )
      end
    end

    if not self.EscortMenuHoldAtLeaderPosition then
      self.EscortMenuHoldAtLeaderPosition = {}
    end

    self.EscortMenuHoldAtLeaderPosition[#self.EscortMenuHoldAtLeaderPosition+1] = MENU_CLIENT_COMMAND
      :New(
        self.EscortClient,
        MenuText,
        self.EscortMenuHold,
        ESCORT._HoldPosition,
        { ParamSelf = self,
          ParamOrbitGroup = self.EscortClient,
          ParamHeight = Height,
          ParamSeconds = Seconds
        }
      )
  end

  return self
end

--- Defines a menu slot to let the escort scan for targets at a certain height for a certain time in seconds.
-- This menu will appear under **Scan targets**.
-- @param #ESCORT self
-- @param DCSTypes#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCSTypes#Time Seconds Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain one or two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #ESCORT
function ESCORT:MenuScanForTargets( Height, Seconds, MenuTextFormat )
  self:F( { Height, Seconds, MenuTextFormat } )

  if self.EscortGroup:IsAir() then
    if not self.EscortMenuScan then
      self.EscortMenuScan = MENU_CLIENT:New( self.EscortClient, "Scan for targets", self.EscortMenu )
    end

    if not Height then
      Height = 100
    end

    if not Seconds then
      Seconds = 30
    end

    local MenuText = ""
    if not MenuTextFormat then
      if Seconds == 0 then
        MenuText = string.format( "At %d meter", Height )
      else
        MenuText = string.format( "At %d meter for %d seconds", Height, Seconds )
      end
    else
      if Seconds == 0 then
        MenuText = string.format( MenuTextFormat, Height )
      else
        MenuText = string.format( MenuTextFormat, Height, Seconds )
      end
    end

    if not self.EscortMenuScanForTargets then
      self.EscortMenuScanForTargets = {}
    end

    self.EscortMenuScanForTargets[#self.EscortMenuScanForTargets+1] = MENU_CLIENT_COMMAND
      :New(
        self.EscortClient,
        MenuText,
        self.EscortMenuScan,
        ESCORT._ScanTargets,
        { ParamSelf = self,
          ParamScanDuration = 30
        }
      )
  end

  return self
end



--- Defines a menu slot to let the escort disperse a flare in a certain color.
-- This menu will appear under **Navigation**.
-- The flare will be fired from the first unit in the group.
-- @param #ESCORT self
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. If no text is given, the default text will be displayed.
-- @return #ESCORT
function ESCORT:MenuFlare( MenuTextFormat )
  self:F()

  if not self.EscortMenuReportNavigation then
    self.EscortMenuReportNavigation = MENU_CLIENT:New( self.EscortClient, "Navigation", self.EscortMenu )
  end

  local MenuText = ""
  if not MenuTextFormat then
    MenuText = "Flare"
  else
    MenuText = MenuTextFormat
  end

  if not self.EscortMenuFlare then
    self.EscortMenuFlare = MENU_CLIENT:New( self.EscortClient, MenuText, self.EscortMenuReportNavigation, ESCORT._Flare, { ParamSelf = self } )
    self.EscortMenuFlareGreen  = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release green flare",  self.EscortMenuFlare, ESCORT._Flare, { ParamSelf = self, ParamColor = UNIT.FlareColor.Green,  ParamMessage = "Released a green flare!"   } )
    self.EscortMenuFlareRed    = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release red flare",    self.EscortMenuFlare, ESCORT._Flare, { ParamSelf = self, ParamColor = UNIT.FlareColor.Red,    ParamMessage = "Released a red flare!"     } )
    self.EscortMenuFlareWhite  = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release white flare",  self.EscortMenuFlare, ESCORT._Flare, { ParamSelf = self, ParamColor = UNIT.FlareColor.White,  ParamMessage = "Released a white flare!"   } )
    self.EscortMenuFlareYellow = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release yellow flare", self.EscortMenuFlare, ESCORT._Flare, { ParamSelf = self, ParamColor = UNIT.FlareColor.Yellow, ParamMessage = "Released a yellow flare!"  } )
  end

  return self
end

--- Defines a menu slot to let the escort disperse a smoke in a certain color.
-- This menu will appear under **Navigation**.
-- Note that smoke menu options will only be displayed for ships and ground units. Not for air units.
-- The smoke will be fired from the first unit in the group.
-- @param #ESCORT self
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. If no text is given, the default text will be displayed.
-- @return #ESCORT
function ESCORT:MenuSmoke( MenuTextFormat )
  self:F()

  if not self.EscortGroup:IsAir() then
    if not self.EscortMenuReportNavigation then
      self.EscortMenuReportNavigation = MENU_CLIENT:New( self.EscortClient, "Navigation", self.EscortMenu )
    end

    local MenuText = ""
    if not MenuTextFormat then
      MenuText = "Smoke"
    else
      MenuText = MenuTextFormat
    end

    if not self.EscortMenuSmoke then
      self.EscortMenuSmoke = MENU_CLIENT:New( self.EscortClient, "Smoke", self.EscortMenuReportNavigation, ESCORT._Smoke, { ParamSelf = self } )
      self.EscortMenuSmokeGreen  = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release green smoke",  self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.Green,  ParamMessage = "Releasing green smoke!"   } )
      self.EscortMenuSmokeRed    = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release red smoke",    self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.Red,    ParamMessage = "Releasing red smoke!"     } )
      self.EscortMenuSmokeWhite  = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release white smoke",  self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.White,  ParamMessage = "Releasing white smoke!"   } )
      self.EscortMenuSmokeOrange = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release orange smoke", self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.Orange, ParamMessage = "Releasing orange smoke!"  } )
      self.EscortMenuSmokeBlue   = MENU_CLIENT_COMMAND:New( self.EscortClient, "Release blue smoke",   self.EscortMenuSmoke, ESCORT._Smoke, { ParamSelf = self, ParamColor = UNIT.SmokeColor.Blue,   ParamMessage = "Releasing blue smoke!"   } )
    end
  end

  return self
end

--- Defines a menu slot to let the escort report their current detected targets with a specified time interval in seconds.
-- This menu will appear under **Report targets**.
-- Note that if a report targets menu is not specified, no targets will be detected by the escort, and the attack and assisted attack menus will not be displayed.
-- @param #ESCORT self
-- @param DCSTypes#Time Seconds Optional parameter that lets the escort report their current detected targets after specified time interval in seconds. The default time is 30 seconds.
-- @return #ESCORT
function ESCORT:MenuReportTargets( Seconds )
  self:F( { Seconds } )

  if not self.EscortMenuReportNearbyTargets then
    self.EscortMenuReportNearbyTargets = MENU_CLIENT:New( self.EscortClient, "Report targets", self.EscortMenu )
  end

  if not Seconds then
    Seconds = 30
  end

  -- Report Targets
  self.EscortMenuReportNearbyTargetsNow = MENU_CLIENT_COMMAND:New( self.EscortClient, "Report targets now!", self.EscortMenuReportNearbyTargets, ESCORT._ReportNearbyTargetsNow, { ParamSelf = self } )
  self.EscortMenuReportNearbyTargetsOn = MENU_CLIENT_COMMAND:New( self.EscortClient, "Report targets on", self.EscortMenuReportNearbyTargets, ESCORT._SwitchReportNearbyTargets, { ParamSelf = self, ParamReportTargets = true } )
  self.EscortMenuReportNearbyTargetsOff = MENU_CLIENT_COMMAND:New( self.EscortClient, "Report targets off", self.EscortMenuReportNearbyTargets, ESCORT._SwitchReportNearbyTargets, { ParamSelf = self, ParamReportTargets = false, } )

  -- Attack Targets
  self.EscortMenuAttackNearbyTargets = MENU_CLIENT:New( self.EscortClient, "Attack targets", self.EscortMenu )


  self.ReportTargetsScheduler = SCHEDULER:New( self, self._ReportTargetsScheduler, {}, 1, Seconds )

  return self
end

--- Defines a menu slot to let the escort attack its detected targets using assisted attack from another escort joined also with the client.
-- This menu will appear under **Request assistance from**.
-- Note that this method needs to be preceded with the method MenuReportTargets.
-- @param #ESCORT self
-- @return #ESCORT
function ESCORT:MenuAssistedAttack()
  self:F()

  -- Request assistance from other escorts.
  -- This is very useful to let f.e. an escorting ship attack a target detected by an escorting plane...
  self.EscortMenuTargetAssistance = MENU_CLIENT:New( self.EscortClient, "Request assistance from", self.EscortMenu )

  return self
end

--- Defines a menu to let the escort set its rules of engagement.
-- All rules of engagement will appear under the menu **ROE**.
-- @param #ESCORT self
-- @return #ESCORT
function ESCORT:MenuROE( MenuTextFormat )
  self:F( MenuTextFormat )

  if not self.EscortMenuROE then
    -- Rules of Engagement
    self.EscortMenuROE = MENU_CLIENT:New( self.EscortClient, "ROE", self.EscortMenu )
    if self.EscortGroup:OptionROEHoldFirePossible() then
      self.EscortMenuROEHoldFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Hold Fire", self.EscortMenuROE, ESCORT._ROE, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROEHoldFire(), ParamMessage = "Holding weapons!" } )
    end
    if self.EscortGroup:OptionROEReturnFirePossible() then
      self.EscortMenuROEReturnFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Return Fire", self.EscortMenuROE, ESCORT._ROE, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROEReturnFire(), ParamMessage = "Returning fire!" } )
    end
    if self.EscortGroup:OptionROEOpenFirePossible() then
      self.EscortMenuROEOpenFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Open Fire", self.EscortMenuROE, ESCORT._ROE, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROEOpenFire(), ParamMessage = "Opening fire on designated targets!!" } )
    end
    if self.EscortGroup:OptionROEWeaponFreePossible() then
      self.EscortMenuROEWeaponFree = MENU_CLIENT_COMMAND:New( self.EscortClient, "Weapon Free", self.EscortMenuROE, ESCORT._ROE, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROEWeaponFree(), ParamMessage = "Opening fire on targets of opportunity!" } )
    end
  end

  return self
end


--- Defines a menu to let the escort set its evasion when under threat.
-- All rules of engagement will appear under the menu **Evasion**.
-- @param #ESCORT self
-- @return #ESCORT
function ESCORT:MenuEvasion( MenuTextFormat )
  self:F( MenuTextFormat )

  if self.EscortGroup:IsAir() then
    if not self.EscortMenuEvasion then
      -- Reaction to Threats
      self.EscortMenuEvasion = MENU_CLIENT:New( self.EscortClient, "Evasion", self.EscortMenu )
      if self.EscortGroup:OptionROTNoReactionPossible() then
        self.EscortMenuEvasionNoReaction = MENU_CLIENT_COMMAND:New( self.EscortClient, "Fight until death", self.EscortMenuEvasion, ESCORT._ROT, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROTNoReaction(), ParamMessage = "Fighting until death!" } )
      end
      if self.EscortGroup:OptionROTPassiveDefensePossible() then
        self.EscortMenuEvasionPassiveDefense = MENU_CLIENT_COMMAND:New( self.EscortClient, "Use flares, chaff and jammers", self.EscortMenuEvasion, ESCORT._ROT, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROTPassiveDefense(), ParamMessage = "Defending using jammers, chaff and flares!" } )
      end
      if self.EscortGroup:OptionROTEvadeFirePossible() then
        self.EscortMenuEvasionEvadeFire = MENU_CLIENT_COMMAND:New( self.EscortClient, "Evade enemy fire", self.EscortMenuEvasion, ESCORT._ROT, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROTEvadeFire(), ParamMessage = "Evading on enemy fire!" } )
      end
      if self.EscortGroup:OptionROTVerticalPossible() then
        self.EscortMenuOptionEvasionVertical = MENU_CLIENT_COMMAND:New( self.EscortClient, "Go below radar and evade fire", self.EscortMenuEvasion, ESCORT._ROT, { ParamSelf = self, ParamFunction = self.EscortGroup:OptionROTVertical(), ParamMessage = "Evading on enemy fire with vertical manoeuvres!" } )
      end
    end
  end

  return self
end

--- Defines a menu to let the escort resume its mission from a waypoint on its route.
-- All rules of engagement will appear under the menu **Resume mission from**.
-- @param #ESCORT self
-- @return #ESCORT
function ESCORT:MenuResumeMission()
  self:F()

  if not self.EscortMenuResumeMission then
    -- Mission Resume Menu Root
    self.EscortMenuResumeMission = MENU_CLIENT:New( self.EscortClient, "Resume mission from", self.EscortMenu )
  end

  return self
end


--- @param #MENUPARAM MenuParam
function ESCORT._HoldPosition( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  local OrbitGroup = MenuParam.ParamOrbitGroup -- Group#GROUP
  local OrbitUnit = OrbitGroup:GetUnit(1) -- Unit#UNIT
  local OrbitHeight = MenuParam.ParamHeight
  local OrbitSeconds = MenuParam.ParamSeconds -- Not implemented yet

  self.FollowScheduler:Stop()

  local PointFrom = {}
  local GroupPoint = EscortGroup:GetUnit(1):GetPointVec3()
  PointFrom = {}
  PointFrom.x = GroupPoint.x
  PointFrom.y = GroupPoint.z
  PointFrom.speed = 250
  PointFrom.type = AI.Task.WaypointType.TURNING_POINT
  PointFrom.alt = GroupPoint.y
  PointFrom.alt_type = AI.Task.AltitudeType.BARO

  local OrbitPoint = OrbitUnit:GetVec2()
  local PointTo = {}
  PointTo.x = OrbitPoint.x
  PointTo.y = OrbitPoint.y
  PointTo.speed = 250
  PointTo.type = AI.Task.WaypointType.TURNING_POINT
  PointTo.alt = OrbitHeight
  PointTo.alt_type = AI.Task.AltitudeType.BARO
  PointTo.task = EscortGroup:TaskOrbitCircleAtVec2( OrbitPoint, OrbitHeight, 0 )

  local Points = { PointFrom, PointTo }

  EscortGroup:OptionROEHoldFire()
  EscortGroup:OptionROTPassiveDefense()

  EscortGroup:SetTask( EscortGroup:TaskRoute( Points ) )
  EscortGroup:MessageToClient( "Orbiting at location.", 10, EscortClient )

end

--- @param #MENUPARAM MenuParam
function ESCORT._JoinUpAndFollow( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  self.Distance = MenuParam.ParamDistance

  self:JoinUpAndFollow( EscortGroup, EscortClient, self.Distance )
end

--- JoinsUp and Follows a CLIENT.
-- @param Escort#ESCORT self
-- @param Group#GROUP EscortGroup
-- @param Client#CLIENT EscortClient
-- @param DCSTypes#Distance Distance
function ESCORT:JoinUpAndFollow( EscortGroup, EscortClient, Distance )
  self:F( { EscortGroup, EscortClient, Distance } )

  self.FollowScheduler:Stop()

  EscortGroup:OptionROEHoldFire()
  EscortGroup:OptionROTPassiveDefense()

  self.EscortMode = ESCORT.MODE.FOLLOW

  self.CT1 = 0
  self.GT1 = 0
  self.FollowScheduler:Start()

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
      self.ReportTargetsScheduler = SCHEDULER:New( self, self._ReportTargetsScheduler, {}, 1, 30 )
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

  self.FollowScheduler:Stop()

  if EscortGroup:IsHelicopter() then
    SCHEDULER:New( EscortGroup, EscortGroup.PushTask,
      { EscortGroup:TaskControlled(
          EscortGroup:TaskOrbitCircle( 200, 20 ),
          EscortGroup:TaskCondition( nil, nil, nil, nil, ScanDuration, nil )
        )
      },
      1
    )
  elseif EscortGroup:IsAirPlane() then
    SCHEDULER:New( EscortGroup, EscortGroup.PushTask,
      { EscortGroup:TaskControlled(
          EscortGroup:TaskOrbitCircle( 1000, 500 ),
          EscortGroup:TaskCondition( nil, nil, nil, nil, ScanDuration, nil )
        )
      },
      1
    )
  end

  EscortGroup:MessageToClient( "Scanning targets for " .. ScanDuration .. " seconds.", ScanDuration, EscortClient )

  if self.EscortMode == ESCORT.MODE.FOLLOW then
    self.FollowScheduler:Start()
  end

end

--- @param Group#GROUP EscortGroup
function _Resume( EscortGroup )
  env.info( '_Resume' )

  local Escort = EscortGroup:GetState( EscortGroup, "Escort" )
  env.info( "EscortMode = "  .. Escort.EscortMode )
  if Escort.EscortMode == ESCORT.MODE.FOLLOW then
    Escort:JoinUpAndFollow( EscortGroup, Escort.EscortClient, Escort.Distance )
  end

end

--- @param #MENUPARAM MenuParam
function ESCORT._AttackTarget( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  
  local EscortClient = self.EscortClient
  local AttackUnit = MenuParam.ParamUnit -- Unit#UNIT

  self.FollowScheduler:Stop()

  self:T( AttackUnit )

  if EscortGroup:IsAir() then
    EscortGroup:OptionROEOpenFire()
    EscortGroup:OptionROTPassiveDefense()
    EscortGroup:SetState( EscortGroup, "Escort", self )
    SCHEDULER:New( EscortGroup,
      EscortGroup.PushTask,
      { EscortGroup:TaskCombo(
          { EscortGroup:TaskAttackUnit( AttackUnit ),
            EscortGroup:TaskFunction( 1, 2, "_Resume", { "''" } )
          }
        )
      }, 10
    )
  else
    SCHEDULER:New( EscortGroup,
      EscortGroup.PushTask,
      { EscortGroup:TaskCombo(
          { EscortGroup:TaskFireAtPoint( AttackUnit:GetVec2(), 50 )
          }
        )
      }, 10
    )
  end
  
  EscortGroup:MessageToClient( "Engaging Designated Unit!", 10, EscortClient )

end

--- @param #MENUPARAM MenuParam
function ESCORT._AssistTarget( MenuParam )

  local self = MenuParam.ParamSelf
  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient
  local EscortGroupAttack = MenuParam.ParamEscortGroup
  local AttackUnit = MenuParam.ParamUnit -- Unit#UNIT

  self.FollowScheduler:Stop()

  self:T( AttackUnit )

  if EscortGroupAttack:IsAir() then
    EscortGroupAttack:OptionROEOpenFire()
    EscortGroupAttack:OptionROTVertical()
    SCHDULER:New( EscortGroupAttack,
      EscortGroupAttack.PushTask,
      { EscortGroupAttack:TaskCombo(
          { EscortGroupAttack:TaskAttackUnit( AttackUnit ),
            EscortGroupAttack:TaskOrbitCircle( 500, 350 )
          }
        )
      }, 10
    )
  else
    SCHEDULER:New( EscortGroupAttack,
      EscortGroupAttack.PushTask,
      { EscortGroupAttack:TaskCombo(
          { EscortGroupAttack:TaskFireAtPoint( AttackUnit:GetVec2(), 50 )
          }
        )
      }, 10
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

  self.FollowScheduler:Stop()

  local WayPoints = EscortGroup:GetTaskRoute()
  self:T( WayPoint, WayPoints )

  for WayPointIgnore = 1, WayPoint do
    table.remove( WayPoints, 1 )
  end

  SCHEDULER:New( EscortGroup, EscortGroup.SetTask, { EscortGroup:TaskRoute( WayPoints ) }, 1 )

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
function ESCORT:_FollowScheduler()
  self:F( { self.FollowDistance } )

  self:T( {self.EscortClient.UnitName, self.EscortGroup.GroupName } )
  if self.EscortGroup:IsAlive() and self.EscortClient:IsAlive() then

    local ClientUnit = self.EscortClient:GetClientGroupUnit()
    local GroupUnit = self.EscortGroup:GetUnit( 1 )
    local FollowDistance = self.FollowDistance
    
    self:T( {ClientUnit.UnitName, GroupUnit.UnitName } )

    if self.CT1 == 0 and self.GT1 == 0 then
      self.CV1 = ClientUnit:GetPointVec3()
      self:T( { "self.CV1", self.CV1 } )
      self.CT1 = timer.getTime()
      self.GV1 = GroupUnit:GetPointVec3()
      self.GT1 = timer.getTime()
    else
      local CT1 = self.CT1
      local CT2 = timer.getTime()
      local CV1 = self.CV1
      local CV2 = ClientUnit:GetPointVec3()
      self.CT1 = CT2
      self.CV1 = CV2

      local CD = ( ( CV2.x - CV1.x )^2 + ( CV2.y - CV1.y )^2 + ( CV2.z - CV1.z )^2 ) ^ 0.5
      local CT = CT2 - CT1

      local CS = ( 3600 / CT ) * ( CD / 1000 )

      self:T2( { "Client:", CS, CD, CT, CV2, CV1, CT2, CT1 } )

      local GT1 = self.GT1
      local GT2 = timer.getTime()
      local GV1 = self.GV1
      local GV2 = GroupUnit:GetPointVec3()
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
      
      if self.SmokeDirectionVector == true then
        trigger.action.smoke( GDV, trigger.smokeColor.Red )
      end
      
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

      self:T( { "Client Speed, Escort Speed, Speed, FollowDistance, Time:", CS, GS, Speed, FollowDistance, Time } )

      -- Now route the escort to the desired point with the desired speed.
      self.EscortGroup:TaskRouteToVec3( GDV, Speed / 3.6 ) -- DCS models speed in Mps (Miles per second)
    end

    return true
  end

  return false
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

        local EscortTargetUnit = UNIT:Find( EscortObject )
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


        local EscortTargetUnitPositionVec3 = EscortTargetUnit:GetPointVec3()
        local EscortPositionVec3 = self.EscortGroup:GetPointVec3()
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

    if self.EscortMenuTargetAssistance then
      self.EscortMenuTargetAssistance:RemoveSubMenus()
    end

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

            local EscortTargetUnitPositionVec3 = ClientEscortTargetData.AttackUnit:GetPointVec3()
            local EscortPositionVec3 = self.EscortGroup:GetPointVec3()
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
              if self.EscortMenuTargetAssistance then
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

    if self.EscortMenuResumeMission then
      self.EscortMenuResumeMission:RemoveSubMenus()

      --    if self.EscortMenuResumeWayPoints then
      --      for MenuIndex = 1, #self.EscortMenuResumeWayPoints do
      --        self:T( { "Remove Menu:", self.EscortMenuResumeWayPoints[MenuIndex] } )
      --        self.EscortMenuResumeWayPoints[MenuIndex] = self.EscortMenuResumeWayPoints[MenuIndex]:Remove()
      --      end
      --    end

      local TaskPoints = self:RegisterRoute()
      for WayPointID, WayPoint in pairs( TaskPoints ) do
        local EscortPositionVec3 = self.EscortGroup:GetPointVec3()
        local Distance = ( ( WayPoint.x - EscortPositionVec3.x )^2 +
          ( WayPoint.y - EscortPositionVec3.z )^2
          ) ^ 0.5 / 1000
        MENU_CLIENT_COMMAND:New( self.EscortClient, "Waypoint " .. WayPointID .. " at " .. string.format( "%.2f", Distance ).. "km", self.EscortMenuResumeMission, ESCORT._ResumeMission, { ParamSelf = self, ParamWayPoint = WayPointID } )
      end
    end

    return true
  end
  
  return false
end
