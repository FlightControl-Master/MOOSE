--- **NAVIGATION** - Template.
--
-- **Main Features:**
--
--    * Stuff
--    * More Stuff
-- 
-- ===
--
-- ## Example Missions:
--
-- Demo missions can be found on [github](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/develop/Navigation%20-%20Template).
-- 
-- ===
--
-- ### Author: **funkyfranky**
-- 
-- ===
-- @module Navigation.Template
-- @image NAVIGATION_Template.png


--- TEMPLATE class.
-- @type TEMPLATE
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity of output.
-- @extends Core.Base#BASE

--- *A fleet of British ships at war are the best negotiators.* -- Horatio Nelson
--
-- ===
--
-- # The TEMPLATE Concept
--
-- The TEMPLATE class has a great concept!
-- 
-- # Basic Setup
-- 
-- A new `TEMPLATE` object can be created with the @{#TEMPLATE.New}() function.
-- 
--     myTemplate=TEMPLATE:New()
--     myTemplate:SetXYZ(X, Y, Z)
--     
-- This is how it works.
--
-- @field #TEMPLATE
TEMPLATE = {
  ClassName       = "TEMPLATE",
  verbose         =       0,
}

--- Type of navaid
-- @type TEMPLATE.Type
-- @field #string VOR VOR
-- @field #string NDB NDB
TEMPLATE.TYPE={
  VOR="VOR",
  NDB="NDB",
}
  
--- TEMPLATE class version.
-- @field #string version
TEMPLATE.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ToDo list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot...

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new TEMPLATE class instance.
-- @param #TEMPLATE self
-- @return #TEMPLATE self
function TEMPLATE:New()

  -- Inherit everything from SCENERY class.
  self=BASE:Inherit(self, BASE:New()) -- #TEMPLATE

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set frequency.
-- @param #TEMPLATE self
-- @param #number Frequency Frequency in Hz.
-- @return #TEMPLATE self
function TEMPLATE:SetFrequency(Frequency)

  self.frequency=Frequency

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Private Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
