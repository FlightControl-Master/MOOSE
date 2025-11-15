--- **Functional** - Build large airborne formations of aircraft.
--
-- **Features:**
--
--   * Build in-air formations consisting of more than 40 aircraft as one group.
--   * Build different formation types.
--   * Assign a group leader that will guide the large formation path.
--
-- ===
--
-- ## Additional Material:
--
-- * **Demo Missions:** [GitHub](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/AI/FORMATION)
-- * **Guides:** None
--
-- ===
--
-- ### Author: **FlightControl**
-- ### Contributions: **Applevangelist** (refactor)
--
-- ===
--
-- @module Functional.FORMATION
-- @image AI_Large_Formations.JPG

--- FORMATION class
-- @type FORMATION
-- @extends Core.Fsm#FSM_SET
-- @field Wrapper.Unit#UNIT FollowUnit
-- @field Core.Set#SET_GROUP FollowGroupSet
-- @field #string FollowName
-- @field Core.Scheduler#SCHEDULER FollowScheduler The instance of the SCHEDULER class.
-- @field #number FollowDistance The current follow distance.
-- @field DCS#AI.Option.Air.val.ROE OptionROE Which ROE is set to the FollowGroup.
-- @field DCS#AI.Option.Air.val.REACTION_ON_THREAT OptionReactionOnThreat Which REACTION_ON_THREAT is set to the FollowGroup.
-- @field #number dtFollow Time step between position updates.


