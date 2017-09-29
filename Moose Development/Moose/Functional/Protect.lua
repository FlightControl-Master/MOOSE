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
-- @extends Core.Fsm#FSM

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

  self.ProtectZone = ProtectZone -- Core.Zone#ZONE
  self.ProtectUnitSet = SET_UNIT:New()
  self.ProtectStaticSet = SET_STATIC:New()
  self.CaptureUnitSet = SET_UNIT:New()
  
  self:SetStartState( "-" )
  
  self:AddTransition( "-", "Start", "Protected" )
  
  self:AddTransition( { "Captured", "Attacked", "Empty" }, "Protected", "Protected" )
  
  self:AddTransition( { "Protected", "Attacked" }, "Empty", "Empty" )
  
  self:AddTransition( { "Protected", "Empty" }, "Attacked", "Attacked" )

  self:AddTransition( { "Protected", "Attacked", "Empty" }, "Captured", "Captured" )
  
  
  self:SetCoalition( Coalition )
  
  self.SmokeTime = nil
  
  return self

end  


--- Get the ProtectZone
-- @param #PROTECT self
-- @return Core.Zone#ZONE_BASE
function PROTECT:GetProtectZone()
  return self.ProtectZone
end


--- Get the name of the ProtectZone
-- @param #PROTECT self
-- @return #string
function PROTECT:GetProtectZoneName()
  return self.ProtectZone:GetName()
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

  local IsProtected = self.ProtectZone:IsAllInZoneOfCoalition( self.Coalition )
  self:E( { IsProtected = IsProtected } )
  return IsProtected
end

function PROTECT:IsCaptured()

  local IsCaptured = self.ProtectZone:IsAllInZoneOfOtherCoalition( self.Coalition )
  self:E( { IsCaptured = IsCaptured } )
  return IsCaptured
end


function PROTECT:IsAttacked()

  local IsAttacked = self.ProtectZone:IsSomeInZoneOfCoalition( self.Coalition )
  self:E( { IsAttacked = IsAttacked } )
  return IsAttacked
end


function PROTECT:IsEmpty()

  local IsEmpty = self.ProtectZone:IsNoneInZone()
  self:E( { IsEmpty = IsEmpty } )
  return IsEmpty
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

  self.SmokeColor = SmokeColor
end
  

--- Flare.
-- @param #PROTECT self
-- @param #SMOKECOLOR.Color FlareColor
function PROTECT:Flare( FlareColor )
  self.ProtectZone:FlareZone( FlareColor, math.random( 1, 360 ) )
end
  

--- Mark.
-- @param #PROTECT self
function PROTECT:Mark()

  local Coord = self.ProtectZone:GetCoordinate()
  local ZoneName = self:GetProtectZoneName()
  local State = self:GetState()
  
  if self.MarkRed and self.MarkBlue then
    self:E( { MarkRed = self.MarkRed, MarkBlue = self.MarkBlue } )
    Coord:RemoveMark( self.MarkRed )
    Coord:RemoveMark( self.MarkBlue )
  end
  
  if self.Coalition == coalition.side.BLUE then
    self.MarkBlue = Coord:MarkToCoalitionBlue( "Protect Zone: " .. ZoneName .. "\nStatus: " .. State )  
    self.MarkRed = Coord:MarkToCoalitionRed( "Capture Zone: " .. ZoneName .. "\nStatus: " .. State )  
  else
    self.MarkRed = Coord:MarkToCoalitionRed( "Protect Zone: " .. ZoneName .. "\nStatus: " .. State )  
    self.MarkBlue = Coord:MarkToCoalitionBlue( "Capture Zone: " .. ZoneName .. "\nStatus: " .. State )  
  end
end


--- Bound.
-- @param #PROTECT self
function PROTECT:onafterStart()

  self:ScheduleRepeat( 5, 15, 0.1, nil, self.StatusCoalition, self )
  self:ScheduleRepeat( 5, 15, 0.1, nil, self.StatusZone, self )
  self:ScheduleRepeat( 10, 15, 0, nil, self.StatusSmoke, self )
end

--- Bound.
-- @param #PROTECT self
function PROTECT:onenterProtected()


  if self.Coalition == coalition.side.BLUE then
    --elf.ProtectZone:BoundZone( 12, country.id.USA )
  else
    --self.ProtectZone:BoundZone( 12, country.id.RUSSIA )
  end
  
  self:Mark()
  
end

function PROTECT:onenterCaptured()

  local NewCoalition = self.ProtectZone:GetCoalition()
  self:E( { NewCoalition = NewCoalition } )
  self:SetCoalition( NewCoalition )

  self:Mark()
end


function PROTECT:onenterEmpty()

  self:Mark()
end


function PROTECT:onenterAttacked()

  self:Mark()
end


--- Check status Coalition ownership.
-- @param #PROTECT self
function PROTECT:StatusCoalition()

  self:E( { State = self:GetState() } )
  
  self.ProtectZone:Scan()

  if self:IsProtected() then
    self:Protected()
  else
    if self:IsCaptured() then  
      self:Captured()
    end
  end
end

--- Check status Zone.
-- @param #PROTECT self
function PROTECT:StatusZone()
  
  self:E( { State = self:GetState() } )

  self.ProtectZone:Scan()

  if self:IsAttacked() then
    self:Attacked()
  else
    if self:IsEmpty() then  
      self:Empty()
    end
  end
end

--- Check status Smoke.
-- @param #PROTECT self
function PROTECT:StatusSmoke()
  
  local CurrentTime = timer.getTime()

  if self.SmokeTime == nil or self.SmokeTime + 300 <= CurrentTime then
    if self.SmokeColor then
      self.ProtectZone:GetCoordinate():Smoke( self.SmokeColor )
      --self.SmokeColor = nil
      self.SmokeTime = CurrentTime
    end
  end
end



