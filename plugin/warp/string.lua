---@module "warp.string"

---@class Wezterm
local wt = require "wezterm" --[[@as Wezterm]]

local str_find, str_gmatch, str_gsub, str_sub, str_rep =
  string.find, string.gmatch, string.gsub, string.sub, string.rep
local tbl_remove, table_concat = table.remove, table.concat
local ceil, floor = math.ceil, math.floor
local huge = math.huge

local maths = require "warp.maths" --[[@as Warp.Maths]]
local clamp = maths.clamp

local col_width = wt.column_width

---@class Warp.String
local M = {}

---Empty string constant.
---@type string
M.empty = ""

---Single space constant.
---@type string
M.space = " "

---Alias for `wezterm.column_width`.
---@type fun(s: string): integer
M.col_width = col_width

---Strip ANSI/VT escape sequences from a string.
---
---@param s string Raw rendered string, may contain ANSI codes.
---@return string s String with ANSI sequences removed.
local function strip_ansi(s)
  return (str_gsub(s, "\27%[[\32-\63]*[\64-\126]", ""))
end
M.strip_ansi = strip_ansi

---Calculate visible string width.
---
---Strips any ANSI escape sequences (otherwise they would
---contribute to the width) and then calls the WezTerm
---internal `column_width()` function.
---
---@param s string Input string.
---@return number column_width Visible column width.
local function width(s)
  -- Fast path: no ESC byte means no ANSI codes to strip
  if not str_find(s, "\27", 1, true) then
    return col_width(s)
  end
  return col_width(strip_ansi(s))
end
M.width = width

---@alias Warp.String.Padding
---| (integer|{ left: integer|nil, right: integer|nil })

---Clamp a single padding value to `[0, huge]`.
---
---@param pad number Padding value.
---@return number pad Clamped value.
local function clamp_pad(pad)
  return clamp(pad, 0, huge)
end

---Normalize padding into left/right integers (>= 0).
---
---@param padding Warp.String.Padding|nil Padding spec.
---@return integer left  Left padding.
---@return integer right Right padding.
local function compute_padding(padding)
  if padding == nil then
    return 1, 1
  end

  local typ = type(padding)
  if typ == "number" then
    local n = clamp_pad(padding)
    return n, n
  elseif typ == "table" then
    local left = padding.left ~= nil and clamp_pad(padding.left) or 0
    local right = padding.right ~= nil and clamp_pad(padding.right) or 0
    return left, right
  end

  return 1, 1
end

---Pad string on both sides.
---
---Converts input to string if necessary and adds
---whitespace to both sides. Adds a single whitespace by
---default but respects `nil` values when `padding` is a
---table (e.g. `{ left = 1, right = nil }` won't add any
---right padding).
---
---@param s       string|any              Input value to pad.
---@param padding Warp.String.Padding|nil Spaces to add per side. Defaults to `1`.
---@param ch      string|nil              Char to use when padding. Defaults to `" "`
---@return string padded Resulting padded string.
function M.pad(s, padding, ch)
  s = type(s) == "string" and s or tostring(s)
  local l, r = compute_padding(padding)

  local left = l > 0 and str_rep(ch or M.space, l) or M.empty
  local right = r > 0 and str_rep(ch or M.space, r) or M.empty
  return left .. s .. right
end

---Pad string on left side.
---
---@param s       string|any  Input value to pad.
---@param padding integer|nil Spaces to add. Defaults to `1`
---@param ch      string|nil  Char to use when padding. Defaults to `" "`
---@return string padded Resulting left-padded string.
M.padl = function(s, padding, ch)
  return M.pad(s, { left = padding or 1, right = nil }, ch)
end

---Pad string on right side.
---
---@param s       string|any  Input value to pad.
---@param padding integer|nil Spaces to add. Defaults to `1`
---@param ch      string|nil  Char to use when padding. Defaults to `" "`
---@return string padded Resulting right-padded string.
M.padr = function(s, padding, ch)
  return M.pad(s, { left = nil, right = padding or 1 }, ch)
end

