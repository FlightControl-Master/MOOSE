--
--
-- ### Author: **nielsvaes/coconutcockpit**
--
-- ===
-- @module Shapes.CIRCLE
-- @image MOOSE.JPG

--- CIRCLE class.
-- @type CIRCLE
-- @field #string ClassName Name of the class.
-- @field #number Radius Radius of the circle

--- *It's NOT hip to be square* -- Someone, somewhere, probably
--
-- ===
--
-- # CIRCLE
-- CIRCLEs can be fetched from the drawings in the Mission Editor

---
-- This class has some of the standard CIRCLE functions you'd expect. One function of interest is CIRCLE:PointInSector() that you can use if a point is
-- within a certain sector (pizza slice) of a circle. This can be useful for many things, including rudimentary, "radar-like" searches from a unit.
-- 
-- CIRCLE class with properties and methods for handling circles.
-- @field #CIRCLE
CIRCLE = {
    ClassName = "CIRCLE",
    Radius = nil,
}
--- Finds a circle on the map by its name. The circle must have been added in the Mission Editor
-- @param #string shape_name Name of the circle to find
-- @return #CIRCLE The found circle, or nil if not found
function CIRCLE:FindOnMap(shape_name)
    local self = BASE:Inherit(self, SHAPE_BASE:FindOnMap(shape_name))
    for _, layer in pairs(env.mission.drawings.layers) do
        for _, object in pairs(layer["objects"]) do
            if string.find(object["name"], shape_name, 1, true) then
                if object["polygonMode"] == "circle" then
                    self.Radius = object["radius"]
                end
            end
        end
    end

    return self
end

--- Finds a circle by its name in the database.
-- @param #string shape_name Name of the circle to find
-- @return #CIRCLE The found circle, or nil if not found
function CIRCLE:Find(shape_name)
    return _DATABASE:FindShape(shape_name)
end

--- Creates a new circle from a center point and a radius.
-- @param #table vec2 The center point of the circle
-- @param #number radius The radius of the circle
-- @return #CIRCLE The new circle
function CIRCLE:New(vec2, radius)
    local self = BASE:Inherit(self, SHAPE_BASE:New())
    self.CenterVec2 = vec2
    self.Radius = radius
    return self
end

--- Gets the radius of the circle.
-- @return #number The radius of the circle
function CIRCLE:GetRadius()
    return self.Radius
end

--- Checks if a point is contained within the circle.
-- @param #table point The point to check
-- @return #bool True if the point is contained, false otherwise
function CIRCLE:ContainsPoint(point)
    if ((point.x - self.CenterVec2.x) ^ 2 + (point.y - self.CenterVec2.y) ^ 2) ^ 0.5 <= self.Radius then
        return true
    end
    return false
end

--- Checks if a point is contained within a sector of the circle. The start and end sector need to be clockwise
-- @param #table point The point to check
-- @param #table sector_start The start point of the sector
-- @param #table sector_end The end point of the sector
-- @param #table center The center point of the sector
-- @param #number radius The radius of the sector
-- @return #bool True if the point is contained, false otherwise
function CIRCLE:PointInSector(point, sector_start, sector_end, center, radius)
    center = center or self.CenterVec2
    radius = radius or self.Radius

    local function are_clockwise(v1, v2)
        return -v1.x * v2.y + v1.y * v2.x > 0
    end

    local function is_in_radius(rp)
        return rp.x * rp.x + rp.y * rp.y <= radius ^ 2
    end

    local rel_pt = {
        x = point.x - center.x,
        y = point.y - center.y
    }

    local rel_sector_start = {
        x = sector_start.x - center.x,
        y = sector_start.y - center.y,
    }

    local rel_sector_end = {
        x = sector_end.x - center.x,
        y = sector_end.y - center.y,
    }

    return not are_clockwise(rel_sector_start, rel_pt) and
           are_clockwise(rel_sector_end, rel_pt) and
           is_in_radius(rel_pt, radius)
end

--- Checks if a unit is contained within a sector of the circle. The start and end sector need to be clockwise
-- @param #string unit_name The name of the unit to check
-- @param #table sector_start The start point of the sector
-- @param #table sector_end The end point of the sector
-- @param #table center The center point of the sector
-- @param #number radius The radius of the sector
-- @return #bool True if the unit is contained, false otherwise
function CIRCLE:UnitInSector(unit_name, sector_start, sector_end, center, radius)
    center = center or self.CenterVec2
    radius = radius or self.Radius

    if self:PointInSector(UNIT:FindByName(unit_name):GetVec2(), sector_start, sector_end, center, radius) then
        return true
    end
    return false
