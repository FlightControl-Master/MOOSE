local machine = {}
machine.__index = machine

--- This module contains the STATEMACHINE class.
-- 
-- ===
-- 
-- 1) @{Workflow#STATEMACHINE} class, extends @{Base#BASE}
-- ==============================================
-- 
-- 1.1) Add or remove objects from the STATEMACHINE
-- --------------------------------------------
-- @module StateMachine
-- @author FlightControl


--- STATEMACHINE class
-- @type STATEMACHINE
STATEMACHINE = {
  ClassName = "STATEMACHINE",
}

--- Creates a new STATEMACHINE object.
-- @param #STATEMACHINE self
-- @return #STATEMACHINE
function STATEMACHINE:New(options)

  local self = routines.utils.deepCopy( self ) -- Create a new self instance

  assert(options.events)

  local FiniteStateMachine = {}
  setmetatable( FiniteStateMachine, self )
  self.__index = self

  FiniteStateMachine.options = options
  FiniteStateMachine.current = options.initial or 'none'
  FiniteStateMachine.events = {}

  for _, event in ipairs(options.events or {}) do
    local name = event.name
    FiniteStateMachine[name] = FiniteStateMachine[name] or self:create_transition(name)
    FiniteStateMachine.events[name] = FiniteStateMachine.events[name] or { map = {} }
    self:add_to_map(FiniteStateMachine.events[name].map, event)
  end
  
  for name, callback in pairs(options.callbacks or {}) do
    FiniteStateMachine[name] = callback
  end

  return FiniteStateMachine
end


function STATEMACHINE:call_handler(handler, params)
  if handler then
    return handler(unpack(params))
  end
end

function STATEMACHINE:create_transition(name)
  return function(self, ...)
    local can, to = self:can(name)

    if can then
      local from = self.current
      local params = { self, name, from, to, ... }

      if self:call_handler(self["onbefore" .. name], params) == false
      or self:call_handler(self["onleave" .. from], params) == false then
        return false
      end

      self.current = to

      self:call_handler(self["onenter" .. to] or self["on" .. to], params)
      self:call_handler(self["onafter" .. name] or self["on" .. name], params)
      self:call_handler(self["onstatechange"], params)

      return true
    end

    return false
  end
end

function STATEMACHINE:add_to_map(map, event)
  if type(event.from) == 'string' then
    map[event.from] = event.to
  else
    for _, from in ipairs(event.from) do
      map[from] = event.to
    end
  end
end

function STATEMACHINE:is(state)
  return self.current == state
end

function STATEMACHINE:can(e)
  local event = self.events[e]
  local to = event and event.map[self.current] or event.map['*']
  return to ~= nil, to
end

function STATEMACHINE:cannot(e)
  return not self:can(e)
end

function STATEMACHINE:todot(filename)
  local dotfile = io.open(filename,'w')
  dotfile:write('digraph {\n')
  local transition = function(event,from,to)
    dotfile:write(string.format('%s -> %s [label=%s];\n',from,to,event))
  end
  for _, event in pairs(self.options.events) do
    if type(event.from) == 'table' then
      for _, from in ipairs(event.from) do
        transition(event.name,from,event.to)
      end
    else
      transition(event.name,event.from,event.to)
    end
  end
  dotfile:write('}\n')
  dotfile:close()
end
