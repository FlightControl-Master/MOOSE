--- Tracing functions...
-- @module trace
-- @author Flightcontrol

trace = {}
trace.names = {}
trace.scheduledfunction = ""

trace.names.all = true
trace.names.New = false
trace.names.Inherit = false
trace.names.do_scheduled_functions = false 
trace.names.main = false 
trace.names.Meta = false 
trace.names.mistdisplayV3 = false 
trace.names.f = false 
trace.names.Spawn = false
trace.names.SpawnTrack = false
trace.names.SpawnGroupAdd = false
trace.names.SpawnInfantry = false
trace.names.SpawnPrepare = false
trace.names.SpawnInit = false
trace.names.SpawnInitSchedule = false
trace.names.SpawnFromCarrier = false
trace.names.SpawnGroup = false
trace.names.SpawnMissionGroup = false
trace.names.SpawnScheduled = false
trace.names.SpawnInZone = false
trace.names.Spawn = false
trace.names.ShowCargo = false 
trace.names.AddCargo = true
trace.names.RemoveCargo = false 
trace.names.MenuAction = false
trace.names.DeploySA6TroopsGoal = false
trace.names.AddEvent = false
trace.names.onEvent = false
trace.names.EventShot = false
trace.names.EventDead = false
trace.names.EventFunction = false
trace.names.ShowGoalProgress = false
trace.names.ReportGoalProgress = false
trace.names.ProgressTrigger = false
trace.names.IsGoalReached = false
trace.names.Validate = false
trace.names.Execute = false
trace.names.EnableEvents = false
trace.names.DisableEvents = false
trace.names.IsCompleted = false
trace.names.GetGoalCount = false
trace.names.GetGoalTotal = false
trace.names.SetGoalTotal = false
trace.names.GetGoalPercentage = false
trace.names.deepCopy = false
trace.names._Scheduler = false
trace.names._GetTemplate = false
trace.names.FollowPlayers = false
trace.names.AddPlayerFromUnit = false
trace.names.FromCarrier = false
trace.cache = {}

trace.tracefunction = function( functionname )

	if functionname then
		if trace.names[functionname] then
			return true
		else
			return false
		end
	else
		return false
	end

end

trace.f = function(object, parameters)

	local info = debug.getinfo( 2, "nl" )
	if trace.names.all or trace.tracefunction( info.name ) then

		local objecttrace = ""
		if object then
			objecttrace = object
		end
		trace.nametrace = ""
		if info.name then
			trace.nametrace = info.name
		end
		local parameterstrace = "()"
		if parameters then
			parameterstrace = "( " .. routines.utils.oneLineSerialize( parameters ) .. " )"
		end
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "F", objecttrace, "function " .. trace.nametrace .. parameterstrace ) )
	end

end

trace.scheduled = function(object, func, parameters)

	local info = debug.getinfo( 2, "l" )
	if trace.names.all or trace.tracefunction( func ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		trace.nametrace = ""
		if func then
			trace.nametrace = func
		end
		trace.scheduledfunction = trace.nametrace
		local parameterstrace = "()"
		if parameters then
			parameterstrace = "( " .. routines.utils.oneLineSerialize( parameters ) .. " )"
		end
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "S", objecttrace, "function " .. trace.nametrace .. parameterstrace ) )
	end

end

trace.s = function(object, parameters)

	local info = debug.getinfo( 3, "nl" )
	if trace.names.all or trace.tracefunction( info.name ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		trace.nametrace = ""
		if info.name then
			trace.nametrace = info.name
		end
		trace.scheduledfunction = trace.nametrace
		local parameterstrace = "()"
		if parameters then
			parameterstrace = "( " .. routines.utils.oneLineSerialize( parameters ) .. " )"
		end
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "S", objecttrace, "scheduled " .. trace.nametrace .. parameterstrace ) )
	end

end

trace.si = function(object, variable)

	local info = debug.getinfo( 3, "nl" )
	if info.name ~= trace.nametrace then
		trace.nametrace = info.name
	end
	if trace.names.all or trace.tracefunction( trace.nametrace ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		local variabletrace = ""
		if variable then
			variabletrace = "( " .. routines.utils.oneLineSerialize( variable ) .. " )"
		end
		
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "S", objecttrace, trace.nametrace .. variabletrace) )
	end

end


trace.l = function(object, func, variable)

	local info = debug.getinfo( 2, "l" )
	if trace.names.all or trace.tracefunction( func ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		trace.nametrace = ""
		if func then
			trace.nametrace = func
		end
		local variabletrace = ""
		if variable then
			variabletrace = "( " .. routines.utils.oneLineSerialize( variable ) .. " )"
		end
		
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "L", objecttrace, trace.nametrace .. variabletrace) )
	end

end

trace.menu = function(object, func)

	if trace.names.all then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		trace.nametrace = ""
		if func then
			trace.nametrace = func
		end
		env.info( string.format( "%6d/%1s:%20s.%s" , 0, "M", objecttrace, trace.nametrace .. "()" ) )
	end

end

trace.r = function(object, step, variable)

	local info = debug.getinfo( 2, "nl" )
	if info.name ~= trace.nametrace then
		trace.nametrace = info.name
	end
	if trace.names.all or trace.tracefunction( trace.nametrace ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		local steptrace = ""
		if step then
			steptrace = "< " .. step .. " >"
		end
		local variabletrace = ""
		if variable then
			variabletrace = "( " .. routines.utils.oneLineSerialize( variable ) .. " )"
		end
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "R", objecttrace, "return " .. trace.nametrace .. variabletrace ) )
	end

end

trace.e = function(object)

	local info = debug.getinfo( 2, "nl" )
	if info.name ~= trace.nametrace then
		trace.nametrace = info.name
	end
	if trace.names.all or trace.tracefunction( trace.nametrace ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "E", objecttrace, "end " .. trace.nametrace ) )
	end

end

trace.i = function(object, variable)

	local info = debug.getinfo( 2, "nl" )
	if info.name ~= trace.nametrace then
		trace.nametrace = info.name
	end
	if trace.names.all or trace.tracefunction( trace.nametrace ) then
		local objecttrace = ""
		if object then
			objecttrace = object
		end
		local variabletrace = ""
		if variable then
			variabletrace = "( " .. routines.utils.oneLineSerialize( variable ) .. " )"
		end
		
		env.info( string.format( "%6d/%1s:%20s.%s" , info.currentline, "I", objecttrace, trace.nametrace .. variabletrace) )
	end

end
