--- DCS API prototypes
-- @module DCS
-- @image MOOSE.JPG

do -- world

  --- @type world
  -- @field #world.event event
  
  --- @type world.event
  -- @field S_EVENT_INVALID
  -- @field S_EVENT_SHOT
  -- @field S_EVENT_HIT
  -- @field S_EVENT_TAKEOFF
  -- @field S_EVENT_LAND
  -- @field S_EVENT_CRASH
  -- @field S_EVENT_EJECTION
  -- @field S_EVENT_REFUELING
  -- @field S_EVENT_DEAD
  -- @field S_EVENT_PILOT_DEAD
  -- @field S_EVENT_BASE_CAPTURED
  -- @field S_EVENT_MISSION_START
  -- @field S_EVENT_MISSION_END
  -- @field S_EVENT_TOOK_CONTROL
  -- @field S_EVENT_REFUELING_STOP
  -- @field S_EVENT_BIRTH
  -- @field S_EVENT_HUMAN_FAILURE
  -- @field S_EVENT_ENGINE_STARTUP
  -- @field S_EVENT_ENGINE_SHUTDOWN
  -- @field S_EVENT_PLAYER_ENTER_UNIT
  -- @field S_EVENT_PLAYER_LEAVE_UNIT
  -- @field S_EVENT_PLAYER_COMMENT
  -- @field S_EVENT_SHOOTING_START
  -- @field S_EVENT_SHOOTING_END
  -- @field S_EVENT_MAX
  
  world = {} --#world
  
end -- world


