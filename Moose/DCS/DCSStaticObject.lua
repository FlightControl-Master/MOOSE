-------------------------------------------------------------------------------
-- @module DCSStaticObject


-------------------------------------------------------------------------------
-- @module StaticObject
-- @extends CoalitionObject#CoalitionObject

--- Represents static object added in the Mission Editor.
-- @type StaticObject
-- @field #StaticObject.ID ID Identifier of a StaticObject. It assigned to an StaticObject by the Mission Editor automatically.
-- @field #StaticObject.Desc Desc Descriptor of StaticObject and Unit are equal. StaticObject is just a passive variant of Unit. 

--- StaticObject descriptor. Airdromes are unique and their types are unique, but helipads and ships are not always unique and may have the same type. 
-- @type StaticObject.Desc
-- @extends Unit#Unit.Desc

--- Returns static object by its name. If no static object found nil will be returned. 
-- @function [parent=#StaticObject] getByName
-- @param #string name Name of static object to find. 
-- @return #StaticObject

--- returns identifier of the static object.
-- @function [parent=#StaticObject] getID
-- @param #StaticObject self
-- @return #StaticObject.ID

--- Returns descriptor of the StaticObject. 
-- @function [parent=#StaticObject] getDesc
-- @param #StaticObject self
-- @return #StaticObject.Desc


StaticObject = {} --#StaticObject
