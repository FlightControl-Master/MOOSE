-----------------------------------------------------------------------
-- MANTIS System
-----------------------------------------------------------------------
--
--- **MANTIS** - Moose derived  *M*odular, *A*utomatic and *N*etwork capable *T*argeting and *I*nterception *S*ystem
-- 
-- ===
-- 
-- MANTIS - Moose derived  Modular, Automatic and Network capable Targeting and Interception System
-- Controls a network of SAM sites. Use detection to switch on the AA site closest to the enemy
-- Leverage evasiveness from SEAD
-- Leverage attack range setup added by DCS in 11/20
-- 
-- ===
-- 
-- ## Missions:
--
-- ### [MANTIS - Modular, Automatic and Network capable Targeting and Interception System](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/MTS%20-%20Mantis/MTS-010%20-%20Basic%20Mantis%20Demo)
-- 
-- ===
-- 
-- ### Authors : **applevangelist **
-- 
-- @module Functional.Mantis
-- @image Functional.Mantis.jpg
-- Date: Dec 2020

-------------------------------------------------------------------------
--- **MANTIS** class, extends @{Core.Base#BASE}
-- @type MANTIS
-- @field #string Classname
-- @field #string name Name of this Mantis
-- @field #string SAM_Templates_Prefix Prefix to build the #GROUP_SET for SAM sites
-- @field @{Core.Set#GROUP_SET} SAM_Group The SAM #GROUP_SET
-- @field #string EWR_Templates_Prefix Prefix to build the #GROUP_SET for EWR group
-- @field @{Core.Set#GROUP_SET} EWR_Group The EWR #GROUP_SET
-- @field #string SEAD_Template_CC The ME name of the HQ object
-- @field @{Tasking.CommandCenter#COMMANDCENTER} SEAD_CC The #COMMANDCENTER object
-- @field #table SAM_Table Table of SAM sites
-- @field #string lid Prefix for logging
-- @field @{Functional.Detection#DETECTION_AREAS} Detection The #DETECTION_AREAS object
-- @field #boolean debug Switch on extra messages
-- @field #number checkradius Radius of the SAM sites
-- @field #number grouping Radius to group detected objects
-- @field #number acceptrange Radius of the EWR detection
-- @field #number detectinterval Interval in seconds for the target detection
-- @extends @{Core.Base#BASE}

--- *The worst thing that can happen to a good cause is, not to be skillfully attacked, but to be ineptly defended.* - Frédéric Bastiat 
-- 
-- Simple Class for a more intelligent Air Defense System
-- 
-- #MANTIS
-- Moose derived  Modular, Automatic and Network capable Targeting and Interception System.
-- Controls a network of SAM sites. Use detection to switch on the AA site closest to the enemy.
-- Leverage evasiveness from @{Functional.Sead#SEAD}.
-- Leverage attack range setup added by DCS in 11/20.
--
-- Set up your SAM sites in the mission editor. Name the groups with common prefix like "Red SAM".
-- Set up your EWR system in the mission editor. Name the groups with common prefix like "Red EWR". Can be e.g. AWACS or a combination of AWACS and Search Radars like e.g. EWR 1L13 etc.
-- [optional] Set up your HQ. Can be any group, e.g. a command vehicle.
-- 
-- Start up your MANTIS
-- 
--    `myredmantis = MANTIS:New("myredmantis","Red SAM","Red EWR",nil,"red",false)`
--    
-- [optional] Use  
--  + `MANTIS:SetEWRGrouping(radius)`  
--  + `MANTIS:SetEWRRange(radius)`  
--  + `MANTIS:SetSAMRadius(radius)`  
--  + `MANTIS:SetDetectInterval(interval)`   
-- to fine-tune your setup.
-- 
--    `myredmantis:Start()`
-- 
-- @field #MANTIS
MANTIS = {
  ClassName = "MANTIS",
  name  = "mymantis",
  SAM_Templates_Prefix = "",
  SAM_Group = nil,
  EWR_Templates_Prefix = "",
  EWR_Group = nil,
  SEAD_Template_CC = "",
  SEAD_CC = nil,
  SAM_Table = {},
  lid = "",
  Detection = nil,
  debug = false,
  checkradius = 25000,
  grouping = 5000,
  acceptrange = 80000,
  detectinterval = 30
}

do
  --- Function instantiate new class
  --@param #MANTIS self
  --@param #string name Name of this MANTIS for reporting
  --@param #string samprefix Prefixes for the SAM groups from the ME, e.g. all groups starting with "Red Sam..."
  --@param #string ewrprefix Prefixes for the EWR and AWACS groups from the ME, e.g. all groups starting with "Red EWR..."
  --@param #string hq Group name of your HQ (optional)
  --@param #string coaltion Coalition side of your setup, e.g. "blue", "red" or "neutral"
  --@param #boolean dynamic Use constant (true) filtering or just filer once (false, default)
  --@return #MANTIS self
  function MANTIS:New(name,samprefix,ewrprefix,hq,coaltion,dynamic)
    
    -- DONE: Create user functions for these
    -- TODO: Make HQ useful
    -- TODO: Set SAMs to auto if EWR dies

    self.name = name or "mymantis"
    self.SAM_Templates_Prefix = samprefix or "Red SAM"
    self.EWR_Templates_Prefix = ewrprefix or "Red EWR"
    self.SEAD_Template_CC = hq or nil
    self.Coalition = coaltion or "red"
    self.SAM_Table = {}
    self.dynamic = dynamic or false
    self.checkradius = 25000
    self.grouping = 5000
    self.acceptrange = 80000
    self.detectinterval = 30
    
    -- @field #string version
    self.version="0.2.2"
    env.info(string.format("***** Starting MANTIS Version %s *****", self.version))
    
    -- Set the string id for output to DCS.log file.
    self.lid=string.format("MANTIS %s | ", self.name)
  
    -- Debug trace.
    if self.debug then
      BASE:TraceOnOff(true)
      BASE:TraceClass(self.ClassName)
      --BASE:TraceClass("SEAD")
      BASE:TraceLevel(1)
    end
    
    if self.dynamic then
      -- Set SAM SET_GROUP
      self.SAM_Group = SET_GROUP:New():FilterPrefixes(self.SAM_Templates_Prefix):FilterCoalitions(self.Coalition):FilterStart()
      -- Set EWR SET_GROUP
      self.EWR_Group = SET_GROUP:New():FilterPrefixes({self.SAM_Templates_Prefix,self.EWR_Templates_Prefix}):FilterCoalitions(self.Coalition):FilterStart()
    else
      -- Set SAM SET_GROUP
      self.SAM_Group = SET_GROUP:New():FilterPrefixes(self.SAM_Templates_Prefix):FilterCoalitions(self.Coalition):FilterOnce()
      -- Set EWR SET_GROUP
      self.EWR_Group = SET_GROUP:New():FilterPrefixes({self.SAM_Templates_Prefix,self.EWR_Templates_Prefix}):FilterCoalitions(self.Coalition):FilterOnce()
    end
    
    -- set up CC
    if self.SEAD_Template_CC then
      self.SEAD_CC = COMMANDCENTER:New(GROUP:FindByName(self.SEAD_Template_CC),self.SEAD_Template_CC)
    end
    -- Inherit everything from BASE class.
    local self = BASE:Inherit(self, BASE:New()) -- #MANTIS
    
    return self    
  end

-----------------------------------------------------------------------
-- MANTIS helper functions
-----------------------------------------------------------------------  
  
  --- [internal] Function to get the self.SAM_Table
  -- @param #MANTIS self
  -- @return #table table  
  function MANTIS:_GetSAMTable()
    return self.SAM_Table
  end
  
  --- [internal] Function to set the self.SAM_Table
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:_SetSAMTable(table)
    self.SAM_Table = table
    return self
  end
 
  --- Function to set the grouping radius of the detection in meters
  -- @param #MANTIS self
  -- @param #number radius Radius upon which detected objects will be grouped
  function MANTIS:SetEWRGrouping(radius)
    local radius = radius or 5000
    self.grouping = radius
  end

  --- Function to set the detection radius of the EWR in meters
  -- @param #MANTIS self
  -- @param #number radius Radius of the EWR detection zone
  function MANTIS:SetEWRRange(radius)
    local radius = radius or 80000
    self.acceptrange = radius
  end
  
  --- Function to set switch-on/off zone for the SAM sites in meters
  -- @param #MANTIS self
  -- @param #number radius Radius of the firing zone  
  function MANTIS:SetSAMRadius(radius)
    local radius = radius or 25000
    self.checkradius = radius
  end
  
  --- Function to set switch-on/off the debug state
  -- @param #MANTIS self
  -- @param #boolean onoff Set true to switch on
  function MANTIS:Debug(onoff)
    local onoff = onoff or false
    self.debug = onoff
  end 
          
  --- Function to set the detection interval
  -- @param #MANTIS self
  -- @param #number interval The interval in seconds
  function MANTIS:SetDetectInterval(interval)
    local interval = interval or 30
    self.detectinterval = interval
  end    
     
  --- Function to check if any object is in the given SAM zone
  -- @param #MANTIS self
  -- @param #table dectset Table of coordinates of detected items
  -- @param samcoordinate Core.Point#COORDINATE Coordinate object.
  -- @return #boolean True if in any zone, else false
  function MANTIS:CheckObjectInZone(dectset, samcoordinate)
    self:F(self.lid.."CheckObjectInZone Called")
    -- check if non of the coordinate is in the given defense zone
    local radius = self.checkradius
    local set = dectset
    for _,_coord in pairs (set) do
      local coord = _coord  -- get current coord to check
      -- output for cross-check
      local dectstring = coord:ToStringLLDMS()
      local samstring = samcoordinate:ToStringLLDMS()
      local targetdistance = samcoordinate:DistanceFromPointVec2(coord)
      local text = string.format("Checking SAM at % s - Distance %d m - Target %s", samstring, targetdistance, dectstring)
      local m = MESSAGE:New(text,10,"Check"):ToAllIf(self.debug)
      -- end output to cross-check
      if targetdistance <= radius then
        return true
      end
    end
    return false
  end

  --- Function to start the detection via EWR groups
  -- @param #MANTIS self
  -- @return Functional.Detection #DETECTION_AREAS The running detection set
  function MANTIS:StartDetection()
    self:F(self.lid.."Starting Detection")
    
    -- start detection
    local groupset = self.EWR_Group
    local grouping = self.grouping or 5000
    local acceptrange = self.acceptrange or 80000
    local interval = self.detectinterval or 60
    
    --@param Functional.Detection #DETECTION_AREAS _MANTISdetection [internal] The MANTIS detection object
    _MANTISdetection = DETECTION_AREAS:New( groupset, grouping ) --[internal] Groups detected objects to 5000m zones
    _MANTISdetection:FilterCategories({ Unit.Category.AIRPLANE, Unit.Category.HELICOPTER })
    _MANTISdetection:SetAcceptRange(acceptrange)
    _MANTISdetection:SetRefreshTimeInterval(interval)
    _MANTISdetection:Start()
    
    function _MANTISdetection:OnAfterDetectedItem(From,Event,To,DetectedItem)
      --BASE:I( { From, Event, To, DetectedItem })
      if DetectedItem.IsDetected then
        local Coordinate = DetectedItem.Coordinate -- Core.Point#COORDINATE
        local text = "MANTIS: Detection at "..Coordinate:ToStringLLDMS()
        local m = MESSAGE:New(text,10,"MANTIS"):ToAllIf(self.debug)
      end
    end  
    return _MANTISdetection
  end
  
  --- Function to set the SAM start state
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:SetSAMStartState()
    self:F(self.lid.."Setting SAM Start States")
     -- get SAM Group
     local SAM_SET = self.SAM_Group
     local SAM_Grps = SAM_SET.Set --table of objects
     local SAM_Tbl = {} -- table of SAM defense zones
     local SEAD_Grps = {} -- table of SAM names to make evasive
     --cycle through groups and set alarm state etc
     for _i,_group in pairs (SAM_Grps) do
     --for i=1,#SAM_Grps do
        local group = _group
        group:OptionAlarmStateGreen()
        --group:OptionROEHoldFire()
        --group:SetAIOn()
        group:SetOption(AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION,75)  --engagement will be 75% of firing range
        if group:IsGround() then
          local grpname = group:GetName()
          local grpcoord = group:GetCoordinate()
          local grpzone = ZONE_UNIT:New(grpname,group:GetUnit(1),5000) -- defense zone around each SAM site 5000 meters
          table.insert( SAM_Tbl, {grpname, grpcoord, grpzone})
          table.insert( SEAD_Grps, grpname )
        end
     end
     self.SAM_Table = SAM_Tbl
     -- make SAMs evasive
     SEAD:New( SEAD_Grps )
     return self
  end
  
-----------------------------------------------------------------------
-- MANTIS main functions
-----------------------------------------------------------------------    
  
  --- Function to set the SAM start state
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:Start()
    self:F(self.lid.."Starting MANTIS")
    self:SetSAMStartState()
    self.Detection = self:StartDetection()

    local function check(detection)
      --get detected set
      local detset = detection:GetDetectedItemCoordinates()
      self:F("Check:", {detset})
      --[[report detections
      if self.debug then
        for _,_data in pairs (detset) do
          local coord = _data
          local text = "Target detect at "
          text = text..coord:ToStringLLDMS()
          m=MESSAGE:New(text,15,"MANTIS"):ToAllIf(self.debug)
        end --end for
      end --end if ]]
      -- switch SAMs on/off if (n)one of the detected groups is inside their reach
      local samset = self:_GetSAMTable() -- table of i.1=names, i.2=coordinates and i.3=zones of SAM sites
      for _,_data in pairs (samset) do
        local samcoordinate = _data[2]
        local name = _data[1]
        local samgroup = GROUP:FindByName(name)
        if self:CheckObjectInZone(detset, samcoordinate) then --check any target in zone
          if samgroup:IsAlive() then
            -- switch off SAM
            samgroup:OptionAlarmStateRed()
            --samgroup:OptionROEWeaponFree()
            --samgroup:SetAIOn()
            local text = string.format("SAM %s switched to alarm state RED!", name)
            local m=MESSAGE:New(text,15,"MANTIS"):ToAllIf(self.debug)
          end --end alive
        else 
          if samgroup:IsAlive() then
            -- switch off SAM
            samgroup:OptionAlarmStateGreen()
            --samgroup:OptionROEWeaponFree()
            --samgroup:SetAIOn()
            local text = string.format("SAM %s switched to alarm state GREEN!", name)
            local m=MESSAGE:New(text,15,"MANTIS"):ToAllIf(self.debug)
          end --end alive
        end --end check
      end --for for loop
    end --end function
    -- timer to run the system
    local interval = self.detectinterval
    self.MantisTimer = TIMER:New(check,self.Detection)
    self.MantisTimer:Start(5,interval,nil)
    return self
  end
  
  --- Function to stop MANTIS
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:Stop()
    if self.MantisTimer then
      self.MantisTimer:Stop()
    end
  return self        
  end
  
end
-----------------------------------------------------------------------
-- MANTIS end
-----------------------------------------------------------------------
