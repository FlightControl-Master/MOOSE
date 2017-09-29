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
-- @param DCSCoalition.DCSCoalition#coalition Coalition The initial coalition owning the zone.
-- @return #PROTECT
-- @usage
--  -- Protect the zone
-- ProtectZone = PROTECT:New( ZONE:New( "Zone" ) )
-- 
function PROTECT:New( ProtectZone, Coalition )

  local self = BASE:Inherit( self, FSM:New() ) -- #PROTECT

  self.ProtectZone = ProtectZone
  self.ProtectUnitSet = SET_UNIT:New()
  self.ProtectStaticSet = SET_STATIC:New()
  self.CaptureUnitSet = SET_UNIT:New()
  
  self:SetStartState( "-" )
  
  self:AddTransition( { "-", "Protected", "Captured" }, "Protected", "Protected" )
  
  self:AddTransition( { "Protected", "Attacked" }, "Destroyed", "Destroyed" )
  
  self:AddTransition( { "Protected", "Destroyed" }, "Attacked", "Attacked" )

  self:AddTransition( { "Protected", "Attacked", "Destroyed" }, "Captured", "Captured" )
  
  self:ScheduleRepeat( 60, 60, 0, nil, self.Status, self )
  
  self:SetCoalition( Coalition )
  
  self:__Protected( 5 )
  
  return self

end  

--- Set the owning coalition of the zone.
-- @param #PROTECT self
-- @param DCSCoalition.DCSCoalition#coalition Coalition
function PROTECT:SetCoalition( Coalition )
  self.Coalition = Coalition
end


--- Get the owning coalition of the zone.
-- @param #PROTECT self
-- @return DCSCoalition.DCSCoalition#coalition Coalition
function PROTECT:GetCoalition()
  return self.Coalition
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


function PROTECT:IsProtected()

  local IsAllCoalition = self.ProtectZone:IsAllInZoneOfCoalition( self.Coalition )
  self:E( { IsAllCoalition = IsAllCoalition } )
  return IsAllCoalition
end

function PROTECT:IsCaptured()

  local IsCaptured = self.ProtectZone:IsAllInZoneOfOtherCoalition( self.Coalition )
  self:E( { IsCaptured = IsCaptured } )
  return IsCaptured
end


function PROTECT:IsAttacked()

  local IsSomeCoalition = self.ProtectZone:IsSomeInZoneOfCoalition( self.Coalition )
  self:E( { IsSomeCoalition = IsSomeCoalition } )
  return IsSomeCoalition
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
  

function PROTECT:onenterCaptured()

  local NewCoalition = self.ProtectZone:GetCoalition()
  self:E( { NewCoalition = NewCoalition } )
  self:SetCoalition( NewCoalition )
end

--- Check status ProtectZone.
-- @param #PROTECT self
function PROTECT:Status()
  
  self.ProtectZone:Scan()

  if self:IsProtected() then
    self:Protected()
  else
    if self:IsAttacked() then
      self:Attacked()
    else
      if self:IsCaptured() then  
        self:Captured()
      end
    end
  end
end


