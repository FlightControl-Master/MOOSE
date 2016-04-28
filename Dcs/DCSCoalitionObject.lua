-------------------------------------------------------------------------------
-- @module DCSCoalitionObject

--- @type CoalitionObject
-- @extends DCSObject#Object

--- @type coalition
-- @field #coalition.side side

--- @type coalition.side
-- @field NEUTRAL
-- @field RED
-- @field BLUE

coalition = {} --#coalition

--- Returns coalition of the object.
-- @function [parent=#CoalitionObject] getCoalition
-- @param #CoalitionObject self
-- @return DCSTypes#coalition.side

--- Returns object country.
-- @function [parent=#CoalitionObject] getCountry
-- @param #CoalitionObject self
-- @return #country.id


CoalitionObject = {} --#CoalitionObject
