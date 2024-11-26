--- **DCS API** Prototypes.
-- 
-- ===
-- 
-- See the [Simulator Scripting Engine Documentation](https://wiki.hoggitworld.com/view/Simulator_Scripting_Engine_Documentation) on Hoggit for further explanation and examples.
-- 
-- @module DCS
-- @image MOOSE.JPG

do -- world

  --- [DCS Enum world](https://wiki.hoggitworld.com/view/DCS_enum_world)
  -- @type world
  -- @field #world.event event [https://wiki.hoggitworld.com/view/DCS_enum_world](https://wiki.hoggitworld.com/view/DCS_enum_world)
  -- @field #world.BirthPlace BirthPlace The birthplace enumerator is used to define where an aircraft or helicopter has spawned in association with birth events.
  -- @field #world.VolumeType VolumeType The volumeType enumerator defines the types of 3d geometery used within the [world.searchObjects](https://wiki.hoggitworld.com/view/DCS_func_searchObjects) function.
  -- @field #world.weather weather Weather functions for fog etc.

  --- The world singleton contains functions centered around two different but extremely useful functions.
  -- * Events and event handlers are all governed within world.
  -- * A number of functions to get information about the game world.
  -- 
  -- See [https://wiki.hoggitworld.com/view/DCS_singleton_world](https://wiki.hoggitworld.com/view/DCS_singleton_world)
  -- @field #world world
  world = {}
  
  --- [https://wiki.hoggitworld.com/view/DCS_enum_world](https://wiki.hoggitworld.com/view/DCS_enum_world)
  -- @type world.event
  -- @field S_EVENT_INVALID = 0
  -- @field S_EVENT_SHOT = 1
  -- @field S_EVENT_HIT = 2
  -- @field S_EVENT_TAKEOFF = 3
  -- @field S_EVENT_LAND = 4
  -- @field S_EVENT_CRASH = 5
  -- @field S_EVENT_EJECTION = 6
  -- @field S_EVENT_REFUELING = 7
  -- @field S_EVENT_DEAD = 8
  -- @field S_EVENT_PILOT_DEAD = 9
  -- @field S_EVENT_BASE_CAPTURED = 10
  -- @field S_EVENT_MISSION_START = 11
  -- @field S_EVENT_MISSION_END = 12
  -- @field S_EVENT_TOOK_CONTROL = 13
  -- @field S_EVENT_REFUELING_STOP = 14
  -- @field S_EVENT_BIRTH = 15
  -- @field S_EVENT_HUMAN_FAILURE = 16
  -- @field S_EVENT_DETAILED_FAILURE = 17
  -- @field S_EVENT_ENGINE_STARTUP = 18
  -- @field S_EVENT_ENGINE_SHUTDOWN = 19
  -- @field S_EVENT_PLAYER_ENTER_UNIT = 20
  -- @field S_EVENT_PLAYER_LEAVE_UNIT = 21
  -- @field S_EVENT_PLAYER_COMMENT = 22
  -- @field S_EVENT_SHOOTING_START = 23
  -- @field S_EVENT_SHOOTING_END = 24
  -- @field S_EVENT_MARK_ADDED  = 25 
  -- @field S_EVENT_MARK_CHANGE = 26
  -- @field S_EVENT_MARK_REMOVED = 27
  -- @field S_EVENT_KILL = 28
  -- @field S_EVENT_SCORE = 29
  -- @field S_EVENT_UNIT_LOST = 30
  -- @field S_EVENT_LANDING_AFTER_EJECTION = 31
  -- @field S_EVENT_PARATROOPER_LENDING = 32 -- who's lending whom what? ;)
  -- @field S_EVENT_DISCARD_CHAIR_AFTER_EJECTION = 33 
  -- @field S_EVENT_WEAPON_ADD = 34
  -- @field S_EVENT_TRIGGER_ZONE = 35
  -- @field S_EVENT_LANDING_QUALITY_MARK = 36
  -- @field S_EVENT_BDA = 37 -- battle damage assessment
  -- @field S_EVENT_AI_ABORT_MISSION = 38 
  -- @field S_EVENT_DAYNIGHT = 39 
  -- @field S_EVENT_FLIGHT_TIME = 40 
  -- @field S_EVENT_PLAYER_SELF_KILL_PILOT = 41 
  -- @field S_EVENT_PLAYER_CAPTURE_AIRFIELD = 42 
  -- @field S_EVENT_EMERGENCY_LANDING = 43
  -- @field S_EVENT_UNIT_CREATE_TASK = 44
  -- @field S_EVENT_UNIT_DELETE_TASK = 45
  -- @field S_EVENT_SIMULATION_START = 46
  -- @field S_EVENT_WEAPON_REARM = 47
  -- @field S_EVENT_WEAPON_DROP = 48
  -- @field S_EVENT_UNIT_TASK_COMPLETE = 49
  -- @field S_EVENT_UNIT_TASK_STAGE = 50
  -- @field S_EVENT_MAC_EXTRA_SCORE= 51 -- not sure what this is
  -- @field S_EVENT_MISSION_RESTART= 52
  -- @field S_EVENT_MISSION_WINNER = 53
  -- @field S_EVENT_RUNWAY_TAKEOFF= 54 
  -- @field S_EVENT_RUNWAY_TOUCH= 55 
  -- @field S_EVENT_MAC_LMS_RESTART= 56 -- not sure what this is
  -- @field S_EVENT_SIMULATION_FREEZE = 57 
  -- @field S_EVENT_SIMULATION_UNFREEZE = 58 
  -- @field S_EVENT_HUMAN_AIRCRAFT_REPAIR_START = 59 
  -- @field S_EVENT_HUMAN_AIRCRAFT_REPAIR_FINISH = 60   
  -- @field S_EVENT_MAX = 61
  
  --- The birthplace enumerator is used to define where an aircraft or helicopter has spawned in association with birth events.
  -- @type world.BirthPlace
  -- @field wsBirthPlace_Air
  -- @field wsBirthPlace_RunWay
  -- @field wsBirthPlace_Park
  -- @field wsBirthPlace_Heliport_Hot
  -- @field wsBirthPlace_Heliport_Cold

  --- The volumeType enumerator defines the types of 3d geometery used within the #world.searchObjects function.
  -- @type world.VolumeType
  -- @field SEGMENT
  -- @field BOX
  -- @field SPHERE
  -- @field PYRAMID

  --- Adds a function as an event handler that executes whenever a simulator event occurs. See [hoggit](https://wiki.hoggitworld.com/view/DCS_func_addEventHandler).
  -- @function [parent=#world] addEventHandler
  -- @param #table handler Event handler table.
  
  --- Removes the specified event handler from handling events.
  -- @function [parent=#world] removeEventHandler
  -- @param #table handler Event handler table.
  
  --- Returns a table of the single unit object in the game who's skill level is set as "Player". See [hoggit](https://wiki.hoggitworld.com/view/DCS_func_getPlayer).
  -- There is only a single player unit in a mission and in single player the user will always spawn into this unit automatically unless other client or Combined Arms slots are available.
  -- @function [parent=#world] getPlayer
  -- @return DCS#Unit  
  
  --- Searches a defined volume of 3d space for the specified objects within it and then can run function on each returned object. See [hoggit](https://wiki.hoggitworld.com/view/DCS_func_searchObjects).
  -- @function [parent=#world] searchObjects
  -- @param DCS#Object.Category objectcategory Category (can be a table) of objects to search.
  -- @param DCS#word.VolumeType volume Shape of the search area/volume.
  -- @param ObjectSeachHandler handler A function that handles the search.
  -- @param #table any Additional data.
  -- @return DCS#Unit  
  
  --- Returns a table of mark panels indexed numerically that are present within the mission. See [hoggit](https://wiki.hoggitworld.com/view/DCS_func_getMarkPanels)
  -- @function [parent=#world] getMarkPanels
  -- @return #table Table of marks.

  --- Returns a table of DCS airbase objects.
  -- @function [parent=#world] getAirbases
  -- @param #number coalitionId The coalition side number ID. Default is all airbases are returned.
  -- @return #table Table of DCS airbase objects.


  --- Weather functions.
  -- @type world.weather

  --- Fog animation data structure.
  -- @type world.FogAnimation
  -- @field #number time
  -- @field #number visibility
  -- @field #number thickness

  --- Returns the current fog thickness.
  -- @function [parent=#world.weather] getFogThickness Returns the fog thickness.
  -- @return #number Fog thickness in meters. If there is no fog, zero is returned.

  --- Sets the fog thickness instantly. Any current fog animation is discarded.
  -- @function [parent=#world.weather] setFogThickness
  -- @param #number thickness Fog thickness in meters. Set to zero to disable fog.

  --- Returns the current fog visibility distance.
  -- @function [parent=#world.weather] getFogVisibilityDistance Returns the current maximum visibility distance in meters. Returns zero if fog is not present.

  --- Instantly sets the maximum visibility distance of fog at sea level when looking at the horizon. Any current fog animation is discarded. Set zero to disable the fog.
  -- @function [parent=#world.weather] setFogVisibilityDistance
  -- @param #number visibility Max fog visibility in meters. Set to zero to disable fog.

  --- Sets fog animation keys. Time is set in seconds and relative to the current simulation time, where time=0 is the current moment. 
  -- Time must be increasing. Previous animation is always discarded despite the data being correct.
  -- @function [parent=#world.weather] setFogAnimation
  -- @param #world.FogAnimation animation List of fog animations
 
end -- world


do -- env

  --- [DCS Singleton env](https://wiki.hoggitworld.com/view/DCS_singleton_env)
  -- @type env

  --- Add message to simulator log with caption "INFO". Message box is optional.
  -- @function [parent=#env] info
  -- @param #string message message string to add to log.
  -- @param #boolean showMessageBox If the parameter is true Message Box will appear. Optional.
  
  --- Add message to simulator log with caption "WARNING". Message box is optional. 
  -- @function [parent=#env] warning
  -- @param #string message message string to add to log.
  -- @param #boolean showMessageBox If the parameter is true Message Box will appear. Optional.
  
  --- Add message to simulator log with caption "ERROR". Message box is optional.
  -- @function [parent=#env] error
  -- @param #string message message string to add to log.
  -- @param #boolean showMessageBox If the parameter is true Message Box will appear. Optional.
  
  --- Enables/disables appearance of message box each time lua error occurs.
  -- @function [parent=#env] setErrorMessageBoxEnabled
  -- @param #boolean on if true message box appearance is enabled.

  --- [DCS Singleton env](https://wiki.hoggitworld.com/view/DCS_singleton_env)
  env = {} --#env 
  
end -- env

do -- radio

  ---@type radio
  -- @field #radio.modulation modulation
  
  ---
  -- @type radio.modulation
  -- @field AM
  -- @field FM
  
  radio = {}
  radio.modulation = {}
  radio.modulation.AM = 0  
  radio.modulation.FM = 1
  
end

do -- timer

  --- [DCS Singleton timer](https://wiki.hoggitworld.com/view/DCS_singleton_timer)
  -- @type timer
  
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
  
  --- [DCS Singleton timer](https://wiki.hoggitworld.com/view/DCS_singleton_timer)
  timer = {} --#timer

end 


do -- land

  --- [DCS Singleton land](https://wiki.hoggitworld.com/view/DCS_singleton_land)
  -- @type land
  -- @field #land.SurfaceType SurfaceType
  
  --- [Type of surface enumerator](https://wiki.hoggitworld.com/view/DCS_singleton_land)
  -- @type land.SurfaceType
  -- @field LAND Land=1
  -- @field SHALLOW_WATER Shallow water=2
  -- @field WATER Water=3
  -- @field ROAD Road=4
  -- @field RUNWAY Runway=5
  
  --- Returns the distance from sea level (y-axis) of a given vec2 point.
  -- @function [parent=#land] getHeight
  -- @param #Vec2 point Point on the ground. 
  -- @return #number Height in meters.

  --- Returns the surface height and depth of a point. Useful for checking if the path is deep enough to support a given ship. 
  -- Both values are positive. When checked over water at sea level the first value is always zero. 
  -- When checked over water at altitude, for example the reservoir of the Inguri Dam, the first value is the corresponding altitude the water level is at.
  -- @function [parent=#land] getSurfaceHeightWithSeabed
  -- @param #Vec2 point Position where to check.
  -- @return #number Height in meters.
  -- @return #number Depth in meters.
  
  --- Returns surface type at the given point.
  -- @function [parent=#land] getSurfaceType
  -- @param #Vec2 point Point on the land. 
  -- @return #number Enumerator value from `land.SurfaceType` (LAND=1, SHALLOW_WATER=2, WATER=3, ROAD=4, RUNWAY=5)
  
  --- [DCS Singleton land](https://wiki.hoggitworld.com/view/DCS_singleton_land)
  land = {} --#land

end -- land

do -- country

  --- [DCS Enum country](https://wiki.hoggitworld.com/view/DCS_enum_country)
  -- @type country
  -- @field #country.id id 
  
  
  --- [DCS enumerator country](https://wiki.hoggitworld.com/view/DCS_enum_country)
  -- @type country.id
  -- @field RUSSIA
  -- @field UKRAINE
  -- @field USA
  -- @field TURKEY
  -- @field UK
  -- @field FRANCE
  -- @field GERMANY
  -- @field AGGRESSORS
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
  -- @field AUSTRALIA
  -- @field SWITZERLAND
  -- @field AUSTRIA
  -- @field BELARUS
  -- @field BULGARIA
  -- @field CHEZH_REPUBLIC
  -- @field CHINA
  -- @field CROATIA
  -- @field EGYPT
  -- @field FINLAND
  -- @field GREECE
  -- @field HUNGARY
  -- @field INDIA
  -- @field IRAN
  -- @field IRAQ
  -- @field JAPAN
  -- @field KAZAKHSTAN
  -- @field NORTH_KOREA
  -- @field PAKISTAN
  -- @field POLAND
  -- @field ROMANIA
  -- @field SAUDI_ARABIA
  -- @field SERBIA
  -- @field SLOVAKIA
  -- @field SOUTH_KOREA
  -- @field SWEDEN
  -- @field SYRIA
  -- @field YEMEN
  -- @field VIETNAM
  -- @field VENEZUELA
  -- @field TUNISIA
  -- @field THAILAND
  -- @field SUDAN
  -- @field PHILIPPINES
  -- @field MOROCCO
  -- @field MEXICO
  -- @field MALAYSIA
  -- @field LIBYA
  -- @field JORDAN
  -- @field INDONESIA
  -- @field HONDURAS
  -- @field ETHIOPIA
  -- @field CHILE
  -- @field BRAZIL 
  -- @field BAHRAIN
  -- @field THIRDREICH
  -- @field YUGOSLAVIA
  -- @field USSR
  -- @field ITALIAN_SOCIAL_REPUBLIC
  -- @field ALGERIA
  -- @field KUWAIT
  -- @field QATAR
  -- @field OMAN
  -- @field UNITED_ARAB_EMIRATES
  -- @field SOUTH_AFRICA
  -- @field CUBA
  -- @field PORTUGAL
  -- @field GDR
  -- @field LEBANON
  -- @field CJTF_BLUE
  -- @field CJTF_RED
  -- @field UN_PEACEKEEPERS
  -- @field Argentinia
  -- @field Cyprus
  -- @field Slovenia
  -- @field BOLIVIA
  -- @field GHANA
  -- @field NIGERIA
  -- @field PERU
  -- @field ECUADOR

  country = {} --#country

end -- country


do -- Command

  -- @type Command
  -- @field #string id
  -- @field #Command.params params
  
  -- @type Command.params

end -- Command

do -- coalition

  --- [DCS Enum coalition](https://wiki.hoggitworld.com/view/DCS_enum_coalition)
  -- @type coalition
  -- @field #coalition.side side
  
  --- [DCS Enum coalition.side](https://wiki.hoggitworld.com/view/DCS_enum_coalition)
  -- @type coalition.side
  -- @field NEUTRAL
  -- @field RED
  -- @field BLUE
  
  --- Get country coalition.
  -- @function [parent=#coalition] getCountryCoalition
  -- @param #number countryId Country ID.
  -- @return #number coalitionId Coalition ID.

  --- Dynamically spawns a group. See [hoggit](https://wiki.hoggitworld.com/view/DCS_func_addGroup)
  -- @function [parent=#coalition] addGroup
  -- @param #number countryId Id of the country.
  -- @param #number groupCategory Group category. Set -1 for spawning FARPS.
  -- @param #table groupData Group data table.
  -- @return DCS#Group The spawned Group object.

  --- Dynamically spawns a static object. See [hoggit](https://wiki.hoggitworld.com/view/DCS_func_addStaticObject)
  -- @function [parent=#coalition] addStaticObject
  -- @param #number countryId Id of the country.
  -- @param #table groupData Group data table.
  -- @return DCS#Static The spawned static object.
  
  coalition = {} -- #coalition

end -- coalition


do -- Types

  --- Descriptors.
  -- @type Desc
  -- @field #number speedMax0 Max speed in meters/second at zero altitude.
  -- @field #number massEmpty Empty mass in kg.
  -- @field #number tankerType Type of refueling system: 0=boom, 1=probe.
  -- @field #number range Range in km(?).
  -- @field #table box Bounding box.
  -- @field #number Hmax Max height in meters.
  -- @field #number Kmax ?
  -- @field #number speedMax10K Max speed in meters/second at 10k altitude.
  -- @field #number NyMin ?
  -- @field #number NyMax ?
  -- @field #number fuelMassMax Max fuel mass in kg.
  -- @field #number speedMax10K Max speed in meters/second.
  -- @field #number massMax Max mass of unit.
  -- @field #number RCS ?
  -- @field #number life Life points.
  -- @field #number VyMax Max vertical velocity in m/s.
  -- @field #number Kab ?
  -- @field #table attributes Table of attributes.
  -- @field #TypeName typeName Type Name.
  -- @field #string displayName Localized display name.
  -- @field #number category Unit category.
  
  --- A distance type
  -- @type Distance
  
  --- An angle type
  -- @type Angle
  
  --- Time is given in seconds.
  -- @type Time
  -- @extends #number Time in seconds.
  
  --- Model time is the time that drives the simulation. Model time may be stopped, accelerated and decelerated relative real time. 
  -- @type ModelTime
  -- @extends #number
  
  --- Mission time is a model time plus time of the mission start.
  -- @type MissionTime
  -- @extends #number Time in seconds.
  
  
  --- Distance is given in meters.
  -- @type Distance
  -- @extends #number Distance in meters.
  
  --- Angle is given in radians.
  -- @type Angle
  -- @extends #number Angle in radians.
  
  --- Azimuth is an angle of rotation around world axis y counter-clockwise.
  -- @type Azimuth
  -- @extends #number Angle in radians.
  
  --- Mass is given in kilograms.
  -- @type Mass
  -- @extends #number
  
  --- Vec3 type is a 3D-vector.
  -- DCS world has 3-dimensional coordinate system. DCS ground is an infinite plain.
  -- @type Vec3
  -- @field #Distance x is directed to the North
  -- @field #Distance z is directed to the East
  -- @field #Distance y is directed up
  
  --- Vec2 is a 2D-vector for the ground plane as a reference plane.
  -- @type Vec2
  -- @field #Distance x Vec2.x = Vec3.x
  -- @field #Distance y Vec2.y = Vec3.z
  
  --- Position is a composite structure. It consists of both coordinate vector and orientation matrix. Position3 (also known as "Pos3" for short) is a table that has following format: 
  -- @type Position3
  -- @field #Vec3 p 3D position vector.
  -- @field #Vec3 x Orientation component of vector pointing East.
  -- @field #Vec3 y Orientation component of vector pointing up.
  -- @field #Vec3 z Orientation component of vector pointing North.
  
  --- 3-dimensional box.
  -- @type Box3
  -- @field #Vec3 min Min.
  -- @field #Vec3 max Max
  
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

  -- @type Zone
  -- @field DCSVec3#Vec3 point
  -- @field #number radius

  Zone = {}

  -- @type ModelTime
  -- @extends #number
  
  -- @type Time
  -- @extends #number
  
  --- A task descriptor (internal structure for DCS World). See [https://wiki.hoggitworld.com/view/Category:Tasks](https://wiki.hoggitworld.com/view/Category:Tasks).
  -- In MOOSE, these tasks can be accessed via @{Wrapper.Controllable#CONTROLLABLE}.
  -- @type Task
  -- @field #string id
  -- @field #Task.param param
  
  -- @type Task.param
  
  --- List of @{#Task}
  -- @type TaskArray
  -- @list <#Task>

  ---
  --@type WaypointAir
  --@field #boolean lateActivated
  --@field #boolean uncontrolled

  --- DCS template data structure.
  -- @type Template
  -- @field #boolean uncontrolled Aircraft is uncontrolled.
  -- @field #boolean lateActivation Group is late activated.
  -- @field #number x 2D Position on x-axis in meters.
  -- @field #number y 2D Position on y-axis in meters.
  -- @field #table units Unit list.
  -- 
  
  --- Unit data structure.
  --@type Template.Unit
  --@field #string name Name of the unit.
  --@field #number x
  --@field #number y
  --@field #number alt

end --



do -- Object

  --- [DCS Class Object](https://wiki.hoggitworld.com/view/DCS_Class_Object)
  -- @type Object
  -- @field #Object.Category Category
  -- @field #Object.Desc Desc
  
  --- [DCS Enum Object.Category](https://wiki.hoggitworld.com/view/DCS_Class_Object)
  -- @type Object.Category
  -- @field UNIT
  -- @field WEAPON
  -- @field STATIC
  -- @field BASE
  -- @field SCENERY
  -- @field CARGO
  
  -- @type Object.Desc
  -- @extends #Desc
  -- @field #number life initial life level
  -- @field #Box3 box bounding box of collision geometry
  
  --- @function [parent=#Object] isExist
  -- @param #Object self
  -- @return #boolean

  --- @function [parent=#Object] isActive
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
  -- @return #Vec3 3D position vector with x,y,z components.
  
  --- Returns object position for current time. 
  -- @function [parent=#Object] getPosition
  -- @param #Object self
  -- @return #Position3
  
  --- Returns the unit's velocity vector.
  -- @function [parent=#Object] getVelocity
  -- @param #Object self
  -- @return #Vec3 3D velocity vector.
  
  --- Returns true if the unit is in air.
  -- @function [parent=#Object] inAir
  -- @param #Object self
  -- @return #boolean
  
  Object = {} --#Object

end -- Object

do -- CoalitionObject

  --- [DCS Class CoalitionObject](https://wiki.hoggitworld.com/view/DCS_Class_Coalition_Object)
  -- @type CoalitionObject
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


do -- Weapon

  --- [DCS Class Weapon](https://wiki.hoggitworld.com/view/DCS_Class_Weapon)
  -- @type Weapon
  -- @extends #CoalitionObject
  -- @field #Weapon.flag flag enum stores weapon flags. Some of them are combination of another flags.
  -- @field #Weapon.Category Category enum that stores weapon categories.
  -- @field #Weapon.GuidanceType GuidanceType enum that stores guidance methods. Available only for guided weapon (Weapon.Category.MISSILE and some Weapon.Category.BOMB).
  -- @field #Weapon.MissileCategory MissileCategory enum that stores missile category. Available only for missiles (Weapon.Category.MISSILE). 
  -- @field #Weapon.WarheadType WarheadType enum that stores warhead types.
  -- @field #Weapon.Desc Desc The descriptor of a weapon.

  --- enum stores weapon flags. Some of them are combination of another flags.
  -- @type Weapon.flag
  -- @field LGB
  -- @field TvGB
  -- @field SNSGB
  -- @field HEBomb
  -- @field Penetrator
  -- @field NapalmBomb
  -- @field FAEBomb
  -- @field ClusterBomb
  -- @field Dispencer
  -- @field CandleBomb
  -- @field ParachuteBomb
  -- @field GuidedBomb = LGB + TvGB + SNSGB
  -- @field AnyUnguidedBomb  = HEBomb + Penetrator + NapalmBomb + FAEBomb + ClusterBomb + Dispencer + CandleBomb + ParachuteBomb
  -- @field AnyBomb = GuidedBomb + AnyUnguidedBomb
  -- @field LightRocket
  -- @field MarkerRocket
  -- @field CandleRocket
  -- @field HeavyRocket
  -- @field AnyRocket = LightRocket + HeavyRocket + MarkerRocket + CandleRocket
  -- @field AntiRadarMissile
  -- @field AntiShipMissile
  -- @field AntiTankMissile
  -- @field FireAndForgetASM
  -- @field LaserASM
  -- @field TeleASM
  -- @field CruiseMissile
  -- @field GuidedASM = LaserASM + TeleASM
  -- @field TacticASM = GuidedASM + FireAndForgetASM 
  -- @field AnyASM = AntiRadarMissile + AntiShipMissile + AntiTankMissile + FireAndForgetASM + GuidedASM + CruiseMissile
  -- @field SRAAM
  -- @field MRAAM 
  -- @field LRAAM 
  -- @field IR_AAM 
  -- @field SAR_AAM 
  -- @field AR_AAM 
  -- @field AnyAAM = IR_AAM + SAR_AAM + AR_AAM + SRAAM + MRAAM + LRAAM 
  -- @field AnyMissile = AnyASM + AnyAAM
  -- @field AnyAutonomousMissile = IR_AAM + AntiRadarMissile + AntiShipMissile + FireAndForgetASM + CruiseMissile
  -- @field GUN_POD
  -- @field BuiltInCannon
  -- @field Cannons = GUN_POD + BuiltInCannon 
  -- @field AnyAGWeapon = BuiltInCannon + GUN_POD + AnyBomb + AnyRocket + AnyASM
  -- @field AnyAAWeapon = BuiltInCannon + GUN_POD + AnyAAM
  -- @field UnguidedWeapon = Cannons + BuiltInCannon + GUN_POD + AnyUnguidedBomb + AnyRocket
  -- @field GuidedWeapon = GuidedBomb + AnyASM + AnyAAM
  -- @field AnyWeapon = AnyBomb + AnyRocket + AnyMissile + Cannons
  -- @field MarkerWeapon = MarkerRocket + CandleRocket + CandleBomb
  -- @field ArmWeapon = AnyWeapon - MarkerWeapon

  --- Weapon.Category enum that stores weapon categories.
  -- @type Weapon.Category
  -- @field #number SHELL Shell.
  -- @field #number MISSILE Missile
  -- @field #number ROCKET Rocket.
  -- @field #number BOMB Bomb.
  -- @field #number TORPEDO Torpedo.
  

  --- Weapon.GuidanceType enum that stores guidance methods. Available only for guided weapon (Weapon.Category.MISSILE and some Weapon.Category.BOMB). 
  -- @type Weapon.GuidanceType
  -- @field INS
  -- @field IR
  -- @field RADAR_ACTIVE
  -- @field RADAR_SEMI_ACTIVE
  -- @field RADAR_PASSIVE
  -- @field TV
  -- @field LASER
  -- @field TELE 

  
  --- Weapon.MissileCategory enum that stores missile category. Available only for missiles (Weapon.Category.MISSILE). 
  -- @type Weapon.MissileCategory
  -- @field AAM
  -- @field SAM
  -- @field BM
  -- @field ANTI_SHIP
  -- @field CRUISE
  -- @field OTHER

  --- Weapon.WarheadType enum that stores warhead types. 
  -- @type Weapon.WarheadType
  -- @field AP
  -- @field HE
  -- @field SHAPED_EXPLOSIVE
  
  --- Returns the unit that launched the weapon.
  -- @function [parent=#Weapon] getLauncher
  -- @param #Weapon self
  -- @return #Unit
  
  --- returns target of the guided weapon. Unguided weapons and guided weapon that is targeted at the point on the ground will return nil. 
  -- @function [parent=#Weapon] getTarget
  -- @param #Weapon self
  -- @return #Object
  
  --- returns weapon descriptor. Descriptor type depends on weapon category.  
  -- @function [parent=#Weapon] getDesc
  -- @param #Weapon self
  -- @return #Weapon.Desc



  Weapon = {} --#Weapon

end -- Weapon


do -- Airbase

  --- [DCS Class Airbase](https://wiki.hoggitworld.com/view/DCS_Class_Airbase)
  -- Represents airbases: airdromes, helipads and ships with flying decks or landing pads.  
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

  --- Returns the warehouse object associated with the airbase object. Can then be used to call the warehouse class functions to modify the contents of the warehouse.
  -- @function [parent=#Airbase] getWarehouse
  -- @param self
  -- @return #Warehouse The DCS warehouse object of this airbase.

  --- Enables or disables the airbase and FARP auto capture game mechanic where ownership of a base can change based on the presence of ground forces or the 
  -- default setting assigned in the editor.
  -- @function [parent=#Airbase] autoCapture
  -- @param self
  -- @param #boolean setting `true` : enables autoCapture behavior, `false` : disables autoCapture behavior

  --- Returns the current autoCapture setting for the passed base.
  -- @function [parent=#Airbase] autoCaptureIsOn
  -- @param self
  -- @return #boolean `true` if autoCapture behavior is enabled and `false` otherwise.

  --- Changes the passed airbase object's coalition to the set value. Must be used with Airbase.autoCapture to disable auto capturing of the base, 
  -- otherwise the base can revert back to a different coalition depending on the situation and built in game capture rules.
  -- @function [parent=#Airbase] setCoalition
  -- @param self
  -- @param #number coa The new owner coalition: 0=neutra, 1=red, 2=blue.

  --- Returns the wsType of every object that exists in DCS. A wsType is a table consisting of 4 entries indexed numerically. 
  -- It can be used to broadly categorize object types. The table can be broken down as: {mainCategory, subCat1, subCat2, index}
  -- @function [parent=#Airbase] getResourceMap
  -- @param self
  -- @return #table wsType of every object that exists in DCS.

  Airbase = {} --#Airbase

end -- Airbase


do -- Warehouse

  --- [DCS Class Warehouse](https://wiki.hoggitworld.com/view/DCS_Class_Warehouse)
  -- The warehouse class gives control over warehouses that exist in airbase objects. These warehouses can limit the aircraft, munitions, and fuel available to coalition aircraft.
  -- @type Warehouse

  
  --- Get a warehouse by passing its name.
  -- @function [parent=#Warehouse] getByName
  -- @param #string Name Name of the warehouse.
  -- @return #Warehouse The warehouse object.

  --- Adds the passed amount of a given item to the warehouse.
  -- itemName is the typeName associated with the item: "weapons.missiles.AIM_54C_Mk47"
  -- A wsType table can also be used, however the last digit with wsTypes has been known to change. {4, 4, 7, 322}
  -- @function [parent=#Warehouse] addItem
  -- @param self
  -- @param #string itemName Name of the item.
  -- @param #number count Number of items to add.

  --- Returns the number of the passed type of item currently in a warehouse object.
  -- @function [parent=#Warehouse] getItemCount
  -- @param self
  -- @param #string itemName Name of the item.

  --- Sets the passed amount of a given item to the warehouse.
  -- @function [parent=#Warehouse] setItem
  -- @param self
  -- @param #string itemName Name of the item.
  -- @param #number count Number of items to add.

  --- Removes the amount of the passed item from the warehouse.
  -- @function [parent=#Warehouse] removeItem
  -- @param self
  -- @param #string itemName Name of the item.
  -- @param #number count Number of items to be removed.

  --- Adds the passed amount of a liquid fuel into the warehouse inventory.
  -- @function [parent=#Warehouse] addLiquid
  -- @param self
  -- @param #number liquidType Type of liquid to add: 0=jetfuel, 1=aviation gasoline, 2=MW50, 3=Diesel.
  -- @param #number count Amount of liquid to add.

  --- Returns the amount of the passed liquid type within a given warehouse.
  -- @function [parent=#Warehouse] getLiquidAmount
  -- @param self
  -- @param #number liquidType Type of liquid to add: 0=jetfuel, 1=aviation gasoline, 2=MW50, 3=Diesel.
  -- @return #number Amount of liquid.

  --- Sets the passed amount of a liquid fuel into the warehouse inventory.
  -- @function [parent=#Warehouse] setLiquidAmount
  -- @param self
  -- @param #number liquidType Type of liquid to add: 0=jetfuel, 1=aviation gasoline, 2=MW50, 3=Diesel.
  -- @param #number count Amount of liquid.

  --- Removes the set amount of liquid from the inventory in a warehouse.
  -- @function [parent=#Warehouse] setLiquidAmount
  -- @param self
  -- @param #number liquidType Type of liquid to add: 0=jetfuel, 1=aviation gasoline, 2=MW50, 3=Diesel.
  -- @param #number count Amount of liquid.

  --- Returns the airbase object associated with the warehouse object.
  -- @function [parent=#Warehouse] getOwner
  -- @param self
  -- @return #Airbase The airbase object owning this warehouse.

  --- Returns a full itemized list of everything currently in a warehouse. If a category is set to unlimited then the table will be returned empty.
  -- Aircraft and weapons are indexed by strings. Liquids are indexed by number.
  -- @function [parent=#Warehouse] getInventory
  -- @param self
  -- @param #string itemName Name of the item.
  -- @return #table Itemized list of everything currently in a warehouse


  Warehouse = {} --#Warehouse 

end

do -- Spot

  --- [DCS Class Spot](https://wiki.hoggitworld.com/view/DCS_Class_Spot)
  -- Represents a spot from laser or IR-pointer.
  -- @type Spot 
  -- @field #Spot.Category Category enum that stores spot categories. 
  
  --- Enum that stores spot categories. 
  -- @type Spot.Category
  -- @field #string INFRA_RED
  -- @field #string LASER

  
  --- Creates a laser ray emanating from the given object to a point in 3d space.
  -- @function [parent=#Spot] createLaser
  -- @param DCS#Object Source The source object of the laser.
  -- @param DCS#Vec3 LocalRef An optional 3D offset for the source.
  -- @param DCS#Vec3 Vec3 Target coordinate where the ray is pointing at.
  -- @param #number LaserCode Any 4 digit number between 1111 and 1788.
  -- @return #Spot

  --- Creates an infrared ray emanating from the given object to a point in 3d space. Can be seen with night vision goggles.
  -- @function [parent=#Spot] createInfraRed
  -- @param DCS#Object Source Source position of the IR ray.
  -- @param DCS#Vec3 LocalRef An optional 3D offset for the source.
  -- @param DCS#Vec3 Vec3 Target coordinate where the ray is pointing at.
  -- @return #Spot

  --- Returns a vec3 table of the x, y, and z coordinates for the position of the given object in 3D space. Coordinates are dependent on the position of the maps origin.
  -- @function [parent=#Spot] getPoint
  -- @param #Spot self
  -- @return DCS#Vec3 Point in 3D, where the beam is pointing at.
  
  --- Sets the destination point from which the source of the spot is drawn toward.
  -- @function [parent=#Spot] setPoint
  -- @param #Spot self
  -- @param DCS#Vec3 Vec3 Point in 3D, where the beam is pointing at.

  --- Returns the number that is used to define the laser code for which laser designation can track.
  -- @function [parent=#Spot] getCode
  -- @param #Spot self
  -- @return #number Code The laser code used.

  --- Sets the number that is used to define the laser code for which laser designation can track.
  -- @function [parent=#Spot] setCode
  -- @param #Spot self
  -- @param #number Code The laser code. Default value is 1688.
  
  --- Destroys the spot.
  -- @function [parent=#Spot] destroy
  -- @param #Spot self

  --- Gets the category of the spot (laser or IR).
  -- @function [parent=#Spot] getCategory
  -- @param #Spot self
  -- @return #string Category.

  Spot = {} --#Spot

end -- Spot

do -- Controller

  --- Controller is an object that performs A.I.-tasks. Other words controller is an instance of A.I.. Controller stores current main task, active enroute tasks and behavior options. Controller performs commands. Please, read DCS A-10C GUI Manual EN.pdf chapter "Task Planning for Unit Groups", page 91 to understand A.I. system of DCS:A-10C. 
  -- 
  -- This class has 2 types of functions:
  -- 
  -- * Tasks
  -- * Commands: Commands are instant actions those required zero time to perform. Commands may be used both for control unit/group behavior and control game mechanics.
  -- 
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
  
  --- Enum containing detection types.
  -- @type Controller.Detection
  -- @field #number VISUAL Visual detection. Numeric value 1.
  -- @field #number OPTIC Optical detection. Numeric value 2.
  -- @field #number RADAR Radar detection. Numeric value 4.
  -- @field #number IRST Infra-red search and track detection. Numeric value 8.
  -- @field #number RWR Radar Warning Receiver detection. Numeric value 16.
  -- @field #number DLINK Data link detection. Numeric value 32.
  
  --- Detected target. 
  -- @type Controller.DetectedTarget
  -- @field DCS#Object object The target
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
  -- @return #boolean type Has effect only if detected is true. True if the target type is known.
  -- @return #boolean distance Has effect only if detected is true. True if the distance to the target is known.
  -- @return #ModelTime lastTime Has effect only if visible is false. Last time when target was seen. 
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

  --- Unit.
  -- @type Unit
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
  -- @field BOOM_AND_RECEPTACLE Tanker with a boom.
  -- @field PROBE_AND_DROGUE Tanker with a probe.
  
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
  
  --- A radar.
  -- @type Unit.Radar.detectionDistanceAir 
  -- @field #Unit.Radar.detectionDistanceAir.upperHemisphere upperHemisphere
  -- @field #Unit.Radar.detectionDistanceAir.lowerHemisphere lowerHemisphere
  
  --- A radar.
  -- @type Unit.Radar.detectionDistanceAir.upperHemisphere
  -- @field #Distance headOn
  -- @field #Distance tailOn
  
  --- A radar.
  -- @type Unit.Radar.detectionDistanceAir.lowerHemisphere 
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

  --- Returns the number of infantry that can be embark onto the aircraft. Only returns a value if run on airplanes or helicopters. Returns nil if run on ground or ship units.
  -- @function [parent=#Unit] getDescentCapacity
  -- @param #Unit self
  -- @return #number Number of soldiers that embark.
  
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
  
  --- GROUND - Switch on/off radar emissions
  -- @function [parent=#Unit] enableEmission
  -- @param #Unit self
  -- @param #boolean switch
  
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
  -- @field TRAIN
  
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
  
  --- Returns initial size of the group. If some of the units will be destroyed, initial size of the group will not be changed; Initial size limits the unitNumber parameter for Group.getUnit() function.
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
  
    --- GROUND - Switch on/off radar emissions
  -- @function [parent=#Group] enableEmission
  -- @param #Group self
  -- @param #boolean switch
  
  Group = {} --#Group

end -- Group

do -- StaticObject

  --- Represents a static object.
  -- @type StaticObject
  -- @extends DCS#Object

  --- Returns the static object.
  -- @function [parent=#StaticObject] getByName
  -- @param #string name Name of the static object.
  -- @return #StaticObject

  StaticObject = {} --#StaticObject

end

do --Event

  --- Event structure. Note that present fields depend on type of event.
  -- @type Event
  -- @field #number id Event ID.
  -- @field #number time Mission time in seconds.
  -- @field DCS#Unit initiator Unit initiating the event.
  -- @field DCS#Unit target Target unit.
  -- @field DCS#Airbase place Airbase.
  -- @field number subPlace Subplace. Unknown and often just 0.
  -- @field #string weapon_name Weapoin name.
  -- @field #number idx Mark ID.
  -- @field #number coalition Coalition ID.
  -- @field #number groupID Group ID, *e.g.* of group that added mark point.
  -- @field #string text Text, *e.g.* of mark point.
  -- @field DCS#Vec3 pos Position vector, *e.g.* of mark point.
  -- @field #string comment Comment, *e.g.* LSO score.

  Event={} --#Event

end

do -- AI

  --- [https://wiki.hoggitworld.com/view/DCS_enum_AI](https://wiki.hoggitworld.com/view/DCS_enum_AI)
  -- @type AI
  -- @field #AI.Skill Skill
  -- @field #AI.Task Task
  -- @field #AI.Option Option
  
  --- [https://wiki.hoggitworld.com/view/DCS_enum_AI](https://wiki.hoggitworld.com/view/DCS_enum_AI)
  -- @type AI.Skill
  -- @field AVERAGE
  -- @field GOOD
  -- @field HIGH
  -- @field EXCELLENT
  -- @field PLAYER
  -- @field CLIENT
  
  --- [https://wiki.hoggitworld.com/view/DCS_enum_AI](https://wiki.hoggitworld.com/view/DCS_enum_AI)
  -- @type AI.Task
  -- @field #AI.Task.WeaponExpend WeaponExpend
  -- @field #AI.Task.OrbitPattern OrbitPattern
  -- @field #AI.Task.Designation Designation
  -- @field #AI.Task.WaypointType WaypointType
  -- @field #AI.Task.TurnMethod TurnMethod
  -- @field #AI.Task.AltitudeType AltitudeType
  -- @field #AI.Task.VehicleFormation VehicleFormation
  
  --- [https://wiki.hoggitworld.com/view/DCS_enum_AI](https://wiki.hoggitworld.com/view/DCS_enum_AI)
  -- @type AI.Task.WeaponExpend
  -- @field ONE
  -- @field TWO
  -- @field FOUR
  -- @field QUARTER
  -- @field HALF
  -- @field ALL
  
  --- [https://wiki.hoggitworld.com/view/DCS_enum_AI](https://wiki.hoggitworld.com/view/DCS_enum_AI)
  -- @type AI.Task.OrbitPattern
  -- @field CIRCLE
  -- @field RACE_TRACK
  
  --- [https://wiki.hoggitworld.com/view/DCS_enum_AI](https://wiki.hoggitworld.com/view/DCS_enum_AI)
  -- @type AI.Task.Designation
  -- @field NO
  -- @field AUTO
  -- @field WP
  -- @field IR_POINTER
  -- @field LASER
  
  ---
  -- @type AI.Task.WaypointType
  -- @field TAKEOFF
  -- @field TAKEOFF_PARKING
  -- @field TURNING_POINT
  -- @field TAKEOFF_PARKING_HOT
  -- @field LAND
  
  ---
  -- @type AI.Task.TurnMethod
  -- @field FLY_OVER_POINT
  -- @field FIN_POINT
  
  ---
  -- @type AI.Task.AltitudeType
  -- @field BARO
  -- @field RADIO
  
  ---
  -- @type AI.Task.VehicleFormation
  -- @field OFF_ROAD
  -- @field ON_ROAD
  -- @field RANK
  -- @field CONE
  -- @field DIAMOND
  -- @field VEE
  -- @field ECHELON_LEFT
  -- @field ECHELON_RIGHT
  
  ---
  -- @type AI.Option
  -- @field #AI.Option.Air                          Air
  -- @field #AI.Option.Ground                       Ground
  -- @field #AI.Option.Naval                        Naval
  
  ---
  -- @type AI.Option.Air
  -- @field #AI.Option.Air.id                       id
  -- @field #AI.Option.Air.val                      val
  
  ---
  -- @type AI.Option.Ground
  -- @field #AI.Option.Ground.id                    id
  -- @field #AI.Option.Ground.val                   val
  -- @field #AI.Option.Ground.mid                   mid
  -- @field #AI.Option.Ground.mval                  mval
  -- 
  -- @type AI.Option.Naval
  -- @field #AI.Option.Naval.id                     id
  -- @field #AI.Option.Naval.val                    val
 
  ---
  -- @type AI.Option.Air.id
  -- @field NO_OPTION
  -- @field ROE
  -- @field REACTION_ON_THREAT
  -- @field RADAR_USING
  -- @field FLARE_USING
  -- @field FORMATION
  -- @field RTB_ON_BINGO
  -- @field SILENCE
  -- @field RTB_ON_OUT_OF_AMMO
  -- @field ECM_USING
  -- @field PROHIBIT_AA
  -- @field PROHIBIT_JETT
  -- @field PROHIBIT_AB
  -- @field PROHIBIT_AG
  -- @field MISSILE_ATTACK
  -- @field PROHIBIT_WP_PASS_REPORT
  -- @field OPTION_RADIO_USAGE_CONTACT
  -- @field OPTION_RADIO_USAGE_ENGAGE
  -- @field OPTION_RADIO_USAGE_KILL
  -- @field JETT_TANKS_IF_EMPTY
  -- @field FORCED_ATTACK

  ---
  -- @type AI.Option.Air.val
  -- @field #AI.Option.Air.val.ROE ROE
  -- @field #AI.Option.Air.val.REACTION_ON_THREAT REACTION_ON_THREAT
  -- @field #AI.Option.Air.val.RADAR_USING RADAR_USING
  -- @field #AI.Option.Air.val.FLARE_USING FLARE_USING
  
  ---
  -- @type AI.Option.Air.val.ROE
  -- @field WEAPON_FREE
  -- @field OPEN_FIRE_WEAPON_FREE
  -- @field OPEN_FIRE
  -- @field RETURN_FIRE
  -- @field WEAPON_HOLD
  
  --- 
  -- @type AI.Option.Air.val.REACTION_ON_THREAT
  -- @field NO_REACTION
  -- @field PASSIVE_DEFENCE
  -- @field EVADE_FIRE
  -- @field BYPASS_AND_ESCAPE
  -- @field ALLOW_ABORT_MISSION
  
  ---
  -- @type AI.Option.Air.val.RADAR_USING
  -- @field NEVER
  -- @field FOR_ATTACK_ONLY
  -- @field FOR_SEARCH_IF_REQUIRED
  -- @field FOR_CONTINUOUS_SEARCH
  
  ---
  -- @type AI.Option.Air.val.FLARE_USING
  -- @field NEVER
  -- @field AGAINST_FIRED_MISSILE
  -- @field WHEN_FLYING_IN_SAM_WEZ
  -- @field WHEN_FLYING_NEAR_ENEMIES
  
  ---
  -- @type AI.Option.Air.val.ECM_USING
  -- @field NEVER_USE
  -- @field USE_IF_ONLY_LOCK_BY_RADAR
  -- @field USE_IF_DETECTED_LOCK_BY_RADAR
  -- @field ALWAYS_USE
  
  ---
  -- @type AI.Option.Air.val.MISSILE_ATTACK
  -- @field MAX_RANGE
  -- @field NEZ_RANGE
  -- @field HALF_WAY_RMAX_NEZ
  -- @field TARGET_THREAT_EST
  -- @field RANDOM_RANGE

  ---
  -- @type AI.Option.Ground.id
  -- @field NO_OPTION
  -- @field ROE @{#AI.Option.Ground.val.ROE}
  -- @field FORMATION
  -- @field DISPERSE_ON_ATTACK true or false
  -- @field ALARM_STATE @{#AI.Option.Ground.val.ALARM_STATE}
  -- @field ENGAGE_AIR_WEAPONS
  -- @field AC_ENGAGEMENT_RANGE_RESTRICTION
  -- @field EVASION_OF_ARM
  
  ---
  -- @type AI.Option.Ground.mid -- Moose added
  -- @field RESTRICT_AAA_MIN        27
  -- @field RESTRICT_AAA_MAX        29
  -- @field RESTRICT_TARGETS @{#AI.Option.Ground.mval.ENGAGE_TARGETS}  28
  
  ---
  -- @type AI.Option.Ground.val
  -- @field #AI.Option.Ground.val.ROE               ROE
  -- @field #AI.Option.Ground.val.ALARM_STATE       ALARM_STATE
  -- @field #AI.Option.Ground.val.ENGAGE_TARGETS    RESTRICT_TARGETS
  
  ---
  -- @type AI.Option.Ground.val.ROE
  -- @field OPEN_FIRE
  -- @field RETURN_FIRE
  -- @field WEAPON_HOLD
  
  ---
  -- @type AI.Option.Ground.mval -- Moose added
  -- @field #AI.Option.Ground.mval.ENGAGE_TARGETS   ENGAGE_TARGETS
  
  ---
  -- @type AI.Option.Ground.mval.ENGAGE_TARGETS -- Moose added
  -- @field ANY_TARGET -- 0
  -- @field AIR_UNITS_ONLY -- 1
  -- @field GROUND_UNITS_ONLY -- 2
  
  ---
  -- @type AI.Option.Ground.val.ALARM_STATE
  -- @field AUTO
  -- @field GREEN
  -- @field RED
  
  ---
  -- @type AI.Option.Naval.id
  -- @field NO_OPTION
  -- @field ROE
  
  ---
  -- @type AI.Option.Naval.val
  -- @field #AI.Option.Naval.val.ROE ROE
  
  ---
  -- @type AI.Option.Naval.val.ROE
  -- @field OPEN_FIRE
  -- @field RETURN_FIRE
  -- @field WEAPON_HOLD
  
  AI = {} --#AI

end -- AI
