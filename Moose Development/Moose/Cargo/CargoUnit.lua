--- **Cargo** - Management of single cargo logistics, which are based on a @{Wrapper.Unit} object.
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
-- @module Cargo.CargoUnit
-- @image Cargo_Units.JPG

do -- CARGO_UNIT

  --- Models CARGO in the form of units, which can be boarded, unboarded, loaded, unloaded. 
  -- @type CARGO_UNIT
  -- @extends Cargo.Cargo#CARGO_REPRESENTABLE
  
  --- Defines a cargo that is represented by a UNIT object within the simulator, and can be transported by a carrier.
  -- Use the event functions as described above to Load, UnLoad, Board, UnBoard the CARGO_UNIT objects to and from carriers.
  -- Note that ground forces behave in a group, and thus, act in formation, regardless if one unit is commanded to move.
  -- 
  -- This class is used in CARGO_GROUP, and is not meant to be used by mission designers individually.
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
  function CARGO_UNIT:New( CargoUnit, Type, Name, LoadRadius, NearRadius )
  
    -- Inherit CARGO_REPRESENTABLE.
    local self = BASE:Inherit( self, CARGO_REPRESENTABLE:New( CargoUnit, Type, Name, LoadRadius, NearRadius ) ) -- #CARGO_UNIT
    
    -- Debug info.
    self:T({Type=Type, Name=Name, LoadRadius=LoadRadius, NearRadius=NearRadius})
  
    -- Set cargo object.
    self.CargoObject = CargoUnit
  
    -- Set event prio.
    self:SetEventPriority( 5 )
  
    return self
  end
  
  --- Enter UnBoarding State.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  -- @param #number NearRadius (optional) Defaut 25 m.
  function CARGO_UNIT:onenterUnBoarding( From, Event, To, ToPointVec2, NearRadius )
    self:F( { From, Event, To, ToPointVec2, NearRadius } )
  
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
            if CargoCarrier:IsShip() then
              -- If CargoCarrier is a ship, we don't want to spawn the units in the water next to the boat. Use destination coord instead.
              self.CargoObject:ReSpawnAt( ToPointVec2, CargoDeployHeading )
            else
              self.CargoObject:ReSpawnAt( FromPointVec2, CargoDeployHeading )
            end
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
  -- @param #number NearRadius (optional) Defaut 100 m.
  function CARGO_UNIT:onleaveUnBoarding( From, Event, To, ToPointVec2, NearRadius )
    self:F( { From, Event, To, ToPointVec2, NearRadius } )
  
    local Angle = 180
    local Speed = 10
    local Distance = 5
  
    if From == "UnBoarding" then
      --if self:IsNear( ToPointVec2, NearRadius ) then
        return true
      --else
        
        --self:__UnBoarding( 1, ToPointVec2, NearRadius )
      --end
      --return false
    end
  
  end
  
  --- UnBoard Event.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Core.Point#POINT_VEC2 ToPointVec2
  -- @param #number NearRadius (optional) Defaut 100 m.
  function CARGO_UNIT:onafterUnBoarding( From, Event, To, ToPointVec2, NearRadius )
    self:F( { From, Event, To, ToPointVec2, NearRadius } )
  
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
        self.CargoObject:ReSpawnAt( ToPointVec2, 0 )
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
  -- @param Wrapper.Group#GROUP CargoCarrier
  -- @param #number NearRadius
  function CARGO_UNIT:onafterBoard( From, Event, To, CargoCarrier, NearRadius, ... )
    self:F( { From, Event, To, CargoCarrier, NearRadius = NearRadius } )
  
    self.CargoInAir = self.CargoObject:InAir()
    
    local Desc = self.CargoObject:GetDesc()
    local MaxSpeed = Desc.speedMaxOffRoad
    local TypeName = Desc.typeName
    
    --self:F({Unit=self.CargoObject:GetName()})
    
    -- A cargo unit can only be boarded if it is not dead
    
      -- Only move the group to the carrier when the cargo is not in the air
      -- (eg. cargo can be on a oil derrick, moving the cargo on the oil derrick will drop the cargo on the sea).
      if not self.CargoInAir then
        -- If NearRadius is given, then use the given NearRadius, otherwise calculate the NearRadius 
        -- based upon the Carrier bounding radius, which is calculated from the bounding rectangle on the Y axis.
        local NearRadius = NearRadius or CargoCarrier:GetBoundingRadius() + 5
        if self:IsNear( CargoCarrier:GetPointVec2(), NearRadius ) then
          self:Load( CargoCarrier, NearRadius, ... )
        else
          if MaxSpeed and MaxSpeed == 0 or TypeName and TypeName == "Stinger comm" then
            self:Load( CargoCarrier, NearRadius, ... )
          else
            
            local Speed = 90
            local Angle = 180
            local Distance = 0
            
            local CargoCarrierPointVec2 = CargoCarrier:GetPointVec2()
            local CargoCarrierHeading = CargoCarrier:GetHeading() -- Get Heading of object in degrees.
            local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
            local CargoDeployPointVec2 = CargoCarrierPointVec2:Translate( Distance, CargoDeployHeading )
            
            -- Set the CargoObject to state Green to ensure it is boarding!
            self.CargoObject:OptionAlarmStateGreen()
            
            local Points = {}
          
            local PointStartVec2 = self.CargoObject:GetPointVec2()
          
            Points[#Points+1] = PointStartVec2:WaypointGround( Speed )
            Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed )
            
            local TaskRoute = self.CargoObject:TaskRoute( Points )
            self.CargoObject:SetTask( TaskRoute, 2 )
            self:__Boarding( -5, CargoCarrier, NearRadius, ... )
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
  -- @param #number NearRadius Default 25 m.
  function CARGO_UNIT:onafterBoarding( From, Event, To, CargoCarrier, NearRadius, ... )
    self:F( { From, Event, To, CargoCarrier:GetName(), NearRadius = NearRadius } )
    
    self:F( { IsAlive=self.CargoObject:IsAlive() }  )
    
      if CargoCarrier and CargoCarrier:IsAlive() then -- and self.CargoObject and self.CargoObject:IsAlive() then 
        if (CargoCarrier:IsAir() and not CargoCarrier:InAir()) or true then
          local NearRadius = NearRadius or CargoCarrier:GetBoundingRadius( NearRadius ) + 5
          if self:IsNear( CargoCarrier:GetPointVec2(), NearRadius ) then
            self:__Load( -1, CargoCarrier, ... )
          else
            if self:IsNear( CargoCarrier:GetPointVec2(), 20 ) then
              self:__Boarding( -1, CargoCarrier, NearRadius, ... )
              self.RunCount = self.RunCount + 1
            else
              self:__Boarding( -2, CargoCarrier, NearRadius, ... )
              self.RunCount = self.RunCount + 2
            end
            if self.RunCount >= 40 then
              self.RunCount = 0
              local Speed = 90
              local Angle = 180
              local Distance = 0
              
              --self:F({Unit=self.CargoObject:GetName()})
  
              local CargoCarrierPointVec2 = CargoCarrier:GetPointVec2()
              local CargoCarrierHeading = CargoCarrier:GetHeading() -- Get Heading of object in degrees.
              local CargoDeployHeading = ( ( CargoCarrierHeading + Angle ) >= 360 ) and ( CargoCarrierHeading + Angle - 360 ) or ( CargoCarrierHeading + Angle )
              local CargoDeployPointVec2 = CargoCarrierPointVec2:Translate( Distance, CargoDeployHeading )
            
              -- Set the CargoObject to state Green to ensure it is boarding!
              self.CargoObject:OptionAlarmStateGreen()
  
              local Points = {}
            
              local PointStartVec2 = self.CargoObject:GetPointVec2()
            
              Points[#Points+1] = PointStartVec2:WaypointGround( Speed, "Off road" )
              Points[#Points+1] = CargoDeployPointVec2:WaypointGround( Speed, "Off road" )
            
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
  
  
  --- Loaded State.
  -- @param #CARGO_UNIT self
  -- @param #string Event
  -- @param #string From
  -- @param #string To
  -- @param Wrapper.Unit#UNIT CargoCarrier
  function CARGO_UNIT:onenterLoaded( From, Event, To, CargoCarrier )
    self:F( { From, Event, To, CargoCarrier } )
  
    self.CargoCarrier = CargoCarrier
    
    --self:F({Unit=self.CargoObject:GetName()})
    
    -- Only destroy the CargoObject if there is a CargoObject (packages don't have CargoObjects).
    if self.CargoObject then
      self.CargoObject:Destroy( false )
      --self.CargoObject:ReSpawnAt( COORDINATE:NewFromVec2( {x=0,y=0} ), 0 )
    end
  end

  --- Get the transportation method of the Cargo.
  -- @param #CARGO_UNIT self
  -- @return #string The transportation method of the Cargo.
  function CARGO_UNIT:GetTransportationMethod()
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

end -- CARGO_UNIT
