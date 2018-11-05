--- **AI** -- Models the process of AI air operations.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===
-- 
-- @module AI.AI_Air
-- @image AI_Air_Operations.JPG

--- @type AI_AIR
-- @extends Core.Fsm#FSM_CONTROLLABLE

--- The AI_AIR class implements the core functions to operate an AI @{Wrapper.Group}.
-- 
-- 
-- # 1) AI_AIR constructor
--   
--   * @{#AI_AIR.New}(): Creates a new AI_AIR object.
-- 
-- # 2) AI_AIR is a Finite State Machine.
-- 
-- This section must be read as follows. Each of the rows indicate a state transition, triggered through an event, and with an ending state of the event was executed.
-- The first column is the **From** state, the second column the **Event**, and the third column the **To** state.
-- 
-- So, each of the rows have the following structure.
-- 
--   * **From** => **Event** => **To**
-- 
-- Important to know is that an event can only be executed if the **current state** is the **From** state.
-- This, when an **Event** that is being triggered has a **From** state that is equal to the **Current** state of the state machine, the event will be executed,
-- and the resulting state will be the **To** state.
-- 
-- These are the different possible state transitions of this state machine implementation: 
-- 
--   * Idle => Start => Monitoring
--
-- ## 2.1) AI_AIR States.
-- 
--   * **Idle**: The process is idle.
-- 
-- ## 2.2) AI_AIR Events.
-- 
--   * **Start**: Start the transport process.
--   * **Stop**: Stop the transport process.
--   * **Monitor**: Monitor and take action.
--
-- @field #AI_AIR
AI_AIR = {
  ClassName = "AI_AIR",
}

--- Creates a new AI_AIR process.
-- @param #AI_AIR self
-- @param Wrapper.Group#GROUP AIGroup The group object to receive the A2G Process.
-- @return #AI_AIR
function AI_AIR:New( AIGroup )

  -- Inherits from BASE
  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New() ) -- #AI_AIR
  
  self:SetControllable( AIGroup )
  
  self:SetStartState( "Stopped" ) 

  self:AddTransition( "*", "Start", "Started" )
  
  --- Start Handler OnBefore for AI_AIR
  -- @function [parent=#AI_AIR] OnBeforeStart
  -- @param #AI_AIR self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @return #boolean
  
  --- Start Handler OnAfter for AI_AIR
  -- @function [parent=#AI_AIR] OnAfterStart
  -- @param #AI_AIR self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  
  --- Start Trigger for AI_AIR
  -- @function [parent=#AI_AIR] Start
  -- @param #AI_AIR self
  
  --- Start Asynchronous Trigger for AI_AIR
  -- @function [parent=#AI_AIR] __Start
  -- @param #AI_AIR self
  -- @param #number Delay

  self:AddTransition( "*", "Stop", "Stopped" )

--- OnLeave Transition Handler for State Stopped.
-- @function [parent=#AI_AIR] OnLeaveStopped
-- @param #AI_AIR self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Stopped.
-- @function [parent=#AI_AIR] OnEnterStopped
-- @param #AI_AIR self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

--- OnBefore Transition Handler for Event Stop.
-- @function [parent=#AI_AIR] OnBeforeStop
-- @param #AI_AIR self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Stop.
-- @function [parent=#AI_AIR] OnAfterStop
-- @param #AI_AIR self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Stop.
-- @function [parent=#AI_AIR] Stop
-- @param #AI_AIR self

--- Asynchronous Event Trigger for Event Stop.
-- @function [parent=#AI_AIR] __Stop
-- @param #AI_AIR self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "Status", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_AIR.

--- OnBefore Transition Handler for Event Status.
-- @function [parent=#AI_AIR] OnBeforeStatus
-- @param #AI_AIR self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event Status.
-- @function [parent=#AI_AIR] OnAfterStatus
-- @param #AI_AIR self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event Status.
-- @function [parent=#AI_AIR] Status
-- @param #AI_AIR self

--- Asynchronous Event Trigger for Event Status.
-- @function [parent=#AI_AIR] __Status
-- @param #AI_AIR self
-- @param #number Delay The delay in seconds.

  self:AddTransition( "*", "RTB", "*" ) -- FSM_CONTROLLABLE Transition for type #AI_AIR.

--- OnBefore Transition Handler for Event RTB.
-- @function [parent=#AI_AIR] OnBeforeRTB
-- @param #AI_AIR self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnAfter Transition Handler for Event RTB.
-- @function [parent=#AI_AIR] OnAfterRTB
-- @param #AI_AIR self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
	
--- Synchronous Event Trigger for Event RTB.
-- @function [parent=#AI_AIR] RTB
-- @param #AI_AIR self

--- Asynchronous Event Trigger for Event RTB.
-- @function [parent=#AI_AIR] __RTB
-- @param #AI_AIR self
-- @param #number Delay The delay in seconds.

--- OnLeave Transition Handler for State Returning.
-- @function [parent=#AI_AIR] OnLeaveReturning
-- @param #AI_AIR self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
-- @return #boolean Return false to cancel Transition.

--- OnEnter Transition Handler for State Returning.
-- @function [parent=#AI_AIR] OnEnterReturning
-- @param #AI_AIR self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.

  self:AddTransition( "Patrolling", "Refuel", "Refuelling" ) 

  --- Refuel Handler OnBefore for AI_AIR
  -- @function [parent=#AI_AIR] OnBeforeRefuel
  -- @param #AI_AIR self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @return #boolean
  
  --- Refuel Handler OnAfter for AI_AIR
  -- @function [parent=#AI_AIR] OnAfterRefuel
  -- @param #AI_AIR self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  
  --- Refuel Trigger for AI_AIR
  -- @function [parent=#AI_AIR] Refuel
  -- @param #AI_AIR self
  
  --- Refuel Asynchronous Trigger for AI_AIR
  -- @function [parent=#AI_AIR] __Refuel
  -- @param #AI_AIR self
  -- @param #number Delay

  self:AddTransition( "*", "Takeoff", "Airborne" )
  self:AddTransition( "*", "Return", "Returning" )
  self:AddTransition( "*", "Hold", "Holding" )
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

--- @param Wrapper.Group#GROUP self
-- @param Core.Event#EVENTDATA EventData
function GROUP:OnEventTakeoff( EventData, Fsm )
  Fsm:Takeoff()
  self:UnHandleEvent( EVENTS.Takeoff )
end



function AI_AIR:SetDispatcher( Dispatcher )
  self.Dispatcher = Dispatcher
end

function AI_AIR:GetDispatcher()
  return self.Dispatcher
end

function AI_AIR:SetTargetDistance( Coordinate )

  local CurrentCoord = self.Controllable:GetCoordinate()
  self.TargetDistance = CurrentCoord:Get2DDistance( Coordinate )

  self.ClosestTargetDistance = ( not self.ClosestTargetDistance or self.ClosestTargetDistance > self.TargetDistance ) and self.TargetDistance or self.ClosestTargetDistance
end


function AI_AIR:ClearTargetDistance()

  self.TargetDistance = nil
  self.ClosestTargetDistance = nil
end


--- Sets (modifies) the minimum and maximum speed of the patrol.
-- @param #AI_AIR self
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Controllable} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Controllable} in km/h.
-- @return #AI_AIR self
function AI_AIR:SetSpeed( PatrolMinSpeed, PatrolMaxSpeed )
  self:F2( { PatrolMinSpeed, PatrolMaxSpeed } )
  
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
end


--- Sets the floor and ceiling altitude of the patrol.
-- @param #AI_AIR self
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
-- @return #AI_AIR self
function AI_AIR:SetAltitude( PatrolFloorAltitude, PatrolCeilingAltitude )
  self:F2( { PatrolFloorAltitude, PatrolCeilingAltitude } )
  
  self.PatrolFloorAltitude = PatrolFloorAltitude
  self.PatrolCeilingAltitude = PatrolCeilingAltitude
end


--- Sets the home airbase.
-- @param #AI_AIR self
-- @param Wrapper.Airbase#AIRBASE HomeAirbase
-- @return #AI_AIR self
function AI_AIR:SetHomeAirbase( HomeAirbase )
  self:F2( { HomeAirbase } )
  
  self.HomeAirbase = HomeAirbase
end

--- Sets to refuel at the given tanker.
-- @param #AI_AIR self
-- @param Wrapper.Group#GROUP TankerName The group name of the tanker as defined within the Mission Editor or spawned.
-- @return #AI_AIR self
function AI_AIR:SetTanker( TankerName )
  self:F2( { TankerName } )
  
  self.TankerName = TankerName
end


--- Sets the disengage range, that when engaging a target beyond the specified range, the engagement will be cancelled and the plane will RTB.
-- @param #AI_AIR self
-- @param #number DisengageRadius The disengage range.
-- @return #AI_AIR self
function AI_AIR:SetDisengageRadius( DisengageRadius )
  self:F2( { DisengageRadius } )
  
  self.DisengageRadius = DisengageRadius
end

--- Set the status checking off.
-- @param #AI_AIR self
-- @return #AI_AIR self
function AI_AIR:SetStatusOff()
  self:F2()
  
  self.CheckStatus = false
end


--- When the AI is out of fuel, it is required that a new AI is started, before the old AI can return to the home base.
-- Therefore, with a parameter and a calculation of the distance to the home base, the fuel treshold is calculated.
-- When the fuel treshold is reached, the AI will continue for a given time its patrol task in orbit, while a new AIControllable is targetted to the AI_AIR.
-- Once the time is finished, the old AI will return to the base.
-- @param #AI_AIR self
-- @param #number FuelThresholdPercentage The treshold in percentage (between 0 and 1) when the AIControllable is considered to get out of fuel.
-- @param #number OutOfFuelOrbitTime The amount of seconds the out of fuel AIControllable will orbit before returning to the base.
-- @return #AI_AIR self
function AI_AIR:SetFuelThreshold( FuelThresholdPercentage, OutOfFuelOrbitTime )

  self.FuelThresholdPercentage = FuelThresholdPercentage
  self.OutOfFuelOrbitTime = OutOfFuelOrbitTime
  
  self.Controllable:OptionRTBBingoFuel( false )
  
  return self
end

--- When the AI is damaged beyond a certain treshold, it is required that the AI returns to the home base.
-- However, damage cannot be foreseen early on. 
-- Therefore, when the damage treshold is reached, 
-- the AI will return immediately to the home base (RTB).
-- Note that for groups, the average damage of the complete group will be calculated.
-- So, in a group of 4 airplanes, 2 lost and 2 with damage 0.2, the damage treshold will be 0.25.
-- @param #AI_AIR self
-- @param #number PatrolDamageThreshold The treshold in percentage (between 0 and 1) when the AI is considered to be damaged.
-- @return #AI_AIR self
function AI_AIR:SetDamageThreshold( PatrolDamageThreshold )

  self.PatrolManageDamage = true
  self.PatrolDamageThreshold = PatrolDamageThreshold
  
  return self
end

--- Defines a new patrol route using the @{Process_PatrolZone} parameters and settings.
-- @param #AI_AIR self
-- @return #AI_AIR self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
-- @param #string From The From State string.
-- @param #string Event The Event string.
-- @param #string To The To State string.
function AI_AIR:onafterStart( Controllable, From, Event, To )

  self:__Status( 10 ) -- Check status status every 30 seconds.
  
  self:HandleEvent( EVENTS.PilotDead, self.OnPilotDead )
  self:HandleEvent( EVENTS.Crash, self.OnCrash )
  self:HandleEvent( EVENTS.Ejection, self.OnEjection )
  
  Controllable:OptionROEHoldFire()
  Controllable:OptionROTVertical()
end



--- @param #AI_AIR self
function AI_AIR:onbeforeStatus()

  return self.CheckStatus
end

--- @param #AI_AIR self
function AI_AIR:onafterStatus()

  if self.Controllable and self.Controllable:IsAlive() then
  
    local RTB = false
    
    local DistanceFromHomeBase = self.HomeAirbase:GetCoordinate():Get2DDistance( self.Controllable:GetCoordinate() )
    
    if not self:Is( "Holding" ) and not self:Is( "Returning" ) then
      local DistanceFromHomeBase = self.HomeAirbase:GetCoordinate():Get2DDistance( self.Controllable:GetCoordinate() )
      self:F({DistanceFromHomeBase=DistanceFromHomeBase})
      
      if DistanceFromHomeBase > self.DisengageRadius then
        self:E( self.Controllable:GetName() .. " is too far from home base, RTB!" )
        self:Hold( 300 )
        RTB = false
      end
    end

-- I think this code is not requirement anymore after release 2.5.    
--    if self:Is( "Fuel" ) or self:Is( "Damaged" ) or self:Is( "LostControl" ) then
--      if DistanceFromHomeBase < 5000 then
--        self:E( self.Controllable:GetName() .. " is near the home base, RTB!" )
--        self:Home( "Destroy" )
--      end
--    end
    

    if not self:Is( "Fuel" ) and not self:Is( "Home" ) then
      local Fuel = self.Controllable:GetFuelMin()
      self:F({Fuel=Fuel, FuelThresholdPercentage=self.FuelThresholdPercentage})
      if Fuel < self.FuelThresholdPercentage then
        if self.TankerName then
          self:E( self.Controllable:GetName() .. " is out of fuel: " .. Fuel .. " ... Refuelling at Tanker!" )
          self:Refuel()
        else
          self:E( self.Controllable:GetName() .. " is out of fuel: " .. Fuel .. " ... RTB!" )
          local OldAIControllable = self.Controllable
          
          local OrbitTask = OldAIControllable:TaskOrbitCircle( math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude ), self.PatrolMinSpeed )
          local TimedOrbitTask = OldAIControllable:TaskControlled( OrbitTask, OldAIControllable:TaskCondition(nil,nil,nil,nil,self.OutOfFuelOrbitTime,nil ) )
          OldAIControllable:SetTask( TimedOrbitTask, 10 )
    
          self:Fuel()
          RTB = true
        end
      else
      end
    end
    
    -- TODO: Check GROUP damage function.
    local Damage = self.Controllable:GetLife()
    local InitialLife = self.Controllable:GetLife0()
    self:F( { Damage = Damage, InitialLife = InitialLife, DamageThreshold = self.PatrolDamageThreshold } )
    if ( Damage / InitialLife ) < self.PatrolDamageThreshold then
      self:E( self.Controllable:GetName() .. " is damaged: " .. Damage .. " ... RTB!" )
      self:Damaged()
      RTB = true
      self:SetStatusOff()
    end

    -- Check if planes went RTB and are out of control.
    -- We only check if planes are out of control, when they are in duty.
    if self.Controllable:HasTask() == false then
      if not self:Is( "Started" ) and 
         not self:Is( "Stopped" ) and
         not self:Is( "Fuel" ) and 
         not self:Is( "Damaged" ) and 
         not self:Is( "Home" ) then
        if self.IdleCount >= 2 then
          if Damage ~= InitialLife then
            self:Damaged()
          else  
            self:E( self.Controllable:GetName() .. " control lost! " )
            self:LostControl()
          end
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

    if not self:Is("Home") then
      self:__Status( 10 )
    end
    
  end
end


--- @param Wrapper.Group#GROUP AIGroup
function AI_AIR.RTBRoute( AIGroup, Fsm )

  AIGroup:F( { "AI_AIR.RTBRoute:", AIGroup:GetName() } )
  
  if AIGroup:IsAlive() then
    Fsm:__RTB( 0.5 )
  end
  
end

--- @param Wrapper.Group#GROUP AIGroup
function AI_AIR.RTBHold( AIGroup, Fsm )

  AIGroup:F( { "AI_AIR.RTBHold:", AIGroup:GetName() } )
  if AIGroup:IsAlive() then
    Fsm:__RTB( 0.5 )
    Fsm:Return()
    local Task = AIGroup:TaskOrbitCircle( 4000, 400 )
    AIGroup:SetTask( Task )
  end
  
end


--- @param #AI_AIR self
-- @param Wrapper.Group#GROUP AIGroup
function AI_AIR:onafterRTB( AIGroup, From, Event, To )
  self:F( { AIGroup, From, Event, To } )

  
  if AIGroup and AIGroup:IsAlive() then

    self:E( "Group " .. AIGroup:GetName() .. " ... RTB! ( " .. self:GetState() .. " )" )
    
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
      self:E( "RTB and near the airbase!" )
      self:Home()
      return
    end
    --- Create a route point of type air.
    local ToRTBRoutePoint = ToAirbaseCoord:WaypointAir( 
      self.PatrolAltType, 
      POINT_VEC3.RoutePointType.TurningPoint, 
      POINT_VEC3.RoutePointAction.TurningPoint, 
      ToTargetSpeed, 
      true 
    )

    self:F( { Angle = ToAirbaseAngle, ToTargetSpeed = ToTargetSpeed } )
    self:T2( { self.MinSpeed, self.MaxSpeed, ToTargetSpeed } )
    
    EngageRoute[#EngageRoute+1] = ToRTBRoutePoint
    EngageRoute[#EngageRoute+1] = ToRTBRoutePoint
    
    AIGroup:OptionROEHoldFire()
    AIGroup:OptionROTEvadeFire()

    --- Now we're going to do something special, we're going to call a function from a waypoint action at the AIControllable...
    AIGroup:WayPointInitialize( EngageRoute )
  
    local Tasks = {}
    Tasks[#Tasks+1] = AIGroup:TaskFunction( "AI_AIR.RTBRoute", self )
    EngageRoute[#EngageRoute].task = AIGroup:TaskCombo( Tasks )

    --- NOW ROUTE THE GROUP!
    AIGroup:Route( EngageRoute, 0.5 )
      
  end
    
end

--- @param #AI_AIR self
-- @param Wrapper.Group#GROUP AIGroup
function AI_AIR:onafterHome( AIGroup, From, Event, To )
  self:F( { AIGroup, From, Event, To } )

  self:E( "Group " .. self.Controllable:GetName() .. " ... Home! ( " .. self:GetState() .. " )" )
  
  if AIGroup and AIGroup:IsAlive() then
  end

end



--- @param #AI_AIR self
-- @param Wrapper.Group#GROUP AIGroup
function AI_AIR:onafterHold( AIGroup, From, Event, To, HoldTime )
  self:F( { AIGroup, From, Event, To } )

  self:E( "Group " .. self.Controllable:GetName() .. " ... Holding! ( " .. self:GetState() .. " )" )
  
  if AIGroup and AIGroup:IsAlive() then
    local OrbitTask = AIGroup:TaskOrbitCircle( math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude ), self.PatrolMinSpeed )
    local TimedOrbitTask = AIGroup:TaskControlled( OrbitTask, AIGroup:TaskCondition( nil, nil, nil, nil, HoldTime , nil ) )
    
    local RTBTask = AIGroup:TaskFunction( "AI_AIR.RTBHold", self )
    
    local OrbitHoldTask = AIGroup:TaskOrbitCircle( 4000, self.PatrolMinSpeed )
    
    --AIGroup:SetState( AIGroup, "AI_AIR", self )
    
    AIGroup:SetTask( AIGroup:TaskCombo( { TimedOrbitTask, RTBTask, OrbitHoldTask } ), 1 )
  end

end

--- @param Wrapper.Group#GROUP AIGroup
function AI_AIR.Resume( AIGroup, Fsm )

  AIGroup:I( { "AI_AIR.Resume:", AIGroup:GetName() } )
  if AIGroup:IsAlive() then
    Fsm:__RTB( 0.5 )
  end
  
end

--- @param #AI_AIR self
-- @param Wrapper.Group#GROUP AIGroup
function AI_AIR:onafterRefuel( AIGroup, From, Event, To )
  self:F( { AIGroup, From, Event, To } )

  self:E( "Group " .. self.Controllable:GetName() .. " ... Refuelling! ( " .. self:GetState() .. " )" )
  
  if AIGroup and AIGroup:IsAlive() then
    local Tanker = GROUP:FindByName( self.TankerName )
    if Tanker:IsAlive() and Tanker:IsAirPlane() then

      local RefuelRoute = {}
  
      --- Calculate the target route point.
      
      local CurrentCoord = AIGroup:GetCoordinate()
      local ToRefuelCoord = Tanker:GetCoordinate()
      local ToRefuelSpeed = math.random( self.PatrolMinSpeed, self.PatrolMaxSpeed )
      
      --- Create a route point of type air.
      local ToRefuelRoutePoint = ToRefuelCoord:WaypointAir( 
        self.PatrolAltType, 
        POINT_VEC3.RoutePointType.TurningPoint, 
        POINT_VEC3.RoutePointAction.TurningPoint, 
        ToRefuelSpeed, 
        true 
      )
  
      self:F( { ToRefuelSpeed = ToRefuelSpeed } )
      
      RefuelRoute[#RefuelRoute+1] = ToRefuelRoutePoint
      RefuelRoute[#RefuelRoute+1] = ToRefuelRoutePoint
      
      AIGroup:OptionROEHoldFire()
      AIGroup:OptionROTEvadeFire()
  
      local Tasks = {}
      Tasks[#Tasks+1] = AIGroup:TaskRefueling()
      Tasks[#Tasks+1] = AIGroup:TaskFunction( self:GetClassName() .. ".Resume", self )
      RefuelRoute[#RefuelRoute].task = AIGroup:TaskCombo( Tasks )
  
      AIGroup:Route( RefuelRoute, 0.5 )
    else
      self:RTB()
    end
  end

end
    


--- @param #AI_AIR self
function AI_AIR:onafterDead()
  self:SetStatusOff()
end


--- @param #AI_AIR self
-- @param Core.Event#EVENTDATA EventData
function AI_AIR:OnCrash( EventData )

  if self.Controllable:IsAlive() and EventData.IniDCSGroupName == self.Controllable:GetName() then
    self:E( self.Controllable:GetUnits() )
    if #self.Controllable:GetUnits() == 1 then
      self:__Crash( 1, EventData )
    end
  end
end

--- @param #AI_AIR self
-- @param Core.Event#EVENTDATA EventData
function AI_AIR:OnEjection( EventData )

  if self.Controllable:IsAlive() and EventData.IniDCSGroupName == self.Controllable:GetName() then
    self:__Eject( 1, EventData )
  end
end

--- @param #AI_AIR self
-- @param Core.Event#EVENTDATA EventData
function AI_AIR:OnPilotDead( EventData )

  if self.Controllable:IsAlive() and EventData.IniDCSGroupName == self.Controllable:GetName() then
    self:__PilotDead( 1, EventData )
  end
end
