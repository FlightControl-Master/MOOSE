--- **AI** -- **AI A2A Air Patrolling or Staging.**
-- 
-- ====
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- ### Contributions: 
-- 
--   * **[Dutch_Baron](https://forums.eagle.ru/member.php?u=112075)**: Working together with James has resulted in the creation of the AI_BALANCER class. James has shared his ideas on balancing AI with air units, and together we made a first design which you can use now :-)
--   * **[Pikey](https://forums.eagle.ru/member.php?u=62835)**: Testing and API concept review.
-- 
-- ====
-- 
-- @module AI_A2A

--BASE:TraceClass("AI_A2A")


--- @type AI_A2A
-- @extends Core.Fsm#FSM_CONTROLLABLE

--- # AI_A2A class, extends @{Fsm#FSM_CONTROLLABLE}
-- 
-- The AI_A2A class implements the core functions to operate an AI @{Group} A2A tasking.
-- 
-- 
-- ## AI_A2A constructor
--   
--   * @{#AI_A2A.New}(): Creates a new AI_A2A object.
-- 
-- ## 2. AI_A2A is a FSM
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia2.JPG)
-- 
-- ### 2.1. AI_A2A States
-- 
--   * **None** ( Group ): The process is not started yet.
--   * **Patrolling** ( Group ): The AI is patrolling the Patrol Zone.
--   * **Returning** ( Group ): The AI is returning to Base.
--   * **Stopped** ( Group ): The process is stopped.
--   * **Crashed** ( Group ): The AI has crashed or is dead.
-- 
-- ### 2.2. AI_A2A Events
-- 
--   * **Start** ( Group ): Start the process.
--   * **Stop** ( Group ): Stop the process.
--   * **Route** ( Group ): Route the AI to a new random 3D point within the Patrol Zone.
--   * **RTB** ( Group ): Route the AI to the home base.
--   * **Detect** ( Group ): The AI is detecting targets.
--   * **Detected** ( Group ): The AI has detected new targets.
--   * **Status** ( Group ): The AI is checking status (fuel and damage). When the tresholds have been reached, the AI will RTB.
--    
-- ## 3. Set or Get the AI controllable
-- 
--   * @{#AI_A2A.SetControllable}(): Set the AIControllable.
--   * @{#AI_A2A.GetControllable}(): Get the AIControllable.
--
-- @field #AI_A2A
AI_A2A = {
  ClassName = "AI_A2A",
}

--- Creates a new AI_A2A object
-- @param #AI_A2A self
-- @param Wrapper.Group#GROUP AIGroup The GROUP object to receive the A2A Process.
-- @return #AI_A2A
function AI_A2A:New( AIGroup )

  -- Inherits from BASE
  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_A2A
  
  self:SetControllable( AIGroup )
  
  self:ManageFuel( .2, 60 )
  self:ManageDamage( 0.4 )

  self:SetStartState( "Stopped" ) 
  
  self:AddTransition( "*", "Start", "Started" )
  
  --- Start Handler OnBefore for AI_A2A
  -- @function [parent=#AI_A2A] OnBeforeStart
  -- @param #AI_A2A self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @return #boolean
  
  --- Start Handler OnAfter for AI_A2A
  -- @function [parent=#AI_A2A] OnAfterStart
  -- @param #AI_A2A self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  
  --- Start Trigger for AI_A2A
  -- @function [parent=#AI_A2A] Start
  -- @param #AI_A2A self
  
  --- Start Asynchronous Trigger for AI_A2A
  -- @function [parent=#AI_A2A] __Start
  -- @param #AI_A2A self
  -- @param #number Delay

  self:AddTransition( "*", "Stop", "Stopped" )

--- OnLeave Transition Handler for State Stopped.
-- @function [parent=#AI_A2A] OnLeaveStopped
-- @param #AI_A2A self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Stopped.
-- @function [parent=#AI_A2A] OnEnterStopped
-- @param #AI_A2A self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

--- OnBefore Transition Handler for Event Stop.
-- @function [parent=#AI_A2A] OnBeforeStop
-- @param #AI_A2A self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Stop.
-- @function [parent=#AI_A2A] OnAfterStop
-- @param #AI_A2A self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Stop.
-- @function [parent=#AI_A2A] Stop
-- @param #AI_A2A self

--- Asynchronous Event Trigger for Event Stop.
-- @function [parent=#AI_A2A] __Stop
-- @param #AI_A2A self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Status", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A.

--- OnBefore Transition Handler for Event Status.
-- @function [parent=#AI_A2A] OnBeforeStatus
-- @param #AI_A2A self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Status.
-- @function [parent=#AI_A2A] OnAfterStatus
-- @param #AI_A2A self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Status.
-- @function [parent=#AI_A2A] Status
-- @param #AI_A2A self

--- Asynchronous Event Trigger for Event Status.
-- @function [parent=#AI_A2A] __Status
-- @param #AI_A2A self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "RTB", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_A2A.

--- OnBefore Transition Handler for Event RTB.
-- @function [parent=#AI_A2A] OnBeforeRTB
-- @param #AI_A2A self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event RTB.
-- @function [parent=#AI_A2A] OnAfterRTB
-- @param #AI_A2A self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event RTB.
-- @function [parent=#AI_A2A] RTB
-- @param #AI_A2A self

--- Asynchronous Event Trigger for Event RTB.
-- @function [parent=#AI_A2A] __RTB
-- @param #AI_A2A self
-- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Returning.
-- @function [parent=#AI_A2A] OnLeaveReturning
-- @param #AI_A2A self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Returning.
-- @function [parent=#AI_A2A] OnEnterReturning
-- @param #AI_A2A self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.


  self:AddTransition( "*", "Return", "Returning" )
  self:AddTransition( "*", "Home", "Home" )
  self:AddTransition( "*", "LostControl", "LostControl" )
  self:AddTransition( "*", "Fuel", "Fuel" )
  self:AddTransition( "*", "Damaged", "Damaged" )
  self:AddTransition( "*", "Eject", "*" )
  self:AddTransition( "*", "Crash", "Crashed" )
  self:AddTransition( "*", "PilotDead", "*" )
  
  self.IdleCount = 0
  
  return self
end

function AI_A2A:SetDispatcher( Dispatcher )
  self.Dispatcher = Dispatcher
end

function AI_A2A:GetDispatcher()
  return self.Dispatcher
end

function AI_A2A:SetTargetDistance( Coordinate )

  local CurrentCoord = self.Controllable:GetCoordinate()
  self.TargetDistance = CurrentCoord:Get2DDistance( Coordinate )

  self.ClosestTargetDistance = ( not self.ClosestTargetDistance or self.ClosestTargetDistance > self.TargetDistance ) and self.TargetDistance or self.ClosestTargetDistance
end


function AI_A2A:ClearTargetDistance()

  self.TargetDistance = nil
  self.ClosestTargetDistance = nil
end


--- Sets (modifies) the minimum and maximum speed of the patrol.
-- @param #AI_A2A self
-- @param Dcs.DCSTypes#Speed  PatrolMinSpeed The minimum speed of the @{Controllable} in km/h.
-- @param Dcs.DCSTypes#Speed  PatrolMaxSpeed The maximum speed of the @{Controllable} in km/h.
-- @return #AI_A2A self
function AI_A2A:SetSpeed( PatrolMinSpeed, PatrolMaxSpeed )
  self:F2( { PatrolMinSpeed, PatrolMaxSpeed } )
  
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
end


--- Sets the floor and ceiling altitude of the patrol.
-- @param #AI_A2A self
-- @param Dcs.DCSTypes#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param Dcs.DCSTypes#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @return #AI_A2A self
function AI_A2A:SetAltitude( PatrolFloorAltitude, PatrolCeilingAltitude )
  self:F2( { PatrolFloorAltitude, PatrolCeilingAltitude } )
  
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
end


--- Sets the home airbase.
-- @param #AI_A2A self
-- @param Wrapper.Airbase#AIRBASE HomeAirbase
-- @return #AI_A2A self
function AI_A2A:SetHomeAirbase( HomeAirbase )
  self:F2( { HomeAirbase } )
  
  self.HomeAirbase = HomeAirbase
end



--- Set the status checking off.
-- @param #AI_A2A self
-- @return #AI_A2A self
function AI_A2A:SetStatusOff()
  self:F2()
  
  self.CheckStatus = false
end


--- When the AI is out of fuel, it is required that a new AI is started, before the old AI can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the AI will continue for a given time its patrol task in orbit, while a new AIControllable is targetted to the AI_A2A.
-- Once the time is finished, the old AI will return to the base.
-- @param #AI_A2A self
-- @param #number PatrolFuelTresholdPercentage The treshold in percentage (between 0 and 1) when the AIControllable is considered to get out of fuel.
-- @param #number PatrolOutOfFuelOrbitTime The amount of seconds the out of fuel AIControllable will orbit before returning to the base.
-- @return #AI_A2A self
function AI_A2A:ManageFuel( PatrolFuelTresholdPercentage, PatrolOutOfFuelOrbitTime )

  self.PatrolManageFuel = true
  self.PatrolFuelTresholdPercentage = PatrolFuelTresholdPercentage
  self.PatrolOutOfFuelOrbitTime = PatrolOutOfFuelOrbitTime
  
  self.Controllable:OptionRTBBingoFuel( false )
  
  return self
end

--- When the AI is damaged beyond a certain treshold, it is required that the AI returns to the home base.
-- However, damage cannot be foreseen early on. 
-- Therefore, when the damage treshold is reached, 
-- the AI will return immediately to the home base (RTB).
-- Note that for groups, the average damage of the complete group will be calculated.
-- So, in a group of 4 airplanes, 2 lost and 2 with damage 0.2, the damage treshold will be 0.25.
-- @param #AI_A2A self
-- @param #number PatrolDamageTreshold The treshold in percentage (between 0 and 1) when the AI is considered to be damaged.
-- @return #AI_A2A self
function AI_A2A:ManageDamage( PatrolDamageTreshold )

  self.PatrolManageDamage = true
  self.PatrolDamageTreshold = PatrolDamageTreshold
  
  return self
end

--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_A2A self
-- @return #AI_A2A self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_A2A:onafterStart( Controllable, From, Event, To )
  self:F2()

  self:__Status( 10 ) -- Check status status every 30 seconds.
  
  self:HandleEvent( EVENTS.PilotDead, self.OnPilotDead )
  self:HandleEvent( EVENTS.Crash, self.OnCrash )
  self:HandleEvent( EVENTS.Ejection, self.OnEjection )
  
  Controllable:OptionROEHoldFire()
  Controllable:OptionROTVertical()
end



--- @param #AI_A2A self
function AI_A2A:onbeforeStatus()

  return self.CheckStatus
end

--- @param #AI_A2A self
function AI_A2A:onafterStatus()
  self:F()

  if self.Controllable and self.Controllable:IsAlive() then
  
    local RTB = false
    
    local Fuel = self.Controllable:GetUnit(1):GetFuel()
    self:F({Fuel=Fuel})
    if Fuel < self.PatrolFuelTresholdPercentage then
      self:E( self.Controllable:GetName() .. " is out of fuel: " .. Fuel .. " ... RTB!" )
      local OldAIControllable = self.Controllable
      local AIControllableTemplate = self.Controllable:GetTemplate()
      
      local OrbitTask = OldAIControllable:TaskOrbitCircle( math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude ), self.PatrolMinSpeed )
      local TimedOrbitTask = OldAIControllable:TaskControlled( OrbitTask, OldAIControllable:TaskCondition(nil,nil,nil,nil,self.PatrolOutOfFuelOrbitTime,nil ) )
      OldAIControllable:SetTask( TimedOrbitTask, 10 )

      self:Fuel()
      RTB = true
    else
    end
    
    -- TODO: Check GROUP damage function.
    local Damage = self.Controllable:GetLife()
    local InitialLife = self.Controllable:GetLife0()
    self:F( { Damage = Damage, InitialLife = InitialLife, DamageTreshold = self.PatrolDamageTreshold } )
    if ( Damage / InitialLife ) < self.PatrolDamageTreshold then
      self:E( self.Controllable:GetName() .. " is damaged: " .. Damage .. " ... RTB!" )
      self:Damaged()
      RTB = true
    end

    -- Check if planes went RTB and are out of control.
    if self.Controllable:HasTask() == false then
      if not self:Is( "Started" ) and 
         not self:Is( "Stopped" ) then
        if self.IdleCount >= 2 then
          self:E( self.Controllable:GetName() .. " control lost! " )
          self:LostControl()
        else
          self.IdleCount = self.IdleCount + 1
        end
      end
    else
      self.IdleCount = 0
    end
    
    if RTB == true then
      self:__RTB( 0.5 )
    end
    
    self:__Status( 10 )
  end
end


--- @param Wrapper.Group#GROUP AIGroup
function AI_A2A.RTBRoute( AIGroup )

  AIGroup:E( { "RTBRoute:", AIGroup:GetName() } )
  local _AI_A2A = AIGroup:GetState( AIGroup, "AI_A2A" ) -- #AI_A2A
  _AI_A2A:__RTB( 0.5 )
end



--- @param #AI_A2A self
-- @param Wrapper.Group#GROUP AIGroup
function AI_A2A:onafterRTB( AIGroup, From, Event, To )
  self:F( { AIGroup, From, Event, To } )

  
  if AIGroup and AIGroup:IsAlive() then

    self:E( "Group " .. AIGroup:GetName() .. " ... RTB! ( " .. self:GetState() .. " )" )
    
    self.CheckStatus = false
    
    self:ClearTargetDistance()
    AIGroup:ClearTasks()

    local EngageRoute = {}

    --- Calculate the target route point.
    
    local CurrentCoord = AIGroup:GetCoordinate()
    local ToTargetCoord = self.HomeAirbase:GetCoordinate()
    local ToTargetSpeed = math.random( self.PatrolMinSpeed, self.PatrolMaxSpeed )
    local ToAirbaseAngle = CurrentCoord:GetAngleDegrees( CurrentCoord:GetDirectionVec3( ToTargetCoord ) )

    local Distance = CurrentCoord:Get2DDistance( ToTargetCoord )
    
    local ToAirbaseCoord = CurrentCoord:Translate( 5000, ToAirbaseAngle )
    if Distance < 5000 then
      self:Home()
      return
    end
    --- Create a route point of type air.
    local ToPatrolRoutePoint = ToAirbaseCoord:RoutePointAir( 
      self.PatrolAltType, 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      ToTargetSpeed, 
      true 
    )

    self:F( { Angle = ToAirbaseAngle, ToTargetSpeed = ToTargetSpeed } )
    self:T2( { self.MinSpeed, self.MaxSpeed, ToTargetSpeed } )
    
    EngageRoute[#EngageRoute+1] = ToPatrolRoutePoint
    
    AIGroup:OptionROEHoldFire()
    AIGroup:OptionROTEvadeFire()

    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    AIGroup:WayPointInitialize( EngageRoute )
  
    local Tasks = {}
    Tasks[#Tasks+1] = AIGroup:TaskFunction( 1, 1, "AI_A2A.RTBRoute" )
    EngageRoute[1].task = AIGroup:TaskCombo( Tasks )

    AIGroup:SetState( AIGroup, "AI_A2A", self )

    --- NOW ROUTE THE GROUP!
    AIGroup:WayPointExecute( 1, 0 )
      
  end
    
end

--- @param #AI_A2A self
-- @param Wrapper.Group#GROUP AIGroup
function AI_A2A:onafterHome( AIGroup, From, Event, To )
  self:F( { AIGroup, From, Event, To } )

  self:E( "Group " .. self.Controllable:GetName() .. " ... Home! ( " .. self:GetState() .. " )" )
  
  if AIGroup and AIGroup:IsAlive() then
  end

end
    


--- @param #AI_A2A self
function AI_A2A:onafterDead()
  self:SetStatusOff()
end


--- @param #AI_A2A self
-- @param Core.Event#EVENTDATA EventData
function AI_A2A:OnCrash( EventData )

  if self.Controllable:IsAlive() and EventData.IniDCSGroupName == self.Controllable:GetName() then
    self:E( self.Controllable:GetUnits() )
    if #self.Controllable:GetUnits() == 1 then
      self:__Crash( 1, EventData )
    end
  end
end

--- @param #AI_A2A self
-- @param Core.Event#EVENTDATA EventData
function AI_A2A:OnEjection( EventData )

  if self.Controllable:IsAlive() and EventData.IniDCSGroupName == self.Controllable:GetName() then
    self:__Eject( 1, EventData )
  end
end

--- @param #AI_A2A self
-- @param Core.Event#EVENTDATA EventData
function AI_A2A:OnPilotDead( EventData )

  if self.Controllable:IsAlive() and EventData.IniDCSGroupName == self.Controllable:GetName() then
    self:__PilotDead( 1, EventData )
  end
end
