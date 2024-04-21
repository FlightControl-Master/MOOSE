--
--
-- ### Author: **nielsvaes/coconutcockpit**
--
-- ===
-- @module Shapes.OVAL

--- OVAL class.
-- @type OVAL
-- @field #string ClassName Name of the class.
-- @field #number MajorAxis The major axis (radius) of the oval
-- @field #number MinorAxis The minor axis (radius) of the oval
-- @field #number Angle The angle the oval is rotated on

--- *The little man removed his hat, what an egg shaped head he had* -- Agatha Christie
--
-- ===
--
-- # OVAL
-- OVALs can be fetched from the drawings in the Mission Editor

-- The major and minor axes define how elongated the shape of an oval is. This class has some basic functions that the other SHAPE classes have as well.
-- Since it's not possible to draw the shape of an oval while the mission is running, right now the draw function draws 2 cicles. One with the major axis and one with
-- the minor axis. It then draws a diamond shape on an angle where the corners touch the major and minor axes to give an indication of what the oval actually
-- looks like.

-- Using ovals can be handy to find an area on the ground that is actually an intersection of a cone and a plane. So imagine you're faking the view cone of
-- a targeting pod and

-- @field #CIRCLE

--- OVAL class with properties and methods for handling ovals.
OVAL = {
    ClassName = "OVAL",
    MajorAxis = nil,
    MinorAxis = nil,
    Angle = 0,
    DrawPoly=nil
}

--- Finds an oval on the map by its name. The oval must be drawn on the map.
-- @param #string shape_name Name of the oval to find
-- @return #OVAL The found oval, or nil if not found
function OVAL:FindOnMap(shape_name)
    local self = BASE:Inherit(self, SHAPE_BASE:FindOnMap(shape_name))
    for _, layer in pairs(env.mission.drawings.layers) do
        for _, object in pairs(layer["objects"]) do
            if string.find(object["name"], shape_name, 1, true) then
                if object["polygonMode"] == "oval" then
                    self.CenterVec2 = { x = object["mapX"], y = object["mapY"] }
                    self.MajorAxis = object["r1"]
                    self.MinorAxis = object["r2"]
                    self.Angle = object["angle"]
                end
            end
        end
    end

    return self
end

--- Finds an oval by its name in the database.
-- @param #string shape_name Name of the oval to find
-- @return #OVAL The found oval, or nil if not found
function OVAL:Find(shape_name)
    return _DATABASE:FindShape(shape_name)
end

--- Creates a new oval from a center point, major axis, minor axis, and angle.
-- @param #table vec2 The center point of the oval
-- @param #number major_axis The major axis of the oval
-- @param #number minor_axis The minor axis of the oval
-- @param #number angle The angle of the oval
-- @return #OVAL The new oval
function OVAL:New(vec2, major_axis, minor_axis, angle)
    local self = BASE:Inherit(self, SHAPE_BASE:New())
    self.CenterVec2 = vec2
    self.MajorAxis = major_axis
    self.MinorAxis = minor_axis
    self.Angle = angle or 0

    return self
end

--- Gets the major axis of the oval.
-- @return #number The major axis of the oval
function OVAL:GetMajorAxis()
    return self.MajorAxis
end

--- Gets the minor axis of the oval.
-- @return #number The minor axis of the oval
function OVAL:GetMinorAxis()
    return self.MinorAxis
end

--- Gets the angle of the oval.
-- @return #number The angle of the oval
function OVAL:GetAngle()
    return self.Angle
end

--- Sets the major axis of the oval.
-- @param #number value The new major axis
function OVAL:SetMajorAxis(value)
    self.MajorAxis = value
end

--- Sets the minor axis of the oval.
-- @param #number value The new minor axis
function OVAL:SetMinorAxis(value)
    self.MinorAxis = value
end

--- Sets the angle of the oval.
-- @param #number value The new angle
function OVAL:SetAngle(value)
    self.Angle = value
end