end

--- Checks if any unit of a group is contained within a sector of the circle. The start and end sector need to be clockwise
-- @param #string group_name The name of the group to check
-- @param #table sector_start The start point of the sector
-- @param #table sector_end The end point of the sector
-- @param #table center The center point of the sector
-- @param #number radius The radius of the sector
-- @return #bool True if any unit of the group is contained, false otherwise
function CIRCLE:AnyOfGroupInSector(group_name, sector_start, sector_end, center, radius)
    center = center or self.CenterVec2
    radius = radius or self.Radius

    for _, unit in pairs(GROUP:FindByName(group_name):GetUnits()) do
        if self:PointInSector(unit:GetVec2(), sector_start, sector_end, center, radius) then
            return true
        end
    end
    return false
end

--- Checks if all units of a group are contained within a sector of the circle. The start and end sector need to be clockwise
-- @param #string group_name The name of the group to check
-- @param #table sector_start The start point of the sector
-- @param #table sector_end The end point of the sector
-- @param #table center The center point of the sector
-- @param #number radius The radius of the sector
-- @return #bool True if all units of the group are contained, false otherwise
function CIRCLE:AllOfGroupInSector(group_name, sector_start, sector_end, center, radius)
    center = center or self.CenterVec2
    radius = radius or self.Radius

    for _, unit in pairs(GROUP:FindByName(group_name):GetUnits()) do
        if not self:PointInSector(unit:GetVec2(), sector_start, sector_end, center, radius) then
            return false
        end
    end
    return true
end

--- Checks if a unit is contained within a radius of the circle.
-- @param #string unit_name The name of the unit to check
-- @param #table center The center point of the radius
-- @param #number radius The radius to check
-- @return #bool True if the unit is contained, false otherwise
function CIRCLE:UnitInRadius(unit_name, center, radius)
    center = center or self.CenterVec2
    radius = radius or self.Radius

    if UTILS.IsInRadius(center, UNIT:FindByName(unit_name):GetVec2(), radius) then
        return true
    end
    return false
end

--- Checks if any unit of a group is contained within a radius of the circle.
-- @param #string group_name The name of the group to check
-- @param #table center The center point of the radius
-- @param #number radius The radius to check
-- @return #bool True if any unit of the group is contained, false otherwise
function CIRCLE:AnyOfGroupInRadius(group_name, center, radius)
    center = center or self.CenterVec2
    radius = radius or self.Radius

    for _, unit in pairs(GROUP:FindByName(group_name):GetUnits()) do
        if UTILS.IsInRadius(center, unit:GetVec2(), radius) then
            return true
        end
    end
    return false
end

--- Checks if all units of a group are contained within a radius of the circle.
-- @param #string group_name The name of the group to check
-- @param #table center The center point of the radius
-- @param #number radius The radius to check
-- @return #bool True if all units of the group are contained, false otherwise
function CIRCLE:AllOfGroupInRadius(group_name, center, radius)
    center = center or self.CenterVec2
    radius = radius or self.Radius

    for _, unit in pairs(GROUP:FindByName(group_name):GetUnits()) do
        if not UTILS.IsInRadius(center, unit:GetVec2(), radius) then
            return false
        end
    end
    return true
end

--- Returns a random Vec2 within the circle.
-- @return #table The random Vec2
function CIRCLE:GetRandomVec2()
    local angle = math.random() * 2 * math.pi

    local rx = math.random(0, self.Radius) * math.cos(angle) + self.CenterVec2.x
    local ry = math.random(0, self.Radius) * math.sin(angle) + self.CenterVec2.y

    return {x=rx, y=ry}
end

--- Returns a random Vec2 on the border of the circle.
-- @return #table The random Vec2
function CIRCLE:GetRandomVec2OnBorder()
    local angle = math.random() * 2 * math.pi

    local rx = self.Radius * math.cos(angle) + self.CenterVec2.x
    local ry = self.Radius * math.sin(angle) + self.CenterVec2.y

    return {x=rx, y=ry}
end

--- Calculates the bounding box of the circle. The bounding box is the smallest rectangle that contains the circle.
-- @return #table The bounding box of the circle
function CIRCLE:GetBoundingBox()
    local min_x = self.CenterVec2.x - self.Radius
    local min_y = self.CenterVec2.y - self.Radius
    local max_x = self.CenterVec2.x + self.Radius
    local max_y = self.CenterVec2.y + self.Radius

    return {
        {x=min_x, y=min_x}, {x=max_x, y=min_y}, {x=max_x, y=max_y}, {x=min_x, y=max_y}
    }
end

