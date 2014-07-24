local getenv = os.getenv

local _M = {}

-- Returns directory path used for temporary files
do
  local path
  function _M.temp_dir()
    if path == nil then
      -- TODO: Test in Windows and Mac
      path = getenv [[TMP]] or getenv [[TEMP]] or getenv [[TMPDIR]]  or [[/tmp]]
    end
    return path
  end
end

return _M
