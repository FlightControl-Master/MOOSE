-------------------------------------------------------------------------------
-- @module DCSTypes



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


--- @type Desc
-- @field #TypeName typeName type name
-- @field #string displayName localized display name
-- @field #table attributes object type attributes

--- A distance type
-- @type Distance

--- An angle type
-- @type Angle

env.info( 'AI types created' )

