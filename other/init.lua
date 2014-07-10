require [[seawolf.text]]
local string, require, substr = string, require, seawolf.text.substr

module([[seawolf.other]], package.seeall)

-- Generate a unique ID
-- Migrated from Drupy (authored by Brendon Crawford)
-- by Fernando P. García
function uniqid(prefix, more_entropy)
  if more_entropy == nil then more_entropy = false end

  local out, num, prefix, charmap, i, pos

  out = {}
  num = more_entropy and 23 or 13
  if prefix ~= nil then
    MT_RAND_GENERATOR().seed(prefix)
  end

  charmap = 'abcdefghijklmnopqrstuvwxyz' ..
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ' ..
            '0123456789'

  for i = 1, num do
    pos = math.floor(string.len(charmap) * MT_RAND_GENERATOR())
    table.insert(out, string.sub(charmap, pos, pos))
  end

  return table.concat(out)
end

-- Format a local time/date
-- by Fernando P. García
function date(format_, timestamp)
  local t, d, gmd, gmt, date_, year, month, i, c

  t = {
    ['d'] = 'd',
    ['D'] = 'a',
    ['j'] = 'e',
    ['l'] = 'A',
    ['N'] = 'u',
    ['w'] = 'w',
    ['z'] = 'j', -- Needs tonumber
    ['W'] = 'V',
    ['F'] = 'B',
    ['m'] = 'm',
    ['M'] = 'b',
    ['n'] = 'm', -- Needs tonumber
    ['t'] = 't', -- Needs custom calculation
    ['L'] = 'L', -- Needs custom calculation
    ['o'] = 'G',
    ['Y'] = 'Y',
    ['y'] = 'y',
    ['a'] = 'P',
    ['A'] = 'p',
    ['B'] = 'B', -- Needs custom calculation
    ['g'] = 'l',
    ['G'] = 'H', -- Needs custom calculation
    ['h'] = 'I',
    ['H'] = 'H',
    ['i'] = 'M',
    ['s'] = 'S',
    ['I'] = 'I', -- Needs custom calculation
    ['O'] = 'O', -- Needs custom calculation
    ['Z'] = 'Z', -- Needs custom calculation
    ['c'] = 'c', -- Needs custom calculation
    ['r'] = 'r', -- Needs custom calculation
    ['U'] = 's', -- Needs custom calculation
    [''] = '',
    -- TODO
    -- ['u'] = 'u',
    -- ['e'] = 'e',
    -- ['T'] = 'T',
    ['%'] = '%',
  }

  d = os.date('*t', timestamp)
  gmd = os.date('!*t', timestamp)
  gmt = substr(format_, 1, 1) == '!'

  date_ = {}
  for i = 1, string.len(format_) do
    c = substr(format_, i, 1)
    if c == 'z' or c == 'n' or c == 'G' then
      table.insert(date_, tonumber(os.date((gmt and '!' or '') .. '%'.. t[c], timestamp)))
    elseif c == 't' then
      table.insert(date_, os.date('*t', os.time{['year'] = d.year, ['month'] = d.month + 1, ['day'] = 0})['day'])
    elseif c == 'L' then -- Leap year
      table.insert(date_, (d.year % 4 == 0 and (d.year % 100 ~= 0 or d.year % 400 == 0)) and 1 or 0)
    elseif c == 'I' then -- Leap year
      if gmt then
        table.insert(date_, gmd.isdst and 1 or 0)
      else
        table.insert(date_, d.isdst and 1 or 0)
      end
    elseif c == 'O' or c == 'P' then -- Difference to GMT
      tz = {['sep'] = c == 'P' and ':' or '', ['sign'] = '+'}
      if gmt then
        tz.hour = 0;
        tz.min = 0;
      else
        tz.hour = (gmd.yday - d.yday) * 24 + (gmd.hour - d.hour)
        tz.min  = (gmd.yday - d.yday) * 24 * 60 + (gmd.hour - d.hour) * 60 + (gmd.min - d.min) - tz.hour * 60
        if tz.hour < 0 then
          tz.hour = tz.hour * -1
        else
          tz.sign = '-'
        end
        if tz.min < 0 then
          tz.min = tz.min * -1
        else
          tz.sign = '-'
        end
      end
      table.insert(date_, string.format('%s%02d%s%02d', tz.sign, tz.hour, tz.sep, tz.min))
    elseif c == 'Z' then -- Timezone offset in seconds
      if gmt then
        table.insert(date_, 0)
      else
        table.insert(date_, os.time(os.date('*t', timestamp)) - os.time(os.date('!*t', timestamp)))
      end
    elseif c == 'c'  then -- ISO 8601 date
      table.insert(date_, os.date((gmt and '!' or '') .. '%Y-%m-%dT%H:%M:%S', timestamp) .. date((gmt and '!' or '') .. 'P', timestamp))
    elseif c == 'r'  then -- ISO 8601 date
      table.insert(date_, os.date((gmt and '!' or '') .. '%a, %e %b %Y %H:%M:%S ', timestamp) .. date((gmt and '!' or '') .. 'O', timestamp))
    elseif c == 'B' then -- Swatch Internet Time
      table.insert(date_, math.floor(((((
          gmd.sec/60 -- Seconds to Minutes
        + gmd.min)/60 -- Minutes to Hours
        + gmd.hour)/24) -- Hours to Days
        + 1/24) -- GMT/UTC is 1 hour after Biel Mean Time (BMT)
        * 1000 -- .beats in one Day
      ))
    elseif c == 'U' then -- Seconds since the Unix Epoch
      table.insert(date_, os.date('%s', timestamp))
    elseif t[c] then
      table.insert(date_, '%'.. t[c])
    else
      table.insert(date_, c)
    end
  end

  return os.date(table.concat(date_), timestamp)
