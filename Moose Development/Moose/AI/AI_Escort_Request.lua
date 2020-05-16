--- **Functional** -- Taking the lead of AI escorting your flight or of other AI, upon request using the menu.
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



--- @type AI_ESCORT_REQUEST
-- @extends AI.AI_Escort#AI_ESCORT

--- AI_ESCORT_REQUEST class
-- 
-- # AI_ESCORT_REQUEST construction methods.
-- 
-- Create a new AI_ESCORT_REQUEST object with the @{#AI_ESCORT_REQUEST.New} method:
--
--  * @{#AI_ESCORT_REQUEST.New}: Creates a new AI_ESCORT_REQUEST object from a @{Wrapper.Group#GROUP} for a @{Wrapper.Client#CLIENT}, with an optional briefing text.
--
-- @usage
-- -- Declare a new EscortPlanes object as follows:
-- 
-- -- First find the GROUP object and the CLIENT object.
-- local EscortUnit = CLIENT:FindByName( "Unit Name" ) -- The Unit Name is the name of the unit flagged with the skill Client in the mission editor.
-- local EscortGroup = GROUP:FindByName( "Group Name" ) -- The Group Name is the name of the group that will escort the Escort Client.
-- 
-- -- Now use these 2 objects to construct the new EscortPlanes object.
-- EscortPlanes = AI_ESCORT_REQUEST:New( EscortUnit, EscortGroup, "Desert", "Welcome to the mission. You are escorted by a plane with code name 'Desert', which can be instructed through the F10 radio menu." )
--
-- @field #AI_ESCORT_REQUEST
AI_ESCORT_REQUEST = {
  ClassName = "AI_ESCORT_REQUEST",
}

--- AI_ESCORT_REQUEST.Mode class
-- @type AI_ESCORT_REQUEST.MODE
-- @field #number FOLLOW
-- @field #number MISSION

--- MENUPARAM type
-- @type MENUPARAM
-- @field #AI_ESCORT_REQUEST ParamSelf
-- @field #Distance ParamDistance
-- @field #function ParamFunction
-- @field #string ParamMessage

--- AI_ESCORT_REQUEST class constructor for an AI group
-- @param #AI_ESCORT_REQUEST self
-- @param Wrapper.Client#CLIENT EscortUnit The client escorted by the EscortGroup.
-- @param Core.Spawn#SPAWN EscortSpawn The spawn object of AI, escorting the EscortUnit.
-- @param Wrapper.Airbase#AIRBASE EscortAirbase The airbase where escorts will be spawned once requested.
-- @param #string EscortName Name of the escort.
-- @param #string EscortBriefing A text showing the AI_ESCORT_REQUEST briefing to the player. Note that if no EscortBriefing is provided, the default briefing will be shown.
-- @return #AI_ESCORT_REQUEST
-- @usage
-- EscortSpawn = SPAWN:NewWithAlias( "Red A2G Escort Template", "Red A2G Escort AI" ):InitLimit( 10, 10 )
-- EscortSpawn:ParkAtAirbase( AIRBASE:FindByName( AIRBASE.Caucasus.Sochi_Adler ), AIRBASE.TerminalType.OpenBig )
--
-- local EscortUnit = UNIT:FindByName( "Red A2G Pilot" )
--
-- Escort = AI_ESCORT_REQUEST:New( EscortUnit, EscortSpawn, AIRBASE:FindByName(AIRBASE.Caucasus.Sochi_Adler), "A2G", "Briefing" )
-- Escort:FormationTrail( 50, 100, 100 )
-- Escort:Menus()
-- Escort:__Start( 5 )
function AI_ESCORT_REQUEST:New( EscortUnit, EscortSpawn, EscortAirbase, EscortName, EscortBriefing )
  
  local EscortGroupSet = SET_GROUP:New():FilterDeads():FilterCrashes()
  local self = BASE:Inherit( self, AI_ESCORT:New( EscortUnit, EscortGroupSet, EscortName, EscortBriefing ) ) -- #AI_ESCORT_REQUEST

  self.EscortGroupSet = EscortGroupSet
  self.EscortSpawn = EscortSpawn
  self.EscortAirbase = EscortAirbase

  self.LeaderGroup = self.PlayerUnit:GetGroup()

  self.Detection = DETECTION_AREAS:New( self.EscortGroupSet, 5000 )
  self.Detection:__Start( 30 )
  
  self.SpawnMode = self.__Enum.Mode.Mission
  
  return self
end

--- @param #AI_ESCORT_REQUEST self
function AI_ESCORT_REQUEST:SpawnEscort()

  local EscortGroup = self.EscortSpawn:SpawnAtAirbase( self.EscortAirbase, SPAWN.Takeoff.Hot )

  self:ScheduleOnce( 0.1,
    function( EscortGroup )

      EscortGroup:OptionROTVertical()
      EscortGroup:OptionROEHoldFire()
  
      self.EscortGroupSet:AddGroup( EscortGroup )

      local LeaderEscort = self.EscortGroupSet:GetFirst() -- Wrapper.Group#GROUP
      local Report = REPORT:New()
      Report:Add( "Joining Up " .. self.EscortGroupSet:GetUnitTypeNames():Text( ", " ) .. " from " .. LeaderEscort:GetCoordinate():ToString( self.EscortUnit ) )
      LeaderEscort:MessageTypeToGroup( Report:Text(),  MESSAGE.Type.Information, self.PlayerUnit )

      self:SetFlightModeFormation( EscortGroup )
      self:FormationTrail()

      self:_InitFlightMenus()
      self:_InitEscortMenus( EscortGroup )
      self:_InitEscortRoute( EscortGroup )

      --- @param #AI_ESCORT self
      -- @param Core.Event#EVENTDATA EventData
      function EscortGroup:OnEventDeadOrCrash( EventData )
        self:F( { "EventDead", EventData } )
        self.EscortMenu:Remove()
      end

      EscortGroup:HandleEvent( EVENTS.Dead, EscortGroup.OnEventDeadOrCrash )
      EscortGroup:HandleEvent( EVENTS.Crash, EscortGroup.OnEventDeadOrCrash )

    end, EscortGroup
  )

end

--- @param #AI_ESCORT_REQUEST self
-- @param Core.Set#SET_GROUP EscortGroupSet
function AI_ESCORT_REQUEST:onafterStart( EscortGroupSet )

  self:F()

  if not self.MenuRequestEscort then
    self.MainMenu = MENU_GROUP:New( self.PlayerGroup, self.EscortName )
    self.MenuRequestEscort = MENU_GROUP_COMMAND:New( self.LeaderGroup, "Request new escort ", self.MainMenu, 
      function()
        self:SpawnEscort()
      end
      )
  end

  self:GetParent( self ).onafterStart( self, EscortGroupSet )

  self:HandleEvent( EVENTS.Dead, self.OnEventDeadOrCrash )
  self:HandleEvent( EVENTS.Crash, self.OnEventDeadOrCrash )
    
end

--- @param #AI_ESCORT_REQUEST self
-- @param Core.Set#SET_GROUP EscortGroupSet
function AI_ESCORT_REQUEST:onafterStop( EscortGroupSet )

  self:F()
  
  EscortGroupSet:ForEachGroup(
    --- @param Core.Group#GROUP EscortGroup
    function( EscortGroup )
      EscortGroup:WayPointInitialize()
    
      EscortGroup:OptionROTVertical()
      EscortGroup:OptionROEOpenFire()
    end
  )

  self.Detection:Stop()
    
  self.MainMenu:Remove()
  
end

--- Set the spawn mode to be mission execution.
-- @param #AI_ESCORT_REQUEST self
function AI_ESCORT_REQUEST:SetEscortSpawnMission()

  self.SpawnMode = self.__Enum.Mode.Mission
    
end
