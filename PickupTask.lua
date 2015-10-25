--- A PICKUPTASK orchestrates the loading of CARGO at a specific landing zone.
-- @classmod PICKUPTASK
-- @parent TASK

Include.File("Task")

PICKUPTASK = {
  ClassName = "PICKUPTASK",
  TEXT = { "Pick-Up", "picked-up", "loaded" },
  GoalVerb = "Pick-Up"
}

--- Creates a new PICKUPTASK.
-- @tparam table{string,...}|string LandingZones Table of Zone names where Cargo is to be loaded.
-- @tparam CARGO_TYPE CargoType Type of the Cargo. The type must be of the following Enumeration:..
-- @tparam number OnBoardSide Reflects from which side the cargo Group will be on-boarded on the Carrier.
function PICKUPTASK:New( LandingZones, CargoType, OnBoardSide )
trace.f(self.ClassName)

    -- Child holds the inherited instance of the PICKUPTASK Class to the BASE class.
    local Child = BASE:Inherit( self, TASK:New() )

    local Valid = true
  
	Valid = routines.ValidateZone( LandingZones, "LandingZones", Valid )
    Valid = routines.ValidateEnumeration( CargoType, "CargoType", CARGO_TYPE, Valid )
    Valid = routines.ValidateEnumeration( CargoType, "CargoType", CARGO_TYPE, Valid )
    --Valid = routines.ValidateEnumeration( OnBoardSide, "OnBoardSide", CLIENT.ONBOARDSIDE, Valid )
    
    if  Valid then
		Child.Name = 'Pickup Cargo'
		Child.TaskBriefing = "Task: Fly to the indicated landing zones and pickup " .. CargoType.TEXT .. ". Your co-pilot will provide you with the directions (required flight angle in degrees) and the distance (in km) to the pickup zone."
		if type( LandingZones ) == "table" then
			Child.LandingZones = LandingZones
		else
			Child.LandingZones = { LandingZones }
		end
		Child.CargoType = CargoType
		Child.GoalVerb = CargoType.TEXT .. " " .. Child.GoalVerb
		Child.OnBoardSide = OnBoardSide
		Child.Stages = { STAGEBRIEF:New(), STAGESTART:New(), STAGEROUTE:New(), STAGELANDING:New(), STAGELANDED:New(), STAGELOAD:New(), STAGEDONE:New() }
		Child.SetStage( Child, 1 )

	end
  
  return Child
end

function PICKUPTASK:AddCargoMenus( Client, Cargos, TransportRadius )
trace.f(self.ClassName, { Client, Cargos, TransportRadius } )
  
	for CargoID, CargoData in pairs( Cargos ) do

		if CargoData.Status ~= CARGOSTATUS.LOADED and CargoData.Status ~= CARGOSTATUS.LOADING then
		
			if Group.getByName( CargoData.CargoGroupName ) then
			
				if Group.getByName( CargoData.CargoGroupName ):getSize() >= 1 then
			
					if Client._Menus[CargoData.CargoType] == nil then
						Client._Menus[CargoData.CargoType] = {}
					end
					
					if not Client._Menus[CargoData.CargoType].PickupMenu then
						Client._Menus[CargoData.CargoType].PickupMenu = missionCommands.addSubMenuForGroup(
							Client:ClientGroup():getID(), 
							self.TEXT[1], 
							nil
						)
						trace.i( self.ClassName, 'Added PickupMenu' .. self.TEXT[1] )
					end

					if Client._Menus[CargoData.CargoType].PickupSubMenus == nil then
						Client._Menus[CargoData.CargoType].PickupSubMenus = {}
					end
					
					local MenuAdd = false
					if CargoData.CargoType.TRANSPORT == CARGO_TRANSPORT.UNIT then
						CargoGroup = Group.getByName( CargoData.CargoGroupName )
						if routines.IsPartOfGroupInRadius( CargoGroup, Client:ClientGroup(), TransportRadius ) then
							MenuAdd = true
						end
					else
						MenuAdd = true
					end
					
					if MenuAdd then
						Client._Menus[CargoData.CargoType].PickupSubMenus[ #Client._Menus[CargoData.CargoType].PickupSubMenus + 1 ] = missionCommands.addCommandForGroup(
							Client:ClientGroup():getID(), 
							CargoData.CargoName .. " ( " .. CargoData.CargoWeight .. "kg )",
							Client._Menus[CargoData.CargoType].PickupMenu, 
							self.MenuAction,
							{ ReferenceTask = self, CargoName = CargoData.CargoName }
						)
						trace.i( self.ClassName, 'Added PickupSubMenu' .. CargoData.CargoType.TEXT .. ":" .. CargoData.CargoName .. " ( " .. CargoData.CargoWeight .. "kg )" )
					end
				end
			end
		end
	end
	
