--- **Ops** - Strategic Zone.
--
-- **Main Features:**
--
--    * Monitor if a zone is captured.
--    * Monitor if an airbase is captured.
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
-- @field #string lid DCS log ID string.
-- @field #number verbose Verbosity of output.
-- @field Core.Zone#ZONE zone The zone.
-- @field Wrapper.Airbase#AIRBASE airbase The airbase that is monitored.
-- @field #string airbaseName Name of the airbase that is monitored.
-- @field #string zoneName Name of the zone.
-- @field #number zoneRadius Radius of the zone in meters.
-- @field #number ownerCurrent Coalition of the current owner of the zone.
-- @field #number ownerPrevious Coalition of the previous owner of the zone.
-- @field Core.Timer#TIMER timerStatus Timer for calling the status update.
-- @field #number Nred Number of red units in the zone.
-- @field #number Nblu Number of blue units in the zone.
-- @field #number Nnut Number of neutral units in the zone.
-- @field #table ObjectCategories Object categories for the scan.
-- @field #table UnitCategories Unit categories for the scan.
-- @field #number Tattacked Abs. mission time stamp when an attack was started.
-- @field #number dTCapture Time interval in seconds until a zone is captured.
-- @field #boolean neutralCanCapture Neutral units can capture. Default `false`.
-- @field #boolean drawZone If `true`, draw the zone on the F10 map.
-- @field #boolean markZone If `true`, mark the zone on the F10 map.
-- @field Wrapper.Marker#MARKER marker Marker on the F10 map.
-- @field #string markerText Text shown in the maker.
-- @field #table chiefs Chiefs that monitor this zone.
-- @field #table Missions Missions that are attached to this OpsZone
-- @extends Core.Fsm#FSM

--- Be surprised!
--
-- ===
--
-- # The OPSZONE Concept
--
-- An OPSZONE is a strategically important area.
--
-- **Restrictions**
--
-- * Since we are using a DCS routine that scans a zone for units or other objects present in the zone and this DCS routine is limited to cicular zones, only those can be used.
--
-- @field #OPSZONE
OPSZONE = {
  ClassName      = "OPSZONE",
  verbose        =     0,
  Nred           =     0,
  Nblu           =     0,
  Nnut           =     0,
  chiefs         =    {},
  Missions       =    {},
}

--- OPSZONE.MISSION
-- @type OPSZONE.MISSION
-- @field #number Coalition Coalition
-- @field #string Type Type of mission
-- @field Ops.Auftrag#AUFTRAG Mission The actual attached mission

