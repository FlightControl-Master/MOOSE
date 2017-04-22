--- **Core  (Release 2.1)** -- Management of SPOT logistics, that can be transported from and to transportation carriers.
--
-- ![Banner Image](..\Presentations\SPOT\Dia1.JPG)
--
-- ===
-- 
-- Spot lases points endlessly or for a duration.
--
-- ====
-- 
-- # Demo Missions
-- 
-- ### [SPOT Demo Missions source code]()
-- 
-- ### [SPOT Demo Missions, only for beta testers]()
--
-- ### [ALL Demo Missions pack of the last release](https://github.com/FlightControl-Master/MOOSE_MISSIONS/releases)
-- 
-- ====
-- 
-- # YouTube Channel
-- 
-- ### [SPOT YouTube Channel]()
-- 
-- ====
-- 
-- This module is still under construction, but is described above works already, and will keep working ...
-- 
-- @module Spot


do

  --- @type SPOT
  -- @extends Core.Base#BASE


  --- 
  -- @field #SPOT
  SPOT = {
    ClassName = "SPOT",
  }
  
  --- SPOT Constructor.
  -- @param #SPOT self
  -- @param Wrapper.Unit#UNIT Recce
  -- @param #number LaserCode
  -- @param #number Duration
  -- @return #SPOT
  function SPOT:New( Recce )
  
    local self = BASE:Inherit( self, FSM:New() ) -- #SPOT
    self:F( { Type, Name, Weight } )
    
    self:SetStartState( "Off" )
    self:AddTransition( "Off", "LaseOn", "On" )
    
    --- LaseOn Handler OnBefore for SPOT
    -- @function [parent=#SPOT] OnBeforeLaseOn
    -- @param #SPOT self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- LaseOn Handler OnAfter for SPOT
    -- @function [parent=#SPOT] OnAfterLaseOn
    -- @param #SPOT self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- LaseOn Trigger for SPOT
    -- @function [parent=#SPOT] LaseOn
    -- @param #SPOT self
    
    --- LaseOn Asynchronous Trigger for SPOT
    -- @function [parent=#SPOT] __LaseOn
    -- @param #SPOT self
    -- @param #number Delay
    
    
    
    self:AddTransition( "On",  "Lasing", "On" )
    self:AddTransition( "On" , "LaseOff", "Off" )
    
    --- LaseOff Handler OnBefore for SPOT
    -- @function [parent=#SPOT] OnBeforeLaseOff
    -- @param #SPOT self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    -- @return #boolean
    
    --- LaseOff Handler OnAfter for SPOT
    -- @function [parent=#SPOT] OnAfterLaseOff
    -- @param #SPOT self
    -- @param #string From
    -- @param #string Event
    -- @param #string To
    
    --- LaseOff Trigger for SPOT
    -- @function [parent=#SPOT] LaseOff
    -- @param #SPOT self
    
    --- LaseOff Asynchronous Trigger for SPOT
    -- @function [parent=#SPOT] __LaseOff
    -- @param #SPOT self
    -- @param #number Delay
    
    
  
    self.Recce = Recce
  
    self.LaseScheduler = SCHEDULER:New( self )
  
    self:SetEventPriority( 5 )
  
    return self
  end
  
  --- @param #SPOT self
  -- @param From
  -- @param Event
  -- @param To
  -- @param Wrapper.Positionable#POSITIONABLE Target
  -- @param #number LaserCode
  -- @param #number Duration
  function SPOT:onafterLaseOn( From, Event, To, Target, LaserCode, Duration )

    local function StopLase( self )
      self:LaseOff()
    end
    
    self.Target = Target
    self.LaserCode = LaserCode
    
    local RecceDcsUnit = self.Recce:GetDCSObject()
    
    self.Spot = Spot.createInfraRed( RecceDcsUnit, { x = 0, y = 2, z = 0 }, Target:GetPointVec3():AddY(1):GetVec3() )
    self.Spot = Spot.createLaser( RecceDcsUnit, { x = 0, y = 2, z = 0 }, Target:GetPointVec3():AddY(1):GetVec3(), LaserCode )

    if Duration then
      self.ScheduleID = self.LaseScheduler:Schedule( self, StopLase, {self}, Duration )
    end
    
    self:HandleEvent( EVENTS.Dead )
    
    self:__Lasing( -0.2 )
  end
  
  --- @param #SPOT self
  -- @param Core.Event#EVENTDATA EventData
  function SPOT:OnEventDead(EventData)
    if self.Target then
      if EventData.IniDCSUnitName == self.Target:GetName() then
        self:E( {"Target dead ", self.Target:GetName() } )
        self:__LaseOff( 0.1 )
      end
    end
  end
  
  --- @param #SPOT self
  -- @param From
  -- @param Event
  -- @param To
  function SPOT:onafterLasing( From, Event, To )
  
    if self.Target:IsAlive() then
      self.Spot:setPoint( self.Target:GetPointVec3():AddY(1):GetVec3() )
      self:__Lasing( -0.2 )
    else
      self:__LaseOff( 0.2 )
    end
  
  end

  --- @param #SPOT self
  -- @param From
  -- @param Event
  -- @param To
  -- @return #SPOT
  function SPOT:onafterLaseOff( From, Event, To )
  
    self:E( {"Stopped lasing for ", self.Target:GetName() } )
    self.Spot:destroy()
    self.Spot = nil
    if self.ScheduleID then
      self.LaseScheduler:Stop(self.ScheduleID)
    end
    self.ScheduleID = nil
    
    self.Target = nil
    
    return self
  end
  
  --- Check if the SPOT is lasing
  -- @param #SPOT self
  -- @return #boolean true if it is lasing
  function SPOT:IsLasing()
    self:F2()
  
    local Lasing = false
    
    if self.Spot then
      Lasing = true
    end
  
    return Lasing
  end
  
end