end

-- Format a GMT/UTC date/time
-- by Fernando P. García
function gmdate(format_, timestamp)
  return date('!'.. format_, timestamp)
end

IMAGETYPE_GIF = 1
IMAGETYPE_JPEG = 2
IMAGETYPE_PNG = 3
-- Get the size of an image
-- by Fernando P. García
do 
  local types = {
    [ [[gif]]] = IMAGETYPE_GIF,
    [ [[jpeg]]] = IMAGETYPE_JPEG,
    [ [[png]]] = IMAGETYPE_PNG,
  }
  local imlib2
  function getimagesize(filename)
    if imlib2 == nil then imlib2 = require [[imlib2]] end

    -- imageinfo = {v = {}} -- TODO: implement parameter imageinfo

    if is_file(filename) then
      local im = imlib2.image.load(filename)
      local info = {
        im:get_width(),
        im:get_height(),
        types[im:get_format()],
      }
      info[4] = [[width="]] .. info[1] .. [[" height="]] .. info[2] ..[["]]
      -- bits = im:colors(), --TODO: read amount of color
      info.mime = [[image/]] .. im:get_format()

      im:free()

      return info
    end
  end
end

--[[Output Buffering]]
local _PRINT_FUNCTION = print
local _OB_ENV = {}
local _OB_TREE = {}
local _OB_BUFFER = _OB_TREE
local function ob_print(data)
  if #_OB_BUFFER > 0 then
    data = data or ''
    if type(data) == 'table' then
      data = 'Array'
      --~ error('invalid value (table) at index 1 in table for \'ob_print\'')
    end
    table.insert(_OB_BUFFER[2], data)
  end
end

-- Turn on output buffering
-- by Fernando P. García
function ob_start()
  local caller = debug.getinfo(2, [[n]])
  _OB_ENV = getfenv(_G[caller.name])
  _OB_ENV.print = ob_print
  table.insert(_OB_BUFFER, {_OB_BUFFER, {}})
  _OB_BUFFER = _OB_BUFFER[#_OB_BUFFER]
end

-- Return the contents of the output buffer
-- by Fernando P. García
function ob_get_contents()
  if _OB_ENV.print == ob_print then
    return table.concat(_OB_BUFFER[2])
  end
  return false
end

-- Flush (send) the output buffer and turn off output buffering
-- by Fernando P. García
function ob_end_flush()
  if #_OB_BUFFER > 0 and (_OB_ENV.print == ob_print or #_OB_BUFFER[2] > 0) then
    ob_flush()
    return ob_end_clean()
  end
  return false
end

-- Flush (send) the output buffer
-- by Fernando P. García
function ob_flush()
  _PRINT_FUNCTION(table.concat(_OB_BUFFER[2]))
end

-- Clean (erase) the output buffer and turn off output buffering
-- by Fernando P. García
function ob_end_clean()
  if #_OB_BUFFER > 0 then
    _OB_BUFFER = _OB_BUFFER[1] -- point to parent buffer

    -- Buffer has children
    if #_OB_BUFFER == 2 then
      _OB_ENV.print = _PRINT_FUNCTION
    end

    table.remove(_OB_BUFFER) -- remove children buffer
    return true
  end
  return false
end

-- Get current buffer contents and delete current output buffer
-- by Fernando P. García
function ob_get_clean()
  local output = ob_get_contents()
  ob_end_clean()
  return output
end

-- Copied and adapted from http://lua-users.org/wiki/CopyTable
function clone(object)
  local lookup_table = {}
  local function _copy(object)
    if type(object) ~= "table" then
      return object
    elseif lookup_table[object] then
      return lookup_table[object]
    end
    local new_table = {}
    lookup_table[object] = new_table
    for index, value in pairs(object) do
      new_table[_copy(index)] = _copy(value)
    end
    return setmetatable(new_table, getmetatable(object))
  end
  return _copy(object)
end

-- Flush the output buffer
function flush()
 -- TODO: Implement buffering for performance
end

-- Generate a hash value (message digest)
-- by Fernando P. Garcia
do
  local _hash = {
    md5 = {
      [true] = require 'md5'.sum,
      [false] = require 'md5'.sumhexa,
    },
    sha256 = {
      [true] = require 'sha2'.sha256,
      [false] = require 'sha2'.sha256hex,
    },
    sha384 = {
      [true] = require 'sha2'.sha384,
      [false] = require 'sha2'.sha384hex,
    },
    sha512 = {
      [true] = require 'sha2'.sha512,
      [false] = require 'sha2'.sha512hex,
    },
  }

  function hash(algo, data, raw_output)
    if raw_output == nil then raw_output = false end

    if _hash[algo] then
      return _hash[algo][raw_output](data)
    else
      error(('[seawolf.other] in function hash(): unknown hash algorythm "%s"'):format(algo))
    end
  end
end
