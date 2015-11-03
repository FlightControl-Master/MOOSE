--- CLEANUP Classes
-- @classmod CLEANUP
-- @author Flightcontrol

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Mission" )
Include.File( "Client" )
Include.File( "Task" )

CLEANUP = {
	ClassName = "CLEANUP",
	ZoneNames = {},
	TimeInterval = 300,
	CleanUpList = {},
}

--- Creates the main object which is handling the cleaning of the debris within the given Zone Names.
-- @tparam table{string,...}|string ZoneNames which is a table of zone names where the debris should be cleaned. Also a single string can be passed with one zone name.
-- @tparam ?number TimeInterval is the interval in seconds when the clean activity takes place. The default is 300 seconds, thus every 5 minutes.
-- @treturn CLEANUP
-- @usage
-- -- Clean these Zones.
-- CleanUpAirports = CLEANUP:New( { 'CLEAN Tbilisi', 'CLEAN Kutaisi' }, 150 )
-- or
-- CleanUpTbilisi = CLEANUP:New( 'CLEAN Tbilisi', 150 )
-- CleanUpKutaisi = CLEANUP:New( 'CLEAN Kutaisi', 600 )
function CLEANUP:New( ZoneNames, TimeInterval )
trace.f( self.ClassName, { ZoneNames, TimeInterval } )

	-- Arrange meta tables
	local self = BASE:Inherit( self, BASE:New() )
	if type( ZoneNames ) == 'table' then
		self.ZoneNames = ZoneNames
	else
		self.ZoneNames = { ZoneNames }
	end
	if TimeInterval then
		self.TimeInterval = TimeInterval
	end
	
	self:AddEvent( world.event.S_EVENT_ENGINE_SHUTDOWN, self._EventAddForCleanUp )
	self:AddEvent( world.event.S_EVENT_HIT, self._EventAddForCleanUp )
	self:AddEvent( world.event.S_EVENT_DEAD, self._EventAddForCleanUp )
	self:EnableEvents()

	self.CleanUpFunction = routines.scheduleFunction( self._Scheduler, { self }, timer.getTime() + 1, TimeInterval )
	
	return self
end

--- Detects if the Unit has an S_EVENT_ENGINE_SHUTDOWN or an S_EVENT_HIT within the given ZoneNames. If this is the case, add the Group to the CLEANUP List.
function CLEANUP:_EventAddForCleanUp( event )
trace.f( self.ClassName, { event } )

	if event.initiator and Object.getCategory(event.initiator) == Object.Category.UNIT then
		local CleanUpUnit = event.initiator -- the Unit
		local CleanUpUnitName = event.initiator:getName() -- return the name of the Unit
		local CleanUpGroup = Unit.getGroup(event.initiator)-- Identify the Group 
		local CleanUpGroupName = CleanUpGroup:getName() -- return the name of the Group
		if not self.CleanUpList[CleanUpGroupName] then
			local AddForCleanUp = false
			if routines.IsUnitInZones( CleanUpUnit, self.ZoneNames ) ~= nil then
				AddForCleanUp = true
				env.info( "CleanUp:" .. CleanUpGroupName .. "/" .. CleanUpUnitName )
			end
			if AddForCleanUp == true then
				self.CleanUpList[CleanUpGroupName] = CleanUpUnitName
			end
		end
	end

	if event.target and Object.getCategory(event.target) == Object.Category.UNIT then

		local CleanUpTgtUnit = event.target -- the target Unit
		if CleanUpTgtUnit then
			local CleanUpTgtUnitName = event.target:getName() -- return the name of the target Unit
			local CleanUpTgtGroup = Unit.getGroup(event.target)-- Identify the target Group 
			local CleanUpTgtGroupName = CleanUpTgtGroup:getName() -- return the name of the target Group
			if not self.CleanUpList[CleanUpTgtGroupName] then
				local AddForCleanUp = false
				if routines.IsUnitInZones( CleanUpTgtUnit, self.ZoneNames ) ~= nil then
					AddForCleanUp = true
					env.info( "CleanUp:" .. CleanUpTgtGroupName .. "/" .. CleanUpTgtUnitName )
				end
				if AddForCleanUp == true then
					self.CleanUpList[CleanUpTgtGroupName] = CleanUpTgtUnitName
				end
			end
		end
	end
	
end

--- At the defined time interval, CleanUp the Groups within the CleanUpList.
function CLEANUP:_Scheduler()

	for GroupName, ListData in pairs( self.CleanUpList ) do
		env.info( "CleanUp: GroupName = " .. GroupName .. " UnitName = " .. ListData )
		local CleanUpGroup = Group.getByName( GroupName )
		local CleanUpUnit = Unit.getByName( ListData )
		if CleanUpUnit and CleanUpGroup then
			env.info( "CleanUp: Check Database" )
			if CleanUpGroup:isExist() and CleanUpUnit:isExist() then
				env.info( "CleanUp: Group Existing" )
				if _Database:GetStatusGroup( GroupName ) ~= "ReSpawn" then
					env.info( "CleanUp: Database OK" )
					local CleanUpUnitVelocity = CleanUpUnit:getVelocity()
					local CleanUpUnitVelocityTotal = math.abs(CleanUpUnitVelocity.x) + math.abs(CleanUpUnitVelocity.y) + math.abs(CleanUpUnitVelocity.z)
					if CleanUpUnitVelocityTotal < 1 then
						env.info( "CleanUp: Destroy: " .. GroupName )
						trigger.action.deactivateGroup(CleanUpGroup)
						ListData = nil
					end
				else
					ListData = nil
				end
			else
				env.info( "CleanUp: Not Existing anymore, cleaning: " .. GroupName )
				Event = {
				  id = 8,
				  time = Time,
				  initiator = CleanUpUnit,
				}
				world.onEvent(Event)
				trigger.action.deactivateGroup(CleanUpGroup)
				ListData = nil
			end
		else
			ListData = nil -- Not anymore in the DCSRTE
		end
	end
end

