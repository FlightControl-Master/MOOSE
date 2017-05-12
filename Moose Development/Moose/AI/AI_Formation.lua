--- **AI** -- (R2.1) Build large **formations** of AI @{Group}s flying together.
-- 
-- ![Banner Image](..\Presentations\AI_FORMATION\Dia1.JPG)
-- 
-- ===
-- 
-- AI_FORMATION makes AI @{GROUP}s fly in formation of various compositions.
-- 
-- There are the following types of classes defined:
-- 
--   * @{#AI_FORMATION}: Create a formation from several @{GROUP}s.
--   
-- ====
-- 
-- # Demo Missions
-- 
-- ### [AI_FORMATION Demo Missions source code]()
-- 
-- ### [AI_FORMATION Demo Missions, only for beta testers]()
--
-- ### [ALL Demo Missions pack of the last release]()
-- 
-- ====
-- 
-- # YouTube Channel
-- 
--- ### [AI_FORMATION YouTube Channel]()
-- 
-- ===
-- 
-- # **AUTHORS and CONTRIBUTIONS**
--
-- ### Contributions:
--
-- ### Authors:
--
--   * **FlightControl**: Concept, Design & Programming.
--   
-- @module AI_Formation

--- AI_FORMATION class
-- @type AI_FORMATION
-- @extends Fsm#FSM_SET
-- @field Unit#UNIT FollowUnit
-- @field Set#SET_GROUP FollowGroupSet
-- @field #string FollowName
-- @field #AI_FORMATION.MODE FollowMode The mode the escort is in.
-- @field Scheduler#SCHEDULER FollowScheduler The instance of the SCHEDULER class.
-- @field #number FollowDistance The current follow distance.
-- @field #boolean ReportTargets If true, nearby targets are reported.
-- @Field DCSTypes#AI.Option.Air.val.ROE OptionROE Which ROE is set to the FollowGroup.
-- @field DCSTypes#AI.Option.Air.val.REACTION_ON_THREAT OptionReactionOnThreat Which REACTION_ON_THREAT is set to the FollowGroup.
-- @field Menu#MENU_CLIENT FollowMenuResumeMission


--- # AI_FORMATION class, extends @{Fsm#FSM_SET}
-- 
-- The #AI_FORMATION class allows you to build large formations, make AI follow a @{Client#CLIENT} (player) leader or a @{Unit#UNIT} (AI) leader.
--
-- ## AI_FORMATION construction
-- 
-- Create a new SPAWN object with the @{#AI_FORMATION.New} method:
--
--   * @{Follow#AI_FORMATION.New}(): Creates a new AI_FORMATION object from a @{Group#GROUP} for a @{Client#CLIENT} or a @{Unit#UNIT}, with an optional briefing text.
--
-- ## Initialization methods
-- 
-- The following menus are created within the RADIO MENU of an active unit hosted by a player:
-- 
--  * @{AI_Formation#AI_FORMATION.FormationRandom}(): Form a randomized formation (can cause crashed of planes :-)).
--  * @{AI_Formation#AI_FORMATION.FormationLeftLine}(): Form a left line formation.
--  * @{AI_Formation#AI_FORMATION.FormationRightLine}(): Form a right line formation.
--  * @{AI_Formation#AI_FORMATION.FormationRightWing}(): Form a right wing formation.
--  * @{AI_Formation#AI_FORMATION.FormationLeftWing}(): Form a left wing formation.
--  * @{AI_Formation#AI_FORMATION.FormationCenterLine}(): Form a center line formation.
--  * @{AI_Formation#AI_FORMATION.FormationCenterBoxed}(): Form a center boxed formation.
--  
--
-- @usage
-- local FollowGroupSet = SET_GROUP:New():FilterCategories("plane"):FilterCoalitions("blue"):FilterPrefixes("Follow"):FilterStart()
-- FollowGroupSet:Flush()
-- local LeaderUnit = UNIT:FindByName( "Leader" )
-- local LargeFormation = AI_FORMATION:New( LeaderUnit, FollowGroupSet, "Center Wing Formation", "Briefing" )
-- LargeFormation:FormationCenterWing( 500, 50, 0, 250, 250 )
-- LargeFormation:__Start( 1 )
-- 
-- @field #AI_FORMATION 
AI_FORMATION = {
  ClassName = "AI_FORMATION",
  FollowName = nil, -- The Follow Name
  FollowUnit = nil,
  FollowGroupSet = nil,
  FollowMode = 1,
  MODE = {
    FOLLOW = 1,
    MISSION = 2,
  },
  FollowScheduler = nil,
  OptionROE = AI.Option.Air.val.ROE.OPEN_FIRE,
  OptionReactionOnThreat = AI.Option.Air.val.REACTION_ON_THREAT.ALLOW_ABORT_MISSION,
}

--- AI_FORMATION.Mode class
-- @type AI_FORMATION.MODE
-- @field #number FOLLOW
-- @field #number MISSION

--- MENUPARAM type
-- @type MENUPARAM
-- @field #AI_FORMATION ParamSelf
-- @field #Distance ParamDistance
-- @field #function ParamFunction
-- @field #string ParamMessage

--- AI_FORMATION class constructor for an AI group
-- @param #AI_FORMATION self
-- @param Unit#UNIT FollowUnit The UNIT leading the FolllowGroupSet.
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string FollowName Name of the escort.
-- @return #AI_FORMATION self
function AI_FORMATION:New( FollowUnit, FollowGroupSet, FollowName, FollowBriefing )
  local self = BASE:Inherit( self, FSM_SET:New( FollowGroupSet ) )
  self:F( { FollowUnit, FollowGroupSet, FollowName } )

  self.FollowUnit = FollowUnit -- Unit#UNIT
  self.FollowGroupSet = FollowGroupSet -- Set#SET_GROUP
  
  self:SetStartState( "None" ) 

  self:AddTransition( "*", "Stop", "Stopped" )

  self:AddTransition( "None", "Start", "Following" )
  
  self:AddTransition( "*", "FormationLeftLine", "*" )
  
  --- FormationLeftLine Handler OnBefore for AI_FORMATION
  -- @function [parent=#AI_FORMATION] OnBeforeFormationLeftLine
  -- @param #AI_FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  -- @return #boolean
  
  --- FormationLeftLine Handler OnAfter for AI_FORMATION
  -- @function [parent=#AI_FORMATION] OnAfterFormationLeftLine
  -- @param #AI_FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  --- FormationLeftLine Trigger for AI_FORMATION
  -- @function [parent=#AI_FORMATION] FormationLeftLine
  -- @param #AI_FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  --- FormationLeftLine Asynchronous Trigger for AI_FORMATION
  -- @function [parent=#AI_FORMATION] __FormationLeftLine
  -- @param #AI_FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  
  self:AddTransition( "*", "FormationRightLine", "*" )
  
  --- FormationRightLine Handler OnBefore for AI_FORMATION
  -- @function [parent=#AI_FORMATION] OnBeforeFormationRightLine
  -- @param #AI_FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  -- @return #boolean
  
  --- FormationRightLine Handler OnAfter for AI_FORMATION
  -- @function [parent=#AI_FORMATION] OnAfterFormationRightLine
  -- @param #AI_FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  --- FormationRightLine Trigger for AI_FORMATION
  -- @function [parent=#AI_FORMATION] FormationRightLine
  -- @param #AI_FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  --- FormationRightLine Asynchronous Trigger for AI_FORMATION
  -- @function [parent=#AI_FORMATION] __FormationRightLine
  -- @param #AI_FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  self:AddTransition( "*", "FormationLeftWing", "*" )
  
  --- FormationLeftWing Handler OnBefore for AI_FORMATION
  -- @function [parent=#AI_FORMATION] OnBeforeFormationLeftWing
  -- @param #AI_FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  -- @return #boolean
  
  --- FormationLeftWing Handler OnAfter for AI_FORMATION
  -- @function [parent=#AI_FORMATION] OnAfterFormationLeftWing
  -- @param #AI_FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  --- FormationLeftWing Trigger for AI_FORMATION
  -- @function [parent=#AI_FORMATION] FormationLeftWing
  -- @param #AI_FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  --- FormationLeftWing Asynchronous Trigger for AI_FORMATION
  -- @function [parent=#AI_FORMATION] __FormationLeftWing
  -- @param #AI_FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  
  self:AddTransition( "*", "FormationRightWing", "*" )
  
  --- FormationRightWing Handler OnBefore for AI_FORMATION
  -- @function [parent=#AI_FORMATION] OnBeforeFormationRightWing
  -- @param #AI_FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  -- @return #boolean
  
  --- FormationRightWing Handler OnAfter for AI_FORMATION
  -- @function [parent=#AI_FORMATION] OnAfterFormationRightWing
  -- @param #AI_FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  --- FormationRightWing Trigger for AI_FORMATION
  -- @function [parent=#AI_FORMATION] FormationRightWing
  -- @param #AI_FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  --- FormationRightWing Asynchronous Trigger for AI_FORMATION
  -- @function [parent=#AI_FORMATION] __FormationRightWing
  -- @param #AI_FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
    self:AddTransition( "*", "FormationCenterWing", "*" )
  
  --- FormationCenterWing Handler OnBefore for AI_FORMATION
  -- @function [parent=#AI_FORMATION] OnBeforeFormationCenterWing
  -- @param #AI_FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  -- @return #boolean
  
  --- FormationCenterWing Handler OnAfter for AI_FORMATION
  -- @function [parent=#AI_FORMATION] OnAfterFormationCenterWing
  -- @param #AI_FORMATION self
  -- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  --- FormationCenterWing Trigger for AI_FORMATION
  -- @function [parent=#AI_FORMATION] FormationCenterWing
  -- @param #AI_FORMATION self
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  --- FormationCenterWing Asynchronous Trigger for AI_FORMATION
  -- @function [parent=#AI_FORMATION] __FormationCenterWing
  -- @param #AI_FORMATION self
  -- @param #number Delay
  -- @param #number XStart The start position on the X-axis in meters for the first group.
  -- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
  -- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
  -- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
  -- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
  
  
  
  
  self:AddTransition( "*", "Follow", "Following" )

  self:FormationLeftLine( 500, 0, 250, 250 )
  
  self.FollowName = FollowName
  self.FollowBriefing = FollowBriefing


  self.CT1 = 0
  self.GT1 = 0

  self.FollowMode = AI_FORMATION.MODE.MISSION

  return self
end

--- This function is for test, it will put on the frequency of the FollowScheduler a red smoke at the direction vector calculated for the escort to fly to.
-- This allows to visualize where the escort is flying to.
-- @param #AI_FORMATION self
-- @param #boolean SmokeDirection If true, then the direction vector will be smoked.
-- @return #AI_FORMATION
function AI_FORMATION:TestSmokeDirectionVector( SmokeDirection )
  self.SmokeDirectionVector = ( SmokeDirection == true ) and true or false
  return self
end

--- FormationLeftLine Handler OnAfter for AI_FORMATION
-- @function [parent=#AI_FORMATION] OnAfterFormationLeftLine
-- @param #AI_FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
-- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
function AI_FORMATION:onafterFormationLeftLine( FollowGroupSet, From , Event , To, XStart, YStart, ZStart, ZSpace )
  self:F( { FollowGroupSet, From , Event ,To, XStart, YStart, ZStart, ZSpace } )

  FollowGroupSet:Flush()
  
  local FollowSet = FollowGroupSet:GetSet()
  
  local i = 0
  
  for FollowID, FollowGroup in pairs( FollowSet ) do
  
    local PointVec3 = POINT_VEC3:New()
    PointVec3:SetX( XStart )
    PointVec3:SetY( YStart )
    PointVec3:SetZ( ZStart + i * ZSpace )
  
    local Vec3 = PointVec3:GetVec3()
    FollowGroup:SetState( self, "Vec3", Vec3 )
    FollowGroup:OptionROTPassiveDefense()
    FollowGroup:OptionROEReturnFire()
    i = i + 1
  end

end


--- FormationRightLine Handler OnAfter for AI_FORMATION
-- @function [parent=#AI_FORMATION] OnAfterFormationRightLine
-- @param #AI_FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
-- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
function AI_FORMATION:onafterFormationRightLine( FollowGroupSet, From , Event , To, XStart, YStart, ZStart, ZSpace )
  self:F( { FollowGroupSet, From , Event , To, XStart, YStart, ZStart, ZSpace } )

  local FollowSet = FollowGroupSet:GetSet()
  
  local i = 0
  
  for FollowID, FollowGroup in pairs( FollowSet ) do
  
    local PointVec3 = POINT_VEC3:New()
    PointVec3:SetX( XStart )
    PointVec3:SetY( YStart )
    PointVec3:SetZ( -(ZStart + i * ZSpace) )
  
    local Vec3 = PointVec3:GetVec3()
    FollowGroup:SetState( self, "Vec3", Vec3 )
    FollowGroup:OptionROTPassiveDefense()
    FollowGroup:OptionROEReturnFire()
    i = i + 1
  end

end


--- FormationLeftWing Handler OnAfter for AI_FORMATION
-- @function [parent=#AI_FORMATION] OnAfterFormationLeftWing
-- @param #AI_FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
-- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
function AI_FORMATION:onafterFormationLeftWing( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, ZStart, ZSpace )

  local FollowSet = FollowGroupSet:GetSet()
  
  local i = 0
  
  for FollowID, FollowGroup in pairs( FollowSet ) do
  
    local PointVec3 = POINT_VEC3:New()
    PointVec3:SetX( XStart + i * XSpace )
    PointVec3:SetY( YStart )
    PointVec3:SetZ( ZStart + i * ZSpace )
  
    local Vec3 = PointVec3:GetVec3()
    FollowGroup:SetState( self, "Vec3", Vec3 )
    FollowGroup:OptionROTPassiveDefense()
    FollowGroup:OptionROEReturnFire()
    i = i + 1
  end

end


--- FormationRightWing Handler OnAfter for AI_FORMATION
-- @function [parent=#AI_FORMATION] OnAfterFormationRightWing
-- @param #AI_FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
-- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
function AI_FORMATION:onafterFormationRightWing( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, ZStart, ZSpace )

  local FollowSet = FollowGroupSet:GetSet()
  
  local i = 0
  
  for FollowID, FollowGroup in pairs( FollowSet ) do
  
    local PointVec3 = POINT_VEC3:New()
    PointVec3:SetX( XStart + i * XSpace )
    PointVec3:SetY( YStart )
    PointVec3:SetZ( -(ZStart + i * ZSpace) )
  
    local Vec3 = PointVec3:GetVec3()
    FollowGroup:SetState( self, "Vec3", Vec3 )
    FollowGroup:OptionROTPassiveDefense()
    FollowGroup:OptionROEReturnFire()
    i = i + 1
  end

end


--- FormationCenterWing Handler OnAfter for AI_FORMATION
-- @function [parent=#AI_FORMATION] OnAfterFormationCenterWing
-- @param #AI_FORMATION self
-- @param Core.Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param #number XStart The start position on the X-axis in meters for the first group.
-- @param #number XSpace The space between groups on the X-axis in meters for each sequent group.
-- @param #nubmer YStart The start position on the Y-axis in meters for the first group.
-- @param #nubmer ZStart The start position on the Z-axis in meters for the first group.
-- @param #number ZSpace The space between groups on the Z-axis in meters for each sequent group.
function AI_FORMATION:onafterFormationCenterWing( FollowGroupSet, From , Event , To, XStart, XSpace, YStart, ZStart, ZSpace )

  local FollowSet = FollowGroupSet:GetSet()
  
  local i = 0
  
  for FollowID, FollowGroup in pairs( FollowSet ) do
  
    local PointVec3 = POINT_VEC3:New()
    
    local Side = ( i % 2 == 0 ) and 1 or -1
    local Row = i / 2 + 1
    
    PointVec3:SetX( XStart + Row * XSpace )
    PointVec3:SetY( YStart )
    PointVec3:SetZ( Side * ( ZStart + i * ZSpace ) )
  
    local Vec3 = PointVec3:GetVec3()
    FollowGroup:SetState( self, "Vec3", Vec3 )
    FollowGroup:OptionROTPassiveDefense()
    FollowGroup:OptionROEReturnFire()
    i = i + 1
  end

end



--- @param Follow#AI_FORMATION self
function AI_FORMATION:onenterFollowing( FollowGroupSet )
  self:F( )

  self:T( { self.FollowUnit.UnitName, self.FollowUnit:IsAlive() } )
  if self.FollowUnit:IsAlive() then

    local ClientUnit = self.FollowUnit

    self:T( {ClientUnit.UnitName } )

    local CT1, CT2, CV1, CV2
    CT1 = ClientUnit:GetState( self, "CT1" )

    if CT1 == nil or CT1 == 0 then
      ClientUnit:SetState( self, "CV1", ClientUnit:GetPointVec3() )
      ClientUnit:SetState( self, "CT1", timer.getTime() )
    else
      CT1 = ClientUnit:GetState( self, "CT1" )
      CT2 = timer.getTime()
      CV1 = ClientUnit:GetState( self, "CV1" )
      CV2 = ClientUnit:GetPointVec3()
      
      ClientUnit:SetState( self, "CT1", CT2 )
      ClientUnit:SetState( self, "CV1", CV2 )
    end
        
    FollowGroupSet:ForEachGroup(
      --- @param Wrapper.Group#GROUP FollowGroup
      -- @param Wrapper.Unit#UNIT ClientUnit
      function( FollowGroup, ClientUnit, CT1, CV1, CT2, CV2 )
        
        local GroupUnit = FollowGroup:GetUnit( 1 )
        local FollowFormation = FollowGroup:GetState( self, "Vec3" )
        if FollowFormation then
          local FollowDistance = FollowFormation.x
          
          local GT1 = GroupUnit:GetState( self, "GT1" )
      
          if CT1 == nil or CT1 == 0 or GT1 == nil or GT1 == 0 then
            GroupUnit:SetState( self, "GV1", GroupUnit:GetPointVec3() )
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
            local GV2 = GroupUnit:GetPointVec3()
            GroupUnit:SetState( self, "GT1", GT2 )
            GroupUnit:SetState( self, "GV1", GV2 )
      
            local GD = ( ( GV2.x - GV1.x )^2 + ( GV2.y - GV1.y )^2 + ( GV2.z - GV1.z )^2 ) ^ 0.5
            local GT = GT2 - GT1
      
      
            -- Calculate the group direction vector
            local GV = { x = GV2.x - CV2.x, y = GV2.y - CV2.y, z = GV2.z - CV2.z  }
      
            -- Calculate GH2, GH2 with the same height as CV2.
            local GH2 = { x = GV2.x, y = CV2.y, z = GV2.z }
      
            -- Calculate the angle of GV to the orthonormal plane
            local alpha = math.atan2( GV.x, GV.z )
      
            local GVx = FollowFormation.z * math.cos( Ca ) + FollowFormation.x * math.sin( Ca )
            local GVz = FollowFormation.x * math.cos( Ca ) - FollowFormation.z * math.sin( Ca )

            -- Now we calculate the intersecting vector between the circle around CV2 with radius FollowDistance and GH2.
            -- From the GeoGebra model: CVI = (x(CV2) + FollowDistance cos(alpha), y(GH2) + FollowDistance sin(alpha), z(CV2))
            local CVI = { x = CV2.x + CS * 10 * math.sin(Ca),
              y = GH2.y, -- + FollowFormation.y,
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
            
            if self.SmokeDirectionVector == true then
              trigger.action.smoke( GDV, trigger.smokeColor.Green )
              trigger.action.smoke( GDV_Formation, trigger.smokeColor.White )
            end
            
            
            -- Calculate the distance

            local GDv =  { x = GV2.x - CV1.x, y =  GV2.y - CV1.y, z = GV2.z - CV1.z }
            
            local Alpha_T = math.atan2( GDv.x, GDv.z ) - math.atan2( CDv.x, CDv.z ) 
            local Alpha_R = ( Alpha_T < 0 ) and Alpha_T + 2 * math.pi or Alpha_T
            local Position = math.cos( Alpha_R )
            local GD = ( ( GDv.x )^2 + ( GDv.z )^2 ) ^ 0.5
            local Distance = GD * Position + FollowDistance - CS * 2
            
            
            
            local Time = 40
            local Speed = - Distance / Time
            local GS = Speed + CS
            if Speed < 0 then
              Speed = 0
            end

            -- Now route the escort to the desired point with the desired speed.
            FollowGroup:RouteToVec3( GDV_Formation, GS ) -- DCS models speed in Mps (Miles per second)
          end
        end
      end,
      ClientUnit, CT1, CV1, CT2, CV2
    )

    self:__Follow( -2 )
  end
  
end

