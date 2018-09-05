--- **AI** -- (R2.3) - Models the intelligent transportation of infantry and other cargo.
--
-- ===
-- 
-- ### Author: **FlightControl**
-- 
-- ===       
--
-- @module AI.AI_Cargo
-- @image AI_Cargo_Dispatching.JPG

--- @type AI_CARGO
-- @extends Core.Fsm#FSM_CONTROLLABLE


--- Brings a dynamic cargo handling capability for AI groups.
-- 
-- Armoured Personnel Carriers (Carrier), Trucks, Jeeps and other ground based carrier equipment can be mobilized to intelligently transport infantry and other cargo within the simulation.
-- The AI\_CARGO\Carrier module uses the @{Cargo} capabilities within the MOOSE framework.
-- CARGO derived objects must be declared within the mission to make the AI\_CARGO\Carrier object recognize the cargo.
-- Please consult the @{Cargo} module for more information. 
-- 
-- ## Cargo loading.
-- 
-- The module will load automatically cargo when the Carriers are within boarding or loading range.
-- The boarding or loading range is specified when the cargo is created in the simulation, and therefore, this range depends on the type of cargo
-- and the specified boarding range.
-- 
-- ## Enemies nearby.
--  
-- When the Carriers are approaching enemy units, something special is happening. 
-- The Carriers will stop moving, and the loaded infantry will unboard and follow the Carriers and will help to defend the group.
-- The carrier will hold the route once the unboarded infantry is further than 50 meters from the Carriers, 
-- to ensure that the Carriers are not too far away from the following running infantry.
-- Once all enemies are cleared, the infantry will board again automatically into the Carriers. Once boarded, the Carriers will follow its pre-defined route.
-- 
-- A combat range needs to be specified in meters at the @{#AI_CARGO.New}() method. 
-- This combat range will trigger the unboarding of troops when enemies are within the combat range around the Carriers.
-- During my tests, I've noticed that there is a balance between ensuring that the infantry is within sufficient hit range (effectiveness) versus
-- vulnerability of the infantry. It all depends on the kind of enemies that are expected to be encountered. 
-- A combat range of 350 meters to 500 meters has been proven to be the most effective and efficient.
-- 
-- ## Infantry health.
-- 
-- When infantry is unboarded from the Carriers, the infantry is actually respawned into the battlefield. 
-- As a result, the unboarding infantry is very _healthy_ every time it unboards.
-- This is due to the limitation of the DCS simulator, which is not able to specify the health of new spawned units as a parameter.
-- However, infantry that was destroyed when unboarded and following the Carriers, won't be respawned again. Destroyed is destroyed.
-- As a result, there is some additional strength that is gained when an unboarding action happens, but in terms of simulation balance this has
-- marginal impact on the overall battlefield simulation. Fortunately, the firing strength of infantry is limited, and thus, respacing healthy infantry every
-- time is not so much of an issue ... 
-- 
-- ## Control the Carriers on the map.
-- 
-- It is possible also as a human ground commander to influence the path of the Carriers, by pointing a new path using the DCS user interface on the map.
-- In this case, the Carriers will change the direction towards its new indicated route. However, there is a catch!
-- Once the Carriers are near the enemy, and infantry is unboarded, the Carriers won't be able to hold the route until the infantry could catch up.
-- The Carriers will simply drive on and won't stop! This is a limitation in ED that prevents user actions being controlled by the scripting engine.
-- No workaround is possible on this.
-- 
-- ## Cargo deployment.
--  
-- Using the @{#AI_CARGO.Deploy}() method, you are able to direct the Carriers towards a point on the battlefield to unboard/unload the cargo at the specific coordinate. 
-- The Carriers will follow nearby roads as much as possible, to ensure fast and clean cargo transportation between the objects and villages in the simulation environment.
-- 
-- ## Cargo pickup.
--  
-- Using the @{#AI_CARGO.Pickup}() method, you are able to direct the Carriers towards a point on the battlefield to board/load the cargo at the specific coordinate. 
-- The Carriers will follow nearby roads as much as possible, to ensure fast and clean cargo transportation between the objects and villages in the simulation environment.
-- 
-- 
-- 
-- @field #AI_CARGO
AI_CARGO = {
  ClassName = "AI_CARGO",
  Coordinate = nil, -- Core.Point#COORDINATE,
  Carrier_Cargo = {},
}

--- Creates a new AI_CARGO object.
-- @param #AI_CARGO self
-- @param Wrapper.Group#GROUP Carrier
-- @param Core.Set#SET_CARGO CargoSet
-- @param #number CombatRadius
-- @return #AI_CARGO
function AI_CARGO:New( Carrier, CargoSet )

  local self = BASE:Inherit( self, FSM_CONTROLLABLE:New( Carrier ) ) -- #AI_CARGO

  self.CargoSet = CargoSet -- Core.Set#SET_CARGO
  self.CargoCarrier = Carrier -- Wrapper.Group#GROUP

  self:SetStartState( "Unloaded" )
  
  self:AddTransition( "Unloaded", "Pickup", "*" )
  self:AddTransition( "Loaded", "Deploy", "*" )
  
  self:AddTransition( "*", "Load", "Boarding" )
  self:AddTransition( { "Boarding", "Loaded" }, "Board", "Boarding" )
  self:AddTransition( "Boarding", "Loaded", "Boarding" )
  self:AddTransition( "Boarding", "PickedUp", "Loaded" )
  
  self:AddTransition( "Loaded", "Unload", "Unboarding" )
  self:AddTransition( "Unboarding", "Unboard", "Unboarding" )
  self:AddTransition( "Unboarding", "Unloaded", "Unboarding" )
  self:AddTransition( "Unboarding", "Deployed", "Unloaded" )
  
  --- Pickup Handler OnBefore for AI_CARGO
  -- @function [parent=#AI_CARGO] OnBeforePickup
  -- @param #AI_CARGO self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h. Default is 50% of max possible speed the group can do. 
  -- @return #boolean
  
  --- Pickup Handler OnAfter for AI_CARGO
  -- @function [parent=#AI_CARGO] OnAfterPickup
  -- @param #AI_CARGO self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h. Default is 50% of max possible speed the group can do.
  
  --- Pickup Trigger for AI_CARGO
  -- @function [parent=#AI_CARGO] Pickup
  -- @param #AI_CARGO self
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h. Default is 50% of max possible speed the group can do.
  
  --- Pickup Asynchronous Trigger for AI_CARGO
  -- @function [parent=#AI_CARGO] __Pickup
  -- @param #AI_CARGO self
  -- @param #number Delay
  -- @param Core.Point#COORDINATE Coordinate Pickup place. If not given, loading starts at the current location.
  -- @param #number Speed Speed in km/h. Default is 50% of max possible speed the group can do.
  
  --- Deploy Handler OnBefore for AI_CARGO
  -- @function [parent=#AI_CARGO] OnBeforeDeploy
  -- @param #AI_CARGO self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h. Default is 50% of max possible speed the group can do.
  -- @return #boolean
  
  --- Deploy Handler OnAfter for AI_CARGO
  -- @function [parent=#AI_CARGO] OnAfterDeploy
  -- @param #AI_CARGO self
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h. Default is 50% of max possible speed the group can do.
  
  --- Deploy Trigger for AI_CARGO
  -- @function [parent=#AI_CARGO] Deploy
  -- @param #AI_CARGO self
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h. Default is 50% of max possible speed the group can do.
  
  --- Deploy Asynchronous Trigger for AI_CARGO
  -- @function [parent=#AI_CARGO] __Deploy
  -- @param #AI_CARGO self
  -- @param #number Delay
  -- @param Core.Point#COORDINATE Coordinate
  -- @param #number Speed Speed in km/h. Default is 50% of max possible speed the group can do.

  
  --- Loaded Handler OnAfter for AI_CARGO
  -- @function [parent=#AI_CARGO] OnAfterLoaded
  -- @param #AI_CARGO self
  -- @param Wrapper.Group#GROUP Carrier
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  
  --- Unloaded Handler OnAfter for AI_CARGO
  -- @function [parent=#AI_CARGO] OnAfterUnloaded
  -- @param #AI_CARGO self
  -- @param Wrapper.Group#GROUP Carrier
  -- @param #string From
  -- @param #string Event
  -- @param #string To
  
  for _, CarrierUnit in pairs( Carrier:GetUnits() ) do
    CarrierUnit:SetCargoBayWeightLimit()
  end
  
  self.Transporting = false
  self.Relocating = false
  
  return self
end



function AI_CARGO:IsTransporting()

  return self.Transporting == true
end

function AI_CARGO:IsRelocating()

  return self.Relocating == true
end



--- On before Load event.
-- @param #AI_CARGO self
-- @param Wrapper.Group#GROUP Carrier
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE PickupZone (optional) The zone where the cargo will be picked up. The PickupZone can be nil, if there wasn't any PickupZoneSet provided.
function AI_CARGO:onbeforeLoad( Carrier, From, Event, To, PickupZone )
  self:F( { Carrier, From, Event, To } )

  local Boarding = false

  local LoadInterval = 10
  local LoadDelay = 10
  local Carrier_List = {}
  local Carrier_Weight = {}

  if Carrier and Carrier:IsAlive() then
    self.Carrier_Cargo = {}
    for _, CarrierUnit in pairs( Carrier:GetUnits() ) do
      local CarrierUnit = CarrierUnit -- Wrapper.Unit#UNIT
      
      local CargoBayFreeWeight = CarrierUnit:GetCargoBayFreeWeight()
      self:F({CargoBayFreeWeight=CargoBayFreeWeight})
      
      Carrier_List[#Carrier_List+1] = CarrierUnit
      Carrier_Weight[CarrierUnit] = CargoBayFreeWeight
    end

    local Carrier_Count = #Carrier_List
    local Carrier_Index = 1
      
    for _, Cargo in UTILS.spairs( self.CargoSet:GetSet(), function( t, a, b ) return t[a]:GetWeight() > t[b]:GetWeight() end ) do
      local Cargo = Cargo -- Cargo.Cargo#CARGO

      self:F( { IsUnLoaded = Cargo:IsUnLoaded(), IsDeployed = Cargo:IsDeployed(), Cargo:GetName(), Carrier:GetName() } )

      local Loaded = false

      -- Try all Carriers, but start from the one according the Carrier_Index
      for Carrier_Loop = 1, #Carrier_List do

        local CarrierUnit = Carrier_List[Carrier_Index] -- Wrapper.Unit#UNIT

        -- This counters loop through the available Carriers.
        Carrier_Index = Carrier_Index + 1
        if Carrier_Index > Carrier_Count then
          Carrier_Index = 1
        end
        
        if Cargo:IsUnLoaded() then -- and not Cargo:IsDeployed() then
          if Cargo:IsInLoadRadius( CarrierUnit:GetCoordinate() ) then
            self:F( { "In radius", CarrierUnit:GetName() } )
            
            local CargoWeight = Cargo:GetWeight()
  
            -- Only when there is space within the bay to load the next cargo item!
            if Carrier_Weight[CarrierUnit] > CargoWeight then --and CargoBayFreeVolume > CargoVolume then
              Carrier:RouteStop()
              --Cargo:Ungroup()
              Cargo:__Board( LoadDelay, CarrierUnit, 25 )
              LoadDelay = LoadDelay + LoadInterval
              self:__Board( LoadDelay, Cargo, CarrierUnit, PickupZone )
  
              -- So now this CarrierUnit has Cargo that is being loaded.
              -- This will be used further in the logic to follow and to check cargo status.
              self.Carrier_Cargo[Cargo] = CarrierUnit
              Boarding = true
              Carrier_Weight[CarrierUnit] = Carrier_Weight[CarrierUnit] - CargoWeight
              Loaded = true
              
              -- Ok, we loaded a cargo, now we can stop the loop.
              break
            end
          end
        end
        
      end
      
      if not Loaded then
        -- If the cargo wasn't loaded in one of the carriers, then we need to stop the loading.
      end
      
    end
  end

  return Boarding
  
end

--- On after Board event.
-- @param #AI_CARGO self
-- @param Wrapper.Group#GROUP Carrier
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Cargo.Cargo#CARGO Cargo Cargo object.
-- @param Wrapper.Unit#UNIT CarrierUnit
-- @param Core.Zone#ZONE PickupZone (optional) The zone where the cargo will be picked up. The PickupZone can be nil, if there wasn't any PickupZoneSet provided.
function AI_CARGO:onafterBoard( Carrier, From, Event, To, Cargo, CarrierUnit, PickupZone )
  self:F( { Carrier, From, Event, To, Cargo, CarrierUnit:GetName() } )

  if Carrier and Carrier:IsAlive() then
    self:F({ IsLoaded = Cargo:IsLoaded(), Cargo:GetName(), Carrier:GetName() } )
    if not Cargo:IsLoaded() then
      self:__Board( 10, Cargo, CarrierUnit, PickupZone )
      return
    end
  end

  self:__Loaded( 10, Cargo, CarrierUnit, PickupZone )
  
end

--- On after Loaded event.
-- @param #AI_CARGO self
-- @param Wrapper.Group#GROUP Carrier
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @return #boolean Cargo loaded.
-- @param Core.Zone#ZONE PickupZone (optional) The zone where the cargo will be picked up. The PickupZone can be nil, if there wasn't any PickupZoneSet provided.
function AI_CARGO:onafterLoaded( Carrier, From, Event, To, Cargo, PickupZone )
  self:F( { Carrier, From, Event, To } )

  local Loaded = true

  if Carrier and Carrier:IsAlive() then
    for Cargo, CarrierUnit in pairs( self.Carrier_Cargo ) do
      local Cargo = Cargo -- Cargo.Cargo#CARGO
      self:F( { IsLoaded = Cargo:IsLoaded(), IsDestroyed = Cargo:IsDestroyed(), Cargo:GetName(), Carrier:GetName() } )
      if not Cargo:IsLoaded() and not Cargo:IsDestroyed() then
        Loaded = false
      end
    end
  end
  
  if Loaded then
    self:PickedUp( PickupZone )
  end
  
end

--- On after PickedUp event.
-- @param #AI_CARGO self
-- @param Wrapper.Group#GROUP Carrier
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE PickupZone (optional) The zone where the cargo will be picked up. The PickupZone can be nil, if there wasn't any PickupZoneSet provided.
function AI_CARGO:onafterPickedUp( Carrier, From, Event, To, PickupZone )
  self:F( { Carrier, From, Event, To } )

  Carrier:RouteResume()
  
end




--- On after Unload event.
-- @param #AI_CARGO self
-- @param Wrapper.Group#GROUP Carrier
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
function AI_CARGO:onafterUnload( Carrier, From, Event, To, DeployZone )
  self:F( { Carrier, From, Event, To, DeployZone } )

  local UnboardInterval = 10
  local UnboardDelay = 10

  if Carrier and Carrier:IsAlive() then
    for _, CarrierUnit in pairs( Carrier:GetUnits() ) do
      local CarrierUnit = CarrierUnit -- Wrapper.Unit#UNIT
      Carrier:RouteStop()
      for _, Cargo in pairs( CarrierUnit:GetCargo() ) do
        if Cargo:IsLoaded() then
          Cargo:__UnBoard( UnboardDelay )
          UnboardDelay = UnboardDelay + UnboardInterval
          Cargo:SetDeployed( true )
          self:__Unboard( UnboardDelay, Cargo, CarrierUnit, DeployZone )
        end 
      end
    end
  end
  
end

--- On after Unboard event.
-- @param #AI_CARGO self
-- @param Wrapper.Group#GROUP Carrier
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string Cargo.Cargo#CARGO Cargo Cargo object.
-- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
function AI_CARGO:onafterUnboard( Carrier, From, Event, To, Cargo, CarrierUnit, DeployZone )
  self:F( { Carrier, From, Event, To, Cargo:GetName() } )

  if Carrier and Carrier:IsAlive() then
    if not Cargo:IsUnLoaded() then
      self:__Unboard( 10, Cargo, CarrierUnit, DeployZone ) 
      return
    end
  end

  self:Unloaded( Cargo, CarrierUnit, DeployZone )
  
end

--- On after Unloaded event.
-- @param #AI_CARGO self
-- @param Wrapper.Group#GROUP Carrier
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param #string Cargo.Cargo#CARGO Cargo Cargo object.
-- @param #boolean Deployed Cargo is deployed.
-- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
function AI_CARGO:onafterUnloaded( Carrier, From, Event, To, Cargo, CarrierUnit, DeployZone )
  self:F( { Carrier, From, Event, To, Cargo:GetName(), DeployZone = DeployZone } )

  local AllUnloaded = true

  --Cargo:Regroup()

  if Carrier and Carrier:IsAlive() then
    for _, CarrierUnit in pairs( Carrier:GetUnits() ) do
      local CarrierUnit = CarrierUnit -- Wrapper.Unit#UNIT
      local IsEmpty = CarrierUnit:IsCargoEmpty()
      self:I({ IsEmpty = IsEmpty })
      if not IsEmpty then
        AllUnloaded = false
        break
      end
    end
    
    if AllUnloaded == true then
      if DeployZone == true then
        self.Carrier_Cargo = {}
      end
      self.CargoCarrier = Carrier
    end
  end

  if AllUnloaded == true then
    self:Deployed( DeployZone )
  end
  
end

--- On after Deployed event.
-- @param #AI_CARGO self
-- @param Wrapper.Group#GROUP Carrier
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
-- @param Core.Zone#ZONE DeployZone The zone wherein the cargo is deployed. This can be any zone type, like a ZONE, ZONE_GROUP, ZONE_AIRBASE.
function AI_CARGO:onafterDeployed( Carrier, From, Event, To, DeployZone )
  self:F( { Carrier, From, Event, To, DeployZone = DeployZone } )

    self:__Guard( 0.1 )

end

