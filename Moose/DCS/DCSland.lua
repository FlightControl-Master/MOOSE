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

land = {} --#land