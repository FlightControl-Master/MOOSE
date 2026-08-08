--- Minimal JSON helper for the MOOSE Bridge V1 prototype.
-- This is deliberately small and covers the V1 command/ack/heartbeat/snapshot payloads.

MOOSE_BRIDGE_JSON = MOOSE_BRIDGE_JSON or {}
local json = MOOSE_BRIDGE_JSON

local function escape(value)
  value = tostring(value or "")
  value = value:gsub('\\', '\\\\')
  value = value:gsub('"', '\\"')
  value = value:gsub('\n', '\\n')
  value = value:gsub('\r', '\\r')
  value = value:gsub('\t', '\\t')
  return value
end

local function is_array(value)
  if type(value) ~= "table" then
    return false
  end

  local max_index = 0
  local count = 0

  for key, _ in pairs(value) do
    if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
      return false
    end
    if key > max_index then
      max_index = key
    end
    count = count + 1
  end

  return count == max_index
end

local function encode_value(value)
  local t = type(value)

  if value == nil then
    return "null"
  elseif t == "boolean" then
    return value and "true" or "false"
  elseif t == "number" then
    return tostring(value)
  elseif t == "string" then
    return '"' .. escape(value) .. '"'
  elseif t == "table" then
    local parts = {}

    if is_array(value) then
      for index = 1, #value do
        parts[#parts + 1] = encode_value(value[index])
      end
      return "[" .. table.concat(parts, ",") .. "]"
    end

    for k, v in pairs(value) do
      parts[#parts + 1] = '"' .. escape(k) .. '":' .. encode_value(v)
    end
    return "{" .. table.concat(parts, ",") .. "}"
  end

  return '"' .. escape(value) .. '"'
end

function json.encode(value)
  return encode_value(value)
end

local function decode_error(text, index, message)
  error("JSON decode error at byte " .. tostring(index) .. ": " .. message .. " near " .. string.format("%q", text:sub(index, index + 20)))
end

local function skip_ws(text, index)
  while index <= #text do
    local char = text:sub(index, index)
    if char ~= " " and char ~= "\n" and char ~= "\r" and char ~= "\t" then break end
    index = index + 1
  end
  return index
end

local function utf8_char(codepoint)
  if codepoint <= 0x7F then
    return string.char(codepoint)
  elseif codepoint <= 0x7FF then
    return string.char(
      0xC0 + math.floor(codepoint / 0x40),
      0x80 + (codepoint % 0x40)
    )
  elseif codepoint <= 0xFFFF then
    return string.char(
      0xE0 + math.floor(codepoint / 0x1000),
      0x80 + (math.floor(codepoint / 0x40) % 0x40),
      0x80 + (codepoint % 0x40)
    )
  elseif codepoint <= 0x10FFFF then
    return string.char(
      0xF0 + math.floor(codepoint / 0x40000),
      0x80 + (math.floor(codepoint / 0x1000) % 0x40),
      0x80 + (math.floor(codepoint / 0x40) % 0x40),
      0x80 + (codepoint % 0x40)
    )
  end
  return "?"
end

local parse_value

local function parse_string(text, index)
  if text:sub(index, index) ~= '"' then decode_error(text, index, "expected string") end
  index = index + 1
  local parts = {}
  local start = index

  while index <= #text do
    local char = text:sub(index, index)
    if char == '"' then
      parts[#parts + 1] = text:sub(start, index - 1)
      return table.concat(parts), index + 1
    elseif char == "\\" then
      parts[#parts + 1] = text:sub(start, index - 1)
      local escape_char = text:sub(index + 1, index + 1)
      if escape_char == '"' or escape_char == "\\" or escape_char == "/" then
        parts[#parts + 1] = escape_char
        index = index + 2
      elseif escape_char == "b" then
        parts[#parts + 1] = "\b"
        index = index + 2
      elseif escape_char == "f" then
        parts[#parts + 1] = "\f"
        index = index + 2
      elseif escape_char == "n" then
        parts[#parts + 1] = "\n"
        index = index + 2
      elseif escape_char == "r" then
        parts[#parts + 1] = "\r"
        index = index + 2
      elseif escape_char == "t" then
        parts[#parts + 1] = "\t"
        index = index + 2
      elseif escape_char == "u" then
        local hex = text:sub(index + 2, index + 5)
        local codepoint = tonumber(hex, 16)
        if not codepoint then decode_error(text, index, "invalid unicode escape") end
        index = index + 6

        if codepoint >= 0xD800 and codepoint <= 0xDBFF and text:sub(index, index + 1) == "\\u" then
          local low = tonumber(text:sub(index + 2, index + 5), 16)
          if low and low >= 0xDC00 and low <= 0xDFFF then
            codepoint = 0x10000 + ((codepoint - 0xD800) * 0x400) + (low - 0xDC00)
            index = index + 6
          end
        end

        parts[#parts + 1] = utf8_char(codepoint)
      else
        decode_error(text, index, "invalid escape sequence")
      end
      start = index
    else
      index = index + 1
    end
  end

  decode_error(text, index, "unterminated string")
end

local function parse_number(text, index)
  local start = index
  if text:sub(index, index) == "-" then index = index + 1 end
  while text:sub(index, index):match("%d") do index = index + 1 end
  if text:sub(index, index) == "." then
    index = index + 1
    while text:sub(index, index):match("%d") do index = index + 1 end
  end
  local exponent = text:sub(index, index)
  if exponent == "e" or exponent == "E" then
    index = index + 1
    local sign = text:sub(index, index)
    if sign == "+" or sign == "-" then index = index + 1 end
    while text:sub(index, index):match("%d") do index = index + 1 end
  end
  local raw = text:sub(start, index - 1)
  local value = tonumber(raw)
  if value == nil then decode_error(text, start, "invalid number") end
  return value, index
end

local function parse_array(text, index)
  index = skip_ws(text, index + 1)
  local result = {}
  if text:sub(index, index) == "]" then return result, index + 1 end

  while index <= #text do
    local value
    value, index = parse_value(text, index)
    result[#result + 1] = value
    index = skip_ws(text, index)
    local char = text:sub(index, index)
    if char == "]" then return result, index + 1 end
    if char ~= "," then decode_error(text, index, "expected ',' or ']'") end
    index = skip_ws(text, index + 1)
  end

  decode_error(text, index, "unterminated array")
end

local function parse_object(text, index)
  index = skip_ws(text, index + 1)
  local result = {}
  if text:sub(index, index) == "}" then return result, index + 1 end

  while index <= #text do
    local key
    key, index = parse_string(text, index)
    index = skip_ws(text, index)
    if text:sub(index, index) ~= ":" then decode_error(text, index, "expected ':'") end
    index = skip_ws(text, index + 1)
    local value
    value, index = parse_value(text, index)
    result[key] = value
    index = skip_ws(text, index)
    local char = text:sub(index, index)
    if char == "}" then return result, index + 1 end
    if char ~= "," then decode_error(text, index, "expected ',' or '}'") end
    index = skip_ws(text, index + 1)
  end

  decode_error(text, index, "unterminated object")
end

parse_value = function(text, index)
  index = skip_ws(text, index)
  local char = text:sub(index, index)
  if char == '"' then return parse_string(text, index) end
  if char == "{" then return parse_object(text, index) end
  if char == "[" then return parse_array(text, index) end
  if char == "-" or char:match("%d") then return parse_number(text, index) end
  if text:sub(index, index + 3) == "true" then return true, index + 4 end
  if text:sub(index, index + 4) == "false" then return false, index + 5 end
  if text:sub(index, index + 3) == "null" then return nil, index + 4 end
  decode_error(text, index, "unexpected value")
end

function json.decode(text)
  if type(text) ~= "string" then error("JSON decode expects a string") end
  local value, index = parse_value(text, 1)
  index = skip_ws(text, index)
  if index <= #text then decode_error(text, index, "trailing characters") end
  if type(value) ~= "table" then error("JSON command must decode to an object") end
  if type(value.params) ~= "table" then value.params = {} end
  return value
end

return json
