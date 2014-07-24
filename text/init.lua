local seawolf = require 'seawolf'.__build 'variable'
local io, lpeg = io, require [[lpeg]]
local require, string, table, type, pairs = require, string, table, type, pairs
local rawset, is_array, tostring = rawset, seawolf.variable.is_array, tostring
local empty, mmin = seawolf.variable.empty, math.min
local pcall, dofile, floor, tconcat = pcall, dofile, math.floor, table.concat
local print, tinsert, tremove = print, table.insert, table.remove
local slen, ssub, sfind, slower = string.len, string.sub, string.find, string.lower

local _M = {}

-- Dependencies

-- Split a string by another string
-- Copied and adapted from http://luanet.net/lua/function/explode
-- TODO: Improve performance
function _M.explode(delimiter, string_, limit)
  string_ = string_ or [[]]
  if limit == 0 then limit = 1 end

  delimiter = lpeg.P(delimiter)
  local elem = lpeg.C((1 - delimiter)^0)
  local p = lpeg.Ct(elem * (delimiter * elem)^0)
  local arr = lpeg.match(p, string_)

  if limit and limit < 0 then
    for c = 1, limit*-1 do
      tremove(arr)
    end
  end
  return arr
end

-- Strip whitespace (or other characters) from the end of a string
-- Copied and adapted from http://lua-users.org/wiki/CommonFunctions
function _M.ltrim(str, charlist)
  charlist = charlist or '%s'

  return str:gsub('^[' .. charlist .. ']*', [[]])
end

-- Strip whitespace (or other characters) from the beginning of a string
-- Copied and adapted from http://lua-users.org/wiki/CommonFunctions
function _M.rtrim(s, pattern)
  pattern = pattern or [[%s]]
  local n = #s
  while n > 0 and s:find([[^]] .. pattern, n) do n = n - 1 end
  return s:sub(1, n)
end

-- Remove leading and/or trailing spaces
-- Copied and adapted from http://lua-users.org/wiki/StringTrim
function _M.trim(str, charlist)
  local lpeg = require [[lpeg]]
  if charlist == nil then
    charlist = lpeg.S(' \t\n\r\0\v')
  else
    charlist = lpeg.S(charlist)
  end
  return lpeg.match(charlist^0 * lpeg.C((charlist^0 * (1 - charlist)^1)^0), str or [[]])
end

-- Return part of a string
-- by Fernando P. García
function _M.substr(string_, start, length)
  if length then
    if length < 0 then
      length = slen(string_) + length
    else
      length = start + length - 1
    end
  else
    length = -1
  end

  return ssub(string_, start, length)
end

-- Helper function for str_replace
-- by Fernando P. García
local function _str_replace(search, replace, subject, count)
  search = search or [[]]
  subject = subject or [[]]
  count = count or {['v'] = 0}

  local st, sp
  local pos, buf, len = 0, {}, 0
  count.v = 0
  len = #search
  for st, sp in function() return sfind(subject, search, pos, true) end do -- for each match found
    tinsert(buf, ssub(subject, pos, st - 1)) -- Attach chars left of match
    tinsert(buf, replace) -- Attach replacement string
    pos = sp + 1 -- Jump past current match
    count.v = count.v + 1
  end
  tinsert(buf, subject:sub(pos)) -- Attach chars right of last match
  return tconcat(buf), count.v
end

-- Replace all occurrences of the search string with the replacement string
-- by Fernando P. García
function _M.str_replace(search, replace, subject, count)
  count = count or {['v'] = 0}

  local s, k
  local c = 0

  if type(search) ~= [[table]] then search = {search} end
  count.v = 0

  if type(replace) == [[table]] then
    for k, s in pairs(search) do
      subject, c = _str_replace(s, replace[k] or [[]], subject, count)
      count.v = count.v + c
    end
  else
    for _, s in pairs(search) do
      subject, c = _str_replace(s, replace, subject, count)
      count.v = count.v + c
    end
  end

  return subject, count.v
end

-- Translate certain characters
-- by Fernando P. García
function _M.strtr(...)
  local arg = {...}
  local str, from, to, replace_pairs
  str = arg[1] or [[]]
  replace_pairs = arg[2]
  if is_array(replace_pairs) then
    for from, to in pairs(replace_pairs) do
      str = strtr(str, from, to)
    end
    return str
  else
    from = arg[2]
    to = arg[3]
    return _str_replace(from , to, str)
    --~ return string.gsub(str, from, to)
  end
end

