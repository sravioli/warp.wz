---@module "warp.path"

---@class Wezterm
local wt = require "wezterm"--[[@as Wezterm]]

local str = require "warp.string" --[[@as Warp.String]]

local col_width = str.col_width
local str_split = str.split
local wt_truncate_right = wt.truncate_right

local str_find, str_sub, str_match, str_gsub =
  string.find, string.sub, string.match, string.gsub
local tbl_concat = table.concat
local ceil, floor, max = math.ceil, math.floor, math.max

---@class Warp.Path
local M = {}

M.is_win = str_find(wt.target_triple, "windows", 1, true) ~= nil
M.separator = M.is_win and "\\" or "/"

---Abbreviate path by shortening intermediate components to specified length.
---
---@param path string File or directory path.
---@param len integer  Number of characters to keep per component.
---@return string shortened Abbreviated path.
M.shorten = function(path, len)
  local sep = M.separator
  local root_path = str_sub(path, 1, 1) == sep
  if root_path then
    path = str_sub(path, 2)
  end

  local parts = str_split(path, sep)
  local last = #parts
  local result = {}

  for i = 1, last do
    local part = parts[i]
    if i == last then
      result[i] = part
    else
      local short = str_sub(part, 1, len)
      if short == "" then
        break
      end
      result[i] = short
    end
  end

  local short_path = tbl_concat(result, sep)
  if root_path then
    short_path = sep .. short_path
  end
  return short_path
end

---Keep characters from each end with an ellipsis in the
---middle. The amount kept per side is the largest value
---that fits the `budget`, maximising readability.
---
---@param s      string
---@param budget integer  Available columns.
---@return string
local function truncate_middle(s, budget)
  if col_width(s) <= budget then
    return s
  end

  local ellipsis = "…"
  local ew = col_width(ellipsis)
  if budget <= ew then
    return ellipsis
  end

  local remaining = budget - ew
  local left_n = ceil(remaining / 2)
  local right_n = floor(remaining / 2)

  local left = wt_truncate_right(s, left_n)

  -- Collect codepoints so we can take exactly right_n columns from the end
  local cps = {}
  for cp in s:gmatch "[^\128-\191][\128-\191]*" do
    cps[#cps + 1] = cp
  end

  -- Find start index for rightmost `right_n` columns (avoids table.insert prepend)
  local start_idx = #cps + 1
  local w = 0
  for i = #cps, 1, -1 do
    local cpw = col_width(cps[i])
    if w + cpw > right_n then
      break
    end
    start_idx = i
    w = w + cpw
  end

  return left .. ellipsis .. tbl_concat(cps, "", start_idx, #cps)
end

--- Count occurrences of a literal substring using string.find (JIT-friendly).
---@param s   string
---@param sub string
---@return integer
local function count_substr(s, sub)
  local n, pos = 0, 1
  while true do
    local i = str_find(s, sub, pos, true)
    if not i then
      return n
    end
    n = n + 1
    pos = i + 1
  end
end

---Shorten a path to fit within a visible column budget.
---
---Abbreviates intermediate directory components, and if
---the last component still doesn't fit, middle-truncates
---it. Preserves the general path shape for readability.
---
---@param path    string  File or directory path.
---@param max_len integer Maximum visible column width.
---@return string shortened Abbreviated path.
M.shorten_to = function(path, max_len)
  local sep = M.separator
  path = str_gsub(path, "/+$", "")

  local last = str_match(path, "([^/]+)$") or path
  local last_w = col_width(last)
  local prefix = str_sub(path, 1, -(#last + 1)) -- everything up to and including the final sep

  local sep_count = count_substr(path, sep)
  local is_rooted = str_sub(path, 1, 1) == sep
  local dir_count = is_rooted and (sep_count - 1) or sep_count
  local sep_w = sep_count * col_width(sep)

  -- No directory prefix: middle-truncate the bare name
  if dir_count <= 0 then
    return truncate_middle(last, max_len)
  end

  -- Happy path: last component fits in full; shorten dir components as needed
  local dir_budget = max_len - sep_w - last_w
  if dir_budget >= dir_count then -- at least 1 col per dir component
    local per = floor(dir_budget / dir_count)
    return M.shorten(path, per)
  end

  -- Dirs at minimum (1 char each); give the rest to the last component via
  -- middle-truncation so the path shape is preserved and stays readable.
  local last_budget = max(3, max_len - sep_w - dir_count)
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
  return tbl_concat({ ... }, M.separator)
end

return M