--- Checks if a point is contained within the oval.
-- @param #table point The point to check
-- @return #bool True if the point is contained, false otherwise
function OVAL:ContainsPoint(point)
    local cos, sin = math.cos, math.sin
    local dx = point.x - self.CenterVec2.x
    local dy = point.y - self.CenterVec2.y
    local rx = dx * cos(self.Angle) + dy * sin(self.Angle)
    local ry = -dx * sin(self.Angle) + dy * cos(self.Angle)
    return rx * rx / (self.MajorAxis * self.MajorAxis) + ry * ry / (self.MinorAxis * self.MinorAxis) <= 1
end

--- Returns a random Vec2 within the oval.
-- @return #table The random Vec2
function OVAL:GetRandomVec2()
    local theta = math.rad(self.Angle)

    local random_point = math.sqrt(math.random())  --> uniformly
    --local random_point = math.random()  --> more clumped around center
    local phi = math.random() * 2 * math.pi
    local x_c = random_point * math.cos(phi)
    local y_c = random_point * math.sin(phi)
    local x_e = x_c * self.MajorAxis
    local y_e = y_c * self.MinorAxis
    local rx = (x_e * math.cos(theta) - y_e * math.sin(theta)) + self.CenterVec2.x
    local ry = (x_e * math.sin(theta) + y_e * math.cos(theta)) + self.CenterVec2.y

    return {x=rx, y=ry}
end

--- Calculates the bounding box of the oval. The bounding box is the smallest rectangle that contains the oval.
-- @return #table The bounding box of the oval
function OVAL:GetBoundingBox()
    local min_x = self.CenterVec2.x - self.MajorAxis
    local min_y = self.CenterVec2.y - self.MinorAxis
    local max_x = self.CenterVec2.x + self.MajorAxis
    local max_y = self.CenterVec2.y + self.MinorAxis

    return {
        {x=min_x, y=min_x}, {x=max_x, y=min_y}, {x=max_x, y=max_y}, {x=min_x, y=max_y}
    }
end

--- Draws the oval on the map, for debugging
-- @param #number angle (Optional) The angle of the oval. If nil will use self.Angle
function OVAL:Draw()
    --for pt in pairs(self:PointsOnEdge(20)) do
    --    COORDINATE:NewFromVec2(pt)
   --end

    self.DrawPoly = POLYGON:NewFromPoints(self:PointsOnEdge(20))
    self.DrawPoly:Draw(true)




    ---- TODO: draw a better shape using line segments
    --angle = angle or self.Angle
    --local coor = self:GetCenterCoordinate()
    --
    --table.add(self.MarkIDs, coor:CircleToAll(self.MajorAxis))
    --table.add(self.MarkIDs, coor:CircleToAll(self.MinorAxis))
    --table.add(self.MarkIDs, coor:LineToAll(coor:Translate(self.MajorAxis, self.Angle)))
    --
    --local pt_1 = coor:Translate(self.MajorAxis, self.Angle)
    --local pt_2 = coor:Translate(self.MinorAxis, self.Angle - 90)
    --local pt_3 = coor:Translate(self.MajorAxis, self.Angle - 180)
    --local pt_4 = coor:Translate(self.MinorAxis, self.Angle - 270)
    --table.add(self.MarkIDs, pt_1:QuadToAll(pt_2, pt_3, pt_4), -1, {0, 1, 0}, 1, {0, 1, 0})
end

--- Removes the drawing of the oval from the map
function OVAL:RemoveDraw()
    self.DrawPoly:RemoveDraw()
end


function OVAL:PointsOnEdge(num_points)
    num_points = num_points or 20
    local points = {}
    local dtheta = 2 * math.pi / num_points

    for i = 0, num_points - 1 do
        local theta = i * dtheta
        local x = self.CenterVec2.x + self.MajorAxis * math.cos(theta) * math.cos(self.Angle) - self.MinorAxis * math.sin(theta) * math.sin(self.Angle)
        local y = self.CenterVec2.y + self.MajorAxis * math.cos(theta) * math.sin(self.Angle) + self.MinorAxis * math.sin(theta) * math.cos(self.Angle)
        table.insert(points, {x = x, y = y})
    end

    return points
end


