local type, print, rawget, unpack = type, print, rawget, unpack
local table, pairs = table, pairs
local ipairs, tostring = ipairs, tostring
local format = string.format
local sort, tinsert = table.sort, table.insert

module [[seawolf.contrib]]

-- Recursively print a table.
function table_print(t)
  local print, type, pairs = print, type, pairs
  for _, v in pairs(t) do
    if type(v) == [[table]] then
      table_print(v)
    else
      print(v)
    end
  end
end

-- Recursively concat a table
function table_concat(t)
  local table, output = table, {}
  local function table_concat_(t, output)
    local insert, type, pairs = table.insert, type, pairs
    local v
    for k, v in pairs(t) do
      if type(v) == [[table]] then
        table_concat_(v, output)
      else
        insert(output, v)
      end
    end
  end
  table_concat_(t, output)
  return table.concat(output)
end

-- Copied and Adapted from cgilua/session.lua, part of CGILua Project
--
-- Serializes a value.
--
local value function value (v, outf, ind, pre)
  local t = type (v)
  if t == "string" then
    outf (format ("%q", v))
  elseif t == "number" then
    outf (tostring(v))
  elseif t == "boolean" then
    outf (tostring(v))
  elseif t == "table" then
    table_dump (v, outf, ind, pre)
  else
    outf (format ("%q", tostring(v)))
  end
end

-- Copied and Adapted from cgilua/session.lua, part of CGILua Project
--
-- Serializes a table.
-- @param tab Table representing the session.
-- @param outf Function used to generate the output.
-- @param ind String with indentation pattern (default = "").
-- @param pre String with indentation prefix (default = "").
function table_dump (tab, outf, ind, pre)
  local sep_n, sep, _n = ",\n", ", ", "\n"
  if (not ind) or (ind == "") then ind = ""; sep_n = ", "; _n = "" end
  if not pre then pre = "" end
  outf ("{")
  local p = pre..ind
  -- prepare list of keys
  local keys = { boolean = {}, number = {}, string = {} }
  local total = 0
  for key in pairs (tab) do
    total = total + 1
    local t = type(key)
    if t == "string" then
      tinsert (keys.string, key)
    else
      keys[t][key] = true
    end
  end
  local many = total > 5
  if not many then sep_n = sep; _n = " " end
  outf (_n)
  -- serialize entries with numeric keys
  if many then
    local _f,_s,_v = ipairs(tab)
    if _f(_s,_v) then outf (p) end
  end
  local num = keys.number
  local ok = false
  -- entries with automatic index
  for key, val in ipairs (tab) do
    value (val, outf, ind, p)
    outf (sep)
    num[key] = nil
    ok = true
  end
  if ok and many then outf (_n) end
  -- entries with explicit index
  for key in pairs (num) do
    if many then outf (p) end
    outf ("[")
    outf (key)
    outf ("] = ")
    value (tab[key], outf, ind, p)
    outf (sep_n)
  end
  -- serialize entries with boolean keys
  local tr = keys.boolean[true]
  if tr then
    outf (format ("%s[true] = ", many and p or ''))
    value (tab[true], outf, ind, p)
    outf (sep_n)
  end
  local fa = keys.boolean[false]
  if fa then
    outf (format ("%s[false] = ", many and p or ''))
    value (tab[false], outf, ind, p)
    outf (sep_n)
  end
  -- serialize entries with string keys
  sort (keys.string)
  for _, key in ipairs (keys.string) do
    outf (format ("%s[%q] = ", many and p or '', key))
    value (tab[key], outf, ind, p)
    outf (sep_n)
  end
  if many then outf (pre) end
  outf ("}")
end

-- Shift an element off the beginning of a table
function table_shift(t)
  local function _table_shift(_, ...)
    return {...}
  end

  return _table_shift(unpack(t))
end
