---
--
-- ### Author: **nielsvaes/coconutcockpit**
--
-- ===
-- @module Shapes.POLYGON
-- @image MOOSE.JPG

--- POLYGON class.
-- @type POLYGON
-- @field #string ClassName Name of the class.
-- @field #table Points List of 3D points defining the shape, this will be assigned automatically if you're passing in a drawing from the Mission Editor
-- @field #table Coords List of COORDINATE defining the path, this will be assigned automatically if you're passing in a drawing from the Mission Editor
-- @field #table MarkIDs List any MARKIDs this class use, this will be assigned automatically if you're passing in a drawing from the Mission Editor
-- @field #table Triangles List of TRIANGLEs that make up the shape of the POLYGON after being triangulated
-- @extends Core.Base#BASE

--- *Polygons are fashionable at the moment* -- Trip Hawkins
--
-- ===
--
-- # POLYGON
-- POLYGONs can be fetched from the drawings in the Mission Editor if the drawing is:
-- * A closed shape made with line segments
-- * A closed shape made with a freehand line
-- * A freehand drawn polygon
-- * A rect
-- Use the POLYGON:FindOnMap() of POLYGON:Find() functions for this. You can also create a non existing polygon in memory using the POLYGON:New() function. Pass in a
-- any number of Vec2s into this function to define the shape of the polygon you want.
--
-- You can draw very intricate and complex polygons in the Mission Editor to avoid (or include) map objects. You can then generate random points within this complex
-- shape for spawning groups or checking positions.
--
-- When a POLYGON is made, it's automatically triangulated. The resulting triangles are stored in POLYGON.Triangles. This also immeadiately saves the surface area
-- of the POLYGON. Because the POLYGON is triangulated, it's possible to generate random points within this POLYGON without having to use a trial and error method to see if
-- the point is contained within the shape.
-- Using POLYGON:GetRandomVec2() will result in a truly, non-biased, random Vec2 within the shape. You'll want to use this function most. There's also POLYGON:GetRandomNonWeightedVec2
-- which ignores the size of the triangles in the polygon to pick a random points. This will result in more points clumping together in parts of the polygon where the triangles are
-- the smallest.

---
-- @field #POLYGON
POLYGON = {
    ClassName = "POLYGON",
    Points = {},
    Coords = {},
    Triangles = {},
    SurfaceArea = 0,
    TriangleMarkIDs = {},
    OutlineMarkIDs = {},
    Angle = nil,   -- for arrows
    Heading = nil  -- for arrows
}

