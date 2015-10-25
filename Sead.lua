--- Provides defensive behaviour to a set of SAM sites within a running Mission.
-- @classmod SEAD
-- @author to be searched on the forum
-- @author (co) Flightcontrol (Modified and enriched with functionality)

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Task" )

SEAD = {
	ClassName = "SEAD", 
	TargetSkill = {
		Average   = { Evade = 50, DelayOff = { 10, 25 }, DelayOn = { 10, 30 } } ,
		Good      = { Evade = 30, DelayOff = { 8, 20 }, DelayOn = { 20, 40 } } ,
		High      = { Evade = 15, DelayOff = { 5, 17 }, DelayOn = { 30, 50 } } ,
		Excellent = { Evade = 10, DelayOff = { 3, 10 }, DelayOn = { 30, 60 } } 
	}, 
	SEADGroupPrefixes = {} 
}

--- Creates the main object which is handling defensive actions for SA sites or moving SA vehicles.
-- When an anti radiation missile is fired (KH-58, KH-31P, KH-31A, KH-25MPU, HARM missiles), the SA will shut down their radars and will take evasive actions...
-- Chances are big that the missile will miss.
-- @tparam table{string,...}|string SEADGroupPrefixes which is a table of Prefixes of the SA Groups in the DCSRTE on which evasive actions need to be taken.
-- @treturn SEAD
-- @usage
-- -- CCCP SEAD Defenses
-- -- Defends the Russian SA installations from SEAD attacks.
-- SEAD_RU_SAM_Defenses = SEAD:New( { 'RU SA-6 Kub', 'RU SA-6 Defenses', 'RU MI-26 Troops', 'RU Attack Gori' } )
function SEAD:New( SEADGroupPrefixes )
trace.f(self.ClassName, SEADGroupPrefixes )

	-- Arrange meta tables
	local Child = BASE:Inherit( self, BASE:New() )
	if type( SEADGroupPrefixes ) == 'table' then
		for SEADGroupPrefixID, SEADGroupPrefix in pairs( SEADGroupPrefixes ) do
			Child.SEADGroupPrefixes[SEADGroupPrefix] = SEADGroupPrefix
		end
	else
		Child.SEADGroupNames[SEADGroupPrefixes] = SEADGroupPrefixes
	end
	Child.AddEvent( Child, world.event.S_EVENT_SHOT, Child.EventShot )
	Child.EnableEvents( Child )
	
	return Child
end

--- Detects if an SA site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @see SEAD
function SEAD:EventShot( event )
trace.f( self.ClassName, { event } )

	local _grp = Unit.getGroup(event.initiator)-- Identify the group that fired 
	local _groupname = _grp:getName() -- return the name of the group
	local _unittable = {event.initiator:getName()} -- return the name of the units in the group
	local _SEADmissile = event.weapon -- Identify the weapon fired						
	local _SEADmissileName = _SEADmissile:getTypeName()	-- return weapon type
	--trigger.action.outText( string.format("Alerte, depart missile " ..string.format(_SEADmissileName)), 20) --debug message
	-- Start of the 2nd loop
	trace.i( self.ClassName, "Missile Launched = " .. _SEADmissileName )
	if _SEADmissileName == "KH-58" or _SEADmissileName == "KH-25MPU" or _SEADmissileName == "AGM-88" or _SEADmissileName == "KH-31A" or _SEADmissileName == "KH-31P" then -- Check if the missile is a SEAD
		local _evade = math.random (1,100) -- random number for chance of evading action
		local _targetMim = Weapon.getTarget(_SEADmissile) -- Identify target
		local _targetMimname = Unit.getName(_targetMim)
		local _targetMimgroup = Unit.getGroup(Weapon.getTarget(_SEADmissile))
		local _targetMimgroupName = _targetMimgroup:getName()
		local _targetMimcont= _targetMimgroup:getController()
		local _targetskill =  _Database.Units[_targetMimname].Template.skill
		trace.i( self.ClassName, self.SEADGroupPrefixes )
		trace.i( self.ClassName, _targetMimgroupName )
		local SEADGroupFound = false
		for SEADGroupPrefixID, SEADGroupPrefix in pairs( self.SEADGroupPrefixes ) do
			if string.find( _targetMimgroupName, SEADGroupPrefix, 1, true ) then
				SEADGroupFound = true
				trace.i( self.ClassName, 'Group Found' )
				break
			end
		end		
		if SEADGroupFound == true then
			if _targetskill == "Random" then -- when skill is random, choose a skill
				local Skills = { "Average", "Good", "High", "Excellent" }
				_targetskill = Skills[ math.random(1,4) ]
			end
			trace.i( self.ClassName, _targetskill ) -- debug message for skill check
			if self.TargetSkill[_targetskill] then
				if (_evade > self.TargetSkill[_targetskill].Evade) then
					trace.i( self.ClassName, string.format("Evading, target skill  " ..string.format(_targetskill)) ) --debug message
					local _targetMim = Weapon.getTarget(_SEADmissile)
					local _targetMimname = Unit.getName(_targetMim)
					local _targetMimgroup = Unit.getGroup(Weapon.getTarget(_SEADmissile))
					local _targetMimcont= _targetMimgroup:getController()
					routines.groupRandomDistSelf(_targetMimgroup,300,'Rank',250,20) -- move randomly
					local SuppressedGroups1 = {} -- unit suppressed radar off for a random time
					local function SuppressionEnd1(id)
						id.ctrl:setOption(AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.GREEN)
						SuppressedGroups1[id.groupName] = nil
					end
					local id = {
					groupName = _targetMimgroup,
					ctrl = _targetMimcont
					}
					local delay1 = math.random(self.TargetSkill[_targetskill].DelayOff[1], self.TargetSkill[_targetskill].DelayOff[2])
					if SuppressedGroups1[id.groupName] == nil then
						SuppressedGroups1[id.groupName] = {
							SuppressionEndTime1 = timer.getTime() + delay1,
							SuppressionEndN1 = SuppressionEndCounter1	--Store instance of SuppressionEnd() scheduled function
						}	
						Controller.setOption(_targetMimcont, AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.GREEN)
						timer.scheduleFunction(SuppressionEnd1, id, SuppressedGroups1[id.groupName].SuppressionEndTime1)	--Schedule the SuppressionEnd() function
						--trigger.action.outText( string.format("Radar Off " ..string.format(delay1)), 20)
					end
					
					local SuppressedGroups = {}
					local function SuppressionEnd(id)
						id.ctrl:setOption(AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.RED)
						SuppressedGroups[id.groupName] = nil
					end
					local id = {
						groupName = _targetMimgroup,
						ctrl = _targetMimcont
					}
					local delay = math.random(self.TargetSkill[_targetskill].DelayOn[1], self.TargetSkill[_targetskill].DelayOn[2])
					if SuppressedGroups[id.groupName] == nil then
						SuppressedGroups[id.groupName] = {
							SuppressionEndTime = timer.getTime() + delay,
							SuppressionEndN = SuppressionEndCounter	--Store instance of SuppressionEnd() scheduled function
						}
						timer.scheduleFunction(SuppressionEnd, id, SuppressedGroups[id.groupName].SuppressionEndTime)	--Schedule the SuppressionEnd() function
						--trigger.action.outText( string.format("Radar On " ..string.format(delay)), 20)
					end
				end
			end
		end
	end
end


