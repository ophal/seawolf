#!/usr/bin/env lua

require 'text'
dofile '../variable/variable.lua'

-- str_replace

datetime = os.time()
print_r (datetime)
start = os.clock()*100
loops = 10116
iter = 0
repeat
  str_replace('hola', 'chau', 'hola Fernando')
  iter = iter + 1
until iter == loops
stop = os.clock()*100
print 'Done!'
print('Start = '.. (start))
print('Stop = '.. (stop))
print('Total Time = '.. (stop - start))

-- substr

print_r(substr('12345', -1))
print_r(substr('12345', 1, -1))
