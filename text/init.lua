require [[seawolf.variable]]
local io, lpeg = io, require [[lpeg]]
local
  require, string, table, type, pairs, rawset, is_array, empty, static =
  require, string, table, type, pairs, rawset, seawolf.variable.is_array, seawolf.variable.empty, seawolf.variable.static
local tostring = tostring

module([[seawolf.text]])

-- Dependencies
rex = require [[rex_pcre]]

PREG_SPLIT_NO_EMPTY = 1
PREG_SPLIT_DELIM_CAPTURE = 2
PREG_SPLIT_OFFSET_CAPTURE = 4
PREG_OFFSET_CAPTURE = 256

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

-- Perform a regular expression search and replace
-- Copied and adapted from http://lua-users.org/wiki/MakingLuaLikePhp
function preg_replace(pattern, replacement, subject, limit, pcre_flags)
  pcre_flags = pcre_flags or [[]]

  local sk, s, sp, p
  local extract = false

  if subject == nil then
    return
  end

  if type(subject) == [[string]] then
    subject = {subject}
    extract = true
  end

  if type(pattern) == [[string]] then
    pattern = {pattern}
    pcre_flags = {pcre_flags}
  end

  if type(replacement) ~= [[table]] then
    replacement = {replacement}
  end

  for sk, s in pairs(subject) do
    for sp, p in pairs(pattern) do
      subject[sk] = rex.gsub(subject[sk], p, replacement[sp], limit, pcre_flags[sp])
    end
  end

  if extract then
    return subject[1]
  else
    return subject
  end
end

-- Perform a regular expression match
-- by Fernando P. García
--
-- For the use of pcre_flags parameter, please see the following link:
--   http://www.php.net/manual/en/reference.pcre.pattern.modifiers.php
function preg_match(pattern, subject, matches, flags, offset, pcre_flags)
  subject = subject or [[]]
  offset = offset or 1

  local match
  local k, matches_ = 0, {}
  if flags == PREG_OFFSET_CAPTURE then
    offset, _, match = rex.find(subject, pattern, offset, nil, pcre_flags)
    if match ~= nil then
      k = 1
      rawset(matches_, k, {match, offset})
      rawset(matches_, k + 1, {match, offset})
    end
  else
    for match in rex.gmatch(subject, pattern, pcre_flags) do
      k = k + 1
      rawset(matches_, k, match)
    end
  end
  -- If matches is passed then reference to matches found
  if type(matches) == [[table]] then
    matches.v = matches_
  end
  return k > 0 and 1 or 0
end

-- Helper function for preg_replace_callback
-- by Fernando P. García
local function _preg_replace_callback(match, init)
  init = not empty(init)
  local env = static([[_preg_replace_callback_callback]])
  if init then
    env.v = match -- store parameters from parent function: preg_replace_callback
    return
  end
  env.v.count = env.v.count + 1
  if env.v.limit > -1 then
    if env.v.count > env.v.limit then
      return
    end
  end
  return _G[env.v.callback]({match, match})
end

-- Perform a regular expression search and replace using a callback
-- by Fernando P. García
function preg_replace_callback(pattern, callback, subject, limit, count, pcre_flags)
  limit = limit or -1

  local result
  local params = {callback = callback, limit = limit, count = 0}
  _preg_replace_callback(params, true)
  result = rex.gsub(subject, pattern, _preg_replace_callback, nil, pcre_flags)

  -- count_ref
  if type(count) == [[table]] then
    count.v = params.count
  end

  return result
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

-- Split string by a regular expression
-- by Fernando P. García
-- TODO: pcre_flags should be read from pattern, just as in PHP
-- TODO: flags should work just as in PHP
function preg_split(pattern, subject, limit, flags, pcre_flags)
  if limit == -1 or limit == 0 or limit == nil then limit = nil end
  flags = flags or 0

  local t, c, p, o, s = {}, 0

  for match in rex.split(subject, pattern, pcre_flags) do
    table.insert(t, match)
    c = c + 1
    if limit and limit == c then
      break
    end
  end
--~ print_r ({pattern, subject, limit, flags, pcre_flags})
--~ print_r (t)
  return t
end
