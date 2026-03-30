-- ---------------------------------------------------------------------------
-- spec/mocks/filesystem.lua — warp.filesystem mock helpers for unit tests
-- ---------------------------------------------------------------------------

local _real_io_open = io.open
local _real_io_close = io.close
local _real_os_getenv = os.getenv

local M = {}

--- Build the wezterm mock and load warp.filesystem with a given configuration.
--- Every call returns a *fresh* copy of the module so load-time values
--- (is_win, home, target_triple) reflect the supplied configuration.
---@param opts { triple: string, home?: string, hostname?: string, env?: table<string,string>, io_open?: function, io_close?: function }
---@return table fs  The freshly-loaded warp.filesystem module.
function M.load_fs(opts)
  opts = opts or {}
  local triple = opts.triple or "x86_64-pc-windows-msvc"
  local home = opts.home or "/mock/home"
  local hostname_val = opts.hostname or "mockhost"
  local env = opts.env or {}

  -- Mock os.getenv before the module reads it at load time.
  os.getenv = function(key)
    if env[key] ~= nil then
      return env[key]
    end
    return nil
  end

  -- Mock io.open / io.close if requested.
  if opts.io_open then
    io.open = opts.io_open
  else
    io.open = _real_io_open
  end
  io.close = opts.io_close or _real_io_close

  -- Provide a minimal `wezterm` module.
  package.loaded["wezterm"] = {
    home = home,
    hostname = function()
      return hostname_val
    end,
    target_triple = triple,
  }

  -- Remove cached module so it is re-executed.
  package.loaded["warp.filesystem"] = nil

  -- Adjust package.path (idempotent duplicate entries are harmless).
  if not package.path:find("plugin/%?.lua", 1, true) then
    package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path
  end

  local fs = require "warp.filesystem"

  -- Restore originals immediately to avoid leaking into other tests.
  os.getenv = _real_os_getenv
  io.open = _real_io_open
  io.close = _real_io_close

  return fs
end

--- Build a mock pane whose `get_current_working_dir()` returns `uri`.
---@param uri any  The value returned by get_current_working_dir().
---@return table pane
function M.mock_pane(uri)
  return {
    get_current_working_dir = function()
      return uri
    end,
  }
end

--- Build a userdata-like URI for the modern WezTerm URI object.
--- Uses a real userdata (io.tmpfile) so `type(uri) == "userdata"` holds,
--- then overrides __index on a *private copy* of the metatable to inject fields.
---@param file_path string
---@param host?     string
---@return userdata
function M.userdata_uri(file_path, host)
  local u = io.tmpfile()
  local orig_mt = getmetatable(u)
  local old_index = orig_mt.__index
  -- Build a per-object metatable so we don't pollute the shared file MT.
  local mt = {}
  for k, v in pairs(orig_mt) do
    mt[k] = v
  end
  mt.__index = function(self, k)
    if k == "file_path" then
      return file_path
    end
    if k == "host" then
      return host
    end
    if type(old_index) == "table" then
      return old_index[k]
    elseif type(old_index) == "function" then
      return old_index(self, k)
    end
  end
  mt.__gc = nil -- avoid double-close issues
  -- Lua 5.4: debug.setmetatable sets the metatable for a specific userdata.
  debug.setmetatable(u, mt)
  return u
end

return M
