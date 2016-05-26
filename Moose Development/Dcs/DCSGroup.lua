-------------------------------------------------------------------------------
-- @module DCSGroup

--- Represents group of Units.
-- @type Group
-- @field #ID ID Identifier of a group. It is assigned to a group by Mission Editor automatically. 
-- @field #Group.Category Category Enum contains identifiers of group types. 

--- Enum contains identifiers of group types.
-- @type Group.Category
-- @field AIRPLANE
-- @field HELICOPTER
-- @field GROUND
-- @field SHIP

-- Static Functions

--- Returns group by the name assigned to the group in Mission Editor. 
-- @function [parent=#Group] getByName
-- @param #string name
-- @return #Group

-- Member Functions

--- returns true if the group exist or false otherwise. 
-- @function [parent=#Group] isExist
-- @param #Group self 
-- @return #boolean

--- Destroys the group and all of its units.
-- @function [parent=#Group] destroy
-- @param #Group self 

--- Returns category of the group.
-- @function [parent=#Group] getCategory
-- @param #Group self 
-- @return #Group.Category

--TODO check coalition.side

--- Returns the coalition of the group.
-- @function [parent=#Group] getCoalition
-- @param #Group self 
-- @return DCSCoalitionObject#coalition.side

--- Returns the group's name. This is the same name assigned to the group in Mission Editor.
-- @function [parent=#Group] getName
-- @param #Group self 
-- @return #string

--- Returns the group identifier.
-- @function [parent=#Group] getID
-- @param #Group self 
-- @return #ID

--- Returns the unit with number unitNumber. If the unit is not exists the function will return nil.
-- @function [parent=#Group] getUnit
-- @param #Group self 
-- @param #number unitNumber
-- @return DCSUnit#Unit

--- Returns current size of the group. If some of the units will be destroyed, As units are destroyed the size of the group will be changed.
-- @function [parent=#Group] getSize
-- @param #Group self 
-- @return #number

--- Returns initial size of the group. If some of the units will be destroyed, initial size of the group will not be changed. Initial size limits the unitNumber parameter for Group.getUnit() function.
-- @function [parent=#Group] getInitialSize
-- @param #Group self 
-- @return #number

--- Returns array of the units present in the group now. Destroyed units will not be enlisted at all.
-- @function [parent=#Group] getUnits
-- @param #Group self 
-- @return #list<DCSUnit#Unit> array of Units

--- Returns controller of the group. 
-- @function [parent=#Group] getController
-- @param #Group self 
-- @return Controller#Controller

Group = {} --#Group

