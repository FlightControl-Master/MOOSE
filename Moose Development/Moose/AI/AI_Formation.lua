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
-- @module AI_Follow

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
--  * @{Follow#AI_FORMATION.SetFormation}(): Set a Vec3 position for a GroupName within the GroupSet following.
--
-- @usage
-- -- Declare a new FollowPlanes object as follows:
-- 
-- -- First find the GROUP object and the CLIENT object.
-- local FollowUnit = CLIENT:FindByName( "Unit Name" ) -- The Unit Name is the name of the unit flagged with the skill Client in the mission editor.
-- local FollowGroup = GROUP:FindByName( "Group Name" ) -- The Group Name is the name of the group that will escort the Follow Client.
-- 
-- -- Now use these 2 objects to construct the new FollowPlanes object.
-- FollowPlanes = AI_FORMATION:New( FollowUnit, FollowGroup, "Desert", "Welcome to the mission. You are escorted by a plane with code name 'Desert', which can be instructed through the F10 radio menu." )
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
-- @param Set#SET_GROUP FollowGroupSet The group AI escorting the FollowUnit.
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
  
  self:AddTransition( "*", "Follow", "Following" )
  
  FollowGroupSet:ForEachGroup(
    --- @param Group#GROUP FollowGroup
    function( FollowGroup, FollowName, FollowUnit )
      local Vec3 = { x = math.random( -20, -150 ), y = math.random( -50, 50 ), z = math.random( -800, 800 ) }
      FollowGroup:SetState( self, "Vec3", Vec3 )
      FollowGroup:OptionROTPassiveDefense()
      FollowGroup:OptionROEReturnFire()
      --FollowGroup:MessageToClient( FollowGroup:GetCategoryName() .. " '" .. FollowName .. "' (" .. FollowGroup:GetCallsign() .. ") reporting! " ..
      --  "We're following your flight. ",
      --  60, FollowUnit
      --)
    end,
    FollowName, self.FollowUnit
  )

  
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
function AI_FORMATION:TestSmokeDirectionVector( SmokeDirection )
  self.SmokeDirectionVector = ( SmokeDirection == true ) and true or false
  return self
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
      --- @param Group#GROUP FollowGroup
      -- @param Unit#UNIT ClientUnit
      function( FollowGroup, ClientUnit, CT1, CV1, CT2, CV2 )
        
        local GroupUnit = FollowGroup:GetUnit( 1 )
        local FollowFormation = FollowGroup:GetState( self, "Vec3" )
        self:T( FollowFormation )
        local FollowDistance = FollowFormation.x
        
        self:T( {ClientUnit.UnitName, GroupUnit.UnitName } )

        local GT1 = GroupUnit:GetState( self, "GT1" )
    
        if CT1 == nil or CT1 == 0 or GT1 == nil or GT1 == 0 then
          GroupUnit:SetState( self, "GV1", GroupUnit:GetPointVec3() )
          GroupUnit:SetState( self, "GT1", timer.getTime() ) 
        else
          local CD = ( ( CV2.x - CV1.x )^2 + ( CV2.y - CV1.y )^2 + ( CV2.z - CV1.z )^2 ) ^ 0.5
          local CT = CT2 - CT1
    
          local CS = ( 3600 / CT ) * ( CD / 1000 )
    
          self:T2( { "Client:", CS, CD, CT, CV2, CV1, CT2, CT1 } )
    
          local GT1 = GroupUnit:GetState( self, "GT1" )
          local GT2 = timer.getTime()
          local GV1 = GroupUnit:GetState( self, "GV1" )
          local GV2 = GroupUnit:GetPointVec3()
          GroupUnit:SetState( self, "GT1", GT2 )
          GroupUnit:SetState( self, "GV1", GV2 )
    
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
            y = GH2.y + FollowFormation.y,
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
          
          local GDV_Formation = { 
            x = GDV.x + ( FollowFormation.x * math.cos(alpha) - FollowFormation.z * math.sin(alpha) ), 
            y = GDV.y, 
            z = GDV.z + ( FollowFormation.z * math.cos(alpha) + FollowFormation.x * math.sin(alpha) )
          }
          
          if self.SmokeDirectionVector == true then
            trigger.action.smoke( GDV, trigger.smokeColor.Green )
            trigger.action.smoke( GDV_Formation, trigger.smokeColor.White )
          end
          
          self:T3( { "CV2:", CV2 } )
          self:T3( { "CVI:", CVI } )
          self:T2( { "GDV:", GDV } )
    
          -- Measure distance between client and group
          local CatchUpDistance = ( ( GDV_Formation.x - GV2.x )^2 + ( GDV_Formation.y - GV2.y )^2 + ( GDV_Formation.z - GV2.z )^2 ) ^ 0.5
    
          -- The calculation of the Speed would simulate that the group would take 30 seconds to overcome
          -- the requested Distance).
          local Time = 20
          local CatchUpSpeed = ( CatchUpDistance - ( CS * 9.5 ) ) / Time
    
          local Speed = CS + CatchUpSpeed
          if Speed < 0 then
            Speed = 0
          end
          
          self:T({CatchUpDistance, CatchUpSpeed})
    
          self:T3( { "Client Speed, Follow Speed, Speed, FollowDistance, Time:", CS, GS, Speed, FollowDistance, Time } )
    
          -- Now route the escort to the desired point with the desired speed.
          FollowGroup:RouteToVec3( GDV_Formation, Speed / 3.6 ) -- DCS models speed in Mps (Miles per second)
        end
      end,
      ClientUnit, CT1, CV1, CT2, CV2
    )

    self:__Follow( -0.5 )
  end
  
end

