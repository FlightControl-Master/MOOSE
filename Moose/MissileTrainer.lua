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
	
	self.MessageInterval = 2
	self.MessageLastTime = timer.getTime()
	
	self.Distance = Distance

	_EVENTDISPATCHER:OnShot( self._EventShot, self )
	
	self.DB = DATABASE:New():FilterStart()
	self.DBClients = self.DB.Clients
	self.DBUnits = self.DB.Units
	
	for ClientID, Client in pairs( self.DBClients ) do
     Client:Message( "Welcome to the Missile Trainer", 10, "ID", "TEST" )
     Client.MainMenu = MENU_CLIENT:New( Client, "Missile Trainer", nil )
     Client.MenuMessages = MENU_CLIENT:New( Client, "Messages", Client.MainMenu )
     Client.MenuOn = MENU_CLIENT_COMMAND:New( Client, "Messages On", Client.MenuMessages, self._MenuMessages, { MenuSelf = self, MessagesOnOff = true } )
     Client.MenuOff = MENU_CLIENT_COMMAND:New( Client, "Messages Off", Client.MenuMessages, self._MenuMessages, { MenuSelf = self, MessagesOnOff = false } )
     Client.MenuToAll = MENU_CLIENT_COMMAND:New( Client, "To All", Client.MenuMessages, self._MenuMessages, { MenuSelf = self, MessagesToAll = true } )
     Client.MenuToTarget = MENU_CLIENT_COMMAND:New( Client, "To Target", Client.MenuMessages, self._MenuMessages, { MenuSelf = self, MessagesToAll = false } )
     Client.MenuTrackOn = MENU_CLIENT_COMMAND:New( Client, "Tracking On", Client.MenuMessages, self._MenuMessages, { MenuSelf = self, MessagesTrack = true } )
     Client.MenuTrackOff = MENU_CLIENT_COMMAND:New( Client, "Tracking Off", Client.MenuMessages, self._MenuMessages, { MenuSelf = self, MessagesTrack = false } )
	end
--	self.DB:ForEachClient( 
--	 --- @param Client#CLIENT Client
--	 function( Client )
--     
--	 end 
--	)
	
	self.MessagesOnOff = true
  self.MessagesToAll = false
  self.MessagesTrack = true
	
	return self
end

function MISSILETRAINER:_MenuMessages( MenuParameters )

  local self = MenuParameters.MenuSelf
  
  if MenuParameters.MessagesOnOff then
    self.MessagesOnOff = MenuParameters.MessagesOnOff
  end
  
  if MenuParameters.MessagesToAll then
    self.MessagesToAll = MenuParameters.MessagesToAll
  end
  
  if MenuParameters.MessagesTrack then
    self.MessagesTrack = MenuParameters.MessagesTrack
  end
  
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
	local TrainerTargetSkill =  _DATABASE.Templates.Units[TrainerTargetDCSUnitName].Template.skill

	self:T( TrainerTargetSkill )
	
	local Client = self.DBClients[TrainerTargetDCSUnitName]
	if Client then
	  local TrainerSourceUnit = UNIT:New(TrainerSourceDCSUnit)
    local TrainerTargetUnit = UNIT:New(TrainerTargetDCSUnit)
	  self.Schedulers[#self.Schedulers+1] = SCHEDULER:New( self, self._FollowMissile, { TrainerSourceUnit, TrainerWeapon, TrainerTargetUnit, Client }, 0.5, 0.05, 0 )  
	end
end

---
-- @param #MISSILETRAINER self
-- @param Unit#UNIT TrainerSourceDCSUnit
-- @param DCSWeapon#Weapon TrainerWeapon
-- @param Unit#UNIT TrainerTargetDCSUnit
-- @param Client#CLIENT Client
function MISSILETRAINER:_FollowMissile( TrainerSourceUnit, TrainerWeapon, TrainerTargetUnit, Client )
  self:F( { TrainerSourceUnit, TrainerWeapon, TrainerTargetUnit, Client } )
  
  local PositionMissile = TrainerWeapon:getPoint()
  local PositionTarget = TrainerTargetUnit:GetPositionVec3()
  
  local Distance = ( ( PositionMissile.x - PositionTarget.x )^2 +
    ( PositionMissile.y - PositionTarget.y )^2 +
    ( PositionMissile.z - PositionTarget.z )^2
    ) ^ 0.5

  
  if self.MessagesOnOff and self.MessagesTrack and self.MessageLastTime + 2 <= timer.getTime() then
    self:T( Distance )
    self.MessageLastTime = timer.getTime()
    local Message = MESSAGE:New( 
        string.format( "%s launched by %s: %4.2f km", 
          TrainerWeapon:getTypeName(), 
          TrainerSourceUnit:GetName(), 
          Distance 
        ),"Tracking", 2, "ID" )  
    
    if self.MessagesToAll then
      Message:ToAll()
    else
      Message:ToClient( Client )
    end
  end
  
  if Distance <= self.Distance then
    TrainerWeapon:destroy()
    if self.MessagesOnOff then
      self:T( "Destroyed" )
      local Message = MESSAGE:New( 
          string.format( "%s launched by %s destroyed", 
            TrainerWeapon:getTypeName(), 
            TrainerSourceUnit:GetName(), 
            Distance 
          ),"Tracking", 2, "ID" )  
      if self.MessagesToAll then
        Message:ToAll()
      else
        Message:ToClient( Client )
      end
    end
    return false
  end

  return true
end
