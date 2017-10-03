---------
-- This module does parser-based optimizations.
--
-- **Notes:**
--
-- * The processing load is quite significant, but since this is an
--   off-line text processor, I believe we can wait a few seconds.
-- * TODO: Might process "local a,a,a" wrongly... need tests!
-- * TODO: Remove position handling if overlapped locals (rem < 0)
--   needs more study, to check behaviour.
-- * TODO: There are probably better ways to do allocation, e.g. by
--   choosing better methods to sort and pick locals...
-- * TODO: We don't need 53*63 two-letter identifiers; we can make
--   do with significantly less depending on how many that are really
--   needed and improve entropy; e.g. 13 needed -> choose 4*4 instead.
----
local byte = string.byte
local char = string.char
local concat = table.concat
local fmt = string.format
local pairs = pairs
local rep = string.rep
local sort = table.sort
local sub = string.sub


local M = {}

-- Letter frequencies for reducing symbol entropy (fixed version)
-- * Might help a wee bit when the output file is compressed
-- * See Wikipedia: http://en.wikipedia.org/wiki/Letter_frequencies
-- * We use letter frequencies according to a Linotype keyboard, plus
--   the underscore, and both lower case and upper case letters.
-- * The arrangement below (LC, underscore, %d, UC) is arbitrary.
-- * This is certainly not optimal, but is quick-and-dirty and the
--   process has no significant overhead
local LETTERS = "etaoinshrdlucmfwypvbgkqjxz_ETAOINSHRDLUCMFWYPVBGKQJXZ"
local ALPHANUM = "etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"

-- Names or identifiers that must be skipped.
-- (The first two lines are for keywords.)
local SKIP_NAME = {}
for v in ([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while
self _ENV]]):gmatch("%S+") do
  SKIP_NAME[v] = true
end


local toklist, seminfolist,             -- token lists (lexer output)
      tokpar, seminfopar, xrefpar,      -- token lists (parser output)
      globalinfo, localinfo,            -- variable information tables
      statinfo,                         -- statment type table
      globaluniq, localuniq,            -- unique name tables
      var_new,                          -- index of new variable names
      varlist                           -- list of output variables

--- Preprocesses information table to get lists of unique names.
--
-- @tparam {table,...} infotable
-- @treturn table
local function preprocess(infotable)
  local uniqtable = {}
  for i = 1, #infotable do              -- enumerate info table
    local obj = infotable[i]
    local name = obj.name

    if not uniqtable[name] then         -- not found, start an entry
      uniqtable[name] = {
        decl = 0, token = 0, size = 0,
      }
    end

    local uniq = uniqtable[name]        -- count declarations, tokens, size
    uniq.decl = uniq.decl + 1
    local xref = obj.xref
    local xcount = #xref
    uniq.token = uniq.token + xcount
    uniq.size = uniq.size + xcount * #name

    if obj.decl then            -- if local table, create first,last pairs
      obj.id = i
      obj.xcount = xcount
      if xcount > 1 then        -- if ==1, means local never accessed
        obj.first = xref[2]
        obj.last = xref[xcount]
      end

    else                        -- if global table, add a back ref
      uniq.id = i
    end

  end--for
  return uniqtable
end

--- Calculates actual symbol frequencies, in order to reduce entropy.
--
-- * This may help further reduce the size of compressed sources.
-- * Note that since parsing optimizations is put before lexing
--   optimizations, the frequency table is not exact!
-- * Yes, this will miss --keep block comments too...
--
-- @tparam table option
local function recalc_for_entropy(option)
  -- table of token classes to accept in calculating symbol frequency
  local ACCEPT = {
    TK_KEYWORD = true, TK_NAME = true, TK_NUMBER = true,
    TK_STRING = true, TK_LSTRING = true,
  }
  if not option["opt-comments"] then
    ACCEPT.TK_COMMENT = true
    ACCEPT.TK_LCOMMENT = true
  end

  -- Create a new table and remove any original locals by filtering.
  local filtered = {}
  for i = 1, #toklist do
    filtered[i] = seminfolist[i]
  end
  for i = 1, #localinfo do              -- enumerate local info table
    local obj = localinfo[i]
    local xref = obj.xref
    for j = 1, obj.xcount do
      local p = xref[j]
      filtered[p] = ""                  -- remove locals
    end
  end

  local freq = {}                       -- reset symbol frequency table
  for i = 0, 255 do freq[i] = 0 end
  for i = 1, #toklist do                -- gather symbol frequency
    local tok, info = toklist[i], filtered[i]
    if ACCEPT[tok] then
      for j = 1, #info do
        local c = byte(info, j)
        freq[c] = freq[c] + 1
      end
    end--if
  end--for

  -- Re-sorts symbols according to actual frequencies.
  --
  -- @tparam string symbols
  -- @treturn string
  local function resort(symbols)
    local symlist = {}
    for i = 1, #symbols do              -- prepare table to sort
      local c = byte(symbols, i)
      symlist[i] = { c = c, freq = freq[c], }
    end
    sort(symlist, function(v1, v2)  -- sort selected symbols
        return v1.freq > v2.freq
      end)
    local charlist = {}                 -- reconstitute the string
    for i = 1, #symlist do
      charlist[i] = char(symlist[i].c)
    end
    return concat(charlist)
  end

  LETTERS = resort(LETTERS)             -- change letter arrangement
  ALPHANUM = resort(ALPHANUM)
