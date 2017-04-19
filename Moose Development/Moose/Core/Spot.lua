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
    self:AddTransition( "On" , "LaseOff", "Off" )
  
    self.Recce = Recce
  
    self.LaseScheduler = SCHEDULER:New( self )
  
    self:SetEventPriority( 5 )
  
    return self
  end
  
  --- @param #SPOT self
  -- @param From
  -- @param Event
  -- @param To
  -- @param Core.Point#POINT_VEC3 PointVec3
  -- @param #number LaserCode
  -- @param #number Duration
  function SPOT:onafterLaseOn( From, Event, To, PointVec3, LaserCode, Duration )

    local function StopLase( self )
      self:LaseOff()
    end
  
    local RecceDcsUnit = self.Recce:GetDCSObject()
    local TargetVec3 = PointVec3:GetVec3()
    self:E("lasing")
    self.Spot = Spot.createInfraRed( RecceDcsUnit, { x = 0, y = 2, z = 0 }, TargetVec3, LaserCode )
    if Duration then
      self.ScheduleID = self.LaseScheduler:Schedule( self, StopLase, {self}, Duration )
    end
  end

  --- @param #SPOT self
  -- @param From
  -- @param Event
  -- @param To
  function SPOT:onafterLaseOff( From, Event, To )
  
    self.Spot:destroy()
    self.Spot = nil
    if self.ScheduleID then
      self.LaseScheduler:Stop(self.ScheduleID)
    end
    self.ScheduleID = nil
  end
end