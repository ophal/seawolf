-- Try lo load deprecated PREG library
local rex_loaded, rex = pcall(function () return require [[rex_pcre]] end)
if rex_loaded then
  PREG_SPLIT_NO_EMPTY = 1
  PREG_SPLIT_DELIM_CAPTURE = 2
  PREG_SPLIT_OFFSET_CAPTURE = 4
  PREG_OFFSET_CAPTURE = 256
else
  return FALSE
end
local type, pairs = type, pairs
local rawset, empty = rawset, empty

module [[seawolf.text.preg]]

-- PREG library (deprecated)

-- Perform a regular expression search and replace
-- Copied and adapted from http://lua-users.org/wiki/MakingLuaLikePhp
function replace(pattern, replacement, subject, limit, pcre_flags)
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
function match(pattern, subject, matches, flags, offset, pcre_flags)
  subject = subject or [[]]
  offset = offset or 1

  local match
  local k, matches_ = 0, {}
  if flags == PREG_OFFSET_CAPTURE then
    offset, _, match = rex.find(subject, pattern, offset, pcre_flags)
    if offset ~= nil then
      k = 1
      if match ~= nil then
        rawset(matches_, k, {match, offset})
        rawset(matches_, k + 1, {match, offset})
      end
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

-- Helper function for replace_callback
-- by Fernando P. García
do
  local env = {v = nil}
  local function _replace_callback(match, init)
    init = not empty(init)
    local env = env
    if init then
      env.v = match -- store parameters from parent function: replace_callback
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
end

-- Perform a regular expression search and replace using a callback
-- by Fernando P. García
function replace_callback(pattern, callback, subject, limit, count, pcre_flags)
  limit = limit or -1

  local result
  local params = {callback = callback, limit = limit, count = 0}
  _replace_callback(params, true)
  result = rex.gsub(subject, pattern, _replace_callback, nil, pcre_flags)

  -- count_ref
  if type(count) == [[table]] then
    count.v = params.count
  end

  return result
end

-- Split string by a regular expression
-- by Fernando P. García
-- TODO: pcre_flags should be read from pattern, just as in PHP
-- TODO: flags should work just as in PHP
function split(pattern, subject, limit, flags, pcre_flags)
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

