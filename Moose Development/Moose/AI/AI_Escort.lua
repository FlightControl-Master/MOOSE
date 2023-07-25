--- **AI** - Taking the lead of AI escorting your flight or of other AI.
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
-- Each escorting group can be commanded with a complete set of radio commands (radio menu in your flight, and then F10).
--
-- The radio commands will vary according the category of the group. The richest set of commands are with helicopters and airPlanes.
-- Ships and Ground troops will have a more limited set, but they can provide support through the bombing of targets designated by the other escorts.
-- 
-- Escorts detect targets using a built-in detection mechanism. The detected targets are reported at a specified time interval.
-- Once targets are reported, each escort has these targets as menu options to command the attack of these targets.
-- Targets are by default grouped per area of 5000 meters, but the kind of detection and the grouping range can be altered.
-- 
-- Different formations can be selected in the Flight menu: Trail, Stack, Left Line, Right Line, Left Wing, Right Wing, Central Wing and Boxed formations are available.
-- The Flight menu also allows for a mass attack, where all of the escorts are commanded to attack a target.
-- 
-- Escorts can emit flares to reports their location. They can be commanded to hold at a location, which can be their current or the leader location.
-- In this way, you can spread out the escorts over the battle field before a coordinated attack.
-- 
-- But basically, the escort class provides 4 modes of operation, and depending on the mode, you are either leading the flight, or following the flight.
-- 
-- ## Leading the flight
-- 
-- When leading the flight, you are expected to guide the escorts towards the target areas, 
-- and carefully coordinate the attack based on the threat levels reported, and the available weapons
-- carried by the escorts. Ground ships or ground troops can execute A-assisted attacks, when they have long-range ground precision weapons for attack.
-- 
-- ## Following the flight
-- 
-- Escorts can be commanded to execute a specific mission path. In this mode, the escorts are in the lead.
-- You as a player, are following the escorts, and are commanding them to progress the mission while
-- ensuring that the escorts survive. You are joining the escorts in the battlefield. They will detect and report targets
-- and you will ensure that the attacks are well coordinated, assigning the correct escort type for the detected target
-- type. Once the attack is finished, the escort will resume the mission it was assigned.
-- In other words, you can use the escorts for reconnaissance, and for guiding the attack.
-- Imagine you as a mi-8 pilot, assigned to pickup cargo. Two ka-50s are guiding the way, and you are
-- following. You are in control. The ka-50s detect targets, report them, and you command how the attack
-- will commence and from where. You can control where the escorts are holding position and which targets
-- are attacked first. You are in control how the ka-50s will follow their mission path.
-- 
-- Escorts can act as part of a AI A2G dispatcher offensive. In this way, You was a player are in control.
-- The mission is defined by the A2G dispatcher, and you are responsible to join the flight and ensure that the
-- attack is well coordinated.
-- 
-- It is with great proud that I present you this class, and I hope you will enjoy the functionality and the dynamism
-- it brings in your DCS world simulations.
-- 
-- # RADIO MENUs that can be created:
-- 
-- Find a summary below of the current available commands:
--
-- ## Navigation ...:
-- 
-- Escort group navigation functions:
--
--   * **"Join-Up":** The escort group fill follow you in the assigned formation.
--   * **"Flare":** Provides menu commands to let the escort group shoot a flare in the air in a color.
--   * **"Smoke":** Provides menu commands to let the escort group smoke the air in a color. Note that smoking is only available for ground and naval troops.
--
-- ## Hold position ...:
-- 
-- Escort group navigation functions:
--
--   * **"At current location":** The escort group will hover above the ground at the position they were. The altitude can be specified as a parameter.
--   * **"At my location":** The escort group will hover or orbit at the position where you are. The escort will fly to your location and hold position. The altitude can be specified as a parameter.
--
-- ## Report targets ...:
-- 
-- Report targets will make the escort group to report any target that it identifies within detection range. Any detected target can be attacked using the "Attack Targets" menu function. (see below).
--
--   * **"Report now":** Will report the current detected targets.
--   * **"Report targets on":** Will make the escorts to report the detected targets and will fill the "Attack Targets" menu list.
--   * **"Report targets off":** Will stop detecting targets.
--
-- ## Attack targets ...:
-- 
-- This menu item will list all detected targets within a 15km range. Depending on the level of detection (known/unknown) and visuality, the targets type will also be listed.
-- This menu will be available in Flight menu or in each Escort menu.
--
-- ## Scan targets ...:
-- 
-- Menu items to pop-up the escort group for target scanning. After scanning, the escort group will resume with the mission or rejoin formation.
--
--   * **"Scan targets 30 seconds":** Scan 30 seconds for targets.
--   * **"Scan targets 60 seconds":** Scan 60 seconds for targets.
--
-- ## Request assistance from ...:
-- 
-- This menu item will list all detected targets within a 15km range, similar as with the menu item **Attack Targets**.
-- This menu item allows to request attack support from other ground based escorts supporting the current escort.
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
-- @module AI.AI_Escort
-- @image Escorting.JPG


---
-- @type AI_ESCORT
-- @extends AI.AI_Formation#AI_FORMATION


-- TODO: Add the menus when the class Start method is activated.
-- TODO: Remove the menus when the class Stop method is called.

