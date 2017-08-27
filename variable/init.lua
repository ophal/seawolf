local
  type, string, table, tostring, print, next, getmetatable, pairs =
  type, string, table, tostring, print, next, getmetatable, pairs
local
  setmetatable, rawset, rawget = setmetatable, rawset, rawget

local _M = {}

-- PHP Array emulator
-- by Fernando P. García
do

  local keys = {} -- Index of Array keys
  local rkeys = {} -- Reverse index of keys

  Array = {
  -- Metamethods
    --~ __index = function (t, k)
      --~ if rawget(t, k) == nil then
        --~ rawset(t, k, {})
      --~ end
      --~ return rawget(t, k)
    --~ end,

    __newindex = function (t, k, v)
      if v ~= nil then
        local tk = tostring(t)
        table.insert(keys[tk], k)
        rawset(rkeys[tk], k, #keys[tk])
        rawset(t, k, v)
      end
    end,
   
  -- Psedo-class methods
    type = function ()
      return [[PHPArray]]
    end,

    keys = function (t)
      Array.import(t)
      return keys[tostring(t)]
    end,

    -- Take care of given table
    import = function(t)
      if not Array.registered(t) and type(t) == [[table]] then
        local i, r, v = {}, {}
        for k in pairs(t) do
          table.insert(i, k)
          rawset(r, k, #i)
        end
        keys[tostring(t)] = i
        rkeys[tostring(t)] = r
        setmetatable(t, Array)
      end
    end,

    -- Forget about given table
    forget = function (t)
      if Array.registered(t) then
        keys[tostring(t)] = nil
        rkeys[tostring(t)] = nil
      end
    end,

    -- Return a new Array instance
    new = function (t)
      if t == nil then t = {} end

      Array.import(t)
      return t
    end,

    -- Add items without checking if given Table is already registered
    set = function (t, k, v)
      t[k] = v
    end,

    -- Right method to add items, DO NOT use table.insert()
    insert = function (...)
      local args, temp
      args = {...}

      Array.import(args[1])

      if #args == 2 then
        temp = args[2]
        args[3] = args[2]
        args[2] = #args[1] + 1
      end

      Array.set(unpack(args))
    end,

    shift = function (t)
      local ti, tr, k, ki, v
      local tk = tostring(t)
      
      -- Get indexes
      ti = keys[tk]
      tr = rkeys[tk]
      -- get key and value(shifting index)
      ki, k = next(ti)
      v = t[k]
      -- remove and forget item
      t[k] = nil
      ti[ki] = nil
      tr[k] = nil
      return v
    end,

    remove = function (t, k)
      local tk, ti, v

      Array.import(t)

      -- Get index and reverse index
      tk = tostring(t)
      ti = keys[tk]
      -- Get last key when 'k' is nil
      if k == nil then k = ti[#ti] end
      -- Read value to be removed
      v = t[k]
      -- Remove item from Array, index and reverse index
      t[k] = nil
      table.remove(ti, rkeys[tk][k])
      rkeys[tk][k] = nil

      return v
    end,

    -- Right method to fetch items in the correct order
    each = function (t, f)
      if type(t) ~= [[table]] then return end
      local keys

      Array.import(t)

      keys = Array.keys(t)
      for k in pairs(keys) do
        k = rawget(keys, k)
        f(k, rawget(t, k))
      end
    end,

    -- Returns true if given Table is managed by psedo-class Array
    registered = function (t)
      return keys[tostring(t)] ~= nil
    end,
  }
end

-- Prints human-readable information about a variable
-- Copied and adapted from https://dev.mobileread.com/trac/luailiad/browser/trunk/experiments/XX/print_r.lua?rev=42
function _M.print_r(expression, return_)
  return_ = not _M.empty(return_)

  local tableList, output = {}, {}
  function table_r(t, name, indent, full)
    local serial = tostring(name)
    table.insert(output, indent .. serial ..(name ~= nil and ' = ' or ''))
    if type(t) == 'table' then
      if tableList[t] ~= nil then
        table.insert(output, '{} -- '.. tableList[t] ..' (self reference)\n')
      else
        tableList[t] = full .. serial
        if next(t) then -- Table not empty
          table.insert(output, '{\n')
          for key,value in pairs(t) do
            table_r(value, key, indent ..'    ', full .. serial)
          end
          table.insert(output, indent ..'}\n')
        else
          table.insert(output, '{}\n')
        end
      end
    else
      table.insert(output, (type(t) ~= 'number' and type(t) ~= 'boolean' and
        '"'.. tostring(t) ..'"' or
        tostring(t)) ..'\n')
    end
  end

  table_r(expression, nil, '', '')

  if return_ then
    return table.concat(output)
  else
    print(table.concat(output))
  end
end

-- Return true if the given function has been defined
-- by Fernando P. García
function _M.function_exists(function_)
  return type(_G[function_]) == 'function'
end

-- Checks if the given key or index exists in the array
-- by Fernando P. García
function _M.array_key_exists(key, array)
  if is_array(array) then
    return not (array[key] == nil)
  end
  return false
end

-- Finds whether a variable is an array
-- by Fernando P. García
function _M.is_array(var)
 return type(var) == 'table'
end

-- Emulate array_reverse of PHP
-- by by Philippe Lhoste
-- Copied and adapted from http://phi.lho.free.fr/programming/TestLuaArray.lua.htmlhttp://phi.lho.free.fr/programming/TestLuaArray.lua.html
function _M.array_reverse(t)
  local l = table.getn(t) -- table length
  local j = l
  for i = 1, l / 2 do
    t[i], t[j] = t[j], t[i]
    j = j - 1
  end
  return t
end

-- Emulate array_slice of PHP
-- by Philippe Lhoste
-- Copied and adapted from http://phi.lho.free.fr/programming/TestLuaArray.lua.htmlhttp://phi.lho.free.fr/programming/TestLuaArray.lua.html
function _M.array_slice(t, startPos, endPos)
  local tableSize = #t -- Table size
  if endPos == nil then
    -- Only one parameter: extract to end of table
    endPos = tableSize + 1
  end
  if startPos < 0 then
    startPos = tableSize + 1 + startPos
    -- -1 -> last element
    -- -2 -> last two elements, etc.
  end
  if endPos < 0 then
    endPos = tableSize + 1 + endPos
  end
  local result = {}
  for i = startPos, endPos - 1 do
    result[i - startPos + 1] = t[i]
  end
  return result
end

-- Implementation of is_numeric function
-- TODO: review http://www.gammon.co_M.au/forum/bbshowpost.php?bbsubject_id=9271
do
  local falses = {
    [false] = true,
    [ [[]]] = true,
  }
  function _M.is_numeric (var)
    var = tonumber(var)
    return not (not var or falses[var] or (type(var) == [[table]] and next(var) == nil))
  end
end

-- Call a user function given by the first parameter
-- by Fernando P. García
function _M.call_user_func(function_, ...)
  return _G[function_](...)
end

-- Call a user function given with an array of parameters
-- by Fernando P. García
function _M.call_user_func_array(function_, args)
  args = args or {}
  if _G[function_] ~= nil then
    return _G[function_](unpack(args))
  else
    error("attempt to call global '".. function_ .."' (a nil value)")
  end
end

-- Exchanges all keys with their associated values in an array
-- by Fernando P. García
function _M.array_flip(trans)
  local out, key, value = {}

  for key, value in pairs(trans) do
    if type(value) == 'string' or type(value) == 'number' then
      out[value] = key
    else
      out[key] = value
    end
  end

  return out
end

-- Helper function for array_shift(), array_merge() and array_merge_recursive()
-- by Fernando P. García
local function _array_shift(t)
  if type(t) == [[table]] and not empty(t) then
    local k, v
    k, v = next(t)
    t[k] = nil
    return v, k
  end
end

-- Pop the element off the beginning of array
-- by Fernando P. García
function _M.array_shift(array)
  if type(array) == [[table]] and not _M.empty(array) then
    if getmetatable(array) == Array then
      return Array.shift(array)
    else
      return table.remove(array, 1)
    end
  end
end

-- Shift an element off the end of array
-- by Fernando P. García
function _M.array_pop(array)
  if type(array) == [[table]] and not empty(array) then
    if getmetatable(array) == Array then
      return Array.remove(array)
    else
      return table.remove(array)
    end
  end
end

-- Searches the array for a given value and returns the corresponding key if successful
-- by Fernando P. García
function _M.array_search(needle, array)
  local key, value

  for key, value in pairs(array) do
    if value == needle then
      return key
    end
  end

  return false
end

-- Fetch a key from an array
-- by Fernando P. García
function _M.key(array)
  -- WARNING! This implementation returns just the FIRST key of given array
  return select(1, next(array))
end

-- Computes the difference of arrays
-- by Fernando P. García
function _M.array_diff(...)
  local t1, pos, ot, new
  local arg = {...}; arg.n = #arg

  local array_diff_ = function (t1, t2)
    local k1, v1, k2, v2
    local new, same = {}, {}

    for k1, v1 in pairs(t1) do
      for k2, v2 in pairs(t2) do
        if v1 == v2 then
          same[k1] = v1
        end
      end
      if not same[k1] then
        table.insert(new, v1)
      end
    end

    return new
  end

  t1 = _array_shift(arg)

  pos = 1
  while pos < arg.n do
    ot = arg[pos]
    new = array_diff_(t1, ot)
    t1 = new -- redirect diff to new array
    pos = pos + 1
  end

  return new
end

-- Determine whether a variable is empty
-- by Javier Guerra
do
   local falses = {
       [false] = true,
       [0] = true,
       [ [[]]] = true,
       [ [[0]]] = true,
   }
   function _M.empty (var)
       return not var or falses[var] or (type(var) == [[table]] and next(var)==nil)
   end
end

-- Helper function for array_merge() and array_merge_recursive()
-- by Fernando P. García
local function _array_merge(t1, t2, recursive)
  if recursive == nil then recursive = false end

  Array.import(t1)
  Array.import(t2)

  local key, value
  local new = Array.new()
  Array.each(t1, function (key, value)
    new[key] = value
  end)
  Array.each(t2, function (key, value)
    if type(key) == 'number' then
      Array.insert(new, value)
    elseif type(key) == 'string' then
      if recursive and (type(new[key]) == 'table' or type(value) == 'table') then
        if type(value) ~= 'table' then
          value = {value}
        end
        if type(new[key]) ~= 'table' then
          new[key] = {new[key]}
        end
        new[key] = _array_merge(new[key], value, recursive)
      elseif not recursive or new[key] == nil then
        new[key] = value
      else
        new[key] = {new[key], value}
      end
    else
      error('Unknown key type!')
    end
  end)
  return new
end

-- Merge one or more arrays
-- by Fernando P. García
function _M.array_merge(...)
  local t1, pos, ot, new
  local arg = {...}; arg.n = #arg

  t1 = _M.array_shift(arg)
  pos = 1
  while pos < arg.n do
    ot = arg[pos]
    new = _array_merge(t1, ot)
    t1 = new -- redirect merge to new array
    pos = pos + 1
  end

  return new
end

-- Return all the keys of an array
-- by Fernando P. García
function _M.array_keys(input, search_value, strict)
  assert(type(input) == [[table]], [['bad argument #1 to 'array_keys' (table expected, got ]].. type(input) ..[[)]])
  assert(strict == nil, [[Parameter "strict" still not implement]])
  assert(search_value == nil, [[Parameter "search_value" still not implement]])

  local key
  local keys, k = {}, 1

  for key in pairs(input) do
    keys[k] = key
    k = k + 1
  end

  return keys
end

-- Return all the keys of an array
-- by Fernando P. García
function _M.array_values(array)
  assert(type(array) == [[table]], [['bad argument #1 to 'array_values' (table expected, got ]].. type(array) ..[[)]])

  local val
  local values, k = {}, 1

  for _, val in pairs(array) do
    values[k] = val
    k = k + 1
  end

  return values
end

-- Fill an array with values
-- by Fernando P. García
function _M.array_fill(start_index, num, value)
  local i
  local buf, c = {}, 0

  if num > 0  then
    for i = start_index, start_index + num - 1 do
      table.insert(buf, value)
    end
  end

  return buf
end

-- Sort an array by values using a user-defined comparison function
-- by Fernando P. García
function _M.usort(array, cmp_function)
  table.sort(array, _G[cmp_function])
end

-- Prepend one or more elements to the beginning of an array
-- by Fernando P. García
function _M.array_unshift(array, ...)
  local k, v
  local bkp, c = {}, 0

  -- Copy table
  for k, v in pairs(array) do
    bkp[k] = v
    array[k] = nil
  end

  -- Append new values
  for _, v in pairs({...}) do
    table.insert(array, v)
    c = c + 1
  end

  -- Insert old values
  for k, v in pairs(bkp) do
    if type(k) == 'string' then
      array[k] = v
    else
      table.insert(array, v)
    end
    c = c + 1
  end

  return c
end

-- Helper function for uasort()
-- Copied and adapted from http://rosettacode.org/wiki/Quicksort#Lua
local function _uasort(array, keys, cmp_function, start, endi)
  start, endi = start or 1, endi or #keys
  -- partition w.r.t. first element
  if endi - start < 1 then
    return
  end
  local pivot, cmp, i = start, _, _
  for i = start + 1, endi do
    cmp = cmp_function(array[keys[i]], array[keys[pivot]])
    if cmp < 1 then
      local temp = keys[pivot + 1]
      keys[pivot + 1] = keys[pivot]
      if i == pivot + 1 then
        keys[pivot] = temp
      else
        keys[pivot] = keys[i]
        keys[i] = temp
      end
      pivot = pivot + 1
    end
  end
  _uasort(array, keys, cmp_function, start, pivot - 1)
  _uasort(array, keys, cmp_function, pivot + 1, endi)
end

-- Sort an array with a user-defined comparison function and maintain index association
function _M.uasort(array, cmp_function)
  local temp, k, v

  if _G[cmp_function] ~= nil then
    Array.import(array)
    _uasort(array, Array.keys(array), _G[cmp_function])
  end
end

-- Push one or more elements onto the end of array
-- by Fernando P. García
function _M.array_push(array, ...)
  local args, var

  if type(array) ~= 'table' then
    error('Table expected, got:'.. type(array))
  end

  args = {...}

  if #args > 0 then
    for _, var in pairs(args) do
      table.insert(array, var)
    end
    return 
  end
end

-- Merge two or more arrays recursively
-- by Fernando P. García
function _M.array_merge_recursive(...)
  local t1, pos, ot, new
  local arg = {...}; arg.n = #arg

  t1 = _M.array_shift(arg)

  pos = 1
  while pos < arg.n do
    ot = arg[pos]
    new = _array_merge(t1, ot, true)
    t1 = new -- redirect merge to new array
    pos = pos + 1
  end

  return new
end

-- Filters elements of an array using a callback function
-- by Fernando P. García
function _M.array_filter(input, callback)
  local t = Array.new()

  if callback == nil then
    callback = function (v)
      return not _M.empty(v)
    end
  else
    callback = _G[callback]
  end

  Array.each(input, function(k, v)
    if callback(v) then
      t[k] = v
    end
  end)

  return t
end

-- Sort an array and maintain index association
-- by Fernando P. Garcia
function _M.asort(t)
  table.sort(t)
end

-- Checks if a value exists in an array
-- TODO: validate variables, deal with sub-tables
-- by Fernando P. Garcia
function _M.in_array(needle, haystack)
  local out = {}
  out = _M.array_flip(haystack)
  return out[needle]
end

-- Finds whether a variable is NULL
function _M.is_null(var)
  return var == nil
end

--[[
  Given a pointer name, return pointer from metadata
  
  Usage
    PHP:
      <?php
        function foo() {
          static $var
          $var = 1
        }
      ?>
    LUA:
      function foo()
        var = static('foo_var')
        var.v = 1
      end
]]
_S = {} -- global place for static variables
function _M.static(pointer, value)
  -- Read static variable
  if _S[pointer] == nil then
    -- Set default value
    _S[pointer] = {['v'] = value}
  end
  return _S[pointer]
end

--[[
  Lua port of PHP serialization functions.
  
  Port based on PHPSerialize and PHPUnserialize by Scott Hurring
  http://hurring.com/scott/code/python/serialize/v0.4
  
  @version v0.1 BETA
  @author Fernando P. García; fernando at develcuy dot com
  @copyright Copyright (c) 2009 Fernando P. García
  @license http://opensource.org/licenses/gpl-license.php GNU Public License
  
  $Id$
]]

local _serialize_key, _read_chars, _read_until, _unknown_type

function _serialize_key(data)
  --[[
  Serialize a key, which follows different rules than when 
  serializing values.  Many thanks to Todd DeLuca for pointing 
  out that keys are serialized differently than values!
  
  From http://us2.php.net/manual/en/language.types.array.php
  A key may be either an integer or a string. 
  If a key is the standard representation of an integer, it will be
  interpreted as such (i.e. "8" will be interpreted as int 8,
  while "08" will be interpreted as "08"). 
  Floats in key are truncated to integer. 
  ]]

  -- Integer, Long, Float
  if type(data) == 'number' then
    return 'i:' .. tonumber(data) .. ';'

  -- Boolean => integer
  elseif type(data) == 'boolean' then
    if data then
      return 'i:1;'
    else
      return 'i:0;'
    end

  -- String => string or String => int (if string looks like int)
  elseif type(data) == 'string' then
    if tonumber(data) == nil then
      return 's:' .. string.len(data) .. ':"' .. data .. '";'
    else
      return 'i:' .. tonumber(data) .. ';'
    end
  
  -- None / NULL => empty string
  elseif type(data) == 'nil' then
    return 's:0:"";'
  
  -- I dont know how to serialize this
  else
    error('Unknown / Unhandled key  type (' .. type(data) .. ')!')
  end
end

function _M.serialize(data)
  --[[
  Serialize a value.
  ]]

  local i, out, key, value

  -- Numbers
  if type(data) == 'number' then
    -- Integer => integer
    if  math.floor(data) == data then
      return 'i:' .. data .. ';'
    -- Float, Long => double
    else
      return 'd:' .. data .. ';'
    end

  -- String => string or String => int (if string looks like int)
  -- Thanks to Todd DeLuca for noticing that PHP strings that
  -- look like integers are serialized as ints by PHP 
  elseif type(data) == 'string' then
    if tonumber(data) == nil then
      return 's:' .. string.len(data) .. ':"' .. data .. '";'
    else
      return 'i:' .. tonumber(data) .. ';'
    end

  -- Nil / NULL
  elseif type(data) == 'nil' then
    return 'N;'

  -- Tuple and List => array
  -- The 'a' array type is the only kind of list supported by PHP.
  -- array keys are automagically numbered up from 0
  elseif type(data) == 'table' then
    i = 0
    out = {}
    -- All arrays must have keys
    for key, value in pairs(data) do
      table.insert(out, _serialize_key(key))
      table.insert(out, _M.serialize(value))
      i = i + 1
    end
    return 'a:' .. i .. ':{' .. table.concat(out) .. '}'

  -- Boolean => bool
  elseif type(data) == 'boolean' then
    if data then
      return 'b:1;'
    else
      return 'b:0;'
    end

  --~ TODO:
  --~ -- Table + Functions => stdClass
  --~ elseif type(data) == 'function' then

  --~ # I dont know how to serialize this
  else
   error('Unknown / Unhandled data type (' .. type(data) .. ')!')
  end
end

function _read_until(data, offset, stopchar)
  --[[
  Read from data[offset] until you encounter some char 'stopchar'.
  ]]

  local buf = {}
  local char = string.sub(data, offset + 1, offset + 1)
  local i = 2
  while not (char == stopchar) do
    -- Consumed all the characters and havent found ';'
    if i + offset > string.len(data) then
      error('Invalid')
    end
    table.insert(buf, char)
    char = string.sub(data, offset + i, offset + i)
    i = i + 1
  end
  -- (chars_read, data)
  return i - 2, table.concat(buf)
end

function _read_chars(data, offset, length)
  --[[
  Read 'length' number of chars from data[offset].
  ]]

  local buf = {}, char
  -- Account for the starting quote char
  -- offset += 1
  for i = 0, length -1 do
    char = string.sub(data, offset + i, offset + i)
    table.insert(buf, char)
  end

  -- (chars_read, data)
  return length, table.concat(buf)
end

function _M.unserialize(data, offset)
  offset = offset or 0

  --[[
  Find the next token and unserialize it.
  Recurse on array.

  offset = raw offset from start of data
  --]]

  local buf, dtype, dataoffset, typeconvert, datalength, chars, readdata, i,
         key, value, keys, properties, otchars, otype, property

  buf = {}
  dtype = string.lower(string.sub(data, offset + 1, offset + 1))

  -- 't:' = 2 chars
  dataoffset = offset + 2
  typeconvert = function(x) return x end
  datalength = 0
  chars = datalength

  -- int or double => Number
  if dtype == 'i' or dtype == 'd' then
    typeconvert = function(x) return tonumber(x) end
    chars, readdata = _read_until(data, dataoffset, ';')
    -- +1 for end semicolon
    dataoffset = dataoffset + chars + 1

  -- bool => Boolean
  elseif dtype == 'b' then
    typeconvert = function(x) return tonumber(x) == 1 end
    chars, readdata = _read_until(data, dataoffset, ';')
    -- +1 for end semicolon
    dataoffset = dataoffset + chars + 1

  -- n => None
  elseif dtype == 'n' then
    readdata = nil

  -- s => String
  elseif dtype == 's' then
    chars, stringlength = _read_until(data, dataoffset, ':')
    -- +2 for colons around length field
    dataoffset = dataoffset + chars + 2

    -- +1 for start quote
    chars, readdata = _read_chars(data, dataoffset + 1, tonumber(stringlength))
    -- +2 for endquote semicolon
    dataoffset = dataoffset + chars + 2

    --[[
    TODO
    review original: if chars != int(stringlength) != int(readdata):
    ]]
    if not (chars == tonumber(stringlength)) then
      error('String length mismatch')
    end

  -- array => Table
  -- If you originally serialized a Tuple or List, it will
  -- be unserialized as a Dict.  PHP doesn't have tuples or lists,
  -- only arrays - so everything has to get converted into an array
  -- when serializing and the original type of the array is lost
  elseif dtype == 'a' then
    readdata = {}

    -- How many keys does this list have?
    chars, keys = _read_until(data, dataoffset, ':')
    -- +2 for colons around length field
    dataoffset = dataoffset + chars + 2

    -- Loop through and fetch this number of key/value pairs
    for i = 0, tonumber(keys) - 1 do
      -- Read the key
      key, ktype, kchars = _M.unserialize(data, dataoffset)
      dataoffset = dataoffset + kchars

      -- Read value of the key
      value, vtype, vchars = _M.unserialize(data, dataoffset)
      -- Cound ending bracket of nested array
      if vtype == 'a' then
        vchars = vchars + 1
      end
      dataoffset = dataoffset + vchars

      -- Set the list element
      readdata[key] = value
    end
  -- object => Table
  elseif dtype == 'o' then
    readdata = {}

    -- How log is the type of this object?
    chars, otchars = _read_until(data, dataoffset, ':')
    dataoffset = dataoffset + chars + 2

    -- Which type is this object?
    otype = string.sub(data, dataoffset + 1, dataoffset + otchars)
    dataoffset = dataoffset + otchars + 2

    if otype == 'stdClass' then
      -- How many properties does this list have?
      chars, properties = _read_until(data, dataoffset, ':')

      -- +2 for colons around length field
      dataoffset = dataoffset + chars + 2

      -- Loop through and fetch this number of key/value pairs
      for i = 0, tonumber(properties) - 1 do
        -- Read the key
        property, ktype, kchars = unserialize(data, dataoffset)
        dataoffset = dataoffset + kchars

        -- Read value of the key
        value, vtype, vchars = unserialize(data, dataoffset)
        -- Cound ending bracket of nested array
        if vtype == 'a' then
          vchars = vchars + 1
        end
        dataoffset = dataoffset + vchars

        -- Set the list element
        readdata[property] = value
      end
    else
      _unknown_type(dtype)
    end
  else
    _unknown_type(dtype)
  end

  --~ return (dtype, dataoffset-offset, typeconvert(readdata))
  return typeconvert(readdata), dtype, dataoffset - offset
end

-- I don't know how to unserialize this
function _unknown_type(type_)
  error('Unknown / Unhandled data type (' .. type_ .. ')!', 2)
end

return _M