do -- env

  --- @type env
  
  --- Add message to simulator log with caption "INFO". Message box is optional.
  -- @function [parent=#env] info
  -- @field #string message message string to add to log.
  -- @field #boolean showMessageBox If the parameter is true Message Box will appear. Optional.
  
  --- Add message to simulator log with caption "WARNING". Message box is optional. 
  -- @function [parent=#env] warning
  -- @field #string message message string to add to log.
  -- @field #boolean showMessageBox If the parameter is true Message Box will appear. Optional.
  
  --- Add message to simulator log with caption "ERROR". Message box is optional.
  -- @function [parent=#env] error
  -- @field #string message message string to add to log.
  -- @field #boolean showMessageBox If the parameter is true Message Box will appear. Optional.
  
  --- Enables/disables appearance of message box each time lua error occurs.
  -- @function [parent=#env] setErrorMessageBoxEnabled
  -- @field #boolean on if true message box appearance is enabled.
  
  env = {} --#env
  
end -- env


do -- timer

  --- @type timer
  
  
  --- Returns model time in seconds.
  -- @function [parent=#timer] getTime
  -- @return #Time   
  
  --- Returns mission time in seconds.
  -- @function [parent=#timer] getAbsTime
  -- @return #Time
  
  --- Returns mission start time in seconds.
  -- @function [parent=#timer] getTime0
  -- @return #Time
  
  --- Schedules function to call at desired model time.
  --  Time function FunctionToCall(any argument, Time time)
  --  
  --  ...
  --  
  --  return ...
  --  
  --  end
  --  
  --  Must return model time of next call or nil. Note that the DCS scheduler calls the function in protected mode and any Lua errors in the called function will be trapped and not reported. If the function triggers a Lua error then it will be terminated and not scheduled to run again. 
  -- @function [parent=#timer] scheduleFunction
  -- @param #FunctionToCall functionToCall Lua-function to call. Must have prototype of FunctionToCall. 
  -- @param functionArgument Function argument of any type to pass to functionToCall.
  -- @param #Time time Model time of the function call.
  -- @return functionId
  
  --- Re-schedules function to call at another model time.
  -- @function [parent=#timer] setFunctionTime 
  -- @param functionId Lua-function to call. Must have prototype of FunctionToCall. 
  -- @param #Time time Model time of the function call. 
  
  
  --- Removes the function from schedule.
  -- @function [parent=#timer] removeFunction
  -- @param functionId Function identifier to remove from schedule 
  
  timer = {} --#timer

end 


do -- land

  --- @type land
  -- @field #land.SurfaceType SurfaceType
  
  
  --- @type land.SurfaceType
  -- @field LAND
  -- @field SHALLOW_WATER
  -- @field WATER
  -- @field ROAD
  -- @field RUNWAY
  
  --- Returns altitude MSL of the point.
  -- @function [parent=#land] getHeight
  -- @param #Vec2 point point on the ground. 
  -- @return #Distance
  
  --- returns surface type at the given point.
  -- @function [parent=#land] getSurfaceType
  -- @param #Vec2 point Point on the land. 
  -- @return #land.SurfaceType
  
  land = {} --#land

end -- land

do -- country

  --- @type country
  -- @field #country.id id
  
  --- @type country.id
  -- @field RUSSIA
  -- @field UKRAINE
  -- @field USA
  -- @field TURKEY
  -- @field UK
  -- @field FRANCE
  -- @field GERMANY
  -- @field CANADA
  -- @field SPAIN
  -- @field THE_NETHERLANDS
  -- @field BELGIUM
  -- @field NORWAY
  -- @field DENMARK
  -- @field ISRAEL
  -- @field GEORGIA
  -- @field INSURGENTS
  -- @field ABKHAZIA
  -- @field SOUTH_OSETIA
  -- @field ITALY

  country = {} -- #country

end -- country

do -- Command

  --- @type Command
  -- @field #string id
  -- @field #Command.params params
  
  --- @type Command.params

end -- Command

do -- coalition

  --- @type coalition
  -- @field #coalition.side side
  
  --- @type coalition.side
  -- @field NEUTRAL
  -- @field RED
  -- @field BLUE
  
  --- @function [parent=#coalition] getCountryCoalition
  -- @param #number countryId
  -- @return #number coalitionId
  
  coalition = {} -- #coalition

end -- coalition


do -- Types

  --- @type Desc
  -- @field #TypeName typeName type name
  -- @field #string displayName localized display name
  -- @field #table attributes object type attributes
  
  --- A distance type
  -- @type Distance
  
  --- An angle type
  -- @type Angle
  
  --- Time is given in seconds.
  -- @type Time
  -- @extends #number
  
  --- Model time is the time that drives the simulation. Model time may be stopped, accelerated and decelerated relative real time. 
  -- @type ModelTime
  -- @extends #number
  
  --- Mission time is a model time plus time of the mission start.
  -- @type MissionTime
  -- @extends #number
  
  
  --- Distance is given in meters.
  -- @type Distance
  -- @extends #number
  
  --- Angle is given in radians.
  -- @type Angle
  -- @extends #number
  
  --- Azimuth is an angle of rotation around world axis y counter-clockwise.
  -- @type Azimuth
  -- @extends #number
  
  --- Mass is given in kilograms.
  -- @type Mass
  -- @extends #number
  
  --- Vec3 type is a 3D-vector.
  -- DCS world has 3-dimensional coordinate system. DCS ground is an infinite plain.
  -- @type Vec3
  -- @field #Distance x is directed to the north
  -- @field #Distance z is directed to the east
  -- @field #Distance y is directed up
  
  --- Vec2 is a 2D-vector for the ground plane as a reference plane.
  -- @type Vec2
  -- @field #Distance x Vec2.x = Vec3.x
  -- @field #Distance y Vec2.y = Vec3.z
  
  --- Position is a composite structure. It consists of both coordinate vector and orientation matrix. Position3 (also known as "Pos3" for short) is a table that has following format: 
  -- @type Position3
  -- @field #Vec3 p
  -- @field #Vec3 x
  -- @field #Vec3 y
  -- @field #Vec3 z
  
  --- 3-dimensional box.
  -- @type Box3
  -- @field #Vec3 min
  -- @field #Vec3 max
  
  --- Each object belongs to a type. Object type is a named couple of properties those independent of mission and common for all units of the same type. Name of unit type is a string. Samples of unit type: "Su-27", "KAMAZ" and "M2 Bradley". 
  -- @type TypeName
  -- @extends #string
  
  --- AttributeName = string 
  -- Each object type may have attributes.
  -- Attributes are enlisted in ./Scripts/Database/db_attributes.Lua.
  -- To know what attributes the object type has, look for the unit type script in sub-directories planes/, helicopter/s, vehicles, navy/ of ./Scripts/Database/ directory. 
  -- @type AttributeName
  -- @extends #string
  
  --- List of @{#AttributeName}
  -- @type AttributeNameArray 
  -- @list <#AttributeName>

  --- @type Zone
  -- @field DCSVec3#Vec3 point
  -- @field #number radius

  Zone = {}

  --- @type ModelTime
  -- @extends #number
  
  --- @type Time
  -- @extends #number
  
  --- A task descriptor (internal structure for DCS World)
  -- @type Task
  -- @field #string id
  -- @field #Task.param param
  
  --- @type Task.param
  
  --- List of @{#Task}
  -- @type TaskArray
  -- @list <#Task>


end --

do -- Object

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

end -- Object

do -- CoalitionObject

  --- @type CoalitionObject
  -- @extends #Object
  
  
  --- Returns coalition of the object.
  -- @function [parent=#CoalitionObject] getCoalition
  -- @param #CoalitionObject self
  -- @return #coalition.side
  
  --- Returns object country.
  -- @function [parent=#CoalitionObject] getCountry
  -- @param #CoalitionObject self
  -- @return #country.id

CoalitionObject = {} --#CoalitionObject

end -- CoalitionObject


do -- Airbase

  --- Represents airbases: airdromes, helipads and ships with flying decks or landing pads.  
  -- @type Airbase
  -- @extends #CoalitionObject
  -- @field #Airbase.ID ID Identifier of an airbase. It assigned to an airbase by the Mission Editor automatically. This identifier is used in AI tasks to refer an airbase that exists (spawned and not dead) or not. 
  -- @field #Airbase.Category Category enum contains identifiers of airbase categories. 
  -- @field #Airbase.Desc Desc Airbase descriptor. Airdromes are unique and their types are unique, but helipads and ships are not always unique and may have the same type. 
  
  --- Enum contains identifiers of airbase categories.
  -- @type Airbase.Category
  -- @field AIRDROME
  -- @field HELIPAD
  -- @field SHIP
  
  --- Airbase descriptor. Airdromes are unique and their types are unique, but helipads and ships are not always unique and may have the same type. 
  -- @type Airbase.Desc
  -- @extends #Desc
  -- @field #Airbase.Category category Category of the airbase type.
  
  --- Returns airbase by its name. If no airbase found the function will return nil.
  -- @function [parent=#Airbase] getByName
  -- @param #string name
  -- @return #Airbase
  
  --- Returns airbase descriptor by type name. If no descriptor is found the function will return nil.
  -- @function [parent=#Airbase] getDescByName
  -- @param #TypeName typeName Airbase type name.
  -- @return #Airbase.Desc
  
  --- Returns Unit that is corresponded to the airbase. Works only for ships.
  -- @function [parent=#Airbase] getUnit
  -- @param self
  -- @return #Unit
  
  --- Returns identifier of the airbase.
  -- @function [parent=#Airbase] getID
  -- @param self
  -- @return #Airbase.ID
  
  --- Returns the airbase's callsign - the localized string.
  -- @function [parent=#Airbase] getCallsign
  -- @param self
  -- @return #string
  
  --- Returns descriptor of the airbase. 
  -- @function [parent=#Airbase] getDesc
  -- @param self
  -- @return #Airbase.Desc
  
  Airbase = {} --#Airbase

end -- Airbase



do -- Controller
  --- Controller is an object that performs A.I.-routines. Other words controller is an instance of A.I.. Controller stores current main task, active enroute tasks and behavior options. Controller performs commands. Please, read DCS A-10C GUI Manual EN.pdf chapter "Task Planning for Unit Groups", page 91 to understand A.I. system of DCS:A-10C. 
  -- 
  -- This class has 2 types of functions:
  -- 
  -- * Tasks
  -- * Commands: Commands are instant actions those required zero time to perform. Commands may be used both for control unit/group behavior and control game mechanics. 
  -- @type Controller
  -- @field #Controller.Detection Detection Enum contains identifiers of surface types. 
  
  --- Enables and disables the controller.
  -- Note: Now it works only for ground / naval groups!
  -- @function [parent=#Controller] setOnOff
  -- @param self
  -- @param #boolean value Enable / Disable.
  
  -- Tasks
  
  --- Resets current task and then sets the task to the controller. Task is a table that contains task identifier and task parameters.
  -- @function [parent=#Controller] setTask
  -- @param self
  -- @param #Task task
  
  --- Resets current task of the controller.
  -- @function [parent=#Controller] resetTask 
  -- @param self
  
  --- Pushes the task to the front of the queue and makes the task active. Further call of function Controller.setTask() function will stop current task, clear the queue and set the new task active. If the task queue is empty the function will work like function Controller.setTask() function.
  -- @function [parent=#Controller] pushTask
  -- @param self
  -- @param #Task task
  
  --- Pops current (front) task from the queue and makes active next task in the queue (if exists). If no more tasks in the queue the function works like function Controller.resetTask() function. Does nothing if the queue is empty.
  -- @function [parent=#Controller] popTask
  -- @param self
  
  --- Returns true if the controller has a task. 
  -- @function [parent=#Controller] hasTask
  -- @param self
  -- @return #boolean
  
  -- Commands
  
  --TODO: describe #Command structure
  --- Sets the command to perform by controller.
  -- @function [parent=#Controller] setCommand
  -- @param self
  -- @param #Command command Table that contains command identifier and command parameters. 
  
  
  -- Behaviours
  
  --- Sets the option to the controller.
  -- Option is a pair of identifier and value. Behavior options are global parameters those affect controller behavior in all tasks it performs.
  -- Option identifiers and values are stored in table AI.Option in subtables Air, Ground and Naval.
  -- 
  -- OptionId = @{#AI.Option.Air.id} or @{#AI.Option.Ground.id} or @{#AI.Option.Naval.id}
  -- OptionValue = AI.Option.Air.val[optionName] or AI.Option.Ground.val[optionName] or AI.Option.Naval.val[optionName]
  -- 
  -- @function [parent=#Controller] setOption
  -- @param self
  -- @param #OptionId optionId Option identifier. 
  -- @param #OptionValue optionValue Value of the option.
  
  
  -- Detection
  
  --- Enum contains identifiers of surface types. 
  -- @type Controller.Detection
  -- @field VISUAL
  -- @field OPTIC
  -- @field RADAR
  -- @field IRST
  -- @field RWR
  -- @field DLINK
  
  --- Detected target. 
  -- @type DetectedTarget
  -- @field Wrapper.Object#Object object The target
  -- @field #boolean visible The target is visible
  -- @field #boolean type The target type is known
  -- @field #boolean distance Distance to the target is known
  
  
  --- Checks if the target is detected or not. If one or more detection method is specified the function will return true if the target is detected by at least one of these methods. If no detection methods are specified the function will return true if the target is detected by any method. 
  -- @function [parent=#Controller] isTargetDetected
  -- @param self
  -- @param Wrapper.Object#Object target Target to check
  -- @param #Controller.Detection detection Controller.Detection detection1, Controller.Detection detection2, ... Controller.Detection detectionN 
  -- @return #boolean detected True if the target is detected. 
  -- @return #boolean visible Has effect only if detected is true. True if the target is visible now. 
  -- @return #ModelTime lastTime Has effect only if visible is false. Last time when target was seen. 
  -- @return #boolean type Has effect only if detected is true. True if the target type is known. 
  -- @return #boolean distance Has effect only if detected is true. True if the distance to the target is known. 
  -- @return #Vec3 lastPos Has effect only if visible is false. Last position of the target when it was seen. 
  -- @return #Vec3 lastVel Has effect only if visible is false. Last velocity of the target when it was seen. 
  
  
  --- Returns list of detected targets. If one or more detection method is specified the function will return targets which were detected by at least one of these methods. If no detection methods are specified the function will return targets which were detected by any method.
  -- @function [parent=#Controller] getDetectedTargets
  -- @param self
  -- @param #Controller.Detection detection Controller.Detection detection1, Controller.Detection detection2, ... Controller.Detection detectionN 
  -- @return #list<#DetectedTarget> array of DetectedTarget
  
  --- Know a target.
  -- @function [parent=#Controller] knowTarget
  -- @param self
  -- @param Wrapper.Object#Object object The target.
  -- @param #boolean type Target type is known.
  -- @param #boolean distance Distance to target is known.
  
  
  Controller = {} --#Controller

end -- Controller


do -- Unit

  --- @type Unit
  -- @extends #CoalitionObject
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
  -- @extends #Object.Desc
  -- @field #Unit.Category category Unit Category
  -- @field #Mass massEmpty mass of empty unit
  -- @field #number speedMax istance / Time, --maximal velocity
  
  --- An aircraft descriptor. 
  -- @type Unit.DescAircraft
  -- @extends #Unit.Desc
  -- @field #Mass fuelMassMax maximal inner fuel mass
  -- @field #Distance range Operational range
  -- @field #Distance Hmax Ceiling
  -- @field #number VyMax  #Distance / #Time, --maximal climb rate
  -- @field #number NyMin minimal safe acceleration
  -- @field #number NyMax maximal safe acceleration
  -- @field #Unit.RefuelingSystem tankerType refueling system type
  
  --- An airplane descriptor.
  -- @type Unit.DescAirplane 
  -- @extends #Unit.DescAircraft
  -- @field #number speedMax0 Distance / Time maximal TAS at ground level
  -- @field #number speedMax10K Distance / Time maximal TAS at altitude of 10 km
  
  --- A helicopter descriptor.
  -- @type Unit.DescHelicopter 
  -- @extends #Unit.DescAircraft
  -- @field #Distance HmaxStat static ceiling
  
  --- A vehicle descriptor.
  -- @type Unit.DescVehicle 
  -- @extends #Unit.Desc
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
  -- @extends #Unit.Sensor
  -- @field #Unit.OpticType opticType
  
  --- A radar.
  -- @type  Unit.Radar 
  -- @extends #Unit.Sensor
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
  --  @type Unit.IRST 
  --  @extends #Unit.Sensor
  --  @field #Distance detectionDistanceIdle detection of tail-on target with heat signature = 1 in upper hemisphere, engines are in idle
  --  @field #Distance detectionDistanceMaximal ..., engines are in maximal mode
  --  @field #Distance detectionDistanceAfterburner ..., engines are in afterburner mode
  
  --- An RWR.
  --  @type Unit.RWR 
  --  @extends #Unit.Sensor
  
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
  -- @return #Group
  
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
  -- @return #boolean, Wrapper.Object#Object
  
  --- Returns unit descriptor. Descriptor type depends on unit category. 
  -- @function [parent=#Unit] getDesc
  -- @param #Unit self
  -- @return #Unit.Desc
  
  
  Unit = {} --#Unit

end -- Unit


do -- Group

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
  -- @return #coalition.side
  
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
  -- @return #Unit
  
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
  -- @return #list<#Unit> array of Units
  
  --- Returns controller of the group. 
  -- @function [parent=#Group] getController
  -- @param #Group self 
  -- @return #Controller
  
  Group = {} --#Group

end -- Group


do -- AI

  --- @type AI
  -- @field #AI.Skill Skill
  -- @field #AI.Task Task
  -- @field #AI.Option Option
  
  --- @type AI.Skill
  -- @field AVERAGE
  -- @field GOOD
  -- @field HIGH
  -- @field EXCELLENT
  -- @field PLAYER
  -- @field CLIENT
  
  --- @type AI.Task
  -- @field #AI.Task.WeaponExpend WeaponExpend
  -- @field #AI.Task.OrbitPattern OrbitPattern
  -- @field #AI.Task.Designation Designation
  -- @field #AI.Task.WaypointType WaypointType
  -- @field #AI.Task.TurnMethod TurnMethod
  -- @field #AI.Task.AltitudeType AltitudeType
  -- @field #AI.Task.VehicleFormation VehicleFormation
  
  --- @type AI.Task.WeaponExpend
  -- @field ONE
  -- @field TWO
  -- @field FOUR
  -- @field QUARTER
  -- @field HALF
  -- @field ALL
  
  --- @type AI.Task.OrbitPattern
  -- @field CIRCLE
  -- @field RACE_TRACK
  
  --- @type AI.Task.Designation
  -- @field NO
  -- @field AUTO
  -- @field WP
  -- @field IR_POINTER
  -- @field LASER
  
  --- @type AI.Task.WaypointType
  -- @field TAKEOFF
  -- @field TAKEOFF_PARKING
  -- @field TURNING_POINT
  -- @field LAND
  
  --- @type AI.Task.TurnMethod
  -- @field FLY_OVER_POINT
  -- @field FIN_POINT
  
  --- @type AI.Task.AltitudeType
  -- @field BARO
  -- @field RADIO
  
  --- @type AI.Task.VehicleFormation
  -- @field OFF_ROAD
  -- @field ON_ROAD
  -- @field RANK
  -- @field CONE
  -- @field DIAMOND
  -- @field VEE
  -- @field ECHELON_LEFT
  -- @field ECHELON_RIGHT
  
  --- @type AI.Option
  -- @field #AI.Option.Air                          Air
  -- @field #AI.Option.Ground                       Ground
  -- @field #AI.Option.Naval                        Naval
  
  --- @type AI.Option.Air
  -- @field #AI.Option.Air.id                       id
  -- @field #AI.Option.Air.val                      val
  
  --- @type AI.Option.Ground
  -- @field #AI.Option.Ground.id                    id
  -- @field #AI.Option.Ground.val                   val
  
  --- @type AI.Option.Naval
  -- @field #AI.Option.Naval.id                     id
  -- @field #AI.Option.Naval.val                    val
  
  --TODO: work on formation
  --- @type AI.Option.Air.id
  -- @field NO_OPTION
  -- @field ROE
  -- @field REACTION_ON_THREAT
  -- @field RADAR_USING
  -- @field FLARE_USING
  -- @field FORMATION
  -- @field RTB_ON_BINGO
  -- @field SILENCE 
  
  --- @type AI.Option.Air.val
  -- @field #AI.Option.Air.val.ROE ROE
  -- @field #AI.Option.Air.val.REACTION_ON_THREAT REACTION_ON_THREAT
  -- @field #AI.Option.Air.val.RADAR_USING RADAR_USING
  -- @field #AI.Option.Air.val.FLARE_USING FLARE_USING
  
  --- @type AI.Option.Air.val.ROE
  -- @field WEAPON_FREE
  -- @field OPEN_FIRE_WEAPON_FREE
  -- @field OPEN_FIRE
  -- @field RETURN_FIRE
  -- @field WEAPON_HOLD
   
  --- @type AI.Option.Air.val.REACTION_ON_THREAT
  -- @field NO_REACTION
  -- @field PASSIVE_DEFENCE
  -- @field EVADE_FIRE
  -- @field BYPASS_AND_ESCAPE
  -- @field ALLOW_ABORT_MISSION
  
  --- @type AI.Option.Air.val.RADAR_USING
  -- @field NEVER
  -- @field FOR_ATTACK_ONLY
  -- @field FOR_SEARCH_IF_REQUIRED
  -- @field FOR_CONTINUOUS_SEARCH
  
  --- @type AI.Option.Air.val.FLARE_USING
  -- @field NEVER
  -- @field AGAINST_FIRED_MISSILE
  -- @field WHEN_FLYING_IN_SAM_WEZ
  -- @field WHEN_FLYING_NEAR_ENEMIES
  
  --- @type AI.Option.Ground.id
  -- @field NO_OPTION
  -- @field ROE @{#AI.Option.Ground.val.ROE}
  -- @field DISPERSE_ON_ATTACK true or false
  -- @field ALARM_STATE @{#AI.Option.Ground.val.ALARM_STATE}
  
  --- @type AI.Option.Ground.val
  -- @field #AI.Option.Ground.val.ROE               ROE
  -- @field #AI.Option.Ground.val.ALARM_STATE       ALARM_STATE
  
  --- @type AI.Option.Ground.val.ROE
  -- @field OPEN_FIRE
  -- @field RETURN_FIRE
  -- @field WEAPON_HOLD
  
  --- @type AI.Option.Ground.val.ALARM_STATE
  -- @field AUTO
  -- @field GREEN
  -- @field RED
  
  --- @type AI.Option.Naval.id
  -- @field NO_OPTION
  -- @field ROE
  
  --- @type AI.Option.Naval.val
  -- @field #AI.Option.Naval.val.ROE ROE
  
  --- @type AI.Option.Naval.val.ROE
  -- @field OPEN_FIRE
  -- @field RETURN_FIRE
  -- @field WEAPON_HOLD
  
  AI = {} --#AI

end -- AI