end

function PICKUPTASK:RemoveCargoMenus( Client )
trace.f(self.ClassName, { Client } )

	for MenuID, MenuData in pairs( Client._Menus ) do
		for SubMenuID, SubMenuData in pairs( MenuData.PickupSubMenus ) do
			missionCommands.removeItemForGroup( Client:ClientGroup():getID(), SubMenuData )
			trace.i( self.ClassName, "Removed PickupSubMenu " )
			SubMenuData = nil
		end
		if MenuData.PickupMenu then
			missionCommands.removeItemForGroup( Client:ClientGroup():getID(), MenuData.PickupMenu )
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

function PICKUPTASK:OnBoardCargo( ClientGroup, Cargos )
trace.f(self.ClassName, { ClientGroup, Cargos } )
  
  local Valid = true
  
  Valid = routines.ValidateGroup( ClientGroup, "ClientGroup", Valid )
  
  if Valid then

		local CarrierPos = ClientGroup:getUnits()[1]:getPoint()
		local CarrierPosMove = ClientGroup:getUnits()[1]:getPoint()
		local CarrierPosOnBoard = ClientGroup:getUnits()[1]:getPoint()
		
		local CargoGroup = Group.getByName( Cargos[ self.CargoName ].CargoGroupName )
		trigger.action.activateGroup( CargoGroup )
		trigger.action.setGroupAIOn( CargoGroup )

		local CargoUnits = CargoGroup:getUnits()
		local CargoPos = CargoUnits[1]:getPoint()

		
		local Points = {}
		
		trace.i( self.ClassName, 'CargoPos x = ' .. CargoPos.x .. " z = " .. CargoPos.z )
		trace.i( self.ClassName, 'CarrierPosMove x = ' .. CarrierPosMove.x .. " z = " .. CarrierPosMove.z )
		
		Points[#Points+1] = routines.ground.buildWP( CargoPos, "off road", 6 )

		trace.i( self.ClassName, 'Points[1] x = ' .. Points[1].x .. " y = " .. Points[1].y )
		
		if self.OnBoardSide == nil then
			self.OnBoardSide = CLIENT.ONBOARDSIDE.NONE
		end
		
		if    self.OnBoardSide == CLIENT.ONBOARDSIDE.LEFT then
			trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding LEFT" )
			CarrierPosMove.z = CarrierPosMove.z - 50
			CarrierPosOnBoard.z = CarrierPosOnBoard.z - 5
			Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "diamond", 6 )
			Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "diamond", 6 )
		elseif  self.OnBoardSide == CLIENT.ONBOARDSIDE.RIGHT then
			trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding RIGHT" )
			CarrierPosMove.z = CarrierPosMove.z + 50
			CarrierPosOnBoard.z = CarrierPosOnBoard.z + 5
			Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "diamond", 6 )
			Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "diamond", 6 )
		elseif  self.OnBoardSide == CLIENT.ONBOARDSIDE.BACK then
			trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding BACK" )
			CarrierPosMove.x = CarrierPosMove.x - 50
			CarrierPosOnBoard.x = CarrierPosOnBoard.x - 5
			Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "diamond", 6 )
			Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "diamond", 6 )
		elseif  self.OnBoardSide == CLIENT.ONBOARDSIDE.FRONT then
			trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding FRONT" )
			CarrierPosMove.x = CarrierPosMove.x + 50
			CarrierPosOnBoard.x = CarrierPosOnBoard.x + 5
			Points[#Points+1] = routines.ground.buildWP( CarrierPosMove, "diamond", 6 )
			Points[#Points+1] = routines.ground.buildWP( CarrierPosOnBoard, "diamond", 6 )
		elseif  self.OnBoardSide == CLIENT.ONBOARDSIDE.NONE then
			trace.i( self.ClassName, "TransportCargoOnBoard: Onboarding CENTRAL" )
			Points[#Points+1] = routines.ground.buildWP( CarrierPos, "diamond", 6 )
		end
		trace.i( self.ClassName, "TransportCargoOnBoard: Routing " .. Cargos[ self.CargoName ].CargoGroupName )

		trace.i( self.ClassName, 'Points[2] x = ' .. Points[2].x .. " y = " .. Points[2].y )
		trace.i( self.ClassName, 'Points[3] x = ' .. Points[3].x .. " y = " .. Points[3].y )

		routines.scheduleFunction(routines.goRoute, {Cargos[ self.CargoName ].CargoGroupName, Points}, timer.getTime() + 8)
		--routines.goRoute( Cargos[ self.CargoName ].CargoGroupName, Points )     
  end  
  
  return Valid
  
end
