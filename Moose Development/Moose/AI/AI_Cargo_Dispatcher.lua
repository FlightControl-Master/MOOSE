--- **AI** -- (R2.4) - Models the intelligent transportation of infantry and other cargo.
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI_Cargo_Dispatcher

--- @type AI_CARGO_DISPATCHER
-- @extends Core.Fsm#FSM_CONTROLLABLE


--- # AI\_CARGO\_DISPATCHER class, extends @{Core.Base#BASE}
-- 
-- ===
-- 
-- AI\_CARGO\_DISPATCHER brings a dynamic cargo handling capability for AI groups.
-- 
-- Armoured Personnel APCs (APC), Trucks, Jeeps and other carrier equipment can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- The AI\_CARGO\_DISPATCHER module uses the @{Cargo} capabilities within the MOOSE framework.
-- CARGO derived objects must be declared within the mission to make the AI\_CARGO\_DISPATCHER object recognize the cargo.
-- Please consult the @{Cargo} module for more information. 
-- 
-- 
-- 
-- @field #AI_CARGO_DISPATCHER
AI_CARGO_DISPATCHER = {
  ClassName = "AI_CARGO_DISPATCHER",
  SetAPC = nil,
  SetDeployZones = nil,
  AI_CARGO_APC = {}
}

--- @type AI_CARGO_DISPATCHER.AI_CARGO_APC
-- @map <Wrapper.Group#GROUP, AI.AI_Cargo_APC#AI_CARGO_APC>

--- @field #AI_CARGO_DISPATCHER.AI_CARGO_APC 
AI_CARGO_DISPATCHER.AI_Cargo = {}

--- @field #AI_CARGO_DISPATCHER.PickupCargo
AI_CARGO_DISPATCHER.PickupCargo = {}



--- Creates a new AI_CARGO_DISPATCHER object.
-- @param #AI_CARGO_DISPATCHER self
-- @param Core.Set#SET_GROUP SetAPC
-- @param Core.Set#SET_CARGO SetCargo
-- @param Core.Set#SET_ZONE SetDeployZone
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- SetAPC = SET_GROUP:New():FilterPrefixes( "APC" ):FilterStart()
-- SetCargo = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
-- SetDeployZone = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetAPC, SetCargo, SetDeployZone )
-- 
function AI_CARGO_DISPATCHER:New( SetAPC, SetCargo, SetDeployZones )

  local self = BASE:Inherit( self, FSM:New() ) -- #AI_CARGO_DISPATCHER

  self.SetAPC = SetAPC -- Core.Set#SET_GROUP
  self.SetCargo = SetCargo -- Core.Set#SET_CARGO
  self.SetDeployZones = SetDeployZones -- Core.Set#SET_ZONE

  self:SetStartState( "Dispatch" ) 
  
  self:AddTransition( "*", "Monitor", "*" )

  self:AddTransition( "*", "Pickup", "*" )
  self:AddTransition( "*", "Loading", "*" )
  self:AddTransition( "*", "Loaded", "*" )

  self:AddTransition( "*", "Deploy", "*" )
  self:AddTransition( "*", "Unloading", "*" )
  self:AddTransition( "*", "Unloaded", "*" )
  
  self:AddTransition( "*", "Home", "*" )
  
  self.MonitorTimeInterval = 30
  self.DeployRadiusInner = 200
  self.DeployRadiusOuter = 500
  
  self.CarrierHome = {}
  
  return self
end


--- Set the home zone.
-- When there is nothing anymore to pickup, the carriers will go to a random coordinate in this zone.
-- They will await here new orders.
-- @param #AI_CARGO_DISPATCHER self
-- @param Core.Zone#ZONE_BASE HomeZone
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetAPC, SetCargo, SetDeployZone )
-- 
-- -- Set the home coordinate
-- local HomeZone = ZONE:New( "Home" )
-- AICargoDispatcher:SetHomeZone( HomeZone )
-- 
function AI_CARGO_DISPATCHER:SetHomeZone( HomeZone )

  self.HomeZone = HomeZone
  
  return self
end