--- AI_ESCORT class
-- 
-- # AI_ESCORT construction methods.
-- 
-- Create a new AI_ESCORT object with the @{#AI_ESCORT.New} method:
--
--  * @{#AI_ESCORT.New}: Creates a new AI_ESCORT object from a @{Wrapper.Group#GROUP} for a @{Wrapper.Client#CLIENT}, with an optional briefing text.
--
-- @usage
-- -- Declare a new EscortPlanes object as follows:
-- 
-- -- First find the GROUP object and the CLIENT object.
-- local EscortUnit = CLIENT:FindByName( "Unit Name" ) -- The Unit Name is the name of the unit flagged with the skill Client in the mission editor.
-- local EscortGroup = SET_GROUP:New():FilterPrefixes("Escort"):FilterOnce() -- The the group name of the escorts contains "Escort".
-- 
-- -- Now use these 2 objects to construct the new EscortPlanes object.
-- EscortPlanes = AI_ESCORT:New( EscortUnit, EscortGroup, "Desert", "Welcome to the mission. You are escorted by a plane with code name 'Desert', which can be instructed through the F10 radio menu." )
-- EscortPlanes:MenusAirplanes() -- create menus for airplanes
-- EscortPlanes:__Start(2)
-- 
-- 
-- @field #AI_ESCORT
AI_ESCORT = {
  ClassName = "AI_ESCORT",
  EscortName = nil, -- The Escort Name
  EscortUnit = nil,
  EscortGroup = nil,
  EscortMode = 1,
  Targets = {}, -- The identified targets
  FollowScheduler = nil,
  ReportTargets = true,
  OptionROE = AI.Option.Air.val.ROE.OPEN_FIRE,
  OptionReactionOnThreat = AI.Option.Air.val.REACTION_ON_THREAT.ALLOW_ABORT_MISSION,
  SmokeDirectionVector = false,
  TaskPoints = {}
}

-- @field Functional.Detection#DETECTION_AREAS
AI_ESCORT.Detection = nil

--- MENUPARAM type
-- @type MENUPARAM
-- @field #AI_ESCORT ParamSelf
-- @field #Distance ParamDistance
-- @field #function ParamFunction
-- @field #string ParamMessage

--- AI_ESCORT class constructor for an AI group
-- @param #AI_ESCORT self
-- @param Wrapper.Client#CLIENT EscortUnit The client escorted by the EscortGroup.
-- @param Core.Set#SET_GROUP EscortGroupSet The set of group AI escorting the EscortUnit.
-- @param #string EscortName Name of the escort.
-- @param #string EscortBriefing A text showing the AI_ESCORT briefing to the player. Note that if no EscortBriefing is provided, the default briefing will be shown.
-- @return #AI_ESCORT self
-- @usage
-- -- Declare a new EscortPlanes object as follows:
-- 
-- -- First find the GROUP object and the CLIENT object.
-- local EscortUnit = CLIENT:FindByName( "Unit Name" ) -- The Unit Name is the name of the unit flagged with the skill Client in the mission editor.
-- local EscortGroup = SET_GROUP:New():FilterPrefixes("Escort"):FilterOnce() -- The the group name of the escorts contains "Escort".
-- 
-- -- Now use these 2 objects to construct the new EscortPlanes object.
-- EscortPlanes = AI_ESCORT:New( EscortUnit, EscortGroup, "Desert", "Welcome to the mission. You are escorted by a plane with code name 'Desert', which can be instructed through the F10 radio menu." )
-- EscortPlanes:MenusAirplanes() -- create menus for airplanes
-- EscortPlanes:__Start(2)
-- 
-- 
function AI_ESCORT:New( EscortUnit, EscortGroupSet, EscortName, EscortBriefing )
  
  local self = BASE:Inherit( self, AI_FORMATION:New( EscortUnit, EscortGroupSet, EscortName, EscortBriefing ) ) -- #AI_ESCORT
  self:F( { EscortUnit, EscortGroupSet } )

  self.PlayerUnit = self.FollowUnit -- Wrapper.Unit#UNIT
  self.PlayerGroup = self.FollowUnit:GetGroup() -- Wrapper.Group#GROUP
  
  self.EscortName = EscortName
  self.EscortGroupSet = EscortGroupSet
  
  self.EscortGroupSet:SetSomeIteratorLimit( 8 )

  self.EscortBriefing = EscortBriefing
 
  self.Menu = {}
  self.Menu.HoldAtEscortPosition = self.Menu.HoldAtEscortPosition or {}
  self.Menu.HoldAtLeaderPosition = self.Menu.HoldAtLeaderPosition or {}
  self.Menu.Flare = self.Menu.Flare or {}
  self.Menu.Smoke = self.Menu.Smoke or {}
  self.Menu.Targets = self.Menu.Targets or {}
  self.Menu.ROE = self.Menu.ROE or {}
  self.Menu.ROT = self.Menu.ROT or {}
  
--  if not EscortBriefing then
--    EscortGroup:MessageToClient( EscortGroup:GetCategoryName() .. " '" .. EscortName .. "' (" .. EscortGroup:GetCallsign() .. ") reporting! " ..
--      "We're escorting your flight. " ..
--      "Use the Radio Menu and F10 and use the options under + " .. EscortName .. "\n",
--      60, EscortUnit
--    )
--  else
--    EscortGroup:MessageToClient( EscortGroup:GetCategoryName() .. " '" .. EscortName .. "' (" .. EscortGroup:GetCallsign() .. ") " .. EscortBriefing,
--      60, EscortUnit
--    )
--  end

  self.FollowDistance = 100
  self.CT1 = 0
  self.GT1 = 0


  EscortGroupSet:ForEachGroup(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      -- Set EscortGroup known at EscortUnit.
      if not self.PlayerUnit._EscortGroups then
        self.PlayerUnit._EscortGroups = {}
      end
    
      if not self.PlayerUnit._EscortGroups[EscortGroup:GetName()] then
        self.PlayerUnit._EscortGroups[EscortGroup:GetName()] = {}
        self.PlayerUnit._EscortGroups[EscortGroup:GetName()].EscortGroup = EscortGroup
        self.PlayerUnit._EscortGroups[EscortGroup:GetName()].EscortName = self.EscortName
        self.PlayerUnit._EscortGroups[EscortGroup:GetName()].Detection = self.Detection
      end  
    end
  )
  
  self:SetFlightReportType( self.__Enum.ReportType.All )
  
  return self
end


function AI_ESCORT:_InitFlightMenus()

  self:SetFlightMenuJoinUp()
  self:SetFlightMenuFormation( "Trail" )
  self:SetFlightMenuFormation( "Stack" )
  self:SetFlightMenuFormation( "LeftLine" )
  self:SetFlightMenuFormation( "RightLine" )
  self:SetFlightMenuFormation( "LeftWing" )
  self:SetFlightMenuFormation( "RightWing" )
  self:SetFlightMenuFormation( "Vic" )
  self:SetFlightMenuFormation( "Box" )

  self:SetFlightMenuHoldAtEscortPosition()
  self:SetFlightMenuHoldAtLeaderPosition()
  
  self:SetFlightMenuFlare()
  self:SetFlightMenuSmoke()

  self:SetFlightMenuROE()
  self:SetFlightMenuROT()

  self:SetFlightMenuTargets()
  self:SetFlightMenuReportType()

end

function AI_ESCORT:_InitEscortMenus( EscortGroup )

  EscortGroup.EscortMenu = MENU_GROUP:New( self.PlayerGroup, EscortGroup:GetCallsign(), self.MainMenu )
  
  self:SetEscortMenuJoinUp( EscortGroup )
  self:SetEscortMenuResumeMission( EscortGroup )
  
  self:SetEscortMenuHoldAtEscortPosition( EscortGroup )
  self:SetEscortMenuHoldAtLeaderPosition( EscortGroup )
  
  self:SetEscortMenuFlare( EscortGroup )
  self:SetEscortMenuSmoke( EscortGroup )

  self:SetEscortMenuROE( EscortGroup )
  self:SetEscortMenuROT( EscortGroup )
  
  self:SetEscortMenuTargets( EscortGroup )

end

function AI_ESCORT:_InitEscortRoute( EscortGroup )

  EscortGroup.MissionRoute = EscortGroup:GetTaskRoute()

end


-- @param #AI_ESCORT self
-- @param Core.Set#SET_GROUP EscortGroupSet
function AI_ESCORT:onafterStart( EscortGroupSet )

  self:F()

  EscortGroupSet:ForEachGroup(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      EscortGroup:WayPointInitialize()
    
      EscortGroup:OptionROTVertical()
      EscortGroup:OptionROEOpenFire()
    end
  )

  -- TODO:Revise this...  
  local LeaderEscort = EscortGroupSet:GetFirst() -- Wrapper.Group#GROUP
  if LeaderEscort then
    local Report = REPORT:New( "Escort reporting:" )
    Report:Add( "Joining Up " .. EscortGroupSet:GetUnitTypeNames():Text( ", " ) .. " from " .. LeaderEscort:GetCoordinate():ToString( self.PlayerUnit ) )
    LeaderEscort:MessageTypeToGroup( Report:Text(),  MESSAGE.Type.Information, self.PlayerUnit )
  end

  self.Detection = DETECTION_AREAS:New( EscortGroupSet, 5000 )

  -- This only makes the escort report detections made by the escort, not through DLINK.
  -- These must be enquired using other facilities.
  -- In this way, the escort will report the target areas that are relevant for the mission.
  self.Detection:InitDetectVisual( true )
  self.Detection:InitDetectIRST( true )
  self.Detection:InitDetectOptical( true )
  self.Detection:InitDetectRadar( true )
  self.Detection:InitDetectRWR( true )
  
  self.Detection:SetAcceptRange( 100000 )

  self.Detection:__Start( 30 )
    
  self.MainMenu = MENU_GROUP:New( self.PlayerGroup, self.EscortName )
  self.FlightMenu = MENU_GROUP:New( self.PlayerGroup, "Flight", self.MainMenu )

  self:_InitFlightMenus()
  
  self.EscortGroupSet:ForSomeGroupAlive(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )

      self:_InitEscortMenus( EscortGroup )
      self:_InitEscortRoute( EscortGroup )

      self:SetFlightModeFormation( EscortGroup )
      
      -- @param #AI_ESCORT self
      -- @param Core.Event#EVENTDATA EventData
      function EscortGroup:OnEventDeadOrCrash( EventData )
        self:F( { "EventDead", EventData } )
        self.EscortMenu:Remove()
      end

      EscortGroup:HandleEvent( EVENTS.Dead, EscortGroup.OnEventDeadOrCrash )
      EscortGroup:HandleEvent( EVENTS.Crash, EscortGroup.OnEventDeadOrCrash )
      
    end
  )
  

end

-- @param #AI_ESCORT self
-- @param Core.Set#SET_GROUP EscortGroupSet
function AI_ESCORT:onafterStop( EscortGroupSet )

  self:F()

  EscortGroupSet:ForEachGroup(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      EscortGroup:WayPointInitialize()
    
      EscortGroup:OptionROTVertical()
      EscortGroup:OptionROEOpenFire()
    end
  )

  self.Detection:Stop()
    
  self.MainMenu:Remove()

end

--- Set a Detection method for the EscortUnit to be reported upon.
-- Detection methods are based on the derived classes from DETECTION_BASE.
-- @param #AI_ESCORT self
-- @param Functional.Detection#DETECTION_AREAS Detection
function AI_ESCORT:SetDetection( Detection )

  self.Detection = Detection
  self.EscortGroup.Detection = self.Detection
  self.PlayerUnit._EscortGroups[self.EscortGroup:GetName()].Detection = self.EscortGroup.Detection
  
  Detection:__Start( 1 )
  
end

--- This function is for test, it will put on the frequency of the FollowScheduler a red smoke at the direction vector calculated for the escort to fly to.
-- This allows to visualize where the escort is flying to.
-- @param #AI_ESCORT self
-- @param #boolean SmokeDirection If true, then the direction vector will be smoked.
function AI_ESCORT:TestSmokeDirectionVector( SmokeDirection )
  self.SmokeDirectionVector = ( SmokeDirection == true ) and true or false
end


--- Defines the default menus for helicopters.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @param #number ZLevels The amount of levels on the Z-axis.
-- @return #AI_ESCORT
function AI_ESCORT:MenusHelicopters( XStart, XSpace, YStart, YSpace, ZStart, ZSpace, ZLevels )
  self:F()

--  self:MenuScanForTargets( 100, 60 )

  self.XStart = XStart or 50
  self.XSpace = XSpace or 50
  self.YStart = YStart or 50
  self.YSpace = YSpace or 50
  self.ZStart = ZStart or 50
  self.ZSpace = ZSpace or 50
  self.ZLevels = ZLevels or 10

  self:MenuJoinUp()
  self:MenuFormationTrail(self.XStart,self.XSpace,self.YStart)
  self:MenuFormationStack(self.XStart,self.XSpace,self.YStart,self.YSpace)
  self:MenuFormationLeftLine(self.XStart,self.YStart,self.ZStart,self.ZSpace)
  self:MenuFormationRightLine(self.XStart,self.YStart,self.ZStart,self.ZSpace)
  self:MenuFormationLeftWing(self.XStart,self.XSpace,self.YStart,self.ZStart,self.ZSpace)
  self:MenuFormationRightWing(self.XStart,self.XSpace,self.YStart,self.ZStart,self.ZSpace)
  self:MenuFormationVic(self.XStart,self.XSpace,self.YStart,self.YSpace,self.ZStart,self.ZSpace)
  self:MenuFormationBox(self.XStart,self.XSpace,self.YStart,self.YSpace,self.ZStart,self.ZSpace,self.ZLevels)
  
  self:MenuHoldAtEscortPosition( 30 )
  self:MenuHoldAtEscortPosition( 100 )
  self:MenuHoldAtEscortPosition( 500 )
  self:MenuHoldAtLeaderPosition( 30, 500 )
  
  self:MenuFlare()
  self:MenuSmoke()

  self:MenuTargets( 60 )
  self:MenuAssistedAttack()
  self:MenuROE()
  self:MenuROT()

  return self
end


--- Defines the default menus for airplanes.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @param #number ZLevels The amount of levels on the Z-axis.
-- @return #AI_ESCORT
function AI_ESCORT:MenusAirplanes( XStart, XSpace, YStart, YSpace, ZStart, ZSpace, ZLevels )
  self:F()

--  self:MenuScanForTargets( 100, 60 )

  self.XStart = XStart or 50
  self.XSpace = XSpace or 50
  self.YStart = YStart or 50
  self.YSpace = YSpace or 50
  self.ZStart = ZStart or 50
  self.ZSpace = ZSpace or 50
  self.ZLevels = ZLevels or 10

  self:MenuJoinUp()
  self:MenuFormationTrail(self.XStart,self.XSpace,self.YStart)
  self:MenuFormationStack(self.XStart,self.XSpace,self.YStart,self.YSpace)
  self:MenuFormationLeftLine(self.XStart,self.YStart,self.ZStart,self.ZSpace)
  self:MenuFormationRightLine(self.XStart,self.YStart,self.ZStart,self.ZSpace)
  self:MenuFormationLeftWing(self.XStart,self.XSpace,self.YStart,self.ZStart,self.ZSpace)
  self:MenuFormationRightWing(self.XStart,self.XSpace,self.YStart,self.ZStart,self.ZSpace)
  self:MenuFormationVic(self.XStart,self.XSpace,self.YStart,self.YSpace,self.ZStart,self.ZSpace)
  self:MenuFormationBox(self.XStart,self.XSpace,self.YStart,self.YSpace,self.ZStart,self.ZSpace,self.ZLevels)
  
  self:MenuHoldAtEscortPosition( 1000, 500 )
  self:MenuHoldAtLeaderPosition( 1000, 500 )
  
  self:MenuFlare()
  self:MenuSmoke()

  self:MenuTargets( 60 )
  self:MenuAssistedAttack()
  self:MenuROE()
  self:MenuROT()

  return self
end


function AI_ESCORT:SetFlightMenuFormation( Formation )

  local FormationID = "Formation" .. Formation
  
  local MenuFormation = self.Menu[FormationID]

  if MenuFormation then
    local Arguments = MenuFormation.Arguments
    --self:I({Arguments=unpack(Arguments)})
    local FlightMenuFormation = MENU_GROUP:New( self.PlayerGroup, "Formation", self.MainMenu )
    local MenuFlightFormationID = MENU_GROUP_COMMAND:New( self.PlayerGroup, Formation, FlightMenuFormation, 
      function ( self, Formation, ... )
        self.EscortGroupSet:ForSomeGroupAlive(
          -- @param Core.Group#GROUP EscortGroup
          function( EscortGroup, self, Formation, Arguments )
            if EscortGroup:IsAir() then
              self:E({FormationID=FormationID})
              self[FormationID]( self, unpack(Arguments) )
            end
          end, self, Formation, Arguments
        )
      end, self, Formation, Arguments
    )
  end
    
  return self
end


function AI_ESCORT:MenuFormation( Formation, ... )

  local FormationID = "Formation"..Formation
  self.Menu[FormationID] = self.Menu[FormationID] or {}
  self.Menu[FormationID].Arguments = arg

end


--- Defines a menu slot to let the escort to join in a trail formation.
-- This menu will appear under **Formation**.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @return #AI_ESCORT
function AI_ESCORT:MenuFormationTrail( XStart, XSpace, YStart )

  self:MenuFormation( "Trail", XStart, XSpace, YStart )

  return self
end

--- Defines a menu slot to let the escort to join in a stacked formation.
-- This menu will appear under **Formation**.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
-- @return #AI_ESCORT
function AI_ESCORT:MenuFormationStack( XStart, XSpace, YStart, YSpace )

  self:MenuFormation( "Stack", XStart, XSpace, YStart, YSpace )

  return self
end


--- Defines a menu slot to let the escort to join in a leFt wing formation.
-- This menu will appear under **Formation**.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @return #AI_ESCORT
function AI_ESCORT:MenuFormationLeftLine( XStart, YStart, ZStart, ZSpace )

  self:MenuFormation( "LeftLine", XStart, YStart, ZStart, ZSpace )

  return self
end


--- Defines a menu slot to let the escort to join in a right line formation.
-- This menu will appear under **Formation**.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @return #AI_ESCORT
function AI_ESCORT:MenuFormationRightLine( XStart, YStart, ZStart, ZSpace )

  self:MenuFormation( "RightLine", XStart, YStart, ZStart, ZSpace )

  return self
end


--- Defines a menu slot to let the escort to join in a left wing formation.
-- This menu will appear under **Formation**.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @return #AI_ESCORT
function AI_ESCORT:MenuFormationLeftWing( XStart, XSpace, YStart, ZStart, ZSpace )

  self:MenuFormation( "LeftWing", XStart, XSpace, YStart, ZStart, ZSpace )

  return self
end


--- Defines a menu slot to let the escort to join in a right wing formation.
-- This menu will appear under **Formation**.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @return #AI_ESCORT
function AI_ESCORT:MenuFormationRightWing( XStart, XSpace, YStart, ZStart, ZSpace )

  self:MenuFormation( "RightWing", XStart, XSpace, YStart, ZStart, ZSpace )

  return self
end


--- Defines a menu slot to let the escort to join in a center wing formation.
-- This menu will appear under **Formation**.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @return #AI_ESCORT
function AI_ESCORT:MenuFormationCenterWing( XStart, XSpace, YStart, YSpace, ZStart, ZSpace )

  self:MenuFormation( "CenterWing", XStart, XSpace, YStart, YSpace, ZStart, ZSpace )

  return self
end


--- Defines a menu slot to let the escort to join in a vic formation.
-- This menu will appear under **Formation**.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @return #AI_ESCORT
function AI_ESCORT:MenuFormationVic( XStart, XSpace, YStart, YSpace, ZStart, ZSpace )

  self:MenuFormation( "Vic", XStart, XSpace, YStart, YSpace, ZStart, ZSpace )

  return self
end


--- Defines a menu slot to let the escort to join in a box formation.
-- This menu will appear under **Formation**.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @param #number ZLevels The amount of levels on the Z-axis.
-- @return #AI_ESCORT
function AI_ESCORT:MenuFormationBox( XStart, XSpace, YStart, YSpace, ZStart, ZSpace, ZLevels )

  self:MenuFormation( "Box", XStart, XSpace, YStart, YSpace, ZStart, ZSpace, ZLevels )

  return self
end

function AI_ESCORT:SetFlightMenuJoinUp()

  if self.Menu.JoinUp == true then
    local FlightMenuReportNavigation = MENU_GROUP:New( self.PlayerGroup, "Navigation", self.FlightMenu )
    local FlightMenuJoinUp  = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Join Up",  FlightMenuReportNavigation, AI_ESCORT._FlightJoinUp, self )
  end
  
end


--- Sets a menu slot to join formation for an escort.
-- @param #AI_ESCORT self
-- @return #AI_ESCORT
function AI_ESCORT:SetEscortMenuJoinUp( EscortGroup )

  if self.Menu.JoinUp == true then
    if EscortGroup:IsAir() then
      local EscortGroupName = EscortGroup:GetName()
      local EscortMenuReportNavigation = MENU_GROUP:New( self.PlayerGroup, "Navigation", EscortGroup.EscortMenu )
      local EscortMenuJoinUp = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Join Up", EscortMenuReportNavigation, AI_ESCORT._JoinUp, self, EscortGroup )
    end
  end
end



--- Defines --- Defines a menu slot to let the escort to join formation.
-- @param #AI_ESCORT self
-- @return #AI_ESCORT
function AI_ESCORT:MenuJoinUp()

  self.Menu.JoinUp = true

  return self
end


function AI_ESCORT:SetFlightMenuHoldAtEscortPosition()

  for _, MenuHoldAtEscortPosition in pairs( self.Menu.HoldAtEscortPosition or {} ) do
    local FlightMenuReportNavigation = MENU_GROUP:New( self.PlayerGroup, "Navigation", self.FlightMenu )
  
    local FlightMenuHoldPosition = MENU_GROUP_COMMAND
      :New(
        self.PlayerGroup,
        MenuHoldAtEscortPosition.MenuText,
        FlightMenuReportNavigation,
        AI_ESCORT._FlightHoldPosition,
        self,
        nil,
        MenuHoldAtEscortPosition.Height,
        MenuHoldAtEscortPosition.Speed
      )
  
    end
  return self
end

function AI_ESCORT:SetEscortMenuHoldAtEscortPosition( EscortGroup )

  for _, HoldAtEscortPosition in pairs( self.Menu.HoldAtEscortPosition or {}) do
    if EscortGroup:IsAir() then
      local EscortGroupName = EscortGroup:GetName()
      local EscortMenuReportNavigation = MENU_GROUP:New( self.PlayerGroup, "Navigation", EscortGroup.EscortMenu )
      local EscortMenuHoldPosition = MENU_GROUP_COMMAND
        :New(
          self.PlayerGroup,
          HoldAtEscortPosition.MenuText,
          EscortMenuReportNavigation,
          AI_ESCORT._HoldPosition,
          self,
          EscortGroup,
          EscortGroup,
          HoldAtEscortPosition.Height,
          HoldAtEscortPosition.Speed
        )
    end
  end
  
  return self
end


--- Defines a menu slot to let the escort hold at their current position and stay low with a specified height during a specified time in seconds.
-- This menu will appear under **Hold position**.
-- @param #AI_ESCORT self
-- @param DCS#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCS#Time Speed Optional parameter that lets the escort orbit with a specified speed. The default value is a speed that is average for the type of airplane or helicopter.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #AI_ESCORT
function AI_ESCORT:MenuHoldAtEscortPosition( Height, Speed, MenuTextFormat )
  self:F( { Height, Speed, MenuTextFormat } )

  if not Height then
    Height = 30
  end

  if not Speed then
    Speed = 0
  end

  local MenuText = ""
  if not MenuTextFormat then
    if Speed == 0 then
      MenuText = string.format( "Hold at %d meter", Height )
    else
      MenuText = string.format( "Hold at %d meter at %d", Height, Speed )
    end
  else
    if Speed == 0 then
      MenuText = string.format( MenuTextFormat, Height )
    else
      MenuText = string.format( MenuTextFormat, Height, Speed )
    end
  end

  self.Menu.HoldAtEscortPosition = self.Menu.HoldAtEscortPosition or {}
  self.Menu.HoldAtEscortPosition[#self.Menu.HoldAtEscortPosition+1] = {}
  self.Menu.HoldAtEscortPosition[#self.Menu.HoldAtEscortPosition].Height = Height
  self.Menu.HoldAtEscortPosition[#self.Menu.HoldAtEscortPosition].Speed = Speed
  self.Menu.HoldAtEscortPosition[#self.Menu.HoldAtEscortPosition].MenuText = MenuText

  return self
end


function AI_ESCORT:SetFlightMenuHoldAtLeaderPosition()

  for _, MenuHoldAtLeaderPosition in pairs( self.Menu.HoldAtLeaderPosition or {}) do
    local FlightMenuReportNavigation = MENU_GROUP:New( self.PlayerGroup, "Navigation", self.FlightMenu )
  
    local FlightMenuHoldAtLeaderPosition = MENU_GROUP_COMMAND
      :New(
        self.PlayerGroup,
        MenuHoldAtLeaderPosition.MenuText,
        FlightMenuReportNavigation,
        AI_ESCORT._FlightHoldPosition,
        self,
        self.PlayerGroup,
        MenuHoldAtLeaderPosition.Height,
        MenuHoldAtLeaderPosition.Speed
      )
  end

  return self
end

function AI_ESCORT:SetEscortMenuHoldAtLeaderPosition( EscortGroup )

  for _, HoldAtLeaderPosition in pairs( self.Menu.HoldAtLeaderPosition or {}) do
    if EscortGroup:IsAir() then
      
      local EscortGroupName = EscortGroup:GetName()
      local EscortMenuReportNavigation = MENU_GROUP:New( self.PlayerGroup, "Navigation", EscortGroup.EscortMenu )
  
      local EscortMenuHoldAtLeaderPosition = MENU_GROUP_COMMAND
        :New(
          self.PlayerGroup,
          HoldAtLeaderPosition.MenuText,
          EscortMenuReportNavigation,
          AI_ESCORT._HoldPosition,
          self,
          self.PlayerGroup,
          EscortGroup,
          HoldAtLeaderPosition.Height,
          HoldAtLeaderPosition.Speed
        )
    end
  end

  return self
end

--- Defines a menu slot to let the escort hold at the client position and stay low with a specified height during a specified time in seconds.
-- This menu will appear under **Navigation**.
-- @param #AI_ESCORT self
-- @param DCS#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCS#Time Speed Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain one or two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #AI_ESCORT
function AI_ESCORT:MenuHoldAtLeaderPosition( Height, Speed, MenuTextFormat )
  self:F( { Height, Speed, MenuTextFormat } )

  if not Height then
    Height = 30
  end

  if not Speed then
    Speed = 0
  end

  local MenuText = ""
  if not MenuTextFormat then
    if Speed == 0 then
      MenuText = string.format( "Rejoin and hold at %d meter", Height )
    else
      MenuText = string.format( "Rejoin and hold at %d meter at %d", Height, Speed )
    end
  else
    if Speed == 0 then
      MenuText = string.format( MenuTextFormat, Height )
    else
      MenuText = string.format( MenuTextFormat, Height, Speed )
    end
  end

  self.Menu.HoldAtLeaderPosition = self.Menu.HoldAtLeaderPosition or {}
  self.Menu.HoldAtLeaderPosition[#self.Menu.HoldAtLeaderPosition+1] = {}
  self.Menu.HoldAtLeaderPosition[#self.Menu.HoldAtLeaderPosition].Height = Height
  self.Menu.HoldAtLeaderPosition[#self.Menu.HoldAtLeaderPosition].Speed = Speed
  self.Menu.HoldAtLeaderPosition[#self.Menu.HoldAtLeaderPosition].MenuText = MenuText

  return self
end

--- Defines a menu slot to let the escort scan for targets at a certain height for a certain time in seconds.
-- This menu will appear under **Scan targets**.
-- @param #AI_ESCORT self
-- @param DCS#Distance Height Optional parameter that sets the height in meters to let the escort orbit at the current location. The default value is 30 meters.
-- @param DCS#Time Seconds Optional parameter that lets the escort orbit at the current position for a specified time. (not implemented yet). The default value is 0 seconds, meaning, that the escort will orbit forever until a sequent command is given.
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. The text string is formatted, and should contain one or two %d tokens in the string. The first for the Height, the second for the Time (if given). If no text is given, the default text will be displayed.
-- @return #AI_ESCORT
function AI_ESCORT:MenuScanForTargets( Height, Seconds, MenuTextFormat )
  self:F( { Height, Seconds, MenuTextFormat } )

  if self.EscortGroup:IsAir() then
    if not self.EscortMenuScan then
      self.EscortMenuScan = MENU_GROUP:New( self.PlayerGroup, "Scan for targets", self.EscortMenu )
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
        self.PlayerGroup,
        MenuText,
        self.EscortMenuScan,
        AI_ESCORT._ScanTargets,
        self,
        30
      )
  end

  return self
end


function AI_ESCORT:SetFlightMenuFlare()

  for _, MenuFlare in pairs( self.Menu.Flare or {}) do
    local FlightMenuReportNavigation = MENU_GROUP:New( self.PlayerGroup, "Navigation", self.FlightMenu )
    local FlightMenuFlare = MENU_GROUP:New( self.PlayerGroup, MenuFlare.MenuText, FlightMenuReportNavigation )
  
    local FlightMenuFlareGreenFlight  = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release green flare",  FlightMenuFlare, AI_ESCORT._FlightFlare, self, FLARECOLOR.Green,  "Released a green flare!"   )
    local FlightMenuFlareRedFlight    = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release red flare",    FlightMenuFlare, AI_ESCORT._FlightFlare, self, FLARECOLOR.Red,    "Released a red flare!"     )
    local FlightMenuFlareWhiteFlight  = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release white flare",  FlightMenuFlare, AI_ESCORT._FlightFlare, self, FLARECOLOR.White,  "Released a white flare!"   )
    local FlightMenuFlareYellowFlight = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release yellow flare", FlightMenuFlare, AI_ESCORT._FlightFlare, self, FLARECOLOR.Yellow, "Released a yellow flare!"  )
  end

  return self
end

function AI_ESCORT:SetEscortMenuFlare( EscortGroup )

  for _, MenuFlare in pairs( self.Menu.Flare or {}) do
    if EscortGroup:IsAir() then
      
      local EscortGroupName = EscortGroup:GetName()
      local EscortMenuReportNavigation = MENU_GROUP:New( self.PlayerGroup, "Navigation", EscortGroup.EscortMenu )
      local EscortMenuFlare = MENU_GROUP:New( self.PlayerGroup, MenuFlare.MenuText, EscortMenuReportNavigation )

      local EscortMenuFlareGreen  = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release green flare",  EscortMenuFlare, AI_ESCORT._Flare, self, EscortGroup, FLARECOLOR.Green,  "Released a green flare!"   )
      local EscortMenuFlareRed    = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release red flare",    EscortMenuFlare, AI_ESCORT._Flare, self, EscortGroup, FLARECOLOR.Red,    "Released a red flare!"     )
      local EscortMenuFlareWhite  = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release white flare",  EscortMenuFlare, AI_ESCORT._Flare, self, EscortGroup, FLARECOLOR.White,  "Released a white flare!"   )
      local EscortMenuFlareYellow = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release yellow flare", EscortMenuFlare, AI_ESCORT._Flare, self, EscortGroup, FLARECOLOR.Yellow, "Released a yellow flare!"  )
    end
  end

  return self
end



--- Defines a menu slot to let the escort disperse a flare in a certain color.
-- This menu will appear under **Navigation**.
-- The flare will be fired from the first unit in the group.
-- @param #AI_ESCORT self
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. If no text is given, the default text will be displayed.
-- @return #AI_ESCORT
function AI_ESCORT:MenuFlare( MenuTextFormat )
  self:F()

  local MenuText = ""
  if not MenuTextFormat then
    MenuText = "Flare"
  else
    MenuText = MenuTextFormat
  end

  self.Menu.Flare = self.Menu.Flare or {}
  self.Menu.Flare[#self.Menu.Flare+1] = {}
  self.Menu.Flare[#self.Menu.Flare].MenuText = MenuText

  return self
end


function AI_ESCORT:SetFlightMenuSmoke()

  for _, MenuSmoke in pairs( self.Menu.Smoke or {}) do
    local FlightMenuReportNavigation = MENU_GROUP:New( self.PlayerGroup, "Navigation", self.FlightMenu )
    local FlightMenuSmoke = MENU_GROUP:New( self.PlayerGroup, MenuSmoke.MenuText, FlightMenuReportNavigation )
  
    local FlightMenuSmokeGreenFlight  = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release green smoke",  FlightMenuSmoke, AI_ESCORT._FlightSmoke, self, SMOKECOLOR.Green,  "Releasing green smoke!"   )
    local FlightMenuSmokeRedFlight    = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release red smoke",    FlightMenuSmoke, AI_ESCORT._FlightSmoke, self, SMOKECOLOR.Red,    "Releasing red smoke!"     )
    local FlightMenuSmokeWhiteFlight  = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release white smoke",  FlightMenuSmoke, AI_ESCORT._FlightSmoke, self, SMOKECOLOR.White,  "Releasing white smoke!"   )
    local FlightMenuSmokeOrangeFlight = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release orange smoke", FlightMenuSmoke, AI_ESCORT._FlightSmoke, self, SMOKECOLOR.Orange, "Releasing orange smoke!"  )
    local FlightMenuSmokeBlueFlight   = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release blue smoke",   FlightMenuSmoke, AI_ESCORT._FlightSmoke, self, SMOKECOLOR.Blue,   "Releasing blue smoke!"    )
  end

  return self
end


function AI_ESCORT:SetEscortMenuSmoke( EscortGroup )

  for _, MenuSmoke in pairs( self.Menu.Smoke or {}) do
    if EscortGroup:IsAir() then
      
      local EscortGroupName = EscortGroup:GetName()
      local EscortMenuReportNavigation = MENU_GROUP:New( self.PlayerGroup, "Navigation", EscortGroup.EscortMenu )
      local EscortMenuSmoke = MENU_GROUP:New( self.PlayerGroup, MenuSmoke.MenuText, EscortMenuReportNavigation )

      local EscortMenuSmokeGreen  = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release green smoke",  EscortMenuSmoke, AI_ESCORT._Smoke, self, EscortGroup, SMOKECOLOR.Green,  "Releasing green smoke!"   )
      local EscortMenuSmokeRed    = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release red smoke",    EscortMenuSmoke, AI_ESCORT._Smoke, self, EscortGroup, SMOKECOLOR.Red,    "Releasing red smoke!"     )
      local EscortMenuSmokeWhite  = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release white smoke",  EscortMenuSmoke, AI_ESCORT._Smoke, self, EscortGroup, SMOKECOLOR.White,  "Releasing white smoke!"   )
      local EscortMenuSmokeOrange = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release orange smoke", EscortMenuSmoke, AI_ESCORT._Smoke, self, EscortGroup, SMOKECOLOR.Orange, "Releasing orange smoke!"  )
      local EscortMenuSmokeBlue   = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Release blue smoke",   EscortMenuSmoke, AI_ESCORT._Smoke, self, EscortGroup, SMOKECOLOR.Blue,   "Releasing blue smoke!"    )
    end
  end

  return self
end


--- Defines a menu slot to let the escort disperse a smoke in a certain color.
-- This menu will appear under **Navigation**.
-- Note that smoke menu options will only be displayed for ships and ground units. Not for air units.
-- The smoke will be fired from the first unit in the group.
-- @param #AI_ESCORT self
-- @param #string MenuTextFormat Optional parameter that shows the menu option text. If no text is given, the default text will be displayed.
-- @return #AI_ESCORT
function AI_ESCORT:MenuSmoke( MenuTextFormat )
  self:F()

  local MenuText = ""
  if not MenuTextFormat then
    MenuText = "Smoke"
  else
    MenuText = MenuTextFormat
  end

  self.Menu.Smoke = self.Menu.Smoke or {}
  self.Menu.Smoke[#self.Menu.Smoke+1] = {}
  self.Menu.Smoke[#self.Menu.Smoke].MenuText = MenuText

  return self
end

function AI_ESCORT:SetFlightMenuReportType()

  local FlightMenuReportTargets = MENU_GROUP:New( self.PlayerGroup, "Report targets", self.FlightMenu )
  local MenuStamp = FlightMenuReportTargets:GetStamp()

  local FlightReportType = self:GetFlightReportType()
  
  if FlightReportType ~= self.__Enum.ReportType.All then
    local FlightMenuReportTargetsAll = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Report all targets",  FlightMenuReportTargets, AI_ESCORT._FlightSwitchReportTypeAll, self )
                                                         :SetTag( "ReportType" )
                                                         :SetStamp( MenuStamp )
  end
  
  if FlightReportType == self.__Enum.ReportType.All or FlightReportType ~= self.__Enum.ReportType.Airborne then
    local FlightMenuReportTargetsAirborne = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Report airborne targets",  FlightMenuReportTargets, AI_ESCORT._FlightSwitchReportTypeAirborne, self )
                                                              :SetTag( "ReportType" )
                                                              :SetStamp( MenuStamp )
  end
  
  if FlightReportType == self.__Enum.ReportType.All or FlightReportType ~= self.__Enum.ReportType.GroundRadar then
    local FlightMenuReportTargetsGroundRadar = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Report gound radar targets",  FlightMenuReportTargets, AI_ESCORT._FlightSwitchReportTypeGroundRadar, self )
                                                                 :SetTag( "ReportType" )
                                                                 :SetStamp( MenuStamp )
  end
  if FlightReportType == self.__Enum.ReportType.All or FlightReportType ~= self.__Enum.ReportType.Ground then
    local FlightMenuReportTargetsGround = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Report ground targets",  FlightMenuReportTargets, AI_ESCORT._FlightSwitchReportTypeGround, self )
                                                            :SetTag( "ReportType" )
                                                            :SetStamp( MenuStamp )
  end
  
  FlightMenuReportTargets:RemoveSubMenus( MenuStamp, "ReportType" )

end


function AI_ESCORT:SetFlightMenuTargets()

  local FlightMenuReportTargets = MENU_GROUP:New( self.PlayerGroup, "Report targets", self.FlightMenu )

  -- Report Targets
  local FlightMenuReportTargetsNow = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Report targets now!", FlightMenuReportTargets, AI_ESCORT._FlightReportNearbyTargetsNow, self )
  local FlightMenuReportTargetsOn =  MENU_GROUP_COMMAND:New( self.PlayerGroup, "Report targets on",   FlightMenuReportTargets, AI_ESCORT._FlightSwitchReportNearbyTargets, self, true )
  local FlightMenuReportTargetsOff = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Report targets off",  FlightMenuReportTargets, AI_ESCORT._FlightSwitchReportNearbyTargets, self, false )

  -- Attack Targets
  self.FlightMenuAttack = MENU_GROUP:New( self.PlayerGroup, "Attack targets", self.FlightMenu )
  local FlightMenuAttackNearby = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Attack nearest targets",  self.FlightMenuAttack, AI_ESCORT._FlightAttackNearestTarget, self ):SetTag( "Attack" )
  local FlightMenuAttackNearbyAir = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Attack nearest airborne targets",  self.FlightMenuAttack, AI_ESCORT._FlightAttackNearestTarget, self, self.__Enum.ReportType.Air ):SetTag( "Attack" )
  local FlightMenuAttackNearbyGround = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Attack nearest ground targets",  self.FlightMenuAttack, AI_ESCORT._FlightAttackNearestTarget, self, self.__Enum.ReportType.Ground ):SetTag( "Attack" )
  
  for _, MenuTargets in pairs( self.Menu.Targets or {}) do
    MenuTargets.FlightReportTargetsScheduler = SCHEDULER:New( self, self._FlightReportTargetsScheduler, {}, MenuTargets.Interval, MenuTargets.Interval )
  end

  return self
end


function AI_ESCORT:SetEscortMenuTargets( EscortGroup )

  for _, MenuTargets in pairs( self.Menu.Targets or {} or {}) do
    if EscortGroup:IsAir() then
      local EscortGroupName = EscortGroup:GetName()
      --local EscortMenuReportTargets = MENU_GROUP:New( self.PlayerGroup, "Report targets", EscortGroup.EscortMenu )

      -- Report Targets
      EscortGroup.EscortMenuReportNearbyTargetsNow = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Report targets", EscortGroup.EscortMenu, AI_ESCORT._ReportNearbyTargetsNow, self, EscortGroup, true )
      --EscortGroup.EscortMenuReportNearbyTargetsOn = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Report targets on", EscortGroup.EscortMenuReportNearbyTargets, AI_ESCORT._SwitchReportNearbyTargets, self, EscortGroup, true )
      --EscortGroup.EscortMenuReportNearbyTargetsOff = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Report targets off", EscortGroup.EscortMenuReportNearbyTargets, AI_ESCORT._SwitchReportNearbyTargets, self, EscortGroup, false )
    
      -- Attack Targets
      --local EscortMenuAttackTargets = MENU_GROUP:New( self.PlayerGroup, "Attack targets", EscortGroup.EscortMenu )
    
      EscortGroup.ReportTargetsScheduler = SCHEDULER:New( self, self._ReportTargetsScheduler, { EscortGroup }, 1, MenuTargets.Interval )
      EscortGroup.ResumeScheduler = SCHEDULER:New( self, self._ResumeScheduler, { EscortGroup }, 1, 60 )
    end
  end

  return self
end



--- Defines a menu slot to let the escort report their current detected targets with a specified time interval in seconds.
-- This menu will appear under **Report targets**.
-- Note that if a report targets menu is not specified, no targets will be detected by the escort, and the attack and assisted attack menus will not be displayed.
-- @param #AI_ESCORT self
-- @param DCS#Time Seconds Optional parameter that lets the escort report their current detected targets after specified time interval in seconds. The default time is 30 seconds.
-- @return #AI_ESCORT
function AI_ESCORT:MenuTargets( Seconds )
  self:F( { Seconds } )

  if not Seconds then
    Seconds = 30
  end

  self.Menu.Targets = self.Menu.Targets or {}
  self.Menu.Targets[#self.Menu.Targets+1] = {}
  self.Menu.Targets[#self.Menu.Targets].Interval = Seconds
  
  return self
end

--- Defines a menu slot to let the escort attack its detected targets using assisted attack from another escort joined also with the client.
-- This menu will appear under **Request assistance from**.
-- Note that this method needs to be preceded with the method MenuTargets.
-- @param #AI_ESCORT self
-- @return #AI_ESCORT
function AI_ESCORT:MenuAssistedAttack()
  self:F()

  self.EscortGroupSet:ForSomeGroupAlive(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if not EscortGroup:IsAir() then
        -- Request assistance from other escorts.
        -- This is very useful to let f.e. an escorting ship attack a target detected by an escorting plane...
        self.EscortMenuTargetAssistance = MENU_GROUP:New( self.PlayerGroup, "Request assistance from", EscortGroup.EscortMenu )
      end
    end
  )

  return self
end

function AI_ESCORT:SetFlightMenuROE()

  for _, MenuROE in pairs( self.Menu.ROE or {}) do
    local FlightMenuROE = MENU_GROUP:New( self.PlayerGroup, "Rule Of Engagement", self.FlightMenu )
  
    local FlightMenuROEHoldFire   = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Hold fire",          FlightMenuROE, AI_ESCORT._FlightROEHoldFire,   self,  "Holding weapons!" )
    local FlightMenuROEReturnFire = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Return fire",        FlightMenuROE, AI_ESCORT._FlightROEReturnFire, self, "Returning fire!" )
    local FlightMenuROEOpenFire   = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Open Fire",          FlightMenuROE, AI_ESCORT._FlightROEOpenFire,   self,  "Open fire at designated targets!" )
    local FlightMenuROEWeaponFree = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Engage all targets", FlightMenuROE, AI_ESCORT._FlightROEWeaponFree, self,  "Engaging all targets!" )
  end

  return self
end


function AI_ESCORT:SetEscortMenuROE( EscortGroup )

  for _, MenuROE in pairs( self.Menu.ROE or {}) do
    if EscortGroup:IsAir() then

      local EscortGroupName = EscortGroup:GetName()
      local EscortMenuROE = MENU_GROUP:New( self.PlayerGroup, "Rule Of Engagement", EscortGroup.EscortMenu )
      
      if EscortGroup:OptionROEHoldFirePossible() then
        local EscortMenuROEHoldFire         = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Hold fire",          EscortMenuROE, AI_ESCORT._ROE, self, EscortGroup, EscortGroup.OptionROEHoldFire, "Holding weapons!" )
      end
      if EscortGroup:OptionROEReturnFirePossible() then
        local EscortMenuROEReturnFire       = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Return fire",        EscortMenuROE, AI_ESCORT._ROE, self, EscortGroup, EscortGroup.OptionROEReturnFire, "Returning fire!" )
      end
      if EscortGroup:OptionROEOpenFirePossible() then
        EscortGroup.EscortMenuROEOpenFire   = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Open Fire",          EscortMenuROE, AI_ESCORT._ROE, self, EscortGroup, EscortGroup.OptionROEOpenFire, "Opening fire on designated targets!!" )
      end
      if EscortGroup:OptionROEWeaponFreePossible() then
        EscortGroup.EscortMenuROEWeaponFree = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Engage all targets", EscortMenuROE, AI_ESCORT._ROE, self, EscortGroup, EscortGroup.OptionROEWeaponFree, "Opening fire on targets of opportunity!" )
      end
    end
  end

  return self
end


--- Defines a menu to let the escort set its rules of engagement.
-- All rules of engagement will appear under the menu **ROE**.
-- @param #AI_ESCORT self
-- @return #AI_ESCORT
function AI_ESCORT:MenuROE()
  self:F()

  self.Menu.ROE = self.Menu.ROE or {}
  self.Menu.ROE[#self.Menu.ROE+1] = {}

  return self
end


function AI_ESCORT:SetFlightMenuROT()

  for _, MenuROT in pairs( self.Menu.ROT or {}) do
    local FlightMenuROT = MENU_GROUP:New( self.PlayerGroup, "Reaction On Threat", self.FlightMenu )
  
    local FlightMenuROTNoReaction     = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Fight until death",             FlightMenuROT, AI_ESCORT._FlightROTNoReaction,     self, "Fighting until death!" )
    local FlightMenuROTPassiveDefense = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Use flares, chaff and jammers", FlightMenuROT, AI_ESCORT._FlightROTPassiveDefense, self, "Defending using jammers, chaff and flares!" )
    local FlightMenuROTEvadeFire      = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Open fire",                     FlightMenuROT, AI_ESCORT._FlightROTEvadeFire,      self, "Evading on enemy fire!" )
    local FlightMenuROTVertical       = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Avoid radar and evade fire",    FlightMenuROT, AI_ESCORT._FlightROTVertical,       self, "Evading on enemy fire with vertical manoeuvres!" )
  end

  return self
end


function AI_ESCORT:SetEscortMenuROT( EscortGroup )

  for _, MenuROT in pairs( self.Menu.ROT or {}) do
    if EscortGroup:IsAir() then

      local EscortGroupName = EscortGroup:GetName()
      local EscortMenuROT = MENU_GROUP:New( self.PlayerGroup, "Reaction On Threat", EscortGroup.EscortMenu )

      if not EscortGroup.EscortMenuEvasion then
        -- Reaction to Threats
        if EscortGroup:OptionROTNoReactionPossible() then
          local EscortMenuEvasionNoReaction     = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Fight until death",             EscortMenuROT, AI_ESCORT._ROT, self, EscortGroup, EscortGroup.OptionROTNoReaction, "Fighting until death!" )
        end
        if EscortGroup:OptionROTPassiveDefensePossible() then
          local EscortMenuEvasionPassiveDefense = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Use flares, chaff and jammers", EscortMenuROT, AI_ESCORT._ROT, self, EscortGroup, EscortGroup.OptionROTPassiveDefense, "Defending using jammers, chaff and flares!" )
        end
        if EscortGroup:OptionROTEvadeFirePossible() then
          local EscortMenuEvasionEvadeFire      = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Open fire",                     EscortMenuROT, AI_ESCORT._ROT, self, EscortGroup, EscortGroup.OptionROTEvadeFire, "Evading on enemy fire!" )
        end
        if EscortGroup:OptionROTVerticalPossible() then
          local EscortMenuOptionEvasionVertical = MENU_GROUP_COMMAND:New( self.PlayerGroup, "Avoid radar and evade fire",    EscortMenuROT, AI_ESCORT._ROT, self, EscortGroup, EscortGroup.OptionROTVertical, "Evading on enemy fire with vertical manoeuvres!" )
        end
      end
    end
  end

  return self
end



--- Defines a menu to let the escort set its evasion when under threat.
-- All rules of engagement will appear under the menu **Evasion**.
-- @param #AI_ESCORT self
-- @return #AI_ESCORT
function AI_ESCORT:MenuROT( MenuTextFormat )
  self:F( MenuTextFormat )

  self.Menu.ROT = self.Menu.ROT or {}
  self.Menu.ROT[#self.Menu.ROT+1] = {}

  return self
end

--- Defines a menu to let the escort resume its mission from a waypoint on its route.
-- All rules of engagement will appear under the menu **Resume mission from**.
-- @param #AI_ESCORT self
-- @return #AI_ESCORT
function AI_ESCORT:SetEscortMenuResumeMission( EscortGroup )
  self:F()

  if EscortGroup:IsAir() then
    local EscortGroupName = EscortGroup:GetName()
    EscortGroup.EscortMenuResumeMission = MENU_GROUP:New( self.PlayerGroup, "Resume from", EscortGroup.EscortMenu )
  end

  return self
end


-- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP OrbitGroup
-- @param Wrapper.Group#GROUP EscortGroup
-- @param #number OrbitHeight
-- @param #number OrbitSeconds
function AI_ESCORT:_HoldPosition( OrbitGroup, EscortGroup, OrbitHeight, OrbitSeconds )

  local EscortUnit = self.PlayerUnit

  local OrbitUnit = OrbitGroup:GetUnit(1) -- Wrapper.Unit#UNIT
  
  self:SetFlightModeMission( EscortGroup )

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

  EscortGroup:SetTask( EscortGroup:TaskRoute( Points ), 1 )
  EscortGroup:MessageTypeToGroup( "Orbiting at current location.", MESSAGE.Type.Information, EscortUnit:GetGroup() )

end


-- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP OrbitGroup
-- @param #number OrbitHeight
-- @param #number OrbitSeconds
function AI_ESCORT:_FlightHoldPosition( OrbitGroup, OrbitHeight, OrbitSeconds )

  local EscortUnit = self.PlayerUnit

  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup, OrbitGroup )
      if EscortGroup:IsAir() then
        if OrbitGroup == nil then
          OrbitGroup = EscortGroup
        end
        self:_HoldPosition( OrbitGroup, EscortGroup, OrbitHeight, OrbitSeconds )
      end
    end, OrbitGroup
  )

end  



function AI_ESCORT:_JoinUp( EscortGroup )

  local EscortUnit = self.PlayerUnit

  self:SetFlightModeFormation( EscortGroup )

  EscortGroup:MessageTypeToGroup( "Joining up!", MESSAGE.Type.Information, EscortUnit:GetGroup() )
end


function AI_ESCORT:_FlightJoinUp()

  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if EscortGroup:IsAir() then
        self:_JoinUp( EscortGroup )
      end
    end
  )

end


--- Lets the escort to join in a trail formation.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @return #AI_ESCORT
function AI_ESCORT:_EscortFormationTrail( EscortGroup, XStart, XSpace, YStart )

  self:FormationTrail( XStart, XSpace, YStart )

end


function AI_ESCORT:_FlightFormationTrail( XStart, XSpace, YStart )

  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if EscortGroup:IsAir() then
        self:_EscortFormationTrail( EscortGroup, XStart, XSpace, YStart )
      end
    end
  )

end

--- Lets the escort to join in a stacked formation.
-- @param #AI_ESCORT self
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
-- @return #AI_ESCORT
function AI_ESCORT:_EscortFormationStack( EscortGroup, XStart, XSpace, YStart, YSpace )

  self:FormationStack( XStart, XSpace, YStart, YSpace )

end


function AI_ESCORT:_FlightFormationStack( XStart, XSpace, YStart, YSpace )

  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if EscortGroup:IsAir() then
        self:_EscortFormationStack( EscortGroup, XStart, XSpace, YStart, YSpace )
      end
    end
  )

end


function AI_ESCORT:_Flare( EscortGroup, Color, Message )

  local EscortUnit = self.PlayerUnit

  EscortGroup:GetUnit(1):Flare( Color )
  EscortGroup:MessageTypeToGroup( Message, MESSAGE.Type.Information, EscortUnit:GetGroup() )
end


function AI_ESCORT:_FlightFlare( Color, Message )

  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if EscortGroup:IsAir() then
        self:_Flare( EscortGroup, Color, Message )
      end
    end
  )
  
end



function AI_ESCORT:_Smoke( EscortGroup, Color, Message )

  local EscortUnit = self.PlayerUnit

  EscortGroup:GetUnit(1):Smoke( Color )
  EscortGroup:MessageTypeToGroup( Message, MESSAGE.Type.Information, EscortUnit:GetGroup() )
end

function AI_ESCORT:_FlightSmoke( Color, Message )

  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if EscortGroup:IsAir() then
        self:_Smoke( EscortGroup, Color, Message )
      end
    end
  )

end


function AI_ESCORT:_ReportNearbyTargetsNow( EscortGroup )

  local EscortUnit = self.PlayerUnit

  self:_ReportTargetsScheduler( EscortGroup )

end


function AI_ESCORT:_FlightReportNearbyTargetsNow()

  self:_FlightReportTargetsScheduler()
  
end



function AI_ESCORT:_FlightSwitchReportNearbyTargets( ReportTargets )

  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      if EscortGroup:IsAir() then
        self:_EscortSwitchReportNearbyTargets( EscortGroup, ReportTargets )
      end
    end
  )

end

function AI_ESCORT:SetFlightReportType( ReportType )

  self.FlightReportType = ReportType

end

function AI_ESCORT:GetFlightReportType()

  return self.FlightReportType

end

function AI_ESCORT:_FlightSwitchReportTypeAll()

  self:SetFlightReportType( self.__Enum.ReportType.All )
  self:SetFlightMenuReportType()

  local EscortGroup = self.EscortGroupSet:GetFirst()
  EscortGroup:MessageTypeToGroup( "Reporting all targets.", MESSAGE.Type.Information, self.PlayerGroup )

end

function AI_ESCORT:_FlightSwitchReportTypeAirborne()

  self:SetFlightReportType( self.__Enum.ReportType.Airborne )
  self:SetFlightMenuReportType()

  local EscortGroup = self.EscortGroupSet:GetFirst()
  EscortGroup:MessageTypeToGroup( "Reporting airborne targets.", MESSAGE.Type.Information, self.PlayerGroup )

end

function AI_ESCORT:_FlightSwitchReportTypeGroundRadar()

  self:SetFlightReportType( self.__Enum.ReportType.Ground )
  self:SetFlightMenuReportType()

  local EscortGroup = self.EscortGroupSet:GetFirst()
  EscortGroup:MessageTypeToGroup( "Reporting ground radar targets.", MESSAGE.Type.Information, self.PlayerGroup )

end

function AI_ESCORT:_FlightSwitchReportTypeGround()

  self:SetFlightReportType( self.__Enum.ReportType.Ground )
  self:SetFlightMenuReportType()

  local EscortGroup = self.EscortGroupSet:GetFirst()
  EscortGroup:MessageTypeToGroup( "Reporting ground targets.", MESSAGE.Type.Information, self.PlayerGroup )

end


function AI_ESCORT:_ScanTargets( ScanDuration )

  local EscortGroup = self.EscortGroup -- Wrapper.Group#GROUP
  local EscortUnit = self.PlayerUnit

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

  EscortGroup:MessageToClient( "Scanning targets for " .. ScanDuration .. " seconds.", ScanDuration, EscortUnit )

  if self.EscortMode == AI_ESCORT.MODE.FOLLOW then
    self.FollowScheduler:Start( self.FollowSchedule )
  end

end

-- @param Wrapper.Group#GROUP EscortGroup
-- @param #AI_ESCORT self
function AI_ESCORT.___Resume( EscortGroup, self )

  self:F( { self=self } )

  local PlayerGroup = self.PlayerGroup
  
  EscortGroup:OptionROEHoldFire()
  EscortGroup:OptionROTVertical()
  
  EscortGroup:SetState( EscortGroup, "Mode", EscortGroup:GetState( EscortGroup, "PreviousMode" ) )
  
  if EscortGroup:GetState( EscortGroup, "Mode" ) == self.__Enum.Mode.Mission then
    EscortGroup:MessageTypeToGroup( "Resuming route.", MESSAGE.Type.Information, PlayerGroup )
  else
    EscortGroup:MessageTypeToGroup( "Rejoining formation.", MESSAGE.Type.Information, PlayerGroup )
  end

end


-- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP EscortGroup
-- @param #number WayPoint
function AI_ESCORT:_ResumeMission( EscortGroup, WayPoint )

  --self.FollowScheduler:Stop( self.FollowSchedule )
  
  self:SetFlightModeMission( EscortGroup )

  local WayPoints = EscortGroup.MissionRoute
  self:T( WayPoint, WayPoints )

  for WayPointIgnore = 1, WayPoint do
    table.remove( WayPoints, 1 )
  end

  EscortGroup:SetTask( EscortGroup:TaskRoute( WayPoints ), 1 )
  
  EscortGroup:MessageTypeToGroup( "Resuming mission from waypoint ", MESSAGE.Type.Information, self.PlayerGroup )
end


-- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP EscortGroup The escort group that will attack the detected item.
-- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
function AI_ESCORT:_AttackTarget( EscortGroup, DetectedItem )

  self:F( EscortGroup )
  
  self:SetFlightModeAttack( EscortGroup )

  if EscortGroup:IsAir() then
    EscortGroup:OptionROEOpenFire()
    EscortGroup:OptionROTVertical()
    EscortGroup:SetState( EscortGroup, "Escort", self )

    local DetectedSet = self.Detection:GetDetectedItemSet( DetectedItem )
    
    local Tasks = {}
    local AttackUnitTasks = {}

    DetectedSet:ForEachUnit(
      -- @param Wrapper.Unit#UNIT DetectedUnit
      function( DetectedUnit, Tasks )
        if DetectedUnit:IsAlive() then
          AttackUnitTasks[#AttackUnitTasks+1] = EscortGroup:TaskAttackUnit( DetectedUnit )
        end
      end, Tasks
    )    

    Tasks[#Tasks+1] = EscortGroup:TaskCombo( AttackUnitTasks )
    Tasks[#Tasks+1] = EscortGroup:TaskFunction( "AI_ESCORT.___Resume", self )
    
    EscortGroup:PushTask( 
      EscortGroup:TaskCombo(
        Tasks
      ), 1
    )
    
  else
  
    local DetectedSet = self.Detection:GetDetectedItemSet( DetectedItem )
    
    local Tasks = {}

    DetectedSet:ForEachUnit(
      -- @param Wrapper.Unit#UNIT DetectedUnit
      function( DetectedUnit, Tasks )
        if DetectedUnit:IsAlive() then
          Tasks[#Tasks+1] = EscortGroup:TaskFireAtPoint( DetectedUnit:GetVec2(), 50 )
        end
      end, Tasks
    )    

    EscortGroup:PushTask( 
      EscortGroup:TaskCombo(
        Tasks
      ), 1
    )

  end
  
  local DetectedTargetsReport = REPORT:New( "Engaging target:\n" )
  local DetectedItemReportSummary = self.Detection:DetectedItemReportSummary( DetectedItem, self.PlayerGroup, _DATABASE:GetPlayerSettings( self.PlayerUnit:GetPlayerName() ) )
  local ReportSummary = DetectedItemReportSummary:Text(", ")
  DetectedTargetsReport:AddIndent( ReportSummary, "-" )

  EscortGroup:MessageTypeToGroup( DetectedTargetsReport:Text(), MESSAGE.Type.Information, self.PlayerGroup )
end


function AI_ESCORT:_FlightAttackTarget( DetectedItem )

  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Core.Group#GROUP EscortGroup
    function( EscortGroup, DetectedItem )
      if EscortGroup:IsAir() then
        self:_AttackTarget( EscortGroup, DetectedItem )
      end
    end, DetectedItem
  )

end


function AI_ESCORT:_FlightAttackNearestTarget( TargetType )

  self.Detection:Detect()
  self:_FlightReportTargetsScheduler()
  
  local EscortGroup = self.EscortGroupSet:GetFirst()
  local AttackDetectedItem = nil
  local DetectedItems = self.Detection:GetDetectedItems()

  for DetectedItemIndex, DetectedItem in UTILS.spairs( DetectedItems, function( t, a, b ) return self:Distance( self.PlayerUnit, t[a] ) < self:Distance( self.PlayerUnit, t[b] ) end  ) do
  
    local DetectedItemSet = self.Detection:GetDetectedItemSet( DetectedItem )
    
    local HasGround = DetectedItemSet:HasGroundUnits() > 0
    local HasAir = DetectedItemSet:HasAirUnits() > 0
    
    local FlightReportType = self:GetFlightReportType()
        
    if ( TargetType and TargetType == self.__Enum.ReportType.Ground and HasGround ) or
       ( TargetType and TargetType == self.__Enum.ReportType.Air and HasAir ) or
       ( TargetType ==  nil ) then
      AttackDetectedItem = DetectedItem
      break
    end
  end
  
  if AttackDetectedItem then
    self:_FlightAttackTarget( AttackDetectedItem )
  else
    EscortGroup:MessageTypeToGroup( "Nothing to attack!", MESSAGE.Type.Information, self.PlayerGroup )
  end

end


--- 
-- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP EscortGroup The escort group that will attack the detected item.
-- @param Functional.Detection#DETECTION_BASE.DetectedItem DetectedItem
function AI_ESCORT:_AssistTarget( EscortGroup, DetectedItem )

  local EscortUnit = self.PlayerUnit

  local DetectedSet = self.Detection:GetDetectedItemSet( DetectedItem )
  
  local Tasks = {}

  DetectedSet:ForEachUnit(
    -- @param Wrapper.Unit#UNIT DetectedUnit
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


  EscortGroup:MessageTypeToGroup( "Assisting attack!", MESSAGE.Type.Information, EscortUnit:GetGroup() )

end

function AI_ESCORT:_ROE( EscortGroup, EscortROEFunction, EscortROEMessage )
    pcall( function() EscortROEFunction( EscortGroup ) end )
    EscortGroup:MessageTypeToGroup( EscortROEMessage, MESSAGE.Type.Information, self.PlayerGroup )
end


function AI_ESCORT:_FlightROEHoldFire( EscortROEMessage )
  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Wrapper.Group#GROUP EscortGroup
    function( EscortGroup )
      self:_ROE( EscortGroup, EscortGroup.OptionROEHoldFire, EscortROEMessage )
    end
  )
end

function AI_ESCORT:_FlightROEOpenFire( EscortROEMessage )
  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Wrapper.Group#GROUP EscortGroup
    function( EscortGroup )
      self:_ROE( EscortGroup, EscortGroup.OptionROEOpenFire, EscortROEMessage )
    end
  )
end

function AI_ESCORT:_FlightROEReturnFire( EscortROEMessage )
  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Wrapper.Group#GROUP EscortGroup
    function( EscortGroup )
      self:_ROE( EscortGroup, EscortGroup.OptionROEReturnFire, EscortROEMessage )
    end
  )
end

function AI_ESCORT:_FlightROEWeaponFree( EscortROEMessage )
  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Wrapper.Group#GROUP EscortGroup
    function( EscortGroup )
      self:_ROE( EscortGroup, EscortGroup.OptionROEWeaponFree, EscortROEMessage )
    end
  )
end


function AI_ESCORT:_ROT( EscortGroup, EscortROTFunction, EscortROTMessage )
  pcall( function() EscortROTFunction( EscortGroup ) end )
  EscortGroup:MessageTypeToGroup( EscortROTMessage, MESSAGE.Type.Information, self.PlayerGroup )
end


function AI_ESCORT:_FlightROTNoReaction( EscortROTMessage )
  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Wrapper.Group#GROUP EscortGroup
    function( EscortGroup )
      self:_ROT( EscortGroup, EscortGroup.OptionROTNoReaction, EscortROTMessage )
    end
  )
end

function AI_ESCORT:_FlightROTPassiveDefense( EscortROTMessage )
  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Wrapper.Group#GROUP EscortGroup
    function( EscortGroup )
      self:_ROT( EscortGroup, EscortGroup.OptionROTPassiveDefense, EscortROTMessage )
    end
  )
end

function AI_ESCORT:_FlightROTEvadeFire( EscortROTMessage )
  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Wrapper.Group#GROUP EscortGroup
    function( EscortGroup )
      self:_ROT( EscortGroup, EscortGroup.OptionROTEvadeFire, EscortROTMessage )
    end
  )
end

function AI_ESCORT:_FlightROTVertical( EscortROTMessage )
  self.EscortGroupSet:ForEachGroupAlive(
    -- @param Wrapper.Group#GROUP EscortGroup
    function( EscortGroup )
      self:_ROT( EscortGroup, EscortGroup.OptionROTVertical, EscortROTMessage )
    end
  )
end

--- Registers the waypoints
-- @param #AI_ESCORT self
-- @return #table
function AI_ESCORT:RegisterRoute()
  self:F()

  local EscortGroup = self.EscortGroup -- Wrapper.Group#GROUP

  local TaskPoints = EscortGroup:GetTaskRoute()

  self:T( TaskPoints )

  return TaskPoints
end

--- Resume Scheduler.
-- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP EscortGroup
function AI_ESCORT:_ResumeScheduler( EscortGroup )
  self:F( EscortGroup:GetName() )

  if EscortGroup:IsAlive() and self.PlayerUnit:IsAlive() then


    local EscortGroupName = EscortGroup:GetCallsign() 

    if EscortGroup.EscortMenuResumeMission then
      EscortGroup.EscortMenuResumeMission:RemoveSubMenus()

      local TaskPoints = EscortGroup.MissionRoute
      
      for WayPointID, WayPoint in pairs( TaskPoints ) do
        local EscortVec3 = EscortGroup:GetVec3()
        local Distance = ( ( WayPoint.x - EscortVec3.x )^2 +
          ( WayPoint.y - EscortVec3.z )^2
          ) ^ 0.5 / 1000
        MENU_GROUP_COMMAND:New( self.PlayerGroup, "Waypoint " .. WayPointID .. " at " .. string.format( "%.2f", Distance ).. "km", EscortGroup.EscortMenuResumeMission, AI_ESCORT._ResumeMission, self, EscortGroup, WayPointID )
      end
    end
  end
end


--- Measure distance between coordinate player and coordinate detected item.
-- @param #AI_ESCORT self
function AI_ESCORT:Distance( PlayerUnit, DetectedItem )

  local DetectedCoordinate = self.Detection:GetDetectedItemCoordinate( DetectedItem )
  local PlayerCoordinate = PlayerUnit:GetCoordinate()
  
  return DetectedCoordinate:Get3DDistance( PlayerCoordinate )

end

--- Report Targets Scheduler.
-- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP EscortGroup
function AI_ESCORT:_ReportTargetsScheduler( EscortGroup, Report )
  self:F( EscortGroup:GetName() )

  if EscortGroup:IsAlive() and self.PlayerUnit:IsAlive() then

      local EscortGroupName = EscortGroup:GetCallsign() 
 
      local DetectedTargetsReport = REPORT:New( "Reporting targets:\n" ) -- A new report to display the detected targets as a message to the player.
    

      if EscortGroup.EscortMenuTargetAssistance then
        EscortGroup.EscortMenuTargetAssistance:RemoveSubMenus()
      end

      local DetectedItems = self.Detection:GetDetectedItems()

      local ClientEscortTargets = self.Detection

      local TimeUpdate = timer.getTime()
      
      local EscortMenuAttackTargets = MENU_GROUP:New( self.PlayerGroup, "Attack targets", EscortGroup.EscortMenu )
      
      local DetectedTargets = false
      
      for DetectedItemIndex, DetectedItem in UTILS.spairs( DetectedItems, function( t, a, b ) return self:Distance( self.PlayerUnit, t[a] ) < self:Distance( self.PlayerUnit, t[b] ) end  ) do
      --for DetectedItemIndex, DetectedItem in pairs( DetectedItems ) do

        local DetectedItemSet = self.Detection:GetDetectedItemSet( DetectedItem )
        
        local HasGround = DetectedItemSet:HasGroundUnits() > 0
        local HasGroundRadar = HasGround and DetectedItemSet:HasRadar() > 0
        local HasAir = DetectedItemSet:HasAirUnits() > 0
        
        local FlightReportType = self:GetFlightReportType()
          

        if ( FlightReportType == self.__Enum.ReportType.All ) or
           ( FlightReportType == self.__Enum.ReportType.Airborne and HasAir ) or
           ( FlightReportType == self.__Enum.ReportType.Ground and HasGround ) or
           ( FlightReportType == self.__Enum.ReportType.GroundRadar and HasGroundRadar ) then
      
          DetectedTargets = true
  
          local DetectedMenu = self.Detection:DetectedItemReportMenu( DetectedItem, EscortGroup, _DATABASE:GetPlayerSettings( self.PlayerUnit:GetPlayerName() ) ):Text("\n")
  
          local DetectedItemReportSummary = self.Detection:DetectedItemReportSummary( DetectedItem, EscortGroup, _DATABASE:GetPlayerSettings( self.PlayerUnit:GetPlayerName() ) )
          local ReportSummary = DetectedItemReportSummary:Text(", ")
          DetectedTargetsReport:AddIndent( ReportSummary, "-" )
          
          if EscortGroup:IsAir() then
  
            MENU_GROUP_COMMAND:New( self.PlayerGroup,
              DetectedMenu,
              EscortMenuAttackTargets,
              AI_ESCORT._AttackTarget,
              self,
              EscortGroup,
              DetectedItem
            ):SetTag( "Escort" ):SetTime( TimeUpdate )
          else
            if self.EscortMenuTargetAssistance then
              local MenuTargetAssistance = MENU_GROUP:New( self.PlayerGroup, EscortGroupName, EscortGroup.EscortMenuTargetAssistance )
              MENU_GROUP_COMMAND:New( self.PlayerGroup,
                DetectedMenu,
                MenuTargetAssistance,
                AI_ESCORT._AssistTarget,
                self,
                EscortGroup,
                DetectedItem
              )
            end
          end
        end
      end

      EscortMenuAttackTargets:RemoveSubMenus( TimeUpdate, "Escort" )

      if Report then
        if DetectedTargets then
          EscortGroup:MessageTypeToGroup( DetectedTargetsReport:Text( "\n" ), MESSAGE.Type.Information, self.PlayerGroup )
        else
          EscortGroup:MessageTypeToGroup( "No targets detected.", MESSAGE.Type.Information, self.PlayerGroup )
        end
      end

      return true
  end
  
  return false
end

--- Report Targets Scheduler for the flight. The report is generated from the perspective of the player plane, and is reported by the first plane in the formation set.
-- @param #AI_ESCORT self
-- @param Wrapper.Group#GROUP EscortGroup
function AI_ESCORT:_FlightReportTargetsScheduler()

  self:F("FlightReportTargetScheduler")
  
  local EscortGroup = self.EscortGroupSet:GetFirst() -- Wrapper.Group#GROUP
  
  local DetectedTargetsReport = REPORT:New( "Reporting your targets:\n" ) -- A new report to display the detected targets as a message to the player.

  if EscortGroup and ( self.PlayerUnit:IsAlive() and EscortGroup:IsAlive() ) then

    local TimeUpdate = timer.getTime()

    local DetectedItems = self.Detection:GetDetectedItems()

    local DetectedTargets = false

    local ClientEscortTargets = self.Detection

    for DetectedItemIndex, DetectedItem in UTILS.spairs( DetectedItems, function( t, a, b ) return self:Distance( self.PlayerUnit, t[a] ) < self:Distance( self.PlayerUnit, t[b] ) end  ) do
    
      self:F("FlightReportTargetScheduler Targets")

      local DetectedItemSet = self.Detection:GetDetectedItemSet( DetectedItem )
      
      local HasGround = DetectedItemSet:HasGroundUnits() > 0
      local HasGroundRadar = HasGround and DetectedItemSet:HasRadar() > 0
      local HasAir = DetectedItemSet:HasAirUnits() > 0
      
      local FlightReportType = self:GetFlightReportType()
          

      if ( FlightReportType == self.__Enum.ReportType.All ) or
         ( FlightReportType == self.__Enum.ReportType.Airborne and HasAir ) or
         ( FlightReportType == self.__Enum.ReportType.Ground and HasGround ) or
         ( FlightReportType == self.__Enum.ReportType.GroundRadar and HasGroundRadar ) then
         

        DetectedTargets = true -- There are detected targets, when the content of the for loop is executed. We use it to display a message.
        
        local DetectedItemReportMenu = self.Detection:DetectedItemReportMenu( DetectedItem, self.PlayerGroup, _DATABASE:GetPlayerSettings( self.PlayerUnit:GetPlayerName() ) )
        local ReportMenuText = DetectedItemReportMenu:Text(", ")
        
        MENU_GROUP_COMMAND:New( self.PlayerGroup,
          ReportMenuText,
          self.FlightMenuAttack,
          AI_ESCORT._FlightAttackTarget,
          self,
          DetectedItem
        ):SetTag( "Flight" ):SetTime( TimeUpdate )
  
        local DetectedItemReportSummary = self.Detection:DetectedItemReportSummary( DetectedItem, self.PlayerGroup, _DATABASE:GetPlayerSettings( self.PlayerUnit:GetPlayerName() ) )
        local ReportSummary = DetectedItemReportSummary:Text(", ")
        DetectedTargetsReport:AddIndent( ReportSummary, "-" )
      end
    end

    self.FlightMenuAttack:RemoveSubMenus( TimeUpdate, "Flight" )

    if DetectedTargets then
      EscortGroup:MessageTypeToGroup( DetectedTargetsReport:Text( "\n" ), MESSAGE.Type.Information, self.PlayerGroup )
--    else
--      EscortGroup:MessageTypeToGroup( "No targets detected.", MESSAGE.Type.Information, self.PlayerGroup )
    end

    return true
  end
  
  return false
end
