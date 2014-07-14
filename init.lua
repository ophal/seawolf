local default_components = {
  'behaviour',
  'calendar',
  'contrib',
  'database',
  'fs',
  'maths',
  'other',
  'text',
  'variable',
}

local m = {}

function m.__build(...)
  local components = {...}

  for _, v in pairs(components) do
    local status, component = pcall(require, ('seawolf.%s'):format(v))
    if component ~= nil then
      m[v] = component
    end
  end

  return m
end

return m
