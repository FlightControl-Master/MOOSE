--- **Ops** - Strategic Zone.
--
-- **Main Features:**
--
--    * Monitor if zone is captured.
--
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- @module Ops.OpsZone
-- @image OPS_OpsZone.png


--- OPSZONE class.
-- @type OPSZONE
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @field Core.Zone#ZONE zone The zone.
-- @field #string zoneName Name of the zone.
-- @field #number ownerCurrent Coalition of the current owner of the zone.
-- @field #number ownerPrevious Coalition of the previous owner of the zone.
-- @field Core.Timer#TIMER timerStatus Timer for calling the status update.
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- # The OPSZONE Concept
--
-- An OPSZONE is a strategically important area.
--
--
-- @field #OPSZONE
OPSZONE = {
  ClassName      = "OPSZONE",
  verbose        =     3,
}


--- OPSZONE class version.
-- @field #string version
OPSZONE.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Can neutrals capture?
-- TODO: Can statics capture or hold a zone?
-- TODO: Differentiate between ground attack and boming by air or arty.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new OPSZONE class object.
-- @param #OPSZONE self
-- @param Core.Zone#ZONE Zone The zone.
-- @param #number CoalitionOwner Initial owner of the coaliton. Default `coalition.side.NEUTRAL`.
-- @return #OPSZONE self
function OPSZONE:New(Zone, CoalitionOwner)

  -- Inherit everything from LEGION class.
  local self=BASE:Inherit(self, FSM:New()) -- #OPSZONE
  
  -- Check if zone name instead of ZONE object was passed.
  if type(Zone)=="string" then
    Zone=ZONE:New(Zone)
  end
  
  -- Basic checks.
  if not Zone then
    self:E("ERROR: OPSZONE not found!")
    return nil  
  elseif not Zone:IsInstanceOf("ZONE_RADIUS") then
    self:E("ERROR: OPSZONE must be a SPHERICAL zone due to DCS restrictions!")
    return nil
  end
  
  self.zone=Zone
  self.zoneName=Zone:GetName()
  self.zoneRadius=Zone:GetRadius()
  
  self.ownerCurrent=CoalitionOwner or coalition.side.NEUTRAL
  self.ownerPrevious=CoalitionOwner or coalition.side.NEUTRAL

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("OPSZONE %s | ", Zone:GetName())

  -- FMS start state is PLANNED.
  self:SetStartState("Empty")
  

  -- Add FSM transitions.
  --                 From State    -->      Event       -->     To State
  self:AddTransition("*",                  "Start",             "*")           -- Start FSM.
  self:AddTransition("*",                  "Stop",              "*")           -- Start FSM.

  self:AddTransition("*",                  "Captured",          "Guarded")     -- Start FSM.
  self:AddTransition("*",                  "Empty",             "Empty")       -- Start FSM.
  
  self:AddTransition("*",                  "Attacked",          "Attacked")    -- A guarded zone is under attack.
  self:AddTransition("*",                  "Defeated",          "Guarded")     -- The owning coalition defeated an attack.


  self.timerStatus=TIMER:New(OPSZONE.Status, self)
    
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get current owner of the zone.
-- @param #OPSZONE self
-- @return #number Owner coalition.
function OPSZONE:GetOwner()
  return self.ownerCurrent
end

--- Get previous owner of the zone.
-- @param #OPSZONE self
-- @return #number Previous owner coalition.
function OPSZONE:GetPreviousOwner()
  return self.ownerPrevious
end


--- Check if the red coalition is currently owning the zone.
-- @param #OPSZONE self 
-- @return #boolean If `true`, zone is red.
function OPSZONE:IsRed()
  local is=self.ownerCurrent==coalition.side.RED
  return is
end

--- Check if the blue coalition is currently owning the zone.
-- @param #OPSZONE self 
-- @return #boolean If `true`, zone is blue.
function OPSZONE:IsBlue()
  local is=self.ownerCurrent==coalition.side.BLUE
  return is
end

--- Check if the neutral coalition is currently owning the zone.
-- @param #OPSZONE self 
-- @return #boolean If `true`, zone is neutral.
function OPSZONE:IsNeutral()
  local is=self.ownerCurrent==coalition.side.NEUTRAL
  return is
end

--- Check if zone is guarded.
-- @param #OPSZONE self 
-- @return #boolean If `true`, zone is guarded.
function OPSZONE:IsEmpty()
  local is=self:is("Guarded")
  return is
end

--- Check if zone is empty.
-- @param #OPSZONE self 
-- @return #boolean If `true`, zone is empty.
function OPSZONE:IsEmpty()
  local is=self:is("Empty")
  return is
end

