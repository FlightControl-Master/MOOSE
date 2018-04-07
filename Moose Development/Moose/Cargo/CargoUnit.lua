--- **Cargo** -- Management of single cargo logistics, which are based on a @{Unit} object.
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
-- @module CargoUnit

do -- CARGO_UNIT

  --- Models CARGO in the form of units, which can be boarded, unboarded, loaded, unloaded. 
  -- @type CARGO_UNIT
  -- @extends Cargo.Cargo#CARGO_REPRESENTABLE
  
  --- # CARGO\_UNIT class, extends @{#CARGO_REPRESENTABLE}
  -- 
  -- The CARGO\_UNIT class defines a cargo that is represented by a UNIT object within the simulator, and can be transported by a carrier.
  -- Use the event functions as described above to Load, UnLoad, Board, UnBoard the CARGO\_UNIT objects to and from carriers.
  -- 
  -- ===
  -- 
  -- @field #CARGO_UNIT CARGO_UNIT
  --
  CARGO_UNIT = {
    ClassName = "CARGO_UNIT"
  }

  --- CARGO_UNIT Constructor.
  -- @param #CARGO_UNIT self
  -- @param Wrapper.Unit#UNIT CargoUnit
  -- @param #string Type
  -- @param #string Name
  -- @param #number Weight
  -- @param #number LoadRadius (optional)
  -- @param #number NearRadius (optional)
  -- @return #CARGO_UNIT
  function CARGO_UNIT:New( CargoUnit, Type, Name, Weight, NearRadius )
    local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( CargoUnit, Type, Name, Weight, NearRadius ) ) -- #CARGO_UNIT
    self:F( { Type, Name, Weight, NearRadius } )
  
    self:T( CargoUnit )
    self.CargoObject = CargoUnit
  
    self:T( self.ClassName )
  
    self:SetEventPriority( 5 )
  
    return self
  end
  
  --- Enter UnBoarding State.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  function CARGO_UNIT:onenterUnBoarding( From, Event, To, ToPointVec2, NearRadius )
    self:F( { From, Event, To, ToPointVec2, NearRadius } )
  
    NearRadius = NearRadius or 25
  
    local Angle = 180
    local Speed = 60
    local DeployDistance = 9
    local RouteDistance = 60
  
    if From == "Loaded" then
  
      if not self:IsDestroyed() then
  
        local CargoCarrier = self.CargoCarrier -- Wrapper.Controllable#CONTROLLABLE
        
        if CargoCarrier:IsAlive() then
    
          local CargoCarrierPointVec2 = CargoCarrier:GetPointVec2()
          local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
          local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
      
      
          local CargoRoutePointVec2 = CargoCarrierPointVec2:Translate( RouteDistance, CargoDeployHeading )
          
          
          -- if there is no ToPointVec2 given, then use the CargoRoutePointVec2
          local FromDirectionVec3 = CargoCarrierPointVec2:GetDirectionVec3( ToPointVec2 or CargoRoutePointVec2 )
          local FromAngle = CargoCarrierPointVec2:GetAngleDegrees(FromDirectionVec3)
          local FromPointVec2 = CargoCarrierPointVec2:Translate( DeployDistance, FromAngle )
        --local CargoDeployPointVec2 = CargoCarrierPointVec2:GetRandomCoordinateInRadius( 10, 5 )
  
          ToPointVec2 = ToPointVec2 or CargoCarrierPointVec2:GetRandomCoordinateInRadius( NearRadius, DeployDistance )
          
          -- Respawn the group...
          if self.CargoObject then
            self.CargoObject:ReSpawn( FromPointVec2:GetVec3(), CargoDeployHeading )
            self:F( { "CargoUnits:", self.CargoObject:GetGroup():GetName() } )
            self.CargoCarrier = nil
      
            local Points = {}
            
            -- From
            Points[#Points+1] = FromPointVec2:WaypointGround( Speed, "Vee" )
            
            -- To
            Points[#Points+1] = ToPointVec2:WaypointGround( Speed, "Vee" )
        
            local TaskRoute = self.CargoObject:TaskRoute( Points )
            self.CargoObject:SetTask( TaskRoute, 1 )
      
            
            self:__UnBoarding( 1, ToPointVec2, NearRadius )
          end
        else
          -- the Carrier is dead. This cargo is dead too!
          self:Destroyed()
        end
      end
    end
  
  end
  
  --- Leave UnBoarding State.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  function CARGO_UNIT:onleaveUnBoarding( From, Event, To, ToPointVec2, NearRadius )
    self:F( { From, Event, To, ToPointVec2, NearRadius } )
  
    NearRadius = NearRadius or 100
  
    local Angle = 180
    local Speed = 10
    local Distance = 5
  
    if From == "UnBoarding" then
      if self:IsNear( ToPointVec2, NearRadius ) then
        return true
      else
        
        self:__UnBoarding( 1, ToPointVec2, NearRadius )
      end
      return false
    end
  
  end
  
  --- UnBoard Event.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  function CARGO_UNIT:onafterUnBoarding( From, Event, To, ToPointVec2, NearRadius )
    self:F( { From, Event, To, ToPointVec2, NearRadius } )
  
    NearRadius = NearRadius or 100
  
    self.CargoInAir = self.CargoObject:InAir()
  
    self:T( self.CargoInAir )
  
    -- Only unboard the cargo when the carrier is not in the air.
    -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
    if not self.CargoInAir then
  
    end
  
    self:__UnLoad( 1, ToPointVec2, NearRadius )
  
  end
  
  
  
  --- Enter UnLoaded State.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2
  function CARGO_UNIT:onenterUnLoaded( From, Event, To, ToPointVec2 )
    self:F( { ToPointVec2, From, Event, To } )
  
    local Angle = 180
    local Speed = 10
    local Distance = 5
  
    if From == "Loaded" then
      local StartPointVec2 = self.CargoCarrier:GetPointVec2()
      local CargoCarrierHeading = self.CargoCarrier:GetHeading() -- Get Heading of object in degrees.
      local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
      local CargoDeployCoord = StartPointVec2:Translate( Distance, CargoDeployHeading )
  
      ToPointVec2 = ToPointVec2 or COORDINATE:New( CargoDeployCoord.x, CargoDeployCoord.z )
  
      -- Respawn the group...
      if self.CargoObject then
        self.CargoObject:ReSpawn( ToPointVec2:GetVec3(), 0 )
        self.CargoCarrier = nil
      end
      
    end
  
    if self.OnUnLoadedCallBack then
      self.OnUnLoadedCallBack( self, unpack( self.OnUnLoadedParameters ) )
      self.OnUnLoadedCallBack = nil
    end
  
  end
  
  --- Board Event.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  function CARGO_UNIT:onafterBoard( From, Event, To, CargoCarrier, NearRadius, ... )
    self:F( { From, Event, To, CargoCarrier, NearRadius } )
  
    local NearRadius = NearRadius or 25
    
    self.CargoInAir = self.CargoObject:InAir()
    
    local Desc = self.CargoObject:GetDesc()
    local MaxSpeed = Desc.speedMaxOffRoad
    local TypeName = Desc.typeName
    
    self:T( self.CargoInAir )
  
    -- Only move the group to the carrier when the cargo is not in the air
    -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
    if not self.CargoInAir then
      if self:IsNear( CargoCarrier:GetPointVec2(), NearRadius ) then
        self:Load( CargoCarrier, NearRadius, ... )
      else
        if MaxSpeed and MaxSpeed == 0 or TypeName and TypeName == "Stinger comm" then
          self:Load( CargoCarrier, NearRadius, ... )
        else
          
          local Speed = 90
          local Angle = 180
          local Distance = 5
          
          NearRadius = NearRadius or 25
        
          local CargoCarrierPointVec2 = CargoCarrier:GetPointVec2()
          local CargoCarrierHeading = CargoCarrier:GetHeading() -- Get Heading of object in degrees.
          local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
          local CargoDeployPointVec2 = CargoCarrierPointVec2:Translate( Distance, CargoDeployHeading )
        
          local Points = {}
        
          local PointStartVec2 = self.CargoObject:GetPointVec2()
        
          Points[#Points+1] = PointStartVec2:WaypointGround( Speed )
          Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )
        
          local TaskRoute = self.CargoObject:TaskRoute( Points )
          self.CargoObject:SetTask( TaskRoute, 2 )
          self:__Boarding( -1, CargoCarrier, NearRadius )
          self.RunCount = 0
        end
      end
    end
    
  end
  
  
  --- Boarding Event.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Wrapper.Client#CLIENT CargoCarrier
  -- @param #number NearRadius
  function CARGO_UNIT:onafterBoarding( From, Event, To, CargoCarrier, NearRadius, ... )
    self:F( { From, Event, To, CargoCarrier.UnitName, NearRadius } )
    
    
    if CargoCarrier and CargoCarrier:IsAlive() and self.CargoObject and self.CargoObject:IsAlive() then 
      if CargoCarrier:InAir() == false then
        if self:IsNear( CargoCarrier:GetPointVec2(), NearRadius ) then
          self:__Load( 1, CargoCarrier, ... )
        else
          self:__Boarding( -1, CargoCarrier, NearRadius, ... )
          self.RunCount = self.RunCount + 1
          if self.RunCount >= 60 then
            self.RunCount = 0
            local Speed = 90
            local Angle = 180
            local Distance = 5
            
            NearRadius = NearRadius or 25
          
            local CargoCarrierPointVec2 = CargoCarrier:GetPointVec2()
            local CargoCarrierHeading = CargoCarrier:GetHeading() -- Get Heading of object in degrees.
            local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
            local CargoDeployPointVec2 = CargoCarrierPointVec2:Translate( Distance, CargoDeployHeading )
          
            local Points = {}
          
            local PointStartVec2 = self.CargoObject:GetPointVec2()
          
            Points[#Points+1] = PointStartVec2:WaypointGround( Speed )
            Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )
          
            local TaskRoute = self.CargoObject:TaskRoute( Points )
            self.CargoObject:SetTask( TaskRoute, 0.2 )
          end
        end
      else
        self.CargoObject:MessageToGroup( "Cancelling Boarding... Get back on the ground!", 5, CargoCarrier:GetGroup(), self:GetName() )
        self:CancelBoarding( CargoCarrier, NearRadius, ... )
        self.CargoObject:SetCommand( self.CargoObject:CommandStopRoute( true ) )
      end
    else
      self:E("Something is wrong")
    end
    
  end
  
  
  --- Enter Boarding State.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Wrapper.Unit#UNIT CargoCarrier
  function CARGO_UNIT:onenterBoarding( From, Event, To, CargoCarrier, NearRadius, ... )
    self:F( { From, Event, To, CargoCarrier.UnitName, NearRadius } )
    
    local Speed = 90
    local Angle = 180
    local Distance = 5
    
    local NearRadius = NearRadius or 25
  
    if From == "UnLoaded" or From == "Boarding" then
    
    end
    
  end
  
  --- Loaded State.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Wrapper.Unit#UNIT CargoCarrier
  function CARGO_UNIT:onenterLoaded( From, Event, To, CargoCarrier )
    self:F( { From, Event, To, CargoCarrier } )
  
    self.CargoCarrier = CargoCarrier
    
    -- Only destroy the CargoObject is if there is a CargoObject (packages don't have CargoObjects).
    if self.CargoObject then
      self:T("Destroying")
      self.CargoObject:Destroy()
    end
  end

end -- CARGO_UNIT
