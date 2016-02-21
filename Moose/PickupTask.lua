--- A PICKUPTASK orchestrates the loading of CARGO at a specific landing zone.
-- @classmod PICKUPTASK
-- @parent TASK

Include.File("Task")
Include.File("Cargo")

PICKUPTASK = {
  ClassName = "PICKUPTASK",
  TEXT = { "Pick-Up", "picked-up", "loaded" },
  GoalVerb = "Pick-Up"
}

--- Creates a new PICKUPTASK.
-- @tparam table{string,...}|string LandingZones Table of Zone names where Cargo is to be loaded.
-- @tparam CARGO_TYPE CargoType Type of the Cargo. The type must be of the following Enumeration:..
-- @tparam number OnBoardSide Reflects from which side the cargo Group will be on-boarded on the Carrier.
function PICKUPTASK:New( CargoType, OnBoardSide )
trace.f(self.ClassName)

    -- Child holds the inherited instance of the PICKUPTASK Class to the BASE class.
    local Child = BASE:Inherit( self, TASK:New() )

    local Valid = true
  
    if  Valid then
		Child.Name = 'Pickup Cargo'
		Child.TaskBriefing = "Task: Fly to the indicated landing zones and pickup " .. CargoType .. ". Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the pickup zone."
		Child.CargoType = CargoType
		Child.GoalVerb = CargoType .. " " .. Child.GoalVerb
		Child.OnBoardSide = OnBoardSide
		Child.IsLandingRequired = false -- required to decide whether the client needs to land or not
		Child.IsSlingLoad = false -- Indicates whether the cargo is a sling load cargo
		Child.Stages = { STAGE_CARGO_INIT:New(), STAGE_CARGO_LOAD:New(), STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGELANDING:New(), STAGELANDED:New(), STAGELOAD:New(), STAGEDONE:New() }
		Child.SetStage( Child, 1 )
	end
  
  return Child
end

function PICKUPTASK:FromZone( LandingZone )
trace.f(self.ClassName)

	self.LandingZones.LandingZoneNames[LandingZone.CargoZoneName] = LandingZone.CargoZoneName
	self.LandingZones.LandingZones[LandingZone.CargoZoneName] = LandingZone
	
	return self
end

function PICKUPTASK:InitCargo( InitCargos )
trace.f( self.ClassName, { InitCargos } )

	if type( InitCargos ) == "table" then
		self.Cargos.InitCargos = InitCargos
	else
		self.Cargos.InitCargos = { InitCargos }
	end

	return self
end

function PICKUPTASK:LoadCargo( LoadCargos )
trace.f( self.ClassName, { LoadCargos } )

	if type( LoadCargos ) == "table" then
		self.Cargos.LoadCargos = LoadCargos
	else
		self.Cargos.LoadCargos = { LoadCargos }
	end

	return self
end

function PICKUPTASK:AddCargoMenus( Client, Cargos, TransportRadius )
trace.f( self.ClassName )
  
	for CargoID, Cargo in pairs( Cargos ) do

		trace.i( self.ClassName, { Cargo.ClassName, Cargo.CargoName, Cargo.CargoType, Cargo:IsStatusNone(), Cargo:IsStatusLoaded(), Cargo:IsStatusLoading(), Cargo:IsStatusUnLoaded() } )
		
		if Cargo:IsStatusNone() then
		
			local MenuAdd = false
			if Cargo:IsNear( Client, self.CurrentCargoZone ) then
				MenuAdd = true
			end
			
			if MenuAdd then
				if Client._Menus[Cargo.CargoType] == nil then
					Client._Menus[Cargo.CargoType] = {}
				end
				
				if not Client._Menus[Cargo.CargoType].PickupMenu then
					Client._Menus[Cargo.CargoType].PickupMenu = missionCommands.addSubMenuForGroup(
						Client:GetClientGroupID(), 
						self.TEXT[1] .. " " .. Cargo.CargoType, 
						nil
					)
					trace.i( self.ClassName, 'Added PickupMenu: ' .. self.TEXT[1] .. " " .. Cargo.CargoType )
				end

				if Client._Menus[Cargo.CargoType].PickupSubMenus == nil then
					Client._Menus[Cargo.CargoType].PickupSubMenus = {}
				end

				Client._Menus[Cargo.CargoType].PickupSubMenus[ #Client._Menus[Cargo.CargoType].PickupSubMenus + 1 ] = missionCommands.addCommandForGroup(
					Client:GetClientGroupID(), 
					Cargo.CargoName .. " ( " .. Cargo.CargoWeight .. "kg )",
					Client._Menus[Cargo.CargoType].PickupMenu, 
					self.MenuAction,
					{ ReferenceTask = self, CargoTask = Cargo }
				)
				trace.i( self.ClassName, 'Added PickupSubMenu' .. Cargo.CargoType .. ":" .. Cargo.CargoName .. " ( " .. Cargo.CargoWeight .. "kg )" )
			end
		end
	end
	
end

function PICKUPTASK:RemoveCargoMenus( Client )
trace.f( self.ClassName )

	for MenuID, MenuData in pairs( Client._Menus ) do
		for SubMenuID, SubMenuData in pairs( MenuData.PickupSubMenus ) do
			missionCommands.removeItemForGroup( Client:GetClientGroupID(), SubMenuData )
			trace.i( self.ClassName, "Removed PickupSubMenu " )
			SubMenuData = nil
		end
		if MenuData.PickupMenu then
			missionCommands.removeItemForGroup( Client:GetClientGroupID(), MenuData.PickupMenu )
			trace.i( self.ClassName, "Removed PickupMenu " )
			MenuData.PickupMenu = nil
		end
	end
			
end



function PICKUPTASK:HasFailed( ClientDead )
trace.f(self.ClassName)

	local TaskHasFailed = self.TaskFailed
	return TaskHasFailed
end

