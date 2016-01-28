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
function DEPLOYTASK:New( CargoType )
trace.f(self.ClassName)

	-- Child holds the inherited instance of the DEPLOYTASK Class to the BASE class.
	local Child = BASE:Inherit( self, TASK:New() )
  
	local Valid = true
  
    if Valid then
		Child.Name = 'Deploy Cargo'
		Child.TaskBriefing = "Fly to one of the indicated landing zones and deploy " .. CargoType .. ". Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the deployment zone."
		Child.CargoType = CargoType
		Child.GoalVerb = CargoType .. " " .. self.GoalVerb
		Child.Stages = { STAGE_CARGO_INIT:New(), STAGE_CARGO_LOAD:New(), STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGELANDING:New(), STAGELANDED:New(), STAGEUNLOAD:New(), STAGEDONE:New() }
		Child.SetStage( Child, 1 )
	end
  
	return Child
end

function DEPLOYTASK:ToZone( LandingZone )
trace.f(self.ClassName)

	self.LandingZones.LandingZoneNames[LandingZone.CargoZoneName] = LandingZone.CargoZoneName
	self.LandingZones.LandingZones[LandingZone.CargoZoneName] = LandingZone
	
	return self
end


function DEPLOYTASK:InitCargo( InitCargos )
trace.f( self.ClassName, { InitCargos } )

	if type( InitCargos ) == "table" then
		self.Cargos.InitCargos = InitCargos
	else
		self.Cargos.InitCargos = { InitCargos }
	end


	return self
end


function DEPLOYTASK:LoadCargo( LoadCargos )
trace.f( self.ClassName, { LoadCargos } )

	if type( LoadCargos ) == "table" then
		self.Cargos.LoadCargos = LoadCargos
	else
		self.Cargos.LoadCargos = { LoadCargos }
	end

	return self
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
trace.f( self.ClassName )

	for CargoID, Cargo in pairs( Cargos ) do

		trace.i( self.ClassName, { Cargo.ClassName, Cargo.CargoName, Cargo.CargoType } )
		
		if Cargo:IsStatusLoaded() then


			if Client._Menus[Cargo.CargoType] == nil then
				Client._Menus[Cargo.CargoType] = {}
			end
			
			if not Client._Menus[Cargo.CargoType].DeployMenu then
				Client._Menus[Cargo.CargoType].DeployMenu = missionCommands.addSubMenuForGroup(
					Client:ClientGroup():getID(), 
					self.TEXT[1], 
					nil
				)
				trace.i( self.ClassName, 'Added DeployMenu ' .. self.TEXT[1] )
			end
			
			if Client._Menus[Cargo.CargoType].DeploySubMenus == nil then
				Client._Menus[Cargo.CargoType].DeploySubMenus = {}
			end
			
			if Client._Menus[Cargo.CargoType].DeployMenu == nil then
				trace.i( self.ClassName, 'deploymenu is nil' )
			end

			Client._Menus[Cargo.CargoType].DeploySubMenus[ #Client._Menus[Cargo.CargoType].DeploySubMenus + 1 ].MenuPath = missionCommands.addCommandForGroup(
				Client:ClientGroup():getID(), 
				Cargo.CargoName .. " ( " .. Cargo.CargoWeight .. "kg )",
				Client._Menus[Cargo.CargoType].DeployMenu, 
				self.MenuAction,
				{ ReferenceTask = self, CargoTask = Cargo }
			)
			trace.i( self.ClassName, 'Added DeploySubMenu ' .. Cargo.CargoType .. ":" .. Cargo.CargoName .. " ( " .. Cargo.CargoWeight .. "kg )" )
		end
	end

end

function DEPLOYTASK:RemoveCargoMenus( Client )
trace.f(self.ClassName )

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