--- Sets or randomizes the pickup location for the carrier around the cargo coordinate in a radius defined an outer and optional inner radius.
-- This radius is influencing the location where the carrier will land to pickup the cargo.
-- There are two aspects that are very important to remember and take into account:
-- 
--   - Ensure that the outer and inner radius are within reporting radius set by the cargo.
--     For example, if the cargo has a reporting radius of 400 meters, and the outer and inner radius is set to 500 and 450 respectively, 
--     then no cargo will be loaded!!!
--   - Also take care of the potential cargo position and possible reasons to crash the carrier. This is especially important
--     for locations which are crowded with other objects, like in the middle of villages or cities.
--     So, for the best operation of cargo operations, always ensure that the cargo is located at open spaces.
-- 
-- The default radius is 0, so the center. In case of a polygon zone, a random location will be selected as the center in the zone.
-- @param #AI_CARGO_DISPATCHER self
-- @param #number OuterRadius The outer radius in meters around the cargo coordinate.
-- @param #number InnerRadius (optional) The inner radius in meters around the cargo coordinate.
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetAPC, SetCargo, SetDeployZone )
-- 
-- -- Set the carrier to land within a band around the cargo coordinate between 500 and 300 meters!
-- AICargoDispatcher:SetPickupRadius( 500, 300 )
-- 
function AI_CARGO_DISPATCHER:SetPickupRadius( OuterRadius, InnerRadius )

  OuterRadius = OuterRadius or 0
  InnerRadius = InnerRadius or OuterRadius

  self.PickupOuterRadius = OuterRadius
  self.PickupInnerRadius = InnerRadius
  
  return self
end


--- Set the speed or randomizes the speed in km/h to pickup the cargo.
-- @param #AI_CARGO_DISPATCHER self
-- @param #number MaxSpeed (optional) The maximum speed to move to the cargo pickup location.
-- @param #number MinSpeed The minimum speed to move to the cargo pickup location.
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetAPC, SetCargo, SetDeployZone )
-- 
-- -- Set the minimum pickup speed to be 100 km/h and the maximum speed to be 200 km/h.
-- AICargoDispatcher:SetPickupSpeed( 200, 100 )
-- 
function AI_CARGO_DISPATCHER:SetPickupSpeed( MaxSpeed, MinSpeed )

  MaxSpeed = MaxSpeed or 999
  MinSpeed = MinSpeed or MaxSpeed

  self.PickupMinSpeed = MinSpeed
  self.PickupMaxSpeed = MaxSpeed
  
  return self
end


--- Sets or randomizes the deploy location for the carrier around the cargo coordinate in a radius defined an outer and an optional inner radius.
-- This radius is influencing the location where the carrier will land to deploy the cargo.
-- There is an aspect that is very important to remember and take into account:
-- 
--   - Take care of the potential cargo position and possible reasons to crash the carrier. This is especially important
--     for locations which are crowded with other objects, like in the middle of villages or cities.
--     So, for the best operation of cargo operations, always ensure that the cargo is located at open spaces.
-- 
-- The default radius is 0, so the center. In case of a polygon zone, a random location will be selected as the center in the zone.
-- @param #AI_CARGO_DISPATCHER self
-- @param #number OuterRadius The outer radius in meters around the cargo coordinate.
-- @param #number InnerRadius (optional) The inner radius in meters around the cargo coordinate.
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetAPC, SetCargo, SetDeployZone )
-- 
-- -- Set the carrier to land within a band around the cargo coordinate between 500 and 300 meters!
-- AICargoDispatcher:SetDeployRadius( 500, 300 )
-- 
function AI_CARGO_DISPATCHER:SetDeployRadius( OuterRadius, InnerRadius )

  OuterRadius = OuterRadius or 0
  InnerRadius = InnerRadius or OuterRadius

  self.DeployOuterRadius = OuterRadius
  self.DeployInnerRadius = InnerRadius
  
  return self
end


--- Sets or randomizes the speed in km/h to deploy the cargo.
-- @param #AI_CARGO_DISPATCHER self
-- @param #number MaxSpeed The maximum speed to move to the cargo deploy location.
-- @param #number MinSpeed (optional) The minimum speed to move to the cargo deploy location.
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetAPC, SetCargo, SetDeployZone )
-- 
-- -- Set the minimum deploy speed to be 100 km/h and the maximum speed to be 200 km/h.
-- AICargoDispatcher:SetDeploySpeed( 200, 100 )
-- 
function AI_CARGO_DISPATCHER:SetDeploySpeed( MaxSpeed, MinSpeed )

  MaxSpeed = MaxSpeed or 999
  MinSpeed = MinSpeed or MaxSpeed

  self.DeployMinSpeed = MinSpeed
  self.DeployMaxSpeed = MaxSpeed
  
  return self
end



