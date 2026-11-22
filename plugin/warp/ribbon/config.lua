---@module "warp.ribbon.config"

local tbl = require "warp.table"
local validate = require "warp.validate"

---@class Ribbon.Config
---@field log Ribbon.LogConfig
---@field defaults Ribbon.Defaults
---@field attribute_aliases table<string, string|string[]>
---@field validate_attributes boolean
---@field strict_mode boolean
---@field text Ribbon.TextConfig
---@field atomic boolean
---@field validate boolean Set to `false` to skip option validation (and never load warden).

---@class Ribbon.LogConfig
---@field enabled boolean
---@field threshold "DEBUG"|"INFO"|"WARN"|"ERROR"|integer
---@field sinks? table Accepted for compatibility with the old layout opts.

---@class Ribbon.Defaults
---@field foreground? string
---@field background? string
---@field attributes table<string, table|string>
---@field colors table<string, boolean>

---@class Ribbon.TextConfig
---@field strip boolean
---@field max_length? integer
---@field transform? fun(text: string): string

---@class Ribbon.ConfigModule
local M = {}

---@type Ribbon.Config
local defaults = {
  log = {
    enabled = true,
    threshold = "WARN",
    sinks = { default_enabled = true },
  },

  defaults = {
    foreground = nil,
    background = nil,

    attributes = {
      None = "ResetAttributes",
      NoUnderline = { Underline = "None" },
      Single = { Underline = "Single" },
      Double = { Underline = "Double" },
      Curly = { Underline = "Curly" },
      Dotted = { Underline = "Dotted" },
      Dashed = { Underline = "Dashed" },
      Normal = { Intensity = "Normal" },
      Bold = { Intensity = "Bold" },
      Half = { Intensity = "Half" },
      Italic = { Italic = true },
      NoItalic = { Italic = false },
    },

    -- stylua: ignore
    colors = {
      Black = true, Maroon  = true, Green = true, Olive = true, Navy = true, Purple = true,
      Teal  = true, Silver  = true, Grey  = true, Red   = true, Lime = true, Yellow = true,
      Blue  = true, Fuchsia = true, Aqua  = true, White = true,
    },
  },

  attribute_aliases = {
    b = "Bold",
    i = "Italic",
    u = "Single",
    dim = "Half",
    reset = "None",
    highlight = { "Bold", "Single" },
    emph = { "Bold", "Italic" },
    subtle = { "Half", "Italic" },
  },

  validate_attributes = true,
  strict_mode = false,

  text = {
    strip = false,
    max_length = nil,
    transform = nil,
  },

  atomic = false,
  validate = true,
}

-- Validates user options only; the merge below still extends the defaults.
---@param w Warden
local function build_schema(w)
  return w.object({
    log = w.object({
      enabled = w.boolean():optional(),
      threshold = w.union({ w.string(), w.integer() }):optional(),
      sinks = w.table():optional(),
    })
      :optional()
      :unknown "warn",
    defaults = w.object({
      foreground = w.string():optional(),
      background = w.string():optional(),
      attributes = w.map(w.string(), w.any()):optional(),
      colors = w.map(w.string(), w.boolean()):optional(),
    })
      :optional()
      :unknown "warn",
    attribute_aliases = w.map(w.string(), w.union { w.string(), w.array(w.string()) }):optional(),
    validate_attributes = w.boolean():optional(),
    strict_mode = w.boolean():optional(),
    text = w.object({
      strip = w.boolean():optional(),
      max_length = w.integer():min(0):optional(),
      transform = w.any():optional():refine(function(v)
        return type(v) == "function"
      end, "Expected function"),
    })
      :optional()
      :unknown "warn",
    atomic = w.boolean():optional(),
    validate = w.boolean():optional(),
  }):unknown "warn"
end

---Log invalid fields and drop them so one typo never discards the rest.
---@param opts table
---@return table
local function sanitize(opts)
  if opts.validate == false then
    return opts
  end
  return validate.sanitize(build_schema, opts)
end

local current

---Configure Ribbon. Invalid options are logged and ignored.
---@param opts? table
---@return Ribbon.Config
function M.setup(opts)
  if type(opts) ~= "table" then
    opts = {}
  end
  current = tbl.merge("force", tbl.deepcopy(defaults), sanitize(opts))
  return current
end

---Return the active Ribbon configuration.
---@return Ribbon.Config
function M.get()
  if not current then
    current = tbl.deepcopy(defaults)
  end
  return current
end

---Return a copy of the default configuration.
---@return Ribbon.Config
function M.defaults()
  return tbl.deepcopy(defaults)
end

return M
