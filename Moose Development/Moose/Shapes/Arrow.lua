ARROW = {
    ClassName = "ARROW",
    Angle = 0,
    Heading = 0,
}


function ARROW:FindOnMap(shape_name)
    local found = false

    for _, layer in pairs(env.mission.drawings.layers) do
        for _, object in pairs(layer["objects"]) do
            if string.find(object["name"], shape_name, 1, true) then
                if object["polygonMode"] == "arrow" then
                    local self = BASE:Inherit(self, POLYGON:New(unpack(object["points"])))
                    self.Name = object["name"]
                    self.Angle = object["angle"]
                    self.Heading = UTILS.ClampAngle(self.Angle + 90)
                end

                found = true
            end
        end
    end

    if not found then
        self:E("Can't find a shape with name " .. shape_name)
    end

    return self
end
