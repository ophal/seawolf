Seawolf is a toolkit library, it implements several handy functions to make Ophal developers life easier. It was originally planned to be a PHP standard library, but now is open to improvements and additions of other old and new approaches to web development.

### Dependencies
Seawolf packages reuse Lua modules that are helpful for web development.

* [Lua MD5](http://www.keplerproject.org/md5)
* [lrandom](http://www.tecgraf.puc-rio.br/~lhf/ftp/lua/#lrandom)
* [luuid](http://www.tecgraf.puc-rio.br/~lhf/ftp/lua/#luuid)
* [lrexlib-pcre](http://lrexlib.luaforge.net)
* [LuaFileSystem](http://www.keplerproject.org/luafilesystem)
* [luaposix](http://luaforge.net/projects/luaposix)
* [lua-imlib2](http://asbradbury.org/projects/lua-imlib2)
* [LuaSocket](http://luasocket.luaforge.net)
* [LuaSQL](http://www.keplerproject.org/luasql)


### Functions by package
NOTICE: some functions may be deprecated and/or replaced over time, in aims of improving Ophal's coding standards.

* ** Behaviour **
  ini_get

* ** Calendar **
  microtime

* ** Database **
  mysql_connect, mysql_error, mysql_fetch_assoc, mysql_real_escape_string, mysql_affected_rows, mysql_insert_id

* **Filesystem**
  basename, dirname, is_dir, is_file, is_writable

* **Text**
  explode, htmlspecialchars, implode, ltrim, md5, preg_match, preg_replace, preg_replace_callback, rtrim, str_replace, strnatcasecmp, strpos, strrpos, strtr, substr, trim

* **Variable**
  array_diff, array_fill, array_flip, array_key_exists, array_keys, array_merge, array_pop, array_reverse, array_search, array_shift, array_slice, array_unshift, call_user_func, call_user_func_array, empty, function_exists, is_array, is_numeric, is_null, key, print_r, serialize, unserialize, usort, is_numeric, array_push, array_merge_recursive, array_filter, asort, uasort, static

* **Other**
  clone, date, flush, gmdate, getimagesize, in_array, ob_print, ob_start, ob_get_contents, ob_end_flush, ob_flush, ob_end_clean, ob_get_clean, uniqid
