-------------------------------------------------------------------------------
-- @module land

--- @type land
-- @field #land.SurfaceType SurfaceType


--- @type land.SurfaceType
-- @field LAND
-- @field SHALLOW_WATER
-- @field WATER
-- @field ROAD
-- @field RUNWAY

--- Returns altitude MSL of the point.
-- @function [parent=#land] getHeight
-- @param #Vec2 point point on the ground. 
-- @return DCSTypes#Distance

--- returns surface type at the given point.
-- @function [parent=#land] getSurfaceType
-- @param #Vec2 point Point on the land. 
-- @return #land.SurfaceType


land = {} --#land