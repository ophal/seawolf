local type, print, rawget = type, print, rawget
local table, pairs = table, pairs

module [[seawolf.contrib]]

-- Recursively print a table.
function table_print(t)
  local print, type, pairs = print, type, pairs
  for _, v in pairs(t) do
    if type(v) == [[table]] then
      table_print(v)
    else
      print(v)
    end
  end
end

-- Recursively concat a table
function table_concat(t)
  local table, output = table, {}
  local function table_concat_(t, output)
    local insert, type, pairs = table.insert, type, pairs
    local v
    for k, v in pairs(t) do
      if type(v) == [[table]] then
        table_concat_(v, output)
      else
        insert(output, v)
      end
    end
  end
  table_concat_(t, output)
  return table.concat(output)
end