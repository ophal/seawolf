#!/usr/bin/env lua

local m = require 'init'
local print_r = m.print_r

-- Array Reverse
array = {1, 2}
print_r(m.array_reverse(array))

-- Array Merge
ar1 = {}
ar2 = {[2] = 'data'}
print_r(m.array_merge(ar1, ar2))

ar1 = {['color'] = 'red', 2, 4}
ar2 = {'a', 'b', ['color'] = 'green', ['shape'] = 'trapezoid', 4}
print_r(m.array_merge(ar1, ar2))

-- Array Merge Recursive
ar1 = {1, 5}
ar2 = {2, 3}
result = m.array_merge_recursive(ar1, ar2)
print_r(result)

ar1 = {1, 5}
ar2 = {{2}, 3}
result = m.array_merge_recursive(ar1, ar2)
print_r(result)

ar1 = {{1}, 5}
ar2 = {{2}, 3}
result = m.array_merge_recursive(ar1, ar2)
print_r(result)

ar1 = {["favorite"] = "red"}
ar2 = {["favorite"] = {"green", 'yellow'}, "blue"}
result = m.array_merge_recursive(ar1, ar2)
print_r(result)

ar1 = {["color"] = {["favorite"] = {"red", 'yellow'}}, 5}
ar2 = {10, ["color"] = {["favorite"] = "green", "blue"}}
result = m.array_merge_recursive(ar1, ar2)
print_r(result)

ar1 = {["color"] = {["favorite"] = "red"}, 5}
ar2 = {10, ["color"] = {["favorite"] = {"green", 'yellow'}, "blue"}}
result = m.array_merge_recursive(ar1, ar2)
print_r(result)

-- Array Filter
ar1 = {{}, 2, 0, ''}
print_r(m.array_filter(ar1))

-- Is Numeric
ar1 = "1"
print_r(m.is_numeric(ar1))

-- Serialize & Unserialize
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
  r1 = m.serialize(data)
  r2, dtype = m.unserialize(r1)
  if r1 == m.serialize(r2) then
    check = 'OK'
  else
    check = 'Fail!'
  end
  print(types[dtype], data, r1, m.serialize(r2), 'check:',  check)
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
_test_value(m.unserialize(m.serialize({
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
