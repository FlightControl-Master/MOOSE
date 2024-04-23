--- **Shapes** - Class that serves as the base shapes drawn in the Mission Editor
--
--
-- ### Author: **nielsvaes/coconutcockpit**
--
-- ===
-- @module Shapes.SHAPE_BASE
-- @image CORE_Pathline.png


--- SHAPE_BASE class.
-- @type SHAPE_BASE
-- @field #string ClassName Name of the class.
-- @field #string Name Name of the shape
-- @field #table CenterVec2 Vec2 of the center of the shape, this will be assigned automatically
-- @field #table Points List of 3D points defining the shape, this will be assigned automatically
-- @field #table Coords List of COORDINATE defining the path, this will be assigned automatically
-- @field #table MarkIDs List any MARKIDs this class use, this will be assigned automatically
-- @extends Core.Base#BASE

--- *I'm in love with the shape of you -- Ed Sheeran
--
-- ===
--
-- # SHAPE_BASE
-- The class serves as the base class to deal with these shapes using MOOSE. You should never use this class on its own,
-- rather use:
--      CIRCLE
--      LINE
--      OVAL
--      POLYGON
--      TRIANGLE (although this one's a bit special as well)
--
-- ===
-- The idea is that anything you draw on the map in the Mission Editor can be turned in a shape to work with in MOOSE.
-- This is the base class that all other shape classes are built on. There are some shared functions, most of which are overridden in the derived classes
--
-- @field #SHAPE_BASE
SHAPE_BASE = {
    ClassName = "SHAPE_BASE",
    Name = "",
    CenterVec2 = nil,
    Points = {},
    Coords = {},
    MarkIDs = {},
    ColorString = "",
    ColorRGBA = {}
}

--- Creates a new instance of SHAPE_BASE.
-- @return #SHAPE_BASE The new instance
function SHAPE_BASE:New()
    local self = BASE:Inherit(self, BASE:New())
    return self
end

--- Finds a shape on the map by its name.
-- @param #string shape_name Name of the shape to find
-- @return #SHAPE_BASE The found shape
function SHAPE_BASE:FindOnMap(shape_name)
    local self = BASE:Inherit(self, BASE:New())

    local found = false

    for _, layer in pairs(env.mission.drawings.layers) do
        for _, object in pairs(layer["objects"]) do
            if object["name"] == shape_name then
                self.Name = object["name"]
                self.CenterVec2 = { x = object["mapX"], y = object["mapY"] }
                self.ColorString = object["colorString"]
                self.ColorRGBA = UTILS.HexToRGBA(self.ColorString)
                found = true
            end
        end
    end
    if not found then
        self:E("Can't find a shape with name " .. shape_name)
    end
    return self
end

function SHAPE_BASE:GetAllShapes(filter)
    filter = filter or ""
    local return_shapes = {}
    for _, layer in pairs(env.mission.drawings.layers) do
        for _, object in pairs(layer["objects"]) do
            if string.contains(object["name"], filter) then
                table.add(return_shapes, object)
            end
        end
    end

    return return_shapes
end

--- Offsets the shape to a new position.
-- @param #table new_vec2 The new position
function SHAPE_BASE:Offset(new_vec2)
    local offset_vec2 = UTILS.Vec2Subtract(new_vec2, self.CenterVec2)
    self.CenterVec2 = new_vec2
    if self.ClassName == "POLYGON" then
        for _, point in pairs(self.Points) do
            point.x = point.x + offset_vec2.x
            point.y = point.y + offset_vec2.y
        end
    end
end

--- Gets the name of the shape.
-- @return #string The name of the shape
function SHAPE_BASE:GetName()
    return self.Name
end

function SHAPE_BASE:GetColorString()
    return self.ColorString
end

function SHAPE_BASE:GetColorRGBA()
    return self.ColorRGBA
end

function SHAPE_BASE:GetColorRed()
    return self.ColorRGBA.R
end

function SHAPE_BASE:GetColorGreen()
    return self.ColorRGBA.G
end

function SHAPE_BASE:GetColorBlue()
    return self.ColorRGBA.B
end

function SHAPE_BASE:GetColorAlpha()
    return self.ColorRGBA.A
end

--- Gets the center position of the shape.
-- @return #table The center position
function SHAPE_BASE:GetCenterVec2()
    return self.CenterVec2
end

--- Gets the center coordinate of the shape.
-- @return #COORDINATE The center coordinate
function SHAPE_BASE:GetCenterCoordinate()
    return COORDINATE:NewFromVec2(self.CenterVec2)
end

--- Gets the coordinate of the shape.
-- @return #COORDINATE The coordinate
function SHAPE_BASE:GetCoordinate()
    return self:GetCenterCoordinate()
end

--- Checks if a point is contained within the shape.
-- @param #table _ The point to check
-- @return #bool True if the point is contained, false otherwise
function SHAPE_BASE:ContainsPoint(_)
    self:E("This needs to be set in the derived class")
end

--- Checks if a unit is contained within the shape.
-- @param #string unit_name The name of the unit to check
-- @return #bool True if the unit is contained, false otherwise
function SHAPE_BASE:ContainsUnit(unit_name)
    local unit = UNIT:FindByName(unit_name)

    if unit == nil or not unit:IsAlive() then
        return false
    end

    if self:ContainsPoint(unit:GetVec2()) then
        return true
    end
    return false
end

--- Checks if any unit of a group is contained within the shape.
-- @param #string group_name The name of the group to check
-- @return #bool True if any unit of the group is contained, false otherwise
function SHAPE_BASE:ContainsAnyOfGroup(group_name)
    local group = GROUP:FindByName(group_name)

    if group == nil or not group:IsAlive() then
        return false
    end

    for _, unit in pairs(group:GetUnits()) do
        if self:ContainsPoint(unit:GetVec2()) then
            return true
        end
    end
    return false
end

--- Checks if all units of a group are contained within the shape.
-- @param #string group_name The name of the group to check
-- @return #bool True if all units of the group are contained, false otherwise
function SHAPE_BASE:ContainsAllOfGroup(group_name)
    local group = GROUP:FindByName(group_name)

    if group == nil or not group:IsAlive() then
        return false
    end

    for _, unit in pairs(group:GetUnits()) do
        if not self:ContainsPoint(unit:GetVec2()) then
            return false
        end
    end
    return true
end
