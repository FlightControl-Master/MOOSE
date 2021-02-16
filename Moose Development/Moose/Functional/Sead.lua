--- **Functional** -- Make SAM sites execute evasive and defensive behaviour when being fired upon.
-- 
-- ===
-- 
-- ## Features:
-- 
--   * When SAM sites are being fired upon, the SAMs will take evasive action will reposition themselves when possible.
--   * When SAM sites are being fired upon, the SAMs will take defensive action by shutting down their radars.
-- 
-- ===
-- 
-- ## Missions:
-- 
-- [SEV - SEAD Evasion](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/SEV%20-%20SEAD%20Evasion)
-- 
-- ===
-- 
-- ### Authors: **FlightControl**, **applevangelist**
-- 
-- Last Update: Feb 2021
-- 
-- ===
-- 
-- @module Functional.Sead
-- @image SEAD.JPG

--- @type SEAD
-- @extends Core.Base#BASE

--- Make SAM sites execute evasive and defensive behaviour when being fired upon.
-- 
-- This class is very easy to use. Just setup a SEAD object by using @{#SEAD.New}() and SAMs will evade and take defensive action when being fired upon.
-- 
-- # Constructor:
-- 
-- Use the @{#SEAD.New}() constructor to create a new SEAD object.
-- 
--       SEAD_RU_SAM_Defenses = SEAD:New( { 'RU SA-6 Kub', 'RU SA-6 Defenses', 'RU MI-26 Troops', 'RU Attack Gori' } )
-- 
-- @field #SEAD
SEAD = {
	ClassName = "SEAD", 
	TargetSkill = {
		Average   = { Evade = 30, DelayOn = { 40, 60 } } ,
		Good      = { Evade = 20, DelayOn = { 30, 50 } } ,
		High      = { Evade = 15, DelayOn = { 20, 40 } } ,
		Excellent = { Evade = 10, DelayOn = { 10, 30 } } 
	}, 
	SEADGroupPrefixes = {},
	SuppressedGroups = {},
	EngagementRange = 75 --  default 75% engagement range Feature Request #1355
}

  -- TODO Complete list?
  --- Missile enumerators
  -- @field Harms
  SEAD.Harms = {
  --[[
  ["X58"] = "weapons.missiles.X_58", --Kh-58X anti-radiation missiles fired
  ["Kh25"] = "weapons.missiles.Kh25MP_PRGS1VP", --Kh-25MP anti-radiation missiles fired
  ["X25"] = "weapons.missiles.X_25MP", --Kh-25MPU anti-radiation missiles fired
  ["X28"] = "weapons.missiles.X_28", --Kh-28 anti-radiation missiles fired
  ["X31"] = "weapons.missiles.X_31P", --Kh-31P anti-radiation missiles fired
  ["AGM45A"] = "weapons.missiles.AGM_45A", --AGM-45A anti-radiation missiles fired
  ["AGM45"] = "weapons.missiles.AGM_45", --AGM-45B anti-radiation missiles fired
  ["AGM88"] = "weapons.missiles.AGM_88", --AGM-88C anti-radiation missiles fired
  ["AGM122"] = "weapons.missiles.AGM_122", --AGM-122 Sidearm anti-radiation missiles fired
  ["LD10"] = "weapons.missiles.LD-10", --LD-10 anti-radiation missiles fired
  ["ALARM"] = "weapons.missiles.ALARM", --ALARM anti-radiation missiles fired
  ["AGM84E"] = "weapons.missiles.AGM_84E", --AGM84 anti-radiation missiles fired
  ["AGM84A"] = "weapons.missiles.AGM_84A", --AGM84 anti-radiation missiles fired
  ["AGM84H"] = "weapons.missiles.AGM_84H", --AGM84 anti-radiation missiles fired
  --]]
  ["AGM_88"] = "AGM_88",
  ["AGM_45"] = "AGM_45",
  ["AGM_122"] = "AGM_122",
  ["AGM_84"] = "AGM_84",
  ["AGM_45"] = "AGM_45",
  ["ALARN"] = "ALARM",
  ["LD-10"] = "LD-10",
  ["X_58"] = "X_58",
  ["X_28"] = "X_28",
  ["X_25"] = "X_25",
  ["X_31"] = "X_31",
  ["Kh25"] = "Kh25",
  }
  
--- Creates the main object which is handling defensive actions for SA sites or moving SA vehicles.
-- When an anti radiation missile is fired (KH-58, KH-31P, KH-31A, KH-25MPU, HARM missiles), the SA will shut down their radars and will take evasive actions...
-- Chances are big that the missile will miss.
-- @param #SEAD self
-- @param table{string,...}|string SEADGroupPrefixes which is a table of Prefixes of the SA Groups in the DCS mission editor on which evasive actions need to be taken.
-- @return SEAD
-- @usage
-- -- CCCP SEAD Defenses
-- -- Defends the Russian SA installations from SEAD attacks.
-- SEAD_RU_SAM_Defenses = SEAD:New( { 'RU SA-6 Kub', 'RU SA-6 Defenses', 'RU MI-26 Troops', 'RU Attack Gori' } )
function SEAD:New( SEADGroupPrefixes )

	local self = BASE:Inherit( self, BASE:New() )
	self:F( SEADGroupPrefixes )
	
	if type( SEADGroupPrefixes ) == 'table' then
		for SEADGroupPrefixID, SEADGroupPrefix in pairs( SEADGroupPrefixes ) do
			self.SEADGroupPrefixes[SEADGroupPrefix] = SEADGroupPrefix
		end
	else
		self.SEADGroupPrefixes[SEADGroupPrefixes] = SEADGroupPrefixes
	end
	
	self:HandleEvent( EVENTS.Shot )
	self:I("*** SEAD - Started Version 0.2.5")
	return self
end

--- Update the active SEAD Set
-- @param #SEAD self
-- @param #table SEADGroupPrefixes The prefixes to add, note: can also be a single #string
-- @return #SEAD self
function SEAD:UpdateSet( SEADGroupPrefixes )

  self:F( SEADGroupPrefixes )
  
  if type( SEADGroupPrefixes ) == 'table' then
    for SEADGroupPrefixID, SEADGroupPrefix in pairs( SEADGroupPrefixes ) do
      self.SEADGroupPrefixes[SEADGroupPrefix] = SEADGroupPrefix
    end
  else
    self.SEADGroupPrefixes[SEADGroupPrefixes] = SEADGroupPrefixes
  end

  return self
end

--- Sets the engagement range of the SAMs. Defaults to 75% to make it more deadly. Feature Request #1355
-- @param #SEAD self
-- @param #number range Set the engagement range in percent, e.g. 50
-- @return self
function SEAD:SetEngagementRange(range)
  self:F( { range } )
  range = range or 75
  if range < 0 or range > 100 then
    range = 75
  end
  self.EngagementRange = range
  self:T(string.format("*** SEAD - Engagement range set to %s",range))
  return self
end

  --- Check if a known HARM was fired
  -- @param #SEAD self
  -- @param #string WeaponName
  -- @return #boolean Returns true for a match
  function SEAD:_CheckHarms(WeaponName)
    self:F( { WeaponName } )
    local hit = false
      for _,_name in pairs (SEAD.Harms) do
        if string.find(WeaponName,_name,1) then hit = true end
      end
    return hit
  end

--- Detects if an SAM site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @see SEAD
-- @param #SEAD
-- @param Core.Event#EVENTDATA EventData
function SEAD:OnEventShot( EventData )
	self:T( { EventData } )

	local SEADUnit = EventData.IniDCSUnit
	local SEADUnitName = EventData.IniDCSUnitName
	local SEADWeapon = EventData.Weapon -- Identify the weapon fired
	local SEADWeaponName = EventData.WeaponName	-- return weapon type

	self:T( "*** SEAD - Missile Launched = " .. SEADWeaponName)
	self:T({ SEADWeapon })
	
	--[[check for SEAD missiles
  if SEADWeaponName == "weapons.missiles.X_58" --Kh-58U anti-radiation missiles fired
    or 
    SEADWeaponName == "weapons.missiles.Kh25MP_PRGS1VP" --Kh-25MP anti-radiation missiles fired
    or
    SEADWeaponName == "weapons.missiles.X_25MP" --Kh-25MPU anti-radiation missiles fired
    or
    SEADWeaponName == "weapons.missiles.X_28" --Kh-28 anti-radiation missiles fired
    or
    SEADWeaponName == "weapons.missiles.X_31P" --Kh-31P anti-radiation missiles fired
    or
    SEADWeaponName == "weapons.missiles.AGM_45A" --AGM-45A anti-radiation missiles fired
    or
    SEADWeaponName == "weapons.missiles.AGM_45" --AGM-45B anti-radiation missiles fired
    or
    SEADWeaponName == "weapons.missiles.AGM_88" --AGM-88C anti-radiation missiles fired
    or
    SEADWeaponName == "weapons.missiles.AGM_122" --AGM-122 Sidearm anti-radiation missiles fired
    or
    SEADWeaponName == "weapons.missiles.LD-10" --LD-10 anti-radiation missiles fired
    or
    SEADWeaponName == "weapons.missiles.ALARM" --ALARM anti-radiation missiles fired
    or
    SEADWeaponName == "weapons.missiles.AGM_84E" --AGM84 anti-radiation missiles fired
    or
    SEADWeaponName == "weapons.missiles.AGM_84A" --AGM84 anti-radiation missiles fired
    or
    SEADWeaponName == "weapons.missiles.AGM_84H" --AGM84 anti-radiation missiles fired
    --]]
  if self:_CheckHarms(SEADWeaponName) then
  
		local _evade = math.random (1,100) -- random number for chance of evading action
		local _targetMim = EventData.Weapon:getTarget() -- Identify target
		local _targetMimname = Unit.getName(_targetMim) -- Unit name
		local _targetMimgroup = Unit.getGroup(Weapon.getTarget(SEADWeapon)) --targeted group
		local _targetMimgroupName = _targetMimgroup:getName() -- group name
		local _targetskill =  _DATABASE.Templates.Units[_targetMimname].Template.skill
		self:T( self.SEADGroupPrefixes )
		self:T( _targetMimgroupName )
		-- see if we are shot at
		local SEADGroupFound = false
		for SEADGroupPrefixID, SEADGroupPrefix in pairs( self.SEADGroupPrefixes ) do
			if string.find( _targetMimgroupName, SEADGroupPrefix, 1, true ) then
				SEADGroupFound = true
				self:T( '*** SEAD - Group Found' )
				break
			end
		end		
		if SEADGroupFound == true then -- yes we are being attacked
			if _targetskill == "Random" then -- when skill is random, choose a skill
				local Skills = { "Average", "Good", "High", "Excellent" }
				_targetskill = Skills[ math.random(1,4) ]
			end
			self:T( _targetskill )
			if self.TargetSkill[_targetskill] then
				if (_evade > self.TargetSkill[_targetskill].Evade) then
				
					self:T( string.format("*** SEAD - Evading, target skill  " ..string.format(_targetskill)) )
				
					local _targetMimgroup = Unit.getGroup(Weapon.getTarget(SEADWeapon))
					local _targetMimcont= _targetMimgroup:getController()
					
					routines.groupRandomDistSelf(_targetMimgroup,300,'Diamond',250,20) -- move randomly
					
					--tracker ID table to switch groups off and on again
					local id = { 
					groupName = _targetMimgroup,
					ctrl = _targetMimcont
					}

					local function SuppressionEnd(id) --switch group back on
					 local range = self.EngagementRange -- Feature Request #1355
					  self:T(string.format("*** SEAD - Engagement Range is %d", range))
						id.ctrl:setOption(AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.RED)
						id.ctrl:setOption(AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION,range) --Feature Request #1355
						self.SuppressedGroups[id.groupName] = nil  --delete group id from table when done
					end
					-- randomize switch-on time
					local delay = math.random(self.TargetSkill[_targetskill].DelayOn[1], self.TargetSkill[_targetskill].DelayOn[2])
					local SuppressionEndTime = timer.getTime() + delay
					--create entry
					if self.SuppressedGroups[id.groupName] == nil then  --no timer entry for this group yet
						self.SuppressedGroups[id.groupName] = {
							SuppressionEndTime = delay
						  }
						Controller.setOption(_targetMimcont, AI.Option.Ground.id.ALARM_STATE,AI.Option.Ground.val.ALARM_STATE.GREEN)
						timer.scheduleFunction(SuppressionEnd, id, SuppressionEndTime)	--Schedule the SuppressionEnd() function
					end
				end
			end
		end
	end
end
