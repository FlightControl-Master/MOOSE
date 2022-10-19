--- **AI** - Models the assignment of AI escorts to player flights upon request using the radio menu.
--
-- ## Features:
--     
--   * Provides the facilities to trigger escorts when players join flight units.
--   * Provide a menu for which escorts can be requested.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Escort_Dispatcher_Request
-- @image MOOSE.JPG


--- @type AI_ESCORT_DISPATCHER_REQUEST
-- @extends Core.Fsm#FSM


--- Models the assignment of AI escorts to player flights upon request using the radio menu.
-- 
-- ===
--   
-- @field #AI_ESCORT_DISPATCHER_REQUEST
AI_ESCORT_DISPATCHER_REQUEST = {
  ClassName = "AI_ESCORT_DISPATCHER_REQUEST",
}

--- @field #list 
AI_ESCORT_DISPATCHER_REQUEST.AI_Escorts = {}


--- Creates a new AI_ESCORT_DISPATCHER_REQUEST object.
-- @param #AI_ESCORT_DISPATCHER_REQUEST self
-- @param Core.Set#SET_GROUP CarrierSet The set of @{Wrapper.Group#GROUP} objects of carriers for which escorts are requested. 
-- @param Core.Spawn#SPAWN EscortSpawn The spawn object that will spawn in the Escorts.
-- @param Wrapper.Airbase#AIRBASE EscortAirbase The airbase where the escorts are spawned.
-- @param #string EscortName Name of the escort, which will also be the name of the escort menu.
-- @param #string EscortBriefing A text showing the briefing to the player. Note that if no EscortBriefing is provided, the default briefing will be shown.
-- @return #AI_ESCORT_DISPATCHER_REQUEST
function AI_ESCORT_DISPATCHER_REQUEST:New( CarrierSet, EscortSpawn, EscortAirbase, EscortName, EscortBriefing )

  local self = BASE:Inherit( self, FSM:New() ) -- #AI_ESCORT_DISPATCHER_REQUEST

  self.CarrierSet = CarrierSet
  self.EscortSpawn = EscortSpawn
  self.EscortAirbase = EscortAirbase
  self.EscortName = EscortName
  self.EscortBriefing = EscortBriefing

  self:SetStartState( "Idle" ) 
  
  self:AddTransition( "Monitoring", "Monitor", "Monitoring" )

  self:AddTransition( "Idle", "Start", "Monitoring" )
  self:AddTransition( "Monitoring", "Stop", "Idle" )
  
  -- Put a Dead event handler on CarrierSet, to ensure that when a carrier is destroyed, that all internal parameters are reset.
  function self.CarrierSet.OnAfterRemoved( CarrierSet, From, Event, To, CarrierName, Carrier )
    self:F( { Carrier = Carrier:GetName() } )
  end
  
  return self
end

function AI_ESCORT_DISPATCHER_REQUEST:onafterStart( From, Event, To )

  self:HandleEvent( EVENTS.Birth )
  
  self:HandleEvent( EVENTS.PlayerLeaveUnit, self.OnEventExit )
  self:HandleEvent( EVENTS.Crash, self.OnEventExit )
  self:HandleEvent( EVENTS.Dead, self.OnEventExit )

end

--- @param #AI_ESCORT_DISPATCHER_REQUEST self
-- @param Core.Event#EVENTDATA EventData
function AI_ESCORT_DISPATCHER_REQUEST:OnEventExit( EventData )

  local PlayerGroupName = EventData.IniGroupName
  local PlayerGroup = EventData.IniGroup
  local PlayerUnit = EventData.IniUnit
  
  if self.CarrierSet:FindGroup( PlayerGroupName ) then
    if self.AI_Escorts[PlayerGroupName] then
      self.AI_Escorts[PlayerGroupName]:Stop()
      self.AI_Escorts[PlayerGroupName] = nil
    end
  end
      
end

--- @param #AI_ESCORT_DISPATCHER_REQUEST self
-- @param Core.Event#EVENTDATA EventData
function AI_ESCORT_DISPATCHER_REQUEST:OnEventBirth( EventData )

  local PlayerGroupName = EventData.IniGroupName
  local PlayerGroup = EventData.IniGroup
  local PlayerUnit = EventData.IniUnit
  
  if self.CarrierSet:FindGroup( PlayerGroupName ) then
    if not self.AI_Escorts[PlayerGroupName] then
      local LeaderUnit = PlayerUnit
      self:ScheduleOnce( 0.1,
        function()
          self.AI_Escorts[PlayerGroupName] = AI_ESCORT_REQUEST:New( LeaderUnit, self.EscortSpawn, self.EscortAirbase, self.EscortName, self.EscortBriefing )
          self.AI_Escorts[PlayerGroupName]:FormationTrail( 0, 100, 0 )
          if PlayerGroup:IsHelicopter() then
            self.AI_Escorts[PlayerGroupName]:MenusHelicopters()
          else
            self.AI_Escorts[PlayerGroupName]:MenusAirplanes()
          end
          self.AI_Escorts[PlayerGroupName]:__Start( 0.1 )
        end
      )
    end
  end

end


--- Start Trigger for AI_ESCORT_DISPATCHER_REQUEST
-- @function [parent=#AI_ESCORT_DISPATCHER_REQUEST] Start
-- @param #AI_ESCORT_DISPATCHER_REQUEST self

--- Start Asynchronous Trigger for AI_ESCORT_DISPATCHER_REQUEST
-- @function [parent=#AI_ESCORT_DISPATCHER_REQUEST] __Start
-- @param #AI_ESCORT_DISPATCHER_REQUEST self
-- @param #number Delay

--- Stop Trigger for AI_ESCORT_DISPATCHER_REQUEST
-- @function [parent=#AI_ESCORT_DISPATCHER_REQUEST] Stop
-- @param #AI_ESCORT_DISPATCHER_REQUEST self

--- Stop Asynchronous Trigger for AI_ESCORT_DISPATCHER_REQUEST
-- @function [parent=#AI_ESCORT_DISPATCHER_REQUEST] __Stop
-- @param #AI_ESCORT_DISPATCHER_REQUEST self
-- @param #number Delay