---Remove leading and trailing whitespace.
---
---@param s string Input string.
---@return string trimmed Trimmed string.
M.trim = function(s)
  return (str_gsub(s, "^%s*(.-)%s*$", "%1"))
end

---@class SplitOpts
---@field plain?     boolean|nil If `true`, treat `sep` as plain text.
---@field trimempty? boolean|nil If `true`, trim empty edge segments.

---Iterate over substrings separated by pattern.
---
---Returns an iterator yielding substrings from input `s`
---separated by `sep`.
---
---@param s    string        Input string to split.
---@param sep  string        Separator pattern.
---@param opts SplitOpts|nil Optional splitting behavior.
---@return fun(): string|nil iterator
M.gsplit = function(s, sep, opts)
  local plain, trimempty
  opts = opts or {}
  plain, trimempty = opts.plain, opts.trimempty

  local start = 1
  local done = false

  -- For `trimempty`: queue of collected segments, to be emitted at next pass.
  local segs = {}
  local empty_start = true -- Only empty segments seen so far.

  local function _pass(i, j, ...)
    if i then
      assert(j + 1 > start, "Infinite loop detected")
      local seg = str_sub(s, start, i - 1)
      start = j + 1
      return seg, ...
    else
      done = true
      return str_sub(s, start)
    end
  end

  return function()
    if trimempty and #segs > 0 then
      -- trimempty: Pop the collected segments.
      return tbl_remove(segs)
    elseif done or (s == "" and sep == "") then
      return nil
    elseif sep == "" then
      if start == #s then
        done = true
      end
      return _pass(start + 1, start)
    end

    local seg = _pass(str_find(s, sep, start, plain))

    -- Trim empty segments from start/end.
    if trimempty and seg ~= "" then
      empty_start = false
    elseif trimempty and seg == "" then
      while not done and seg == "" do
        segs[1] = ""
        seg = _pass(str_find(s, sep, start, plain))
      end
      if done and seg == "" then
        return nil
      elseif empty_start then
        empty_start = false
        segs = {}
        return seg
      end
      if seg ~= "" then
        segs[1] = seg
      end
      return tbl_remove(segs)
    end

    return seg
  end
end

---Split string into list of substrings.
---
---Uses `gsplit` internally.
---
---@param s    string        Input string to split.
---@param sep  string        Separator pattern.
---@param opts SplitOpts|nil Optional splitting behavior.
---@return string[] parts    List of substrings.
M.split = function(s, sep, opts)
  local t = {}
  local n = 0
  for c in M.gsplit(s, sep, opts) do
    n = n + 1
    t[n] = c
  end
  return t
end

local ELLIPSIS = "…"
local ELLIPSIS_W = width(ELLIPSIS)

--- Take up to `budget` visible columns from the *left* of `s`.
--- No ellipsis is added.
---@param s      string  Input string.
---@param budget integer Available column budget.
---@return string left    Left portion of input.
---@return integer width  Columns consumed.
local function take_left(s, budget)
  local parts, n, w = {}, 0, 0
  for cp in str_gmatch(s, "[^\128-\191][\128-\191]*") do
    local cpw = width(cp)
    if w + cpw > budget then
      break
    end
    n = n + 1
    parts[n] = cp
    w = w + cpw
  end
  return table_concat(parts), w
end

--- Take up to `budget` visible columns from the *right* of `s`.
--- No ellipsis is added.
---@param s      string  Input string.
---@param budget integer Available column budget.
---@return string right   Right portion of input.
---@return integer width  Columns consumed.
local function take_right(s, budget)
  local cps = {}
  local cp_count = 0
  for cp in str_gmatch(s, "[^\128-\191][\128-\191]*") do
    cp_count = cp_count + 1
    cps[cp_count] = cp
  end

  local start_idx = cp_count + 1
  local w = 0
  for i = cp_count, 1, -1 do
    local cpw = width(cps[i])
    if w + cpw > budget then
      break
    end
    start_idx = i
    w = w + cpw
  end
  return table_concat(cps, "", start_idx, cp_count), w
end

