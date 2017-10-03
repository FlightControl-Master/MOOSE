---------
-- LuaSrcDiet API
----
local equiv = require 'luasrcdiet.equiv'
local llex = require 'luasrcdiet.llex'
local lparser = require 'luasrcdiet.lparser'
local optlex = require 'luasrcdiet.optlex'
local optparser = require 'luasrcdiet.optparser'
local utils = require 'luasrcdiet.utils'

local concat = table.concat
local merge = utils.merge

local _  -- placeholder


local function noop ()
  return
end

local function opts_to_legacy (opts)
  local res = {}
  for key, val in pairs(opts) do
    res['opt-'..key] = val
  end
  return res
end


local M = {}

--- The module's name.
M._NAME = 'luasrcdiet'

--- The module's version number.
M._VERSION = '0.3.0'

--- The module's homepage.
M._HOMEPAGE = 'https://github.com/jirutka/luasrcdiet'

--- All optimizations disabled.
M.NONE_OPTS = {
  binequiv = false,
  comments = false,
  emptylines = false,
  entropy = false,
  eols = false,
  experimental = false,
  locals = false,
  numbers = false,
  srcequiv = false,
  strings = false,
  whitespace = false,
}

--- Basic optimizations enabled.
-- @table BASIC_OPTS
M.BASIC_OPTS = merge(M.NONE_OPTS, {
  comments = true,
  emptylines = true,
  srcequiv = true,
  whitespace = true,
})

--- Defaults.
-- @table DEFAULT_OPTS
M.DEFAULT_OPTS = merge(M.BASIC_OPTS, {
  locals = true,
  numbers = true,
})

--- Maximum optimizations enabled (all except experimental).
-- @table MAXIMUM_OPTS
M.MAXIMUM_OPTS = merge(M.DEFAULT_OPTS, {
  entropy = true,
  eols = true,
  strings = true,
})

--- Optimizes the given Lua source code.
--
-- @tparam ?{[string]=bool,...} opts Optimizations to do (default is @{DEFAULT_OPTS}).
-- @tparam string source The Lua source code to optimize.
-- @treturn string Optimized source.
-- @raise if the source is malformed, source equivalence test failed, or some
--   other error occured.
function M.optimize (opts, source)
  assert(source and type(source) == 'string',
         'bad argument #2: expected string, got a '..type(source))

  opts = opts and merge(M.NONE_OPTS, opts) or M.DEFAULT_OPTS
  local legacy_opts = opts_to_legacy(opts)

  local toklist, seminfolist, toklnlist = llex.lex(source)
  local xinfo = lparser.parse(toklist, seminfolist, toklnlist)

  optparser.print = noop
  optparser.optimize(legacy_opts, toklist, seminfolist, xinfo)

  local warn = optlex.warn  -- use this as a general warning lookup
  optlex.print = noop
  _, seminfolist = optlex.optimize(legacy_opts, toklist, seminfolist, toklnlist)
  local optim_source = concat(seminfolist)

  if opts.srcequiv and not opts.experimental then
    equiv.init(legacy_opts, llex, warn)
    equiv.source(source, optim_source)

    if warn.SRC_EQUIV then
      error('Source equivalence test failed!')
    end
  end

  return optim_source
end

return M
