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
  -- @param #number Weight
  -- @param #number ReportRadius (optional)
  -- @param #number NearRadius (optional)
  -- @return #CARGO_CRATE
  function CARGO_CRATE:New( CargoStatic, Type, Name, NearRadius )
    local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( CargoStatic, Type, Name, nil, NearRadius ) ) -- #CARGO_CRATE
    self:F( { Type, Name, NearRadius } )
  
    self.CargoObject = CargoStatic
  
    self:T( self.ClassName )
  
    self:SetEventPriority( 5 )
  
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

end

