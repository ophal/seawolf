local tostring, string, require, socket = tostring, string, require, require [[socket]]

local _M = {}

-- Return current Unix timestamp with microseconds
function _M.microtime()
  local time = tostring(socket.gettime())
  return [[0.]] .. string.sub(time, 12) .. [[ ]] .. string.sub(time, 1, 10)
end

return _M
