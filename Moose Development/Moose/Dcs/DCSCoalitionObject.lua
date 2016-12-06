-------------------------------------------------------------------------------
-- @module DCSCoalitionObject

--- @type CoalitionObject
-- @extends Dcs.DCSWrapper.Object#Object

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
-- @return Dcs.DCSTypes#coalition.side

--- Returns object country.
-- @function [parent=#CoalitionObject] getCountry
-- @param #CoalitionObject self
-- @return #country.id


CoalitionObject = {} --#CoalitionObject
