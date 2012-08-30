require [[seawolf.variable]]
local io, lpeg = io, require [[lpeg]]
local require, string, table, type, pairs = require, string, table, type, pairs
local rawset, is_array, tostring = rawset, seawolf.variable.is_array, tostring
local empty = seawolf.variable.empty
local pcall, dofile = pcall, dofile

module [[seawolf.text]]

-- Dependencies

-- Split a string by another string
-- Copied and adapted from http://luanet.net/lua/function/explode
-- TODO: Improve performance
function explode(delimiter, string_, limit)
  string_ = string_ or [[]]
  if limit == 0 then limit = 1 end

  delimiter = lpeg.P(delimiter)
  local elem = lpeg.C((1 - delimiter)^0)
  local p = lpeg.Ct(elem * (delimiter * elem)^0)
  local arr = lpeg.match(p, string_)

  if limit and limit < 0 then
    for c = 1, limit*-1 do
      table.remove(arr)
    end
  end
  return arr
end

-- Strip whitespace (or other characters) from the end of a string
-- Copied and adapted from http://lua-users.org/wiki/CommonFunctions
function ltrim(str, charlist)
  charlist = charlist or '%s'

  return str:gsub('^[' .. charlist .. ']*', [[]])
end

-- Strip whitespace (or other characters) from the beginning of a string
-- Copied and adapted from http://lua-users.org/wiki/CommonFunctions
function rtrim(s, pattern)
  pattern = pattern or [[%s]]
  local n = #s
  while n > 0 and s:find([[^]] .. pattern, n) do n = n - 1 end
  return s:sub(1, n)
end

-- Remove leading and/or trailing spaces
-- Copied and adapted from http://lua-users.org/wiki/StringTrim
function trim(str, charlist)
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
function substr(string_, start, length)
  if length then
    if length < 0 then
      length = string.len(string_) + length
    else
      length = start + length - 1
    end
  else
    length = -1
  end

  return string.sub(string_, start, length)
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
  for st, sp in function() return string.find(subject, search, pos, true) end do -- for each match found
    table.insert(buf, string.sub(subject, pos, st - 1)) -- Attach chars left of match
    table.insert(buf, replace) -- Attach replacement string
    pos = sp + 1 -- Jump past current match
    count.v = count.v + 1
  end
  table.insert(buf, subject:sub(pos)) -- Attach chars right of last match
  return table.concat(buf), count.v
end

-- Replace all occurrences of the search string with the replacement string
-- by Fernando P. García
function str_replace(search, replace, subject, count)
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
function strtr(...)
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
function strpos(haystack, needle, offset)
  offset = offset or 1
  local start, end_ = nil, nil
  start, end_ = string.find(haystack, needle, offset, true)
  return start and start - 1 or false
end

ENT_QUOTES = 2
ENT_COMPAT = 3
-- Convert special characters to HTML entities
-- Copied and adapted from http://lua-users.org/lists/lua-l/2008-01/msg00125.html
function htmlspecialchars(string_, quote_style)
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
function strrpos(haystack, needle, offset)
  offset = offset or 0

  local last
  local pos = 1

  repeat
    last = pos
    offset = last
    pos = string.find(haystack, needle, offset + 1, true)
  until pos == nil

  return last
end

-- split a string into a table of number and string values
-- Copied and adapted from http://www.davekoelle.com/files/alphanum.lua (C) Andre Bogus
local function splitbynum(s)
  local result = {}
  for x, y in (s or [[]]):gmatch([[(%d*)(%D*)]]) do
    if x ~= [[]] then table.insert(result, tonumber(x)) end
    if y ~= [[]] then table.insert(result, y) end
  end
  return result
end

-- Case insensitive string comparisons using a "natural order" algorithm
-- Adapted from http://www.davekoelle.com/files/alphanum.lua (C) Andre Bogus
-- by Fernando P. García
function strnatcasecmp(str1, str2)
  str1 = string.lower(str1) or [[]]
  str2 = string.lower(str2) or [[]]

  local xt, yt, i, xe, ye

  if str1 == str2 then
    return 0
  end

  xt, yt = splitbynum(str1), splitbynum(str2)
  for i = 1, math.min(#xt, #yt) do
    xe, ye = xt[i], yt[i]
    if type(xe) == [[string]] then ye = tostring(ye)
    elseif type(ye) == [[string]] then xe = tostring(xe) end
    if xe ~= ye then return (xe < ye) and -1 or 1 end
  end

  return #xt < #yt and -1 or 1
end

-- Calculate the md5 hash of a string
-- by Fernando P. García
do
  local lib_md5
  function md5(str)
    if lib_md5 == nil then lib_md5 = require [[md5]] end
    return lib_md5.sumhexa(str)
  end
end

-- Join array elements with a string
-- by Fernando P. García
function implode(glue, pieces)
  local i
  local t = {}
  for _, i in pairs(pieces) do
    table.insert(t, i)
  end
  return table.concat(t, glue)
end
