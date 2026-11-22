---@module "warp.api"

---Public API surface for the Warp plugin. Each module loads on first access,
---so a plugin that only uses `warp.string` never loads `warp.log` or `warp.ribbon`.
---
---@class Warp.Api
---@field list       Warp.List       List (sequence) utilities.
---@field maths      Warp.Maths      Math helpers.
---@field table      Warp.Table      General table utilities.
---@field filesystem Warp.FileSystem Filesystem helpers.
---@field path       Warp.Path       Path manipulation helpers.
---@field process    Warp.Process    Executable lookup and argv helpers.
---@field string     Warp.String     String utilities.
---@field log        Log.API         Tagged loggers and sinks.
---@field ribbon     Ribbon.Api      Chainable `wezterm.format` builder.
local M = {}

local modules = {
  list = true,
  maths = true,
  table = true,
  filesystem = true,
  path = true,
  process = true,
  string = true,
  log = true,
  ribbon = true,
}

setmetatable(M, {
  __index = function(t, name)
    if modules[name] then
      local mod = require("warp." .. name)
      rawset(t, name, mod)
      return mod
    end
  end,
})

return M
