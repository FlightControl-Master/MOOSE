--- **Tasking** -- Models tasks for players to execute CSAR @{Cargo} downed pilots.
-- 
-- ![Banner Image](..\Presentations\TASK_CARGO\Dia1.JPG)
-- 
-- ===


do -- TASK_CARGO_CSAR

  --- The TASK_CARGO_CSAR class
  -- @type TASK_CARGO_CSAR
  -- @extends Tasking.Task_Cargo#TASK_CARGO
  TASK_CARGO_CSAR = {
    ClassName = "TASK_CARGO_CSAR",
  }
  
  --- Instantiates a new TASK_CARGO_CSAR.
  -- @param #TASK_CARGO_CSAR self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_CARGO SetCargo The scope of the cargo to be transported.
  -- @param #string TaskBriefing The Cargo Task briefing.
  -- @return #TASK_CARGO_CSAR self
  function TASK_CARGO_CSAR:New( Mission, SetGroup, TaskName, SetCargo, TaskBriefing )
    local self = BASE:Inherit( self, TASK_CARGO:New( Mission, SetGroup, TaskName, SetCargo, "CSAR", TaskBriefing ) ) -- #TASK_CARGO_CSAR
    self:F()
    
    Mission:AddTask( self )
    
    
    -- Events
    
    self:AddTransition( "*", "CargoPickedUp", "*" )
    self:AddTransition( "*", "CargoDeployed", "*" )
    
    self:F( { CargoDeployed = self.CargoDeployed ~= nil and "true" or "false" } )
    
      --- OnBefore Transition Handler for Event CargoPickedUp.
      -- @function [parent=#TASK_CARGO_CSAR] OnBeforeCargoPickedUp
      -- @param #TASK_CARGO_CSAR self
      -- @param #string From The From State string.
      -- @param #string Event The Event string.
      -- @param #string To The To State string.
      -- @param Wrapper.Unit#UNIT TaskUnit The Unit (Client) that PickedUp the cargo. You can use this to retrieve the PlayerName etc.
      -- @param Core.Cargo#CARGO Cargo The Cargo that got PickedUp by the TaskUnit. You can use this to check Cargo Status.
      -- @return #boolean Return false to cancel Transition.
      
      --- OnAfter Transition Handler for Event CargoPickedUp.
      -- @function [parent=#TASK_CARGO_CSAR] OnAfterCargoPickedUp
      -- @param #TASK_CARGO_CSAR self
      -- @param #string From The From State string.
      -- @param #string Event The Event string.
      -- @param #string To The To State string.
      -- @param Wrapper.Unit#UNIT TaskUnit The Unit (Client) that PickedUp the cargo. You can use this to retrieve the PlayerName etc.
      -- @param Core.Cargo#CARGO Cargo The Cargo that got PickedUp by the TaskUnit. You can use this to check Cargo Status.
        
      --- Synchronous Event Trigger for Event CargoPickedUp.
      -- @function [parent=#TASK_CARGO_CSAR] CargoPickedUp
      -- @param #TASK_CARGO_CSAR self
      -- @param Wrapper.Unit#UNIT TaskUnit The Unit (Client) that PickedUp the cargo. You can use this to retrieve the PlayerName etc.
      -- @param Core.Cargo#CARGO Cargo The Cargo that got PickedUp by the TaskUnit. You can use this to check Cargo Status.
      
      --- Asynchronous Event Trigger for Event CargoPickedUp.
      -- @function [parent=#TASK_CARGO_CSAR] __CargoPickedUp
      -- @param #TASK_CARGO_CSAR self
      -- @param #number Delay The delay in seconds.
      -- @param Wrapper.Unit#UNIT TaskUnit The Unit (Client) that PickedUp the cargo. You can use this to retrieve the PlayerName etc.
      -- @param Core.Cargo#CARGO Cargo The Cargo that got PickedUp by the TaskUnit. You can use this to check Cargo Status.
    
      --- OnBefore Transition Handler for Event CargoDeployed.
      -- @function [parent=#TASK_CARGO_CSAR] OnBeforeCargoDeployed
      -- @param #TASK_CARGO_CSAR self
      -- @param #string From The From State string.
      -- @param #string Event The Event string.
      -- @param #string To The To State string.
      -- @param Wrapper.Unit#UNIT TaskUnit The Unit (Client) that Deployed the cargo. You can use this to retrieve the PlayerName etc.
      -- @param Core.Cargo#CARGO Cargo The Cargo that got PickedUp by the TaskUnit. You can use this to check Cargo Status.
      -- @param Core.Zone#ZONE DeployZone The zone where the Cargo got Deployed or UnBoarded.
      -- @return #boolean Return false to cancel Transition.
      
      --- OnAfter Transition Handler for Event CargoDeployed.
      -- @function [parent=#TASK_CARGO_CSAR] OnAfterCargoDeployed
      -- @param #TASK_CARGO_CSAR self
      -- @param #string From The From State string.
      -- @param #string Event The Event string.
      -- @param #string To The To State string.
      -- @param Wrapper.Unit#UNIT TaskUnit The Unit (Client) that Deployed the cargo. You can use this to retrieve the PlayerName etc.
      -- @param Core.Cargo#CARGO Cargo The Cargo that got PickedUp by the TaskUnit. You can use this to check Cargo Status.
      -- @param Core.Zone#ZONE DeployZone The zone where the Cargo got Deployed or UnBoarded.
        
      --- Synchronous Event Trigger for Event CargoDeployed.
      -- @function [parent=#TASK_CARGO_CSAR] CargoDeployed
      -- @param #TASK_CARGO_CSAR self
      -- @param Wrapper.Unit#UNIT TaskUnit The Unit (Client) that Deployed the cargo. You can use this to retrieve the PlayerName etc.
      -- @param Core.Cargo#CARGO Cargo The Cargo that got PickedUp by the TaskUnit. You can use this to check Cargo Status.
      -- @param Core.Zone#ZONE DeployZone The zone where the Cargo got Deployed or UnBoarded.
      
      --- Asynchronous Event Trigger for Event CargoDeployed.
      -- @function [parent=#TASK_CARGO_CSAR] __CargoDeployed
      -- @param #TASK_CARGO_CSAR self
      -- @param #number Delay The delay in seconds.
      -- @param Wrapper.Unit#UNIT TaskUnit The Unit (Client) that Deployed the cargo. You can use this to retrieve the PlayerName etc.
      -- @param Core.Cargo#CARGO Cargo The Cargo that got PickedUp by the TaskUnit. You can use this to check Cargo Status.
      -- @param Core.Zone#ZONE DeployZone The zone where the Cargo got Deployed or UnBoarded.

    local Fsm = self:GetUnitProcess()

    local CargoReport = REPORT:New( "Rescue a downed pilot from the following position:")
    
    SetCargo:ForEachCargo(
      --- @param Core.Cargo#CARGO Cargo
      function( Cargo )
        local CargoType = Cargo:GetType()
        local CargoName = Cargo:GetName()
        local CargoCoordinate = Cargo:GetCoordinate()
        CargoReport:Add( string.format( '- "%s" (%s) at %s', CargoName, CargoType, CargoCoordinate:ToStringMGRS() ) )
      end
    )
    
    self:SetBriefing( 
      TaskBriefing or 
      CargoReport:Text()
    )

    
    return self
  end 

  function TASK_CARGO_CSAR:ReportOrder( ReportGroup ) 
    
    return 0
  end

  
  --- 
  -- @param #TASK_CARGO_CSAR self
  -- @return #boolean
  function TASK_CARGO_CSAR:IsAllCargoTransported()
  
    local CargoSet = self:GetCargoSet()
    local Set = CargoSet:GetSet()
    
    local DeployZones = self:GetDeployZones()
    
    local CargoDeployed = true
    
    -- Loop the CargoSet (so evaluate each Cargo in the SET_CARGO ).
    for CargoID, CargoData in pairs( Set ) do
      local Cargo = CargoData -- Core.Cargo#CARGO
      
      self:F( { Cargo = Cargo:GetName(), CargoDeployed = Cargo:IsDeployed() } )

      if Cargo:IsDeployed() then
      
--        -- Loop the DeployZones set for the TASK_CARGO_CSAR.
--        for DeployZoneID, DeployZone in pairs( DeployZones ) do
--        
--          -- If all cargo is in one of the deploy zones, then all is good.
--          self:T( { Cargo.CargoObject } )
--          if Cargo:IsInZone( DeployZone ) == false then
--            CargoDeployed = false
--          end
--        end
      else
        CargoDeployed = false
      end
    end

    self:F( { CargoDeployed = CargoDeployed } )
    
    return CargoDeployed
  end
  
  --- @param #TASK_CARGO_CSAR self
  function TASK_CARGO_CSAR:onafterGoal( TaskUnit, From, Event, To )
    local CargoSet = self.CargoSet
    
    if self:IsAllCargoTransported() then
      self:Success()
    end
    
    self:__Goal( -10 )
  end

end

