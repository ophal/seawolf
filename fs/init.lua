local posix, lfs, string, package = require [[posix]], require [[lfs]], string, package
module [[seawolf.fs]]

-- LUA_DIRSEP is the first character in the string package.config, see
-- src/loadlib.c in your lua source tree for reference
LUA_DIRSEP = string.sub(package.config,1,1)

-- Returns directory name component of path
-- Copied and adapted from http://dev.alpinelinux.org/alpine/acf/core/acf-core-0.4.20.tar.bz2/acf-core-0.4.20/lib/fs.lua
function dirname(string_)
  string_ = string_ or [[]]
  -- strip trailing / first
  string_ = string.gsub(string_, LUA_DIRSEP .. [[$]], [[]])
  local basename = basename(string_)
  string_ = string.sub(string_, 1, #string_ - #basename - 1)
  return(string_)  
end

-- Returns string with any leading directory components removed. If specified, also remove a trailing suffix. 
-- Copied and adapted from http://dev.alpinelinux.org/alpine/acf/core/acf-core-0.4.20.tar.bz2/acf-core-0.4.20/lib/fs.lua
function basename(string_, suffix)
  string_ = string_ or [[]]
  local basename = string.gsub(string_, '[^'.. LUA_DIRSEP ..']*'.. LUA_DIRSEP, [[]])
  if suffix then
    basename = string.gsub(basename, suffix, [[]])
  end
  return basename
end

-- Tells whether the filename is a regular file
-- by Fernando P. García
function is_file(filename)
  local file, err = lfs.attributes(filename)
  return err == nil and file.mode == [[file]] or false
end

-- Tells whether the filename is a directory
-- by Fernando P. García
function is_dir(path)
  local directory, err = lfs.attributes(path)
  return directory ~= nil and directory.mode == [[directory]] or false
end

-- Tells whether the filename is writable
-- by Fernando P. García
function is_writable(path)
  return posix.access(path, [[w]])
end

-- Opens file or URL
-- TODO
function fopen(filename, mode, use_include_path, context)
  if use_include_path == nil then use_include_path = false end
  return io.open(filename, mode)
end

-- Binary-safe file read
-- TODO: validate "length"
function fread(handle, length)
  return handle:read(length)
end
