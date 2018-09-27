--- **Cargo** -- Management of single cargo crates, which are based on a @{Static} object. The cargo can only be slingloaded.
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
-- @module Cargo.CargoSlingload
-- @image Cargo_Slingload.JPG


do -- CARGO_SLINGLOAD

  --- Models the behaviour of cargo crates, which can only be slingloaded. 
  -- @type CARGO_SLINGLOAD
  -- @extends Cargo.Cargo#CARGO_REPRESENTABLE
  
  --- Defines a cargo that is represented by a UNIT object within the simulator, and can be transported by a carrier.
  -- 
  -- The above cargo classes are also used by the TASK_CARGO_ classes to allow human players to transport cargo as part of a tasking:
  -- 
  --   * @{Tasking.Task_Cargo_Transport#TASK_CARGO_TRANSPORT} to transport cargo by human players.
  --   * @{Tasking.Task_Cargo_Transport#TASK_CARGO_CSAR} to transport downed pilots by human players.
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


  --- @param #CARGO_SLINGLOAD self
  -- @param Core.Event#EVENTDATA EventData 
  function CARGO_SLINGLOAD:OnEventCargoDead( EventData )

    local Destroyed = false
  
    if self:IsDestroyed() or self:IsUnLoaded() then
      if self.CargoObject:GetName() == EventData.IniUnitName then
        if not self.NoDestroy then 
          Destroyed = true
        end
      end
    end
    
    if Destroyed then
      self:I( { "Cargo crate destroyed: " .. self.CargoObject:GetName() } )
      self:Destroyed()
    end
  
  end
  
  
  --- Check if the cargo can be Slingloaded.
  -- @param #CARGO_SLINGLOAD self
  function CARGO_SLINGLOAD:CanSlingload()
    return true
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


  --- Check if Cargo Crate is in the radius for the Cargo to be reported.
  -- @param #CARGO_SLINGLOAD self
  -- @param Core.Point#COORDINATE Coordinate
  -- @return #boolean true if the Cargo Crate is within the report radius.
  function CARGO_SLINGLOAD:IsInReportRadius( Coordinate )
    --self:F( { Coordinate, LoadRadius = self.LoadRadius } )
  
    local Distance = 0
    if self:IsUnLoaded() then
      Distance = Coordinate:Get2DDistance( self.CargoObject:GetCoordinate() )
      if Distance <= self.LoadRadius then
        return true
      end
    end
    
    return false
  end


  --- Check if Cargo Slingload is in the radius for the Cargo to be Boarded or Loaded.
  -- @param #CARGO_SLINGLOAD self
  -- @param Core.Point#COORDINATE Coordinate
  -- @return #boolean true if the Cargo Slingload is within the loading radius.
  function CARGO_SLINGLOAD:IsInLoadRadius( Coordinate )
    --self:F( { Coordinate } )
  
    local Distance = 0
    if self:IsUnLoaded() then
      Distance = Coordinate:Get2DDistance( self.CargoObject:GetCoordinate() )
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
    --self:F()
    
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
    --self:F( {Coordinate = Coordinate } )
    
  end

  
  --- Check if Cargo is near to the Carrier.
  -- The Cargo is near to the Carrier within NearRadius.
  -- @param #CARGO_SLINGLOAD self
  -- @param Wrapper.Group#GROUP CargoCarrier
  -- @param #number NearRadius
  -- @return #boolean The Cargo is near to the Carrier.
  -- @return #nil The Cargo is not near to the Carrier.
  function CARGO_SLINGLOAD:IsNear( CargoCarrier, NearRadius )
    --self:F( {NearRadius = NearRadius } )
    
    return self:IsNear( CargoCarrier:GetCoordinate(), NearRadius )
  end


  --- Respawn the CargoGroup.
  -- @param #CARGO_SLINGLOAD self
  function CARGO_SLINGLOAD:Respawn()

    --self:F( { "Respawning slingload " .. self:GetName() } )


    -- Respawn the group...
    if self.CargoObject then
      self.CargoObject:ReSpawn() -- A cargo destroy crates a DEAD event.
      self:__Reset( -0.1 )
    end

    
  end


  --- Respawn the CargoGroup.
  -- @param #CARGO_SLINGLOAD self
  function CARGO_SLINGLOAD:onafterReset()

    --self:F( { "Reset slingload " .. self:GetName() } )


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
  -- @param #CARGO_SLINGLOAD self
  -- @return #string The transportation method of the Cargo.
  function CARGO_SLINGLOAD:GetTransportationMethod()
    if self:IsLoaded() then
      return "for sling loading"
    else
      if self:IsUnLoaded() then
        return "for sling loading"
      else
        if self:IsDeployed() then
          return "delivered"
        end
      end
    end
    return ""
  end
   
end
