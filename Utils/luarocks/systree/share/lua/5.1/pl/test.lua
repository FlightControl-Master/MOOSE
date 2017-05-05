--- Useful test utilities.
-- @module pl.test

local tablex = require 'pl.tablex'
local utils = require 'pl.utils'
local pretty = require 'pl.pretty'
local path = require 'pl.path'
local print,type = print,type
local clock = os.clock
local debug = require 'debug'
local io,debug = io,debug

local function dump(x)
    if type(x) == 'table' and not (getmetatable(x) and getmetatable(x).__tostring) then
        return pretty.write(x,' ',true)
    else
        return tostring(x)
    end
end

local test = {}

local function complain (x,y,msg)
    local i = debug.getinfo(3)
    local err = io.stderr
    err:write(path.basename(i.short_src)..':'..i.currentline..': assertion failed\n')
    err:write("got:\t",dump(x),'\n')
    err:write("needed:\t",dump(y),'\n')
    utils.quit(1,msg or "these values were not equal")
end

--- like assert, except takes two arguments that must be equal and can be tables.
-- If they are plain tables, it will use tablex.deepcompare.
-- @param x any value
-- @param y a value equal to x
-- @param eps an optional tolerance for numerical comparisons
function test.asserteq (x,y,eps)
    local res = x == y
    if not res then
        res = tablex.deepcompare(x,y,true,eps)
    end
    if not res then
        complain(x,y)
    end
end

--- assert that the first string matches the second.
-- @param s1 a string
-- @param s2 a string
function test.assertmatch (s1,s2)
    if not s1:match(s2) then
        complain (s1,s2,"these strings did not match")
    end
end

function test.assertraise(fn,e)
    local ok, err = pcall(unpack(fn))
    if not err or err:match(e)==nil then
        complain (err,e,"these errors did not match")
    end
end

--- a version of asserteq that takes two pairs of values.
-- <code>x1==y1 and x2==y2</code> must be true. Useful for functions that naturally
-- return two values.
-- @param x1 any value
-- @param x2 any value
-- @param y1 any value
-- @param y2 any value
function test.asserteq2 (x1,x2,y1,y2)
    if x1 ~= y1 then complain(x1,y1) end
    if x2 ~= y2 then complain(x2,y2) end
end

-- tuple type --

local tuple_mt = {}

function tuple_mt.__tostring(self)
    local ts = {}
    for i=1, self.n do
        local s = self[i]
        ts[i] = type(s) == 'string' and string.format('%q', s) or tostring(s)
    end
    return 'tuple(' .. table.concat(ts, ', ') .. ')'
end

function tuple_mt.__eq(a, b)
    if a.n ~= b.n then return false end
    for i=1, a.n do
        if a[i] ~= b[i] then return false end
    end
    return true
end

--- encode an arbitrary argument list as a tuple.
-- This can be used to compare to other argument lists, which is
-- very useful for testing functions which return a number of values.
-- @usage asserteq(tuple( ('ab'):find 'a'), tuple(1,1))
function test.tuple(...)
    return setmetatable({n=select('#', ...), ...}, tuple_mt)
end

--- Time a function. Call the function a given number of times, and report the number of seconds taken,
-- together with a message.  Any extra arguments will be passed to the function.
-- @param msg a descriptive message
-- @param n number of times to call the function
-- @param fun the function
-- @param ... optional arguments to fun
function test.timer(msg,n,fun,...)
    local start = clock()
    for i = 1,n do fun(...) end
    utils.printf("%s: took %7.2f sec\n",msg,clock()-start)
end

return test
