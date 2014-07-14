local seawolf = require 'seawolf'.__build 'variable'
local empty, require, ini_get, assert, pairs = seawolf.variable.empty,
      require, ini_get, assert, pairs

local m = {}

-- TODO:
--~ MYSQL_CLIENT_SSL = 
--~ MYSQL_CLIENT_COMPRESS = 
--~ MYSQL_CLIENT_IGNORE_SPACE = 
--~ MYSQL_CLIENT_INTERACTIVE = 
--~ MYSQL_ASSOC =
--~ MYSQL_NUM =
--~ MYSQL_BOTH =
do
  -- TODO: multiple connections
  local luasql_mysql, luamysql = {}
  -- Open a connection to a MySQL Server
  function m.mysql_connect(server, username, password, new_link) -- TODO, client_flags)
    server = server or ini_get [[mysql.default_host]]
    server = not empty(server) and server or [[localhost:3306]]
    username = username or ini_get [[mysql.default_user]]
    password = password or ini_get [[mysql.default_password]]
    if new_link == nil then new_link = false end
    client_flags = client_flags or 0

    local err

    if not luasql_mysql.env then
      if luamysql == nil then luamysql = require [[luasql.mysql]] end

      luasql_mysql.env = luamysql.mysql()
      luasql_mysql.connection, luasql_mysql.err = luasql_mysql.env:connect([[]], username, password)
      return luasql_mysql.connection
    end
  end

  -- Select a MySQL database
  function m.mysql_select_db(database_name, link_identifier)
    link_identifier = link_identifier or luasql_mysql.connection
    if not empty(link_identifier) and not empty(database_name) then
      rs, luasql_mysql.err = link_identifier:execute([[use ]] .. database_name)
      return luasql_mysql.err == nil
    end
  end

  -- Returns the text of the error message from previous MySQL operation
  function m.mysql_error(link_identifier)
    return luasql_mysql.err or ''
  end

  -- Ping a server connection or reconnect if there is no connection
  function m.mysql_ping()
    -- TODO: implement this functionality
    return true
  end

  -- Send a MySQL query
  function m.mysql_query(query, link_identifier)
    local rs

    link_identifier = link_identifier or luasql_mysql.connection
    if not empty(link_identifier) then
      rs, luasql_mysql.err = link_identifier:execute(query)
      return rs
    end
  end

  -- Fetch a result row as an associative array
  function m.mysql_fetch_assoc(result)
    return function()
      local row = {result:fetch()}
      if not empty(row) then
        local rt = {}
        -- TODO: Improve performance
        local cols = result:getcolnames()
        for k, v in pairs(row) do
          rt[cols[k]] = v
        end
        return rt
      end
    end
  end

  -- TODO: Fetch a result row as an associative array, a numeric array, or both
  function m.mysql_fetch_array(...)
    return m.mysql_fetch_assoc(...)
  end

  -- Get number of rows in result
  function m.mysql_num_rows(resource)
    return resource:numrows()
  end

  -- Get number of fields in result
  function m.mysql_num_fields(resource)
    return #resource:getcolnames()
  end

  -- Get column information from a result and return as an object
  function m.mysql_fetch_field(resource, field_offset)
    return {
      name = resource:getcolnames()[field_offset],
      type = resource:getcoltypes()[field_offset],
    }
  end

  -- Get a result row as an enumerated array
  function m.mysql_fetch_row(resource)
    return function()
      local row = {resource:fetch()}
      if not empty(row) then
        return row
      end
    end
  end

  -- Escapes special characters in a string for use in a SQL statement
  function m.mysql_real_escape_string(string_, link_identifier)
    link_identifier = link_identifier or luasql_mysql.connection
    return link_identifier:escape(string_)
  end

  -- Get affected rows
  function m.mysql_affected_rows(resource)
    return resource:numrows()
  end

  -- Get the ID generated in the last query
  function m.mysql_insert_id(link_identifier)
    return m.mysql_query([[SELECT LAST_INSERT_ID()]]):fetch()
  end

  -- Ping a server connection or reconnect if there is no connection
  function m.mysql_ping ()
    return assert(m.mysql_query([[SELECT 1]]):fetch())
  end
end

return m
