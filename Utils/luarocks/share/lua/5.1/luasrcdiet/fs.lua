---------
-- Utility functions for operations on a file system.
--
-- **Note: This module is not part of public API!**
----
local fmt = string.format
local open = io.open

local UTF8_BOM = '\239\187\191'

local function normalize_io_error (name, err)
  if err:sub(1, #name + 2) == name..': ' then
    err = err:sub(#name + 3)
  end
  return err
end

local M = {}

--- Reads the specified file and returns its content as string.
--
-- @tparam string filename Path of the file to read.
-- @tparam string mode The mode in which to open the file, see @{io.open} (default: "r").
-- @treturn[1] string A content of the file.
-- @treturn[2] nil
-- @treturn[2] string An error message.
function M.read_file (filename, mode)
  local handler, err = open(filename, mode or 'r')
  if not handler then
    return nil, fmt('Could not open %s for reading: %s',
                    filename, normalize_io_error(filename, err))
  end

  local content, err = handler:read('*a')  --luacheck: ignore 411
  if not content then
    return nil, fmt('Could not read %s: %s', filename, normalize_io_error(filename, err))
  end

  handler:close()

  if content:sub(1, #UTF8_BOM) == UTF8_BOM then
    content = content:sub(#UTF8_BOM + 1)
  end

  return content
end

--- Writes the given data to the specified file.
--
-- @tparam string filename Path of the file to write.
-- @tparam string data The data to write.
-- @tparam ?string mode The mode in which to open the file, see @{io.open} (default: "w").
-- @treturn[1] true
-- @treturn[2] nil
-- @treturn[2] string An error message.
function M.write_file (filename, data, mode)
  local handler, err = open(filename, mode or 'w')
  if not handler then
    return nil, fmt('Could not open %s for writing: %s',
                    filename, normalize_io_error(filename, err))
  end

  local _, err = handler:write(data)  --luacheck: ignore 411
  if err then
    return nil, fmt('Could not write %s: %s', filename, normalize_io_error(filename, err))
  end

  handler:flush()
  handler:close()

  return true
end

return M
