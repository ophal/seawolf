#!/usr/bin/env lua

require 'serialize'

local _unserialize_check, _test_value

function _test_value(data)
  local types, r1, r2, dtype, check
  types = {
    ['n'] = 'Null',
    ['b'] = 'Boolean',
    ['i'] = 'Integer',
    ['d'] = 'Float',
    ['s'] = 'String',
    ['a'] = 'Array',
  }
  r1 = serialize(data)
  r2, dtype = unserialize(r1)
  if r1 == serialize(r2) then
    check = 'OK'
  else
    check = 'Fail!'
  end
  print(types[dtype], data, r1, serialize(r2), 'check:',  check)
end

_test_value(nil)

_test_value(true)

_test_value(false)

_test_value(1)

_test_value(-1)

_test_value(1.1)

_test_value(-1.1)

print('String 1 as Int ')
_test_value('1')

_test_value('text')

print('Array with booleans ')
_test_value(unserialize(serialize({
  [false] = true,
  [true] = false,
})))

print('Array with booleans ')
_test_value({
  [1] = 'string',
  [2] = 1,
  a = 'str_key1',
  ['b'] = 'str_key2',
})