--- OPSZONE class version.
-- @field #string version
OPSZONE.version="0.2.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Pause/unpause evaluations.
-- TODO: Capture time, i.e. time how long a single coalition has to be inside the zone to capture it.
-- DONE: Can neutrals capture? No, since they are _neutral_!
-- TODO: Differentiate between ground attack and boming by air or arty.
-- DONE: Capture airbases.
-- DONE: Can statics capture or hold a zone? No, unless explicitly requested by mission designer.

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
  if Zone then
    if type(Zone)=="string" then
      -- Convert string into a ZONE or ZONE_AIRBASE    
      local Name=Zone      
      Zone=ZONE:New(Name)
      if not Zone then
        local airbase=AIRBASE:FindByName(Name)
        if airbase then
          Zone=ZONE_AIRBASE:New(Name, 2000)
        end
      end
      if not Zone then
        self:E(string.format("ERROR: No ZONE or ZONE_AIRBASE found for name: %s", Name))
        return nil
      end
    end
  else
    self:E("ERROR: First parameter Zone is nil in OPSZONE:New(Zone) call!")
    return nil    
  end
  
  -- Basic checks.
  if Zone:IsInstanceOf("ZONE_AIRBASE") then
    self.airbase=Zone._.ZoneAirbase
    self.airbaseName=self.airbase:GetName()
  elseif Zone:IsInstanceOf("ZONE_RADIUS") then
    -- Nothing to do.
  else  
    self:E("ERROR: OPSZONE must be a SPHERICAL zone due to DCS restrictions!")
    return nil
  end

  -- Set some string id for output to DCS.log file.
  self.lid=string.format("OPSZONE %s | ", Zone:GetName())

  -- Set some values.  
  self.zone=Zone
  self.zoneName=Zone:GetName()
  self.zoneRadius=Zone:GetRadius()
  self.Missions = {}
  
  -- Current and previous owners.
  self.ownerCurrent=CoalitionOwner or coalition.side.NEUTRAL
  self.ownerPrevious=CoalitionOwner or coalition.side.NEUTRAL
  
  -- Contested.
  self.isContested=false
  
  -- We take the airbase coalition.
  if self.airbase then
    self.ownerCurrent=self.airbase:GetCoalition()
    self.ownerPrevious=self.airbase:GetCoalition()
  end
  
  -- Set object categories.
  self:SetObjectCategories()
  self:SetUnitCategories()
  
  -- Draw zone. Default is on.
  self:SetDrawZone()
  self:SetMarkZone(true)
  
  -- Status timer.
  self.timerStatus=TIMER:New(OPSZONE.Status, self)


  -- FMS start state is EMPTY.
  self:SetStartState("Stopped")
  
  -- Add FSM transitions.
  --                 From State    -->      Event       -->     To State
  self:AddTransition("Stopped",            "Start",             "Empty")       -- Start FSM.
  self:AddTransition("*",                  "Stop",              "Stopped")     -- Stop FSM.

  self:AddTransition("*",                  "Captured",          "Guarded")     -- Zone was captured.
  
  self:AddTransition("Empty",              "Guarded",           "Guarded")     -- Owning coalition left the zone and returned.
  
  self:AddTransition("*",                  "Empty",             "Empty")       -- No red or blue units inside the zone.
   
  self:AddTransition("*",                  "Attacked",          "Attacked")    -- A guarded zone is under attack.
  self:AddTransition("*",                  "Defeated",          "Guarded")     -- The owning coalition defeated an attack.

  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start".
  -- @function [parent=#OPSZONE] Start
  -- @param #OPSZONE self

  --- Triggers the FSM event "Start" after a delay.
  -- @function [parent=#OPSZONE] __Start
  -- @param #OPSZONE self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Stop".
  -- @param #OPSZONE self

  --- Triggers the FSM event "Stop" after a delay.
  -- @function [parent=#OPSZONE] __Stop
  -- @param #OPSZONE self
  -- @param #number delay Delay in seconds.


  --- Triggers the FSM event "Captured".
  -- @function [parent=#OPSZONE] Captured
  -- @param #OPSZONE self
  -- @param #number Coalition Coalition side that captured the zone.

  --- Triggers the FSM event "Captured" after a delay.
  -- @function [parent=#OPSZONE] __Captured
  -- @param #OPSZONE self
  -- @param #number delay Delay in seconds.
  -- @param #number Coalition Coalition side that captured the zone.

  --- On after "Captured" event.
  -- @function [parent=#OPSZONE] OnAfterCaptured
  -- @param #OPSZONE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #number Coalition Coalition side that captured the zone.


  --- Triggers the FSM event "Guarded".
  -- @function [parent=#OPSZONE] Guarded
  -- @param #OPSZONE self

  --- Triggers the FSM event "Guarded" after a delay.
  -- @function [parent=#OPSZONE] __Guarded
  -- @param #OPSZONE self
  -- @param #number delay Delay in seconds.

  --- On after "Guarded" event.
  -- @function [parent=#OPSZONE] OnAfterGuarded
  -- @param #OPSZONE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.  


  --- Triggers the FSM event "Empty".
  -- @function [parent=#OPSZONE] Empty
  -- @param #OPSZONE self

  --- Triggers the FSM event "Empty" after a delay.
  -- @function [parent=#OPSZONE] __Empty
  -- @param #OPSZONE self
  -- @param #number delay Delay in seconds.

  --- On after "Empty" event.
  -- @function [parent=#OPSZONE] OnAfterEmpty
  -- @param #OPSZONE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.  


  --- Triggers the FSM event "Attacked".
  -- @function [parent=#OPSZONE] Attacked
  -- @param #OPSZONE self
  -- @param #number AttackerCoalition Coalition side that is attacking the zone.

  --- Triggers the FSM event "Attacked" after a delay.
  -- @function [parent=#OPSZONE] __Attacked
  -- @param #OPSZONE self
  -- @param #number delay Delay in seconds.
  -- @param #number AttackerCoalition Coalition side that is attacking the zone.

  --- On after "Attacked" event.
  -- @function [parent=#OPSZONE] OnAfterAttacked
  -- @param #OPSZONE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #number AttackerCoalition Coalition side that is attacking the zone.


  --- Triggers the FSM event "Defeated".
  -- @function [parent=#OPSZONE] Defeated
  -- @param #OPSZONE self
  -- @param #number DefeatedCoalition Coalition side that was defeated.

  --- Triggers the FSM event "Defeated" after a delay.
  -- @function [parent=#OPSZONE] __Defeated
  -- @param #OPSZONE self
  -- @param #number delay Delay in seconds.
  -- @param #number DefeatedCoalition Coalition side that was defeated.

  --- On after "Defeated" event.
  -- @function [parent=#OPSZONE] OnAfterDefeated
  -- @param #OPSZONE self
  -- @param #string From From state.
  -- @param #string Event Event.
  -- @param #string To To state.
  -- @param #number DefeatedCoalition Coalition side that was defeated.
    
  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set verbosity level.
-- @param #OPSZONE self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #OPSZONE self
function OPSZONE:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Set categories of objects that can capture or hold the zone.
-- 
-- * Default is {Object.Category.UNIT} so only units can capture and hold zones.
-- * Set to `{Object.Category.UNIT, Object.Category.STATIC}` if static objects can capture and hold zones
-- 
-- Which units can capture zones can be further refined by `:SetUnitCategories()`.
-- 
-- @param #OPSZONE self
-- @param #table Categories Object categories. Default is `{Object.Category.UNIT}`.
-- @return #OPSZONE self
function OPSZONE:SetObjectCategories(Categories)

  -- Ensure table if something was passed.
  if Categories and type(Categories)~="table" then
    Categories={Categories}
  end 

  -- Set categories.
  self.ObjectCategories=Categories or {Object.Category.UNIT, Object.Category.STATIC}
  
  return self
end

--- Set categories of units that can capture or hold the zone. See [DCS Class Unit](https://wiki.hoggitworld.com/view/DCS_Class_Unit).
-- @param #OPSZONE self
-- @param #table Categories Table of unit categories. Default `{Unit.Category.GROUND_UNIT}`.
-- @return #OPSZONE
function OPSZONE:SetUnitCategories(Categories)

  -- Ensure table.
  if Categories and type(Categories)~="table" then
    Categories={Categories}
  end
  
  -- Set categories.
  self.UnitCategories=Categories or {Unit.Category.GROUND_UNIT}
  
  return self
end

--- Set whether *neutral* units can capture the zone.
-- @param #OPSZONE self
-- @param #boolean CanCapture If `true`, neutral units can.
-- @return #OPSZONE self
function OPSZONE:SetNeutralCanCapture(CanCapture)
  self.neutralCanCapture=CanCapture
  return self
end

--- Set if zone is drawn on the F10 map. Color will change depending on current owning coalition.
-- @param #OPSZONE self
-- @param #boolean Switch If `true` or `nil`, draw zone. If `false`, zone is not drawn.
-- @return #OPSZONE self
function OPSZONE:SetDrawZone(Switch)
  if Switch==false then
    self.drawZone=false
  else
    self.drawZone=true
  end
  return self
end

--- Set if a marker on the F10 map shows the current zone status.
-- @param #OPSZONE self
-- @param #boolean Switch If `true`, zone is marked. If `false` or `nil`, zone is not marked.
-- @param #boolean ReadOnly If `true` or `nil` then mark is read only.
-- @return #OPSZONE self
function OPSZONE:SetMarkZone(Switch, ReadOnly)
  if Switch then
    self.markZone=true
    local Coordinate=self:GetCoordinate()
    self.markerText=self:_GetMarkerText()
    self.marker=self.marker or MARKER:New(Coordinate, self.markerText)
    if ReadOnly==false then
      self.marker.readonly=false
    else
      self.marker.readonly=true
    end    
    self.marker:ToAll()
  else
    if self.marker then
      self.marker:Remove()
    end
    self.marker=nil
    --self.marker=false
  end
  return self
end


--- Get current owner of the zone.
-- @param #OPSZONE self
-- @return #number Owner coalition.
function OPSZONE:GetOwner()
  return self.ownerCurrent
end

--- Get coordinate of zone.
-- @param #OPSZONE self
-- @return Core.Point#COORDINATE Coordinate of the zone.
function OPSZONE:GetCoordinate()
  local coordinate=self.zone:GetCoordinate()
  return coordinate
end

--- Get name.
-- @param #OPSZONE self
-- @return #string Name of the zone.
function OPSZONE:GetName()
  return self.zoneName
end

--- Get previous owner of the zone.
-- @param #OPSZONE self
-- @return #number Previous owner coalition.
function OPSZONE:GetPreviousOwner()
  return self.ownerPrevious
end

--- Get duration of the current attack.
-- @param #OPSZONE self
-- @return #number Duration in seconds since when the last attack began. Is `nil` if the zone is not under attack currently.
function OPSZONE:GetAttackDuration()
  if self:IsAttacked() and self.Tattacked then
    
    local dT=timer.getAbsTime()-self.Tattacked
    return dT
  end

  return nil
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
function OPSZONE:IsGuarded()
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

--- Check if FMS is stopped.
-- @param #OPSZONE self 
-- @return #boolean If `true`, FSM is stopped
function OPSZONE:IsStopped()
  local is=self:is("Stopped")
  return is
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start/Stop Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Start OPSZONE FSM.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSZONE:onafterStart(From, Event, To)

  -- Info.
  self:I(self.lid..string.format("Starting OPSZONE v%s", OPSZONE.version))
  
  -- Reinit the timer.
  self.timerStatus=self.timerStatus or TIMER:New(OPSZONE.Status, self)
  
  -- Status update.
  self.timerStatus:Start(1, 120)
  
  -- Handle base captured event.
  if self.airbase then
    self:HandleEvent(EVENTS.BaseCaptured)
  end
  
end

--- Stop OPSZONE FSM.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSZONE:onafterStop(From, Event, To)

  -- Info.
  self:I(self.lid..string.format("Stopping OPSZONE"))
  
  -- Reinit the timer.
  self.timerStatus:Stop()
  
  -- Unhandle events.
  self:UnHandleEvent(EVENTS.BaseCaptured)
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Status Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Update status.
-- @param #OPSZONE self
function OPSZONE:Status()

  -- Current FSM state.
  local fsmstate=self:GetState()
  
  -- Get contested.
  local contested=tostring(self:IsContested())

  -- Info message.
  if self.verbose>=1 then
    local text=string.format("State %s: Owner %d (previous %d), contested=%s, Nunits: red=%d, blue=%d, neutral=%d", fsmstate, self.ownerCurrent, self.ownerPrevious, contested, self.Nred, self.Nblu, self.Nnut)
    self:I(self.lid..text)
  end

  -- Scanning zone.
  self:Scan()
  
  -- Evaluate the scan result.
  self:EvaluateZone()
   
  -- Update F10 marker (only if enabled).
  self:_UpdateMarker()
  
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
  self:T(self.lid..string.format("Zone captured by coalition=%d", NewOwnerCoalition))
  
  -- Set owners.
  self.ownerPrevious=self.ownerCurrent
  self.ownerCurrent=NewOwnerCoalition

  for _,_chief in pairs(self.chiefs) do
    local chief=_chief --Ops.Chief#CHIEF
    if chief.coalition==self.ownerCurrent then
      chief:ZoneCaptured(self)
    else
      chief:ZoneLost(self)
    end
  end
    
end

--- On after "Empty" event.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSZONE:onafterEmpty(From, Event, To)

  -- Debug info.
  self:T(self.lid..string.format("Zone is empty EVENT"))

  -- Inform chief.
  for _,_chief in pairs(self.chiefs) do
    local chief=_chief --Ops.Chief#CHIEF  
    chief:ZoneEmpty(self)
  end
  
end

--- On after "Attacked" event.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number AttackerCoalition Coalition of the attacking ground troops.
function OPSZONE:onafterAttacked(From, Event, To, AttackerCoalition)

  -- Debug info.
  self:T(self.lid..string.format("Zone is being attacked by coalition=%s!", tostring(AttackerCoalition)))

  -- Inform chief.
  if AttackerCoalition then
    for _,_chief in pairs(self.chiefs) do
      local chief=_chief --Ops.Chief#CHIEF
      if chief.coalition~=AttackerCoalition then
        chief:ZoneAttacked(self)
      end
    end
  end
  
end

--- On after "Defeated" event.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #number DefeatedCoalition Coalition side that was defeated.
function OPSZONE:onafterDefeated(From, Event, To, DefeatedCoalition)

  -- Debug info.
  self:T(self.lid..string.format("Defeated attack on zone by coalition=%d", DefeatedCoalition))
  
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
  self:T(self.lid..string.format("Zone is guarded"))

  -- Not attacked any more.
  self.Tattacked=nil

  if self.drawZone then
    self.zone:UndrawZone()
    
    local color=self:_GetZoneColor()
    
    self.zone:DrawZone(nil, color, 1.0, color, 0.5)
  end

end

--- On enter "Attacked" state.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSZONE:onenterAttacked(From, Event, To)

  -- Debug info.
  self:T(self.lid..string.format("Zone is Attacked"))

  -- Time stamp when the attack started.
  self.Tattacked=timer.getAbsTime()

  -- Draw zone?
  if self.drawZone then
    self.zone:UndrawZone()
    
    -- Color.
    local color={1, 204/255, 204/255}
    
    -- Draw zone.
    self.zone:DrawZone(nil, color, 1.0, color, 0.5)
  end
  
  self:_CleanMissionTable()
end

--- On enter "Empty" event.
-- @param #OPSZONE self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function OPSZONE:onenterEmpty(From, Event, To)

  -- Debug info.
  self:T(self.lid..string.format("Zone is empty now"))

  if self.drawZone then
    self.zone:UndrawZone()
    
    local color=self:_GetZoneColor()
    
    self.zone:DrawZone(nil, color, 1.0, color, 0.2)
  end
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Scan Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Scan zone.
-- @param #OPSZONE self
-- @return #OPSZONE self
function OPSZONE:Scan()

  -- Debug info.
  if self.verbose>=3 then
    local text=string.format("Scanning zone %s R=%.1f m", self.zoneName, self.zoneRadius)
    self:I(self.lid..text)
  end

  -- Search.
  local SphereSearch={id=world.VolumeType.SPHERE, params={point=self.zone:GetVec3(), radius=self.zoneRadius}}

  -- Init number of red, blue and neutral units.  
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
      
        -- This is a DCS unit object.
        local DCSUnit=ZoneObject --DCS#Unit
        
        --- Function to check if unit category is included.
        local function Included()
          
          if not self.UnitCategories then
            -- Any unit is included.
            return true
          else
            -- Check if found object is in specified categories.
            local CategoryDCSUnit = ZoneObject:getDesc().category
  
            for _,UnitCategory in pairs(self.UnitCategories) do
              if UnitCategory==CategoryDCSUnit then
                return true
              end
            end
  
          end
          
          return false
        end
        

        if Included() then
        
          -- Get Coalition.
          local Coalition=DCSUnit:getCoalition()
          
          -- Increase counter.
          if Coalition==coalition.side.RED then
            Nred=Nred+1
          elseif Coalition==coalition.side.BLUE then
            Nblu=Nblu+1
          elseif Coalition==coalition.side.NEUTRAL then
            Nnut=Nnut+1
          end
          
          -- Debug info.
          if self.verbose>=4 then
            self:I(self.lid..string.format("Found unit %s (coalition=%d)", DCSUnit:getName(), Coalition))
          end
        end
              
      elseif ObjectCategory==Object.Category.STATIC and ZoneObject:isExist() then

        ---
        -- STATIC
        ---
      
        -- This is a DCS static object.
        local DCSStatic=ZoneObject --DCS#Static
        
        -- Get coalition.
        local Coalition=DCSStatic:getCoalition()
        
        -- CAREFUL! Downed pilots break routine here without any error thrown.
        --local unit=STATIC:Find(DCSStatic)

        -- Increase counter.
        if Coalition==coalition.side.RED then
          Nred=Nred+1
        elseif Coalition==coalition.side.BLUE then
          Nblu=Nblu+1
        elseif Coalition==coalition.side.NEUTRAL then
          Nnut=Nnut+1
        end
        
        -- Debug info
        if self.verbose>=4 then        
          self:I(self.lid..string.format("Found static %s (coalition=%d)", DCSStatic:getName(), Coalition))
        end
      
      elseif ObjectCategory==Object.Category.SCENERY then
      
        ---
        -- SCENERY
        ---      
      
        local SceneryType = ZoneObject:getTypeName()
        local SceneryName = ZoneObject:getName()
        
        -- Debug info.
        self:T2(self.lid..string.format("Found scenery type=%s, name=%s", SceneryType, SceneryName))
      end

    end

    return true
  end

  -- Search objects.
  world.searchObjects(self.ObjectCategories, SphereSearch, EvaluateZone)
  
  -- Debug info.
  if self.verbose>=3 then
    local text=string.format("Scan result Nred=%d, Nblue=%d, Nneutral=%d", Nred, Nblu, Nnut)
    self:I(self.lid..text)
  end
  
  -- Set values.
  self.Nred=Nred
  self.Nblu=Nblu
  self.Nnut=Nnut

  return self
end

--- Evaluate zone.
-- @param #OPSZONE self
-- @return #OPSZONE self
function OPSZONE:EvaluateZone()

  -- Set values.
  local Nred=self.Nred
  local Nblu=self.Nblu
  local Nnut=self.Nnut

  if self:IsRed() then
  
    ---
    -- RED zone
    ---
  
    if Nred==0 then
    
      -- No red units in red zone any more.
    
      if Nblu>0 then
        -- Blue captured red zone.
        if not self.airbase then
          self:Captured(coalition.side.BLUE)
        end
      elseif Nnut>0 and self.neutralCanCapture then
        -- Neutral captured red zone.
        if not self.airbase then
          self:Captured(coalition.side.NEUTRAL)
        end
      else
        -- Red zone is now empty (but will remain red).
        if not self:IsEmpty() then
          self:Empty()
        end    
      end
      
    else
    
      -- Red units in red zone.
      
      if Nblu>0 then
      
        if not self:IsAttacked() then
          self:Attacked(coalition.side.BLUE)
        end
        
      elseif Nblu==0 then
      
        if self:IsAttacked() and self:IsContested() then
          self:Defeated(coalition.side.BLUE)
        elseif self:IsEmpty() then
          -- Red units left zone and returned (or from initial Empty state).
          self:Guarded()
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
        if not self.airbase then
          self:Captured(coalition.side.RED)
        end
      elseif Nnut>0 and self.neutralCanCapture then
        -- Neutral captured blue zone.
        if not self.airbase then
          self:Captured(coalition.side.NEUTRAL)
        end
      else
        -- Blue zone is empty now.
        if not self:IsEmpty() then
          self:Empty()
        end
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
        elseif self:IsEmpty() then
          -- Blue units left zone and returned (or from initial Empty state).
          self:Guarded()          
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
        self:T(self.lid.."FF neutrals left neutral zone and red and blue are present! What to do?")
        if not self:IsAttacked() then
          self:Attacked()
        end
        self.isContested=true
      elseif Nred>0 then
        -- Red captured neutral zone.
        if not self.airbase then
          self:Captured(coalition.side.RED)
        end
      elseif Nblu>0 then
        -- Blue captured neutral zone.
        if not self.airbase then
          self:Captured(coalition.side.BLUE)
        end
      else
        -- Neutral zone is empty now.
        if not self:IsEmpty() then
          self:Empty()
        end
      end
      
    --end
  
  else
    self:E(self.lid.."ERROR: Unknown coaliton!")
  end


  -- Finally, check airbase coalition
  if self.airbase then

    -- Current coalition.
    local airbasecoalition=self.airbase:GetCoalition()
    
    if airbasecoalition~=self.ownerCurrent then
      self:T(self.lid..string.format("Captured airbase %s: Coaltion %d-->%d", self.airbaseName, self.ownerCurrent, airbasecoalition))
      self:Captured(airbasecoalition)
    end
  
  end

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

--- Monitor base captured events.
-- @param #OPSZONE self
-- @param Core.Event#EVENTDATA EventData The event data.
function OPSZONE:OnEventBaseCaptured(EventData)

  if EventData and EventData.Place and self.airbase and self.airbaseName then

    -- Place is the airbase that was captured.
    local airbase=EventData.Place --Wrapper.Airbase#AIRBASE

    -- Check that this airbase belongs or did belong to this warehouse.
    if EventData.PlaceName==self.airbaseName then
    
      -- New coalition of the airbase
      local CoalitionNew=airbase:GetCoalition()

      -- Debug info.      
      self:I(self.lid..string.format("EVENT BASE CAPTURED: New coalition of airbase %s: %d [previous=%d]", self.airbaseName, CoalitionNew, self.ownerCurrent))
      
      -- Check that coalition actually changed.
      if CoalitionNew~=self.ownerCurrent then
        self:Captured(CoalitionNew)
      end
    
    end
    
  end  

end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Get RGB color of zone depending on current owner.
-- @param #OPSZONE self
-- @return #table RGB color.
function OPSZONE:_GetZoneColor()

  local color={0,0,0}
  
  if self.ownerCurrent==coalition.side.NEUTRAL then
    color={1, 1, 1}
  elseif self.ownerCurrent==coalition.side.BLUE then
    color={0, 0, 1}
  elseif self.ownerCurrent==coalition.side.RED then
    color={1, 0, 0}
  else
  
  end

  return color
end

--- Update marker on the F10 map.
-- @param #OPSZONE self
function OPSZONE:_UpdateMarker()

  if self.markZone then
  
    -- Get marker text.
    local text=self:_GetMarkerText()
    
    -- Chck if marker text changed and if so, update the marker.
    if text~=self.markerText then
      self.markerText=text
      self.marker:UpdateText(self.markerText)
    end
    
    --TODO: Update position if changed.
  
  end

end

--- Get marker text
-- @param #OPSZONE self
-- @return #string Marker text.
function OPSZONE:_GetMarkerText()

  local owner=UTILS.GetCoalitionName(self.ownerCurrent)
  local prevowner=UTILS.GetCoalitionName(self.ownerPrevious)

  -- Get marker text.
  local text=string.format("%s: Owner=%s [%s]\nState=%s [Contested=%s]\nBlue=%d, Red=%d, Neutral=%d", 
  self.zoneName, owner, prevowner, self:GetState(), tostring(self:IsContested()), self.Nblu, self.Nred, self.Nnut)
  
  return text
end

--- Add a chief that monitors this zone. Chief will be informed about capturing etc.
-- @param #OPSZONE self
-- @param Ops.Chief#CHIEF Chief The chief.
-- @return #table RGB color.
function OPSZONE:_AddChief(Chief)

  -- Add chief.
  table.insert(self.chiefs, Chief)

end

--- Add an entry to the OpsZone mission table
-- @param #OPSZONE self
-- @param #number Coalition Coalition of type e.g. coalition.side.NEUTRAL
-- @param #string Type Type of mission, e.g. AUFTRAG.Type.CAS
-- @param Ops.Auftrag#AUFTRAG Auftrag The Auftrag itself
-- @return #OPSZONE self
function OPSZONE:_AddMission(Coalition,Type,Auftrag)
  
  -- Add a mission
  local entry = {} -- #OPSZONE.MISSION
  entry.Coalition = Coalition or coalition.side.NEUTRAL
  entry.Type = Type or ""
  entry.Mission = Auftrag or nil
  
  table.insert(self.Missions,entry)
  
  return self
end

--- Get the OpsZone mission table. #table of #OPSZONE.MISSION entries
-- @param #OPSZONE self
-- @return #table Missions
function OPSZONE:_GetMissions()
  return self.Missions
end

--- Add an entry to the OpsZone mission table
-- @param #OPSZONE self
-- @param #number Coalition Coalition of type e.g. coalition.side.NEUTRAL
-- @param #string Type Type of mission, e.g. AUFTRAG.Type.CAS
-- @return #boolean found True if we have that kind of mission, else false
-- @return #table Missions Table of Ops.Auftrag#AUFTRAG entries
function OPSZONE:_FindMissions(Coalition,Type)
  -- search the table
  local foundmissions = {}
  local found = false
  for _,_entry in pairs(self.Missions) do
    local entry = _entry -- #OPSZONE.MISSION
    if entry.Coalition == Coalition and entry.Type == Type and entry.Mission and entry.Mission:IsNotOver() then
      table.insert(foundmissions,entry.Mission)
      found = true
    end
  end
  return found, foundmissions
end

--- Housekeeping
-- @param #OPSZONE self
-- @return #OPSZONE self
function OPSZONE:_CleanMissionTable()
  local missions = {}
  for _,_entry in pairs(self.Missions) do
    local entry = _entry -- #OPSZONE.MISSION
    if entry.Mission and entry.Mission:IsNotOver() then
      table.insert(missions,entry)
    end
  end
  self.Missions = missions
  return self
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
