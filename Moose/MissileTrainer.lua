--- Provides missile training functions.
-- @module MissileTrainer
-- @author FlightControl

Include.File( "Client" )
Include.File( "Scheduler" )

--- The MISSILETRAINER class
-- @type MISSILETRAINER
-- @extends Base#BASE
MISSILETRAINER = {
	ClassName = "MISSILETRAINER", 
}

--- Creates the main object which is handling missile tracking.
-- When a missile is fired a SCHEDULER is set off that follows the missile. When near a certain a client player, the missile will be destroyed.
-- @param #MISSILETRAINER
-- @param #number Distance The distance in meters when a tracked missile needs to be destroyed when close to a player.
-- @return #MISSILETRAINER
function MISSILETRAINER:New( Distance )
	local self = BASE:Inherit( self, BASE:New() )
	self:F( Distance )	
	
	self.Schedulers = {}
	self.SchedulerID = 0
	
	self.Distance = Distance

	_EVENTDISPATCHER:OnShot( self._EventShot, self )
	
	return self
end

--- Detects if an SA site was shot with an anti radiation missile. In this case, take evasive actions based on the skill level set within the ME.
-- @see MISSILETRAINER
function MISSILETRAINER:_EventShot( Event )
	self:F( { Event } )

	local TrainerSourceDCSUnit = Event.IniDCSUnit
	local TrainerSourceDCSUnitName = Event.IniDCSUnitName
	local TrainerWeapon = Event.Weapon -- Identify the weapon fired						
	local TrainerWeaponName = Event.WeaponName	-- return weapon type

	self:T( "Missile Launched = " .. TrainerWeaponName )

	local TrainerTargetDCSUnit = TrainerWeapon:getTarget() -- Identify target
	local TrainerTargetDCSUnitName = Unit.getName( TrainerTargetDCSUnit )
	local TrainerTargetDCSGroup = TrainerTargetDCSUnit:getGroup()
	local TrainerTargetDCSGroupName = TrainerTargetDCSGroup:getName()
	local TrainerTargetSkill =  _DATABASE.Units[TrainerTargetDCSUnitName].Template.skill

	self:T( TrainerTargetSkill )
	
	if TrainerTargetSkill == "Client" or TrainerTargetSkill == "Player" then
	  self.Schedulers[#self.Schedulers+1] = SCHEDULER:New( self, self._FollowMissile, { TrainerSourceDCSUnit, TrainerWeapon, TrainerTargetDCSUnit }, 0.5, 0.05, 0 )  
	end
end

function MISSILETRAINER:_FollowMissile( TrainerSourceDCSUnit, TrainerWeapon, TrainerTargetDCSUnit )
  self:F( { TrainerSourceDCSUnit, TrainerWeapon, TrainerTargetDCSUnit } )
  
  local TrainerSourceUnit = UNIT:New( TrainerSourceDCSUnit )
  local TrainerTargetUnit = UNIT:New( TrainerTargetDCSUnit ) 

  local PositionMissile = TrainerWeapon:getPoint()
  local PositionTarget = TrainerTargetUnit:GetPositionVec3()
  
  local Distance = ( ( PositionMissile.x - PositionTarget.x )^2 +
    ( PositionMissile.y - PositionTarget.y )^2 +
    ( PositionMissile.z - PositionTarget.z )^2
    ) ^ 0.5

  MESSAGE:New( "Distance Missle = " .. Distance, nil, 0.2, "/Missile" ):ToAll()
  
  if Distance <= self.Distance then
    TrainerWeapon:destroy()
    MESSAGE:New( "Missle Destroyed", nil, 5, "/Missile" ):ToAll()
    return false
  end

  return true
end
