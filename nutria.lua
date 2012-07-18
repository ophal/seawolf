#!/usr/bin/env wsapi.cgi

--[[
  @file
  The PHP page that serves all page requests on a Nutria installation.

  The routines here dispatch control to the appropriate handler, which then
  prints the appropriate page.

  $Id$
]]

require "wsapi.response"

module(..., package.seeall)

_G.CGILUA_CONF = './sites/default'

function run(wsapi_env)
  local res = wsapi.response.new()

  _G.SAPI = {
    Info = {
      _COPYRIGHT = "Copyright (C) 2009 Fernando P. Garcia",
      _DESCRIPTION = "Nutria SAPI implementation",
      _VERSION = "Nutria SAPI 1.0",
      ispersistent = false,
    },
    Request = {
      servervariable = function (name) return wsapi_env[name] end,
      getpostdata = function (n) return wsapi_env.input:read(n) end
    },
    Response = {
      contenttype = function (header)
        res["Content-Type"] = header
      end,  
      errorlog = function (msg, errlevel)
        wsapi_env.error:write (msg)
      end,
      header = function (header, value, replace, http_response_code)
        if replace == nil then replace = true end

        if res[header] and not replace then
          if type(res[header]) == "table" then
            table.insert(res[header], value)
          else
            res[header] = { res[header], value }
          end
        else
          res[header] = value
        end

        if http_response_code then
          res.status = http_response_code
        end
      end,
      redirect = function (url, http_response_code)
        res.status = http_response_code or 302
        res.headers["Location"] = url
      end,
      write = function (...)
        res:write({...})
      end,
    },
  }
  require"cgilua"
  cgilua.main()
  return res:finish()
end
