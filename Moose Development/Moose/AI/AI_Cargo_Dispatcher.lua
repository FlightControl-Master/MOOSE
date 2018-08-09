--- **AI** -- (R2.4) - Models the intelligent transportation of infantry and other cargo.
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Cargo_Dispatcher
-- @image AI_Cargo_Dispatcher.JPG

--- @type AI_CARGO_DISPATCHER
-- @extends Core.Fsm#FSM


--- A dynamic cargo handling capability for AI groups.
-- 
-- Carrier equipment can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- The AI\_CARGO\_DISPATCHER module uses the @{Cargo} capabilities within the MOOSE framework, to enable Carrier GROUP objects 
-- to transport @{Cargo} towards several deploy zones.
-- CARGO derived objects must be declared within the mission to make the AI\_CARGO\_DISPATCHER object recognize the cargo.
-- Please consult the @{Cargo} module for more information. 
-- 
-- ## 1. AI\_CARGO\_DISPATCHER constructor
--   
--   * @{#AI_CARGO_DISPATCHER.New}(): Creates a new AI\_CARGO\_DISPATCHER object.
-- 
-- ## 2. AI\_CARGO\_DISPATCHER is a FSM
-- 
-- ![Process](..\Presentations\AI_PATROL\Dia2.JPG)
-- 
-- ### 2.1. AI\_CARGO\_DISPATCHER States
-- 
--   * **Monitoring**: The process is dispatching.
--   * **Idle**: The process is idle.
-- 
-- ### 2.2. AI\_CARGO\_DISPATCHER Events
-- 
--   * **Monitor**: Monitor and take action.
--   * **Start**: Start the transport process.
--   * **Stop**: Stop the transport process.
--   * **Pickup**: Pickup cargo.
--   * **Load**: Load the cargo.
--   * **Loaded**: Flag that the cargo is loaded.
--   * **Deploy**: Deploy cargo to a location.
--   * **Unload**: Unload the cargo.
--   * **Unloaded**: Flag that the cargo is unloaded.
--   * **Home**: A Carrier is going home.
-- 
-- ## 3. Set the pickup parameters.
-- 
-- Several parameters can be set to pickup cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER.SetPickupRadius}(): Sets or randomizes the pickup location for the carrier around the cargo coordinate in a radius defined an outer and optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER.SetPickupSpeed}(): Set the speed or randomizes the speed in km/h to pickup the cargo.
--    
-- ## 4. Set the deploy parameters.
-- 
-- Several parameters can be set to deploy cargo:
-- 
--    * @{#AI_CARGO_DISPATCHER.SetDeployRadius}(): Sets or randomizes the deploy location for the carrier around the cargo coordinate in a radius defined an outer and an optional inner radius. 
--    * @{#AI_CARGO_DISPATCHER.SetDeploySpeed}(): Set the speed or randomizes the speed in km/h to deploy the cargo.
-- 
-- ## 5. Set the home zone when there isn't any more cargo to pickup.
-- 
-- A home zone can be specified to where the Carriers will move when there isn't any cargo left for pickup.
-- Use @{#AI_CARGO_DISPATCHER.SetHomeZone}() to specify the home zone.
-- 
-- If no home zone is specified, the carriers will wait near the deploy zone for a new pickup command.   
-- 
-- ===
--   
-- @field #AI_CARGO_DISPATCHER
AI_CARGO_DISPATCHER = {
  ClassName = "AI_CARGO_DISPATCHER",
  SetCarrier = nil,
  DeployZonesSet = nil,
  AI_Cargo = {},
  PickupCargo = {}
}

--- @field #AI_CARGO_DISPATCHER.AI_Cargo 
AI_CARGO_DISPATCHER.AI_Cargo = {}

--- @field #AI_CARGO_DISPATCHER.PickupCargo
AI_CARGO_DISPATCHER.PickupCargo = {}


--- Creates a new AI_CARGO_DISPATCHER object.
-- @param #AI_CARGO_DISPATCHER self
-- @param Core.Set#SET_GROUP SetCarrier
-- @param Core.Set#SET_CARGO SetCargo
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- SetCarriers = SET_GROUP:New():FilterPrefixes( "APC" ):FilterStart()
-- SetCargos = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
-- SetDeployZone = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetCarrier, SetCargo )
-- 
function AI_CARGO_DISPATCHER:New( SetCarrier, SetCargo )

  local self = BASE:Inherit( self, FSM:New() ) -- #AI_CARGO_DISPATCHER

  self.SetCarrier = SetCarrier -- Core.Set#SET_GROUP
  self.SetCargo = SetCargo -- Core.Set#SET_CARGO

  self:SetStartState( "Idle" ) 
  
  self:AddTransition( "Monitoring", "Monitor", "Monitoring" )

  self:AddTransition( "Idle", "Start", "Monitoring" )
  self:AddTransition( "Monitoring", "Stop", "Idle" )
  

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
  
  self.PickupCargo = {}
  self.CarrierHome = {}
  
  -- Put a Dead event handler on SetCarrier, to ensure that when a carrier is destroyed, that all internal parameters are reset.
  function SetCarrier.OnAfterRemoved( SetCarrier, From, Event, To, CarrierName, Carrier )
    self:F( { Carrier = Carrier:GetName() } )
    self.PickupCargo[Carrier] = nil
    self.CarrierHome[Carrier] = nil
  end
  
  return self
end


--- Creates a new AI_CARGO_DISPATCHER object.
-- @param #AI_CARGO_DISPATCHER self
-- @param Core.Set#SET_GROUP SetCarriers
-- @param Core.Set#SET_CARGO SetCargos
-- @param Core.Set#SET_ZONE DeployZonesSet
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- SetCarriers = SET_GROUP:New():FilterPrefixes( "APC" ):FilterStart()
-- SetCargos = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
-- DeployZonesSet = SET_ZONE:New():FilterPrefixes( "Deploy" ):FilterStart()
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetCarrier, SetCargo, SetDeployZone )
-- 
function AI_CARGO_DISPATCHER:NewWithZones( SetCarriers, SetCargos, DeployZonesSet )

  local self = AI_CARGO_DISPATCHER:New( SetCarriers, SetCargos ) -- #AI_CARGO_DISPATCHER
  
  self.DeployZonesSet = DeployZonesSet
  
  return self
end


--- Creates a new AI_CARGO_DISPATCHER object.
-- @param #AI_CARGO_DISPATCHER self
-- @param Core.Set#SET_GROUP SetCarrier
-- @param Core.Set#SET_CARGO SetCargo
-- @param Core.Set#SET_AIRBASE PickupAirbasesSet
-- @param Core.Set#SET_AIRBASE DeployAirbasesSet
-- @return #AI_CARGO_DISPATCHER
-- @usage
-- 
-- -- Create a new cargo dispatcher
-- SetCarriers = SET_GROUP:New():FilterPrefixes( "APC" ):FilterStart()
-- SetCargos = SET_CARGO:New():FilterTypes( "Infantry" ):FilterStart()
-- PickupAirbasesSet = SET_AIRBASES:New()
-- DeployAirbasesSet = SET_AIRBASES:New()
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetCarrier, SetCargo, PickupAirbasesSet, DeployAirbasesSet )
-- 
function AI_CARGO_DISPATCHER:NewWithAirbases( SetCarriers, SetCargos, PickupAirbasesSet, DeployAirbasesSet )

  local self = AI_CARGO_DISPATCHER:New( SetCarriers, SetCargos ) -- #AI_CARGO_DISPATCHER
  
  self.DeployAirbasesSet = DeployAirbasesSet
  self.PickupAirbasesSet = PickupAirbasesSet
  
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
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetCarrier, SetCargo, SetDeployZone )
-- 
-- -- Set the home coordinate
-- local HomeZone = ZONE:New( "Home" )
-- AICargoDispatcher:SetHomeZone( HomeZone )
-- 
function AI_CARGO_DISPATCHER:SetHomeZone( HomeZone )

  self.HomeZone = HomeZone
  
  return self
