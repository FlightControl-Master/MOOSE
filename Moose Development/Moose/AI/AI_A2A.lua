--- **AI** -- (R2.2) - Models the process of air operations for airplanes.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===
-- 
-- @module AI.AI_A2A
-- @image AI_Air_To_Air_Dispatching.JPG

--BASE:TraceClass("AI_A2A")


--- @type AI_A2A
-- @extends Core.Fsm#FSM_CONTROLLABLE

--- The AI_A2A class implements the core functions to operate an AI @{Wrapper.Group} A2A tasking.
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
  
  self:SetFuelThreshold( .2, 60 )
  self:SetDamageThreshold( 0.4 )
  self:SetDisengageRadius( 70000 )

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

  self:AddTransition( "Patrolling", "Refuel", "Refuelling" ) 

  --- Refuel Handler OnBefore for AI_A2A
  -- @function [parent=#AI_A2A] OnBeforeRefuel
  -- @param #AI_A2A self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @return #boolean
  
  --- Refuel Handler OnAfter for AI_A2A
  -- @function [parent=#AI_A2A] OnAfterRefuel
  -- @param #AI_A2A self
  -- @param Wrapper.Controllable#CONTROLLABLE Controllable The Controllable Object managed by the FSM.
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  
  --- Refuel Trigger for AI_A2A
  -- @function [parent=#AI_A2A] Refuel
  -- @param #AI_A2A self
  
  --- Refuel Asynchronous Trigger for AI_A2A
  -- @function [parent=#AI_A2A] __Refuel
  -- @param #AI_A2A self
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
-- @param DCS#Speed  PatrolMinSpeed The minimum speed of the @{Wrapper.Controllable} in km/h.
-- @param DCS#Speed  PatrolMaxSpeed The maximum speed of the @{Wrapper.Controllable} in km/h.
-- @return #AI_A2A self
function AI_A2A:SetSpeed( PatrolMinSpeed, PatrolMaxSpeed )
  self:F2( { PatrolMinSpeed, PatrolMaxSpeed } )
  
  self.PatrolMinSpeed = PatrolMinSpeed
  self.PatrolMaxSpeed = PatrolMaxSpeed
end


--- Sets the floor and ceiling altitude of the patrol.
-- @param #AI_A2A self
-- @param DCS#Altitude PatrolFloorAltitude The lowest altitude in meters where to execute the patrol.
-- @param DCS#Altitude PatrolCeilingAltitude The highest altitude in meters where to execute the patrol.
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

--- Sets to refuel at the given tanker.
-- @param #AI_A2A self
-- @param Wrapper.Group#GROUP TankerName The group name of the tanker as defined within the Mission Editor or spawned.
-- @return #AI_A2A self
function AI_A2A:SetTanker( TankerName )
  self:F2( { TankerName } )
  
  self.TankerName = TankerName
end


--- Sets the disengage range, that when engaging a target beyond the specified range, the engagement will be cancelled and the plane will RTB.
-- @param #AI_A2A self
-- @param #number DisengageRadius The disengage range.
-- @return #AI_A2A self
function AI_A2A:SetDisengageRadius( DisengageRadius )
  self:F2( { DisengageRadius } )
  
  self.DisengageRadius = DisengageRadius
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
-- @param #number PatrolFuelThresholdPercentage The treshold in percentage (between 0 and 1) when the AIControllable is considered to get out of fuel.
-- @param #number PatrolOutOfFuelOrbitTime The amount of seconds the out of fuel AIControllable will orbit before returning to the base.
-- @return #AI_A2A self
function AI_A2A:SetFuelThreshold( PatrolFuelThresholdPercentage, PatrolOutOfFuelOrbitTime )

  self.PatrolFuelThresholdPercentage = PatrolFuelThresholdPercentage
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
-- @param #number PatrolDamageThreshold The treshold in percentage (between 0 and 1) when the AI is considered to be damaged.
-- @return #AI_A2A self
function AI_A2A:SetDamageThreshold( PatrolDamageThreshold )

  self.PatrolManageDamage = true
  self.PatrolDamageThreshold = PatrolDamageThreshold
  
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
      self:F({Fuel=Fuel, PatrolFuelThresholdPercentage=self.PatrolFuelThresholdPercentage})
      if Fuel < self.PatrolFuelThresholdPercentage then
        if self.TankerName then
          self:E( self.Controllable:GetName() .. " is out of fuel: " .. Fuel .. " ... Refuelling at Tanker!" )
          self:Refuel()
        else
          self:E( self.Controllable:GetName() .. " is out of fuel: " .. Fuel .. " ... RTB!" )
          local OldAIControllable = self.Controllable
          
          local OrbitTask = OldAIControllable:TaskOrbitCircle( math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude ), self.PatrolMinSpeed )
          local TimedOrbitTask = OldAIControllable:TaskControlled( OrbitTask, OldAIControllable:TaskCondition(nil,nil,nil,nil,self.PatrolOutOfFuelOrbitTime,nil ) )
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
function AI_A2A.RTBRoute( AIGroup, Fsm )

  AIGroup:F( { "AI_A2A.RTBRoute:", AIGroup:GetName() } )
  
  if AIGroup:IsAlive() then
    Fsm:__RTB( 0.5 )
  end
  
end

--- @param Wrapper.Group#GROUP AIGroup
function AI_A2A.RTBHold( AIGroup, Fsm )

  AIGroup:F( { "AI_A2A.RTBHold:", AIGroup:GetName() } )
  if AIGroup:IsAlive() then
    Fsm:__RTB( 0.5 )
    Fsm:Return()
    local Task = AIGroup:TaskOrbitCircle( 4000, 400 )
    AIGroup:SetTask( Task )
  end
  
end


--- @param #AI_A2A self
-- @param Wrapper.Group#GROUP AIGroup
function AI_A2A:onafterRTB( AIGroup, From, Event, To )
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
    Tasks[#Tasks+1] = AIGroup:TaskFunction( "AI_A2A.RTBRoute", self )
    EngageRoute[#EngageRoute].task = AIGroup:TaskCombo( Tasks )

    --- NOW ROUTE THE GROUP!
    AIGroup:Route( EngageRoute, 0.5 )
      
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
-- @param Wrapper.Group#GROUP AIGroup
function AI_A2A:onafterHold( AIGroup, From, Event, To, HoldTime )
  self:F( { AIGroup, From, Event, To } )

  self:E( "Group " .. self.Controllable:GetName() .. " ... Holding! ( " .. self:GetState() .. " )" )
  
  if AIGroup and AIGroup:IsAlive() then
    local OrbitTask = AIGroup:TaskOrbitCircle( math.random( self.PatrolFloorAltitude, self.PatrolCeilingAltitude ), self.PatrolMinSpeed )
    local TimedOrbitTask = AIGroup:TaskControlled( OrbitTask, AIGroup:TaskCondition( nil, nil, nil, nil, HoldTime , nil ) )
    
    local RTBTask = AIGroup:TaskFunction( "AI_A2A.RTBHold", self )
    
    local OrbitHoldTask = AIGroup:TaskOrbitCircle( 4000, self.PatrolMinSpeed )
    
    --AIGroup:SetState( AIGroup, "AI_A2A", self )
    
    AIGroup:SetTask( AIGroup:TaskCombo( { TimedOrbitTask, RTBTask, OrbitHoldTask } ), 1 )
  end

end

--- @param Wrapper.Group#GROUP AIGroup
function AI_A2A.Resume( AIGroup, Fsm )

  AIGroup:I( { "AI_A2A.Resume:", AIGroup:GetName() } )
  if AIGroup:IsAlive() then
    Fsm:__RTB( 0.5 )
  end
  
end

--- @param #AI_A2A self
-- @param Wrapper.Group#GROUP AIGroup
function AI_A2A:onafterRefuel( AIGroup, From, Event, To )
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
