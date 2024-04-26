---
--
-- ### Author: **nielsvaes/coconutcockpit**
--
-- ===
-- @module Shapes.LINE
-- @image MOOSE.JPG

--- LINE class.
-- @type LINE
-- @field #string ClassName Name of the class.
-- @field #number Points points of the line
-- @field #number Coords coordinates of the line

--
-- ===

---
-- @field #LINE
LINE = {
    ClassName = "LINE",
    Points = {},
    Coords = {},
}

--- Finds a line on the map by its name. The line must be drawn in the Mission Editor
-- @param #string line_name Name of the line to find
-- @return #LINE The found line, or nil if not found
function LINE:FindOnMap(line_name)
    local self = BASE:Inherit(self, SHAPE_BASE:FindOnMap(line_name))

    for _, layer in pairs(env.mission.drawings.layers) do
        for _, object in pairs(layer["objects"]) do
            if object["name"] == line_name then
                if object["primitiveType"] == "Line" then
                    for _, point in UTILS.spairs(object["points"]) do
                        local p = {x = object["mapX"] + point["x"],
                                   y = object["mapY"] + point["y"] }
                        local coord = COORDINATE:NewFromVec2(p)
                        table.insert(self.Points, p)
                        table.insert(self.Coords, coord)
                    end
                end
            end
        end
    end

    self:I(#self.Points)
    if #self.Points == 0 then
        return nil
    end

    self.MarkIDs = {}

    return self
end

--- Finds a line by its name in the database.
-- @param #string shape_name Name of the line to find
-- @return #LINE The found line, or nil if not found
function LINE:Find(shape_name)
    return _DATABASE:FindShape(shape_name)
end

--- Creates a new line from two points.
-- @param #table vec2 The first point of the line
-- @param #number radius The second point of the line
-- @return #LINE The new line
function LINE:New(...)
    local self = BASE:Inherit(self, SHAPE_BASE:New())
    self.Points = {...}
    self:I(self.Points)
    for _, point in UTILS.spairs(self.Points) do
        table.insert(self.Coords, COORDINATE:NewFromVec2(point))
    end
    return self
end

--- Creates a new line from a circle.
-- @param #table center_point center point of the circle
-- @param #number radius radius of the circle, half length of the line
-- @param #number angle_degrees degrees the line will form from center point
-- @return #LINE The new line
function LINE:NewFromCircle(center_point, radius, angle_degrees)
    local self = BASE:Inherit(self, SHAPE_BASE:New())
    self.CenterVec2 = center_point
    local angleRadians = math.rad(angle_degrees)

    local point1 = {
        x = center_point.x + radius * math.cos(angleRadians),
        y = center_point.y + radius * math.sin(angleRadians)
    }

    local point2 = {
        x = center_point.x + radius * math.cos(angleRadians + math.pi),
        y = center_point.y + radius * math.sin(angleRadians + math.pi)
    }

    for _, point in pairs{point1, point2} do
        table.insert(self.Points, point)
        table.insert(self.Coords, COORDINATE:NewFromVec2(point))
    end

    return self
end

--- Gets the coordinates of the line.
-- @return #table The coordinates of the line
function LINE:Coordinates()
    return self.Coords
end

--- Gets the start coordinate of the line. The start coordinate is the first point of the line.
-- @return #COORDINATE The start coordinate of the line
function LINE:GetStartCoordinate()
    return self.Coords[1]
end

--- Gets the end coordinate of the line. The end coordinate is the last point of the line.
-- @return #COORDINATE The end coordinate of the line
function LINE:GetEndCoordinate()
    return self.Coords[#self.Coords]
end

--- Gets the start point of the line. The start point is the first point of the line.
-- @return #table The start point of the line
function LINE:GetStartPoint()
    return self.Points[1]
end

--- Gets the end point of the line. The end point is the last point of the line.
-- @return #table The end point of the line
function LINE:GetEndPoint()
    return self.Points[#self.Points]
end

--- Gets the length of the line.
-- @return #number The length of the line
function LINE:GetLength()
    local total_length = 0
        for i=1, #self.Points - 1 do
        local x1, y1 = self.Points[i]["x"], self.Points[i]["y"]
        local x2, y2 = self.Points[i+1]["x"], self.Points[i+1]["y"]
        local segment_length = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
        total_length = total_length + segment_length
    end
    return total_length
end

--- Returns a random point on the line.
-- @param #table points (optional) The points of the line or 2 other points if you're just using the LINE class without an object of it
-- @return #table The random point
function LINE:GetRandomPoint(points)
    points = points or self.Points
    local rand = math.random() -- 0->1

    local random_x = points[1].x + rand * (points[2].x - points[1].x)
    local random_y = points[1].y + rand * (points[2].y - points[1].y)

    return { x= random_x, y= random_y }
end

--- Gets the heading of the line.
-- @param #table points (optional) The points of the line or 2 other points if you're just using the LINE class without an object of it
-- @return #number The heading of the line
function LINE:GetHeading(points)
    points = points or self.Points

    local angle = math.atan2(points[2].y - points[1].y, points[2].x - points[1].x)

    angle = math.deg(angle)
    if angle < 0 then
        angle = angle + 360
    end

    return angle
end


--- Return each part of the line as a new line
-- @return #table The points
function LINE:GetIndividualParts()
    local parts = {}
    if #self.Points == 2 then
        parts = {self}
    end

    for i=1, #self.Points -1 do
        local p1 = self.Points[i]
        local p2 = self.Points[i % #self.Points + 1]
        table.add(parts, LINE:New(p1, p2))
    end

    return parts
end

--- Gets a number of points in between the start and end points of the line.
-- @param #number amount The number of points to get
-- @param #table start_point (Optional) The start point of the line, defaults to the object's start point
-- @param #table end_point (Optional) The end point of the line, defaults to the object's end point
-- @return #table The points
function LINE:GetPointsInbetween(amount, start_point, end_point)
    start_point = start_point or self:GetStartPoint()
    end_point = end_point or self:GetEndPoint()
    if amount == 0 then return {start_point, end_point} end

    amount = amount + 1
    local points = {}

    local difference = { x = end_point.x - start_point.x, y = end_point.y - start_point.y }
    local divided = { x = difference.x / amount, y = difference.y / amount }

    for j=0, amount do
        local part_pos = {x = divided.x * j, y = divided.y * j}
        -- add part_pos vector to the start point so the new point is placed along in the line
        local point = {x = start_point.x + part_pos.x, y = start_point.y + part_pos.y}
        table.insert(points, point)
    end
    return points
end

--- Gets a number of points in between the start and end points of the line.
-- @param #number amount The number of points to get
-- @param #table start_point (Optional) The start point of the line, defaults to the object's start point
-- @param #table end_point (Optional) The end point of the line, defaults to the object's end point
-- @return #table The points
function LINE:GetCoordinatesInBetween(amount, start_point, end_point)
    local coords = {}
    for _, pt in pairs(self:GetPointsInbetween(amount, start_point, end_point)) do
        table.add(coords, COORDINATE:NewFromVec2(pt))
    end
    return coords
end


function LINE:GetRandomPoint(start_point, end_point)
    start_point = start_point or self:GetStartPoint()
    end_point = end_point or self:GetEndPoint()

    local fraction = math.random()

    local difference = { x = end_point.x - start_point.x, y = end_point.y - start_point.y }
    local part_pos = {x = difference.x * fraction, y = difference.y * fraction}
    local random_point = { x = start_point.x + part_pos.x, y = start_point.y + part_pos.y}

    return random_point
end


function LINE:GetRandomCoordinate(start_point, end_point)
    start_point = start_point or self:GetStartPoint()
    end_point = end_point or self:GetEndPoint()

    return COORDINATE:NewFromVec2(self:GetRandomPoint(start_point, end_point))
end


--- Gets a number of points on a sine wave between the start and end points of the line.
-- @param #number amount The number of points to get
-- @param #table start_point (Optional) The start point of the line, defaults to the object's start point
-- @param #table end_point (Optional) The end point of the line, defaults to the object's end point
-- @param #number frequency (Optional) The frequency of the sine wave, default 1
-- @param #number phase (Optional) The phase of the sine wave, default 0
-- @param #number amplitude (Optional) The amplitude of the sine wave, default 100
-- @return #table The points
function LINE:GetPointsBetweenAsSineWave(amount, start_point, end_point, frequency, phase, amplitude)
    amount = amount or 20
    start_point = start_point or self:GetStartPoint()
    end_point = end_point or self:GetEndPoint()
    frequency = frequency or 1   -- number of cycles per unit of x
    phase = phase or 0           -- offset in radians
    amplitude = amplitude or 100 -- maximum height of the wave

    local points = {}

    -- Returns the y-coordinate of the sine wave at x
    local function sine_wave(x)
        return amplitude * math.sin(2 * math.pi * frequency * (x - start_point.x) + phase)
    end

    -- Plot x-amount of points on the sine wave between point_01 and point_02
    local x = start_point.x
    local step = (end_point.x - start_point.x) / 20
    for _=1, amount do
        local y = sine_wave(x)
        x = x + step
        table.add(points, {x=x, y=y})
    end
    return points
end

--- Calculates the bounding box of the line. The bounding box is the smallest rectangle that contains the line.
-- @return #table The bounding box of the line
function LINE:GetBoundingBox()
    local min_x, min_y, max_x, max_y = self.Points[1].x, self.Points[1].y, self.Points[2].x, self.Points[2].y

    for i = 2, #self.Points do
        local x, y = self.Points[i].x, self.Points[i].y

        if x < min_x then
            min_x = x
        end
        if y < min_y then
            min_y = y
        end
        if x > max_x then
            max_x = x
        end
        if y > max_y then
            max_y = y
        end
    end
    return {
        {x=min_x, y=min_x}, {x=max_x, y=min_y}, {x=max_x, y=max_y}, {x=min_x, y=max_y}
    }
end

--- Draws the line on the map.
-- @param #table points The points of the line
function LINE:Draw()
    for i=1, #self.Coords -1 do
        local c1 = self.Coords[i]
        local c2 = self.Coords[i % #self.Coords + 1]
        table.add(self.MarkIDs, c1:LineToAll(c2))
    end
end

--- Removes the drawing of the line from the map.
function LINE:RemoveDraw()
    for _, mark_id in pairs(self.MarkIDs) do
        UTILS.RemoveMark(mark_id)
    end
end
