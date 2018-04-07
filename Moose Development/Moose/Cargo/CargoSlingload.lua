--- **Cargo** -- Management of single cargo crates, which are based on a @{Static} object. The cargo can only be slingloaded.
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


do -- CARGO_SLINGLOAD

  --- Models the behaviour of cargo crates, which can only be slingloaded. 
  -- @type CARGO_SLINGLOAD
  -- @extends Cargo.Cargo#CARGO_REPRESENTABLE
  
  --- # CARGO\_CRATE class, extends @{#CARGO_REPRESENTABLE}
  -- 
  -- The CARGO\_CRATE class defines a cargo that is represented by a UNIT object within the simulator, and can be transported by a carrier.
  -- 
  -- ===
  -- 
  -- @field #CARGO_SLINGLOAD
  CARGO_SLINGLOAD = {
    ClassName = "CARGO_SLINGLOAD"
  }
  
  --- CARGO_SLINGLOAD Constructor.
  -- @param #CARGO_SLINGLOAD self
  -- @param Wrapper.Static#STATIC CargoStatic
  -- @param #string Type
  -- @param #string Name
  -- @param #number LoadRadius (optional)
  -- @param #number NearRadius (optional)
  -- @return #CARGO_SLINGLOAD
  function CARGO_SLINGLOAD:New( CargoStatic, Type, Name, LoadRadius, NearRadius )
    local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( CargoStatic, Type, Name, nil, LoadRadius, NearRadius ) ) -- #CARGO_SLINGLOAD
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
  
  
  --- Check if the cargo can be Boarded.
  -- @param #CARGO_SLINGLOAD self
  function CARGO_SLINGLOAD:CanBoard()
    return false
  end

  --- Check if the cargo can be Unboarded.
  -- @param #CARGO_SLINGLOAD self
  function CARGO_SLINGLOAD:CanUnboard()
    return false
  end

  --- Check if the cargo can be Loaded.
  -- @param #CARGO_SLINGLOAD self
  function CARGO_SLINGLOAD:CanLoad()
    return false
  end

  --- Check if the cargo can be Unloaded.
  -- @param #CARGO_SLINGLOAD self
  function CARGO_SLINGLOAD:CanUnload()
    return false
  end


  --- Check if Cargo Slingload is in the radius for the Cargo to be Boarded or Loaded.
  -- @param #CARGO_SLINGLOAD self
  -- @param Core.Point#Coordinate Coordinate
  -- @return #boolean true if the Cargo Slingload is within the loading radius.
  function CARGO_SLINGLOAD:IsInLoadRadius( Coordinate )
    self:F( { Coordinate } )
  
    local Distance = 0
    if self:IsUnLoaded() then
      Distance = Coordinate:DistanceFromPointVec2( self.CargoObject:GetPointVec2() )
      self:T( Distance )
      if Distance <= self.NearRadius then
        return true
      end
    end
    
    return false
  end



  --- Get the current Coordinate of the CargoGroup.
  -- @param #CARGO_SLINGLOAD self
  -- @return Core.Point#COORDINATE The current Coordinate of the first Cargo of the CargoGroup.
  -- @return #nil There is no valid Cargo in the CargoGroup.
  function CARGO_SLINGLOAD:GetCoordinate()
    self:F()
    
    return self.CargoObject:GetCoordinate()
  end

  --- Check if the CargoGroup is alive.
  -- @param #CARGO_SLINGLOAD self
  -- @return #boolean true if the CargoGroup is alive.
  -- @return #boolean false if the CargoGroup is dead.
  function CARGO_SLINGLOAD:IsAlive()

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
  -- @param #CARGO_SLINGLOAD self
  -- @param Core.Point#COORDINATE Coordinate
  function CARGO_SLINGLOAD:RouteTo( Coordinate )
    self:F( {Coordinate = Coordinate } )
    
  end

  
  --- Check if Cargo is near to the Carrier.
  -- The Cargo is near to the Carrier within NearRadius.
  -- @param #CARGO_SLINGLOAD self
  -- @param Wrapper.Group#GROUP CargoCarrier
  -- @param #number NearRadius
  -- @return #boolean The Cargo is near to the Carrier.
  -- @return #nil The Cargo is not near to the Carrier.
  function CARGO_SLINGLOAD:IsNear( CargoCarrier, NearRadius )
    self:F( {NearRadius = NearRadius } )
    
    return self:IsNear( CargoCarrier:GetCoordinate(), NearRadius )
  end


  --- Respawn the CargoGroup.
  -- @param #CARGO_SLINGLOAD self
  function CARGO_SLINGLOAD:Respawn()

    self:F( { "Respawning" } )

    self:SetDeployed( false )
    self:SetStartState( "UnLoaded" )
    
  end
  
end