end

--- Returns a string containing a new local variable name to use, and
-- a flag indicating whether it collides with a global variable.
--
-- Trapping keywords and other names like 'self' is done elsewhere.
--
-- @treturn string A new local variable name.
-- @treturn bool Whether the name collides with a global variable.
local function new_var_name()
  local var
  local cletters, calphanum = #LETTERS, #ALPHANUM
  local v = var_new
  if v < cletters then                  -- single char
    v = v + 1
    var = sub(LETTERS, v, v)
  else                                  -- longer names
    local range, sz = cletters, 1       -- calculate # chars fit
    repeat
      v = v - range
      range = range * calphanum
      sz = sz + 1
    until range > v
    local n = v % cletters              -- left side cycles faster
    v = (v - n) / cletters              -- do first char first
    n = n + 1
    var = sub(LETTERS, n, n)
    while sz > 1 do
      local m = v % calphanum
      v = (v - m) / calphanum
      m = m + 1
      var = var..sub(ALPHANUM, m, m)
      sz = sz - 1
    end
  end
  var_new = var_new + 1
  return var, globaluniq[var] ~= nil
end

--- Calculates and prints some statistics.
--
-- Note: probably better in main source, put here for now.
--
-- @tparam table globaluniq
-- @tparam table localuniq
-- @tparam table afteruniq
-- @tparam table option
local function stats_summary(globaluniq, localuniq, afteruniq, option)  --luacheck: ignore 431
  local print = M.print or print
  local opt_details = option.DETAILS
  if option.QUIET then return end

  local uniq_g , uniq_li, uniq_lo = 0, 0, 0
  local decl_g, decl_li, decl_lo = 0, 0, 0
  local token_g, token_li, token_lo = 0, 0, 0
  local size_g, size_li, size_lo = 0, 0, 0

  local function avg(c, l)              -- safe average function
    if c == 0 then return 0 end
    return l / c
  end

  -- Collect statistics (Note: globals do not have declarations!)
  for _, uniq in pairs(globaluniq) do
    uniq_g = uniq_g + 1
    token_g = token_g + uniq.token
    size_g = size_g + uniq.size
  end
  for _, uniq in pairs(localuniq) do
    uniq_li = uniq_li + 1
    decl_li = decl_li + uniq.decl
    token_li = token_li + uniq.token
    size_li = size_li + uniq.size
  end
  for _, uniq in pairs(afteruniq) do
    uniq_lo = uniq_lo + 1
    decl_lo = decl_lo + uniq.decl
    token_lo = token_lo + uniq.token
    size_lo = size_lo + uniq.size
  end
  local uniq_ti = uniq_g + uniq_li
  local decl_ti = decl_g + decl_li
  local token_ti = token_g + token_li
  local size_ti = size_g + size_li
  local uniq_to = uniq_g + uniq_lo
  local decl_to = decl_g + decl_lo
  local token_to = token_g + token_lo
  local size_to = size_g + size_lo

  -- Detailed stats: global list
  if opt_details then
    local sorted = {} -- sort table of unique global names by size
    for name, uniq in pairs(globaluniq) do
      uniq.name = name
      sorted[#sorted + 1] = uniq
    end
    sort(sorted, function(v1, v2)
        return v1.size > v2.size
      end)

    do
      local tabf1, tabf2 = "%8s%8s%10s  %s", "%8d%8d%10.2f  %s"
      local hl = rep("-", 44)
      print("*** global variable list (sorted by size) ***\n"..hl)
      print(fmt(tabf1, "Token",  "Input", "Input", "Global"))
      print(fmt(tabf1, "Count", "Bytes", "Average", "Name"))
      print(hl)
      for i = 1, #sorted do
        local uniq = sorted[i]
        print(fmt(tabf2, uniq.token, uniq.size, avg(uniq.token, uniq.size), uniq.name))
      end
      print(hl)
      print(fmt(tabf2, token_g, size_g, avg(token_g, size_g), "TOTAL"))
      print(hl.."\n")
    end

    -- Detailed stats: local list
    do
      local tabf1, tabf2 = "%8s%8s%8s%10s%8s%10s  %s", "%8d%8d%8d%10.2f%8d%10.2f  %s"
      local hl = rep("-", 70)
      print("*** local variable list (sorted by allocation order) ***\n"..hl)
      print(fmt(tabf1, "Decl.", "Token",  "Input", "Input", "Output", "Output", "Global"))
      print(fmt(tabf1, "Count", "Count", "Bytes", "Average", "Bytes", "Average", "Name"))
      print(hl)
      for i = 1, #varlist do  -- iterate according to order assigned
        local name = varlist[i]
        local uniq = afteruniq[name]
        local old_t, old_s = 0, 0
        for j = 1, #localinfo do  -- find corresponding old names and calculate
          local obj = localinfo[j]
          if obj.name == name then
            old_t = old_t + obj.xcount
            old_s = old_s + obj.xcount * #obj.oldname
          end
        end
        print(fmt(tabf2, uniq.decl, uniq.token, old_s, avg(old_t, old_s),
                  uniq.size, avg(uniq.token, uniq.size), name))
      end
      print(hl)
      print(fmt(tabf2, decl_lo, token_lo, size_li, avg(token_li, size_li),
                size_lo, avg(token_lo, size_lo), "TOTAL"))
      print(hl.."\n")
    end
  end--if opt_details

  -- Display output
  do
    local tabf1, tabf2 = "%-16s%8s%8s%8s%8s%10s", "%-16s%8d%8d%8d%8d%10.2f"
    local hl = rep("-", 58)
    print("*** local variable optimization summary ***\n"..hl)
    print(fmt(tabf1, "Variable",  "Unique", "Decl.", "Token", "Size", "Average"))
    print(fmt(tabf1, "Types", "Names", "Count", "Count", "Bytes", "Bytes"))
    print(hl)
    print(fmt(tabf2, "Global", uniq_g, decl_g, token_g, size_g, avg(token_g, size_g)))
    print(hl)
    print(fmt(tabf2, "Local (in)", uniq_li, decl_li, token_li, size_li, avg(token_li, size_li)))
    print(fmt(tabf2, "TOTAL (in)", uniq_ti, decl_ti, token_ti, size_ti, avg(token_ti, size_ti)))
    print(hl)
    print(fmt(tabf2, "Local (out)", uniq_lo, decl_lo, token_lo, size_lo, avg(token_lo, size_lo)))
    print(fmt(tabf2, "TOTAL (out)", uniq_to, decl_to, token_to, size_to, avg(token_to, size_to)))
    print(hl.."\n")
  end
end

--- Does experimental optimization for f("string") statements.
--
-- It's safe to delete parentheses without adding whitespace, as both
-- kinds of strings can abut with anything else.
local function optimize_func1()

  local function is_strcall(j)          -- find f("string") pattern
    local t1 = tokpar[j + 1] or ""
    local t2 = tokpar[j + 2] or ""
    local t3 = tokpar[j + 3] or ""
    if t1 == "(" and t2 == "<string>" and t3 == ")" then
      return true
    end
  end

  local del_list = {}           -- scan for function pattern,
  local i = 1                   -- tokens to be deleted are marked
  while i <= #tokpar do
    local id = statinfo[i]
    if id == "call" and is_strcall(i) then  -- found & mark ()
      del_list[i + 1] = true    -- '('
      del_list[i + 3] = true    -- ')'
      i = i + 3
    end
    i = i + 1
  end

  -- Delete a token and adjust all relevant tables.
  -- * Currently invalidates globalinfo and localinfo (not updated),
  --   so any other optimization is done after processing locals
  --   (of course, we can also lex the source data again...).
  -- * Faster one-pass token deletion.
  local del_list2 = {}
  do
    local i, dst, idend = 1, 1, #tokpar
    while dst <= idend do         -- process parser tables
      if del_list[i] then         -- found a token to delete?
        del_list2[xrefpar[i]] = true
        i = i + 1
      end
      if i > dst then
        if i <= idend then        -- shift table items lower
          tokpar[dst] = tokpar[i]
          seminfopar[dst] = seminfopar[i]
          xrefpar[dst] = xrefpar[i] - (i - dst)
          statinfo[dst] = statinfo[i]
        else                      -- nil out excess entries
          tokpar[dst] = nil
          seminfopar[dst] = nil
          xrefpar[dst] = nil
          statinfo[dst] = nil
        end
      end
      i = i + 1
      dst = dst + 1
    end
  end

  do
    local i, dst, idend = 1, 1, #toklist
    while dst <= idend do         -- process lexer tables
      if del_list2[i] then        -- found a token to delete?
        i = i + 1
      end
      if i > dst then
        if i <= idend then        -- shift table items lower
          toklist[dst] = toklist[i]
          seminfolist[dst] = seminfolist[i]
        else                      -- nil out excess entries
          toklist[dst] = nil
          seminfolist[dst] = nil
        end
      end
      i = i + 1
      dst = dst + 1
    end
  end
end

--- Does local variable optimization.
--
-- @tparam {[string]=bool,...} option
local function optimize_locals(option)
  var_new = 0                           -- reset variable name allocator
  varlist = {}

  -- Preprocess global/local tables, handle entropy reduction.
  globaluniq = preprocess(globalinfo)
  localuniq = preprocess(localinfo)
  if option["opt-entropy"] then         -- for entropy improvement
    recalc_for_entropy(option)
  end

  -- Build initial declared object table, then sort according to
  -- token count, this might help assign more tokens to more common
  -- variable names such as 'e' thus possibly reducing entropy.
  -- * An object knows its localinfo index via its 'id' field.
  -- * Special handling for "self" and "_ENV" special local (parameter) here.
  local object = {}
  for i = 1, #localinfo do
    object[i] = localinfo[i]
  end
  sort(object, function(v1, v2)  -- sort largest first
      return v1.xcount > v2.xcount
    end)

  -- The special "self" and "_ENV" function parameters must be preserved.
  -- * The allocator below will never use "self", so it is safe to
  --   keep those implicit declarations as-is.
  local temp, j, used_specials = {}, 1, {}
  for i = 1, #object do
    local obj = object[i]
    if not obj.is_special then
      temp[j] = obj
      j = j + 1
    else
      used_specials[#used_specials + 1] = obj.name
    end
  end
  object = temp

  -- A simple first-come first-served heuristic name allocator,
  -- note that this is in no way optimal...
  -- * Each object is a local variable declaration plus existence.
  -- * The aim is to assign short names to as many tokens as possible,
  --   so the following tries to maximize name reuse.
  -- * Note that we preserve sort order.
  local nobject = #object
  while nobject > 0 do
    local varname, gcollide
    repeat
      varname, gcollide = new_var_name()  -- collect a variable name
    until not SKIP_NAME[varname]          -- skip all special names
    varlist[#varlist + 1] = varname       -- keep a list
    local oleft = nobject

    -- If variable name collides with an existing global, the name
    -- cannot be used by a local when the name is accessed as a global
    -- during which the local is alive (between 'act' to 'rem'), so
    -- we drop objects that collides with the corresponding global.
    if gcollide then
      -- find the xref table of the global
      local gref = globalinfo[globaluniq[varname].id].xref
      local ngref = #gref
      -- enumerate for all current objects; all are valid at this point
      for i = 1, nobject do
        local obj = object[i]
        local act, rem = obj.act, obj.rem  -- 'live' range of local
        -- if rem < 0, it is a -id to a local that had the same name
        -- so follow rem to extend it; does this make sense?
        while rem < 0 do
          rem = localinfo[-rem].rem
        end
        local drop
        for j = 1, ngref do
          local p = gref[j]
          if p >= act and p <= rem then drop = true end  -- in range?
        end
        if drop then
          obj.skip = true
          oleft = oleft - 1
        end
      end--for
    end--if gcollide

    -- Now the first unassigned local (since it's sorted) will be the
    -- one with the most tokens to rename, so we set this one and then
    -- eliminate all others that collides, then any locals that left
    -- can then reuse the same variable name; this is repeated until
    -- all local declaration that can use this name is assigned.
    --
    -- The criteria for local-local reuse/collision is:
    --   A is the local with a name already assigned
    --   B is the unassigned local under consideration
    --   => anytime A is accessed, it cannot be when B is 'live'
    --   => to speed up things, we have first/last accesses noted
    while oleft > 0 do
      local i = 1
      while object[i].skip do  -- scan for first object
        i = i + 1
      end

      -- First object is free for assignment of the variable name
      -- [first,last] gives the access range for collision checking.
      oleft = oleft - 1
      local obja = object[i]
      i = i + 1
      obja.newname = varname
      obja.skip = true
      obja.done = true
      local first, last = obja.first, obja.last
      local xref = obja.xref

      -- Then, scan all the rest and drop those colliding.
      -- If A was never accessed then it'll never collide with anything
      -- otherwise trivial skip if:
      -- * B was activated after A's last access (last < act),
      -- * B was removed before A's first access (first > rem),
      -- if not, see detailed skip below...
      if first and oleft > 0 then  -- must have at least 1 access
        local scanleft = oleft
        while scanleft > 0 do
          while object[i].skip do  -- next valid object
            i = i + 1
          end
          scanleft = scanleft - 1
          local objb = object[i]
          i = i + 1
          local act, rem = objb.act, objb.rem  -- live range of B
          -- if rem < 0, extend range of rem thru' following local
          while rem < 0 do
            rem = localinfo[-rem].rem
          end

          if not(last < act or first > rem) then  -- possible collision

            -- B is activated later than A or at the same statement,
            -- this means for no collision, A cannot be accessed when B
            -- is alive, since B overrides A (or is a peer).
            if act >= obja.act then
              for j = 1, obja.xcount do  -- ... then check every access
                local p = xref[j]
                if p >= act and p <= rem then  -- A accessed when B live!
                  oleft = oleft - 1
                  objb.skip = true
                  break
                end
              end--for

            -- A is activated later than B, this means for no collision,
            -- A's access is okay since it overrides B, but B's last
            -- access need to be earlier than A's activation time.
            else
              if objb.last and objb.last >= obja.act then
                oleft = oleft - 1
                objb.skip = true
              end
            end
          end

          if oleft == 0 then break end
        end
      end--if first

    end--while

    -- After assigning all possible locals to one variable name, the
    -- unassigned locals/objects have the skip field reset and the table
    -- is compacted, to hopefully reduce iteration time.
    local temp, j = {}, 1
    for i = 1, nobject do
      local obj = object[i]
      if not obj.done then
        obj.skip = false
        temp[j] = obj
        j = j + 1
      end
    end
    object = temp  -- new compacted object table
    nobject = #object  -- objects left to process

  end--while

  -- After assigning all locals with new variable names, we can
  -- patch in the new names, and reprocess to get 'after' stats.
  for i = 1, #localinfo do  -- enumerate all locals
    local obj = localinfo[i]
    local xref = obj.xref
    if obj.newname then                 -- if got new name, patch it in
      for j = 1, obj.xcount do
        local p = xref[j]               -- xrefs indexes the token list
        seminfolist[p] = obj.newname
      end
      obj.name, obj.oldname             -- adjust names
        = obj.newname, obj.name
    else
      obj.oldname = obj.name            -- for cases like 'self'
    end
  end

  -- Deal with statistics output.
  for _, name in ipairs(used_specials) do
    varlist[#varlist + 1] = name
  end
  local afteruniq = preprocess(localinfo)
  stats_summary(globaluniq, localuniq, afteruniq, option)
end

--- The main entry point.
--
-- @tparam table option
-- @tparam {string,...} _toklist
-- @tparam {string,...} _seminfolist
-- @tparam table xinfo
function M.optimize(option, _toklist, _seminfolist, xinfo)
  -- set tables
  toklist, seminfolist                  -- from lexer
    = _toklist, _seminfolist
  tokpar, seminfopar, xrefpar           -- from parser
    = xinfo.toklist, xinfo.seminfolist, xinfo.xreflist
  globalinfo, localinfo, statinfo       -- from parser
    = xinfo.globalinfo, xinfo.localinfo, xinfo.statinfo

  -- Optimize locals.
  if option["opt-locals"] then
    optimize_locals(option)
  end

  -- Other optimizations.
  if option["opt-experimental"] then    -- experimental
    optimize_func1()
    -- WARNING globalinfo and localinfo now invalidated!
  end
end

return M
