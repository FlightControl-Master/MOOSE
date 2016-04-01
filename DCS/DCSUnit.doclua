-------------------------------------------------------------------------------
-- @module DCSUnit

--- @type Unit
-- @extends DCSCoalitionObject#CoalitionObject
-- @field ID Identifier of an unit. It assigned to an unit by the Mission Editor automatically. 
-- @field #Unit.Category Category
-- @field #Unit.RefuelingSystem RefuelingSystem
-- @field #Unit.SensorType SensorType
-- @field #Unit.OpticType OpticType
-- @field #Unit.RadarType RadarType
-- @field #Unit.Desc Desc
-- @field #Unit.DescAircraft DescAircraft
-- @field #Unit.DescAirplane DescAirplane
-- @field #Unit.DescHelicopter DescHelicopter
-- @field #Unit.DescVehicle DescVehicle
-- @field #Unit.DescShip DescShip
-- @field #Unit.AmmoItem AmmoItem
-- @field #list<#Unit.AmmoItem> Ammo
-- @field #Unit.Sensor Sensor
-- @field #Unit.Optic Optic
-- @field #Unit.Radar Radar
-- @field #Unit.IRST IRST


--- Enum that stores unit categories.
-- @type Unit.Category
-- @field AIRPLANE
-- @field HELICOPTER
-- @field GROUND_UNIT
-- @field SHIP
-- @field STRUCTURE

--- Enum that stores aircraft refueling system types.
-- @type Unit.RefuelingSystem
-- @field BOOM_AND_RECEPTACLE
-- @field PROBE_AND_DROGUE

--- Enum that stores sensor types.
-- @type Unit.SensorType
-- @field OPTIC
-- @field RADAR
-- @field IRST
-- @field RWR

--- Enum that stores types of optic sensors.
-- @type Unit.OpticType
-- @field TV TV-sensor
-- @field LLTV Low-level TV-sensor
-- @field IR Infra-Red optic sensor

--- Enum that stores radar types.
-- @type Unit.RadarType
-- @field AS air search radar
-- @field SS surface/land search radar


--- A unit descriptor. 
-- @type Unit.Desc
-- @extends Object#Object.Desc
-- @field #Unit.Category category Unit Category
-- @field #Mass massEmpty mass of empty unit
-- @field #number speedMax istance / Time, --maximal velocity

--- An aircraft descriptor. 
-- @type Unit.DescAircraft
-- @extends Unit#Unit.Desc
-- @field #Mass fuelMassMax maximal inner fuel mass
-- @field #Distance range Operational range
-- @field #Distance Hmax Ceiling
-- @field #number VyMax  #Distance / #Time, --maximal climb rate
-- @field #number NyMin minimal safe acceleration
-- @field #number NyMax maximal safe acceleration
-- @field #Unit.RefuelingSystem tankerType refueling system type

--- An airplane descriptor.
-- @type Unit.DescAirplane 
-- @extends Unit#Unit.DescAircraft
-- @field #number speedMax0 Distance / Time maximal TAS at ground level
-- @field #number speedMax10K Distance / Time maximal TAS at altitude of 10 km

--- A helicopter descriptor.
-- @type Unit.DescHelicopter 
-- @extends Unit#Unit.DescAircraft
-- @field #Distance HmaxStat static ceiling

--- A vehicle descriptor.
-- @type Unit.DescVehicle 
-- @extends Unit#Unit.Desc
-- @field #Angle maxSlopeAngle maximal slope angle
-- @field #boolean riverCrossing can the vehicle cross a rivers

--- A ship descriptor.
-- @type Unit.DescShip 
-- @extends #Unit.Desc
 
--- ammunition item: "type-count" pair.
-- @type Unit.AmmoItem
-- @field #Weapon.Desc desc ammunition descriptor
-- @field #number count ammunition count

--- A unit sensor.
-- @type Unit.Sensor
-- @field #TypeName typeName
-- @field #Unit.SensorType type

--- An optic sensor.
-- @type Unit.Optic 
-- @extends Unit#Unit.Sensor
-- @field #Unit.OpticType opticType

--- A radar.
-- @type  Unit.Radar 
-- @extends Unit#Unit.Sensor
-- @field #Distance detectionDistanceRBM detection distance for RCS=1m^2 in real-beam mapping mode, nil if radar doesn't support surface/land search
-- @field #Distance detectionDistanceHRM detection distance for RCS=1m^2 in high-resolution mapping mode, nil if radar has no HRM
-- @field #Unit.Radar.detectionDistanceAir detectionDistanceAir detection distance for RCS=1m^2 airborne target, nil if radar doesn't support air search

