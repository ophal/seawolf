local getenv = os.getenv

module [[seawolf.behaviour]]

-- Returns directory path used for temporary files
do
  local path
  function temp_dir()
    if path == nil then
      -- TODO: Test in Windows and Mac
      path = getenv [[TMP]] or getenv [[TEMP]] or getenv [[TMPDIR]]  or [[/tmp]]
    end
    return path
  end
end