--- The Start trigger event, which actually takes action at the specified time interval.
-- @param #AI_CARGO_DISPATCHER self
-- @param Wrapper.Group#GROUP APC
-- @return #AI_CARGO_DISPATCHER
function AI_CARGO_DISPATCHER:onafterMonitor()

  for APCGroupName, Carrier in pairs( self.SetAPC:GetSet() ) do
    local Carrier = Carrier -- Wrapper.Group#GROUP
    local AI_Cargo = self.AI_Cargo[Carrier]
    if not AI_Cargo then
    
      -- ok, so this APC does not have yet an AI_CARGO_APC object...
      -- let's create one and also declare the Loaded and UnLoaded handlers.
      self.AI_Cargo[Carrier] = self:AICargo( Carrier, self.SetCargo, self.CombatRadius )
      AI_Cargo = self.AI_Cargo[Carrier]
      
      function AI_Cargo.OnAfterPickup( AI_Cargo, APC, From, Event, To, Cargo )
        self:Pickup( APC, Cargo )
      end
      
      function AI_Cargo.OnAfterLoad( AI_Cargo, APC )
        self:Loading( APC )
      end

      function AI_Cargo.OnAfterLoaded( AI_Cargo, APC, From, Event, To, Cargo )
        self:Loaded( APC, Cargo )
      end

      function AI_Cargo.OnAfterDeploy( AI_Cargo, APC )
        self:Deploy( APC )
      end      

      function AI_Cargo.OnAfterUnload( AI_Cargo, APC )
        self:Unloading( APC )
      end      

      function AI_Cargo.OnAfterUnloaded( AI_Cargo, APC )
        self:Unloaded( APC )
      end      
    end

    -- The Pickup sequence ...
    -- Check if this APC need to go and Pickup something...
    self:I( { IsTransporting = AI_Cargo:IsTransporting() } )
    if AI_Cargo:IsTransporting() == false then
      -- ok, so there is a free APC
      -- now find the first cargo that is Unloaded
      
      local PickupCargo = nil
      
      for CargoName, Cargo in pairs( self.SetCargo:GetSet() ) do
        local Cargo = Cargo -- Cargo.Cargo#CARGO
        self:F( { Cargo = Cargo:GetName(), UnLoaded = Cargo:IsUnLoaded(), Deployed = Cargo:IsDeployed(), PickupCargo = self.PickupCargo[Cargo] ~= nil } )
        if Cargo:IsUnLoaded() and not Cargo:IsDeployed() then
          local CargoCoordinate = Cargo:GetCoordinate()
          local CoordinateFree = true
          for APC, Coordinate in pairs( self.PickupCargo ) do
            if CargoCoordinate:Get2DDistance( Coordinate ) <= 25 then
              CoordinateFree = false
              break
            end
          end
          if CoordinateFree == true then
            self.PickupCargo[Carrier] = CargoCoordinate
            PickupCargo = Cargo
            break
          end
        end
      end
      if PickupCargo then
        self.CarrierHome[Carrier] = nil
        local PickupCoordinate = PickupCargo:GetCoordinate():GetRandomCoordinateInRadius( self.PickupOuterRadius, self.PickupInnerRadius )
        AI_Cargo:Pickup( PickupCoordinate, math.random( self.PickupMinSpeed, self.PickupMaxSpeed ) )
        break
      else
        if self.HomeZone then
          if not self.CarrierHome[Carrier] then
            self.CarrierHome[Carrier] = true
            AI_Cargo:__Home( 60, self.HomeZone:GetRandomPointVec2() )
          end
        end
      end
    end
  end

  self:__Monitor( self.MonitorTimeInterval )

  return self
end



--- Make a APC run for a cargo deploy action after the cargo Pickup trigger has been initiated, by default.
-- @param #AI_CARGO_DISPATCHER self
-- @param Wrapper.Group#GROUP APC
-- @return #AI_CARGO_DISPATCHER
function AI_CARGO_DISPATCHER:onafterPickup( From, Event, To, APC, Cargo )
  return self
end

--- Make a APC run for a cargo deploy action after the cargo has been loaded, by default.
-- @param #AI_CARGO_DISPATCHER self
-- @param Wrapper.Group#GROUP APC
-- @return #AI_CARGO_DISPATCHER
function AI_CARGO_DISPATCHER:OnAfterLoaded( From, Event, To, APC, Cargo )

  self:I( { "Loaded Dispatcher", APC } )
  local DeployZone = self.SetDeployZones:GetRandomZone()
  self:I( { RandomZone = DeployZone } )
  
  local DeployCoordinate = DeployZone:GetCoordinate():GetRandomCoordinateInRadius( self.DeployOuterRadius, self.DeployInnerRadius )
  self.AI_Cargo[APC]:Deploy( DeployCoordinate, math.random( self.DeployMinSpeed, self.DeployMaxSpeed ) )
  
  self.PickupCargo[APC] = nil
  
  return self
end