--- Build (large) formations, make AI follow a @{Wrapper.Client#CLIENT} (player) leader or a @{Wrapper.Unit#UNIT} (AI) leader.
--
-- FORMATION makes AI @{Wrapper.Group#GROUP}s fly in formation of various compositions.
-- The FORMATION class models formations in a different manner than the internal DCS formation logic!!!
-- The purpose of the class is to:
--
--   * Make formation building a process that can be managed while in flight, rather than a task.
--   * Human players can guide formations, consisting of larget planes.
--   * Build large formations (like a large bomber field).
--   * Form formations that DCS does not support off-the-shelve.
--
-- A few remarks:
--
--   * Depending on the type of plane, the change in direction by the leader may result in the formation getting disentangled while in flight and needs to be rebuild.
--   * Formations are vulnerable to collissions, but is depending on the type of plane, the distance between the planes and the speed and angle executed by the leader.
--   * Formations may take a while to build up.
--
-- As a result, the FORMATION is not perfect, but is very useful to:
--
--   * Model large formations when flying straight line. You can build close formations when doing this.
--   * Make humans guide a large formation, when the planes are wide from each other.
--
-- ## FORMATION construction
--
-- Create a new SPAWN object with the @{#FORMATION.New} method:
--
--   * @{#FORMATION.New}(): Creates a new FORMATION object from a @{Wrapper.Group#GROUP} for a @{Wrapper.Client#CLIENT} or a @{Wrapper.Unit#UNIT}, with an optional briefing text.
--
-- ## Formation methods
--
-- The following methods can be used to set or change the formation:
--
--  * @{#FORMATION.FormationLine}(): Form a line formation (core formation function).
--  * @{#FORMATION.FormationTrail}(): Form a trail formation.
--  * @{#FORMATION.FormationLeftLine}(): Form a left line formation.
--  * @{#FORMATION.FormationRightLine}(): Form a right line formation.
--  * @{#FORMATION.FormationRightWing}(): Form a right wing formation.
--  * @{#FORMATION.FormationLeftWing}(): Form a left wing formation.
--  * @{#FORMATION.FormationCenterWing}(): Form a center wing formation.
--  * @{#FORMATION.FormationCenterVic}(): Form a Vic formation (same as CenterWing).
--  * @{#FORMATION.FormationCenterBoxed}(): Form a center boxed formation.
--
-- ## Randomization
--
-- Use the method @{FORMATION#FORMATION.SetFlightRandomization}() to simulate the formation flying errors that pilots make while in formation. Is a range set in meters.
--
-- @usage
-- local FollowGroupSet = SET_GROUP:New():FilterCategories("plane"):FilterCoalitions("blue"):FilterPrefixes("Follow"):FilterStart()
-- local LeaderUnit = UNIT:FindByName( "Leader" )
-- local LargeFormation = FORMATION:New( LeaderUnit, FollowGroupSet, "Center Wing Formation", "Briefing" )
-- LargeFormation:FormationCenterWing( 500, 50, 0, 250, 250 )
-- LargeFormation:__Start( 1 )
--
-- @field #FORMATION
FORMATION = {
  ClassName = "FORMATION",
  FollowName = nil, -- The Follow Name
  FollowUnit = nil,
  FollowGroupSet = nil,
  FollowScheduler = nil,
  OptionROE = AI.Option.Air.val.ROE.OPEN_FIRE,
  OptionReactionOnThreat = AI.Option.Air.val.REACTION_ON_THREAT.ALLOW_ABORT_MISSION,
  dtFollow = 0.5,
}

--- @type FORMATION.Formation
-- @field #number None
-- @field #number Line
-- @field #number Trail
-- @field #number Stack
-- @field #number LeftLine
-- @field #number RightLine
-- @field #number LeftWing
-- @field #number RightWing
-- @field #number Vic
-- @field #number Box
FORMATION.Formation = {
  None = 1,
  Line = 2,
  Trail = 3,
  Stack = 4,
  LeftLine = 5,
  RightLine = 6,
  LeftWing = 7,
  RightWing = 8,
  Vic = 9,
  Box = 10,
}

--- FORMATION class constructor for an AI group
-- @param #FORMATION self
-- @param Wrapper.Unit#UNIT FollowUnit The UNIT leading the FolllowGroupSet.
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string FollowName Name of the escort.
-- @return #FORMATION self
function FORMATION:New( FollowUnit, FollowGroupSet, FollowName )
  local self = BASE:Inherit( self, FSM_SET:New( FollowGroupSet ) )
  self:F( { FollowUnit, FollowGroupSet, FollowName } )

  self.FollowUnit = FollowUnit -- Wrapper.Unit#UNIT
  self.FollowGroupSet = FollowGroupSet -- Core.Set#SET_GROUP

  self:SetFlightRandomization( 2 )

  self:SetStartState( "None" )

  self:AddTransition( "*", "Stop", "Stopped" )

  self:AddTransition( {"None", "Stopped"}, "Start", "Following" )

  self:AddTransition( "*", "FormationLine", "*" )
  
  --- Start Trigger for FORMATION
  -- @function [parent=#FORMATION] Start
  -- @param #FORMATION self

  --- Start Asynchronous Trigger for FORMATION
  -- @function [parent=#FORMATION] __Start
  -- @param #FORMATION self
  -- @param #number Delay

  --- Stop Trigger for FORMATION
  -- @function [parent=#FORMATION] Stop
  -- @param #FORMATION self

  --- Stop Asynchronous Trigger for FORMATION
  -- @function [parent=#FORMATION] __Stop
  -- @param #FORMATION self
  -- @param #number Delay

  --- FormationLine Handler OnAfter for FORMATION
  -- @function [parent=#FORMATION] OnAfterFormationLine
  -- @param #FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationLine Trigger for FORMATION
  -- @function [parent=#FORMATION] FormationLine
  -- @param #FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationLine Asynchronous Trigger for FORMATION
  -- @function [parent=#FORMATION] __FormationLine
  -- @param #FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  self:AddTransition( "*", "FormationTrail", "*" )

  --- FormationTrail Handler OnAfter for FORMATION
  -- @function [parent=#FORMATION] OnAfterFormationTrail
  -- @param #FORMATION self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.

  --- FormationTrail Trigger for FORMATION
  -- @function [parent=#FORMATION] FormationTrail
  -- @param #FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.

  --- FormationTrail Asynchronous Trigger for FORMATION
  -- @function [parent=#FORMATION] __FormationTrail
  -- @param #FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.

  self:AddTransition( "*", "FormationStack", "*" )

  --- FormationStack Handler OnAfter for FORMATION
  -- @function [parent=#FORMATION] OnAfterFormationStack
  -- @param #FORMATION self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.

  --- FormationStack Trigger for FORMATION
  -- @function [parent=#FORMATION] FormationStack
  -- @param #FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.

  --- FormationStack Asynchronous Trigger for FORMATION
  -- @function [parent=#FORMATION] __FormationStack
  -- @param #FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.

  self:AddTransition( "*", "FormationLeftLine", "*" )

  --- FormationLeftLine Handler OnAfter for FORMATION
  -- @function [parent=#FORMATION] OnAfterFormationLeftLine
  -- @param #FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationLeftLine Trigger for FORMATION
  -- @function [parent=#FORMATION] FormationLeftLine
  -- @param #FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationLeftLine Asynchronous Trigger for FORMATION
  -- @function [parent=#FORMATION] __FormationLeftLine
  -- @param #FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  self:AddTransition( "*", "FormationRightLine", "*" )

  --- FormationRightLine Handler OnAfter for FORMATION
  -- @function [parent=#FORMATION] OnAfterFormationRightLine
  -- @param #FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationRightLine Trigger for FORMATION
  -- @function [parent=#FORMATION] FormationRightLine
  -- @param #FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationRightLine Asynchronous Trigger for FORMATION
  -- @function [parent=#FORMATION] __FormationRightLine
  -- @param #FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  self:AddTransition( "*", "FormationLeftWing", "*" )

  --- FormationLeftWing Handler OnAfter for FORMATION
  -- @function [parent=#FORMATION] OnAfterFormationLeftWing
  -- @param #FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationLeftWing Trigger for FORMATION
  -- @function [parent=#FORMATION] FormationLeftWing
  -- @param #FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationLeftWing Asynchronous Trigger for FORMATION
  -- @function [parent=#FORMATION] __FormationLeftWing
  -- @param #FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  self:AddTransition( "*", "FormationRightWing", "*" )

  --- FormationRightWing Handler OnAfter for FORMATION
  -- @function [parent=#FORMATION] OnAfterFormationRightWing
  -- @param #FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationRightWing Trigger for FORMATION
  -- @function [parent=#FORMATION] FormationRightWing
  -- @param #FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationRightWing Asynchronous Trigger for FORMATION
  -- @function [parent=#FORMATION] __FormationRightWing
  -- @param #FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  self:AddTransition( "*", "FormationCenterWing", "*" )

  --- FormationCenterWing Handler OnAfter for FORMATION
  -- @function [parent=#FORMATION] OnAfterFormationCenterWing
  -- @param #FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationCenterWing Trigger for FORMATION
  -- @function [parent=#FORMATION] FormationCenterWing
  -- @param #FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationCenterWing Asynchronous Trigger for FORMATION
  -- @function [parent=#FORMATION] __FormationCenterWing
  -- @param #FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  self:AddTransition( "*", "FormationVic", "*" )

  --- FormationVic Handler OnAfter for FORMATION
  -- @function [parent=#FORMATION] OnAfterFormationVic
  -- @param #FORMATION self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationVic Trigger for FORMATION
  -- @function [parent=#FORMATION] FormationVic
  -- @param #FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  --- FormationVic Asynchronous Trigger for FORMATION
  -- @function [parent=#FORMATION] __FormationVic
  -- @param #FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.

  self:AddTransition( "*", "FormationBox", "*" )

  --- FormationBox Handler OnAfter for FORMATION
  -- @function [parent=#FORMATION] OnAfterFormationBox
  -- @param #FORMATION self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  -- @param #number ZLevels The amount of levels on the Z-axis.

  --- FormationBox Trigger for FORMATION
  -- @function [parent=#FORMATION] FormationBox
  -- @param #FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  -- @param #number ZLevels The amount of levels on the Z-axis.

  --- FormationBox Asynchronous Trigger for FORMATION
  -- @function [parent=#FORMATION] __FormationBox
  -- @param #FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #number YStart The start position on the Y-axis in meters for the first group.
  -- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
  -- @param #number ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  -- @param #number ZLevels The amount of levels on the Z-axis.

  self:AddTransition( "*", "Follow", "Following" )

  self:FormationLeftLine( 500, 0, 250, 250 )

  self.FollowName = FollowName

  self.CT1 = 0
  self.GT1 = 0

  return self
end


--- Set time interval between updates of the formation.
-- @param #FORMATION self
-- @param #number dt Time step in seconds between formation updates. Default is every 0.5 seconds.
-- @return #FORMATION
function FORMATION:SetFollowTimeInterval(dt)
  self.dtFollow=dt or 0.5
  return self
end

--- This function is for test, it will put on the frequency of the FollowScheduler a red smoke at the direction vector calculated for the escort to fly to.
-- This allows to visualize where the escort is flying to.
-- @param #FORMATION self
-- @param #boolean SmokeDirection If true, then the direction vector will be smoked.
-- @return #FORMATION
function FORMATION:TestSmokeDirectionVector( SmokeDirection )
  self.SmokeDirectionVector = ( SmokeDirection == true ) and true or false
  return self
end

--- FormationLine Handler OnAfter for FORMATION
-- @param #FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @return #FORMATION
function FORMATION:onafterFormationLine( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, YSpace, ZStart, ZSpace, Formation )
  self:F( { FollowGroupSet, From , Event ,To, XStart, XSpace, YStart, YSpace, ZStart, ZSpace, Formation } )

  XStart = XStart or self.XStart
  XSpace = XSpace or self.XSpace
  YStart = YStart or self.YStart
  YSpace = YSpace or self.YSpace
  ZStart = ZStart or self.ZStart
  ZSpace = ZSpace or self.ZSpace

  local FollowSet = FollowGroupSet:GetSet()

  local i = 1  --FF i=0 caused first unit to have no XSpace! Probably needs further adjustments. This is just a quick work around.

  for FollowID, FollowGroup in pairs( FollowSet ) do

    local PointVec3 = COORDINATE:New()
    PointVec3:SetX( XStart + i * XSpace )
    PointVec3:SetY( YStart + i * YSpace )
    PointVec3:SetZ( ZStart + i * ZSpace )

    local Vec3 = PointVec3:GetVec3()
    FollowGroup:SetState( self, "FormationVec3", Vec3 )
    i = i + 1

    FollowGroup:SetState( FollowGroup, "Formation", Formation )
  end

  return self

end

--- FormationTrail Handler OnAfter for FORMATION
-- @param #FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @return #FORMATION
function FORMATION:onafterFormationTrail( FollowGroupSet, From , Event , To, XStart, XSpace, YStart )

  self:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,0,0,0, self.Formation.Trail )

  return self
end


--- FormationStack Handler OnAfter for FORMATION
-- @param #FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
-- @return #FORMATION
function FORMATION:onafterFormationStack( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, YSpace )

  self:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,YSpace,0,0, self.Formation.Stack )

  return self
end

--- FormationLeftLine Handler OnAfter for FORMATION
-- @param #FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @return #FORMATION
function FORMATION:onafterFormationLeftLine( FollowGroupSet, From , Event , To, XStart, YStart, ZStart, ZSpace )

  self:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,0,YStart,0,-ZStart,-ZSpace, self.Formation.LeftLine )

  return self
end

--- FormationRightLine Handler OnAfter for FORMATION
-- @param #FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @return #FORMATION
function FORMATION:onafterFormationRightLine( FollowGroupSet, From , Event , To, XStart, YStart, ZStart, ZSpace )

  self:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,0,YStart,0,ZStart,ZSpace,self.Formation.RightLine)

  return self
end

--- FormationLeftWing Handler OnAfter for FORMATION
-- @param #FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
function FORMATION:onafterFormationLeftWing( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, ZStart, ZSpace )

  self:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,0,-ZStart,-ZSpace,self.Formation.LeftWing)

  return self
end

--- FormationRightWing Handler OnAfter for FORMATION
-- @function [parent=#FORMATION] OnAfterFormationRightWing
-- @param #FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
function FORMATION:onafterFormationRightWing( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, ZStart, ZSpace )

  self:onafterFormationLine(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,0,ZStart,ZSpace,self.Formation.RightWing)

  return self
end

--- FormationCenterWing Handler OnAfter for FORMATION
-- @param #FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
function FORMATION:onafterFormationCenterWing( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, YSpace, ZStart, ZSpace )

  local FollowSet = FollowGroupSet:GetSet()

  local i = 0

  for FollowID, FollowGroup in pairs( FollowSet ) do

    local PointVec3 = COORDINATE:New()

    local Side = ( i % 2 == 0 ) and 1 or -1
    local Row = i / 2 + 1

    PointVec3:SetX( XStart + Row * XSpace )
    PointVec3:SetY( YStart )
    PointVec3:SetZ( Side * ( ZStart + i * ZSpace ) )

    local Vec3 = PointVec3:GetVec3()
    FollowGroup:SetState( self, "FormationVec3", Vec3 )
    i = i + 1
    FollowGroup:SetState( FollowGroup, "Formation", self.Formation.Vic )
  end

  return self
end

--- FormationVic Handle for FORMATION
-- @param #FORMATION self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @return #FORMATION
function FORMATION:onafterFormationVic( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, YSpace, ZStart, ZSpace )

  self:onafterFormationCenterWing(FollowGroupSet,From,Event,To,XStart,XSpace,YStart,YSpace,ZStart,ZSpace)

  return self
end

--- FormationBox Handler OnAfter for FORMATION
-- @param #FORMATION self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #number YStart The start position on the Y-axis in meters for the first group.
-- @param #number YSpace The space between groups on the Y-axis in meters for each sequent group.
-- @param #number ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
-- @param #number ZLevels The amount of levels on the Z-axis.
-- @return #FORMATION
function FORMATION:onafterFormationBox( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, YSpace, ZStart, ZSpace, ZLevels )

  local FollowSet = FollowGroupSet:GetSet()

  local i = 0

  for FollowID, FollowGroup in pairs( FollowSet ) do

    local PointVec3 = COORDINATE:New()

    local ZIndex = i % ZLevels
    local XIndex = math.floor( i / ZLevels )
    local YIndex = math.floor( i / ZLevels )

    PointVec3:SetX( XStart + XIndex * XSpace )
    PointVec3:SetY( YStart + YIndex * YSpace )
    PointVec3:SetZ( -ZStart - (ZSpace * ZLevels / 2 ) + ZSpace * ZIndex )

    local Vec3 = PointVec3:GetVec3()
    FollowGroup:SetState( self, "FormationVec3", Vec3 )
    i = i + 1
    FollowGroup:SetState( FollowGroup, "Formation", self.Formation.Box )
  end

  return self
end

--- Use the method @{FORMATION#FORMATION.SetFlightRandomization}() to make the air units in your formation randomize their flight a bit while in formation.
-- @param #FORMATION self
-- @param #number FlightRandomization The formation flying errors that pilots can make while in formation. Is a range set in meters.
-- @return #FORMATION
function FORMATION:SetFlightRandomization( FlightRandomization )
  self.FlightRandomization = FlightRandomization
  return self
end

--- Stop function. Formation will not be updated any more.
-- @param #FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The following set of groups.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To The to state.
function FORMATION:onafterStop(FollowGroupSet, From, Event, To)
  self:E("Stopping formation.")
end

--- Follow event fuction. Check if coming from state "stopped". If so the transition is rejected.
-- @param #FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The following set of groups.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To The to state.
function FORMATION:onbeforeFollow( FollowGroupSet, From, Event, To )
  if From=="Stopped" then
    return false  -- Deny transition.
  end
  return true
end

--- Enter following state.
-- @param #FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The following set of groups.
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To The to state.
function FORMATION:onenterFollowing( FollowGroupSet )

  if self.FollowUnit:IsAlive() then

    local ClientUnit = self.FollowUnit

    local CT1, CT2, CV1, CV2
    CT1 = ClientUnit:GetState( self, "CT1" )

    local CuVec3=ClientUnit:GetVec3()

    if CT1 == nil or CT1 == 0 then
      ClientUnit:SetState( self, "CV1",  CuVec3)
      ClientUnit:SetState( self, "CT1", timer.getTime() )
    else
      CT1 = ClientUnit:GetState( self, "CT1" )
      CT2 = timer.getTime()
      CV1 = ClientUnit:GetState( self, "CV1" )
      CV2 = CuVec3

      ClientUnit:SetState( self, "CT1", CT2 )
      ClientUnit:SetState( self, "CV1", CV2 )
    end

    --FollowGroupSet:ForEachGroupAlive( bla, self, ClientUnit, CT1, CV1, CT2, CV2)

    for _,_group in pairs(FollowGroupSet:GetSet()) do
      local group=_group --Wrapper.Group#GROUP
      if group and group:IsAlive() then
        self:FollowMe(group, ClientUnit, CT1, CV1, CT2, CV2)
      end
    end

    self:__Follow( -self.dtFollow )
  end

end

--- Follow me.
-- @param #FORMATION self
-- @param Wrapper.Group#GROUP FollowGroup Follow group.
-- @param Wrapper.Unit#UNIT ClientUnit Client Unit.
-- @param DCS#Time CT1 Time
-- @param DCS#Vec3 CV1 Vec3
-- @param DCS#Time CT2 Time
-- @param DCS#Vec3 CV2 Vec3
function FORMATION:FollowMe(FollowGroup, ClientUnit, CT1, CV1, CT2, CV2)

  if not self:Is("Stopped") then

    self:T({Mode=FollowGroup:GetState( FollowGroup, "Mode" )})

    FollowGroup:OptionROTEvadeFire()
    FollowGroup:OptionROEReturnFire()

    local GroupUnit = FollowGroup:GetUnit( 1 )

    local GuVec3=GroupUnit:GetVec3()

    local FollowFormation = FollowGroup:GetState( self, "FormationVec3" )

    if FollowFormation then
      local FollowDistance = FollowFormation.x

      local GT1 = GroupUnit:GetState( self, "GT1" )

      if CT1 == nil or CT1 == 0 or GT1 == nil or GT1 == 0 then
        GroupUnit:SetState( self, "GV1", GuVec3)
        GroupUnit:SetState( self, "GT1", timer.getTime() )
      else
        local CD = ( ( CV2.x - CV1.x )^2 + ( CV2.y - CV1.y )^2 + ( CV2.z - CV1.z )^2 ) ^ 0.5
        local CT = CT2 - CT1

        local CS = ( 3600 / CT ) * ( CD / 1000 ) / 3.6

        local CDv = { x = CV2.x - CV1.x, y = CV2.y - CV1.y, z = CV2.z - CV1.z }
        local Ca = math.atan2( CDv.x, CDv.z )

        local GT1 = GroupUnit:GetState( self, "GT1" )
        local GT2 = timer.getTime()

        local GV1 = GroupUnit:GetState( self, "GV1" )
        local GV2 = GuVec3

        GV2.x=GV2.x+math.random( -self.FlightRandomization / 2, self.FlightRandomization / 2 )
        GV2.y=GV2.y+math.random( -self.FlightRandomization / 2, self.FlightRandomization / 2 )
        GV2.z=GV2.z+math.random( -self.FlightRandomization / 2, self.FlightRandomization / 2 )

        GroupUnit:SetState( self, "GT1", GT2 )
        GroupUnit:SetState( self, "GV1", GV2 )

        local GD = ( ( GV2.x - GV1.x )^2 + ( GV2.y - GV1.y )^2 + ( GV2.z - GV1.z )^2 ) ^ 0.5
        local GT = GT2 - GT1

        -- Calculate the distance
        local GDv =  { x = GV2.x - CV1.x, y =  GV2.y - CV1.y, z = GV2.z - CV1.z }
        local Alpha_T = math.atan2( GDv.x, GDv.z ) - math.atan2( CDv.x, CDv.z )
        local Alpha_R = ( Alpha_T < 0 ) and Alpha_T + 2 * math.pi or Alpha_T
        local Position = math.cos( Alpha_R )
        local GD = ( ( GDv.x )^2 + ( GDv.z )^2 ) ^ 0.5
        local Distance = GD * Position + - CS * 0.5

        -- Calculate the group direction vector
        local GV = { x = GV2.x - CV2.x, y = GV2.y - CV2.y, z = GV2.z - CV2.z  }

        -- Calculate GH2, GH2 with the same height as CV2.
        local GH2 = { x = GV2.x, y = CV2.y + FollowFormation.y, z = GV2.z }

        -- Calculate the angle of GV to the orthonormal plane
        local alpha = math.atan2( GV.x, GV.z )

        local GVx = FollowFormation.z * math.cos( Ca ) + FollowFormation.x * math.sin( Ca )
        local GVz = FollowFormation.x * math.cos( Ca ) - FollowFormation.z * math.sin( Ca )

        -- Now we calculate the intersecting vector between the circle around CV2 with radius FollowDistance and GH2.
        -- From the GeoGebra model: CVI = (x(CV2) + FollowDistance cos(alpha), y(GH2) + FollowDistance sin(alpha), z(CV2))
        local Inclination = ( Distance + FollowFormation.x ) / 10
        if Inclination < -30 then
          Inclination = - 30
        end

        local CVI = {
          x = CV2.x + CS * 10 * math.sin(Ca),
          y = GH2.y + Inclination, -- + FollowFormation.y,
          z = CV2.z + CS * 10 * math.cos(Ca),
        }

        -- Calculate the direction vector DV of the escort group. We use CVI as the base and CV2 as the direction.
        local DV = { x = CV2.x - CVI.x, y = CV2.y - CVI.y, z = CV2.z - CVI.z }

        -- We now calculate the unary direction vector DVu, so that we can multiply DVu with the speed, which is expressed in meters / s.
        -- We need to calculate this vector to predict the point the escort group needs to fly to according its speed.
        -- The distance of the destination point should be far enough not to have the aircraft starting to swipe left to right...
        local DVu = { x = DV.x / FollowDistance, y = DV.y, z = DV.z / FollowDistance }

        -- Now we can calculate the group destination vector GDV.
        local GDV = { x = CVI.x, y = CVI.y, z = CVI.z }

        local ADDx = FollowFormation.x * math.cos(alpha) - FollowFormation.z * math.sin(alpha)
        local ADDz = FollowFormation.z * math.cos(alpha) + FollowFormation.x * math.sin(alpha)

        local GDV_Formation = {
          x = GDV.x - GVx,
          y = GDV.y,
          z = GDV.z - GVz
        }

        -- Debug smoke.
        if self.SmokeDirectionVector == true then
          trigger.action.smoke( GDV, trigger.smokeColor.Green )
          trigger.action.smoke( GDV_Formation, trigger.smokeColor.White )
        end

        local Time = 120

        local Speed = - ( Distance + FollowFormation.x ) / Time

        if Distance > -10000 then
          Speed = - ( Distance + FollowFormation.x ) / 60
        end

        if Distance > -2500 then
          Speed = - ( Distance + FollowFormation.x ) / 20
        end

        local GS = Speed + CS

        --self:F( { Distance = Distance, Speed = Speed, CS = CS, GS = GS } )

        -- Now route the escort to the desired point with the desired speed.
        FollowGroup:RouteToVec3( GDV_Formation, GS ) -- DCS models speed in Mps (Miles per second)

      end
    end
  end
end
