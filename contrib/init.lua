local type, print, rawget, unpack = type, print, rawget, unpack
local table, pairs = table, pairs
local ipairs, tostring = ipairs, tostring
local sformat = string.format
local sort, tinsert, tconcat = table.sort, table.insert, table.concat

local _M = {}

-- Recursively print a table.
function _M.table_print(t)
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

  function _M.table_concat(t, sep, i, j)
    local output = {}
    _table_concat(t, output)
    return tconcat(output, sep, i, j)
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
    _M.table_dump(v, outf, ind, pre)
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
function _M.table_dump(tab, outf, ind, pre)
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
  function _M.table_shift(t)
    return _table_shift(unpack(t))
  end
end

-- Insert each item from rows into the target table
function _M.table_insert_multiple(t, rows)
  local c = #t
  for _, v in pairs(rows) do
    c = c + 1
    t[c] = v
  end
end

-- Insert given value 'v' to the end of table 't' ignoring metatable methods
function _M.table_append(t, v)
  t[#t + 1] = v
end

-- Run given callback on each element
function _M.table_each(t, callback)
  local stop

  for k, v in pairs(t) do
    stop = callback(k, v)
    if stop then
      break
    end
  end
end

-- Creates a new table with metatable set to _M.metahelper
-- If table passed as argument, only assigns the metatable
function _M.seawolf_table(t)
  if t == nil then
    t = {}
  end

  setmetatable(t, _M.metahelper)

  return t
end

-- Copied and adapted from http://stackoverflow.com/questions/15429236/how-to-check-if-a-module-exists-in-lua
function _M.module_exists(name)
  if package.loaded[name] then
    return true
  else
    for _, searcher in ipairs(package.searchers or package.loaders) do
      local loader = searcher(name)
      if type(loader) == 'function' then
        package.preload[name] = loader
        return true
      end
    end
    return false
  end
end

-- Copied and adapted from: https://gist.github.com/HoraceBury/9001099
--
-- Cleans rich text so that HTML is cleanly removed, p and br tags are reduced
-- to new lines and some special characters are replaced with the text
-- equivelents.
function _M.strip_tags(text)
  text = text .. '!!>' -- patch (fix non-closed tag)

  -- list of strings to replace (the order is important to avoid conflicts)
  local cleaner = {
    { "&amp;", "&" }, -- decode ampersands
    { "&#151;", "-" }, -- em dash
    { "&#146;", "'" }, -- right single quote
    { "&#147;", "\"" }, -- left double quote
    { "&#148;", "\"" }, -- right double quote
    { "&#150;", "-" }, -- en dash
    { "&#160;", " " }, -- non-breaking space
    { "<br ?/?>", "\n" }, -- all <br> tags whether terminated or not (<br> <br/> <br />) become new lines
    { "</p>", "\n" }, -- ends of paragraphs become new lines
    { "(%b<>)", "" }, -- all other html elements are completely removed (must be done last)
    { "\r", "\n" }, -- return carriage become new lines
    { "[\n\n]+", "\n" }, -- reduce all multiple new lines with a single new line
    { "^\n*", "" }, -- trim new lines from the start...
    { "\n*$", "" }, -- ... and end
  }

  -- clean html from the string
  for i = 1, #cleaner do
    local cleans = cleaner[i]
    text = text:gsub(cleans[1], cleans[2])
  end

  return text:gsub('!!>', '') -- unpatch
end

-- Exchanges all keys with their associated values in a table
function _M.table_flip(t)
  local out, key, value = {}

  for key, value in pairs(t) do
    if [[string]] == type(value) or [[number]] == type(value) then
      out[value] = key
    else
      out[key] = value
    end
  end

  return out
end

-- Return all the keys of a table
function _M.table_keys(input)
  assert(type(input) == [[table]], [['bad argument #1 to 'table:keys()' (table expected, got ]].. type(input) ..[[)]])

  local key
  local keys, k = _M.seawolf_table(), 1

  for key in pairs(input) do
    keys[k] = key
    k = k + 1
  end

  return keys
end

-- Parse given text to date parts
-- by develCuy and Outlastsheep
do
  local date_map = {
    month = {
      Jan = '01',
      Feb = '02',
      Mar = '03',
      Apr = '04',
      May = '05',
      Jun = '06',
      Jul = '07',
      Aug = '08',
      Sep = '09',
      Oct = '10',
      Nov = '11',
      Dec = '12',
    }
  }

  function _M.parse_date(text)
    local dow, day, month_name, year, hours, minutes, seconds, timezone = text:match('(.-), (.-) (.-) (.-) (.-):(.-):(.-) (.+)')
    return {
      dow = dow,
      month_name = month_name,
      day = day,
      month = date_map.month[month_name],
      year = year,
      hours = hours,
      minutes = minutes,
      seconds = seconds,
      timezone = timezone,
    }
  end
end

-- Helper metatable
_M.metahelper = {
  __index = function(t, k)
    local meta = _M.metahelper
    if meta[k] ~= nil then
      return meta[k]
    end
  end,

  shift = _M.table_shift,
  concat = _M.table_concat,
  print = _M.table_print,
  dump = _M.table_dump,
  insert_multiple = _M.table_insert_multiple,
  append = _M.table_append,
  each = _M.table_each,
  sort = table.sort,
  flip = _M.table_flip,
  keys = _M.table_keys,
}

return _M
