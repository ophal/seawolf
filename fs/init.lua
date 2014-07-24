local lfs, string = require [[lfs]], string
local package, sleep, uuid = package, require 'socket'.sleep, require [[uuid]]
local rename, remove, open = os.rename, os.remove, io.open
local tconcat, tremove = table.concat, table.remove


-- LUA_DIRSEP is the first character in the string package.config, see
-- src/loadlib.c in your lua source tree for reference
local LUA_DIRSEP = string.sub(package.config,1,1)

local _M = {}

-- Returns directory name component of path
-- Copied and adapted from http://dev.alpinelinux.org/alpine/acf/core/acf-core-0.4.20.tar.bz2/acf-core-0.4.20/lib/fs.lua
function _M.dirname(string_)
  string_ = string_ or [[]]
  -- strip trailing / first
  string_ = string.gsub(string_, LUA_DIRSEP .. [[$]], [[]])
  local basename = _M.basename(string_)
  string_ = string.sub(string_, 1, #string_ - #basename - 1)
  return(string_)  
end

-- Returns string with any leading directory components removed. If specified, also remove a trailing suffix. 
-- Copied and adapted from http://dev.alpinelinux.org/alpine/acf/core/acf-core-0.4.20.tar.bz2/acf-core-0.4.20/lib/fs.lua
function _M.basename(string_, suffix)
  string_ = string_ or [[]]
  local basename = string.gsub(string_, '[^'.. LUA_DIRSEP ..']*'.. LUA_DIRSEP, [[]])
  if suffix then
    basename = string.gsub(basename, suffix, [[]])
  end
  return basename
end

-- Tells whether the filename is a regular file
-- by Fernando P. García
function _M.is_file(filename)
  local file, err = lfs.attributes(filename)
  return err == nil and file.mode == [[file]] or false
end

-- Tells whether the filename is a directory
-- by Fernando P. García
function _M.is_dir(path)
  local directory, err = lfs.attributes(path)
  return directory ~= nil and directory.mode == [[directory]] or false
end

-- Copied from Luarocks' function of same name
function _M.normalize(name)
   return name:gsub("\\", "/"):gsub("(.)/*$", "%1")
end

-- Describe a path in a cross-platform way.
-- Use this function to avoid platform-specific directory
-- separators in other modules. Removes trailing slashes from
-- each component given, to avoid repeated separators.
-- Separators inside strings are kept, to handle URLs containing
-- protocols.
-- @param ... strings representing directories
-- @return string: a string with a platform-specific representation
-- of the path.
-- Copied from Luarocks' function of same name
function _M.path(...)
   local items = {...}
   local i = 1
   while items[i] do
      items[i] = items[i]:gsub("(.+)/+$", "%1")
      if items[i] == "" then
         tremove(items, i)
      else
         i = i + 1
      end
   end
   return (tconcat(items, "/"):gsub("(.+)/+$", "%1"))
end

-- Tells whether the filename or directory is writable
-- Warning: testing if a file/dir is writable does not guarantee
-- that it will remain writable and therefore it is no replacement
-- for checking the result of subsequent operations.
-- @param file string: filename to test
-- @return boolean: true if file exists, false otherwise.
-- Copied from Luarocks' function of same name.
function _M.is_writable(file)
   file = normalize(file)
   local result
   if is_dir(file) then
      local file2 = path(file, '.tmpluarockstestwritable')
      local fh = open(file2, 'wb')
      result = fh ~= nil
      if fh then fh:close() end
      remove(file2)
   else
      local fh = open(file, 'r+b')
      result = fh ~= nil
      if fh then fh:close() end
   end
   return result
end

-- Opens file or URL
-- TODO
function _M.fopen(filename, mode, use_include_path, context)
  if use_include_path == nil then use_include_path = false end
  return io.open(filename, mode)
end

-- Binary-safe file read
-- TODO: validate "length"
function _M.fread(handle, length)
  return handle:read(length)
end

-- Thread-safe open file in read mode
function _M.safe_open(filepath, timeout, retry, sign)
  if not timeout then timeout = 0.001 end
  if not retry then retry = 0 end -- for internal use only!
  if not sign then sign = [[]] end -- for internal use only!

  local fh, err
  local file_lock, file_sign = filepath .. [[.lock]]

  -- Try to open lock file
  fh, err = open(file_lock)
  if fh then
    -- Validate signature
    file_sign = fh:read [[*l]]
    fh:close()
    if file_sign == sign and sign:len() > 0 then
      -- Pre-create target file
      fh, err = open(filepath, [[a+]])
      if fh then
        fh:close()
        fh, err = open(filepath)
        return fh, sign, err
      else
        error [[I/O error: can't create session.]]
      end
    else
      -- Other process has set a read lock, wait a bit and retry
      sleep(timeout)
      retry = retry + 1
      if retry <= 224 then
        return _M.safe_open(filepath, timeout, retry)
      else
        return nil, ([[%s retries without luck :(]]):format(retry - 1)
      end
    end
  else
    -- Try to lock
    fh, err = open(file_lock, [[a+]])
    if fh then
      -- Check is not signed yet
      if not fh:read [[*l]] then
        file_sign = uuid.new()
        fh:write(file_sign)
        fh:write("\n")
        fh:close()
        -- Try to re-open lock
        return _M.safe_open(filepath, timeout, retry, file_sign)
      else        
        sleep(timeout)
        retry = retry + 1
        if retry <= 224 then
          return _M.safe_open(filepath, timeout, retry)
        else
          return nil, ([[%s retries without luck :(]]):format(retry - 1)
        end
      end
    else
      return nil, [[Can't lock: retry later]]
    end
  end
end

-- Write to file opened by safe_open()
function _M.safe_write(filepath, sign, data)
  if not sign then sign = [[]] end 

  local fh, err, unlocked
  local file_lock, file_sign = filepath .. [[.lock]]

  -- Try to open lock file
  fh, err = open(file_lock)
  if fh then
    -- Validate signature
    file_sign = fh:read [[*l]]
    fh:close()
    if file_sign == sign and sign:len() > 0 then
      -- Try to open target file
      fh, err = open(filepath, [[w]])
      if fh then
        -- Save data
        fh:write(data)
        fh:close()
        return true
      else
        return nil, [[Can't open target file]]
      end
    else
      return nil,  [[Can't write: invalid sign]]
    end
  else
    return nil, [[Can't open lock]]
  end
end

-- Unlock file opened by safe_open()
function _M.safe_close(filepath, sign)
  local file_lock, file_sign = filepath .. [[.lock]]

  fh, err = open(file_lock)
  if fh then
    -- Validate signature
    file_sign = fh:read [[*l]]
    fh:close()
    if file_sign == sign and sign:len() > 0 then
      -- Unlock
      unlocked, err = remove(file_lock)
      if unlocked then
        return unlocked
      else
        return nil, ([[Can't remove read lock (%s)]]):format(err)
      end
    end
  end
end

return _M