--- Check if zone is being attacked by the opposite coalition.
-- @param #OPSZONE self 
-- @return #boolean If `true`, zone is being attacked.
function OPSZONE:IsAttacked()
  local is=self:is("Attacked")
  return is
end

--- Check if zone is contested. Contested here means red *and* blue units are present in the zone.
-- @param #OPSZONE self 
-- @return #boolean If `true`, zone is contested.
function OPSZONE:IsContested()
  return self.isContested
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start OPSZONE FSM.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSZONE:onafterStart(From, Event, To)

  -- Info.
  self:I(self.lid..string.format("Starting OPSZONE v%s", OPSZONE.version))
  
  -- Status update.
  self.timerStatus:Start(1, 60)
  
end

--- Update status.
-- @param #OPSZONE self
function OPSZONE:Status()

  -- Current FSM state.
  local fsmstate=self:GetState()

  -- Info message.
  local text=string.format("State %s: Owner %d (previous %d), contested=%s, Nunits: red=%d, blue=%d, neutral=%d", fsmstate, self.ownerCurrent, self.ownerPrevious, tostring(self:IsContested()), 0, 0, 0)
  self:I(self.lid..text)

  -- Scanning zone.
  self:Scan()
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FSM Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after "Captured" event.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number NewOwnerCoalition Coalition of the new owner.
function OPSZONE:onafterCaptured(From, Event, To, NewOwnerCoalition)

  -- Debug info.
  self:I(self.lid..string.format("Zone captured by %d coalition", NewOwnerCoalition))
  
  self.ownerPrevious=self.ownerCurrent
  self.ownerCurrent=NewOwnerCoalition
  
end

--- On after "Empty" event.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSZONE:onafterEmpty(From, Event, To)

  -- Debug info.
  self:I(self.lid..string.format("Zone is empty now"))
  
end

--- On after "Attacked" event.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number AttackerCoalition Coalition of the attacking ground troops.
function OPSZONE:onafterAttacked(From, Event, To, AttackerCoalition)

  -- Debug info.
  self:I(self.lid..string.format("Zone is being attacked by coalition %s!", tostring(AttackerCoalition)))
  
  -- Time stam when the attack started.
  self.Tattacked=timer.getAbsTime()
  
end


--- On after "Empty" event.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSZONE:onafterEmpty(From, Event, To)

  -- Debug info.
  self:I(self.lid..string.format("Zone is empty now"))
  
end

--- On after "Defeated" event.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSZONE:onafterDefeated(From, Event, To)

  -- Debug info.
  self:I(self.lid..string.format("Attack on zone has been defeated"))
  
  -- Not attacked any more.
  self.Tattacked=nil
  
end

--- On enter "Guarded" state.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSZONE:onenterGuarded(From, Event, To)

  -- Debug info.
  self:I(self.lid..string.format("Zone is guarded"))

  self.Tattacked=nil

end

