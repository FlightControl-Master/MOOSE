--- TRIANGLE class with properties and methods for handling triangles. This class is mostly used by the POLYGON class, but you can use it on its own as well
--
-- ### Author: **nielsvaes/coconutcockpit**
--
--
-- ===
-- @module Shapes.TRIANGLE

--- LINE class.
-- @type CUBE
-- @field #string ClassName Name of the class.
-- @field #number Points points of the line
-- @field #number Coords coordinates of the line

--
-- ===

---
-- @field #TRIANGLE
TRIANGLE = {
    ClassName = "TRIANGLE",
    Points = {},
    Coords = {},
    SurfaceArea = 0
}

--- Creates a new triangle from three points. The points need to be given as Vec2s
-- @param #table p1 The first point of the triangle
-- @param #table p2 The second point of the triangle
-- @param #table p3 The third point of the triangle
-- @return #TRIANGLE The new triangle
function TRIANGLE:New(p1, p2, p3)
    local self = BASE:Inherit(self, SHAPE_BASE:New())
    self.Points = {p1, p2, p3}

    local center_x = (p1.x + p2.x + p3.x) / 3
    local center_y = (p1.y + p2.y + p3.y) / 3
    self.CenterVec2 = {x=center_x, y=center_y}

    for _, pt in pairs({p1, p2, p3}) do
        table.add(self.Coords, COORDINATE:NewFromVec2(pt))
    end

    self.SurfaceArea = math.abs((p2.x - p1.x) * (p3.y - p1.y) - (p3.x - p1.x) * (p2.y - p1.y)) * 0.5

    self.MarkIDs = {}
    return self
end

--- Checks if a point is contained within the triangle.
-- @param #table pt The point to check
-- @param #table points (optional) The points of the triangle, or 3 other points if you're just using the TRIANGLE class without an object of it
-- @return #bool True if the point is contained, false otherwise
function TRIANGLE:ContainsPoint(pt, points)
    points = points or self.Points

    local function sign(p1, p2, p3)
        return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y)
    end

    local d1 = sign(pt, self.Points[1], self.Points[2])
    local d2 = sign(pt, self.Points[2], self.Points[3])
    local d3 = sign(pt, self.Points[3], self.Points[1])

    local has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    local has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)

    return not (has_neg and has_pos)
end

--- Returns a random Vec2 within the triangle.
-- @param #table points The points of the triangle, or 3 other points if you're just using the TRIANGLE class without an object of it
-- @return #table The random Vec2
function TRIANGLE:GetRandomVec2(points)
    points = points or self.Points
    local pt = {math.random(), math.random()}
    table.sort(pt)
    local s = pt[1]
    local t = pt[2] - pt[1]
    local u = 1 - pt[2]

    return {x = s * points[1].x + t * points[2].x + u * points[3].x,
            y = s * points[1].y + t * points[2].y + u * points[3].y}
end

--- Draws the triangle on the map, just for debugging
function TRIANGLE:Draw()
    for i=1, #self.Coords do
        local c1 = self.Coords[i]
        local c2 = self.Coords[i % #self.Coords + 1]
        table.add(self.MarkIDs, c1:LineToAll(c2))
    end
end

--- Removes the drawing of the triangle from the map.
function TRIANGLE:RemoveDraw()
    for _, mark_id in pairs(self.MarkIDs) do
        UTILS.RemoveMark(mark_id)
    end
end