--- Finds a polygon on the map by its name. The polygon must be added in the mission editor.
-- @param #string shape_name Name of the polygon to find
-- @return #POLYGON The found polygon, or nil if not found
function POLYGON:FindOnMap(shape_name)
    local self = BASE:Inherit(self, SHAPE_BASE:FindOnMap(shape_name))

    for _, layer in pairs(env.mission.drawings.layers) do
        for _, object in pairs(layer["objects"]) do
            if object["name"] == shape_name then
                if (object["primitiveType"] == "Line" and object["closed"] == true) or (object["polygonMode"] == "free") then
                    for _, point in UTILS.spairs(object["points"]) do
                        local p = {x = object["mapX"] + point["x"],
                                   y = object["mapY"] + point["y"] }
                        local coord = COORDINATE:NewFromVec2(p)
                        self.Points[#self.Points + 1] = p
                        self.Coords[#self.Coords + 1] = coord
                    end
                elseif object["polygonMode"] == "rect" then
                    local angle = object["angle"]
                    local half_width  = object["width"] / 2
                    local half_height = object["height"] / 2

                    local p1 = UTILS.RotatePointAroundPivot({ x = self.CenterVec2.x - half_height, y = self.CenterVec2.y + half_width }, self.CenterVec2, angle)
                    local p2 = UTILS.RotatePointAroundPivot({ x = self.CenterVec2.x + half_height, y = self.CenterVec2.y + half_width }, self.CenterVec2, angle)
                    local p3 = UTILS.RotatePointAroundPivot({ x = self.CenterVec2.x + half_height, y = self.CenterVec2.y - half_width }, self.CenterVec2, angle)
                    local p4 = UTILS.RotatePointAroundPivot({ x = self.CenterVec2.x - half_height, y = self.CenterVec2.y - half_width }, self.CenterVec2, angle)

                    self.Points = {p1, p2, p3, p4}
                    for _, point in pairs(self.Points) do
                        self.Coords[#self.Coords + 1] = COORDINATE:NewFromVec2(point)
                    end
                elseif object["polygonMode"] == "arrow" then
                    for _, point in UTILS.spairs(object["points"]) do
                        local p = {x = object["mapX"] + point["x"],
                                   y = object["mapY"] + point["y"] }
                        local coord = COORDINATE:NewFromVec2(p)
                        self.Points[#self.Points + 1] = p
                        self.Coords[#self.Coords + 1] = coord
                    end
                    self.Angle = object["angle"]
                    self.Heading = UTILS.ClampAngle(self.Angle + 90)
                end
            end
        end
    end

    if #self.Points == 0 then
        return nil
    end

    self.CenterVec2 = self:GetCentroid()
    self.Triangles = self:Triangulate()
    self.SurfaceArea = self:__CalculateSurfaceArea()

    self.TriangleMarkIDs = {}
    self.OutlineMarkIDs = {}
    return self
end

--- Creates a polygon from a zone. The zone must be defined in the mission.
-- @param #string zone_name Name of the zone
-- @return #POLYGON The polygon created from the zone, or nil if the zone is not found
function POLYGON:FromZone(zone_name)
    for _, zone in pairs(env.mission.triggers.zones) do
        if zone["name"] == zone_name then
            return POLYGON:New(unpack(zone["verticies"] or {}))
        end
    end
end

--- Finds a polygon by its name in the database.
-- @param #string shape_name Name of the polygon to find
-- @return #POLYGON The found polygon, or nil if not found
function POLYGON:Find(shape_name)
    return _DATABASE:FindShape(shape_name)
end

--- Creates a new polygon from a list of points. Each point is a table with 'x' and 'y' fields.
-- @param #table ... Points of the polygon
-- @return #POLYGON The new polygon
function POLYGON:New(...)
    local self = BASE:Inherit(self, SHAPE_BASE:New())

    self.Points = {...}
    self.Coords = {}
    for _, point in UTILS.spairs(self.Points) do
        table.insert(self.Coords, COORDINATE:NewFromVec2(point))
    end
    self.Triangles = self:Triangulate()
    self.SurfaceArea = self:__CalculateSurfaceArea()

    return self
end

--- Calculates the centroid of the polygon. The centroid is the average of the 'x' and 'y' coordinates of the points.
-- @return #table The centroid of the polygon
function POLYGON:GetCentroid()
    local function sum(t)
        local total = 0
        for _, value in pairs(t) do
            total = total + value
        end
        return total
    end

    local x_values = {}
    local y_values = {}
    local length = table.length(self.Points)

    for _, point in pairs(self.Points) do
        table.insert(x_values, point.x)
        table.insert(y_values, point.y)
    end

    local x = sum(x_values) / length
    local y = sum(y_values) / length

    return {
            ["x"] = x,
            ["y"] = y
           }
end

--- Returns the coordinates of the polygon. Each coordinate is a COORDINATE object.
-- @return #table The coordinates of the polygon
function POLYGON:GetCoordinates()
    return self.Coords
end

--- Returns the start coordinate of the polygon. The start coordinate is the first point of the polygon.
-- @return #COORDINATE The start coordinate of the polygon
function POLYGON:GetStartCoordinate()
    return self.Coords[1]
end

--- Returns the end coordinate of the polygon. The end coordinate is the last point of the polygon.
-- @return #COORDINATE The end coordinate of the polygon
function POLYGON:GetEndCoordinate()
    return self.Coords[#self.Coords]
end

--- Returns the start point of the polygon. The start point is the first point of the polygon.
-- @return #table The start point of the polygon
function POLYGON:GetStartPoint()
    return self.Points[1]
end

--- Returns the end point of the polygon. The end point is the last point of the polygon.
-- @return #table The end point of the polygon
function POLYGON:GetEndPoint()
    return self.Points[#self.Points]
end

--- Returns the points of the polygon. Each point is a table with 'x' and 'y' fields.
-- @return #table The points of the polygon
function POLYGON:GetPoints()
    return self.Points
end

--- Calculates the surface area of the polygon. The surface area is the sum of the areas of the triangles that make up the polygon.
-- @return #number The surface area of the polygon
function POLYGON:GetSurfaceArea()
    return self.SurfaceArea
end

--- Calculates the bounding box of the polygon. The bounding box is the smallest rectangle that contains the polygon.
-- @return #table The bounding box of the polygon
function POLYGON:GetBoundingBox()
    local min_x, min_y, max_x, max_y = self.Points[1].x, self.Points[1].y, self.Points[1].x, self.Points[1].y

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

--- Triangulates the polygon. The polygon is divided into triangles.
-- @param #table points (optional) Points of the polygon or other points if you're just using the POLYGON class without an object of it
-- @return #table The triangles of the polygon
function POLYGON:Triangulate(points)
    points = points or self.Points
    local triangles = {}

    local function get_orientation(shape_points)
        local sum = 0
        for i = 1, #shape_points do
            local j = i % #shape_points + 1
            sum = sum + (shape_points[j].x - shape_points[i].x) * (shape_points[j].y + shape_points[i].y)
        end
        return sum >= 0 and "clockwise" or "counter-clockwise" -- sum >= 0, return "clockwise", else return "counter-clockwise"
    end

    local function ensure_clockwise(shape_points)
        local orientation = get_orientation(shape_points)
        if orientation == "counter-clockwise" then
            -- Reverse the order of shape_points so they're clockwise
            local reversed = {}
            for i = #shape_points, 1, -1 do
                table.insert(reversed, shape_points[i])
            end
            return reversed
        end
        return shape_points
    end

    local function is_clockwise(p1, p2, p3)
        local cross_product = (p2.x - p1.x) * (p3.y - p1.y) - (p2.y - p1.y) * (p3.x - p1.x)
        return cross_product < 0
    end

    local function divide_recursively(shape_points)
        if #shape_points == 3 then
            table.insert(triangles, TRIANGLE:New(shape_points[1], shape_points[2], shape_points[3]))
        elseif #shape_points > 3 then                                                                -- find an ear -> a triangle with no other points inside it
            for i, p1 in ipairs(shape_points) do
                local p2 = shape_points[(i % #shape_points) + 1]
                local p3 = shape_points[(i + 1) % #shape_points + 1]
                local triangle = TRIANGLE:New(p1, p2, p3)
                local is_ear = true

                if not is_clockwise(p1, p2, p3) then
                    is_ear = false
                else
                    for _, point in ipairs(shape_points) do
                        if point ~= p1 and point ~= p2 and point ~= p3 and triangle:ContainsPoint(point) then
                            is_ear = false
                            break
                        end
                    end
                end

                if is_ear then
                    -- Check if any point in the original polygon is inside the ear triangle
                    local is_valid_triangle = true
                    for _, point in ipairs(points) do
                        if point ~= p1 and point ~= p2 and point ~= p3 and triangle:ContainsPoint(point) then
                            is_valid_triangle = false
                            break
                        end
                    end
                    if is_valid_triangle then
                        table.insert(triangles, triangle)
                        local remaining_points = {}
                        for j, point in ipairs(shape_points) do
                            if point ~= p2 then
                                table.insert(remaining_points, point)
                            end
                        end
                        divide_recursively(remaining_points)
                        break
                    end
                end
            end
        end
    end

    points = ensure_clockwise(points)
    divide_recursively(points)
    return triangles
end

function POLYGON:CovarianceMatrix()
    local cx, cy = self:GetCentroid()
    local covXX, covYY, covXY = 0, 0, 0
    for _, p in ipairs(self.points) do
        covXX = covXX + (p.x - cx)^2
        covYY = covYY + (p.y - cy)^2
        covXY = covXY + (p.x - cx) * (p.y - cy)
    end
    covXX = covXX / (#self.points - 1)
    covYY = covYY / (#self.points - 1)
    covXY = covXY / (#self.points - 1)
    return covXX, covYY, covXY
end

function POLYGON:Direction()
    local covXX, covYY, covXY = self:CovarianceMatrix()
    -- Simplified calculation for the largest eigenvector's direction
    local theta = 0.5 * math.atan2(2 * covXY, covXX - covYY)
    return math.cos(theta), math.sin(theta)
end

--- Returns a random Vec2 within the polygon. The Vec2 is weighted by the areas of the triangles that make up the polygon.
-- @return #table The random Vec2
function POLYGON:GetRandomVec2()
    local weights = {}
    for _, triangle in pairs(self.Triangles) do
        weights[triangle] = triangle.SurfaceArea / self.SurfaceArea
    end

    local random_weight = math.random()
    local accumulated_weight = 0
    for triangle, weight in pairs(weights) do
        accumulated_weight = accumulated_weight + weight
        if accumulated_weight >= random_weight then
            return triangle:GetRandomVec2()
        end
    end
end

--- Returns a random non-weighted Vec2 within the polygon. The Vec2 is chosen from one of the triangles that make up the polygon.
-- @return #table The random non-weighted Vec2
function POLYGON:GetRandomNonWeightedVec2()
    return self.Triangles[math.random(1, #self.Triangles)]:GetRandomVec2()
end

--- Checks if a point is contained within the polygon. The point is a table with 'x' and 'y' fields.
-- @param #table point The point to check
-- @param #table points (optional) Points of the polygon or other points if you're just using the POLYGON class without an object of it
-- @return #bool True if the point is contained, false otherwise
function POLYGON:ContainsPoint(point, polygon_points)
    local x = point.x
    local y = point.y

    polygon_points = polygon_points or self.Points

    local counter = 0
    local num_points = #polygon_points
    for current_index = 1, num_points do
        local next_index = (current_index % num_points) + 1
        local current_x, current_y = polygon_points[current_index].x, polygon_points[current_index].y
        local next_x, next_y = polygon_points[next_index].x, polygon_points[next_index].y
        if ((current_y > y) ~= (next_y > y)) and (x < (next_x - current_x) * (y - current_y) / (next_y - current_y) + current_x) then
            counter = counter + 1
        end
    end
    return counter % 2 == 1
end

--- Draws the polygon on the map. The polygon can be drawn with or without inner triangles. This is just for debugging
-- @param #bool include_inner_triangles Whether to include inner triangles in the drawing
function POLYGON:Draw(include_inner_triangles)
    include_inner_triangles = include_inner_triangles or false
    for i=1, #self.Coords do
        local c1 = self.Coords[i]
        local c2 = self.Coords[i % #self.Coords + 1]
        table.add(self.OutlineMarkIDs, c1:LineToAll(c2))
    end


    if include_inner_triangles then
        for _, triangle in ipairs(self.Triangles) do
            triangle:Draw()
        end
    end
end

--- Removes the drawing of the polygon from the map.
function POLYGON:RemoveDraw()
    for _, triangle in pairs(self.Triangles) do
        triangle:RemoveDraw()
    end
    for _, mark_id in pairs(self.OutlineMarkIDs) do
        UTILS.RemoveMark(mark_id)
    end
end

--- Calculates the surface area of the polygon. The surface area is the sum of the areas of the triangles that make up the polygon.
-- @return #number The surface area of the polygon
function POLYGON:__CalculateSurfaceArea()
    local area = 0
    for _, triangle in pairs(self.Triangles) do
        area = area + triangle.SurfaceArea
    end
    return area
end























