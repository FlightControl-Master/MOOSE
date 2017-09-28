--- **Functional** -- The PROTECT class handles the protection of objects, which can be zones, units, scenery.
-- 
-- ===
-- 
-- ### Author: **Sven Van de Velde (FlightControl)**
-- ### Contributions: **MillerTime**
-- 
-- ====
-- 
-- @module Protect

--- @type PROTECT.__ Methods which are not intended for mission designers, but which are used interally by the moose designer :-)
-- @extends Core.Base#BASE

--- @type PROTECT
-- @extends #PROTECT.__

--- # PROTECT, extends @{Base#BASE}
-- 
-- @field #PROTECT
PROTECT = {
  ClassName = "PROTECT",
}

--- PROTECT constructor.
-- @param #PROTECT self
-- @param Core.Zone#ZONE ProtectZone A @{Zone} object to protect.
-- @return #PROTECT
-- @usage
--  -- Protect the zone
-- ProtectZone = PROTECT:New( ZONE:New( "Zone" ) )
-- 
function PROTECT:New( ProtectZone )

  local self = BASE:Inherit( self, FSM:New() ) -- #PROTECT

  self.ProtectZone = ProtectZone
  self.ProtectUnitSet = SET_UNIT:New()
  self.ProtectStaticSet = SET_STATIC:New()
  self.CaptureUnitSet = SET_UNIT:New()
  
  self:SetStartState( "Idle" )
  
  self:AddTransition( { "Idle", "Captured" }, "Protect", "Protecting" )
  
  self:AddTransition( "Protecting", "Check", "Protecting" )
  
  self:AddTransition( "Protecting", "Capture", "Captured" )
  
  self:AddTransition( { "Protecting", "Captured" }, "Leave", "Idle" )
  
  --self:ScheduleRepeat( 1, 5, 0, nil, self.CheckScheduler, self )
  
  return self

end  


--- Add a unit to the protection.
-- @param #PROTECT self
-- @param Wrapper.Unit#UNIT ProtectUnit A @{Unit} object to protect.
function PROTECT:AddProtectUnit( ProtectUnit )
  self.ProtectUnitSet:AddUnit( ProtectUnit )
end

--- Get the Protect unit Set.
-- @param #PROTECT self
-- @return Wrapper.Unit#UNIT The Set of capture units.
function PROTECT:GetProtectUnitSet()
  return self.ProtectUnitSet
end

--- Add a static to the protection.
-- @param #PROTECT self
-- @param Wrapper.Unit#UNIT ProtectStatic A @{Static} object to protect.
function PROTECT:AddProtectStatic( ProtectStatic )
  self.ProtectStaticSet:AddStatic( ProtectStatic )
end

--- Get the Protect static Set.
-- @param #PROTECT self
-- @return Wrapper.Unit#UNIT The Set of capture statics.
function PROTECT:GetProtectStaticSet()
  return self.ProtectStaticSet
end

--- Add a Capture unit to allow to capture the zone.
-- @param #PROTECT self
-- @param Wrapper.Unit#UNIT CaptureUnit A @{Unit} object to allow a capturing.
function PROTECT:AddCaptureUnit( CaptureUnit )
  self.CaptureUnitSet:AddUnit( CaptureUnit )
end

--- Get the Capture unit Set.
-- @param #PROTECT self
-- @return Wrapper.Unit#UNIT The Set of capture units.
function PROTECT:GetCaptureUnitSet()
  return self.CaptureUnitSet
end


--- Check if the units are still alive.
-- @param #PROTECT self
function PROTECT:AreProtectUnitsAlive()

  local IsAlive = false
  
  local UnitSet = self.ProtectUnitSet
  UnitSet:Flush()
  local UnitList = UnitSet:GetSet()
  
  for UnitID, ProtectUnit in pairs( UnitList ) do
    local IsUnitAlive = ProtectUnit:IsAlive()
    if IsUnitAlive == true then
      IsAlive = true
      break
    end
  end
  
  return IsAlive
end

--- Check if the statics are still alive.
-- @param #PROTECT self
function PROTECT:AreProtectStaticsAlive()

  local IsAlive = false
  
  local StaticSet = self.ProtectStaticSet
  StaticSet:Flush()
  local StaticList = StaticSet:GetSet()
  
  for UnitID, ProtectStatic in pairs( StaticList ) do
    local IsStaticAlive = ProtectStatic:IsAlive()
    if IsStaticAlive == true then
      IsAlive = true
      break
    end
  end
  
  return IsAlive
end


--- Check if there is a capture unit in the zone.
-- @param #PROTECT self
function PROTECT:IsCaptureUnitInZone()

  local CaptureUnitSet = self.CaptureUnitSet
  CaptureUnitSet:Flush()

  local IsInZone = self.CaptureUnitSet:IsPartiallyInZone( self.ProtectZone )
  
  self:E({IsInZone = IsInZone})
  
  return IsInZone
end

--- Smoke.
-- @param #PROTECT self
-- @param #SMOKECOLOR.Color SmokeColor
function PROTECT:Smoke( SmokeColor )
  self.ProtectZone:GetCoordinate():Smoke( SmokeColor )
end
  

function PROTECT:onafterProtect()

  self:Check()
end

function PROTECT:onafterCheck()
  
  if ( self.ProtectUnitSet and self:AreProtectUnitsAlive() ) or
     ( self.ProtectStaticSet and self:AreProtectStaticsAlive() ) or
     self:IsCaptureUnitInZone() == false then
    self:__Check( -1 )
  else
    self:Capture()
  end
  
end


