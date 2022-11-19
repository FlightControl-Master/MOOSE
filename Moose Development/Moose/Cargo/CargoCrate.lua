--- **Cargo** - Management of single cargo crates, which are based on a STATIC object.
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
-- @module Cargo.CargoCrate
-- @image Cargo_Crates.JPG

do -- CARGO_CRATE

  --- Models the behaviour of cargo crates, which can be slingloaded and boarded on helicopters. 
  -- @type CARGO_CRATE
  -- @extends Cargo.Cargo#CARGO_REPRESENTABLE
  
  --- Defines a cargo that is represented by a UNIT object within the simulator, and can be transported by a carrier.
  -- Use the event functions as described above to Load, UnLoad, Board, UnBoard the CARGO\_CRATE objects to and from carriers.
  -- 
  -- The above cargo classes are used by the following AI_CARGO_ classes to allow AI groups to transport cargo:
  -- 
  --   * AI Armoured Personnel Carriers to transport cargo and engage in battles, using the @{AI.AI_Cargo_APC} module.
  --   * AI Helicopters to transport cargo, using the @{AI.AI_Cargo_Helicopter} module.
  --   * AI Planes to transport cargo, using the @{AI.AI_Cargo_Airplane} module.
  --   * AI Ships is planned.
  -- 
  -- The above cargo classes are also used by the TASK_CARGO_ classes to allow human players to transport cargo as part of a tasking:
  -- 
  --   * @{Tasking.Task_Cargo_Transport#TASK_CARGO_TRANSPORT} to transport cargo by human players.
  --   * @{Tasking.Task_Cargo_Transport#TASK_CARGO_CSAR} to transport downed pilots by human players.
  -- 
  -- ===
  -- 
  -- @field #CARGO_CRATE
  CARGO_CRATE = {
    ClassName = "CARGO_CRATE"
  }
  
  --- CARGO_CRATE Constructor.
  -- @param #CARGO_CRATE self
  -- @param Wrapper.Static#STATIC CargoStatic
  -- @param #string Type
  -- @param #string Name
  -- @param #number LoadRadius (optional)
  -- @param #number NearRadius (optional)
  -- @return #CARGO_CRATE
  function CARGO_CRATE:New( CargoStatic, Type, Name, LoadRadius, NearRadius )
    local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( CargoStatic, Type, Name, nil, LoadRadius, NearRadius ) ) -- #CARGO_CRATE
    self:F( { Type, Name, NearRadius } )
  
    self.CargoObject = CargoStatic -- Wrapper.Static#STATIC
 
    -- Cargo objects are added to the _DATABASE and SET_CARGO objects.
    _EVENTDISPATCHER:CreateEventNewCargo( self )
    
    self:HandleEvent( EVENTS.Dead, self.OnEventCargoDead )
    self:HandleEvent( EVENTS.Crash, self.OnEventCargoDead )
    --self:HandleEvent( EVENTS.RemoveUnit, self.OnEventCargoDead )
    self:HandleEvent( EVENTS.PlayerLeaveUnit, self.OnEventCargoDead )
    
    self:SetEventPriority( 4 )
    
    self.NearRadius = NearRadius or 25
  
    return self
  end
  
  --- @param #CARGO_CRATE self
  -- @param Core.Event#EVENTDATA EventData 
  function CARGO_CRATE:OnEventCargoDead( EventData )

    local Destroyed = false
  
    if self:IsDestroyed() or self:IsUnLoaded() or self:IsBoarding() then
      if self.CargoObject:GetName() == EventData.IniUnitName then
        if not self.NoDestroy then 
          Destroyed = true
        end
      end
    else
      if self:IsLoaded() then
        local CarrierName = self.CargoCarrier:GetName()
        if CarrierName == EventData.IniDCSUnitName then
          MESSAGE:New( "Cargo is lost from carrier " .. CarrierName, 15 ):ToAll()
          Destroyed = true
          self.CargoCarrier:ClearCargo()
        end
      end
    end
    
    if Destroyed then
      self:I( { "Cargo crate destroyed: " .. self.CargoObject:GetName() } )
      self:Destroyed()
    end
    
  end
  
  
  --- Enter UnLoaded State.
  -- @param #CARGO_CRATE self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2
  function CARGO_CRATE:onenterUnLoaded( From, Event, To, ToPointVec2 )
    --self:F( { ToPointVec2, From, Event, To } )
  
    local Angle = 180
    local Speed = 10
    local Distance = 10
  
    if From == "Loaded" then
      local StartCoordinate = self.CargoCarrier:GetCoordinate()
      local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
      local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
      local CargoDeployCoord = StartCoordinate:Translate( Distance, CargoDeployHeading )
  
      ToPointVec2 = ToPointVec2 or COORDINATE:NewFromVec2( { x= CargoDeployCoord.x, y = CargoDeployCoord.z } )
  
      -- Respawn the group...
      if self.CargoObject then
        self.CargoObject:ReSpawnAt( ToPointVec2, 0 )
        self.CargoCarrier = nil
      end
      
    end
  
    if self.OnUnLoadedCallBack then
      self.OnUnLoadedCallBack( self, unpack( self.OnUnLoadedParameters ) )
      self.OnUnLoadedCallBack = nil
    end
  
  end

  
  --- Loaded State.
  -- @param #CARGO_CRATE self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Wrapper.Unit#UNIT CargoCarrier
  function CARGO_CRATE:onenterLoaded( From, Event, To, CargoCarrier )
    --self:F( { From, Event, To, CargoCarrier } )
  
    self.CargoCarrier = CargoCarrier
    
    -- Only destroy the CargoObject is if there is a CargoObject (packages don't have CargoObjects).
    if self.CargoObject then
      self:T("Destroying")
      self.NoDestroy = true
      self.CargoObject:Destroy( false ) -- Do not generate a remove unit event, because we want to keep the template for later respawn in the database.
      --local Coordinate = self.CargoObject:GetCoordinate():GetRandomCoordinateInRadius( 50, 20 )
      --self.CargoObject:ReSpawnAt( Coordinate, 0 )
    end
  end

  --- Check if the cargo can be Boarded.
  -- @param #CARGO_CRATE self
  function CARGO_CRATE:CanBoard()
    return false
  end

  --- Check if the cargo can be Unboarded.
  -- @param #CARGO_CRATE self
  function CARGO_CRATE:CanUnboard()
    return false
  end

  --- Check if the cargo can be sling loaded.
  -- @param #CARGO_CRATE self
  function CARGO_CRATE:CanSlingload()
    return false
  end

  --- Check if Cargo Crate is in the radius for the Cargo to be reported.
  -- @param #CARGO_CRATE self
  -- @param Core.Point#COORDINATE Coordinate
  -- @return #boolean true if the Cargo Crate is within the report radius.
  function CARGO_CRATE:IsInReportRadius( Coordinate )
    --self:F( { Coordinate, LoadRadius = self.LoadRadius } )
  
    local Distance = 0
    if self:IsUnLoaded() then
      Distance = Coordinate:Get2DDistance( self.CargoObject:GetCoordinate() )
      --self:T( Distance )
      if Distance <= self.LoadRadius then
        return true
      end
    end
    
    return false
  end


  --- Check if Cargo Crate is in the radius for the Cargo to be Boarded or Loaded.
  -- @param #CARGO_CRATE self
  -- @param Core.Point#Coordinate Coordinate
  -- @return #boolean true if the Cargo Crate is within the loading radius.
  function CARGO_CRATE:IsInLoadRadius( Coordinate )
    --self:F( { Coordinate, LoadRadius = self.NearRadius } )
  
    local Distance = 0
    if self:IsUnLoaded() then
      Distance = Coordinate:Get2DDistance( self.CargoObject:GetCoordinate() )
      --self:T( Distance )
      if Distance <= self.NearRadius then
        return true
      end
    end
    
    return false
  end



  --- Get the current Coordinate of the CargoGroup.
  -- @param #CARGO_CRATE self
  -- @return Core.Point#COORDINATE The current Coordinate of the first Cargo of the CargoGroup.
  -- @return #nil There is no valid Cargo in the CargoGroup.
  function CARGO_CRATE:GetCoordinate()
    --self:F()
    
    return self.CargoObject:GetCoordinate()
  end

  --- Check if the CargoGroup is alive.
  -- @param #CARGO_CRATE self
  -- @return #boolean true if the CargoGroup is alive.
  -- @return #boolean false if the CargoGroup is dead.
  function CARGO_CRATE:IsAlive()

    local Alive = true
  
    -- When the Cargo is Loaded, the Cargo is in the CargoCarrier, so we check if the CargoCarrier is alive.
    -- When the Cargo is not Loaded, the Cargo is the CargoObject, so we check if the CargoObject is alive.
    if self:IsLoaded() then
      Alive = Alive == true and self.CargoCarrier:IsAlive()
    else
      Alive = Alive == true and self.CargoObject:IsAlive()
    end 
    
    return Alive
  
  end

  
  --- Route Cargo to Coordinate and randomize locations.
  -- @param #CARGO_CRATE self
  -- @param Core.Point#COORDINATE Coordinate
  function CARGO_CRATE:RouteTo( Coordinate )
    self:F( {Coordinate = Coordinate } )
    
  end

  
  --- Check if Cargo is near to the Carrier.
  -- The Cargo is near to the Carrier within NearRadius.
  -- @param #CARGO_CRATE self
  -- @param Wrapper.Group#GROUP CargoCarrier
  -- @param #number NearRadius
  -- @return #boolean The Cargo is near to the Carrier.
  -- @return #nil The Cargo is not near to the Carrier.
  function CARGO_CRATE:IsNear( CargoCarrier, NearRadius )
    self:F( {NearRadius = NearRadius } )
    
    return self:IsNear( CargoCarrier:GetCoordinate(), NearRadius )
  end

  --- Respawn the CargoGroup.
  -- @param #CARGO_CRATE self
  function CARGO_CRATE:Respawn()

    self:F( { "Respawning crate " .. self:GetName() } )


    -- Respawn the group...
    if self.CargoObject then
      self.CargoObject:ReSpawn() -- A cargo destroy crates a DEAD event.
      self:__Reset( -0.1 )
    end

    
  end


  --- Respawn the CargoGroup.
  -- @param #CARGO_CRATE self
  function CARGO_CRATE:onafterReset()

    self:F( { "Reset crate " .. self:GetName() } )


    -- Respawn the group...
    if self.CargoObject then
      self:SetDeployed( false )
      self:SetStartState( "UnLoaded" )
      self.CargoCarrier = nil
      -- Cargo objects are added to the _DATABASE and SET_CARGO objects.
      _EVENTDISPATCHER:CreateEventNewCargo( self )
    end

    
  end

  --- Get the transportation method of the Cargo.
  -- @param #CARGO_CRATE self
  -- @return #string The transportation method of the Cargo.
  function CARGO_CRATE:GetTransportationMethod()
    if self:IsLoaded() then
      return "for unloading"
    else
      if self:IsUnLoaded() then
        return "for loading"
      else
        if self:IsDeployed() then
          return "delivered"
        end
      end
    end
    return ""
  end
  
end

