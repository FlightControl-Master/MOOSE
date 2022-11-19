--- **Functional** - Taking the lead of AI escorting your flight.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * Escort navigation commands.
--   * Escort hold at position commands.
--   * Escorts reporting detected targets.
--   * Escorts scanning targets in advance.
--   * Escorts attacking specific targets.
--   * Request assistance from other groups for attack.
--   * Manage rule of engagement of escorts.
--   * Manage the allowed evasion techniques of escorts.
--   * Make escort to execute a defined mission or path.
--   * Escort tactical situation reporting.
-- 
-- ===
-- 
-- ## Missions:
-- 
-- [ESC - Escorting](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/ESC%20-%20Escorting)
-- 
-- ===
-- 
-- Allows you to interact with escorting AI on your flight and take the lead.
-- 
-- Each escorting group can be commanded with a whole set of radio commands (radio menu in your flight, and then F10).
--
-- The radio commands will vary according the category of the group. The richest set of commands are with Helicopters and AirPlanes.
-- Ships and Ground troops will have a more limited set, but they can provide support through the bombing of targets designated by the other escorts.
--
-- # RADIO MENUs that can be created:
-- 
-- Find a summary below of the current available commands:
--
-- ## Navigation ...:
-- 
-- Escort group navigation functions:
--
--   * **"Join-Up and Follow at x meters":** The escort group fill follow you at about x meters, and they will follow you.
--   * **"Flare":** Provides menu commands to let the escort group shoot a flare in the air in a color.
--   * **"Smoke":** Provides menu commands to let the escort group smoke the air in a color. Note that smoking is only available for ground and naval troops.
--
-- ## Hold position ...:
-- 
-- Escort group navigation functions:
--
--   * **"At current location":** Stops the escort group and they will hover 30 meters above the ground at the position they stopped.
--   * **"At client location":** Stops the escort group and they will hover 30 meters above the ground at the position they stopped.
--
-- ## Report targets ...:
-- 
-- Report targets will make the escort group to report any target that it identifies within a 8km range. Any detected target can be attacked using the 4. Attack nearby targets function. (see below).
--
--   * **"Report now":** Will report the current detected targets.
--   * **"Report targets on":** Will make the escort group to report detected targets and will fill the "Attack nearby targets" menu list.
--   * **"Report targets off":** Will stop detecting targets.
--
-- ## Scan targets ...:
-- 
-- Menu items to pop-up the escort group for target scanning. After scanning, the escort group will resume with the mission or defined task.
--
--   * **"Scan targets 30 seconds":** Scan 30 seconds for targets.
--   * **"Scan targets 60 seconds":** Scan 60 seconds for targets.
--
-- ## Attack targets ...:
-- 
-- This menu item will list all detected targets within a 15km range. Depending on the level of detection (known/unknown) and visuality, the targets type will also be listed.
--
-- ## Request assistance from ...:
-- 
-- This menu item will list all detected targets within a 15km range, as with the menu item **Attack Targets**.
-- This menu item allows to request attack support from other escorts supporting the current client group.
-- eg. the function allows a player to request support from the Ship escort to attack a target identified by the Plane escort with its Tomahawk missiles.
-- eg. the function allows a player to request support from other Planes escorting to bomb the unit with illumination missiles or bombs, so that the main plane escort can attack the area.
--
-- ## ROE ...:
-- 
-- Sets the Rules of Engagement (ROE) of the escort group when in flight.
--
--   * **"Hold Fire":** The escort group will hold fire.
--   * **"Return Fire":** The escort group will return fire.
--   * **"Open Fire":** The escort group will open fire on designated targets.
--   * **"Weapon Free":** The escort group will engage with any target.
--
-- ## Evasion ...:
-- 
-- Will define the evasion techniques that the escort group will perform during flight or combat.
--
--   * **"Fight until death":** The escort group will have no reaction to threats.
--   * **"Use flares, chaff and jammers":** The escort group will use passive defense using flares and jammers. No evasive manoeuvres are executed.
--   * **"Evade enemy fire":** The rescort group will evade enemy fire before firing.
--   * **"Go below radar and evade fire":** The escort group will perform evasive vertical manoeuvres.
--
-- ## Resume Mission ...:
-- 
-- Escort groups can have their own mission. This menu item will allow the escort group to resume their Mission from a given waypoint.
-- Note that this is really fantastic, as you now have the dynamic of taking control of the escort groups, and allowing them to resume their path or mission.
--
-- ===
-- 
-- ### Authors: **FlightControl** 
-- 
-- ===
--
-- @module Functional.Escort
-- @image Escorting.JPG



--- @type ESCORT
-- @extends Core.Base#BASE
-- @field Wrapper.Client#CLIENT EscortClient
-- @field Wrapper.Group#GROUP EscortGroup
-- @field #string EscortName
-- @field #ESCORT.MODE EscortMode The mode the escort is in.
-- @field Core.Scheduler#SCHEDULER FollowScheduler The instance of the SCHEDULER class.
-- @field #number FollowDistance The current follow distance.
-- @field #boolean ReportTargets If true, nearby targets are reported.
-- @Field DCS#AI.Option.Air.val.ROE OptionROE Which ROE is set to the EscortGroup.
-- @field DCS#AI.Option.Air.val.REACTION_ON_THREAT OptionReactionOnThreat Which REACTION_ON_THREAT is set to the EscortGroup.
-- @field FunctionalMENU_GROUPDETECTION_BASE Detection