--- On enter "Guarded" state.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSZONE:onenterAttacked(From, Event, To)

  -- Debug info.
  self:I(self.lid..string.format("Zone is Attacked"))

  self.Tattacked=nil

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Scan Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Add a platoon to the brigade.
-- @param #OPSZONE self
-- @return #OPSZONE self
function OPSZONE:Scan()

  -- Debug info.
  local text=string.format("Scanning zone %s R=%.1f m", self.zone:GetName(), self.zone:GetRadius())
  self:I(self.lid..text)

  -- Search.
  local SphereSearch={id=world.VolumeType.SPHERE, params={point=self.zone:GetVec3(), radius=self.zone:GetRadius(),}}

  local ObjectCategories={Object.Category.UNIT, Object.Category.STATIC}
  
  local Nred=0
  local Nblu=0
  local Nnut=0

  --- Function to evaluate the world search
  local function EvaluateZone(_ZoneObject)
  
    local ZoneObject=_ZoneObject --DCS#Object
    
    if ZoneObject then

      -- Object category.
      local ObjectCategory=ZoneObject:getCategory()

      if ObjectCategory==Object.Category.UNIT and ZoneObject:isExist() and ZoneObject:isActive() then
      
        ---
        -- UNIT
        ---
      
        local DCSUnit=ZoneObject --DCS#Unit
        
        --TODO: only ground units!
        
        local Coalition=DCSUnit:getCoalition()
        
        if Coalition==coalition.side.RED then
          Nred=Nred+1
        elseif Coalition==coalition.side.BLUE then
          Nblu=Nblu+1
        elseif Coalition==coalition.side.NEUTRAL then
          Nnut=Nnut+1
        end
        
        local unit=UNIT:Find(DCSUnit)
        
        env.info(string.format("FF found unit %s", unit:GetName()))
        
      
      elseif ObjectCategory==Object.Category.STATIC and ZoneObject:isExist() then

        ---
        -- STATIC
        ---
      
        local DCSStatic=ZoneObject --DCS#Static
        
        -- CAREFUL! Downed pilots break routine here without any error thrown.
        local unit=STATIC:Find(DCSStatic)
        
        --env.info(string.format("FF found static %s", unit:GetName()))
      
      elseif ObjectCategory==Object.Category.SCENERY then
      
        ---
        -- SCENERY
        ---      
      
        local SceneryType = ZoneObject:getTypeName()
        local SceneryName = ZoneObject:getName()
        
        local Scenery=SCENERY:Register(SceneryName, ZoneObject)
        
        env.info(string.format("FF found scenery type=%s, name=%s", SceneryType, SceneryName))
      end

    end

    return true
  end

  -- Search objects.
  world.searchObjects(ObjectCategories, SphereSearch, EvaluateZone)
  
  -- Debug info.
  local text=string.format("Scan result Nred=%d, Nblue=%d, Nneutrl=%d", Nred, Nblu, Nnut)
  self:I(self.lid..text)
  
  if self:IsRed() then
  
    ---
    -- RED zone
    ---
  
    if Nred==0 then
    
      -- No red units in red zone any more.
    
      if Nblu>0 then
        -- Blue captured red zone.
        self:Captured(coalition.side.BLUE)
      elseif Nnut>0 and self.neutralCanCapture then
        -- Neutral captured red zone.
        self:Captured(coalition.side.NEUTRAL)
      else
        -- Red zone is now empty (but will remain red).
        self:Empty()    
      end
      
    else
    
      -- Still red units in red zone.
      
      if Nblu>0 then
      
        if not self:IsAttacked() then
          self:Attacked(coalition.side.BLUE)
        end
        
      elseif Nblu==0 then
      
        if self:IsAttacked() and self:IsContested() then
          self:Defeated(coalition.side.BLUE)
        end
      
      end
      
    end
    
    -- Contested by blue?
    if Nblu==0 then
      self.isContested=false
    else  
      self.isContested=true
    end
    
  elseif self:IsBlue() then

    ---
    -- BLUE zone
    ---

    if Nblu==0 then
    
      -- No blue units in blue zone any more.
    
      if Nred>0 then
        -- Red captured blue zone.
        self:Captured(coalition.side.RED)
      elseif Nnut>0 and self.neutralCanCapture then
        -- Neutral captured blue zone.
        self:Captured(coalition.side.NEUTRAL)
      else
        -- Blue zone is empty now.
        self:Empty()    
      end

    else
    
      -- Still blue units in blue zone.
      
      if Nred>0 then
      
        if not self:IsAttacked() then
          -- Red is attacking blue zone.
          self:Attacked(coalition.side.RED)
        end
        
      elseif Nred==0 then
      
        if self:IsAttacked() and self:IsContested() then
          -- Blue defeated read attack.
          self:Defeated(coalition.side.RED)
        end

      end
      
    end
    
    -- Contested by red?
    if Nred==0 then
      self.isContested=false
    else  
      self.isContested=true
    end
  
  elseif self:IsNeutral() then

    ---
    -- NEUTRAL zone
    ---

    -- Not checked as neutrals cant capture (for now).
    --if Nnut==0 then 
    
      -- No neutral units in neutral zone any more.

      if Nred>0 and Nblu>0 then
        env.info("FF neutrals left neutral zone and red and blue are present! What to do?")
        -- TODO Contested!
        self:Attacked()
        self.isContested=true
      elseif Nred>0 then
        -- Red captured neutral zone.
        self:Captured(coalition.side.RED)
      elseif Nblu>0 then
        -- Blue captured neutral zone.
        self:Captured(coalition.side.BLUE)
      else
        -- Neutral zone is empty now.
        if not self:IsEmpty() then
          self:Emtpy()
        end
      end
      
    --end
  
  else
    env.info("FF error")
  end

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DCS Event Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Monitor hit events.
-- @param #OPSZONE self
-- @param Core.Event#EVENTDATA EventData The event data.
function OPSZONE:OnEventHit(EventData)

  if self.HitsOn then

    local UnitHit = EventData.TgtUnit
    
    -- Check if unit is inside the capture zone and that it is of the defending coalition.
    if UnitHit and UnitHit:IsInZone(self) and UnitHit:GetCoalition()==self.ownerCurrent then
    
      -- Update last hit time.
      self.HitTimeLast=timer.getTime()
      
      -- Only trigger attacked event if not already in state "Attacked".
      if not self:IsAttacked() then
        self:T3(self.lid.."Hit ==> Attack")
        self:Attacked()
      end
      
    end

  end

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
