CUBE = {
    ClassName = "CUBE",
    Points = {},
    Coords = {}
}

--- Points need to be added in the following order:
--- p1 -> p4 make up the front face of the cube
--- p5 -> p8 make up the back face of the cube
---        p1 connects to p5
---        p2 connects to p6
---        p3 connects to p7
---        p4 connects to p8
---
---         8-----------7
---        /|          /|
---       / |         / |
---      4--+--------3  |
---      |  |        |  |
---      |  |        |  |
---      |  |        |  |
---      |  5--------+--6
---      | /         | /
---      |/          |/
---      1-----------2
---
function CUBE:New(p1, p2, p3, p4, p5, p6, p7, p8)
    local self = BASE:Inherit(self, SHAPE_BASE)
    self.Points = {p1, p2, p3, p4, p5, p6, p7, p8}
    for _, point in spairs(self.Points) do
        table.insert(self.Coords, COORDINATE:NewFromVec3(point))
    end
    return self
end

function CUBE:GetCenter()
    local center = { x=0, y=0, z=0 }
    for _, point in pairs(self.Points) do
      center.x = center.x + point.x
      center.y = center.y + point.y
      center.z = center.z + point.z
    end

    center.x = center.x / 8
    center.y = center.y / 8
    center.z = center.z / 8
    return center
end

function CUBE:ContainsPoint(point, cube_points)
    cube_points = cube_points or self.Points
    local min_x, min_y, min_z = math.huge, math.huge, math.huge
    local max_x, max_y, max_z = -math.huge, -math.huge, -math.huge

    -- Find the minimum and maximum x, y, and z values of the cube points
    for _, p in ipairs(cube_points) do
        if p.x < min_x then min_x = p.x end
        if p.y < min_y then min_y = p.y end
        if p.z < min_z then min_z = p.z end
        if p.x > max_x then max_x = p.x end
        if p.y > max_y then max_y = p.y end
        if p.z > max_z then max_z = p.z end
    end

    return point.x >= min_x and point.x <= max_x and point.y >= min_y and point.y <= max_y and point.z >= min_z and point.z <= max_z
end
