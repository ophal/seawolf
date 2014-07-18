local type, print, rawget, unpack = type, print, rawget, unpack
local table, pairs = table, pairs
local ipairs, tostring = ipairs, tostring
local sformat = string.format
local sort, tinsert, tconcat = table.sort, table.insert, table.concat

local m = {}

-- Recursively print a table.
function m.table_print(t)
  local print, type, pairs = print, type, pairs
  for _, v in pairs(t) do
    if type(v) == 'table' then
      table_print(v)
    else
      print(v)
    end
  end
end

-- Recursively concat a table
do
  local function _table_concat(t, output)
    local insert, type, pairs = table.insert, type, pairs
    local v
    for k, v in pairs(t) do
      if type(v) == 'table' then
        _table_concat(v, output)
      else
        insert(output, v)
      end
    end
  end

  function m.table_concat(t)
    local table, output = table, {}
    _table_concat(t, output)
    return tconcat(output)
  end
end

-- Copied and Adapted from cgilua/session.lua, part of CGILua Project
--
-- Serializes a value.
--
local function value(v, outf, ind, pre)
  local t = type (v)
  if t == 'string' then
    outf(sformat('%q', v))
  elseif t == 'number' then
    outf(tostring(v))
  elseif t == 'boolean' then
    outf(tostring(v))
  elseif t == 'table' then
    m.table_dump(v, outf, ind, pre)
  else
    outf(sformat('%q', tostring(v)))
  end
end

-- Copied and Adapted from cgilua/session.lua, part of CGILua Project
--
-- Serializes a table.
-- @param tab Table representing the session.
-- @param outf Function used to generate the output.
-- @param ind String with indentation pattern (default = "").
-- @param pre String with indentation prefix (default = "").
function m.table_dump(tab, outf, ind, pre)
  local sep_n, sep, _n = ",\n", ', ', "\n"
  if (not ind) or (ind == '') then ind = ''; sep_n = ', '; _n = '' end
  if not pre then pre = '' end
  if outf == nil then outf = io.write end

  outf '{'
  local p = pre .. ind
  -- prepare list of keys
  local keys = {boolean = {}, number = {}, string = {}}
  local total = 0
  for key in pairs (tab) do
    total = total + 1
    local t = type(key)
    if t == 'string' then
      tinsert(keys.string, key)
    else
      keys[t][key] = true
    end
  end
  local many = total > 5
  if not many then sep_n = sep; _n = ' ' end
  outf(_n)
  -- serialize entries with numeric keys
  if many then
    local _f,_s,_v = ipairs(tab)
    if _f(_s,_v) then outf (p) end
  end
  local num = keys.number
  local ok = false
  -- entries with automatic index
  for key, val in ipairs(tab) do
    value(val, outf, ind, p)
    outf(sep)
    num[key] = nil
    ok = true
  end
  if ok and many then outf (_n) end
  -- entries with explicit index
  for key in pairs (num) do
    if many then outf (p) end
    outf '['
    outf(key)
    outf '] = '
    value(tab[key], outf, ind, p)
    outf(sep_n)
  end
  -- serialize entries with boolean keys
  local tr = keys.boolean[true]
  if tr then
    outf(sformat('%s[true] = ', many and p or ''))
    value(tab[true], outf, ind, p)
    outf(sep_n)
  end
  local fa = keys.boolean[false]
  if fa then
    outf(sformat('%s[false] = ', many and p or ''))
    value(tab[false], outf, ind, p)
    outf(sep_n)
  end
  -- serialize entries with string keys
  sort(keys.string)
  for _, key in ipairs(keys.string) do
    outf(sformat('%s[%q] = ', many and p or '', key))
    value(tab[key], outf, ind, p)
    outf(sep_n)
  end
  if many then outf(pre) end
  outf '}'
end

-- Shift an element off the beginning of a table
do
  local function _table_shift(_, ...)
    return {...}
  end
  function m.table_shift(t)
    return _table_shift(unpack(t))
  end
end

-- Insert each item from rows into the target table
function m.table_insert_multiple(t, rows)
  for _, v in pairs(rows) do
    t[#t+1] = v
  end
end

return m