--- @type Unit.Radar.detectionDistanceAir 
-- @field #Unit.Radar.detectionDistanceAir.upperHemisphere upperHemisphere
-- @field #Unit.Radar.detectionDistanceAir.lowerHemisphere lowerHemisphere

--- @type Unit.Radar.detectionDistanceAir.upperHemisphere
-- @field #Distance headOn
-- @field #Distance tailOn

--- @type Unit.Radar.detectionDistanceAir.lowerHemisphere 
-- @field #Distance headOn
-- @field #Distance tailOn

--- An IRST.
--  @type Unit#Unit.IRST 
--  @extends Unit.Sensor
--  @field #Distance detectionDistanceIdle detection of tail-on target with heat signature = 1 in upper hemisphere, engines are in idle
--  @field #Distance detectionDistanceMaximal ..., engines are in maximal mode
--  @field #Distance detectionDistanceAfterburner ..., engines are in afterburner mode

--- An RWR.
--  @type Unit.RWR 
--  @extends Unit#Unit.Sensor

--- table that stores all unit sensors.
-- TODO @type Sensors
-- 


--- Returns unit object by the name assigned to the unit in Mission Editor. If there is unit with such name or the unit is destroyed the function will return nil. The function provides access to non-activated units too. 
-- @function [parent=#Unit] getByName
-- @param #string name
-- @return #Unit

--- Returns if the unit is activated.
-- @function [parent=#Unit] isActive
-- @param #Unit self
-- @return #boolean

--- Returns name of the player that control the unit or nil if the unit is controlled by A.I.
-- @function [parent=#Unit] getPlayerName
-- @param #Unit self
-- @return #string

--- returns the unit's unique identifier.
-- @function [parent=#Unit] getID
-- @param #Unit self
-- @return #Unit.ID


--- Returns the unit's number in the group. The number is the same number the unit has in ME. It may not be changed during the mission. If any unit in the group is destroyed, the numbers of another units will not be changed.
-- @function [parent=#Unit] getNumber
-- @param #Unit self
-- @return #number

--- Returns controller of the unit if it exist and nil otherwise
-- @function [parent=#Unit] getController
-- @param #Unit self
-- @return #Controller

--- Returns the unit's group if it exist and nil otherwise
-- @function [parent=#Unit] getGroup
-- @param #Unit self
-- @return DCSGroup#Group

--- Returns the unit's callsign - the localized string.
-- @function [parent=#Unit] getCallsign
-- @param #Unit self
-- @return #string

--- Returns the unit's health. Dead units has health <= 1.0
-- @function [parent=#Unit] getLife
-- @param #Unit self
-- @return #number

--- returns the unit's initial health.
-- @function [parent=#Unit] getLife0
-- @param #Unit self
-- @return #number

--- Returns relative amount of fuel (from 0.0 to 1.0) the unit has in its internal tanks. If there are additional fuel tanks the value may be greater than 1.0.
-- @function [parent=#Unit] getFuel
-- @param #Unit self
-- @return #number

--- Returns the unit ammunition.
-- @function [parent=#Unit] getAmmo
-- @param #Unit self
-- @return #Unit.Ammo

--- Returns the unit sensors. 
-- @function [parent=#Unit] getSensors
-- @param #Unit self
-- @return #Unit.Sensors

--- Returns true if the unit has specified types of sensors. This function is more preferable than Unit.getSensors() if you don't want to get information about all the unit's sensors, and just want to check if the unit has specified types of sensors.
-- @function [parent=#Unit] hasSensors
-- @param #Unit self
-- @param #Unit.SensorType sensorType (= nil) Sensor type.
-- @param ... Additional parameters.
-- @return #boolean
-- @usage
-- If sensorType is Unit.SensorType.OPTIC, additional parameters are optic sensor types. Following example checks if the unit has LLTV or IR optics:
-- unit:hasSensors(Unit.SensorType.OPTIC, Unit.OpticType.LLTV, Unit.OpticType.IR)
-- If sensorType is Unit.SensorType.RADAR, additional parameters are radar types. Following example checks if the unit has air search radars:
-- unit:hasSensors(Unit.SensorType.RADAR, Unit.RadarType.AS)
-- If no additional parameters are specified the function returns true if the unit has at least one sensor of specified type.
-- If sensor type is not specified the function returns true if the unit has at least one sensor of any type.
-- 

--- returns two values:
-- First value indicates if at least one of the unit's radar(s) is on.
-- Second value is the object of the radar's interest. Not nil only if at least one radar of the unit is tracking a target. 
-- @function [parent=#Unit] getRadar
-- @param #Unit self
-- @return #boolean, Object#Object

--- Returns unit descriptor. Descriptor type depends on unit category. 
-- @function [parent=#Unit] getDesc
-- @param #Unit self
-- @return #Unit.Desc


Unit = {} --#Unit
