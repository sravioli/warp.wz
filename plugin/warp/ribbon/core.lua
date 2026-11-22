---@module "warp.ribbon.core"

local config = require "warp.ribbon.config"
local log = require "warp.log"
local str = require "warp.string"
local wezterm = require "wezterm" --[[@as Wezterm]]

local tinsert = table.insert

---@class Ribbon
---@field log Log Logger instance.
---@field public atomic? boolean Reset text attributes after each operation.
---@field private layout table Internal format items.
---@field private name string Ribbon identifier.
local M = {}
M.__index = M

---@param attribute string
---@param log Log
---@return string|string[]
local function resolve_attribute(attribute, log)
  local cfg = config.get()
  if cfg.attribute_aliases and cfg.attribute_aliases[attribute] then
    local resolved = cfg.attribute_aliases[attribute]

    if type(resolved) == "table" then
      return resolved
    end

    attribute = resolved
  end

  if cfg.defaults.attributes[attribute] then
    return attribute
  end

  if cfg.validate_attributes then
    local msg = string.format("Unknown attribute '%s'", attribute)
    if cfg.strict_mode then
      error(msg)
    else
      log:warn(msg)
    end
  end

  return attribute
end

---@param text string|nil
---@return string
local function process_text(text)
  local cfg = config.get()
  text = tostring(text)

  if cfg.text.strip then
    text = str.trim(text)
  end

  if cfg.text.transform then
    text = cfg.text.transform(text)
  end

  if cfg.text.max_length then
    -- By display columns, so multi-byte text is never cut mid-character.
    text = str.truncate_right(text, cfg.text.max_length)
  end

  return text
end

---@param layout table
---@param bg? string
---@param fg? string
---@param idx fun(): integer
local function insert_colors(layout, bg, fg, idx)
  local cfg = config.get()
  bg = bg or cfg.defaults.background or "none"
  fg = fg or cfg.defaults.foreground or "none"

  local bg_entry = cfg.defaults.colors[bg] and { Background = { AnsiColor = bg } }
    or { Background = { Color = bg } }
  tinsert(layout, idx(), bg_entry)

  local fg_entry = cfg.defaults.colors[fg] and { Foreground = { AnsiColor = fg } }
    or { Foreground = { Color = fg } }
  tinsert(layout, idx(), fg_entry)
end

---@param layout table
---@param attributes? string|string[]
---@param idx fun(): integer
---@param log Log
local function insert_attributes(layout, attributes, idx, log)
  local cfg = config.get()
  if not attributes or (type(attributes) == "table" and #attributes == 0) then
    return
  end

  local attr_list = (type(attributes) == "string") and { attributes } or attributes

  local function process_attr(val)
    local resolved = resolve_attribute(val, log)

    if type(resolved) == "table" then
      for _, nested_val in ipairs(resolved) do
        process_attr(nested_val)
      end
    elseif type(resolved) == "string" then
      if cfg.defaults.attributes[resolved] then
        local attr = cfg.defaults.attributes[resolved]
        tinsert(layout, idx(), attr == "ResetAttributes" and attr or { Attribute = attr })
      else
        log:error("attribute '%s' is not defined!", resolved)
      end
    end
  end

  for _, attr in ipairs(attr_list) do
    process_attr(attr)
  end
end

---@param item any
---@return boolean
local function is_format_item_array(item)
  return type(item) == "table" and #item > 0
end

---@param layout table
---@param items table|string|nil
---@param prepend? boolean
local function insert_format_items(layout, items, prepend)
  if items == nil then
    return
  end

  if not is_format_item_array(items) then
    tinsert(layout, prepend and 1 or #layout + 1, items)
    return
  end

  if prepend then
    for i = #items, 1, -1 do
      tinsert(layout, 1, items[i])
    end
    return
  end

  for _, item in ipairs(items) do
    tinsert(layout, item)
  end
end

---A logger that keeps Ribbon's own level filter, independent of `log.setup`.
---@param tag string
---@param cfg Ribbon.LogConfig
---@return Log
local function new_logger(tag, cfg)
  local logger = log.new(tag, cfg.enabled ~= false)
  logger.threshold = log.levels.normalize(cfg.threshold) or log.levels.levels.WARN
  return logger
end

---Create a new Ribbon instance.
---@param name? string
---@param atomic? boolean
---@return Ribbon ribbon
function M.new(name, atomic)
  local cfg = config.get()
  name = "Ribbon" .. (name and " > " .. name or "")
  local is_atomic = atomic
  if is_atomic == nil then
    is_atomic = cfg.atomic
  end

  return setmetatable({
    layout = {},
    log = new_logger(name, cfg.log),
    name = name,
    atomic = is_atomic,
  }, M)
end

---Add one styled text segment.
---@param action "append"|"prepend"
---@param background? string
---@param foreground? string
---@param text? string
---@param attributes? string|string[]
---@return Ribbon|nil self
function M:add(action, background, foreground, text, attributes)
  if not action or action == "" then
    return self.log:error "Cannot operate with empty action"
  end

  -- Build the segment in order, then place it: inserting each part at index 1
  -- would reverse it and put the text before its own colors.
  local segment = {}
  local idx = function()
    return #segment + 1
  end

  insert_colors(segment, background, foreground, idx)
  insert_attributes(segment, attributes, idx, self.log)

  tinsert(segment, { Text = process_text(text) })

  if self.atomic then
    tinsert(segment, config.get().defaults.attributes.None)
  end

  insert_format_items(self.layout, segment, action == "prepend")
  return self
end

---Append an element to the ribbon.
---@param background? string
---@param foreground? string
---@param text? string
---@param attributes? string|string[]
---@return Ribbon|nil self
function M:append(background, foreground, text, attributes)
  return M.add(self, "append", background, foreground, text, attributes)
end

---Prepend an element to the ribbon.
---@param background? string
---@param foreground? string
---@param text? string
---@param attributes? string|string[]
---@return Ribbon|nil self
function M:prepend(background, foreground, text, attributes)
  return M.add(self, "prepend", background, foreground, text, attributes)
end

---Append raw `wezterm.format` items.
---@param items table|string|nil FormatItem or FormatItem[].
---@return Ribbon self
function M:append_items(items)
  insert_format_items(self.layout, items, false)
  return self
end

---Prepend raw `wezterm.format` items.
---@param items table|string|nil FormatItem or FormatItem[].
---@return Ribbon self
function M:prepend_items(items)
  insert_format_items(self.layout, items, true)
  return self
end

---Clear all elements from the ribbon.
---@return Ribbon self
function M:clear()
  self.layout = {}
  return self
end

---Append a reset-attributes marker.
---@return nil
function M:reset_attributes()
  tinsert(self.layout, "ResetAttributes")
end

---Render the ribbon with `wezterm.format`.
---@return string
function M:format()
  return wezterm.format(self.layout)
end

---Log the ribbon to the debug console.
---@param formatted boolean Log the formatted string when true, or the raw table when false.
---@return nil
function M:debug(formatted)
  self.log:info(self.name .. " formatted: %s", formatted and self:format() or self.layout)
end

---Return the raw format-item table. Useful for tests and advanced callers.
---@return table
function M:items()
  return self.layout
end

return M
