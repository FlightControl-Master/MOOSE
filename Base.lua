--- BASE The base class for all the classes defined within MOOSE.
-- @classmod BASE
-- @author Flightcontrol

Include.File( "Routines" )

BASE = {

  ClassName = "BASE",
  ClassID = 0,
  Events = {}

}

--- The base constructor. This is the top top class of all classed defined within the MOOSE.
-- Any new class needs to be derived from this class for proper inheritance.
-- @treturn BASE
-- @usage
-- function TASK:New()
-- trace.f(self.ClassName)
--
--     local self = BASE:Inherit( self, BASE:New() )
-- 
--     -- assign Task default values during construction
--     self.TaskBriefing = "Task: No Task."
--     self.Time = timer.getTime()
--     self.ExecuteStage = _TransportExecuteStage.NONE
-- 
--     return self
-- end
-- @todo need to investigate if the deepCopy is really needed... Don't think so.

function BASE:New()
	local Child = routines.utils.deepCopy( self )
	local Parent = {}
	setmetatable( Child, Parent )
	Child.__index = Child
	self.ClassID = self.ClassID + 1
	Child.ClassID = self.ClassID
	--Child.AddEvent( Child, S_EVENT_BIRTH, Child.EventBirth )
	return Child
end

--- This is the worker method to inherit from a parent class.
-- @param Child is the Child class that inherits.
-- @param Parent is the Parent class that the Child inherits from.
-- @return Child
function BASE:Inherit( Child, Parent )
	local Child = routines.utils.deepCopy( Child )
	local Parent = routines.utils.deepCopy( Parent )
	if Child ~= nil then
		setmetatable( Child, Parent )
		Child.__index = Child
	end
	Child.ClassName = Child.ClassName .. '.' .. Child.ClassID
	trace.i( Child.ClassName, 'Inherited from ' .. Parent.ClassName ) 
	return Child
end

--- This is the worker method to retrieve the Parent class.
-- @tparam BASE Child is the Child class from which the Parent class needs to be retrieved.
-- @treturn Parent
function BASE:Inherited( Child )
	local Parent = getmetatable( Child )
--	env.info('Inherited class of ' .. Child.ClassName .. ' is ' .. Parent.ClassName )
	return Parent
end

function BASE:AddEvent( Event, EventFunction )
trace.f( self.ClassName, Event )

	self.Events[#self.Events+1] = {}
	self.Events[#self.Events].Event = Event
	self.Events[#self.Events].EventFunction = EventFunction
	self.Events[#self.Events].EventEnabled = false

	return self
end


function BASE:EnableEvents()
trace.f( self.ClassName )

	trace.i( self.ClassName, #self.Events )
	for EventID, Event in pairs( self.Events ) do
		Event.Self = self
		Event.EventEnabled = true
	end
	--env.info( 'EnableEvent Table Task = ' .. tostring(self) )
	self.Events.Handler = world.addEventHandler( self )

	return self
end

function BASE:DisableEvents()
trace.f( self.ClassName )

	world.removeEventHandler( self )
	for EventID, Event in pairs( self.Events ) do
		Event.Self = nil
		Event.EventEnabled = false
	end

	return self
end
												
function BASE:onEvent(event)
trace.f(self.ClassName, event )

	--env.info( 'onEvent Table self = ' .. tostring(self) )
	if self then
		for EventID, EventObject in pairs( self.Events ) do
			if EventObject.EventEnabled then
				--env.info( 'onEvent Table EventObject.Self = ' .. tostring(EventObject.Self) )
				--env.info( 'onEvent event.id = ' .. tostring(event.id) )
				--env.info( 'onEvent EventObject.Event = ' .. tostring(EventObject.Event) )
				if event.id == EventObject.Event then
					if self == EventObject.Self then
						--env.info( 'onEvent Call EventFunction' )
						EventObject.EventFunction( self, event )
					end
				end
			end
		end
	end

end

