--- **Functional** -- Modular, Automatic and Network capable Targeting and Interception System for Air Defenses
-- 
-- ===
-- 
-- **MANTIS** - Moose derived  Modular, Automatic and Network capable Targeting and Interception System
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
-- ### Author : **applevangelist **
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
-- @field @{Wrapper.Group#GROUP} SEAD_CC The #GROUP object of the HQ
-- @field #table SAM_Table Table of SAM sites
-- @field #string lid Prefix for logging
-- @field @{Functional.Detection#DETECTION_AREAS} Detection The #DETECTION_AREAS object
-- @field #boolean debug Switch on extra messages
-- @field #boolean verbose Switch on extra logging
-- @field #number checkradius Radius of the SAM sites
-- @field #number grouping Radius to group detected objects
-- @field #number acceptrange Radius of the EWR detection
-- @field #number detectinterval Interval in seconds for the target detection
-- @field #number engagerange Firing engage range of the SAMs, see [https://wiki.hoggitworld.com/view/DCS_option_engagementRange]
-- @field #boolean autorelocate Relocate HQ and EWR groups in random intervals. Note: You need to select units for this which are *actually mobile*
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
--  * `MANTIS:SetEWRGrouping(radius)`  
--  * `MANTIS:SetEWRRange(radius)`  
--  * `MANTIS:SetSAMRadius(radius)`  
--  * `MANTIS:SetDetectInterval(interval)`
--  * `MANTIS:SetAutoRelocate(hq, ewr)`      
-- to fine-tune your setup.
-- 
--    `myredmantis:Start()`
--
--
-- @field #MANTIS
MANTIS = {
  ClassName             = "MANTIS",
  name                  = "mymantis",
  SAM_Templates_Prefix  = "",
  SAM_Group             = nil,
  EWR_Templates_Prefix  = "",
  EWR_Group             = nil,
  SEAD_Template_CC      = "",
  SEAD_CC               = nil,
  SAM_Table             = {},
  lid                   = "",
  Detection             = nil,
  debug                 = false,
  checkradius           = 25000,
  grouping              = 5000,
  acceptrange           = 80000,
  detectinterval        = 30,
  engagerange           = 75,
  autorelocate          = false,
  verbose               = false
}

-----------------------------------------------------------------------
-- MANTIS System
-----------------------------------------------------------------------

do
  --- Function instantiate new class
  --@param #MANTIS self
  --@param #string name Name of this MANTIS for reporting
  --@param #string samprefix Prefixes for the SAM groups from the ME, e.g. all groups starting with "Red Sam..."
  --@param #string ewrprefix Prefixes for the EWR and AWACS groups from the ME, e.g. all groups starting with "Red EWR..."
  --@param #string hq Group name of your HQ (optional)
  --@param #string coaltion Coalition side of your setup, e.g. "blue", "red" or "neutral"
  --@param #boolean dynamic Use constant (true) filtering or just filter once (false, default)
  --@return #MANTIS self
  function MANTIS:New(name,samprefix,ewrprefix,hq,coaltion,dynamic)
    
    -- TODO: Create some user functions for these
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
    self.engagerange = 75
    self.autorelocate = false
    self.autorelocateunits = { HQ = false, EWR = false}
    self.verbose = false
    
    -- @field #string version
    self.version="0.2.5"
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
      self.SEAD_CC = GROUP:FindByName(self.SEAD_Template_CC)
      --self.SEAD_CC = COMMANDCENTER:New(GROUP:FindByName(self.SEAD_Template_CC),self.SEAD_Template_CC)
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
  
  --- Function to set SAM firing engage range, 0-100 percent, e.g. 75
  -- @param #MANTIS self
  -- @param #number range Percent of the max fire range
  function MANTIS:SetSAMRadius(range)
    local range = range or 75
    if range < 0 or range > 100 then
      range = 75
    end
    self.engagerange = range
  end
  
  --- Function to set switch-on/off the debug state
  -- @param #MANTIS self
  -- @param #boolean onoff Set true to switch on
  function MANTIS:Debug(onoff)
    local onoff = onoff or false
    self.debug = onoff
  end
     
  --- Function to get the HQ object for further use
  -- @param #MANTIS self
  -- @return Wrapper.GROUP#GROUP The HQ #GROUP object or *nil* if it doesn't exist
  function MANTIS:GetCommandCenter()
    if self.SEAD_CC then
      return self.SEAD_CC
    else
      return nil      
    end   
  end
          
  --- Function to set the detection interval
  -- @param #MANTIS self
  -- @param #number interval The interval in seconds
  function MANTIS:SetDetectInterval(interval)
    local interval = interval or 30
    self.detectinterval = interval
  end  
  
  --- Function to set autorelocation for HQ and EWR objects. Note: Units must be actually mobile in DCS!
  -- @param #MANTIS self
  -- @param #boolean hq If true, will relocate HQ object
  -- @param #boolean ewr If true, will relocate  EWR objects
  function MANTIS:SetAutoRelocate(hq, ewr)
    self:F({hq, ewr})
    local hqrel = hq or false
    local ewrel = ewr or false
    if hqrel or ewrel then
      self.autorelocate = true
      self.autorelocateunits = { HQ = hqrel, EWR = ewrel }
      self:T({self.autorelocate, self.autorelocateunits})
    end
  end    
  
  --- [Internal] Function to execute the relocation
  -- @param #MANTIS self
  function MANTIS:_RelocateGroups()
    self:T(self.lid.." Relocating Groups")
    local text = self.lid.." Relocating Groups"
    local m= MESSAGE:New(text,15,"MANTIS",true):ToAllIf(self.debug)
    if self.verbose then env.info(text) end
    if self.autorelocate then
      -- relocate HQ
      if self.autorelocateunits.HQ and self.SEAD_CC then --only relocate if HQ exists
        local _hqgrp = self.SEAD_CC
        self:T(self.lid.." Relocating HQ")
        local text = self.lid.." Relocating HQ"
        local m= MESSAGE:New(text,15,"MANTIS"):ToAll()
        _hqgrp:RelocateGroundRandomInRadius(20,500,true,true)
      end
      --relocate EWR
      -- TODO: maybe dependent on AlarmState? Observed: SA11 SR only relocates if no objects in reach
      if self.autorelocateunits.EWR then
         -- get EWR Group
         local EWR_GRP = SET_GROUP:New():FilterPrefixes(self.EWR_Templates_Prefix):FilterCoalitions(self.Coalition):FilterOnce()
         local EWR_Grps = EWR_GRP.Set --table of objects in SET_GROUP
         for _,_grp in pairs (EWR_Grps) do
             if _grp:IsGround() then
              self:T(self.lid.." Relocating EWR ".._grp:GetName())
              local text = self.lid.." Relocating EWR ".._grp:GetName()
              local m= MESSAGE:New(text,15,"MANTIS"):ToAllIf(self.debug)
              if self.verbose then env.info(text) end
              _grp:RelocateGroundRandomInRadius(20,500,true,true)
             end
         end
      end
    end
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
      if self.verbose then env.info(self.lid..text) end
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
    _MANTISdetection = DETECTION_AREAS:New( groupset, grouping ) --[internal] Grouping detected objects to 5000m zones
    _MANTISdetection:FilterCategories({ Unit.Category.AIRPLANE, Unit.Category.HELICOPTER })
    _MANTISdetection:SetAcceptRange(acceptrange)
    _MANTISdetection:SetRefreshTimeInterval(interval)
    _MANTISdetection:Start()
    
    function _MANTISdetection:OnAfterDetectedItem(From,Event,To,DetectedItem)
      --BASE:I( { From, Event, To, DetectedItem })
      local debug = false
      if DetectedItem.IsDetected and debug then
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
     local engagerange = self.engagerange -- firing range in % of max
     --cycle through groups and set alarm state etc
     for _i,_group in pairs (SAM_Grps) do
     --for i=1,#SAM_Grps do
        local group = _group
        group:OptionAlarmStateGreen()
        --group:OptionROEHoldFire()
        --group:SetAIOn()
        group:SetOption(AI.Option.Ground.id.AC_ENGAGEMENT_RANGE_RESTRICTION,engagerange)  --engagement will be 75% of firing range
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
            if self.verbose then env.info(self.lid..text) end
          end --end alive
        else 
          if samgroup:IsAlive() then
            -- switch off SAM
            samgroup:OptionAlarmStateGreen()
            --samgroup:OptionROEWeaponFree()
            --samgroup:SetAIOn()
            local text = string.format("SAM %s switched to alarm state GREEN!", name)
            local m=MESSAGE:New(text,15,"MANTIS"):ToAllIf(self.debug)
            if self.verbose then env.info(self.lid..text) end
          end --end alive
        end --end check
      end --for for loop
    end --end function
    -- relocation relay function
    local function relocate()
      self:_RelocateGroups()
    end
    -- timer to run the system
    local interval = self.detectinterval
    self.MantisTimer = TIMER:New(check,self.Detection)
    self.MantisTimer:Start(5,interval,nil)
    -- relocate HQ and EWR
    local relointerval = math.random(1800,3600) -- random between 30 and 60 mins
    self.MantisReloTimer = TIMER:New(relocate)
    self.MantisReloTimer:Start(relointerval,relointerval,nil)
    return self
  end
  
  --- Function to stop MANTIS
  -- @param #MANTIS self
  -- @return #MANTIS self
  function MANTIS:Stop()
    if self.MantisTimer then
      self.MantisTimer:Stop()
    end
    if self.MantisReloTimer then
      self.MantisReloTimer:Stop()
    end
  return self        
  end
  
end
-----------------------------------------------------------------------
-- MANTIS end
-----------------------------------------------------------------------
