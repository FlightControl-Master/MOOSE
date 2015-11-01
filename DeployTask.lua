--- A DEPLOYTASK orchestrates the deployment of CARGO within a specific landing zone.
-- @classmod DEPLOYTASK

Include.File( "Task" )

DEPLOYTASK = {
  ClassName = "DEPLOYTASK",
  TEXT = { "Deploy", "deployed", "unloaded" },
  GoalVerb = "Deployment"
}


--- Creates a new DEPLOYTASK object, which models the sequence of STAGEs to unload a cargo.
-- @tparam table{string,...}|string LandingZones Table or name of the zone(s) where Cargo is to be unloaded.
-- @tparam CARGO_TYPE CargoType Type of the Cargo.
function DEPLOYTASK:New( LandingZones, CargoType )
trace.f(self.ClassName)

	-- Child holds the inherited instance of the DEPLOYTASK Class to the BASE class.
	local Child = BASE:Inherit( self, TASK:New() )
  
	local Valid = true
  
	Valid = routines.ValidateZone( LandingZones, "LandingZones", Valid )
    Valid = routines.ValidateEnumeration( CargoType, "CargoType", CARGO_TYPE, Valid )
	
    if Valid then
		Child.Name = 'Deploy Cargo'
		Child.TaskBriefing = "Fly to one of the indicated landing zones and deploy " .. CargoType.TEXT .. ". Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the deployment zone."
		if type( LandingZones ) == "table" then
			Child.LandingZones = LandingZones
		else
			Child.LandingZones = { LandingZones }
		end
		Child.CargoType = CargoType
		Child.GoalVerb = CargoType.TEXT .. " " .. self.GoalVerb
		Child.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGELANDING:New(), STAGELANDED:New(), STAGEUNLOAD:New(), STAGEDONE:New() }
		Child.SetStage( Child, 1 )
	end
  
	return Child
end


--- When the cargo is unloaded, it will move to the target zone name.
-- @tparam string TargetZoneName Name of the Zone to where the Cargo should move after unloading.
function DEPLOYTASK:SetCargoTargetZoneName( TargetZoneName )
trace.f(self.ClassName)
  
  local Valid = true
  
  Valid = routines.ValidateString( TargetZoneName, "TargetZoneName", Valid )
  
  if Valid then
    self.TargetZoneName = TargetZoneName
  end
  
  return Valid
  
end

function DEPLOYTASK:AddCargoMenus( Client, Cargos, TransportRadius )
trace.f(self.ClassName, {Client, Cargos, TransportRadius})

	for CargoID, CargoData in pairs( Client._Cargos ) do

		trace.i( self.ClassName, { CargoData.CargoName } )
		if Client._Menus[CargoData.CargoType] == nil then
			Client._Menus[CargoData.CargoType] = {}
		end
		
		if not Client._Menus[CargoData.CargoType].DeployMenu then
			Client._Menus[CargoData.CargoType].DeployMenu = missionCommands.addSubMenuForGroup(
				Client:ClientGroup():getID(), 
				self.TEXT[1], 
				nil
			)
			trace.i( self.ClassName, 'Added DeployMenu ' .. self.TEXT[1] )
		end
		
		if Client._Menus[CargoData.CargoType].DeploySubMenus == nil then
			Client._Menus[CargoData.CargoType].DeploySubMenus = {}
		end
		
		if Client._Menus[CargoData.CargoType].DeployMenu == nil then
			trace.i( self.ClassName, 'deploymenu is nil' )
		end

		Client._Menus[CargoData.CargoType].DeploySubMenus[ #Client._Menus[CargoData.CargoType].DeploySubMenus + 1 ].MenuPath = missionCommands.addCommandForGroup(
			Client:ClientGroup():getID(), 
			CargoData.CargoName .. " ( " .. CargoData.CargoWeight .. "kg )",
			Client._Menus[CargoData.CargoType].DeployMenu, 
			self.MenuAction,
			{ ReferenceTask = self, CargoName = CargoData.CargoName }
		)
			trace.i( self.ClassName, 'Added DeploySubMenu ' .. CargoData.CargoType.TEXT .. ":" .. CargoData.CargoName .. " ( " .. CargoData.CargoWeight .. "kg )" )
	end

end

function DEPLOYTASK:RemoveCargoMenus( Client )
trace.f(self.ClassName, { Client } )

	for MenuID, MenuData in pairs( Client._Menus ) do
		if MenuData.DeploySubMenus ~= nil then
			for SubMenuID, SubMenuData in pairs( MenuData.DeploySubMenus ) do
				missionCommands.removeItemForGroup( Client:ClientGroup():getID(), SubMenuData )
				trace.i( self.ClassName, "Removed DeploySubMenu " )
				SubMenuData = nil
			end
		end
		if MenuData.DeployMenu then
			missionCommands.removeItemForGroup( Client:ClientGroup():getID(), MenuData.DeployMenu )
			trace.i( self.ClassName, "Removed DeployMenu " )
			MenuData.DeployMenu = nil
		end
	end

end
