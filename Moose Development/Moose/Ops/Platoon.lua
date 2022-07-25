--- **Ops** - Brigade Platoon.
--
-- **Main Features:**
--
--    * Set parameters like livery, skill valid for all platoon members.
--    * Define modex and callsigns.
--    * Define mission types, this platoon can perform (see Ops.Auftrag#AUFTRAG).
--    * Pause/unpause platoon operations.
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Platoon
-- @image OPS_Platoon.png


--- PLATOON class.
-- @type PLATOON
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field Ops.OpsGroup#OPSGROUP.WeaponData weaponData Weapon data table with key=BitType.
-- @extends Ops.Cohort#COHORT

--- *Some cool cohort quote* -- Known Author
--
-- ===
--
-- # The PLATOON Concept
-- 
-- A PLATOON is essential part of an BRIGADE.
--
--
--
-- @field #PLATOON
PLATOON = {
  ClassName      = "PLATOON",
  verbose        =     0,
  weaponData     =    {},
}

--- PLATOON class version.
-- @field #string version
PLATOON.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new PLATOON object and start the FSM.
-- @param #PLATOON self
-- @param #string TemplateGroupName Name of the template group.
-- @param #number Ngroups Number of asset groups of this platoon. Default 3.
-- @param #string PlatoonName Name of the platoon. Must be **unique**!
-- @return #PLATOON self
function PLATOON:New(TemplateGroupName, Ngroups, PlatoonName)

  -- Inherit everything from COHORT class.
  local self=BASE:Inherit(self, COHORT:New(TemplateGroupName, Ngroups, PlatoonName)) -- #PLATOON
  
  -- All platoons get mission type Nothing.
  self:AddMissionCapability(AUFTRAG.Type.NOTHING, 50)
  
  -- Is ground.
  self.isGround=true

  -- Get ammo.
  self.ammo=self:_CheckAmmo()

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  -- TODO: Platoon specific user functions.

--- Set brigade of this platoon.
-- @param #PLATOON self
-- @param Ops.Brigade#BRIGADE Brigade The brigade.
-- @return #PLATOON self
function PLATOON:SetBrigade(Brigade)
  self.legion=Brigade
  return self
end

--- Get brigade of this platoon.
-- @param #PLATOON self
-- @return Ops.Brigade#BRIGADE The brigade.
function PLATOON:GetBrigade()
  return self.legion
end
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--[[
--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #PLATOON self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function PLATOON:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting %s v%s %s", self.ClassName, self.version, self.name)
  self:I(self.lid..text)

  -- Start the status monitoring.
  self:__Status(-1)
end
]]

--- On after "Status" event.
-- @param #PLATOON self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function PLATOON:onafterStatus(From, Event, To)

  if self.verbose>=1 then

    -- FSM state.
    local fsmstate=self:GetState()
  
    local callsign=self.callsignName and UTILS.GetCallsignName(self.callsignName) or "N/A"
    local skill=self.skill and tostring(self.skill) or "N/A"
    
    local NassetsTot=#self.assets
    local NassetsInS=self:CountAssets(true)
    local NassetsQP=0 ; local NassetsP=0 ; local NassetsQ=0  
    if self.legion then
      NassetsQP, NassetsP, NassetsQ=self.legion:CountAssetsOnMission(nil, self)
    end
    
    -- Short info.
    local text=string.format("%s [Type=%s, Call=%s, Skill=%s]: Assets Total=%d, Stock=%d, Mission=%d [Active=%d, Queue=%d]", 
    fsmstate, self.aircrafttype, callsign, skill, NassetsTot, NassetsInS, NassetsQP, NassetsP, NassetsQ)
    self:T(self.lid..text)
    
    -- Weapon data info.
    if self.verbose>=3 and self.weaponData then
      local text="Weapon Data:"
      for bit,_weapondata in pairs(self.weaponData) do
        local weapondata=_weapondata --Ops.OpsGroup#OPSGROUP.WeaponData
        text=text..string.format("\n- Bit=%s: Rmin=%.1f km, Rmax=%.1f km", bit, weapondata.RangeMin/1000, weapondata.RangeMax/1000)
      end
      self:I(self.lid..text)
    end
    
    -- Check if group has detected any units.
    self:_CheckAssetStatus()
    
  end  
  
  if not self:IsStopped() then
    self:__Status(-60)
  end
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: Misc functions.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
