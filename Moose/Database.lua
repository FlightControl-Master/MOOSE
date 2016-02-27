--- Administers the Initial Sets of the Mission Templates as defined within the Mission Editor.
-- Administers the Spawning of new Groups within the DCSRTE and administers these new Groups within the DATABASE object(s).
-- @classmod DATABASE

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Menu" )

DATABASE = {
	ClassName = "DATABASE",
	Units = {},
	Groups = {},
	NavPoints = {},
	Statics = {},
	Players = {},
	ActivePlayers = {},
	ClientsByName = {},
	ClientsByID = {},
}

DATABASECoalition = 
{
	[1] = "Red",
	[2] = "Blue",
}

DATABASECategory = 
{
	[Unit.Category.AIRPLANE] = "Plane",
	[Unit.Category.HELICOPTER] = "Helicopter",
	[Unit.Category.GROUND_UNIT] = "Ground",
	[Unit.Category.SHIP] = "Ship",
	[Unit.Category.STRUCTURE] = "Structure",	
}


--- Creates a new DATABASE Object to administer the Groups defined and alive within the DCSRTE.
-- @treturn DATABASE
-- @usage
-- -- Define a new DATABASE Object. This DBObject will contain a reference to all Group and Unit Templates defined within the ME and the DCSRTE.
-- DBObject = DATABASE:New()
function DATABASE:New()
trace.f(self.ClassName )

	-- Inherits from BASE
	local self = BASE:Inherit( self, BASE:New() )
  
	self.Navpoints = {}
	self.Units = {}
	 --Build routines.db.units and self.Navpoints
	for coa_name, coa_data in pairs(env.mission.coalition) do

		if (coa_name == 'red' or coa_name == 'blue') and type(coa_data) == 'table' then
			self.Units[coa_name] = {}
			
			----------------------------------------------
			-- build nav points DB
			self.Navpoints[coa_name] = {}
			if coa_data.nav_points then --navpoints
				for nav_ind, nav_data in pairs(coa_data.nav_points) do
					
					if type(nav_data) == 'table' then
						self.Navpoints[coa_name][nav_ind] = routines.utils.deepCopy(nav_data)

						self.Navpoints[coa_name][nav_ind]['name'] = nav_data.callsignStr  -- name is a little bit more self-explanatory.
						self.Navpoints[coa_name][nav_ind]['point'] = {}  -- point is used by SSE, support it.
						self.Navpoints[coa_name][nav_ind]['point']['x'] = nav_data.x
						self.Navpoints[coa_name][nav_ind]['point']['y'] = 0
						self.Navpoints[coa_name][nav_ind]['point']['z'] = nav_data.y
					end
				end
			end
			-------------------------------------------------		
			if coa_data.country then --there is a country table
				for cntry_id, cntry_data in pairs(coa_data.country) do
					
					local countryName = string.lower(cntry_data.name)
					self.Units[coa_name][countryName] = {}
					self.Units[coa_name][countryName]["countryId"] = cntry_data.id

					if type(cntry_data) == 'table' then  --just making sure
					
						for obj_type_name, obj_type_data in pairs(cntry_data) do
						
							if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then --should be an unncessary check 
								
								local category = obj_type_name
								
								if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then  --there's a group!
								
									self.Units[coa_name][countryName][category] = {}
									
									for group_num, GroupTemplate in pairs(obj_type_data.group) do
										
										if GroupTemplate and GroupTemplate.units and type(GroupTemplate.units) == 'table' then  --making sure again- this is a valid group
											self:_RegisterGroup( GroupTemplate )
										end --if GroupTemplate and GroupTemplate.units then
									end --for group_num, GroupTemplate in pairs(obj_type_data.group) do
								end --if ((type(obj_type_data) == 'table') and obj_type_data.group and (type(obj_type_data.group) == 'table') and (#obj_type_data.group > 0)) then
							end --if obj_type_name == "helicopter" or obj_type_name == "ship" or obj_type_name == "plane" or obj_type_name == "vehicle" or obj_type_name == "static" then
						end --for obj_type_name, obj_type_data in pairs(cntry_data) do
					end --if type(cntry_data) == 'table' then
				end --for cntry_id, cntry_data in pairs(coa_data.country) do
			end --if coa_data.country then --there is a country table
		end --if coa_name == 'red' or coa_name == 'blue' and type(coa_data) == 'table' then
	end --for coa_name, coa_data in pairs(mission.coalition) do

	--self:AddEvent( world.event.S_EVENT_BIRTH, self.OnBirth )
	self:AddEvent( world.event.S_EVENT_DEAD, self.OnDeadOrCrash )
	self:AddEvent( world.event.S_EVENT_CRASH, self.OnDeadOrCrash )
	
	self:AddEvent( world.event.S_EVENT_HIT, self.OnHit)

	self:EnableEvents()

	self.SchedulerId = routines.scheduleFunction( DATABASE._FollowPlayers, { self }, 0, 5 )
	
	self:ScoreMenu()
	
	
	return self
end


--- Instantiate new Groups within the DCSRTE.
-- This method expects EXACTLY the same structure as a structure within the ME, and needs 2 additional fields defined:
-- SpawnCountryID, SpawnCategoryID
-- This method is used by the SPAWN class.
function DATABASE:Spawn( SpawnTemplate )
trace.f( self.ClassName, SpawnTemplate )

	trace.i( self.ClassName, { SpawnTemplate.SpawnCountryID, SpawnTemplate.SpawnCategoryID, SpawnTemplate.name } )
	
	local SpawnCountryID = SpawnTemplate.SpawnCountryID
	local SpawnCategoryID = SpawnTemplate.SpawnCategoryID
	
	SpawnTemplate.SpawnCoalitionID = nil
	SpawnTemplate.SpawnCountryID = nil
	SpawnTemplate.SpawnCategoryID = nil
	
	self:_RegisterGroup( SpawnTemplate )
	coalition.addGroup( SpawnCountryID, SpawnCategoryID, SpawnTemplate )
end


--- Set a status to a Group within the Database, this to check crossing events for example.
function DATABASE:SetStatusGroup( GroupName, Status )
trace.f( self.ClassName, Status )

	self.Groups[GroupName].Status = Status
end


--- Get a status to a Group within the Database, this to check crossing events for example.
function DATABASE:GetStatusGroup( GroupName )
trace.f( self.ClassName, Status )

	if self.Groups[GroupName] then
		return self.Groups[GroupName].Status
	else
		return ""
	end
end


--- Private
-- @section Private


--- Registers new Group Templates within the DATABASE Object.
function DATABASE:_RegisterGroup( GroupTemplate )

	local GroupTemplateName = env.getValueDictByKey(GroupTemplate.name)

	if not self.Groups[GroupTemplateName] then
		self.Groups[GroupTemplateName] = {}
		self.Groups[GroupTemplateName].Status = nil
	end
	self.Groups[GroupTemplateName].GroupName = GroupTemplateName
	self.Groups[GroupTemplateName].Template = GroupTemplate
	self.Groups[GroupTemplateName].groupId = GroupTemplate.groupId
	self.Groups[GroupTemplateName].UnitCount = #GroupTemplate.units
	self.Groups[GroupTemplateName].Units = GroupTemplate.units
	
	trace.i( self.ClassName, { "Group", self.Groups[GroupTemplateName].GroupName, self.Groups[GroupTemplateName].UnitCount } )
						
	for unit_num, UnitTemplate in pairs(GroupTemplate.units) do
	
		local UnitTemplateName = env.getValueDictByKey(UnitTemplate.name)
		self.Units[UnitTemplateName] = {}
		self.Units[UnitTemplateName].UnitName = UnitTemplateName
		self.Units[UnitTemplateName].Template = UnitTemplate
		self.Units[UnitTemplateName].GroupName = GroupTemplateName
		self.Units[UnitTemplateName].GroupTemplate = GroupTemplate
		self.Units[UnitTemplateName].GroupId = GroupTemplate.groupId
		if UnitTemplate.skill and (UnitTemplate.skill == "Client" or UnitTemplate.skill == "Player") then
			self.ClientsByName[UnitTemplateName] = UnitTemplate
			self.ClientsByID[UnitTemplate.unitId] = UnitTemplate
		end
		trace.i( self.ClassName, { "Unit", self.Units[UnitTemplateName].UnitName } )
	end 
end


--- Events
-- @section Events


--- Track DCSRTE DEAD or CRASH events for the internal scoring.
function DATABASE:OnDeadOrCrash( event )
trace.f( self.ClassName, { event } )

	local TargetUnit = nil
	local TargetGroup = nil
	local TargetUnitName = ""
	local TargetGroupName = ""
	local TargetPlayerName = ""
	local TargetCoalition = nil
	local TargetCategory = nil
	local TargetType = nil
	local TargetUnitCoalition = nil
	local TargetUnitCategory = nil
	local TargetUnitType = nil

	if event.initiator and Object.getCategory(event.initiator) == Object.Category.UNIT then
	
		TargetUnit = event.initiator
		TargetGroup = Unit.getGroup( TargetUnit )
		
		TargetUnitName = TargetUnit:getName()
		if TargetGroup then
			TargetGroupName = TargetGroup:getName()
		end
		TargetPlayerName = TargetUnit:getPlayerName()

		TargetCoalition = TargetUnit:getCoalition()
		TargetCategory = TargetUnit:getCategory()
		TargetType = TargetUnit:getTypeName()

		TargetUnitCoalition = DATABASECoalition[TargetCoalition]
		TargetUnitCategory = DATABASECategory[TargetCategory]
		TargetUnitType = TargetType

		trace.i( self.ClassName, { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType } )
	end

	for PlayerName, PlayerData in pairs( self.Players ) do
		if PlayerData then -- This should normally not happen, but i'll test it anyway.
			trace.i( self.ClassName, "Something got killed" )

			-- Some variables
			local InitUnitCoalition = DATABASECoalition[PlayerData.UnitCoalition]
			local InitUnitCategory = DATABASECategory[PlayerData.UnitCategory]
			local InitUnitType = PlayerData.UnitType
			local InitUnitName = PlayerData.UnitName

			-- What is he hitting?
			if TargetCategory then
				if PlayerData and PlayerData.Hit and PlayerData.Hit[TargetCategory] and PlayerData.Hit[TargetCategory][TargetUnitName] then -- Was there a hit for this unit for this player before registered???
					if not PlayerData.Kill[TargetCategory] then
						PlayerData.Kill[TargetCategory] = {}
					end
					if not PlayerData.Kill[TargetCategory][TargetType] then 
						PlayerData.Kill[TargetCategory][TargetType] = {}
						PlayerData.Kill[TargetCategory][TargetType].Score = 0
						PlayerData.Kill[TargetCategory][TargetType].ScoreKill = 0
						PlayerData.Kill[TargetCategory][TargetType].Penalty = 0
						PlayerData.Kill[TargetCategory][TargetType].PenaltyKill = 0
					end

					if PlayerData.UnitCoalition == TargetCoalition then
						PlayerData.Kill[TargetCategory][TargetType].Penalty = PlayerData.Kill[TargetCategory][TargetType].Penalty + 25						
						PlayerData.Kill[TargetCategory][TargetType].PenaltyKill = PlayerData.Kill[TargetCategory][TargetType].PenaltyKill + 1
						MESSAGE:New( "Player '" .. PlayerName .. "' killed a target " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " .. 
									PlayerData.Kill[TargetCategory][TargetType].PenaltyKill .. " times. Score: " .. PlayerData.Kill[TargetCategory][TargetType].Penalty, 
									"Game Status: Score", 20, "/PENALTY" .. PlayerName .. "/" .. InitUnitName ):ToAll()
						self:ScoreAdd( PlayerName, "KILL_PENALTY", 1, -125, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
					else
						PlayerData.Kill[TargetCategory][TargetType].Score = PlayerData.Kill[TargetCategory][TargetType].Score + 10						
						PlayerData.Kill[TargetCategory][TargetType].ScoreKill = PlayerData.Kill[TargetCategory][TargetType].ScoreKill + 1
						MESSAGE:New( "Player '" .. PlayerName .. "' killed a target " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " .. 
									  PlayerData.Kill[TargetCategory][TargetType].ScoreKill .. " times. Score: " .. PlayerData.Kill[TargetCategory][TargetType].Score, 
									  "Game Status: Score", 20, "/SCORE" .. PlayerName .. "/" .. InitUnitName ):ToAll()
						self:ScoreAdd( PlayerName, "KILL_SCORE", 1, 10, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
					end
				end
			end
		end
	end
end


--- Scheduled
-- @section Scheduled


--- Follows new players entering Clients within the DCSRTE.
function DATABASE:_FollowPlayers()
trace.scheduled( self.ClassName, "_FollowPlayers" )

	local ClientUnit = 0
	local CoalitionsData = { AlivePlayersRed = coalition.getPlayers(coalition.side.RED), AlivePlayersBlue = coalition.getPlayers(coalition.side.BLUE) }
	local unitId
	local unitData
	local AlivePlayerUnits = {}
	
	for CoalitionId, CoalitionData in pairs( CoalitionsData ) do
		trace.l( self.ClassName, "_FollowPlayers", CoalitionData )
		for UnitId, UnitData in pairs( CoalitionData ) do
			self:_AddPlayerFromUnit( UnitData )
		end
	end
end


--- Private
-- @section Private


--- Add a new player entering a Unit.
function DATABASE:_AddPlayerFromUnit( UnitData )
trace.f( self.ClassName, UnitData )

	if UnitData:isExist() then
		local UnitName = UnitData:getName()
		local PlayerName = UnitData:getPlayerName()

		trace.i(self.ClassName, "Player : " .. PlayerName .. " Unit : " .. UnitName )

		if self.Players[PlayerName] == nil then -- I believe this is the place where a Player gets a life in a mission when he enters a unit ...
			self.Players[PlayerName] = {}
			self.Players[PlayerName].Hit = {}
			self.Players[PlayerName].Kill = {}
			self.Players[PlayerName].Mission = {}
			
			-- for CategoryID, CategoryName in pairs( DATABASECategory ) do
				-- self.Players[PlayerName].Hit[CategoryID] = {}
				-- self.Players[PlayerName].Kill[CategoryID] = {}
			-- end
			self.Players[PlayerName].HitPlayers = {}
			self.Players[PlayerName].HitUnits = {}
			self.Players[PlayerName].Penalty = 0
			self.Players[PlayerName].PenaltyCoalition = 0
		end

		if not self.Players[PlayerName].UnitCoalition then
			self.Players[PlayerName].UnitCoalition = UnitData:getCoalition()
		else
			if self.Players[PlayerName].UnitCoalition ~= UnitData:getCoalition() then
				self.Players[PlayerName].Penalty = self.Players[PlayerName].Penalty + 50						
				self.Players[PlayerName].PenaltyCoalition = self.Players[PlayerName].PenaltyCoalition + 1
				MESSAGE:New( "Player '" .. PlayerName .. "' changed coalition from " .. DATABASECoalition[self.Players[PlayerName].UnitCoalition] .. " to " .. DATABASECoalition[UnitData:getCoalition()] ..  
							  "(changed " .. self.Players[PlayerName].PenaltyCoalition .. " times the coalition). 50 Penalty points added.", 
							  "Game Status: Penalty", 20, "/PENALTYCOALITION" .. PlayerName ):ToAll()
				self:ScoreAdd( PlayerName, "COALITION_PENALTY",  1, -50, self.Players[PlayerName].UnitName, DATABASECoalition[self.Players[PlayerName].UnitCoalition], DATABASECategory[self.Players[PlayerName].UnitCategory], self.Players[PlayerName].UnitType,  
							   UnitName, DATABASECoalition[UnitData:getCoalition()], DATABASECategory[UnitData:getCategory()], UnitData:getTypeName() )
			end
		end
		self.Players[PlayerName].UnitName = UnitName
		self.Players[PlayerName].UnitCoalition = UnitData:getCoalition()
		self.Players[PlayerName].UnitCategory = UnitData:getCategory()
		self.Players[PlayerName].UnitType = UnitData:getTypeName()
	end

end


--- Registers Scores the players completing a Mission Task.
function DATABASE:_AddMissionTaskScore( PlayerUnit, MissionName, Score )
trace.f( self.ClassName, { PlayerUnit, MissionName, Score } )

	local PlayerName = PlayerUnit:getPlayerName()
	
	if not self.Players[PlayerName].Mission[MissionName] then
		self.Players[PlayerName].Mission[MissionName] = {}
		self.Players[PlayerName].Mission[MissionName].ScoreTask = 0
		self.Players[PlayerName].Mission[MissionName].ScoreMission = 0
	end
	
	trace.i( self.ClassName, PlayerName )
	trace.i( self.ClassName, self.Players[PlayerName].Mission[MissionName] )

	self.Players[PlayerName].Mission[MissionName].ScoreTask = self.Players[PlayerName].Mission[MissionName].ScoreTask + Score

	MESSAGE:New( "Player '" .. PlayerName .. "' has finished another Task in Mission '" .. MissionName .. "'. " ..  
				  Score .. " Score points added.", 
				  "Game Status: Task Completion", 20, "/SCORETASK" .. PlayerName ):ToAll()
	
	_Database:ScoreAdd( PlayerName, "TASK_" .. MissionName:gsub( ' ', '_' ), 1, Score, PlayerUnit:getName() )
end


--- Registers Mission Scores for possible multiple players that contributed in the Mission.
function DATABASE:_AddMissionScore( MissionName, Score )
trace.f( self.ClassName, { PlayerUnit, MissionName, Score } )

	for PlayerName, PlayerData in pairs( self.Players ) do
	
		if PlayerData.Mission[MissionName] then
			PlayerData.Mission[MissionName].ScoreMission = PlayerData.Mission[MissionName].ScoreMission + Score
			MESSAGE:New( "Player '" .. PlayerName .. "' has finished Mission '" .. MissionName .. "'. " ..  
						  Score .. " Score points added.", 
						  "Game Status: Mission Completion", 20, "/SCOREMISSION" .. PlayerName ):ToAll()
			_Database:ScoreAdd( PlayerName, "MISSION_" .. MissionName:gsub( ' ', '_' ), 1, Score )
		end
	end
end


--- Events
-- @section Events


function DATABASE:OnHit( event )
trace.f( self.ClassName, { event } )

	local InitUnit = nil
	local InitUnitName = ""
	local InitGroupName = ""
	local InitPlayerName = ""

	local InitCoalition = nil
	local InitCategory = nil
	local InitType = nil
	local InitUnitCoalition = nil
	local InitUnitCategory = nil
	local InitUnitType = nil

	local TargetUnit = nil
	local TargetUnitName = ""
	local TargetGroupName = ""
	local TargetPlayerName = ""

	local TargetCoalition = nil
	local TargetCategory = nil
	local TargetType = nil
	local TargetUnitCoalition = nil
	local TargetUnitCategory = nil
	local TargetUnitType = nil

	if event.initiator and event.initiator:getName() then
	
		if event.initiator and Object.getCategory(event.initiator) == Object.Category.UNIT then
		
			InitUnit = event.initiator
			InitGroup = Unit.getGroup( InitUnit )
			
			InitUnitName = InitUnit:getName()
			if InitGroup then 
				InitGroupName = InitGroup:getName()
			end
			InitPlayerName = InitUnit:getPlayerName()
			
			InitCoalition = InitUnit:getCoalition()
			InitCategory = InitUnit:getCategory()
			InitType = InitUnit:getTypeName()

			InitUnitCoalition = DATABASECoalition[InitCoalition]
			InitUnitCategory = DATABASECategory[InitCategory]
			InitUnitType = InitType
			
			trace.i( self.ClassName, { InitUnitName, InitGroupName, InitPlayerName, InitCoalition, InitCategory, InitType , InitUnitCoalition, InitUnitCategory, InitUnitType } )
		end

			
		if event.target and Object.getCategory(event.target) == Object.Category.UNIT then
		
			TargetUnit = event.target
			TargetGroup = Unit.getGroup( TargetUnit )
			
			TargetUnitName = TargetUnit:getName()
			if TargetGroup then 
				TargetGroupName = TargetGroup:getName() 
			end
			TargetPlayerName = TargetUnit:getPlayerName()

			TargetCoalition = TargetUnit:getCoalition()
			TargetCategory = TargetUnit:getCategory()
			TargetType = TargetUnit:getTypeName()

			TargetUnitCoalition = DATABASECoalition[TargetCoalition]
			TargetUnitCategory = DATABASECategory[TargetCategory]
			TargetUnitType = TargetType
			
			trace.i( self.ClassName, { TargetUnitName, TargetGroupName, TargetPlayerName, TargetCoalition, TargetCategory, TargetType, TargetUnitCoalition, TargetUnitCategory, TargetUnitType } )
		end
		
		if InitPlayerName ~= nil then -- It is a player that is hitting something
			self:_AddPlayerFromUnit( InitUnit )
			if self.Players[InitPlayerName] then -- This should normally not happen, but i'll test it anyway.
				if TargetPlayerName ~= nil then -- It is a player hitting another player ...
					self:_AddPlayerFromUnit( TargetUnit )
					self.Players[InitPlayerName].HitPlayers = self.Players[InitPlayerName].HitPlayers + 1
				end
				
				trace.i( self.ClassName, "Hitting Something" )
				-- What is he hitting?
				if TargetCategory then
					if not self.Players[InitPlayerName].Hit[TargetCategory] then
						self.Players[InitPlayerName].Hit[TargetCategory] = {}
					end
					if not self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName] then
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName] = {}
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score = 0
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty = 0
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit = 0
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit = 0
					end
					local Score = 0
					if InitCoalition == TargetCoalition then
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty + 10						
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit + 1
						MESSAGE:New( "Player '" .. InitPlayerName .. "' hit a friendly " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " .. 
						              self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].PenaltyHit .. " times. Penalty: " .. self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Penalty, 
									  "Game Status: Penalty", 20, "/PENALTY" .. InitPlayerName .. "/" .. InitUnitName ):ToAll()
						self:ScoreAdd( InitPlayerName, "HIT_PENALTY", 1, -25, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
					else
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score + 1						
						self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit = self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit + 1
						MESSAGE:New( "Player '" .. InitPlayerName .. "' hit a target " .. TargetUnitCategory .. " ( " .. TargetType .. " ) " .. 
						              self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].ScoreHit .. " times. Score: " .. self.Players[InitPlayerName].Hit[TargetCategory][TargetUnitName].Score, 
									  "Game Status: Score", 20, "/SCORE" .. InitPlayerName .. "/" .. InitUnitName ):ToAll()
						self:ScoreAdd( InitPlayerName, "HIT_SCORE", 1, 1, InitUnitName, InitUnitCoalition, InitUnitCategory, InitUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
					end
				end
			end
		elseif InitPlayerName == nil then -- It is an AI hitting a player???
				
		end
	end
end


function DATABASE:ReportScoreAll()

env.info( "Hello World " )

	local ScoreMessage = ""
	local PlayerMessage = ""
	
	trace.i( self.ClassName, "Score Report" )

	for PlayerName, PlayerData in pairs( self.Players ) do
		if PlayerData then -- This should normally not happen, but i'll test it anyway.
			trace.i( self.ClassName, "Score Player: " .. PlayerName )

			-- Some variables
			local InitUnitCoalition = DATABASECoalition[PlayerData.UnitCoalition]
			local InitUnitCategory = DATABASECategory[PlayerData.UnitCategory]
			local InitUnitType = PlayerData.UnitType
			local InitUnitName = PlayerData.UnitName
			
			local PlayerScore = 0
			local PlayerPenalty = 0
			
			ScoreMessage = ""
			
			local ScoreMessageHits = ""

			for CategoryID, CategoryName in pairs( DATABASECategory ) do
				trace.i( self.ClassName, CategoryName )
				if PlayerData.Hit[CategoryID] then
					local Score = 0
					local ScoreHit = 0
					local Penalty = 0
					local PenaltyHit = 0
					trace.i( self.ClassName, "Hit scores exist for player " .. PlayerName )
					for UnitName, UnitData in pairs( PlayerData.Hit[CategoryID] ) do
						Score = Score + UnitData.Score
						ScoreHit = ScoreHit + UnitData.ScoreHit
						Penalty = Penalty + UnitData.Penalty
						PenaltyHit = UnitData.PenaltyHit
					end
					local ScoreMessageHit = string.format( "  %s = %d score(%d;-%d) hits(#%d;#-%d)", CategoryName, Score - Penalty, Score, Penalty, ScoreHit,  PenaltyHit )
					trace.i( self.ClassName, ScoreMessageHit )
					ScoreMessageHits = ScoreMessageHits .. ScoreMessageHit
					PlayerScore = PlayerScore + Score
					PlayerPenalty = PlayerPenalty + Penalty
				else
					--ScoreMessageHits = ScoreMessageHits .. string.format( "%s:%d  ", string.format(CategoryName, 1, 1), 0 )
				end
			end
			if ScoreMessageHits ~= "" then
				ScoreMessage = ScoreMessage .. "   Hits: " .. ScoreMessageHits .. " "
			end
	
			local ScoreMessageKills = ""
			for CategoryID, CategoryName in pairs( DATABASECategory ) do
				trace.i( self.ClassName, "Kill scores exist for player " .. PlayerName )
				if PlayerData.Kill[CategoryID] then
					local Score = 0
					local ScoreKill = 0
					local Penalty = 0
					local PenaltyKill = 0
					
					for UnitName, UnitData in pairs( PlayerData.Kill[CategoryID] ) do
						Score = Score + UnitData.Score
						ScoreKill = ScoreKill + UnitData.ScoreKill
						Penalty = Penalty + UnitData.Penalty
						PenaltyKill = PenaltyKill + UnitData.PenaltyKill
					end
					
					local ScoreMessageKill = string.format( "  %s = %d score(%d;-%d) hits(#%d;#-%d)", CategoryName, Score - Penalty, Score, Penalty, ScoreKill, PenaltyKill )
					trace.i( self.ClassName, ScoreMessageKill )
					ScoreMessageKills = ScoreMessageKills .. ScoreMessageKill

					PlayerScore = PlayerScore + Score
					PlayerPenalty = PlayerPenalty + Penalty
				else
					--ScoreMessageKills = ScoreMessageKills .. string.format( "%s:%d  ", string.format(CategoryName, 1, 1), 0 )
				end
			end
			if ScoreMessageKills ~= "" then
				ScoreMessage = ScoreMessage .. "   Kills: " .. ScoreMessageKills .. " "
			end
			
			local ScoreMessageCoalitionChangePenalties = ""
			if PlayerData.PenaltyCoalition ~= 0 then
				ScoreMessageCoalitionChangePenalties = ScoreMessageCoalitionChangePenalties .. string.format( "-%d (%d changed)", PlayerData.Penalty, PlayerData.PenaltyCoalition )
				PlayerPenalty = PlayerPenalty + PlayerData.Penalty
			end
			if ScoreMessageCoalitionChangePenalties ~= "" then
				ScoreMessage = ScoreMessage .. "   Coalition: " .. ScoreMessageCoalitionChangePenalties .. " "
			end

			local ScoreMessageMission = ""
			local ScoreMission = 0
			local ScoreTask = 0
			for MissionName, MissionData in pairs( PlayerData.Mission ) do
				ScoreMission = ScoreMission + MissionData.ScoreMission
				ScoreTask = ScoreTask + MissionData.ScoreTask
				ScoreMessageMission = ScoreMessageMission .. "'" .. MissionName .. "'; " 
			end
			PlayerScore = PlayerScore + ScoreMission + ScoreTask

			if ScoreMessageMission ~= "" then
				ScoreMessage = ScoreMessage .. "   Tasks: " .. ScoreTask .. " Mission: " .. ScoreMission .. " ( " .. ScoreMessageMission .. ") "
			end
			
			PlayerMessage = string.format( "     Player '%s' Score = %d ( %d Score, -%d Penalties ):", PlayerName, PlayerScore - PlayerPenalty, PlayerScore, PlayerPenalty )
			MESSAGE:New( PlayerMessage .. ScoreMessage, "Player Scores", 30, "/SCORE/" .. PlayerName ):ToAll()
		end
	end
end


function DATABASE:ReportScorePlayer()


end


function DATABASE:ScoreMenu()
	local ReportScore = SUBMENU:New( 'Scoring' )
	local ReportAllScores = COMMANDMENU:New( 'Score All Active Players', ReportScore, DATABASE.ReportScoreAll, self )
	local ReportPlayerScores = COMMANDMENU:New('Your Current Score', ReportScore, DATABASE.ReportScorePlayer, self )
end




-- File Logic for tracking the scores

function DATABASE:SecondsToClock(sSeconds)
local nSeconds = sSeconds
	if nSeconds == 0 then
		--return nil;
		return "00:00:00";
	else
		nHours = string.format("%02.f", math.floor(nSeconds/3600));
		nMins = string.format("%02.f", math.floor(nSeconds/60 - (nHours*60)));
		nSecs = string.format("%02.f", math.floor(nSeconds - nHours*3600 - nMins *60));
		return nHours..":"..nMins..":"..nSecs
	end
end


function DATABASE:ScoreOpen()
	if lfs then
		local fdir = lfs.writedir() .. [[Logs\]] .. "Player_Scores_" .. os.date( "%Y-%m-%d_%H-%M-%S" ) .. ".csv"
		self.StatFile, self.err = io.open(fdir,"w+")
		if not self.StatFile then
			error( "Error: Cannot open 'Player Scores.csv' file in " .. lfs.writedir() )
		end
		self.StatFile:write( '"Run-ID";Time;"PlayerName";"ScoreType";"PlayerUnitCoaltion";"PlayerUnitCategory";"PlayerUnitType"; "PlayerUnitName";"TargetUnitCoalition";"TargetUnitCategory";"TargetUnitType";"TargetUnitName";Times;Score\n' )
		
		self.RunID = os.date("%y-%m-%d_%H-%M-%S")
	end
end


function DATABASE:ScoreAdd( PlayerName, ScoreType, ScoreTimes, ScoreAmount, PlayerUnitName, PlayerUnitCoalition, PlayerUnitCategory, PlayerUnitType, TargetUnitName, TargetUnitCoalition, TargetUnitCategory, TargetUnitType )
	--write statistic information to file
	local ScoreTime = self:SecondsToClock(timer.getTime())
	PlayerName = PlayerName:gsub( '"', '_' )

	if PlayerUnitName and PlayerUnitName ~= '' then
		local PlayerUnit = Unit.getByName( PlayerUnitName )
		
		if PlayerUnit then
☺			if not PlayerUnitCategory then
				PlayerUnitCategory = DATABASECategory[PlayerUnit:getCategory()]
			end
			
			if not PlayerUnitCoalition then
				PlayerUnitCoalition = DATABASECoalition[PlayerUnit:getCoalition()]
			end
			
			if not PlayerUnitType then
				PlayerUnitType = PlayerUnit:getTypeName()
			end
		else
			PlayerUnitName = ''
			PlayerUnitCategory = ''
			PlayerUnitCoalition = ''
			PlayerUnitType = ''
		end
	else
		PlayerUnitName = ''
		PlayerUnitCategory = ''
		PlayerUnitCoalition = ''
		PlayerUnitType = ''
	end
			
	if not TargetUnitCoalition then
		TargetUnitCoalition = ''
	end
	
	if not TargetUnitCategory then
		TargetUnitCategory = ''
	end
	
	if not TargetUnitType then
		TargetUnitType = ''
	end
		
	if not TargetUnitName then
		TargetUnitName = ''
	end

	if lfs then
		self.StatFile:write( '"' .. self.RunID .. '";' .. ScoreTime .. ';"' .. PlayerName .. '";"' .. ScoreType .. '";"' .. 
									PlayerUnitCoalition .. '";"' .. PlayerUnitCategory .. '";"' .. PlayerUnitType .. '";"' .. PlayerUnitName .. '";"' .. 
									TargetUnitCoalition .. '";"' .. TargetUnitCategory .. '";"' .. TargetUnitType .. '";"' .. TargetUnitName .. '";' .. 
									ScoreTimes .. ';' .. ScoreAmount )
		self.StatFile:write( "\n" )
	end
end

	
function LogClose()
	if lfs then
		self.StatFile:close()
	end
end

_Database = DATABASE:New()
_Database:ScoreOpen()

