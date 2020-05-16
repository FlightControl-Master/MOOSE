--- **AI** - Models the automatic assignment of AI escorts to player flights.
--
-- ## Features:
-- --     
--   * Provides the facilities to trigger escorts when players join flight slots.
--   * 
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Escort_Dispatcher
-- @image MOOSE.JPG


--- @type AI_ESCORT_DISPATCHER
-- @extends Core.Fsm#FSM


--- Models the automatic assignment of AI escorts to player flights.
-- 
-- ===
--   
-- @field #AI_ESCORT_DISPATCHER
AI_ESCORT_DISPATCHER = {
  ClassName = "AI_ESCORT_DISPATCHER",
}

--- @field #list 
AI_ESCORT_DISPATCHER.AI_Escorts = {}


--- Creates a new AI_ESCORT_DISPATCHER object.
-- @param #AI_ESCORT_DISPATCHER self
-- @param Core.Set#SET_GROUP CarrierSet The set of @{Wrapper.Group#GROUP} objects of carriers for which escorts are spawned in.
-- @param Core.Spawn#SPAWN EscortSpawn The spawn object that will spawn in the Escorts.
-- @param Wrapper.Airbase#AIRBASE EscortAirbase The airbase where the escorts are spawned.
-- @param #string EscortName Name of the escort, which will also be the name of the escort menu.
-- @param #string EscortBriefing A text showing the briefing to the player. Note that if no EscortBriefing is provided, the default briefing will be shown.
-- @return #AI_ESCORT_DISPATCHER
-- @usage
-- 
-- -- Create a new escort when a player joins an SU-25T plane.
-- Create a carrier set, which contains the player slots that can be joined by the players, for which escorts will be defined.
-- local Red_SU25T_CarrierSet = SET_GROUP:New():FilterPrefixes( "Red A2G Player Su-25T" ):FilterStart()
-- 
-- -- Create a spawn object that will spawn in the escorts, once the player has joined the player slot.
-- local Red_SU25T_EscortSpawn = SPAWN:NewWithAlias( "Red A2G Su-25 Escort", "Red AI A2G SU-25 Escort" ):InitLimit( 10, 10 )
-- 
-- -- Create an airbase object, where the escorts will be spawned.
-- local Red_SU25T_Airbase = AIRBASE:FindByName( AIRBASE.Caucasus.Maykop_Khanskaya )
-- 
-- -- Park the airplanes at the airbase, visible before start.
-- Red_SU25T_EscortSpawn:ParkAtAirbase( Red_SU25T_Airbase, AIRBASE.TerminalType.OpenMedOrBig )
-- 
-- -- New create the escort dispatcher, using the carrier set, the escort spawn object at the escort airbase.
-- -- Provide a name of the escort, which will be also the name appearing on the radio menu for the group.
-- -- And a briefing to appear when the player joins the player slot.
-- Red_SU25T_EscortDispatcher = AI_ESCORT_DISPATCHER:New( Red_SU25T_CarrierSet, Red_SU25T_EscortSpawn, Red_SU25T_Airbase, "Escort Su-25", "You Su-25T is escorted by one Su-25. Use the radio menu to control the escorts." )
-- 
-- -- The dispatcher needs to be started using the :Start() method.
-- Red_SU25T_EscortDispatcher:Start()
function AI_ESCORT_DISPATCHER:New( CarrierSet, EscortSpawn, EscortAirbase, EscortName, EscortBriefing )

  local self = BASE:Inherit( self, FSM:New() ) -- #AI_ESCORT_DISPATCHER

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

function AI_ESCORT_DISPATCHER:onafterStart( From, Event, To )

  self:HandleEvent( EVENTS.Birth )
  
  self:HandleEvent( EVENTS.PlayerLeaveUnit, self.OnEventExit )
  self:HandleEvent( EVENTS.Crash, self.OnEventExit )
  self:HandleEvent( EVENTS.Dead, self.OnEventExit )

end

--- @param #AI_ESCORT_DISPATCHER self
-- @param Core.Event#EVENTDATA EventData
function AI_ESCORT_DISPATCHER:OnEventExit( EventData )

  local PlayerGroupName = EventData.IniGroupName
  local PlayerGroup = EventData.IniGroup
  local PlayerUnit = EventData.IniUnit
  
  self:I({EscortAirbase= self.EscortAirbase } )
  self:I({PlayerGroupName = PlayerGroupName } )
  self:I({PlayerGroup = PlayerGroup})
  self:I({FirstGroup = self.CarrierSet:GetFirst()})
  self:I({FindGroup = self.CarrierSet:FindGroup( PlayerGroupName )})
  
  if self.CarrierSet:FindGroup( PlayerGroupName ) then
    if self.AI_Escorts[PlayerGroupName] then
      self.AI_Escorts[PlayerGroupName]:Stop()
      self.AI_Escorts[PlayerGroupName] = nil
    end
  end
      
end

--- @param #AI_ESCORT_DISPATCHER self
-- @param Core.Event#EVENTDATA EventData
function AI_ESCORT_DISPATCHER:OnEventBirth( EventData )

  local PlayerGroupName = EventData.IniGroupName
  local PlayerGroup = EventData.IniGroup
  local PlayerUnit = EventData.IniUnit
  
  self:I({EscortAirbase= self.EscortAirbase } )
  self:I({PlayerGroupName = PlayerGroupName } )
  self:I({PlayerGroup = PlayerGroup})
  self:I({FirstGroup = self.CarrierSet:GetFirst()})
  self:I({FindGroup = self.CarrierSet:FindGroup( PlayerGroupName )})
  
  if self.CarrierSet:FindGroup( PlayerGroupName ) then
    if not self.AI_Escorts[PlayerGroupName] then
      local LeaderUnit = PlayerUnit
      local EscortGroup = self.EscortSpawn:SpawnAtAirbase( self.EscortAirbase, SPAWN.Takeoff.Hot )
      self:I({EscortGroup = EscortGroup})
      
      self:ScheduleOnce( 1,
        function( EscortGroup )
          local EscortSet = SET_GROUP:New()
          EscortSet:AddGroup( EscortGroup )
          self.AI_Escorts[PlayerGroupName] = AI_ESCORT:New( LeaderUnit, EscortSet, self.EscortName, self.EscortBriefing )
          self.AI_Escorts[PlayerGroupName]:FormationTrail( 0, 100, 0 )
          if EscortGroup:IsHelicopter() then
            self.AI_Escorts[PlayerGroupName]:MenusHelicopters()
          else
            self.AI_Escorts[PlayerGroupName]:MenusAirplanes()
          end
          self.AI_Escorts[PlayerGroupName]:__Start( 0.1 )
        end, EscortGroup
      )
    end
  end

end


--- Start Trigger for AI_ESCORT_DISPATCHER
-- @function [parent=#AI_ESCORT_DISPATCHER] Start
-- @param #AI_ESCORT_DISPATCHER self

--- Start Asynchronous Trigger for AI_ESCORT_DISPATCHER
-- @function [parent=#AI_ESCORT_DISPATCHER] __Start
-- @param #AI_ESCORT_DISPATCHER self
-- @param #number Delay

--- Stop Trigger for AI_ESCORT_DISPATCHER
-- @function [parent=#AI_ESCORT_DISPATCHER] Stop
-- @param #AI_ESCORT_DISPATCHER self

--- Stop Asynchronous Trigger for AI_ESCORT_DISPATCHER
-- @function [parent=#AI_ESCORT_DISPATCHER] __Stop
-- @param #AI_ESCORT_DISPATCHER self
-- @param #number Delay