---Return whether `s` already fits within `budget` visible columns.
---
---@param  s      string
---@param  budget integer
---@return boolean
M.fits = function(s, budget)
  return width(s) <= budget
end

---Truncate from the **right**, appending an ellipsis.
---`"plasma-csd-generator.rebupk"` → `"plasma-csd-gen…"`
---
---@param s      string  Input string.
---@param budget integer Total columns available (including the ellipsis).
---@return string truncated Truncated string.
M.truncate_right = function(s, budget)
  if M.fits(s, budget) then
    return s
  end
  if budget <= ELLIPSIS_W then
    return ELLIPSIS
  end
  return take_left(s, budget - ELLIPSIS_W) .. ELLIPSIS
end

---Truncate from the **left**, prepending an ellipsis.
---`"plasma-csd-generator.rebupk"` → `"…ator.rebupk"`
---
---@param s      string  Input string.
---@param budget integer Total columns available (including the ellipsis).
---@return string truncated Truncated string.
M.truncate_left = function(s, budget)
  if M.fits(s, budget) then
    return s
  end
  if budget <= ELLIPSIS_W then
    return ELLIPSIS
  end
  return ELLIPSIS .. take_right(s, budget - ELLIPSIS_W)
end

---Truncate from the **middle**, keeping both ends readable.
---The left side gets the extra column when the budget is odd.
---`"plasma-csd-generator.rebupk"` → `"plasma-c…rebupk"`
---
---@param s      string  Input string.
---@param budget integer Total columns available (including the ellipsis).
---@return string truncated Truncated string.
M.truncate_middle = function(s, budget)
  if M.fits(s, budget) then
    return s
  end
  if budget <= ELLIPSIS_W then
    return ELLIPSIS
  end

  local remaining = budget - ELLIPSIS_W
  local left_n = ceil(remaining / 2)
  local right_n = floor(remaining / 2)

  return take_left(s, left_n) .. ELLIPSIS .. take_right(s, right_n)
end

---@alias TruncateMode "left"|"middle"|"right"

---@type table<TruncateMode, fun(s: string, budget: integer): string>
local truncators = {
  left = M.truncate_left,
  middle = M.truncate_middle,
  right = M.truncate_right,
}

---Check whether `s` starts with the given prefix.
---
---@param s      string Input string.
---@param prefix string Prefix to test.
---@return boolean
M.starts_with = function(s, prefix)
  return str_sub(s, 1, #prefix) == prefix
end

---Check whether `s` ends with the given suffix.
---
---@param s      string Input string.
---@param suffix string Suffix to test.
---@return boolean
M.ends_with = function(s, suffix)
  if suffix == "" then
    return true
  end
  return str_sub(s, -#suffix) == suffix
end

---Left-justify `s` to a total visible width.
---
---Pads on the right so the result is at least `total_width`
---columns wide. If `s` already meets or exceeds the width,
---it is returned unchanged.
---
---@param s           string      Input string.
---@param total_width integer     Desired total column width.
---@param ch          string|nil  Padding character (default `" "`).
---@return string
M.ljust = function(s, total_width, ch)
  local w = width(s)
  if w >= total_width then
    return s
  end
  return s .. str_rep(ch or M.space, total_width - w)
end

---Right-justify `s` to a total visible width.
---
---Pads on the left so the result is at least `total_width`
---columns wide. If `s` already meets or exceeds the width,
---it is returned unchanged.
---
---@param s           string      Input string.
---@param total_width integer     Desired total column width.
---@param ch          string|nil  Padding character (default `" "`).
---@return string
M.rjust = function(s, total_width, ch)
  local w = width(s)
  if w >= total_width then
    return s
  end
  return str_rep(ch or M.space, total_width - w) .. s
end

---Truncate `s` to fit within `budget` columns using the
---specified strategy.
---
---@param mode   TruncateMode Truncation strategy.
---@param s      string       Input string.
---@param budget integer      Total columns available.
---@return string truncated   Truncated string.
M.truncate = function(mode, s, budget)
  local fn = truncators[mode]
  if not fn then
    error("invalid truncate mode: " .. tostring(mode), 2)
  end
  return fn(s, budget)
end

return M
