--- **Cargo** -- Management of single cargo crates, which are based on a @{Static} object.
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
-- @module CargoCrate

do -- CARGO_CRATE

  --- Models the behaviour of cargo crates, which can be slingloaded and boarded on helicopters. 
  -- @type CARGO_CRATE
  -- @extends #CARGO_REPRESENTABLE
  
  --- # CARGO\_CRATE class, extends @{#CARGO_REPRESENTABLE}
  -- 
  -- The CARGO\_CRATE class defines a cargo that is represented by a UNIT object within the simulator, and can be transported by a carrier.
  -- Use the event functions as described above to Load, UnLoad, Board, UnBoard the CARGO\_CRATE objects to and from carriers.
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
  -- @param #number ReportRadius (optional)
  -- @param #number NearRadius (optional)
  -- @return #CARGO_CRATE
  function CARGO_CRATE:New( CargoStatic, Type, Name, ReportRadius, NearRadius )
    local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( CargoStatic, Type, Name, nil, ReportRadius, NearRadius ) ) -- #CARGO_CRATE
    self:F( { Type, Name, NearRadius } )
  
    self.CargoObject = CargoStatic
  
    self:T( self.ClassName )
  
    -- Cargo objects are added to the _DATABASE and SET_CARGO objects.
    _EVENTDISPATCHER:CreateEventNewCargo( self )
    
    self:HandleEvent( EVENTS.Dead, self.OnEventCargoDead )
    self:HandleEvent( EVENTS.Crash, self.OnEventCargoDead )
    self:HandleEvent( EVENTS.PlayerLeaveUnit, self.OnEventCargoDead )
    
    self:SetEventPriority( 4 )
  
    return self
  end
  
  
  
  --- Enter UnLoaded State.
  -- @param #CARGO_CRATE self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2
  function CARGO_CRATE:onenterUnLoaded( From, Event, To, ToPointVec2 )
    self:F( { ToPointVec2, From, Event, To } )
  
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
        self.CargoObject:ReSpawn( ToPointVec2, 0 )
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
    self:F( { From, Event, To, CargoCarrier } )
  
    self.CargoCarrier = CargoCarrier
    
    -- Only destroy the CargoObject is if there is a CargoObject (packages don't have CargoObjects).
    if self.CargoObject then
      self:T("Destroying")
      self.CargoObject:Destroy()
    end
  end

  --- Check if the cargo can be Boarded.
  -- @param #CARGO self
  function CARGO:CanBoard()
    return false
  end

  --- Check if the cargo can be Unboarded.
  -- @param #CARGO self
  function CARGO_CRATE:CanUnboard()
    return false
  end

  --- Get the current Coordinate of the CargoGroup.
  -- @param #CARGO_CRATE self
  -- @return Core.Point#COORDINATE The current Coordinate of the first Cargo of the CargoGroup.
  -- @return #nil There is no valid Cargo in the CargoGroup.
  function CARGO_CRATE:GetCoordinate()
    self:F()
    
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

  --- Check if CargoGroup is in the ReportRadius for the Cargo to be Loaded.
  -- @param #CARGO_CRATE self
  -- @param Core.Point#Coordinate Coordinate
  -- @return #boolean true if the CargoGroup is within the reporting radius.
  function CARGO_CRATE:IsInRadius( Coordinate )
    self:F( { Coordinate } )
  
    local Distance = 0
    if self:IsLoaded() then
      Distance = Coordinate:DistanceFromPointVec2( self.CargoCarrier:GetPointVec2() )
    else
      Distance = Coordinate:DistanceFromPointVec2( self.CargoObject:GetPointVec2() )
    end
    self:T( Distance )
    
    if Distance <= self.ReportRadius then
      return true
    else
      return false
    end
  end

  --- Respawn the CargoGroup.
  -- @param #CARGO_CRATE self
  function CARGO_CRATE:Respawn()

    self:F( { "Respawning" } )

    self:SetDeployed( false )
    self:SetStartState( "UnLoaded" )
    
  end
  
end

