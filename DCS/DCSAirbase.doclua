-------------------------------------------------------------------------------
-- @module DCSAirbase


--- Represents airbases: airdromes, helipads and ships with flying decks or landing pads.  
-- @type Airbase
-- @extends DCSCoalitionObject#CoalitionObject
-- @field #Airbase.ID ID Identifier of an airbase. It assigned to an airbase by the Mission Editor automatically. This identifier is used in AI tasks to refer an airbase that exists (spawned and not dead) or not. 
-- @field #Airbase.Category Category enum contains identifiers of airbase categories. 
-- @field #Airbase.Desc Desc Airbase descriptor. Airdromes are unique and their types are unique, but helipads and ships are not always unique and may have the same type. 

--- Enum contains identifiers of airbase categories.
-- @type Airbase.Category
-- @field AIRDROME
-- @field HELIPAD
-- @field SHIP

--- Airbase descriptor. Airdromes are unique and their types are unique, but helipads and ships are not always unique and may have the same type. 
-- @type Airbase.Desc
-- @extends #Desc
-- @field #Airbase.Category category Category of the airbase type.

--- Returns airbase by its name. If no airbase found the function will return nil.
-- @function [parent=#Airbase] getByName
-- @param #string name
-- @return #Airbase

--- Returns airbase descriptor by type name. If no descriptor is found the function will return nil.
-- @function [parent=#Airbase] getDescByName
-- @param #TypeName typeName Airbase type name.
-- @return #Airbase.Desc

--- Returns Unit that is corresponded to the airbase. Works only for ships.
-- @function [parent=#Airbase] getUnit
-- @param self
-- @return Unit#Unit

--- Returns identifier of the airbase.
-- @function [parent=#Airbase] getID
-- @param self
-- @return #Airbase.ID

--- Returns the airbase's callsign - the localized string.
-- @function [parent=#Airbase] getCallsign
-- @param self
-- @return #string

--- Returns descriptor of the airbase. 
-- @function [parent=#Airbase] getDesc
-- @param self
-- @return #Airbase.Desc


Airbase = {} --#Airbase
