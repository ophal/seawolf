local seawolf = require 'seawolf'.__build(
  'behaviour',
  'calendar',
  'contrib',
  'fs',
  'maths',
  'other',
  'database',
  'variable'
)

seawolf.variable.print_r(seawolf)

t1 = {1,3}

seawolf.variable.print_r(seawolf.contrib.table_shift(t1))
seawolf.variable.print_r(seawolf.contrib.table_concat(t1))
seawolf.contrib.table_dump(t1)
