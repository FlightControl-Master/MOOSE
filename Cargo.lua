--- CARGO
-- @classmod CARGO
--@todo need to define CARGO Class that is used within a mission...

--- Structures
-- @section Structures

--[[--
	Internal Table to understand the form of the CARGO.
	@table CARGO_TRANSPORT
--]]
CARGO_TRANSPORT = { UNIT = 1, SLING = 2, STATIC = 3, INVISIBLE = 4 }

--[[--
	CARGO_TYPE Defines the different types of transports, which has an impact on the menu commands shown in F10.
	@table CARGO_TYPE
	@field TROOPS
	@field GOODS
	@field VEHICLES
	@field INFANTRY
	@field ENGINEERS
	@field PACKAGE
	@field CARGO
--]]
CARGO_TYPE = { 
	TROOPS    = { ID = 1, TEXT = "Troops", TRANSPORT = CARGO_TRANSPORT.UNIT }, 
	GOODS     = { ID = 2, TEXT = "Goods", TRANSPORT = CARGO_TRANSPORT.STATIC }, 
	VEHICLES  = { ID = 3, TEXT = "Vehicles", TRANSPORT = CARGO_TRANSPORT.VEHICLES },
	INFANTRY  = { ID = 4, TEXT = "Infantry", TRANSPORT = CARGO_TRANSPORT.UNIT },
	ENGINEERS = { ID = 5, TEXT = "Engineers", TRANSPORT = CARGO_TRANSPORT.UNIT },
	PACKAGE   = { ID = 5, TEXT = "Package", TRANSPORT = CARGO_TRANSPORT.INVISIBLE },
	CARGO     = { ID = 5, TEXT = "Cargo", TRANSPORT = CARGO_TRANSPORT.STATIC },
}
