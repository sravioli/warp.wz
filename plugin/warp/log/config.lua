---@module "warp.log.config"

local levels = require "warp.log.levels"
local validate = require "warp.validate"

---@class Log.Config
---@field enabled          boolean Whether logging is enabled globally.
---@field threshold        string|integer  Minimum log level.
---@field sinks            Log.Config.Sinks Sink-related settings.
---@field validate         boolean Set to `false` to skip option validation (and never load warden).

---@class Log.Config.Sinks
---@field default_enabled boolean Prepend the default WezTerm sink to every logger.

---@type Log.Config
local _config = {
  enabled = true,
  threshold = "WARN",
  sinks = { default_enabled = true },
  validate = true,
}

---@param w Warden
local function build_schema(w)
  return w.object({
    enabled = w.boolean():optional(),
    threshold = w.union({
      w.string():refine(function(v)
        return levels.levels[v:upper()] ~= nil
      end, "Expected DEBUG, INFO, WARN or ERROR"),
      w.integer(),
    }):optional(),
    sinks = w.object({ default_enabled = w.boolean():optional() }):optional():unknown "warn",
    validate = w.boolean():optional(),
  }):unknown "warn"
end

---@class Log.ConfigModule
local M = {}

---Return the current configuration as a read-only reference.
---
---@return Log.Config
function M.get()
  return _config
end

---Override configuration values.
---
---Options are checked with warden: invalid fields and unknown keys are logged,
---invalid fields are dropped, and the rest still apply. `validate = false`
---skips the check for this and later calls, and for the sink constructors.
---Only keys present in the defaults are stored. The `sinks` sub-table is
---merged one level deep.
---
---@param overrides? table Partial config to merge.
function M.setup(overrides)
  if type(overrides) ~= "table" then
    return
  end

  local skip = overrides.validate == false
    or (overrides.validate == nil and _config.validate == false)
  if not skip then
    overrides = validate.sanitize(build_schema, overrides)
  end
  if overrides.validate ~= nil then
    _config.validate = overrides.validate
  end

  if overrides.enabled ~= nil then
    _config.enabled = overrides.enabled
  end
  if overrides.threshold ~= nil then
    _config.threshold = overrides.threshold
  end
  if type(overrides.sinks) == "table" then
    if overrides.sinks.default_enabled ~= nil then
      _config.sinks.default_enabled = overrides.sinks.default_enabled
    end
  end
end

return M
