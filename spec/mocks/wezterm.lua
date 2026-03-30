-- ---------------------------------------------------------------------------
-- spec/mocks/wezterm.lua — minimal wezterm mock for unit tests
-- ---------------------------------------------------------------------------

local M = {}

--- Naïve column_width: counts UTF-8 codepoints (each = 1 column).
--- Good enough for ASCII; CJK double-width is NOT emulated.
function M.column_width(s)
  local n = 0
  for _ in s:gmatch "[^\128-\191][\128-\191]*" do
    n = n + 1
  end
  return n
end

--- Mock truncate_right: take `budget` codepoints from the left.
function M.truncate_right(s, budget)
  local parts, w = {}, 0
  for cp in s:gmatch "[^\128-\191][\128-\191]*" do
    if w >= budget then
      break
    end
    parts[#parts + 1] = cp
    w = w + 1
  end
  return table.concat(parts)
end

return M
