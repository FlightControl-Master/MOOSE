--- **Ops** - Flotilla is a small naval group belonging to a fleet.
--
-- **Main Features:**
--
--    * Set parameters like livery, skill valid for all flotilla members.
--    * Define mission types, this flotilla can perform (see Ops.Auftrag#AUFTRAG).
--    * Pause/unpause flotilla operations.
--
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Ops.Flotilla
-- @image OPS_Flotilla.png


--- FLOTILLA class.
-- @type FLOTILLA
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field Ops.OpsGroup#OPSGROUP.WeaponData weaponData Weapon data table with key=BitType.
-- @extends Ops.Cohort#COHORT

--- *No captain can do very wrong if he places his ship alongside that of an enemy.* -- Horation Nelson
--
-- ===
--
-- # The FLOTILLA Concept
-- 
-- A FLOTILLA is an essential part of a FLEET.
--
--
--
-- @field #FLOTILLA
FLOTILLA = {
  ClassName      = "FLOTILLA",
  verbose        =     0,
  weaponData     =    {},
}

--- FLOTILLA class version.
-- @field #string version
FLOTILLA.version="0.1.0"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new FLOTILLA object and start the FSM.
-- @param #FLOTILLA self
-- @param #string TemplateGroupName Name of the template group.
-- @param #number Ngroups Number of asset groups of this flotilla. Default 3.
-- @param #string FlotillaName Name of the flotilla. Must be **unique**!
-- @return #FLOTILLA self
function FLOTILLA:New(TemplateGroupName, Ngroups, FlotillaName)

  -- Inherit everything from COHORT class.
  local self=BASE:Inherit(self, COHORT:New(TemplateGroupName, Ngroups, FlotillaName)) -- #FLOTILLA
  
  -- All flotillas get mission type Nothing.
  self:AddMissionCapability(AUFTRAG.Type.NOTHING, 50)
  
  -- Is naval.
  self.isNaval=true

  -- Get initial ammo.
  self.ammo=self:_CheckAmmo()

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  -- TODO: Flotilla specific user functions.

--- Set fleet of this flotilla.
-- @param #FLOTILLA self
-- @param Ops.Fleet#FLEET Fleet The fleet.
-- @return #FLOTILLA self
function FLOTILLA:SetFleet(Fleet)
  self.legion=Fleet
  return self
end

--- Get fleet of this flotilla.
-- @param #FLOTILLA self
-- @return Ops.Fleet#FLEET The fleet.
function FLOTILLA:GetFleet()
  return self.legion
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #FLOTILLA self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLOTILLA:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting %s v%s %s", self.ClassName, self.version, self.name)
  self:I(self.lid..text)

  -- Start the status monitoring.
  self:__Status(-1)
end

--- On after "Status" event.
-- @param #FLOTILLA self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function FLOTILLA:onafterStatus(From, Event, To)

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



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