--- ESCORT class
-- 
-- # ESCORT construction methods.
-- 
-- Create a new SPAWN object with the @{#ESCORT.New} method:
--
--  * @{#ESCORT.New}: Creates a new ESCORT object from a @{Wrapper.Group#GROUP} for a @{Wrapper.Client#CLIENT}, with an optional briefing text.
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
-- @field #ESCORT
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
-- @param Wrapper.Client#CLIENT EscortClient The client escorted by the EscortGroup.
-- @param Wrapper.Group#GROUP EscortGroup The group AI escorting the EscortClient.
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
  
  local self = BASE:Inherit( self, BASE:New() ) -- #ESCORT
  self:F( { EscortClient, EscortGroup, EscortName } )

  self.EscortClient = EscortClient -- Wrapper.Client#CLIENT
  self.EscortGroup = EscortGroup -- Wrapper.Group#GROUP
  self.EscortName = EscortName
  self.EscortBriefing = EscortBriefing
 
  self.EscortSetGroup = SET_GROUP:New()
  self.EscortSetGroup:AddObject( self.EscortGroup )
  self.EscortSetGroup:Flush()
  self.Detection = DETECTION_UNITS:New( self.EscortSetGroup, 15000 )
  
  self.EscortGroup.Detection = self.Detection
  
  -- Set EscortGroup known at EscortClient.
  if not self.EscortClient._EscortGroups then
    self.EscortClient._EscortGroups = {}
  end

  if not self.EscortClient._EscortGroups[EscortGroup:GetName()] then
    self.EscortClient._EscortGroups[EscortGroup:GetName()] = {}
    self.EscortClient._EscortGroups[EscortGroup:GetName()].EscortGroup = self.EscortGroup
    self.EscortClient._EscortGroups[EscortGroup:GetName()].EscortName = self.EscortName
    self.EscortClient._EscortGroups[EscortGroup:GetName()].Detection = self.EscortGroup.Detection
  end

  self.EscortMenu = MENU_GROUP:New( self.EscortClient:GetGroup(), self.EscortName )

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

  self.FollowScheduler, self.FollowSchedule = SCHEDULER:New( self, self._FollowScheduler, {}, 1, .5, .01 )
  self.FollowScheduler:Stop( self.FollowSchedule )

  self.EscortMode = ESCORT.MODE.MISSION
  
 
  return self
end

--- Set a Detection method for the EscortClient to be reported upon.
-- Detection methods are based on the derived classes from DETECTION_BASE.
-- @param #ESCORT self
-- @param Function.Detection#DETECTION_BASE Detection
function ESCORT:SetDetection( Detection )

  self.Detection = Detection
  self.EscortGroup.Detection = self.Detection
  self.EscortClient._EscortGroups[self.EscortGroup:GetName()].Detection = self.EscortGroup.Detection
  
  Detection:__Start( 1 )
  
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
-- @param DCS#Distance Distance The distance in meters that the escort needs to follow the client.
-- @return #ESCORT
function ESCORT:MenuFollowAt( Distance )
  self:F(Distance)

  if self.EscortGroup:IsAir() then
    if not self.EscortMenuReportNavigation then
      self.EscortMenuReportNavigation = MENU_GROUP:New( self.EscortClient:GetGroup(), "Navigation", self.EscortMenu )
    end

    if not self.EscortMenuJoinUpAndFollow then
      self.EscortMenuJoinUpAndFollow = {}
    end

    self.EscortMenuJoinUpAndFollow[#self.EscortMenuJoinUpAndFollow+1] = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Join-Up and Follow at " .. Distance, self.EscortMenuReportNavigation, ESCORT._JoinUpAndFollow, self, Distance )

    self.EscortMode = ESCORT.MODE.FOLLOW
  end

  return self
end

--- Defines a menu slot to let the escort hold at their current position and stay low with a specified height during a specified time in seconds.
-- This menu will appear under **Hold position**.
-- @param #ESCORT self
-- @param DCS#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCS#Time Seconds Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #ESCORT
-- TODO: Implement Seconds parameter. Challenge is to first develop the "continue from last activity" function.
function ESCORT:MenuHoldAtEscortPosition( Height, Seconds, MenuTextFormat )
  self:F( { Height, Seconds, MenuTextFormat } )

  if self.EscortGroup:IsAir() then

    if not self.EscortMenuHold then
      self.EscortMenuHold = MENU_GROUP:New( self.EscortClient:GetGroup(), "Hold position", self.EscortMenu )
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

    self.EscortMenuHoldPosition[#self.EscortMenuHoldPosition+1] = MENU_GROUP_COMMAND
      :New(
        self.EscortClient:GetGroup(),
        MenuText,
        self.EscortMenuHold,
        ESCORT._HoldPosition,
        self,
        self.EscortGroup,
        Height,
        Seconds
      )
  end

  return self
end


--- Defines a menu slot to let the escort hold at the client position and stay low with a specified height during a specified time in seconds.
-- This menu will appear under **Navigation**.
-- @param #ESCORT self
-- @param DCS#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCS#Time Seconds Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain one or two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #ESCORT
-- TODO: Implement Seconds parameter. Challenge is to first develop the "continue from last activity" function.
function ESCORT:MenuHoldAtLeaderPosition( Height, Seconds, MenuTextFormat )
  self:F( { Height, Seconds, MenuTextFormat } )

  if self.EscortGroup:IsAir() then

    if not self.EscortMenuHold then
      self.EscortMenuHold = MENU_GROUP:New( self.EscortClient:GetGroup(), "Hold position", self.EscortMenu )
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

    self.EscortMenuHoldAtLeaderPosition[#self.EscortMenuHoldAtLeaderPosition+1] = MENU_GROUP_COMMAND
      :New(
        self.EscortClient:GetGroup(),
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
-- @param DCS#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCS#Time Seconds Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain one or two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #ESCORT
function ESCORT:MenuScanForTargets( Height, Seconds, MenuTextFormat )
  self:F( { Height, Seconds, MenuTextFormat } )

  if self.EscortGroup:IsAir() then
    if not self.EscortMenuScan then
      self.EscortMenuScan = MENU_GROUP:New( self.EscortClient:GetGroup(), "Scan for targets", self.EscortMenu )
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

    self.EscortMenuScanForTargets[#self.EscortMenuScanForTargets+1] = MENU_GROUP_COMMAND
      :New(
        self.EscortClient:GetGroup(),
        MenuText,
        self.EscortMenuScan,
        ESCORT._ScanTargets,
        self,
        30
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
    self.EscortMenuReportNavigation = MENU_GROUP:New( self.EscortClient:GetGroup(), "Navigation", self.EscortMenu )
  end

  local MenuText = ""
  if not MenuTextFormat then
    MenuText = "Flare"
  else
    MenuText = MenuTextFormat
  end

  if not self.EscortMenuFlare then
    self.EscortMenuFlare = MENU_GROUP:New( self.EscortClient:GetGroup(), MenuText, self.EscortMenuReportNavigation, ESCORT._Flare, self )
    self.EscortMenuFlareGreen  = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Release green flare",  self.EscortMenuFlare, ESCORT._Flare, self, FLARECOLOR.Green,  "Released a green flare!"   )
    self.EscortMenuFlareRed    = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Release red flare",    self.EscortMenuFlare, ESCORT._Flare, self, FLARECOLOR.Red,    "Released a red flare!"     )
    self.EscortMenuFlareWhite  = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Release white flare",  self.EscortMenuFlare, ESCORT._Flare, self, FLARECOLOR.White,  "Released a white flare!"   )
    self.EscortMenuFlareYellow = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Release yellow flare", self.EscortMenuFlare, ESCORT._Flare, self, FLARECOLOR.Yellow, "Released a yellow flare!"  )
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
      self.EscortMenuReportNavigation = MENU_GROUP:New( self.EscortClient:GetGroup(), "Navigation", self.EscortMenu )
    end

    local MenuText = ""
    if not MenuTextFormat then
      MenuText = "Smoke"
    else
      MenuText = MenuTextFormat
    end

    if not self.EscortMenuSmoke then
      self.EscortMenuSmoke = MENU_GROUP:New( self.EscortClient:GetGroup(), "Smoke", self.EscortMenuReportNavigation, ESCORT._Smoke, self )
      self.EscortMenuSmokeGreen  = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Release green smoke",  self.EscortMenuSmoke, ESCORT._Smoke, self, SMOKECOLOR.Green,  "Releasing green smoke!"   )
      self.EscortMenuSmokeRed    = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Release red smoke",    self.EscortMenuSmoke, ESCORT._Smoke, self, SMOKECOLOR.Red,    "Releasing red smoke!"     )
      self.EscortMenuSmokeWhite  = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Release white smoke",  self.EscortMenuSmoke, ESCORT._Smoke, self, SMOKECOLOR.White,  "Releasing white smoke!"   )
      self.EscortMenuSmokeOrange = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Release orange smoke", self.EscortMenuSmoke, ESCORT._Smoke, self, SMOKECOLOR.Orange, "Releasing orange smoke!"  )
      self.EscortMenuSmokeBlue   = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Release blue smoke",   self.EscortMenuSmoke, ESCORT._Smoke, self, SMOKECOLOR.Blue,   "Releasing blue smoke!"    )
    end
  end

  return self
end

--- Defines a menu slot to let the escort report their current detected targets with a specified time interval in seconds.
-- This menu will appear under **Report targets**.
-- Note that if a report targets menu is not specified, no targets will be detected by the escort, and the attack and assisted attack menus will not be displayed.
-- @param #ESCORT self
-- @param DCS#Time Seconds Optional parameter that lets the escort report their current detected targets after specified time interval in seconds. The default time is 30 seconds.
-- @return #ESCORT
function ESCORT:MenuReportTargets( Seconds )
  self:F( { Seconds } )

  if not self.EscortMenuReportNearbyTargets then
    self.EscortMenuReportNearbyTargets = MENU_GROUP:New( self.EscortClient:GetGroup(), "Report targets", self.EscortMenu )
  end

  if not Seconds then
    Seconds = 30
  end

  -- Report Targets
  self.EscortMenuReportNearbyTargetsNow = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Report targets now!", self.EscortMenuReportNearbyTargets, ESCORT._ReportNearbyTargetsNow, self )
  self.EscortMenuReportNearbyTargetsOn = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Report targets on", self.EscortMenuReportNearbyTargets, ESCORT._SwitchReportNearbyTargets, self, true )
  self.EscortMenuReportNearbyTargetsOff = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Report targets off", self.EscortMenuReportNearbyTargets, ESCORT._SwitchReportNearbyTargets, self, false )

  -- Attack Targets
  self.EscortMenuAttackNearbyTargets = MENU_GROUP:New( self.EscortClient:GetGroup(), "Attack targets", self.EscortMenu )


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
  self.EscortMenuTargetAssistance = MENU_GROUP:New( self.EscortClient:GetGroup(), "Request assistance from", self.EscortMenu )

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
    self.EscortMenuROE = MENU_GROUP:New( self.EscortClient:GetGroup(), "ROE", self.EscortMenu )
    if self.EscortGroup:OptionROEHoldFirePossible() then
      self.EscortMenuROEHoldFire = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Hold Fire", self.EscortMenuROE, ESCORT._ROE, self, self.EscortGroup:OptionROEHoldFire(), "Holding weapons!" )
    end
    if self.EscortGroup:OptionROEReturnFirePossible() then
      self.EscortMenuROEReturnFire = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Return Fire", self.EscortMenuROE, ESCORT._ROE, self, self.EscortGroup:OptionROEReturnFire(), "Returning fire!" )
    end
    if self.EscortGroup:OptionROEOpenFirePossible() then
      self.EscortMenuROEOpenFire = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Open Fire", self.EscortMenuROE, ESCORT._ROE, self, self.EscortGroup:OptionROEOpenFire(), "Opening fire on designated targets!!" )
    end
    if self.EscortGroup:OptionROEWeaponFreePossible() then
      self.EscortMenuROEWeaponFree = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Weapon Free", self.EscortMenuROE, ESCORT._ROE, self, self.EscortGroup:OptionROEWeaponFree(), "Opening fire on targets of opportunity!" )
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
      self.EscortMenuEvasion = MENU_GROUP:New( self.EscortClient:GetGroup(), "Evasion", self.EscortMenu )
      if self.EscortGroup:OptionROTNoReactionPossible() then
        self.EscortMenuEvasionNoReaction = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Fight until death", self.EscortMenuEvasion, ESCORT._ROT, self, self.EscortGroup:OptionROTNoReaction(), "Fighting until death!" )
      end
      if self.EscortGroup:OptionROTPassiveDefensePossible() then
        self.EscortMenuEvasionPassiveDefense = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Use flares, chaff and jammers", self.EscortMenuEvasion, ESCORT._ROT, self, self.EscortGroup:OptionROTPassiveDefense(), "Defending using jammers, chaff and flares!" )
      end
      if self.EscortGroup:OptionROTEvadeFirePossible() then
        self.EscortMenuEvasionEvadeFire = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Evade enemy fire", self.EscortMenuEvasion, ESCORT._ROT, self, self.EscortGroup:OptionROTEvadeFire(), "Evading on enemy fire!" )
      end
      if self.EscortGroup:OptionROTVerticalPossible() then
        self.EscortMenuOptionEvasionVertical = MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(), "Go below radar and evade fire", self.EscortMenuEvasion, ESCORT._ROT, self, self.EscortGroup:OptionROTVertical(), "Evading on enemy fire with vertical manoeuvres!" )
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
    self.EscortMenuResumeMission = MENU_GROUP:New( self.EscortClient:GetGroup(), "Resume mission from", self.EscortMenu )
  end

  return self
end


--- @param #MENUPARAM MenuParam
function ESCORT:_HoldPosition( OrbitGroup, OrbitHeight, OrbitSeconds )

  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  local OrbitUnit = OrbitGroup:GetUnit(1) -- Wrapper.Unit#UNIT

  self.FollowScheduler:Stop( self.FollowSchedule )

  local PointFrom = {}
  local GroupVec3 = EscortGroup:GetUnit(1):GetVec3()
  PointFrom = {}
  PointFrom.x = GroupVec3.x
  PointFrom.y = GroupVec3.z
  PointFrom.speed = 250
  PointFrom.type = AI.Task.WaypointType.TURNING_POINT
  PointFrom.alt = GroupVec3.y
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
function ESCORT:_JoinUpAndFollow( Distance )

  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  self.Distance = Distance

  self:JoinUpAndFollow( EscortGroup, EscortClient, self.Distance )
end

--- JoinsUp and Follows a CLIENT.
-- @param Functional.Escort#ESCORT self
-- @param Wrapper.Group#GROUP EscortGroup
-- @param Wrapper.Client#CLIENT EscortClient
-- @param DCS#Distance Distance
function ESCORT:JoinUpAndFollow( EscortGroup, EscortClient, Distance )
  self:F( { EscortGroup, EscortClient, Distance } )

  self.FollowScheduler:Stop( self.FollowSchedule )

  EscortGroup:OptionROEHoldFire()
  EscortGroup:OptionROTPassiveDefense()

  self.EscortMode = ESCORT.MODE.FOLLOW

  self.CT1 = 0
  self.GT1 = 0
  self.FollowScheduler:Start( self.FollowSchedule )

  EscortGroup:MessageToClient( "Rejoining and Following at " .. Distance .. "!", 30, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT:_Flare( Color, Message )

  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  EscortGroup:GetUnit(1):Flare( Color )
  EscortGroup:MessageToClient( Message, 10, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT:_Smoke( Color, Message )

  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  EscortGroup:GetUnit(1):Smoke( Color )
  EscortGroup:MessageToClient( Message, 10, EscortClient )
end


--- @param #MENUPARAM MenuParam
function ESCORT:_ReportNearbyTargetsNow()

  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  self:_ReportTargetsScheduler()

end

function ESCORT:_SwitchReportNearbyTargets( ReportTargets )

  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  self.ReportTargets = ReportTargets

  if self.ReportTargets then
    if not self.ReportTargetsScheduler then
      self.ReportTargetsScheduler:Schedule( self, self._ReportTargetsScheduler, {}, 1, 30 )
    end
  else
    routines.removeFunction( self.ReportTargetsScheduler )
    self.ReportTargetsScheduler = nil
  end
end

--- @param #MENUPARAM MenuParam
function ESCORT:_ScanTargets( ScanDuration )

  local EscortGroup = self.EscortGroup -- Wrapper.Group#GROUP
  local EscortClient = self.EscortClient

  self.FollowScheduler:Stop( self.FollowSchedule )

  if EscortGroup:IsHelicopter() then
    EscortGroup:PushTask(
      EscortGroup:TaskControlled(
        EscortGroup:TaskOrbitCircle( 200, 20 ),
        EscortGroup:TaskCondition( nil, nil, nil, nil, ScanDuration, nil )
      ), 1 )
  elseif EscortGroup:IsAirPlane() then
    EscortGroup:PushTask(
      EscortGroup:TaskControlled(
        EscortGroup:TaskOrbitCircle( 1000, 500 ),
        EscortGroup:TaskCondition( nil, nil, nil, nil, ScanDuration, nil )
      ), 1 )
  end

  EscortGroup:MessageToClient( "Scanning targets for " .. ScanDuration .. " seconds.", ScanDuration, EscortClient )

  if self.EscortMode == ESCORT.MODE.FOLLOW then
    self.FollowScheduler:Start( self.FollowSchedule )
  end

end

--- @param Wrapper.Group#GROUP EscortGroup
function _Resume( EscortGroup )
  env.info( '_Resume' )

  local Escort = EscortGroup:GetState( EscortGroup, "Escort" )
  env.info( "EscortMode = "  .. Escort.EscortMode )
  if Escort.EscortMode == ESCORT.MODE.FOLLOW then
    Escort:JoinUpAndFollow( EscortGroup, Escort.EscortClient, Escort.Distance )
  end

end

--- @param #ESCORT self
-- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
function ESCORT:_AttackTarget( DetectedItem )

  local EscortGroup = self.EscortGroup -- Wrapper.Group#GROUP
  self:F( EscortGroup )
  
  local EscortClient = self.EscortClient

  self.FollowScheduler:Stop( self.FollowSchedule )

  if EscortGroup:IsAir() then
    EscortGroup:OptionROEOpenFire()
    EscortGroup:OptionROTPassiveDefense()
    EscortGroup:SetState( EscortGroup, "Escort", self )

    local DetectedSet = self.Detection:GetDetectedItemSet( DetectedItem )
    
    local Tasks = {}

    DetectedSet:ForEachUnit(
      --- @param Wrapper.Unit#UNIT DetectedUnit
      function( DetectedUnit, Tasks )
        if DetectedUnit:IsAlive() then
          Tasks[#Tasks+1] = EscortGroup:TaskAttackUnit( DetectedUnit )
        end
      end, Tasks
    )    

    Tasks[#Tasks+1] = EscortGroup:TaskFunction( "_Resume", { "''" } )
    
    EscortGroup:SetTask( 
      EscortGroup:TaskCombo(
        Tasks
      ), 1
    )
    
  else
  
    local DetectedSet = self.Detection:GetDetectedItemSet( DetectedItem )
    
    local Tasks = {}

    DetectedSet:ForEachUnit(
      --- @param Wrapper.Unit#UNIT DetectedUnit
      function( DetectedUnit, Tasks )
        if DetectedUnit:IsAlive() then
          Tasks[#Tasks+1] = EscortGroup:TaskFireAtPoint( DetectedUnit:GetVec2(), 50 )
        end
      end, Tasks
    )    

    EscortGroup:SetTask( 
      EscortGroup:TaskCombo(
        Tasks
      ), 1
    )

  end
  
  EscortGroup:MessageToClient( "Engaging Designated Unit!", 10, EscortClient )

end

--- 
--- @param #ESCORT self
-- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
function ESCORT:_AssistTarget( EscortGroupAttack, DetectedItem )

  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  self.FollowScheduler:Stop( self.FollowSchedule )

  if EscortGroupAttack:IsAir() then
    EscortGroupAttack:OptionROEOpenFire()
    EscortGroupAttack:OptionROTVertical()
    
    local DetectedSet = self.Detection:GetDetectedItemSet( DetectedItem )
    
    local Tasks = {}

    DetectedSet:ForEachUnit(
      --- @param Wrapper.Unit#UNIT DetectedUnit
      function( DetectedUnit, Tasks )
        if DetectedUnit:IsAlive() then
          Tasks[#Tasks+1] = EscortGroupAttack:TaskAttackUnit( DetectedUnit )
        end
      end, Tasks
    )    

    Tasks[#Tasks+1] = EscortGroupAttack:TaskOrbitCircle( 500, 350 )
    
    EscortGroupAttack:SetTask( 
      EscortGroupAttack:TaskCombo(
        Tasks
      ), 1
    )

  else
    local DetectedSet = self.Detection:GetDetectedItemSet( DetectedItem )
    
    local Tasks = {}

    DetectedSet:ForEachUnit(
      --- @param Wrapper.Unit#UNIT DetectedUnit
      function( DetectedUnit, Tasks )
        if DetectedUnit:IsAlive() then
          Tasks[#Tasks+1] = EscortGroupAttack:TaskFireAtPoint( DetectedUnit:GetVec2(), 50 )
        end
      end, Tasks
    )    

    EscortGroupAttack:SetTask( 
      EscortGroupAttack:TaskCombo(
        Tasks
      ), 1
    )

  end

  EscortGroupAttack:MessageToClient( "Assisting with the destroying the enemy unit!", 10, EscortClient )

end

--- @param #MENUPARAM MenuParam
function ESCORT:_ROE( EscortROEFunction, EscortROEMessage )

  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  pcall( function() EscortROEFunction() end )
  EscortGroup:MessageToClient( EscortROEMessage, 10, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT:_ROT( EscortROTFunction, EscortROTMessage )

  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  pcall( function() EscortROTFunction() end )
  EscortGroup:MessageToClient( EscortROTMessage, 10, EscortClient )
end

--- @param #MENUPARAM MenuParam
function ESCORT:_ResumeMission( WayPoint )

  local EscortGroup = self.EscortGroup
  local EscortClient = self.EscortClient

  self.FollowScheduler:Stop( self.FollowSchedule )

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

  local EscortGroup = self.EscortGroup -- Wrapper.Group#GROUP

  local TaskPoints = EscortGroup:GetTaskRoute()

  self:T( TaskPoints )

  return TaskPoints
end

--- @param Functional.Escort#ESCORT self
function ESCORT:_FollowScheduler()
  self:F( { self.FollowDistance } )

  self:T( {self.EscortClient.UnitName, self.EscortGroup.GroupName } )
  if self.EscortGroup:IsAlive() and self.EscortClient:IsAlive() then

    local ClientUnit = self.EscortClient:GetClientGroupUnit()
    local GroupUnit = self.EscortGroup:GetUnit( 1 )
    local FollowDistance = self.FollowDistance
    
    self:T( {ClientUnit.UnitName, GroupUnit.UnitName } )

    if self.CT1 == 0 and self.GT1 == 0 then
      self.CV1 = ClientUnit:GetVec3()
      self:T( { "self.CV1", self.CV1 } )
      self.CT1 = timer.getTime()
      self.GV1 = GroupUnit:GetVec3()
      self.GT1 = timer.getTime()
    else
      local CT1 = self.CT1
      local CT2 = timer.getTime()
      local CV1 = self.CV1
      local CV2 = ClientUnit:GetVec3()
      self.CT1 = CT2
      self.CV1 = CV2

      local CD = ( ( CV2.x - CV1.x )^2 + ( CV2.y - CV1.y )^2 + ( CV2.z - CV1.z )^2 ) ^ 0.5
      local CT = CT2 - CT1

      local CS = ( 3600 / CT ) * ( CD / 1000 )

      self:T2( { "Client:", CS, CD, CT, CV2, CV1, CT2, CT1 } )

      local GT1 = self.GT1
      local GT2 = timer.getTime()
      local GV1 = self.GV1
      local GV2 = GroupUnit:GetVec3()
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
      self.EscortGroup:RouteToVec3( GDV, Speed / 3.6 ) -- DCS models speed in Mps (Miles per second)
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

    if true then

      local EscortGroupName = self.EscortGroup:GetName() 
    
      self.EscortMenuAttackNearbyTargets:RemoveSubMenus()

      if self.EscortMenuTargetAssistance then
        self.EscortMenuTargetAssistance:RemoveSubMenus()
      end

      local DetectedItems = self.Detection:GetDetectedItems()
      self:F( DetectedItems )

      local DetectedTargets = false
  
      local DetectedMsgs = {}
      
      for ClientEscortGroupName, EscortGroupData in pairs( self.EscortClient._EscortGroups ) do

        local ClientEscortTargets = EscortGroupData.Detection
        --local EscortUnit = EscortGroupData:GetUnit( 1 )

        for DetectedItemIndex, DetectedItem in pairs( DetectedItems ) do
          self:F( { DetectedItemIndex, DetectedItem } )
          -- Remove the sub menus of the Attack menu of the Escort for the EscortGroup.
  
          local DetectedItemReportSummary = self.Detection:DetectedItemReportSummary( DetectedItem, EscortGroupData.EscortGroup, _DATABASE:GetPlayerSettings( self.EscortClient:GetPlayerName() ) )

          if ClientEscortGroupName == EscortGroupName then
          
            local DetectedMsg = DetectedItemReportSummary:Text("\n")
            DetectedMsgs[#DetectedMsgs+1] = DetectedMsg

            self:T( DetectedMsg )
  
            MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(),
              DetectedMsg,
              self.EscortMenuAttackNearbyTargets,
              ESCORT._AttackTarget,
              self,
              DetectedItem
            )
          else
            if self.EscortMenuTargetAssistance then
            
              local DetectedMsg = DetectedItemReportSummary:Text("\n")
              self:T( DetectedMsg )

              local MenuTargetAssistance = MENU_GROUP:New( self.EscortClient:GetGroup(), EscortGroupData.EscortName, self.EscortMenuTargetAssistance )
              MENU_GROUP_COMMAND:New( self.EscortClient:GetGroup(),
                DetectedMsg,
                MenuTargetAssistance,
                ESCORT._AssistTarget,
                self,
                EscortGroupData.EscortGroup,
                DetectedItem
              )
            end
          end
          
          DetectedTargets = true
                  
        end
      end
      self:F( DetectedMsgs )
      if DetectedTargets then
        self.EscortGroup:MessageToClient( "Reporting detected targets:\n" .. table.concat( DetectedMsgs, "\n" ), 20, self.EscortClient )
      else
        self.EscortGroup:MessageToClient( "No targets detected.", 10, self.EscortClient )
      end
      
      return true
    else
--      local EscortGroupName = self.EscortGroup:GetName()
--      local EscortTargets = self.EscortGroup:GetDetectedTargets()
--  
--      local ClientEscortTargets = self.EscortClient._EscortGroups[EscortGroupName].Targets
--  
--      local EscortTargetMessages = ""
--      for EscortTargetID, EscortTarget in pairs( EscortTargets ) do
--        local EscortObject = EscortTarget.object
--        self:T( EscortObject )
--        if EscortObject and EscortObject:isExist() and EscortObject.id_ < 50000000 then
--  
--          local EscortTargetUnit = UNIT:Find( EscortObject )
--          local EscortTargetUnitName = EscortTargetUnit:GetName()
--  
--  
--  
--          --          local EscortTargetIsDetected,
--          --                EscortTargetIsVisible,
--          --                EscortTargetLastTime,
--          --                EscortTargetKnowType,
--          --                EscortTargetKnowDistance,
--          --                EscortTargetLastPos,
--          --                EscortTargetLastVelocity
--          --                = self.EscortGroup:IsTargetDetected( EscortObject )
--          --
--          --          self:T( { EscortTargetIsDetected,
--          --                EscortTargetIsVisible,
--          --                EscortTargetLastTime,
--          --                EscortTargetKnowType,
--          --                EscortTargetKnowDistance,
--          --                EscortTargetLastPos,
--          --                EscortTargetLastVelocity } )
--  
--  
--          local EscortTargetUnitVec3 = EscortTargetUnit:GetVec3()
--          local EscortVec3 = self.EscortGroup:GetVec3()
--          local Distance = ( ( EscortTargetUnitVec3.x - EscortVec3.x )^2 +
--            ( EscortTargetUnitVec3.y - EscortVec3.y )^2 +
--            ( EscortTargetUnitVec3.z - EscortVec3.z )^2
--            ) ^ 0.5 / 1000
--  
--          self:T( { self.EscortGroup:GetName(), EscortTargetUnit:GetName(), Distance, EscortTarget } )
--  
--          if Distance <= 15 then
--  
--            if not ClientEscortTargets[EscortTargetUnitName] then
--              ClientEscortTargets[EscortTargetUnitName] = {}
--            end
--            ClientEscortTargets[EscortTargetUnitName].AttackUnit = EscortTargetUnit
--            ClientEscortTargets[EscortTargetUnitName].visible = EscortTarget.visible
--            ClientEscortTargets[EscortTargetUnitName].type = EscortTarget.type
--            ClientEscortTargets[EscortTargetUnitName].distance = EscortTarget.distance
--          else
--            if ClientEscortTargets[EscortTargetUnitName] then
--              ClientEscortTargets[EscortTargetUnitName] = nil
--            end
--          end
--        end
--      end
--  
--      self:T( { "Sorting Targets Table:", ClientEscortTargets } )
--      table.sort( ClientEscortTargets, function( a, b ) return a.Distance < b.Distance end )
--      self:T( { "Sorted Targets Table:", ClientEscortTargets } )
--  
--      -- Remove the sub menus of the Attack menu of the Escort for the EscortGroup.
--      self.EscortMenuAttackNearbyTargets:RemoveSubMenus()
--  
--      if self.EscortMenuTargetAssistance then
--        self.EscortMenuTargetAssistance:RemoveSubMenus()
--      end
--  
--      --for MenuIndex = 1, #self.EscortMenuAttackTargets do
--      --  self:T( { "Remove Menu:", self.EscortMenuAttackTargets[MenuIndex] } )
--      --  self.EscortMenuAttackTargets[MenuIndex] = self.EscortMenuAttackTargets[MenuIndex]:Remove()
--      --end
--  
--  
--      if ClientEscortTargets then
--        for ClientEscortTargetUnitName, ClientEscortTargetData in pairs( ClientEscortTargets ) do
--  
--          for ClientEscortGroupName, EscortGroupData in pairs( self.EscortClient._EscortGroups ) do
--  
--            if ClientEscortTargetData and ClientEscortTargetData.AttackUnit:IsAlive() then
--  
--              local EscortTargetMessage = ""
--              local EscortTargetCategoryName = ClientEscortTargetData.AttackUnit:GetCategoryName()
--              local EscortTargetCategoryType = ClientEscortTargetData.AttackUnit:GetTypeName()
--              if ClientEscortTargetData.type then
--                EscortTargetMessage = EscortTargetMessage .. EscortTargetCategoryName .. " (" .. EscortTargetCategoryType .. ") at "
--              else
--                EscortTargetMessage = EscortTargetMessage .. "Unknown target at "
--              end
--  
--              local EscortTargetUnitVec3 = ClientEscortTargetData.AttackUnit:GetVec3()
--              local EscortVec3 = self.EscortGroup:GetVec3()
--              local Distance = ( ( EscortTargetUnitVec3.x - EscortVec3.x )^2 +
--                ( EscortTargetUnitVec3.y - EscortVec3.y )^2 +
--                ( EscortTargetUnitVec3.z - EscortVec3.z )^2
--                ) ^ 0.5 / 1000
--  
--              self:T( { self.EscortGroup:GetName(), ClientEscortTargetData.AttackUnit:GetName(), Distance, ClientEscortTargetData.AttackUnit } )
--              if ClientEscortTargetData.visible == false then
--                EscortTargetMessage = EscortTargetMessage .. string.format( "%.2f", Distance ) .. " estimated km"
--              else
--                EscortTargetMessage = EscortTargetMessage .. string.format( "%.2f", Distance ) .. " km"
--              end
--  
--              if ClientEscortTargetData.visible then
--                EscortTargetMessage = EscortTargetMessage .. ", visual"
--              end
--  
--              if ClientEscortGroupName == EscortGroupName then
--  
--                MENU_GROUP_COMMAND:New( self.EscortClient,
--                  EscortTargetMessage,
--                  self.EscortMenuAttackNearbyTargets,
--                  ESCORT._AttackTarget,
--                  { ParamSelf = self,
--                    ParamUnit = ClientEscortTargetData.AttackUnit
--                  }
--                )
--                EscortTargetMessages = EscortTargetMessages .. "\n - " .. EscortTargetMessage
--              else
--                if self.EscortMenuTargetAssistance then
--                  local MenuTargetAssistance = MENU_GROUP:New( self.EscortClient, EscortGroupData.EscortName, self.EscortMenuTargetAssistance )
--                  MENU_GROUP_COMMAND:New( self.EscortClient,
--                    EscortTargetMessage,
--                    MenuTargetAssistance,
--                    ESCORT._AssistTarget,
--                    self,
--                    EscortGroupData.EscortGroup,
--                    ClientEscortTargetData.AttackUnit
--                  )
--                end
--              end
--            else
--              ClientEscortTargetData = nil
--            end
--          end
--        end
--  
--        if EscortTargetMessages ~= "" and self.ReportTargets == true then
--          self.EscortGroup:MessageToClient( "Detected targets within 15 km range:" .. EscortTargetMessages:gsub("\n$",""), 20, self.EscortClient )
--        else
--          self.EscortGroup:MessageToClient( "No targets detected!", 20, self.EscortClient )
--        end
--      end
--  
--      if self.EscortMenuResumeMission then
--        self.EscortMenuResumeMission:RemoveSubMenus()
--  
--        --    if self.EscortMenuResumeWayPoints then
--        --      for MenuIndex = 1, #self.EscortMenuResumeWayPoints do
--        --        self:T( { "Remove Menu:", self.EscortMenuResumeWayPoints[MenuIndex] } )
--        --        self.EscortMenuResumeWayPoints[MenuIndex] = self.EscortMenuResumeWayPoints[MenuIndex]:Remove()
--        --      end
--        --    end
--  
--        local TaskPoints = self:RegisterRoute()
--        for WayPointID, WayPoint in pairs( TaskPoints ) do
--          local EscortVec3 = self.EscortGroup:GetVec3()
--          local Distance = ( ( WayPoint.x - EscortVec3.x )^2 +
--            ( WayPoint.y - EscortVec3.z )^2
--            ) ^ 0.5 / 1000
--          MENU_GROUP_COMMAND:New( self.EscortClient, "Waypoint " .. WayPointID .. " at " .. string.format( "%.2f", Distance ).. "km", self.EscortMenuResumeMission, ESCORT._ResumeMission, { ParamSelf = self, ParamWayPoint = WayPointID } )
--        end
--      end
--  
--      return true
    end
  end
  
  return false
end
