-------------------------------------------------------------------------------
-- @module DCSObject

--- @type Object
-- @field #Object.Category Category
-- @field #Object.Desc Desc

--- @type Object.Category
-- @field UNIT
-- @field WEAPON
-- @field STATIC
-- @field SCENERY
-- @field BASE

--- @type Object.Desc
-- @extends #Desc
-- @field #number life initial life level
-- @field #Box3 box bounding box of collision geometry

--- @function [parent=#Object] isExist
-- @param #Object self
-- @return #boolean

--- @function [parent=#Object] destroy
-- @param #Object self

--- @function [parent=#Object] getCategory
-- @param #Object self
-- @return #Object.Category

--- Returns type name of the Object.
-- @function [parent=#Object] getTypeName
-- @param #Object self
-- @return #string 

--- Returns object descriptor.
-- @function [parent=#Object] getDesc
-- @param #Object self
-- @return #Object.Desc

--- Returns true if the object belongs to the category.
-- @function [parent=#Object] hasAttribute
-- @param #Object self
-- @param #AttributeName attributeName Attribute name to check.
-- @return #boolean

--- Returns name of the object. This is the name that is assigned to the object in the Mission Editor.
-- @function [parent=#Object] getName
-- @param #Object self
-- @return #string

--- Returns object coordinates for current time.
-- @function [parent=#Object] getPoint
-- @param #Object self
-- @return #Vec3

--- Returns object position for current time. 
-- @function [parent=#Object] getPosition
-- @param #Object self
-- @return #Position3

--- Returns the unit's velocity vector.
-- @function [parent=#Object] getVelocity
-- @param #Object self
-- @return #Vec3

--- Returns true if the unit is in air.
-- @function [parent=#Object] inAir
-- @param #Object self
-- @return #boolean

Object = {} --#Object

