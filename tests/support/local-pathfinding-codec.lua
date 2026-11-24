-- Test-only deterministic JSON codec. Run helpers from the repository root.
-- Ordinary dense arrays/string-key records stay JSON arrays/objects. Lua-only
-- values and sparse/mixed tables use explicit tags; captured text is never code.
local Codec = {}
local defaults = {MaxBytes = 64 * 1024 * 1024, MaxItems = 1000000, MaxDepth = 64}

local function limits(options)
  if options == nil then
    options = {}
  end
  assert(type(options) == "table" and getmetatable(options) == nil, "P0 codec: expected limit record")
  local result = {}
  for key, value in pairs(defaults) do
    result[key] = value
  end
  for key, value in pairs(options) do
    assert(defaults[key], "P0 codec: unknown limit " .. tostring(key))
    assert(type(value) == "number" and value >= 1 and value < math.huge
      and value == math.floor(value), "P0 codec: invalid " .. key)
    result[key] = value
  end
  return result
end

local function utf8(value)
  local index = 1
  while index <= #value do
    local first = value:byte(index)
    local count = first < 128 and 1 or (first >= 194 and first <= 223 and 2
      or (first >= 224 and first <= 239 and 3 or (first >= 240 and first <= 244 and 4)))
    assert(count and index + count - 1 <= #value, "P0 codec: invalid UTF-8")
    for offset = 1, count - 1 do
      local byte = value:byte(index + offset)
      assert(byte >= 128 and byte <= 191, "P0 codec: invalid UTF-8")
    end
    if count > 2 then
      local second = value:byte(index + 1)
      assert(not (first == 224 and second < 160 or first == 237 and second >= 160
        or first == 240 and second < 144 or first == 244 and second >= 144),
        "P0 codec: invalid UTF-8 code point")
    end
    index = index + count
  end
  return value
end

local escapes = {['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b',
  ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t'}
local function quote(value)
  utf8(value)
  return '"' .. value:gsub('[%z\1-\31\\"]', function(char)
    return escapes[char] or string.format("\\u%04x", char:byte())
  end) .. '"'
end

local ranks = {number = 1, string = 2, boolean = 3}
local function keys(value)
  assert(getmetatable(value) == nil, "P0 codec: metatables are not data")
  local result = {}
  for key in pairs(value) do
    assert(ranks[type(key)] and (type(key) ~= "number" or key == key),
      "P0 codec: unsupported table key")
    result[#result + 1] = key
  end
  table.sort(result, function(a, b)
    if type(a) ~= type(b) then
      return ranks[type(a)] < ranks[type(b)]
    end
    if type(a) == "boolean" then
      return a == false and b == true
    end
    return a < b
  end)
  return result
end

local function number(value)
  local result = string.format("%.17g", value)
  assert(not result:find(",", 1, true) and tonumber(result) == value,
    "P0 codec: locale-dependent or non-round-trip number")
  return result
end

-- Canonical bytes have sorted object keys, typed key order and binary64 numbers.
function Codec.Encode(value, options)
  local cap = limits(options)
  local parts, byteCount, itemCount, active = {}, 0, 0, {}
  local function write(part)
    byteCount = byteCount + #part
    assert(byteCount <= cap.MaxBytes, "P0 codec: byte_limit")
    parts[#parts + 1] = part
  end
  local encode
  encode = function(item, depth)
    itemCount = itemCount + 1
    assert(itemCount <= cap.MaxItems, "P0 codec: item_limit")
    assert(depth <= cap.MaxDepth, "P0 codec: depth_limit")
    local kind = type(item)
    if kind == "nil" then
      write('{"$lua":"nil"}')
    elseif kind == "number" then
      if item ~= item then
        write('{"$lua":"number","value":"nan"}')
      elseif item == math.huge or item == -math.huge then
        write('{"$lua":"number","value":"' .. (item > 0 and "+inf" or "-inf") .. '"}')
      elseif item == 0 and 1 / item == -math.huge then
        write('{"$lua":"number","value":"-zero"}')
      else
        write(number(item))
      end
    elseif kind == "boolean" then
      write(item and "true" or "false")
    elseif kind == "string" then
      write(quote(item))
    else
      assert(kind == "table", "P0 codec: unsupported value " .. kind)
      assert(not active[item], "P0 codec: cyclic data")
      active[item] = true
      local ordered = keys(item)
      local dense, object = #ordered > 0, rawget(item, "$lua") == nil
      for index, key in ipairs(ordered) do
        dense = dense and type(key) == "number" and key == index
        object = object and type(key) == "string"
      end
      if dense then
        write("[")
        for index, key in ipairs(ordered) do
          if index > 1 then
            write(",")
          end
          encode(item[key], depth + 1)
        end
        write("]")
      elseif object then
        write("{")
        for index, key in ipairs(ordered) do
          if index > 1 then
            write(",")
          end
          write(quote(key) .. ":")
          encode(item[key], depth + 1)
        end
        write("}")
      else
        write('{"$lua":"table","entries":[')
        for index, key in ipairs(ordered) do
          if index > 1 then
            write(",")
          end
          write("[")
          encode(key, depth + 1)
          write(",")
          encode(item[key], depth + 1)
          write("]")
        end
        write("]}")
      end
      active[item] = nil
    end
  end
  encode(value, 1)
  return table.concat(parts)
end

local function codepoint(value)
  if value < 128 then
    return string.char(value)
  end
  if value < 2048 then
    return string.char(192 + math.floor(value / 64), 128 + value % 64)
  end
  if value < 65536 then
    return string.char(224 + math.floor(value / 4096),
      128 + math.floor(value / 64) % 64, 128 + value % 64)
  end
  return string.char(240 + math.floor(value / 262144),
    128 + math.floor(value / 4096) % 64, 128 + math.floor(value / 64) % 64, 128 + value % 64)
end

-- Strict decoding rejects duplicate keys, malformed tags and trailing content.
function Codec.Decode(text, options)
  local cap = limits(options)
  assert(type(text) == "string" and #text <= cap.MaxBytes, "P0 codec: byte_limit")
  local index, itemCount = 1, 0
  local function skip()
    local _, last = text:find("^[ \t\r\n]*", index)
    index = (last or index - 1) + 1
  end
  local function consume(char)
    assert(text:sub(index, index) == char, "P0 codec: expected " .. char)
    index = index + 1
  end
  local function hex()
    local value = text:sub(index, index + 3)
    assert(value:match("^%x%x%x%x$"), "P0 codec: invalid Unicode escape")
    index = index + 4
    return tonumber(value, 16)
  end
  local function stringValue()
    consume('"')
    local parts = {}
    while index <= #text do
      local char = text:sub(index, index)
      index = index + 1
      if char == '"' then
        return utf8(table.concat(parts))
      end
      assert(char:byte() >= 32, "P0 codec: unescaped control character")
      if char == "\\" then
        local escape = text:sub(index, index)
        index = index + 1
        local simple = {['"'] = '"', ['\\'] = '\\', ['/'] = '/',
          b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
        if escape == "u" then
          local value = hex()
          if value >= 55296 and value <= 56319 then
            assert(text:sub(index, index + 1) == "\\u", "P0 codec: missing low surrogate")
            index = index + 2
            local low = hex()
            assert(low >= 56320 and low <= 57343, "P0 codec: invalid low surrogate")
            value = 65536 + (value - 55296) * 1024 + low - 56320
          else
            assert(value < 56320 or value > 57343, "P0 codec: unpaired low surrogate")
          end
          parts[#parts + 1] = codepoint(value)
        else
          assert(simple[escape], "P0 codec: invalid escape")
          parts[#parts + 1] = simple[escape]
        end
      else
        parts[#parts + 1] = char
      end
    end
    error("P0 codec: unterminated string")
  end
  local parse
  parse = function(depth)
    itemCount = itemCount + 1
    assert(itemCount <= cap.MaxItems, "P0 codec: item_limit")
    assert(depth <= cap.MaxDepth, "P0 codec: depth_limit")
    skip()
    local char = text:sub(index, index)
    if char == '"' then
      return stringValue()
    end
    if char == "{" or char == "[" then
      local object = char == "{"
      local close = object and "}" or "]"
      index = index + 1
      skip()
      local result, seen, count = {}, {}, 0
      if text:sub(index, index) ~= close then
        while true do
          local key
          if object then
            key = stringValue()
            assert(not seen[key], "P0 codec: duplicate object key")
            seen[key] = true
            skip()
            consume(":")
          else
            key = count + 1
          end
          count = count + 1
          result[key] = parse(depth + 1)
          skip()
          if text:sub(index, index) == close then
            break
          end
          consume(",")
          skip()
        end
      end
      consume(close)
      if object and seen["$lua"] then
        local tag = result["$lua"]
        if tag == "nil" then
          assert(count == 1, "P0 codec: malformed nil tag")
          return nil
        elseif tag == "number" then
          assert(count == 2 and result.value, "P0 codec: malformed number tag")
          if result.value == "nan" then
            return 0 / 0
          end
          if result.value == "+inf" then
            return math.huge
          end
          if result.value == "-inf" then
            return -math.huge
          end
          if result.value == "-zero" then
            return -1 / math.huge
          end
          error("P0 codec: unknown number tag")
        elseif tag == "table" then
          assert(count == 2 and type(result.entries) == "table", "P0 codec: malformed table tag")
          local entryKeys = keys(result.entries)
          for ordinal, key in ipairs(entryKeys) do
            assert(key == ordinal, "P0 codec: malformed table entries")
          end
          local decoded, decodedKeys = {}, {}
          for _, entry in ipairs(result.entries) do
            assert(type(entry) == "table" and entry[1] ~= nil
              and ranks[type(entry[1])] and (type(entry[1]) ~= "number" or entry[1] == entry[1])
              and entry[2] ~= nil and #keys(entry) == 2, "P0 codec: malformed table entry")
            assert(not decodedKeys[entry[1]], "P0 codec: duplicate table key")
            decodedKeys[entry[1]] = true
            decoded[entry[1]] = entry[2]
          end
          return decoded
        end
        error("P0 codec: unknown Lua tag")
      end
      return result
    end
    if text:sub(index, index + 3) == "true" then
      index = index + 4
      return true
    end
    if text:sub(index, index + 4) == "false" then
      index = index + 5
      return false
    end
    local token = text:match("^%-?%d+%.?%d*[eE][%+%-]?%d+", index)
      or text:match("^%-?%d+%.%d+", index) or text:match("^%-?%d+", index)
    assert(token and not token:match("^%-?0%d") and not token:match("%.[eE]"),
      "P0 codec: invalid JSON value")
    local value = tonumber(token)
    assert(value and math.abs(value) < math.huge, "P0 codec: non-finite JSON number")
    index = index + #token
    return value
  end
  local result = parse(1)
  skip()
  assert(index == #text + 1, "P0 codec: trailing content")
  return result
end

function Codec.Copy(value)
  return Codec.Decode(Codec.Encode(value))
end

-- Resource limits are expected capture outcomes. Other errors still propagate.
function Codec.TryEncode(value, options)
  local ok, result = pcall(Codec.Encode, value, options)
  if ok then
    return result
  end
  if type(result) == "string" then
    for _, reason in ipairs({"byte_limit", "item_limit", "depth_limit"}) do
      if result:sub(-#("P0 codec: " .. reason)) == "P0 codec: " .. reason then
        return nil, reason
      end
    end
  end
  error(result, 0)
end

function Codec.Pack(...)
  local result = {Arity = select("#", ...), Values = {}}
  for index = 1, result.Arity do
    result.Values[index] = select(index, ...)
  end
  return result
end

-- Report the first exact difference in deterministic typed-key order.
function Codec.Compare(first, second)
  -- Validate bounded plain graphs before recursive comparison, including cycles.
  Codec.Encode(first)
  Codec.Encode(second)
  local function compare(a, b, path)
    if type(a) ~= type(b) then
      return {Path = path, First = a, Second = b}
    end
    if type(a) ~= "table" then
      local signedZeroDiffers = type(a) == "number" and a == 0 and b == 0 and 1 / a ~= 1 / b
      if signedZeroDiffers or (a ~= b and not (type(a) == "number" and a ~= a and b ~= b)) then
        return {Path = path, First = a, Second = b}
      end
      return
    end
    local union = {}
    for _, key in ipairs(keys(a)) do
      union[key] = true
    end
    for _, key in ipairs(keys(b)) do
      union[key] = true
    end
    for _, key in ipairs(keys(union)) do
      local suffix = type(key) == "string" and key:match("^[%a_][%w_]*$")
        and "." .. key or "[" .. Codec.Encode(key) .. "]"
      local difference = compare(rawget(a, key), rawget(b, key), path .. suffix)
      if difference then
        return difference
      end
    end
  end
  local difference = compare(first, second, "$")
  return {Verdict = difference and "failed" or "passed", Difference = difference}
end

return Codec
