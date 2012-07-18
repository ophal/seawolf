require [[seawolf.fs]]
local is_file, loadfile = seawolf.fs.is_file, loadfile
module([[seawolf.behaviour]])

local config

-- Gets the value of a configuration option
function nutria_load_ini_file(file)
  if is_file(file) then
    local f, err = loadfile(file)
    if not f then
      error(err)
    else
      config = f()
    end
  end
end

-- Gets the value of a configuration option
function ini_get(param)
  if config then
    return config[param]
  end
end