end

--- Set the home airbase. This is for air units, i.e. helicopters and airplanes.
-- When there is nothing anymore to pickup, the carriers will go back to their home base. They will await here new orders.
-- @param #AI_CARGO_DISPATCHER self
-- @param Wrapper.Airbase#AIRBASE HomeBase Airbase where the carriers will go after all pickup assignments are done.
-- @return #AI_CARGO_DISPATCHER self
function AI_CARGO_DISPATCHER:SetHomeBase( HomeBase )

  self.HomeBase = HomeBase
  
  return self
end


--- Set the home base.
-- When there is nothing anymore to pickup, the carriers will return to their home airbase. There they will await new orders.
-- @param #AI_CARGO_DISPATCHER self
-- @param Wrapper.Airbase#AIRBASE HomeBase The airbase where the carrier will go to, once they completed all pending assignments.
-- @return #AI_CARGO_DISPATCHER self
function AI_CARGO_DISPATCHER:SetHomeBase( HomeBase )

  self.HomeBase = HomeBase
  
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
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetCarrier, SetCargo, SetDeployZone )
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
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetCarrier, SetCargo, SetDeployZone )
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
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetCarrier, SetCargo, SetDeployZone )
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
-- AICargoDispatcher = AI_CARGO_DISPATCHER:New( SetCarrier, SetCargo, SetDeployZone )
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
function AI_CARGO_DISPATCHER:onafterMonitor()

  for CarrierGroupName, Carrier in pairs( self.SetCarrier:GetSet() ) do
    local Carrier = Carrier -- Wrapper.Group#GROUP
    local AI_Cargo = self.AI_Cargo[Carrier]
    if not AI_Cargo then
    
      -- ok, so this Carrier does not have yet an AI_CARGO handling object...
      -- let's create one and also declare the Loaded and UnLoaded handlers.
      self.AI_Cargo[Carrier] = self:AICargo( Carrier, self.SetCargo, self.CombatRadius )
      AI_Cargo = self.AI_Cargo[Carrier]
      
      function AI_Cargo.OnAfterPickup( AI_Cargo, Carrier, From, Event, To, Cargo )
        self:Pickup( Carrier, Cargo )
      end
      
      function AI_Cargo.OnAfterLoad( AI_Cargo, Carrier, From, Event, To, Cargo )
        self:Loading( Carrier )
      end

      function AI_Cargo.OnAfterLoaded( AI_Cargo, Carrier, From, Event, To, Cargo )
        self:Loaded( Carrier, Cargo )
      end

      function AI_Cargo.OnAfterDeploy( AI_Cargo, Carrier, From, Event, To, Cargo )
        self:Deploy( Carrier, Cargo )
      end      

      function AI_Cargo.OnAfterUnload( AI_Cargo, Carrier, From, Event, To, Cargo )
        self:Unloading( Carrier, Cargo )
      end      

      function AI_Cargo.OnAfterUnloaded( AI_Cargo, Carrier, From, Event, To, Cargo )
        self:Unloaded( Carrier, Cargo )
      end      
    end

    -- The Pickup sequence ...
    -- Check if this Carrier need to go and Pickup something...
    self:I( { IsTransporting = AI_Cargo:IsTransporting() } )
    if AI_Cargo:IsTransporting() == false then
      -- ok, so there is a free Carrier
      -- now find the first cargo that is Unloaded
      
      local PickupCargo = nil
      
      for CargoName, Cargo in pairs( self.SetCargo:GetSet() ) do
        local Cargo = Cargo -- Cargo.Cargo#CARGO
        self:F( { Cargo = Cargo:GetName(), UnLoaded = Cargo:IsUnLoaded(), Deployed = Cargo:IsDeployed(), PickupCargo = self.PickupCargo[Carrier] ~= nil } )
        if Cargo:IsUnLoaded() and not Cargo:IsDeployed() then
          local CargoCoordinate = Cargo:GetCoordinate()
          local CoordinateFree = true
          for CarrierPickup, Coordinate in pairs( self.PickupCargo ) do
            if CarrierPickup:IsAlive() == true then
              if CargoCoordinate:Get2DDistance( Coordinate ) <= 25 then
                CoordinateFree = false
                break
              end
            else
              self.PickupCargo[CarrierPickup] = nil
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
         
        if self.PickupAirbasesSet then
          -- Find airbase within 2km from the cargo with the set.
          local PickupAirbase = self.PickupAirbasesSet:FindAirbaseInRange( PickupCoordinate, 4000 )
          if PickupAirbase then
            AI_Cargo:Pickup( PickupAirbase, math.random( self.PickupMinSpeed, self.PickupMaxSpeed ) )
          end
        else  
          AI_Cargo:Pickup( PickupCoordinate, math.random( self.PickupMinSpeed, self.PickupMaxSpeed ) )
        end
        break
      else
        if self.HomeZone then
          if not self.CarrierHome[Carrier] then
            self.CarrierHome[Carrier] = true
            AI_Cargo:__Home( 60, self.HomeZone:GetRandomPointVec2() )
          end
        elseif self.HomeBase then
          if not self.CarrierHome[Carrier] then
            self.CarrierHome[Carrier] = true
            AI_Cargo:__RTB( 60, self.HomeBase )
          end        
        end
      end
    end
  end

  self:__Monitor( self.MonitorTimeInterval )
