#!/usr/bin/env lua

dofile 'variable.lua'

-- Array Reverse
array = {1, 2}
print_r(array_reverse(array))

-- Array Merge
ar1 = {}
ar2 = {[2] = 'data'}
print_r (array_merge(ar1, ar2))

ar1 = {['color'] = 'red', 2, 4}
ar2 = {'a', 'b', ['color'] = 'green', ['shape'] = 'trapezoid', 4}
print_r (array_merge(ar1, ar2))

-- Array Merge Recursive
ar1 = {1, 5}
ar2 = {2, 3}
result = array_merge_recursive(ar1, ar2)
print_r(result)

ar1 = {1, 5}
ar2 = {{2}, 3}
result = array_merge_recursive(ar1, ar2)
print_r(result)

ar1 = {{1}, 5}
ar2 = {{2}, 3}
result = array_merge_recursive(ar1, ar2)
print_r(result)

ar1 = {["favorite"] = "red"}
ar2 = {["favorite"] = {"green", 'yellow'}, "blue"}
result = array_merge_recursive(ar1, ar2)
print_r(result)

ar1 = {["color"] = {["favorite"] = {"red", 'yellow'}}, 5}
ar2 = {10, ["color"] = {["favorite"] = "green", "blue"}}
result = array_merge_recursive(ar1, ar2)
print_r(result)

ar1 = {["color"] = {["favorite"] = "red"}, 5}
ar2 = {10, ["color"] = {["favorite"] = {"green", 'yellow'}, "blue"}}
result = array_merge_recursive(ar1, ar2)
print_r(result)

-- Array Filter
ar1 = {{}, 2, 0, ''}
print_r (array_filter(ar1))

-- Is Numeric
ar1 = "1"
print_r (is_numeric(ar1))