-- Find position of first occurrence of a string
-- by Fernando P. García
function _M.strpos(haystack, needle, offset)
  offset = offset or 1
  local start, end_ = nil, nil
  start, end_ = sfind(haystack, needle, offset, true)
  return start and start - 1 or false
end

ENT_QUOTES = 2
ENT_COMPAT = 3
-- Convert special characters to HTML entities
-- Copied and adapted from http://lua-users.org/lists/lua-l/2008-01/msg00125.html
function _M.htmlspecialchars(string_, quote_style)
  quote_style = quote_style or 2

  local output

  if type(string_) ~= [[string]] then
    string_ = tostring(string_)
  end

  local escaped = {[ [[&]]] = [[&amp;]], [ [[<]]] = [[&lt;]], [ [[>]]] = [[&gt;]]}

  if (quote_style == ENT_COMPAT or quote_style == ENT_QUOTES) then
    escaped[ [["]]] = [[&quot;]]
  end
  if (quote_style == ENT_QUOTES) then
    escaped[ [[']]] = [[&#039;]]
  end

  output = string_:gsub('[<>&]', function(c) return escaped[c] end)
  return output
end

-- Find position of last occurrence of a char in a string
-- by Fernando P. Garcia
function _M.strrpos(haystack, needle, offset)
  offset = offset or 0

  local last
  local pos = 1

  repeat
    last = pos
    offset = last
    pos = sfind(haystack, needle, offset + 1, true)
  until pos == nil

  return last
end

-- split a string into a table of number and string values
-- Copied and adapted from http://www.davekoelle.com/files/alphanum.lua (C) Andre Bogus
local function splitbynum(s)
  local result = {}
  for x, y in (s or [[]]):gmatch([[(%d*)(%D*)]]) do
    if x ~= [[]] then tinsert(result, tonumber(x)) end
    if y ~= [[]] then tinsert(result, y) end
  end
  return result
end

-- Case insensitive string comparisons using a "natural order" algorithm
-- Adapted from http://www.davekoelle.com/files/alphanum.lua (C) Andre Bogus
-- by Fernando P. García
function _M.strnatcasecmp(str1, str2)
  str1 = slower(str1) or [[]]
  str2 = slower(str2) or [[]]

  local xt, yt, i, xe, ye

  if str1 == str2 then
    return 0
  end

  xt, yt = splitbynum(str1), splitbynum(str2)
  for i = 1, mmin(#xt, #yt) do
    xe, ye = xt[i], yt[i]
    if type(xe) == [[string]] then ye = tostring(ye)
    elseif type(ye) == [[string]] then xe = tostring(xe) end
    if xe ~= ye then return (xe < ye) and -1 or 1 end
  end

  return #xt < #yt and -1 or 1
end

-- Join array elements with a string
-- by Fernando P. García
function _M.implode(glue, pieces)
  local i
  local t = {}
  for _, i in pairs(pieces) do
    tinsert(t, i)
  end
  return tconcat(t, glue)
end

do
  --[[
    Map string chars into a table.

    by LU324_ and DigitalKiwi.
  ]]
  function _M.str2map(s)
    local map, rmap, i = {}, {}, 0
    for c in (s):gmatch('.') do
      i = i + 1
      map[i] = c1
      rmap[c] = i
    end
    return map, i, rmap
  end

  -- Default string map and maplen for int2strmap()
  local default_map, default_maplen, default_rmap = _M.str2map '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

  --[[
    Convert given integer to alphanumeric.

    by LU324_ and q66 (Copied and adapted from http://lua-users.org/lists/lua-l/2004-09/msg00054.html).
  ]]
  function _M.int2strmap(IN, map)
    local buffer, i, d, maplen = {}, 0

    if map == nil then
      map, maplen = default_map, default_maplen
    else
      map, maplen = _M.str2map(map)
    end

    while IN > 0 do
      i = i + 1
      IN, d = floor(IN/maplen), IN % maplen + 1
      buffer[i] = map[d]
    end
    for j = 1, i/2 do
      buffer[j], buffer[i-j+1] = buffer[i-j+1], buffer[j]
    end
    return tconcat(buffer)
  end

  --[[
    Convert given string to integer by (optional) given string map.
  ]]
  function _M.str2intmap(str, map)
    local buffer, int, i, rmap, maplen = {}, 0, #str

    if map == nil then
      rmap, maplen = default_rmap, default_maplen
    else
      map, maplen, rmap = _M.str2map(map)
    end

    for c in (str):gmatch('.') do
      i = i - 1
      int = int + (rmap[c] - 1)*maplen^i
    end

    return int
  end
end

return _M
