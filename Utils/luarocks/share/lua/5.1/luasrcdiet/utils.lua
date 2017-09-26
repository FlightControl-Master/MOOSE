---------
-- General utility functions.
--
-- **Note: This module is not part of public API!**
----
local ipairs = ipairs
local pairs = pairs

local M = {}

--- Returns a new table containing the contents of all the given tables.
-- Tables are iterated using @{pairs}, so this function is intended for tables
-- that represent *associative arrays*. Entries with duplicate keys are
-- overwritten with the values from a later table.
--
-- @tparam {table,...} ... The tables to merge.
-- @treturn table A new table.
function M.merge (...)
  local result = {}

  for _, tab in ipairs{...} do
    for key, val in pairs(tab) do
      result[key] = val
    end
  end

  return result
end

return M
