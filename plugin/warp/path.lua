---@module "warp.path"

---@class Wezterm
local wt = require "wezterm"--[[@as Wezterm]]

---@class Memo.Api
local memo = wt.plugin.require "https://github.com/sravioli/memo.wz"
memo.cache.configure { ttl = nil, stats = false, debug = false }
local cache = memo.cache.namespace "warp.path" ---@class Memo.Cache

---@class Warp.Path
local M = {}

cache.set("separator", M.is_win and "\\" or "/")
M.separator = cache.get "separator"

---Abbreviate path by shortening intermediate components to specified length.
---
---@param path string File or directory path.
---@param len integer  Number of characters to keep per component.
---@return string shortened Abbreviated path.
M.shorten = function(path, len)
  return cache.compute("shorten", function()
    local sep = M.separator
    local root_path = path:sub(1, 1) == sep
    if root_path then
      path = path:sub(2)
    end

    local parts = str.split(path, sep)
    local last = #parts
    local result = {}

    for i = 1, last do
      local part = parts[i]
      if i == last then
        result[i] = part
      else
        local short = string.sub(part, 1, len)
        if short == "" then
          break
        end
        result[i] = short
      end
    end

    local short_path = table.concat(result, sep)
    if root_path then
      short_path = sep .. short_path
    end
    return short_path
  end, path, len)
end

--- Keep n chars from each end with an ellipsis in the middle.
--- n is always the largest value that fits the budget, maximising readability.
---
---@param s      string
---@param budget integer  available columns
---@return string
local function truncate_middle(s, budget)
  if str.column_width(s) <= budget then
    return s
  end

  local ellipsis = "…"
  local ew = str.column_width(ellipsis)
  if budget <= ew then
    return ellipsis
  end

  local remaining = budget - ew
  local left_n = math.ceil(remaining / 2)
  local right_n = math.floor(remaining / 2)

  local left = wt.truncate_right(s, left_n)

  -- Collect codepoints so we can take exactly right_n columns from the end
  local cps = {}
  for cp in s:gmatch "[^\128-\191][\128-\191]*" do
    cps[#cps + 1] = cp
  end

  local right_parts, w = {}, 0
  for i = #cps, 1, -1 do
    local cpw = wt.column_width(cps[i])
    if w + cpw > right_n then
      break
    end
    table.insert(right_parts, 1, cps[i])
    w = w + cpw
  end

  return left .. ellipsis .. table.concat(right_parts)
end

M.shorten_to = function(path, max_len)
  local sep = M.separator
  path = path:gsub("/+$", "")

  local last = path:match "([^/]+)$" or path
  local last_w = str.column_width(last)
  local prefix = path:sub(1, -(#last + 1)) -- everything up to and including the final sep

  local _, sep_count = path:gsub(sep, "")
  local is_rooted = path:sub(1, 1) == sep
  local dir_count = is_rooted and (sep_count - 1) or sep_count
  local sep_w = sep_count * str.column_width(sep)

  -- No directory prefix: middle-truncate the bare name
  if dir_count <= 0 then
    return truncate_middle(last, max_len)
  end

  -- Happy path: last component fits in full; shorten dir components as needed
  local dir_budget = max_len - sep_w - last_w
  if dir_budget >= dir_count then -- at least 1 col per dir component
    local per = math.floor(dir_budget / dir_count)
    return M.shorten(path, per)
  end

  -- Dirs at minimum (1 char each); give the rest to the last component via
  -- middle-truncation so the path shape is preserved and stays readable.
  local last_budget = math.max(3, max_len - sep_w - dir_count)
  local truncated_last = truncate_middle(last, last_budget)
  return M.shorten(prefix .. truncated_last, 1)
end

---Concatenate path components.
---
---Joins arguments using the platform-specific path separator.
---
---@param ... string Path components to join.
---@return string path Joined path string.
M.concat = function(...)
  return table.concat({ ... }, M.separator)
end

return M