end

--- Start Handler OnBefore for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] OnBeforeStart
-- @param #AI_CARGO_DISPATCHER self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #boolean

--- Start Handler OnAfter for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] OnAfterStart
-- @param #AI_CARGO_DISPATCHER self
-- @param #string From
-- @param #string Event
-- @param #string To

--- Start Trigger for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] Start
-- @param #AI_CARGO_DISPATCHER self

--- Start Asynchronous Trigger for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] __Start
-- @param #AI_CARGO_DISPATCHER self
-- @param #number Delay

function AI_CARGO_DISPATCHER:onafterStart( From, Event, To )
  self:__Monitor( -1 )
end

--- Stop Handler OnBefore for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] OnBeforeStop
-- @param #AI_CARGO_DISPATCHER self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @return #boolean

--- Stop Handler OnAfter for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] OnAfterStop
-- @param #AI_CARGO_DISPATCHER self
-- @param #string From
-- @param #string Event
-- @param #string To

--- Stop Trigger for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] Stop
-- @param #AI_CARGO_DISPATCHER self

--- Stop Asynchronous Trigger for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] __Stop
-- @param #AI_CARGO_DISPATCHER self
-- @param #number Delay



--- Loaded Handler OnAfter for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] OnAfterLoaded
-- @param #AI_CARGO_DISPATCHER self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Wrapper.Group#GROUP Carrier Carrier object.
-- @param Cargo.Cargo#CARGO Cargo Cargo object.

