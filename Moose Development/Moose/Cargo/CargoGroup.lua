--- **Cargo** -- Management of grouped cargo logistics, which are based on a @{Wrapper.Group} object.
--
-- ===
--
-- ![Banner Image](..\Presentations\CARGO\Dia1.JPG)
--
-- ===
-- 
-- ### [Demo Missions]()
-- 
-- ### [YouTube Playlist]()
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- ### Contributions: 
-- 
-- ===
-- 
-- @module Cargo.CargoGroup
-- @image Cargo_Groups.JPG


do -- CARGO_GROUP

  --- @type CARGO_GROUP
  -- @extends Cargo.Cargo#CARGO_REPORTABLE
  -- @field Core.Set#SET_CARGO CargoSet The collection of derived CARGO objects.
  -- @field #string GroupName The name of the CargoGroup.
  
  --- Defines a cargo that is represented by a @{Wrapper.Group} object within the simulator.
  -- The cargo can be Loaded, UnLoaded, Boarded, UnBoarded to and from Carriers.
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
  -- The
  --
  -- @field #CARGO_GROUP CARGO_GROUP
  -- 
  CARGO_GROUP = {
    ClassName = "CARGO_GROUP",
  }

  --- CARGO_GROUP constructor.
  -- This make a new CARGO_GROUP from a @{Wrapper.Group} object.
  -- It will "ungroup" the group object within the sim, and will create a @{Set} of individual Unit objects.
  -- @param #CARGO_GROUP self
  -- @param Wrapper.Group#GROUP CargoGroup
  -- @param #string Type
  -- @param #string Name
  -- @param #number LoadRadius (optional)
  -- @param #number NearRadius (optional)
  -- @return #CARGO_GROUP
  function CARGO_GROUP:New( CargoGroup, Type, Name, LoadRadius )
    local self = BASE:Inherit( self, CARGO_REPORTABLE:New( Type, Name, 0, LoadRadius ) ) -- #CARGO_GROUP
    self:F( { Type, Name, LoadRadius } )
  
    self.CargoSet = SET_CARGO:New()
    self.CargoGroup = CargoGroup
    self.Grouped = true
    self.CargoUnitTemplate = {}
    
    self:SetDeployed( false )
    
    local WeightGroup = 0
    
    self.CargoGroup:Destroy()

    local GroupName = CargoGroup:GetName()
    self.CargoName = Name
    self.CargoTemplate = UTILS.DeepCopy( _DATABASE:GetGroupTemplate( GroupName ) )

    local GroupTemplate = UTILS.DeepCopy( self.CargoTemplate )
    GroupTemplate.name = self.CargoName .. "#CARGO"
    GroupTemplate.groupId = nil
    
    GroupTemplate.units = {}
    
    for UnitID, UnitTemplate in pairs( self.CargoTemplate.units ) do
      UnitTemplate.name = UnitTemplate.name .. "#CARGO"
      local CargoUnitName = UnitTemplate.name 
      self.CargoUnitTemplate[CargoUnitName] = UnitTemplate      

       GroupTemplate.units[#GroupTemplate.units+1] = self.CargoUnitTemplate[CargoUnitName]
       GroupTemplate.units[#GroupTemplate.units].unitId = nil
      
      -- And we register the spawned unit as part of the CargoSet.
      local Unit = UNIT:Register( CargoUnitName )
      --local WeightUnit = Unit:GetDesc().massEmpty
      --WeightGroup = WeightGroup + WeightUnit
      local CargoUnit = CARGO_UNIT:New( Unit, Type, CargoUnitName, 10 )
      self.CargoSet:Add( CargoUnitName, CargoUnit )
    end

    -- Then we register the new group in the database
    self.CargoGroup = GROUP:NewTemplate( GroupTemplate, GroupTemplate.CoalitionID, GroupTemplate.CategoryID, GroupTemplate.CountryID)
    
    -- Now we spawn the new group based on the template created.
    self.CargoObject = _DATABASE:Spawn( GroupTemplate )
  
    self:SetWeight( WeightGroup )
    self.CargoLimit = 10
    
    self:T( { "Weight Cargo", WeightGroup } )
  
    -- Cargo objects are added to the _DATABASE and SET_CARGO objects.
    _EVENTDISPATCHER:CreateEventNewCargo( self )
    
    self:HandleEvent( EVENTS.Dead, self.OnEventCargoDead )
    self:HandleEvent( EVENTS.Crash, self.OnEventCargoDead )
    self:HandleEvent( EVENTS.PlayerLeaveUnit, self.OnEventCargoDead )
    
    self:SetEventPriority( 4 )
    
    return self
  end

  
  --- Ungroup the cargo group into individual groups with one unit.
  -- This is required because by default a group will move in formation and this is really an issue for group control.
  -- Therefore this method is made to be able to ungroup a group.
  -- This works for ground only groups.
  -- @param #CARGO_GROUP self
  function CARGO_GROUP:Ungroup()

    if self.Grouped == true then
    
      self.Grouped = false
      
      self.CargoGroup:Destroy()
      
      for CargoUnitName, CargoUnit in pairs( self.CargoSet:GetSet() ) do
        local CargoUnit = CargoUnit -- Cargo.CargoUnit#CARGO_UNIT

        if CargoUnit:IsUnLoaded() then
          local GroupTemplate = UTILS.DeepCopy( self.CargoTemplate )
          --local GroupName = env.getValueDictByKey( GroupTemplate.name )
          
          -- We create a new group object with one unit...
          -- First we prepare the template...
          GroupTemplate.name = self.CargoName .. "#CARGO#" .. CargoUnitName 
          GroupTemplate.groupId = nil
          
          if CargoUnit:IsUnLoaded() then
            GroupTemplate.units = {}
            GroupTemplate.units[1] = self.CargoUnitTemplate[CargoUnitName]
            GroupTemplate.units[#GroupTemplate.units].unitId = nil
            GroupTemplate.units[#GroupTemplate.units].x = CargoUnit:GetX()
            GroupTemplate.units[#GroupTemplate.units].y = CargoUnit:GetY()
            GroupTemplate.units[#GroupTemplate.units].heading = CargoUnit:GetHeading()
          end
      
      
          -- Then we register the new group in the database
          local CargoGroup = GROUP:NewTemplate( GroupTemplate, GroupTemplate.CoalitionID, GroupTemplate.CategoryID, GroupTemplate.CountryID)
          
          -- Now we spawn the new group based on the template created.
          _DATABASE:Spawn( GroupTemplate )
        end
      end
      
      self.CargoObject = nil
    end
    
  
  end

  --- Regroup the cargo group into one group with multiple unit.
  -- This is required because by default a group will move in formation and this is really an issue for group control.
  -- Therefore this method is made to be able to regroup a group.
  -- This works for ground only groups.
  -- @param #CARGO_GROUP self
  function CARGO_GROUP:Regroup()
  
    self:F("Regroup")

    if self.Grouped == false then
    
      self.Grouped = true
      
      local GroupTemplate = UTILS.DeepCopy( self.CargoTemplate )
      GroupTemplate.name = self.CargoName .. "#CARGO"
      GroupTemplate.groupId = nil
      GroupTemplate.units = {}

      for CargoUnitName, CargoUnit in pairs( self.CargoSet:GetSet() ) do
        local CargoUnit = CargoUnit -- Cargo.CargoUnit#CARGO_UNIT

        self:F( { CargoUnit:GetName(), UnLoaded = CargoUnit:IsUnLoaded() } )

        if CargoUnit:IsUnLoaded() then
    
          CargoUnit.CargoObject:Destroy()

          GroupTemplate.units[#GroupTemplate.units+1] = self.CargoUnitTemplate[CargoUnitName]
          GroupTemplate.units[#GroupTemplate.units].unitId = nil
          GroupTemplate.units[#GroupTemplate.units].x = CargoUnit:GetX()
          GroupTemplate.units[#GroupTemplate.units].y = CargoUnit:GetY()
          GroupTemplate.units[#GroupTemplate.units].heading = CargoUnit:GetHeading()
        end
      end

      -- Then we register the new group in the database
      self.CargoGroup = GROUP:NewTemplate( GroupTemplate, GroupTemplate.CoalitionID, GroupTemplate.CategoryID, GroupTemplate.CountryID )

      self:F( { "Regroup", GroupTemplate } )
        
      -- Now we spawn the new group based on the template created.
      self.CargoObject = _DATABASE:Spawn( GroupTemplate )
    end
  
  end


  --- @param #CARGO_GROUP self
  -- @param Core.Event#EVENTDATA EventData 
  function CARGO_GROUP:OnEventCargoDead( EventData )
    self:I( EventData )

    local Destroyed = false
  
    if self:IsDestroyed() or self:IsUnLoaded() or self:IsBoarding() or self:IsUnboarding() then
      Destroyed = true
      for CargoID, CargoData in pairs( self.CargoSet:GetSet() ) do
        local Cargo = CargoData -- Cargo.Cargo#CARGO
        if Cargo:IsAlive() then
          Destroyed = false
        else
          Cargo:Destroyed()
        end
      end
    else
      local CarrierName = self.CargoCarrier:GetName()
      if CarrierName == EventData.IniDCSUnitName then
        MESSAGE:New( "Cargo is lost from carrier " .. CarrierName, 15 ):ToAll()
        Destroyed = true
        self.CargoCarrier:ClearCargo()
      end
    end
    
    if Destroyed then
      self:Destroyed()
      self:E( { "Cargo group destroyed" } )
    end
  
  end

  --- Enter Boarding State.
  -- @param #CARGO_GROUP self
  -- @param Wrapper.Unit#UNIT CargoCarrier
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function CARGO_GROUP:onenterBoarding( From, Event, To, CargoCarrier, NearRadius, ... )
    --self:F( { CargoCarrier.UnitName, From, Event, To } )
    
    local NearRadius = NearRadius or 25
    
    if From == "UnLoaded" then
  
      -- For each Cargo object within the CARGO_GROUPED, route each object to the CargoLoadPointVec2
      self.CargoSet:ForEach(
        function( Cargo, ... )
          Cargo:__Board( 1, CargoCarrier, NearRadius, ... )
        end, ...
      )
      
      self:__Boarding( 1, CargoCarrier, NearRadius, ... )
    end
    
  end

  --- Enter Loaded State.
  -- @param #CARGO_GROUP self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Wrapper.Unit#UNIT CargoCarrier
  function CARGO_GROUP:onenterLoaded( From, Event, To, CargoCarrier, ... )
    --self:F( { From, Event, To, CargoCarrier, ...} )
    
    if From == "UnLoaded" then
      -- For each Cargo object within the CARGO_GROUP, load each cargo to the CargoCarrier.
      for CargoID, Cargo in pairs( self.CargoSet:GetSet() ) do
        Cargo:Load( CargoCarrier )
      end
    end
    
    --self.CargoObject:Destroy()
    self.CargoCarrier = CargoCarrier
    self.CargoCarrier:AddCargo( self )
    
  end

  --- Leave Boarding State.
  -- @param #CARGO_GROUP self
  -- @param Wrapper.Unit#UNIT CargoCarrier
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function CARGO_GROUP:onafterBoarding( From, Event, To, CargoCarrier, NearRadius, ... )
    --self:F( { CargoCarrier.UnitName, From, Event, To } )
  
    local NearRadius = NearRadius or 100
  
    local Boarded = true
    local Cancelled = false
    local Dead = true
  
    self.CargoSet:Flush()
  
    -- For each Cargo object within the CARGO_GROUP, route each object to the CargoLoadPointVec2
    for CargoID, Cargo in pairs( self.CargoSet:GetSet() ) do
      self:T( { Cargo:GetName(), Cargo.current } )
      
      
      if not Cargo:is( "Loaded" ) 
      and (not Cargo:is( "Destroyed" )) then -- If one or more units of a group defined as CARGO_GROUP died, the CARGO_GROUP:Board() command does not trigger the CARGO_GRUOP:OnEnterLoaded() function.
        Boarded = false
      end
      
      if Cargo:is( "UnLoaded" ) then
        Cancelled = true
      end
  
      if not Cargo:is( "Destroyed" ) then
        Dead = false
      end
      
    end
  
    if not Dead then
  
      if not Cancelled then
        if not Boarded then
          self:__Boarding( 1, CargoCarrier, NearRadius, ... )
        else
          self:F("Group Cargo is loaded")
          self:__Load( 1, CargoCarrier, ... )
        end
      else
          self:__CancelBoarding( 1, CargoCarrier, NearRadius, ... )
      end
    else
      self:__Destroyed( 1, CargoCarrier, NearRadius, ... )
    end
    
  end

  --- Enter UnBoarding State.
  -- @param #CARGO_GROUP self
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function CARGO_GROUP:onenterUnBoarding( From, Event, To, ToPointVec2, NearRadius, ... )
    --self:F( {From, Event, To, ToPointVec2, NearRadius } )
  
    NearRadius = NearRadius or 25
  
    local Timer = 1
  
    if From == "Loaded" then
    
      if self.CargoObject then
        self.CargoObject:Destroy()
      end
  
      -- For each Cargo object within the CARGO_GROUP, route each object to the CargoLoadPointVec2
      self.CargoSet:ForEach(
        --- @param Cargo.Cargo#CARGO Cargo
        function( Cargo, NearRadius )
          if not Cargo:IsDestroyed() then
            Cargo:__UnBoard( Timer, ToPointVec2, NearRadius )
            Timer = Timer + 3
          end
        end, { NearRadius }
      )
      
      
      self:__UnBoarding( 1, ToPointVec2, NearRadius, ... )
    end
  
  end

  --- Leave UnBoarding State.
  -- @param #CARGO_GROUP self
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function CARGO_GROUP:onleaveUnBoarding( From, Event, To, ToPointVec2, NearRadius, ... )
    --self:F( { From, Event, To, ToPointVec2, NearRadius } )
  
    --local NearRadius = NearRadius or 25
  
    local Angle = 180
    local Speed = 10
    local Distance = 5
  
    if From == "UnBoarding" then
      local UnBoarded = true
  
      -- For each Cargo object within the CARGO_GROUP, route each object to the CargoLoadPointVec2
      for CargoID, Cargo in pairs( self.CargoSet:GetSet() ) do
        self:T( { Cargo:GetName(), Cargo.current } )
        if not Cargo:is( "UnLoaded" ) and not Cargo:IsDestroyed() then
          UnBoarded = false
        end
      end
    
      if UnBoarded then
        return true
      else
        self:__UnBoarding( 1, ToPointVec2, NearRadius, ... )
      end
      
      return false
    end
    
  end

  --- UnBoard Event.
  -- @param #CARGO_GROUP self
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function CARGO_GROUP:onafterUnBoarding( From, Event, To, ToPointVec2, NearRadius, ... )
    --self:F( { From, Event, To, ToPointVec2, NearRadius } )
  
    --local NearRadius = NearRadius or 25
  
    self:__UnLoad( 1, ToPointVec2, ... )
  end



  --- Enter UnLoaded State.
  -- @param #CARGO_GROUP self
  -- @param Core.Point#POINT_VEC2
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function CARGO_GROUP:onenterUnLoaded( From, Event, To, ToPointVec2, ... )
    --self:F( { From, Event, To, ToPointVec2 } )
  
    if From == "Loaded" then
      
      -- For each Cargo object within the CARGO_GROUP, route each object to the CargoLoadPointVec2
      self.CargoSet:ForEach(
        function( Cargo )
          --Cargo:UnLoad( ToPointVec2 )
          local RandomVec2=ToPointVec2:GetRandomPointVec2InRadius(10)
          Cargo:UnLoad( RandomVec2 )
        end
      )
  
    end
    
    self.CargoCarrier:RemoveCargo( self )
    self.CargoCarrier = nil
    
  end


  --- Get the current Coordinate of the CargoGroup.
  -- @param #CARGO_GROUP self
  -- @return Core.Point#COORDINATE The current Coordinate of the first Cargo of the CargoGroup.
  -- @return #nil There is no valid Cargo in the CargoGroup.
  function CARGO_GROUP:GetCoordinate()
    self:F()

    local Cargo = self:GetFirstAlive() -- Cargo.Cargo#CARGO
    
    if Cargo then
      return Cargo.CargoObject:GetCoordinate()
    end
    
    return nil
  end

  --- Get the x position of the cargo.
  -- @param #CARGO_GROUP self
  -- @return #number
  function CARGO:GetX()

    local Cargo = self:GetFirstAlive() -- Cargo.Cargo#CARGO

    if Cargo then
      return Cargo:GetCoordinate().x
    end 
    
    return nil
  end
  
  --- Get the y position of the cargo.
  -- @param #CARGO_GROUP self
  -- @return #number
  function CARGO:GetY()

    local Cargo = self:GetFirstAlive() -- Cargo.Cargo#CARGO

    if Cargo then
      return Cargo:GetCoordinate().z
    end
    
    return nil 
  end
  


  --- Check if the CargoGroup is alive.
  -- @param #CARGO_GROUP self
  -- @return #boolean true if the CargoGroup is alive.
  -- @return #boolean false if the CargoGroup is dead.
  function CARGO_GROUP:IsAlive()

    local Cargo = self:GetFirstAlive() -- Cargo.Cargo#CARGO
    return Cargo ~= nil
  
  end

  
  --- Get the first alive Cargo Unit of the Cargo Group.
  -- @param #CARGO_GROUP self
  -- @return #CARGO_GROUP
  function CARGO_GROUP:GetFirstAlive()
    
    local CargoFirstAlive = nil
    
    for _, Cargo in pairs( self.CargoSet:GetSet() ) do
      if not Cargo:IsDestroyed() then
        CargoFirstAlive = Cargo
        break
      end
    end
    return CargoFirstAlive
  end

  
  --- Get the amount of cargo units in the group.
  -- @param #CARGO_GROUP self
  -- @return #CARGO_GROUP
  function CARGO_GROUP:GetCount()
    return self.CargoSet:Count()
  end


  --- Get the amount of cargo units in the group.
  -- @param #CARGO_GROUP self
  -- @return #CARGO_GROUP
  function CARGO_GROUP:GetGroup( Cargo )
    local Cargo = Cargo or self:GetFirstAlive() -- Cargo.Cargo#CARGO
    return Cargo.CargoObject:GetGroup()
  end


  --- Route Cargo to Coordinate and randomize locations.
  -- @param #CARGO_GROUP self
  -- @param Core.Point#COORDINATE Coordinate
  function CARGO_GROUP:RouteTo( Coordinate )
    --self:F( {Coordinate = Coordinate } )
    
    -- For each Cargo within the CargoSet, route each object to the Coordinate
    self.CargoSet:ForEach(
      function( Cargo )
        Cargo.CargoObject:RouteGroundTo( Coordinate, 10, "vee", 0 )
      end
    )

  end
  
  --- Check if Cargo is near to the Carrier.
  -- The Cargo is near to the Carrier if the first unit of the Cargo Group is within NearRadius.
  -- @param #CARGO_GROUP self
  -- @param Wrapper.Group#GROUP CargoCarrier
  -- @param #number NearRadius
  -- @return #boolean The Cargo is near to the Carrier.
  -- @return #nil The Cargo is not near to the Carrier.
  function CARGO_GROUP:IsNear( CargoCarrier, NearRadius )
    self:F( {NearRadius = NearRadius } )
    
    for _, Cargo in pairs( self.CargoSet:GetSet() ) do
      local Cargo = Cargo -- Cargo.Cargo#CARGO
      if Cargo:IsAlive() then
        if Cargo:IsNear( CargoCarrier:GetCoordinate(), NearRadius ) then
          self:F( "Near" )
          return true
        end
      end
    end
    
    return nil
  end

  --- Check if Cargo Group is in the radius for the Cargo to be Boarded.
  -- @param #CARGO_GROUP self
  -- @param Core.Point#COORDINATE Coordinate
  -- @return #boolean true if the Cargo Group is within the load radius.
  function CARGO_GROUP:IsInLoadRadius( Coordinate )
    --self:F( { Coordinate } )
  
    local Cargo = self:GetFirstAlive() -- Cargo.Cargo#CARGO

    if Cargo then
      local Distance = 0
      if Cargo:IsLoaded() then
        Distance = Coordinate:Get2DDistance( Cargo.CargoCarrier:GetCoordinate() )
      else
        Distance = Coordinate:Get2DDistance( Cargo.CargoObject:GetCoordinate() )
      end
      
      self:F( { Distance = Distance, LoadRadius = self.LoadRadius } )
      if Distance <= self.LoadRadius then
        return true
      else
        return false
      end
    end
    
    return nil
  
  end


  --- Check if Cargo Group is in the report radius.
  -- @param #CARGO_GROUP self
  -- @param Core.Point#Coordinate Coordinate
  -- @return #boolean true if the Cargo Group is within the report radius.
  function CARGO_GROUP:IsInReportRadius( Coordinate )
    --self:F( { Coordinate } )
  
    local Cargo = self:GetFirstAlive() -- Cargo.Cargo#CARGO

    if Cargo then
      self:F( { Cargo } )
      local Distance = 0
      if Cargo:IsUnLoaded() then
        Distance = Coordinate:Get2DDistance( Cargo.CargoObject:GetCoordinate() )
        --self:T( Distance )
        if Distance <= self.LoadRadius then
          return true
        end
      end
    end
    
    return nil
  
  end

  --- Respawn the CargoGroup.
  -- @param #CARGO_GROUP self
  function CARGO_GROUP:Respawn()

    self:F( { "Respawning" } )

    for CargoID, CargoData in pairs( self.CargoSet:GetSet() ) do
      local Cargo = CargoData -- Cargo.Cargo#CARGO
      Cargo:Destroy()
      Cargo:SetStartState( "UnLoaded" )
    end

    
    -- We iterate through the group template and for each unit in the template, we create a new group with one unit.
    for UnitID, UnitTemplate in pairs( self.CargoTemplate.units ) do
      
      local GroupTemplate = UTILS.DeepCopy( self.CargoTemplate )
      local GroupName = env.getValueDictByKey( GroupTemplate.name )
      
      -- We create a new group object with one unit...
      -- First we prepare the template...
      GroupTemplate.name = GroupName .. "#CARGO#" .. UnitID
      GroupTemplate.groupId = nil
      GroupTemplate.units = {}
      GroupTemplate.units[1] = UnitTemplate
      local UnitName = UnitTemplate.name .. "#CARGO"
      GroupTemplate.units[1].name = UnitTemplate.name .. "#CARGO"
  
  
      -- Then we register the new group in the database
      local CargoGroup = GROUP:NewTemplate( GroupTemplate, GroupTemplate.CoalitionID, GroupTemplate.CategoryID, GroupTemplate.CountryID)
      
      -- Now we spawn the new group based on the template created.
      _DATABASE:Spawn( GroupTemplate )
      
      -- And we register the spawned unit as part of the CargoSet.
      local Unit = UNIT:FindByName( UnitName )
      --local WeightUnit = Unit:GetDesc().massEmpty
      --WeightGroup = WeightGroup + WeightUnit
      local CargoUnit = CARGO_UNIT:New( Unit, Type, UnitName, 10 )
      self.CargoSet:Add( UnitName, CargoUnit )
    end

    self:SetDeployed( false )
    self:SetStartState( "UnLoaded" )
    
  end

  --- Signal a flare at the position of the CargoGroup.
  -- @param #CARGO_GROUP self
  -- @param Utilities.Utils#FLARECOLOR FlareColor
  function CARGO_GROUP:Flare( FlareColor )

    local Cargo = self.CargoSet:GetFirst() -- Cargo.Cargo#CARGO
    if Cargo then
      Cargo:Flare( FlareColor )
    end
  end
  
  --- Smoke the CargoGroup.
  -- @param #CARGO_GROUP self
  -- @param Utilities.Utils#SMOKECOLOR SmokeColor The color of the smoke.
  -- @param #number Radius The radius of randomization around the center of the first element of the CargoGroup.
  function CARGO_GROUP:Smoke( SmokeColor, Radius )

    local Cargo = self.CargoSet:GetFirst() -- Cargo.Cargo#CARGO

    if Cargo then
      Cargo:Smoke( SmokeColor, Radius )
    end
  end
  
  --- Check if the first element of the CargoGroup is the given @{Zone}.
  -- @param #CARGO_GROUP self
  -- @param Core.Zone#ZONE_BASE Zone
  -- @return #boolean **true** if the first element of the CargoGroup is in the Zone
  -- @return #boolean **false** if there is no element of the CargoGroup in the Zone.
  function CARGO_GROUP:IsInZone( Zone )
    --self:F( { Zone } )
  
    local Cargo = self.CargoSet:GetFirst() -- Cargo.Cargo#CARGO

    if Cargo then
      return Cargo:IsInZone( Zone )
    end
    
    return nil
  
  end

  --- Get the transportation method of the Cargo.
  -- @param #CARGO_GROUP self
  -- @return #string The transportation method of the Cargo.
  function CARGO_GROUP:GetTransportationMethod()
    if self:IsLoaded() then
      return "for unboarding"
    else
      if self:IsUnLoaded() then
        return "for boarding"
      else
        if self:IsDeployed() then
          return "delivered"
        end
      end
    end
    return ""
  end

    

end -- CARGO_GROUP
