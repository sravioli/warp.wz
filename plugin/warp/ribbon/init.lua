---@module "warp.ribbon"

local Ribbon = require "warp.ribbon.core"
local config = require "warp.ribbon.config"

---@class Ribbon.Api
---@field config Ribbon.ConfigModule
local M = {
  config = config,
}

---@param self_or_name Ribbon.Api|string|nil
---@param name_or_atomic? string|boolean
---@param atomic? boolean
---@return Ribbon
function M.new(self_or_name, name_or_atomic, atomic)
  local name = self_or_name
  local is_atomic = name_or_atomic

  if self_or_name == M then
    name = name_or_atomic
    is_atomic = atomic
  end

  return Ribbon.new(name, is_atomic)
end

---Configure Ribbon.
---@param opts? table
---@return Ribbon.Config
function M.setup(opts)
  return config.setup(opts)
end

return M
