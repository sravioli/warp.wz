---@module "warp.path"

---@class Wezterm
local wt = require "wezterm"--[[@as Wezterm]]

local fs = require "warp.filesystem" --[[@as Warp.FileSystem]]
local str = require "warp.string" --[[@as Warp.String]]

local col_width = str.col_width
local str_split = str.split
local wt_truncate_right = wt.truncate_right

local str_byte, str_find, str_gmatch, str_sub, str_match, str_gsub =
  string.byte, string.find, string.gmatch, string.sub, string.match, string.gsub
local tbl_concat = table.concat
local ceil, floor, max = math.ceil, math.floor, math.max

---@class Warp.Path
local M = {}

---Whether the current platform is Windows.
---@type boolean
M.is_win = fs.is_win

---Platform-specific path separator (`\` on Windows, `/` elsewhere).
---@type string
M.separator = M.is_win and "\\" or "/"

---Normalize a path.
---
---Collapses `.`, `..`, and repeated separators. Converts backslashes
---to forward slashes. Preserves a leading `~` and trailing separator
---only when the path is root (`/`).
---
---@param path string File or directory path.
---@return string normalized Normalized path.
M.normalize = function(path)
  path = str_gsub(path, "\\", "/")
  path = str_gsub(path, "/+", "/")

  -- Preserve leading ~
  local tilde = false
  if str_sub(path, 1, 2) == "~/" or path == "~" then
    tilde = true
    path = str_sub(path, 2) -- strip ~, keep /...
  end

  local parts = str_split(path, "/")
  local stack = {}
  local n = 0
  local is_abs = str_sub(path, 1, 1) == "/"

  for i = 1, #parts do
    local p = parts[i]
    if p == ".." then
      if n > 0 and stack[n] ~= ".." then
        stack[n] = nil
        n = n - 1
      elseif not is_abs then
        n = n + 1
        stack[n] = p
      end
    elseif p ~= "." and p ~= "" then
      n = n + 1
      stack[n] = p
    end
  end

  local result = tbl_concat(stack, "/")
  if is_abs then
    result = "/" .. result
  end
  if tilde then
    -- Avoid "~/" for bare tilde
    if result == "/" then
      result = "~"
    else
      result = "~" .. result
    end
  end
  if result == "" then
    return "."
  end
  return result
end

---Return the parent directory of a path.
---
---@param path string File or directory path.
---@return string dirname Parent directory, or `.` if none.
M.dirname = function(path)
  path = str_gsub(path, "\\", "/")
  -- Root path (one or more slashes only)
  if str_match(path, "^/+$") then
    return "/"
  end
  path = str_gsub(path, "/+$", "")
  if path == "" then
    return "."
  end
  local parent = str_match(path, "^(.+)/[^/]*$")
  if not parent then
    -- No slash found — check for root
    if str_sub(path, 1, 1) == "/" then
      return "/"
    end
    return "."
  end
  -- Avoid returning empty string for paths like "/foo"
  if parent == "" then
    return "/"
  end
  return parent
end

---Return the file extension including the leading dot.
---
---Returns an empty string when no extension is found.
---
---@param path string File path.
---@return string extension Extension (e.g. `.lua`), or `""`.
M.extension = function(path)
  local base = str_match(path, "([^/\\]*)$") or path
  -- Dotfiles without further extension (e.g. ".gitignore") have no extension.
  local ext = str_match(base, ".(%.[^.]+)$")
  return ext or ""
end

---Check whether a path is absolute.
---
---@param path string File or directory path.
---@return boolean
M.is_absolute = function(path)
  if str_sub(path, 1, 1) == "/" then
    return true
  end
  -- Windows drive letter: C:\ or C:/
  local b = str_byte(path, 1)
  if b and ((b >= 65 and b <= 90) or (b >= 97 and b <= 122)) then
    if str_sub(path, 2, 2) == ":" then
      local third = str_sub(path, 3, 3)
      return third == "/" or third == "\\"
    end
  end
  return false
end

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
---@param s      string  Input string.
---@param budget integer Available columns.
---@return string truncated Truncated string with ellipsis.
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
  local cp_count = 0
  for cp in str_gmatch(s, "[^\128-\191][\128-\191]*") do
    cp_count = cp_count + 1
    cps[cp_count] = cp
  end

  -- Find start index for rightmost `right_n` columns (avoids table.insert prepend)
  local start_idx = cp_count + 1
  local w = 0
  for i = cp_count, 1, -1 do
    local cpw = col_width(cps[i])
    if w + cpw > right_n then
      break
    end
    start_idx = i
    w = w + cpw
  end

  return left .. ellipsis .. tbl_concat(cps, "", start_idx, cp_count)
end

--- Count occurrences of a literal substring using string.find (JIT-friendly).
---@param s   string  Haystack.
---@param sub string  Needle to count.
---@return integer count Number of occurrences.
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

---Expand `~` prefix to the user home directory.
---
---Requires the filesystem module to resolve the home path. Only
---expands a leading `~` followed by `/`, `\`, or end-of-string.
---
---@param path string File or directory path.
---@return string expanded Path with `~` replaced by the home directory.
M.expand = function(path)
  if str_sub(path, 1, 1) ~= "~" then
    return path
  end
  local second = str_sub(path, 2, 2)
  if second ~= "" and second ~= "/" and second ~= "\\" then
    return path
  end
  return fs.home .. str_sub(path, 2)
end

return M