--- Unloaded Handler OnAfter for AI_CARGO_DISPATCHER
-- @function [parent=#AI_CARGO_DISPATCHER] OnAfterUnloaded
-- @param #AI_CARGO_DISPATCHER self
-- @param #string From
-- @param #string Event
-- @param #string To
-- @param Wrapper.Group#GROUP Carrier
-- @param Cargo.Cargo#CARGO Cargo






--- Make a Carrier run for a cargo deploy action after the cargo has been loaded, by default.
-- @param #AI_CARGO_DISPATCHER self
-- @param From
-- @param Event
-- @param To
-- @param Wrapper.Group#GROUP Carrier
-- @param Cargo.Cargo#CARGO Cargo
-- @return #AI_CARGO_DISPATCHER
function AI_CARGO_DISPATCHER:OnAfterLoaded( From, Event, To, Carrier, Cargo )
  

  if self.DeployZonesSet then

    local DeployZone = self.DeployZonesSet:GetRandomZone()
  
    local DeployCoordinate = DeployZone:GetCoordinate():GetRandomCoordinateInRadius( self.DeployOuterRadius, self.DeployInnerRadius )
    self.AI_Cargo[Carrier]:Deploy( DeployCoordinate, math.random( self.DeployMinSpeed, self.DeployMaxSpeed ) )
  
  end
  
  if self.DeployAirbasesSet then

    local DeployAirbase = self.DeployAirbasesSet:GetRandomAirbase()
    self.AI_Cargo[Carrier]:Deploy( DeployAirbase, math.random( self.DeployMinSpeed, self.DeployMaxSpeed ) )
  end
  
   self.PickupCargo[Carrier] = nil
end




