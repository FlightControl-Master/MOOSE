--- A Map class.
-- @class module
-- @name pl.Map

--[[
module ('pl.Map')
]]
local tablex = require 'pl.tablex'
local utils = require 'pl.utils'
local stdmt = utils.stdmt
local is_callable = utils.is_callable
local tmakeset,deepcompare,merge,keys,difference,tupdate = tablex.makeset,tablex.deepcompare,tablex.merge,tablex.keys,tablex.difference,tablex.update

local pretty_write = require 'pl.pretty' . write
local Map = stdmt.Map
local Set = stdmt.Set
local List = stdmt.List

local class = require 'pl.class'
 
-- the Map class ---------------------
class(nil,nil,Map)

local function makemap (m)
    return setmetatable(m,Map)
end

function Map:_init (t)
    local mt = getmetatable(t)
    if mt == Set or mt == Map then
        self:update(t)
    else
        return t -- otherwise assumed to be a map-like table
    end
end


local function makelist(t)
    return setmetatable(t,List)
end

--- list of keys.
Map.keys = tablex.keys

--- list of values.
Map.values = tablex.values

--- return an iterator over all key-value pairs.
function Map:iter ()
    return pairs(self)
end

--- return a List of all key-value pairs, sorted by the keys.
function Map:items()
    local ls = makelist(tablex.pairmap (function (k,v) return makelist {k,v} end, self))
	ls:sort(function(t1,t2) return t1[1] < t2[1] end)
	return ls
end

-- Will return the existing value, or if it doesn't exist it will set
-- a default value and return it.
function Map:setdefault(key, defaultval)
   return self[key] or self:set(key,defaultval) or defaultval
end

--- size of map.
-- note: this is a relatively expensive operation!
-- @class function
-- @name Map:len
Map.len = tablex.size

--- put a value into the map.
-- @param key the key
-- @param val the value
function Map:set (key,val)
    self[key] = val
end

--- get a value from the map.
-- @param key the key
-- @return the value, or nil if not found.
function Map:get (key)
    return rawget(self,key)
end

local index_by = tablex.index_by

-- get a list of values indexed by a list of keys.
-- @param keys a list-like table of keys
-- @return a new list
function Map:getvalues (keys)
    return makelist(index_by(self,keys))
end

Map.iter = pairs

Map.update = tablex.update

function Map:__eq (m)
    -- note we explicitly ask deepcompare _not_ to use __eq!
    return deepcompare(self,m,true)
end

function Map:__tostring ()
    return pretty_write(self,'')
end

return Map
