--- **Cargo** - Management of CARGO logistics, that can be transported from and to transportation carriers.
--
-- ===
-- 
-- # 1) MOOSE Cargo System.
-- 
-- #### Those who have used the mission editor, know that the DCS mission editor provides cargo facilities.
-- However, these are merely static objects. Wouldn't it be nice if cargo could bring a new dynamism into your
-- simulations? Where various objects of various types could be treated also as cargo?
-- 
-- This is what MOOSE brings to you, a complete new cargo object model that used the cargo capabilities of 
-- DCS world, but enhances it.
-- 
-- MOOSE Cargo introduces also a new concept, called a "carrier". These can be:
-- 
--   - Helicopters
--   - Planes
--   - Ground Vehicles
--   - Ships
-- 
-- With the MOOSE Cargo system, you can:
-- 
--   - Take full control of the cargo as objects within your script (see below).
--   - Board/Unboard infantry into carriers. Also other objects can be boarded, like mortars.
--   - Load/Unload dcs world cargo objects into carriers.
--   - Load/Unload other static objects into carriers (like tires etc).
--   - Slingload cargo objects.
--   - Board units one by one...
--   
-- # 2) MOOSE Cargo Objects.
-- 
-- In order to make use of the MOOSE cargo system, you need to **declare** the DCS objects as MOOSE cargo objects!
-- 
-- This sounds complicated, but it is actually quite simple.
-- 
-- See here an example:
-- 
--     local EngineerCargoGroup = CARGO_GROUP:New( GROUP:FindByName( "Engineers" ), "Workmaterials", "Engineers", 250 )
--     
-- The above code declares a MOOSE cargo object called `EngineerCargoGroup`.
-- It actually just refers to an infantry group created within the sim called `"Engineers"`.
-- The infantry group now becomes controlled by the MOOSE cargo object `EngineerCargoGroup`.
-- A MOOSE cargo object also has properties, like the type of cargo, the logical name, and the reporting range.
-- 
-- There are 4 types of MOOSE cargo objects possible, each represented by its own class:
-- 
--   - @{Cargo.CargoGroup#CARGO_GROUP}: A MOOSE cargo that is represented by a DCS world GROUP object.
--   - @{Cargo.CargoCrate#CARGO_CRATE}: A MOOSE cargo that is represented by a DCS world cargo object (static object).
--   - @{Cargo.CargoUnit#CARGO_UNIT}: A MOOSE cargo that is represented by a DCS world unit object or static object.
--   - @{Cargo.CargoSlingload#CARGO_SLINGLOAD}: A MOOSE cargo that is represented by a DCS world cargo object (static object), that can be slingloaded.
--   
-- Note that a CARGO crate is not meant to be slingloaded (it can, but it is not **meant** to be handled like that.
-- Instead, a CARGO_CRATE is able to load itself into the bays of a carrier.
-- 
-- Each of these MOOSE cargo objects behave in its own way, and have methods to be handled.
-- 
--     local InfantryGroup = GROUP:FindByName( "Infantry" )
--     local InfantryCargo = CARGO_GROUP:New( InfantryGroup, "Engineers", "Infantry Engineers", 2000 )
--     local CargoCarrier = UNIT:FindByName( "Carrier" )
--     -- This call will make the Cargo run to the CargoCarrier.
--     -- Upon arrival at the CargoCarrier, the Cargo will be Loaded into the Carrier.
--     -- This process is now fully automated.
--     InfantryCargo:Board( CargoCarrier, 25 ) 
-- 
-- The above would create a MOOSE cargo object called `InfantryCargo`, and using that object,
-- you can board the cargo into the carrier `CargoCarrier`.
-- Simple, isn't it? Told you, and this is only the beginning.
-- 
-- The boarding, unboarding, loading, unloading of cargo is however something that is not meant to be coded manualy by mission designers.
-- It would be too low-level and not end-user friendly to deal with cargo handling complexity.
-- Things can become really complex if you want to make cargo being handled and behave in multiple scenarios.
-- 
-- # 3) Cargo Handling Classes, the main engines for mission designers!
-- 
-- For this reason, the MOOSE Cargo System is heavily used by 3 important **cargo handling class hierarchies** within MOOSE,
-- that make cargo come "alive" within your mission in a full automatic manner!
-- 
-- ## 3.1) AI Cargo handlers.
-- 
--   - @{AI.AI_Cargo_APC} will create for you the capatility to make an APC group handle cargo.
--   - @{AI.AI_Cargo_Helicopter} will create for you the capatility to make a Helicopter group handle cargo.
--   
--   
-- ## 3.2) AI Cargo transportation dispatchers.
-- 
-- There are also dispatchers that make AI work together to transport cargo automatically!!!
--   
--   - @{AI.AI_Cargo_Dispatcher_APC} derived classes will create for your dynamic cargo handlers controlled by AI ground vehicle groups (APCs) to transport cargo between sites.
--   - @{AI.AI_Cargo_Dispatcher_Helicopters} derived classes will create for your dynamic cargo handlers controlled by AI helicpter groups to transport cargo between sites.
-- 
-- ## 3.3) Cargo transportation tasking.
--   
-- And there is cargo transportation tasking for human players.
--   
--   - @{Tasking.Task_CARGO} derived classes will create for you cargo transportation tasks, that allow human players to interact with MOOSE cargo objects to complete tasks.
-- 
-- Please refer to the documentation reflected within these modules to understand the detailed capabilties.
-- 
-- # 4) Cargo SETs.
-- 
-- To make life a bit more easy, MOOSE cargo objects can be grouped into a @{Core.Set#SET_CARGO}.
-- This is a collection of MOOSE cargo objects.
-- 
-- This would work as follows:
-- 
--      -- Define the cargo set.
--      local CargoSetWorkmaterials = SET_CARGO:New():FilterTypes( "Workmaterials" ):FilterStart()
--      
--      -- Now add cargo the cargo set.
--      local EngineerCargoGroup = CARGO_GROUP:New( GROUP:FindByName( "Engineers" ), "Workmaterials", "Engineers", 250 )
--      local ConcreteCargo = CARGO_SLINGLOAD:New( STATIC:FindByName( "Concrete" ), "Workmaterials", "Concrete", 150, 50 )
--      local CrateCargo = CARGO_CRATE:New( STATIC:FindByName( "Crate" ), "Workmaterials", "Crate", 150, 50 )
--      local EnginesCargo = CARGO_CRATE:New( STATIC:FindByName( "Engines" ), "Workmaterials", "Engines", 150, 50 )
--      local MetalCargo = CARGO_CRATE:New( STATIC:FindByName( "Metal" ), "Workmaterials", "Metal", 150, 50 )
-- 
-- This is a very powerful concept!
-- Instead of having to deal with multiple MOOSE cargo objects yourself, the cargo set capability will group cargo objects into one set.
-- The key is the **cargo type** name given at each cargo declaration!
-- In the above example, the cargo type name is `"Workmaterials"`. Each cargo object declared is given that type name. (the 2nd parameter).
-- What happens now is that the cargo set `CargoSetWorkmaterials` will be added with each cargo object **dynamically** when the cargo object is created.
-- In other words, the cargo set `CargoSetWorkmaterials` will incorporate any `"Workmaterials"` dynamically into its set.
-- 
-- The cargo sets are extremely important for the AI cargo transportation dispatchers and the cargo transporation tasking.
-- 
-- # 5) Declare cargo directly in the mission editor!
-- 
-- But I am not finished! There is something more, that is even more great!
-- Imagine the mission designers having to code all these lines every time it wants to embed cargo within a mission.
--  
--      -- Now add cargo the cargo set.
--      local EngineerCargoGroup = CARGO_GROUP:New( GROUP:FindByName( "Engineers" ), "Workmaterials", "Engineers", 250 )
--      local ConcreteCargo = CARGO_SLINGLOAD:New( STATIC:FindByName( "Concrete" ), "Workmaterials", "Concrete", 150, 50 )
--      local CrateCargo = CARGO_CRATE:New( STATIC:FindByName( "Crate" ), "Workmaterials", "Crate", 150, 50 )
--      local EnginesCargo = CARGO_CRATE:New( STATIC:FindByName( "Engines" ), "Workmaterials", "Engines", 150, 50 )
--      local MetalCargo = CARGO_CRATE:New( STATIC:FindByName( "Metal" ), "Workmaterials", "Metal", 150, 50 )
-- 
-- This would be extremely tiring and a huge overload.
-- However, the MOOSE framework allows to declare MOOSE cargo objects within the mission editor!!!
-- 
-- So, at mission startup, MOOSE will search for objects following a special naming convention, and will **create** for you **dynamically
-- cargo objects** at **mission start**!!! -- These cargo objects can then be automatically incorporated within cargo set(s)!!!
-- In other words, your mission will be reduced to about a few lines of code, providing you with a full dynamic cargo handling mission!
-- 
-- ## 5.1) Use \#CARGO tags in the mission editor:
-- 
-- MOOSE can create automatically cargo objects, if the name of the cargo contains the **\#CARGO** tag.
-- When a mission starts, MOOSE will scan all group and static objects it found for the presence of the \#CARGO tag.
-- When found, MOOSE will declare the object as cargo (create in the background a CARGO_ object, like CARGO_GROUP, CARGO_CRATE or CARGO_SLINGLOAD.
-- The creation of these CARGO_ objects will allow to be filtered and automatically added in SET_CARGO objects.
-- In other words, with very minimal code as explained in the above code section, you are able to create vast amounts of cargo objects just from within the editor.
-- 
-- What I talk about is this:
-- 
--      -- BEFORE THIS SCRIPT STARTS, MOOSE WILL ALREADY HAVE SCANNED FOR OBJECTS WITH THE #CARGO TAG IN THE NAME.
--      -- FOR EACH OF THESE OBJECT, MOOSE WILL HAVE CREATED CARGO_ OBJECTS LIKE CARGO_GROUP, CARGO_CRATE AND CARGO_SLINGLOAD.
-- 
--      HQ = GROUP:FindByName( "HQ", "Bravo" )
--      
--      CommandCenter = COMMANDCENTER
--        :New( HQ, "Lima" )
--      
--      Mission = MISSION
--        :New( CommandCenter, "Operation Cargo Fun", "Tactical", "Transport Cargo", coalition.side.RED )
--      
--      TransportGroups = SET_GROUP:New():FilterCoalitions( "blue" ):FilterPrefixes( "Transport" ):FilterStart()
--      
--      TaskDispatcher = TASK_CARGO_DISPATCHER:New( Mission, TransportGroups )
--      
--      -- This is the most important now. You setup a new SET_CARGO filtering the relevant type.
--      -- The actual cargo objects are now created by MOOSE in the background.
--      -- Each cargo is setup in the Mission Editor using the #CARGO tag in the group name.
--      -- This allows a truly dynamic setup.
--      local CargoSetWorkmaterials = SET_CARGO:New():FilterTypes( "Workmaterials" ):FilterStart()
--      
--      local WorkplaceTask = TaskDispatcher:AddTransportTask( "Build a Workplace", CargoSetWorkmaterials, "Transport the workers, engineers and the equipment near the Workplace." )
--      TaskDispatcher:SetTransportDeployZone( WorkplaceTask, ZONE:New( "Workplace" ) )
--      
-- The above code example has the `CargoSetWorkmaterials`, which is a SET_CARGO collection and will include the CARGO_ objects of the type "Workmaterials".    
-- And there is NO cargo object actually declared within the script! However, if you would open the mission, there would be hundreds of cargo objects...
-- 
-- The \#CARGO tag even allows for several options to be specified, which are important to learn.
-- 
-- ## 5.2) The \#CARGO tag to create CARGO_GROUP objects:
-- 
-- You can also use the \#CARGO tag on **group** objects of the mission editor.
-- 
-- For example, the following #CARGO naming in the **group name** of the object, will create a CARGO_GROUP object when the mission starts.
-- 
--   `Infantry #CARGO(T=Workmaterials,RR=500,NR=25)`
-- 
-- This will create a CARGO_GROUP object:
-- 
--    * with the group name `Infantry #CARGO`
--    * is of type `Workmaterials`
--    * will report when a carrier is within 500 meters
--    * will board to carriers when the carrier is within 500 meters from the cargo object
--    * will dissapear when the cargo is within 25 meters from the carrier during boarding
-- 
-- So the overall syntax of the #CARGO naming tag and arguments are:
-- 
--   `GroupName #CARGO(T=CargoTypeName,RR=Range,NR=Range)`
-- 
--    * **T=** Provide a text that contains the type name of the cargo object. This type name can be used to filter cargo within a SET_CARGO object.
--    * **RR=** Provide the minimal range in meters when the report to the carrier, and board to the carrier.
--      Note that this option is optional, so can be omitted. The default value of the RR is 250 meters.
--    * **NR=** Provide the maximum range in meters when the cargo units will be boarded within the carrier during boarding.
--      Note that this option is optional, so can be omitted. The default value of the RR is 10 meters.
-- 
-- ## 5.2) The \#CARGO tag to create CARGO_CRATE objects:
-- 
-- You can also use the \#CARGO tag on **static** objects, including **static cargo** objects of the mission editor.
-- 
-- For example, the following #CARGO naming in the **static name** of the object, will create a CARGO_CRATE object when the mission starts.
-- 
--   `Static #CARGO(T=Workmaterials,RR=500,NR=25)`
-- 
-- This will create a CARGO_CRATE object:
-- 
--    * with the group name `Static #CARGO`
--    * is of type `Workmaterials`
--    * will report when a carrier is within 500 meters
--    * will board to carriers when the carrier is within 500 meters from the cargo object
--    * will dissapear when the cargo is within 25 meters from the carrier during boarding
-- 
-- So the overall syntax of the #CARGO naming tag and arguments are:
-- 
--   `StaticName #CARGO(T=CargoTypeName,RR=Range,NR=Range)`
-- 
--    * **T=** Provide a text that contains the type name of the cargo object. This type name can be used to filter cargo within a SET_CARGO object.
--    * **RR=** Provide the minimal range in meters when the report to the carrier, and board to the carrier.
--      Note that this option is optional, so can be omitted. The default value of the RR is 250 meters.
--    * **NR=** Provide the maximum range in meters when the cargo units will be boarded within the carrier during boarding.
--      Note that this option is optional, so can be omitted. The default value of the RR is 10 meters.
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Cargo.Cargo
-- @image Cargo.JPG

-- Events

-- Board

--- Boards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo to the Carrier.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#CARGO] Board
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.
-- @param #number NearRadius The radius when the cargo will board the Carrier (to avoid collision).

--- Boards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo to the Carrier.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#CARGO] __Board
-- @param #CARGO self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Wrapper.Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.
-- @param #number NearRadius The radius when the cargo will board the Carrier (to avoid collision).


-- UnBoard

--- UnBoards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo from the Carrier.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#CARGO] UnBoard
-- @param #CARGO self
-- @param Core.Point#POINT_VEC2 ToPointVec2 (optional) @{Core.Point#POINT_VEC2) to where the cargo should run after onboarding. If not provided, the cargo will run to 60 meters behind the Carrier location.

--- UnBoards the cargo to a Carrier. The event will create a movement (= running or driving) of the cargo from the Carrier.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#CARGO] __UnBoard
-- @param #CARGO self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Core.Point#POINT_VEC2 ToPointVec2 (optional) @{Core.Point#POINT_VEC2) to where the cargo should run after onboarding. If not provided, the cargo will run to 60 meters behind the Carrier location.


-- Load

--- Loads the cargo to a Carrier. The event will load the cargo into the Carrier regardless of its position. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#CARGO] Load
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.

--- Loads the cargo to a Carrier. The event will load the cargo into the Carrier regardless of its position. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **UnLoaded** state.
-- @function [parent=#CARGO] __Load
-- @param #CARGO self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Wrapper.Controllable#CONTROLLABLE ToCarrier The Carrier that will hold the cargo.


-- UnLoad

--- UnLoads the cargo to a Carrier. The event will unload the cargo from the Carrier. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#CARGO] UnLoad
-- @param #CARGO self
-- @param Core.Point#POINT_VEC2 ToPointVec2 (optional) @{Core.Point#POINT_VEC2) to where the cargo will be placed after unloading. If not provided, the cargo will be placed 60 meters behind the Carrier location.

--- UnLoads the cargo to a Carrier. The event will unload the cargo from the Carrier. There will be no movement simulated of the cargo loading.
-- The cargo must be in the **Loaded** state.
-- @function [parent=#CARGO] __UnLoad
-- @param #CARGO self
-- @param #number DelaySeconds The amount of seconds to delay the action.
-- @param Core.Point#POINT_VEC2 ToPointVec2 (optional) @{Core.Point#POINT_VEC2) to where the cargo will be placed after unloading. If not provided, the cargo will be placed 60 meters behind the Carrier location.

-- State Transition Functions

-- UnLoaded

--- @function [parent=#CARGO] OnLeaveUnLoaded
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#CARGO] OnEnterUnLoaded
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable

-- Loaded

--- @function [parent=#CARGO] OnLeaveLoaded
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#CARGO] OnEnterLoaded
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable

-- Boarding

--- @function [parent=#CARGO] OnLeaveBoarding
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#CARGO] OnEnterBoarding
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @param #number NearRadius The radius when the cargo will board the Carrier (to avoid collision).

-- UnBoarding

--- @function [parent=#CARGO] OnLeaveUnBoarding
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable
-- @return #boolean

--- @function [parent=#CARGO] OnEnterUnBoarding
-- @param #CARGO self
-- @param Wrapper.Controllable#CONTROLLABLE Controllable


-- TODO: Find all Carrier objects and make the type of the Carriers Wrapper.Unit#UNIT in the documentation.

CARGOS = {}

do -- CARGO

  --- @type CARGO
  -- @extends Core.Fsm#FSM_PROCESS
  -- @field #string Type A string defining the type of the cargo. eg. Engineers, Equipment, Screwdrivers.
  -- @field #string Name A string defining the name of the cargo. The name is the unique identifier of the cargo.
  -- @field #number Weight A number defining the weight of the cargo. The weight is expressed in kg.
  -- @field #number NearRadius (optional) A number defining the radius in meters when the cargo is near to a Carrier, so that it can be loaded.
  -- @field Wrapper.Unit#UNIT CargoObject The alive DCS object representing the cargo. This value can be nil, meaning, that the cargo is not represented anywhere...
  -- @field Wrapper.Client#CLIENT CargoCarrier The alive DCS object carrying the cargo. This value can be nil, meaning, that the cargo is not contained anywhere...
  -- @field #boolean Slingloadable This flag defines if the cargo can be slingloaded.
  -- @field #boolean Moveable This flag defines if the cargo is moveable.
  -- @field #boolean Representable This flag defines if the cargo can be represented by a DCS Unit.
  -- @field #boolean Containable This flag defines if the cargo can be contained within a DCS Unit.
  
  --- Defines the core functions that defines a cargo object within MOOSE.
  -- 
  -- A cargo is a **logical object** defined that is available for transport, and has a life status within a simulation.
  -- 
  -- CARGO is not meant to be used directly by mission designers, but provides a base class for **concrete cargo implementation classes** to handle:
  -- 
  --   * Cargo **group objects**, implemented by the @{Cargo.CargoGroup#CARGO_GROUP} class.
  --   * Cargo **Unit objects**, implemented by the @{Cargo.CargoUnit#CARGO_UNIT} class.
  --   * Cargo **Crate objects**, implemented by the @{Cargo.CargoCrate#CARGO_CRATE} class.
  --   * Cargo **Sling Load objects**, implemented by the @{Cargo.CargoSlingload#CARGO_SLINGLOAD} class.
  --
  -- The above cargo classes are used by the AI\_CARGO\_ classes to allow AI groups to transport cargo:
  -- 
  --   * AI Armoured Personnel Carriers to transport cargo and engage in battles, using the @{AI.AI_Cargo_APC#AI_CARGO_APC} class.
  --   * AI Helicopters to transport cargo, using the @{AI.AI_Cargo_Helicopter#AI_CARGO_HELICOPTER} class.
  --   * AI Planes to transport cargo, using the @{AI.AI_Cargo_Plane#AI_CARGO_PLANE} class.
  --   * AI Ships is planned.
  -- 
  -- The above cargo classes are also used by the TASK\_CARGO\_ classes to allow human players to transport cargo as part of a tasking:
  -- 
  --   * @{Tasking.Task_Cargo_Transport#TASK_CARGO_TRANSPORT} to transport cargo by human players.
  --   * @{Tasking.Task_Cargo_Transport#TASK_CARGO_CSAR} to transport downed pilots by human players.
  -- 
  -- 
  -- The CARGO is a state machine: it manages the different events and states of the cargo.
  -- All derived classes from CARGO follow the same state machine, expose the same cargo event functions, and provide the same cargo states.
  -- 
  -- ## CARGO Events:
  -- 
  --   * @{#CARGO.Board}( ToCarrier ):  Boards the cargo to a carrier.
  --   * @{#CARGO.Load}( ToCarrier ): Loads the cargo into a carrier, regardless of its position.
  --   * @{#CARGO.UnBoard}( ToPointVec2 ): UnBoard the cargo from a carrier. This will trigger a movement of the cargo to the option ToPointVec2.
  --   * @{#CARGO.UnLoad}( ToPointVec2 ): UnLoads the cargo from a carrier.
  --   * @{#CARGO.Destroyed}( Controllable ): The cargo is dead. The cargo process will be ended.
  -- 
  -- @field #CARGO
  CARGO = {
    ClassName = "CARGO",
    Type = nil,
    Name = nil,
    Weight = nil,
    CargoObject = nil,
    CargoCarrier = nil,
    Representable = false,
    Slingloadable = false,
    Moveable = false,
    Containable = false,
    Reported = {},
  }

  --- @type CARGO.CargoObjects
  -- @map < #string, Wrapper.Positionable#POSITIONABLE > The alive POSITIONABLE objects representing the the cargo.
  
  
  --- CARGO Constructor. This class is an abstract class and should not be instantiated.
  -- @param #CARGO self
  -- @param #string Type
  -- @param #string Name
  -- @param #number Weight
  -- @param #number LoadRadius (optional)
  -- @param #number NearRadius (optional)
  -- @return #CARGO
  function CARGO:New( Type, Name, Weight, LoadRadius, NearRadius ) --R2.1
  
    local self = BASE:Inherit( self, FSM:New() ) -- #CARGO
    self:F( { Type, Name, Weight, LoadRadius, NearRadius } )
    
    self:SetStartState( "UnLoaded" )
    self:AddTransition( { "UnLoaded", "Boarding" }, "Board", "Boarding" )
    self:AddTransition( "Boarding" , "Boarding", "Boarding" )
    self:AddTransition( "Boarding", "CancelBoarding", "UnLoaded" )
    self:AddTransition( "Boarding", "Load", "Loaded" )
    self:AddTransition( "UnLoaded", "Load", "Loaded" )
    self:AddTransition( "Loaded", "UnBoard", "UnBoarding" )
    self:AddTransition( "UnBoarding", "UnBoarding", "UnBoarding" )
    self:AddTransition( "UnBoarding", "UnLoad", "UnLoaded" )
    self:AddTransition( "Loaded", "UnLoad", "UnLoaded" )
    self:AddTransition( "*", "Damaged", "Damaged" )
    self:AddTransition( "*", "Destroyed", "Destroyed" )
    self:AddTransition( "*", "Respawn", "UnLoaded" )
    self:AddTransition( "*", "Reset", "UnLoaded" )
  
    self.Type = Type
    self.Name = Name
    self.Weight = Weight or 0
    self.CargoObject = nil
    self.CargoCarrier = nil -- Wrapper.Client#CLIENT
    self.Representable = false
    self.Slingloadable = false
    self.Moveable = false
    self.Containable = false

    self.CargoLimit = 0
    
    self.LoadRadius = LoadRadius or 500
    --self.NearRadius = NearRadius or 25
    
    self:SetDeployed( false )
  
    self.CargoScheduler = SCHEDULER:New()
  
    CARGOS[self.Name] = self
  
    
    return self
  end
  
  
  --- Find a CARGO in the _DATABASE.
  -- @param #CARGO self
  -- @param #string CargoName The Cargo Name.
  -- @return #CARGO self
  function CARGO:FindByName( CargoName )
    
    local CargoFound = _DATABASE:FindCargo( CargoName )
    return CargoFound
  end
  
  --- Get the x position of the cargo.
  -- @param #CARGO self
  -- @return #number
  function CARGO:GetX()
    if self:IsLoaded() then
      return self.CargoCarrier:GetCoordinate().x
    else
      return self.CargoObject:GetCoordinate().x
    end 
  end
  
  --- Get the y position of the cargo.
  -- @param #CARGO self
  -- @return #number
  function CARGO:GetY()
    if self:IsLoaded() then
      return self.CargoCarrier:GetCoordinate().z
    else
      return self.CargoObject:GetCoordinate().z
    end 
  end
  
  --- Get the heading of the cargo.
  -- @param #CARGO self
  -- @return #number
  function CARGO:GetHeading()
    if self:IsLoaded() then
      return self.CargoCarrier:GetHeading()
    else
      return self.CargoObject:GetHeading()
    end 
  end
  
  
  --- Check if the cargo can be Slingloaded.
  -- @param #CARGO self
  function CARGO:CanSlingload()
    return false
  end
  
  --- Check if the cargo can be Boarded.
  -- @param #CARGO self
  function CARGO:CanBoard()
    return true
  end
  
  --- Check if the cargo can be Unboarded.
  -- @param #CARGO self
  function CARGO:CanUnboard()
    return true
  end

  --- Check if the cargo can be Loaded.
  -- @param #CARGO self
  function CARGO:CanLoad()
    return true
  end
  
  --- Check if the cargo can be Unloaded.
  -- @param #CARGO self
  function CARGO:CanUnload()
    return true
  end

  
  --- Destroy the cargo.
  -- @param #CARGO self
  function CARGO:Destroy()
    if self.CargoObject then
      self.CargoObject:Destroy()
    end
    self:Destroyed()
  end
  
  --- Get the name of the Cargo.
  -- @param #CARGO self
  -- @return #string The name of the Cargo.
  function CARGO:GetName() --R2.1
    return self.Name
  end
  
  --- Get the current active object representing or being the Cargo.
  -- @param #CARGO self
  -- @return Wrapper.Positionable#POSITIONABLE The object representing or being the Cargo.
  function CARGO:GetObject()
    if self:IsLoaded() then
      return self.CargoCarrier
    else
      return self.CargoObject
    end 
  end
  
  --- Get the object name of the Cargo.
  -- @param #CARGO self
  -- @return #string The object name of the Cargo.
  function CARGO:GetObjectName() --R2.1
    if self:IsLoaded() then
      return self.CargoCarrier:GetName()
    else
      return self.CargoObject:GetName()
    end 
  end
  
  --- Get the amount of Cargo.
  -- @param #CARGO self
  -- @return #number The amount of Cargo.
  function CARGO:GetCount()
    return 1
  end

  --- Get the type of the Cargo.
  -- @param #CARGO self
  -- @return #string The type of the Cargo.
  function CARGO:GetType()
    return self.Type
  end

    
  --- Get the transportation method of the Cargo.
  -- @param #CARGO self
  -- @return #string The transportation method of the Cargo.
  function CARGO:GetTransportationMethod()
    return self.TransportationMethod
  end

    
  --- Get the coalition of the Cargo.
  -- @param #CARGO self
  -- @return Coalition
  function CARGO:GetCoalition()
    if self:IsLoaded() then
      return self.CargoCarrier:GetCoalition()
    else
      return self.CargoObject:GetCoalition()
    end 
  end

  
  --- Get the current coordinates of the Cargo.
  -- @param #CARGO self
  -- @return Core.Point#COORDINATE The coordinates of the Cargo.
  function CARGO:GetCoordinate()
    return self.CargoObject:GetCoordinate()
  end
  
  --- Check if cargo is destroyed.
  -- @param #CARGO self
  -- @return #boolean true if destroyed
  function CARGO:IsDestroyed()
    return self:Is( "Destroyed" )
  end
  
  
  --- Check if cargo is loaded.
  -- @param #CARGO self
  -- @return #boolean true if loaded
  function CARGO:IsLoaded()
    return self:Is( "Loaded" )
  end
  
  --- Check if cargo is loaded.
  -- @param #CARGO self
  -- @param Wrapper.Unit#UNIT Carrier
  -- @return #boolean true if loaded
  function CARGO:IsLoadedInCarrier( Carrier )
    return self.CargoCarrier and self.CargoCarrier:GetName() == Carrier:GetName()
  end
  
  --- Check if cargo is unloaded.
  -- @param #CARGO self
  -- @return #boolean true if unloaded
  function CARGO:IsUnLoaded()
    return self:Is( "UnLoaded" )
  end
  
  --- Check if cargo is boarding.
  -- @param #CARGO self
  -- @return #boolean true if boarding
  function CARGO:IsBoarding()
    return self:Is( "Boarding" )
  end

  
  --- Check if cargo is unboarding.
  -- @param #CARGO self
  -- @return #boolean true if unboarding
  function CARGO:IsUnboarding()
    return self:Is( "UnBoarding" )
  end
  

  --- Check if cargo is alive.
  -- @param #CARGO self
  -- @return #boolean true if unloaded
  function CARGO:IsAlive()
  
    if self:IsLoaded() then
      return self.CargoCarrier:IsAlive()
    else
      return self.CargoObject:IsAlive()
    end 
  end
  
  --- Set the cargo as deployed.
  -- @param #CARGO self
  -- @param #boolean Deployed true if the cargo is to be deployed. false or nil otherwise.
  function CARGO:SetDeployed( Deployed )
    self.Deployed = Deployed
  end
  
  --- Is the cargo deployed
  -- @param #CARGO self
  -- @return #boolean
  function CARGO:IsDeployed()
    return self.Deployed
  end
  
  
  
  
  --- Template method to spawn a new representation of the CARGO in the simulator.
  -- @param #CARGO self
  -- @return #CARGO
  function CARGO:Spawn( PointVec2 )
    self:F()
  
  end
  
  --- Signal a flare at the position of the CARGO.
  -- @param #CARGO self
  -- @param Utilities.Utils#FLARECOLOR FlareColor
  function CARGO:Flare( FlareColor )
    if self:IsUnLoaded() then
      trigger.action.signalFlare( self.CargoObject:GetVec3(), FlareColor , 0 )
    end
  end
  
  --- Signal a white flare at the position of the CARGO.
  -- @param #CARGO self
  function CARGO:FlareWhite()
    self:Flare( trigger.flareColor.White )
  end
  
  --- Signal a yellow flare at the position of the CARGO.
  -- @param #CARGO self
  function CARGO:FlareYellow()
    self:Flare( trigger.flareColor.Yellow )
  end
  
  --- Signal a green flare at the position of the CARGO.
  -- @param #CARGO self
  function CARGO:FlareGreen()
    self:Flare( trigger.flareColor.Green )
  end
  
  --- Signal a red flare at the position of the CARGO.
  -- @param #CARGO self
  function CARGO:FlareRed()
    self:Flare( trigger.flareColor.Red )
  end
  
  --- Smoke the CARGO.
  -- @param #CARGO self
  -- @param Utilities.Utils#SMOKECOLOR SmokeColor The color of the smoke.
  -- @param #number Radius The radius of randomization around the center of the Cargo.
  function CARGO:Smoke( SmokeColor, Radius )
    if self:IsUnLoaded() then
      if Radius then
        trigger.action.smoke( self.CargoObject:GetRandomVec3( Radius ), SmokeColor )
      else
        trigger.action.smoke( self.CargoObject:GetVec3(), SmokeColor )
      end
    end
  end
  
  --- Smoke the CARGO Green.
  -- @param #CARGO self
  function CARGO:SmokeGreen()
    self:Smoke( trigger.smokeColor.Green, Range )
  end
  
  --- Smoke the CARGO Red.
  -- @param #CARGO self
  function CARGO:SmokeRed()
    self:Smoke( trigger.smokeColor.Red, Range )
  end
  
  --- Smoke the CARGO White.
  -- @param #CARGO self
  function CARGO:SmokeWhite()
    self:Smoke( trigger.smokeColor.White, Range )
  end
  
  --- Smoke the CARGO Orange.
  -- @param #CARGO self
  function CARGO:SmokeOrange()
    self:Smoke( trigger.smokeColor.Orange, Range )
  end
  
  --- Smoke the CARGO Blue.
  -- @param #CARGO self
  function CARGO:SmokeBlue()
    self:Smoke( trigger.smokeColor.Blue, Range )
  end
  
  
  --- Set the Load radius, which is the radius till when the Cargo can be loaded.
  -- @param #CARGO self
  -- @param #number LoadRadius The radius till Cargo can be loaded.
  -- @return #CARGO
  function CARGO:SetLoadRadius( LoadRadius )
    self.LoadRadius = LoadRadius or 150
  end
  
  --- Get the Load radius, which is the radius till when the Cargo can be loaded.
  -- @param #CARGO self
  -- @return #number The radius till Cargo can be loaded.
  function CARGO:GetLoadRadius()
    return self.LoadRadius
  end
  
  
  
  --- Check if Cargo is in the LoadRadius for the Cargo to be Boarded or Loaded.
  -- @param #CARGO self
  -- @param Core.Point#COORDINATE Coordinate
  -- @return #boolean true if the CargoGroup is within the loading radius.
  function CARGO:IsInLoadRadius( Coordinate )
    self:F( { Coordinate, LoadRadius = self.LoadRadius } )
  
    local Distance = 0
    if self:IsUnLoaded() then
      local CargoCoordinate = self.CargoObject:GetCoordinate()
      Distance = Coordinate:Get2DDistance( CargoCoordinate )
      self:T( Distance )
      if Distance <= self.LoadRadius then
        return true
      end
    end
    
    return false
  end


  --- Check if the Cargo can report itself to be Boarded or Loaded.
  -- @param #CARGO self
  -- @param Core.Point#COORDINATE Coordinate
  -- @return #boolean true if the Cargo can report itself.
  function CARGO:IsInReportRadius( Coordinate )
    self:F( { Coordinate } )
  
    local Distance = 0
    if self:IsUnLoaded() then
      Distance = Coordinate:Get2DDistance( self.CargoObject:GetCoordinate() )
      self:T( Distance )
      if Distance <= self.LoadRadius then
        return true
      end
    end
    
    return false
  end


  --- Check if CargoCarrier is near the coordinate within NearRadius.
  -- @param #CARGO self
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number NearRadius The radius when the cargo will board the Carrier (to avoid collision).
  -- @return #boolean
  function CARGO:IsNear( Coordinate, NearRadius )
    --self:F( { PointVec2 = PointVec2, NearRadius = NearRadius } )
  
    if self.CargoObject:IsAlive() then
      --local Distance = PointVec2:Get2DDistance( self.CargoObject:GetPointVec2() )
      --self:F( { CargoObjectName = self.CargoObject:GetName() } )
      --self:F( { CargoObjectVec2 = self.CargoObject:GetVec2() } )
      --self:F( { PointVec2 = PointVec2:GetVec2() } )
      local Distance = Coordinate:Get2DDistance( self.CargoObject:GetCoordinate() )
      --self:F( { Distance = Distance, NearRadius = NearRadius or "nil" }  )
      
      if Distance <= NearRadius then
        --self:F( { PointVec2 = PointVec2, NearRadius = NearRadius, IsNear = true } )
        return true
      end
    end
    
    --self:F( { PointVec2 = PointVec2, NearRadius = NearRadius, IsNear = false } )
    return false
  end
  
  
  
  --- Check if Cargo is the given @{Zone}.
  -- @param #CARGO self
  -- @param Core.Zone#ZONE_BASE Zone
  -- @return #boolean **true** if cargo is in the Zone, **false** if cargo is not in the Zone.
  function CARGO:IsInZone( Zone )
    --self:F( { Zone } )
  
    if self:IsLoaded() then
      return Zone:IsPointVec2InZone( self.CargoCarrier:GetPointVec2() )
    else
      --self:F( { Size = self.CargoObject:GetSize(), Units = self.CargoObject:GetUnits() } )
      if self.CargoObject:GetSize() ~= 0 then
        return Zone:IsPointVec2InZone( self.CargoObject:GetPointVec2() )
      else
        return false
      end
    end  
    
    return nil
  
  end
  
  
  --- Get the current PointVec2 of the cargo.
  -- @param #CARGO self
  -- @return Core.Point#POINT_VEC2
  function CARGO:GetPointVec2()
    return self.CargoObject:GetPointVec2()
  end
  
  --- Get the current Coordinate of the cargo.
  -- @param #CARGO self
  -- @return Core.Point#COORDINATE
  function CARGO:GetCoordinate()
    return self.CargoObject:GetCoordinate()
  end
  
  --- Get the weight of the cargo.
  -- @param #CARGO self
  -- @return #number Weight The weight in kg.
  function CARGO:GetWeight()
    return self.Weight 
  end
  
  --- Set the weight of the cargo.
  -- @param #CARGO self
  -- @param #number Weight The weight in kg.
  -- @return #CARGO
  function CARGO:SetWeight( Weight )
    self.Weight = Weight
    return self
  end
  
  --- Get the volume of the cargo.
  -- @param #CARGO self
  -- @return #number Volume The volume in kg.
  function CARGO:GetVolume()
    return self.Volume 
  end
  
  --- Set the volume of the cargo.
  -- @param #CARGO self
  -- @param #number Volume The volume in kg.
  -- @return #CARGO
  function CARGO:SetVolume( Volume )
    self.Volume = Volume
    return self
  end
  
  --- Send a CC message to a @{Wrapper.Group}.
  -- @param #CARGO self
  -- @param #string Message
  -- @param Wrapper.Group#GROUP CarrierGroup The Carrier Group.
  -- @param #string Name (optional) The name of the Group used as a prefix for the message to the Group. If not provided, there will be nothing shown.
  function CARGO:MessageToGroup( Message, CarrierGroup, Name )
  
    MESSAGE:New( Message, 20, "Cargo " .. self:GetName() ):ToGroup( CarrierGroup )
  
  end
  
  --- Report to a Carrier Group.
  -- @param #CARGO self
  -- @param #string Action The string describing the action for the cargo.
  -- @param Wrapper.Group#GROUP CarrierGroup The Carrier Group to send the report to.
  -- @return #CARGO
  function CARGO:Report( ReportText, Action, CarrierGroup )

    if not self.Reported[CarrierGroup] or not self.Reported[CarrierGroup][Action] then
      self.Reported[CarrierGroup] = {}
      self.Reported[CarrierGroup][Action] = true  
      self:MessageToGroup( ReportText, CarrierGroup )
      if self.ReportFlareColor then
        if not self.Reported[CarrierGroup]["Flaring"] then
          self:Flare( self.ReportFlareColor )
          self.Reported[CarrierGroup]["Flaring"] = true
        end
      end
      if self.ReportSmokeColor then
        if not self.Reported[CarrierGroup]["Smoking"] then
          self:Smoke( self.ReportSmokeColor )
          self.Reported[CarrierGroup]["Smoking"] = true
        end
      end
    end
  end
  
  
  --- Report to a Carrier Group with a Flaring signal.
  -- @param #CARGO self
  -- @param Utils#UTILS.FlareColor FlareColor the color of the flare.
  -- @return #CARGO
  function CARGO:ReportFlare( FlareColor )

    self.ReportFlareColor = FlareColor 
  end
  
  
  --- Report to a Carrier Group with a Smoking signal.
  -- @param #CARGO self
  -- @param Utils#UTILS.SmokeColor SmokeColor the color of the smoke.
  -- @return #CARGO
  function CARGO:ReportSmoke( SmokeColor )

    self.ReportSmokeColor = SmokeColor 
  end
  
  
  --- Reset the reporting for a Carrier Group.
  -- @param #CARGO self
  -- @param #string Action The string describing the action for the cargo.
  -- @param Wrapper.Group#GROUP CarrierGroup The Carrier Group to send the report to.
  -- @return #CARGO
  function CARGO:ReportReset( Action, CarrierGroup )

    self.Reported[CarrierGroup][Action] = nil
  end
  
  --- Reset all the reporting for a Carrier Group.
  -- @param #CARGO self
  -- @param Wrapper.Group#GROUP CarrierGroup The Carrier Group to send the report to.
  -- @return #CARGO
  function CARGO:ReportResetAll( CarrierGroup )

    self.Reported[CarrierGroup] = nil
  end
  
  --- Respawn the cargo when destroyed
  -- @param #CARGO self
  -- @param #boolean RespawnDestroyed
  function CARGO:RespawnOnDestroyed( RespawnDestroyed )

    if RespawnDestroyed then
      self.onenterDestroyed = function( self )
        self:Respawn()
      end
    else
      self.onenterDestroyed = nil
    end
      
  end
  

  

end -- CARGO

do -- CARGO_REPRESENTABLE

  --- @type CARGO_REPRESENTABLE
  -- @extends #CARGO
  -- @field test

  --- Models CARGO that is representable by a Unit.
  -- @field #CARGO_REPRESENTABLE CARGO_REPRESENTABLE
  CARGO_REPRESENTABLE = {
    ClassName = "CARGO_REPRESENTABLE"
  }

  --- CARGO_REPRESENTABLE Constructor.
  -- @param #CARGO_REPRESENTABLE self
  -- @param Wrapper.Positionable#POSITIONABLE CargoObject The cargo object.
  -- @param #string Type Type name
  -- @param #string Name Name.
  -- @param #number LoadRadius (optional) Radius in meters.
  -- @param #number NearRadius (optional) Radius in meters when the cargo is loaded into the carrier.
  -- @return #CARGO_REPRESENTABLE
  function CARGO_REPRESENTABLE:New( CargoObject, Type, Name, LoadRadius, NearRadius )
  
    -- Inherit CARGO.
    local self = BASE:Inherit( self, CARGO:New( Type, Name, 0, LoadRadius, NearRadius ) ) -- #CARGO_REPRESENTABLE
    self:F( { Type, Name, LoadRadius, NearRadius } )

    -- Descriptors.
    local Desc=CargoObject:GetDesc()
    self:T({Desc=Desc})
    
    -- Weight.
    local Weight = math.random( 80, 120 )
    
    -- Adjust weight..
    if Desc then
      if Desc.typeName == "2B11 mortar" then
        Weight = 210
      else
        Weight = Desc.massEmpty
      end
    end

    -- Set weight.
    self:SetWeight( Weight )      
    
    return self
  end

  --- CARGO_REPRESENTABLE Destructor.
  -- @param #CARGO_REPRESENTABLE self
  -- @return #CARGO_REPRESENTABLE
  function CARGO_REPRESENTABLE:Destroy()
  
    -- Cargo objects are deleted from the _DATABASE and SET_CARGO objects.
    self:F( { CargoName = self:GetName() } )
    --_EVENTDISPATCHER:CreateEventDeleteCargo( self )
  
    return self
  end
  
  --- Route a cargo unit to a PointVec2.
  -- @param #CARGO_REPRESENTABLE self
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  -- @param #number Speed
  -- @return #CARGO_REPRESENTABLE
  function CARGO_REPRESENTABLE:RouteTo( ToPointVec2, Speed )
    self:F2( ToPointVec2 )
  
    local Points = {}
  
    local PointStartVec2 = self.CargoObject:GetPointVec2()
  
    Points[#Points+1] = PointStartVec2:WaypointGround( Speed )
    Points[#Points+1] = ToPointVec2:WaypointGround( Speed )
  
    local TaskRoute = self.CargoObject:TaskRoute( Points )
    self.CargoObject:SetTask( TaskRoute, 2 )
    return self  
  end
  
  --- Send a message to a @{Wrapper.Group} through a communication channel near the cargo.
  -- @param #CARGO_REPRESENTABLE self
  -- @param #string Message
  -- @param Wrapper.Group#GROUP TaskGroup
  -- @param #string Name (optional) The name of the Group used as a prefix for the message to the Group. If not provided, there will be nothing shown.
  function CARGO_REPRESENTABLE:MessageToGroup( Message, TaskGroup, Name )

    local CoordinateZone = ZONE_RADIUS:New( "Zone" , self:GetCoordinate():GetVec2(), 500 )
    CoordinateZone:Scan( { Object.Category.UNIT } )
    for _, DCSUnit in pairs( CoordinateZone:GetScannedUnits() ) do
      local NearUnit = UNIT:Find( DCSUnit )
      self:F({NearUnit=NearUnit})
      local NearUnitCoalition = NearUnit:GetCoalition()
      local CargoCoalition = self:GetCoalition()
      if NearUnitCoalition == CargoCoalition then
        local Attributes = NearUnit:GetDesc()
        self:F({Desc=Attributes})
        if NearUnit:HasAttribute( "Trucks" ) then
          MESSAGE:New( Message, 20, NearUnit:GetCallsign() .. " reporting - Cargo " .. self:GetName() ):ToGroup( TaskGroup )
          break
        end
      end
    end
  
  end

  
end -- CARGO_REPRESENTABLE

do -- CARGO_REPORTABLE
  
    --- @type CARGO_REPORTABLE
    -- @extends #CARGO
    CARGO_REPORTABLE = {
      ClassName = "CARGO_REPORTABLE"
    }
  
  --- CARGO_REPORTABLE Constructor.
  -- @param #CARGO_REPORTABLE self
  -- @param #string Type
  -- @param #string Name
  -- @param #number Weight
  -- @param #number LoadRadius (optional)
  -- @param #number NearRadius (optional)
  -- @return #CARGO_REPORTABLE
  function CARGO_REPORTABLE:New( Type, Name, Weight, LoadRadius, NearRadius )
    local self = BASE:Inherit( self, CARGO:New( Type, Name, Weight, LoadRadius, NearRadius ) ) -- #CARGO_REPORTABLE
    self:F( { Type, Name, Weight, LoadRadius, NearRadius } )
  
    return self
  end
  
  --- Send a CC message to a @{Wrapper.Group}.
  -- @param #CARGO_REPORTABLE self
  -- @param #string Message
  -- @param Wrapper.Group#GROUP TaskGroup
  -- @param #string Name (optional) The name of the Group used as a prefix for the message to the Group. If not provided, there will be nothing shown.
  function CARGO_REPORTABLE:MessageToGroup( Message, TaskGroup, Name )
  
    MESSAGE:New( Message, 20, "Cargo " .. self:GetName() .. " reporting" ):ToGroup( TaskGroup )
  
  end


  
end







do -- CARGO_PACKAGE

  --- @type CARGO_PACKAGE
  -- @extends #CARGO_REPRESENTABLE
  CARGO_PACKAGE = {
    ClassName = "CARGO_PACKAGE"
  }

--- CARGO_PACKAGE Constructor.
-- @param #CARGO_PACKAGE self
-- @param Wrapper.Unit#UNIT CargoCarrier The UNIT carrying the package.
-- @param #string Type
-- @param #string Name
-- @param #number Weight
-- @param #number LoadRadius (optional)
-- @param #number NearRadius (optional)
-- @return #CARGO_PACKAGE
function CARGO_PACKAGE:New( CargoCarrier, Type, Name, Weight, LoadRadius, NearRadius )
  local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( CargoCarrier, Type, Name, Weight, LoadRadius, NearRadius ) ) -- #CARGO_PACKAGE
  self:F( { Type, Name, Weight, LoadRadius, NearRadius } )

  self:T( CargoCarrier )
  self.CargoCarrier = CargoCarrier

  return self
end

--- Board Event.
-- @param #CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #number Speed
-- @param #number BoardDistance
-- @param #number Angle
function CARGO_PACKAGE:onafterOnBoard( From, Event, To, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
  self:F()

  self.CargoInAir = self.CargoCarrier:InAir()

  self:T( self.CargoInAir )

  -- Only move the CargoCarrier to the New CargoCarrier when the New CargoCarrier is not in the air.
  if not self.CargoInAir then

    local Points = {}

    local StartPointVec2 = self.CargoCarrier:GetPointVec2()
    local CargoCarrierHeading = CargoCarrier:GetHeading() -- Get Heading of object in degrees.
    local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
    self:T( { CargoCarrierHeading, CargoDeployHeading } )
    local CargoDeployPointVec2 = CargoCarrier:GetPointVec2():Translate( BoardDistance, CargoDeployHeading )

    Points[#Points+1] = StartPointVec2:WaypointGround( Speed )
    Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )

    local TaskRoute = self.CargoCarrier:TaskRoute( Points )
    self.CargoCarrier:SetTask( TaskRoute, 1 )
  end

  self:Boarded( CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )

end

--- Check if CargoCarrier is near the Cargo to be Loaded.
-- @param #CARGO_PACKAGE self
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @return #boolean
function CARGO_PACKAGE:IsNear( CargoCarrier )
  self:F()

  local CargoCarrierPoint = CargoCarrier:GetCoordinate()
  
  local Distance = CargoCarrierPoint:Get2DDistance( self.CargoCarrier:GetCoordinate() )
  self:T( Distance )
  
  if Distance <= self.NearRadius then
    return true
  else
    return false
  end
end

--- Boarded Event.
-- @param #CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #number Speed
-- @param #number BoardDistance
-- @param #number LoadDistance
-- @param #number Angle
function CARGO_PACKAGE:onafterOnBoarded( From, Event, To, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
  self:F()

  if self:IsNear( CargoCarrier ) then
    self:__Load( 1, CargoCarrier, Speed, LoadDistance, Angle )
  else
    self:__Boarded( 1, CargoCarrier, Speed, BoardDistance, LoadDistance, Angle )
  end
end

--- UnBoard Event.
-- @param #CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #number Speed
-- @param #number UnLoadDistance
-- @param #number UnBoardDistance
-- @param #number Radius
-- @param #number Angle
function CARGO_PACKAGE:onafterUnBoard( From, Event, To, CargoCarrier, Speed, UnLoadDistance, UnBoardDistance, Radius, Angle )
  self:F()

  self.CargoInAir = self.CargoCarrier:InAir()

  self:T( self.CargoInAir )

  -- Only unboard the cargo when the carrier is not in the air.
  -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
  if not self.CargoInAir then

    self:_Next( self.FsmP.UnLoad, UnLoadDistance, Angle )
  
    local Points = {}

    local StartPointVec2 = CargoCarrier:GetPointVec2()
    local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
    local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
    self:T( { CargoCarrierHeading, CargoDeployHeading } )
    local CargoDeployPointVec2 = StartPointVec2:Translate( UnBoardDistance, CargoDeployHeading )

    Points[#Points+1] = StartPointVec2:WaypointGround( Speed )
    Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )

    local TaskRoute = CargoCarrier:TaskRoute( Points )
    CargoCarrier:SetTask( TaskRoute, 1 )
  end

  self:__UnBoarded( 1 , CargoCarrier, Speed )

end

--- UnBoarded Event.
-- @param #CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #number Speed
function CARGO_PACKAGE:onafterUnBoarded( From, Event, To, CargoCarrier, Speed )
  self:F()

  if self:IsNear( CargoCarrier ) then
    self:__UnLoad( 1, CargoCarrier, Speed )
  else
    self:__UnBoarded( 1, CargoCarrier, Speed )
  end
end

--- Load Event.
-- @param #CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #number Speed
-- @param #number LoadDistance
-- @param #number Angle
function CARGO_PACKAGE:onafterLoad( From, Event, To, CargoCarrier, Speed, LoadDistance, Angle )
  self:F()

  self.CargoCarrier = CargoCarrier

  local StartPointVec2 = self.CargoCarrier:GetPointVec2()
  local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
  local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
  local CargoDeployPointVec2 = StartPointVec2:Translate( LoadDistance, CargoDeployHeading )
  
  local Points = {}
  Points[#Points+1] = StartPointVec2:WaypointGround( Speed )
  Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )

  local TaskRoute = self.CargoCarrier:TaskRoute( Points )
  self.CargoCarrier:SetTask( TaskRoute, 1 )

end

--- UnLoad Event.
-- @param #CARGO_PACKAGE self
-- @param #string Event
-- @param #string From
-- @param #string To
-- @param Wrapper.Unit#UNIT CargoCarrier
-- @param #number Speed
-- @param #number Distance
-- @param #number Angle
function CARGO_PACKAGE:onafterUnLoad( From, Event, To, CargoCarrier, Speed, Distance, Angle )
  self:F()
  
  local StartPointVec2 = self.CargoCarrier:GetPointVec2()
  local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
  local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
  local CargoDeployPointVec2 = StartPointVec2:Translate( Distance, CargoDeployHeading )
  
  self.CargoCarrier = CargoCarrier

  local Points = {}
  Points[#Points+1] = StartPointVec2:WaypointGround( Speed )
  Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )

  local TaskRoute = self.CargoCarrier:TaskRoute( Points )
  self.CargoCarrier:SetTask( TaskRoute, 1 )

end


end
