---@module "warp.tbl"

-- selene: allow(incorrect_standard_library_use)
local tbl_unpack = unpack or table.unpack

local co_yield, co_wrap = coroutine.yield, coroutine.wrap

---@class Warp.Table
local M = {}

---Check if a list has no array elements.
---
---Returns `true` when `tbl` is `nil` or its length is `0`. Hash-only entries are
---ignored; use [isblank](lua://Warp.Table.isblank) to test for a completely empty table.
---
---@param tbl table|nil List to check.
---@return boolean
M.isempty = function(tbl)
  return tbl == nil or #tbl == 0
end

---Check if a table has no entries (array or hash).
---
---Returns `true` when `tbl` is `nil` or `next(tbl)` is `nil`, meaning no array or
---hash-map keys exist.
---
---@param tbl table|nil Table to check.
---@return boolean
M.isblank = function(tbl)
  return tbl == nil or next(tbl) == nil
end

---Check if a table is a contiguous integer-indexed list.
---
---Returns `true` when every key in `tbl` is a consecutive integer from `1` to `#tbl`
---with no gaps or extra hash keys. An empty table (`{}`) is considered a valid list.
---Returns `false` for non-table values.
---
---@param tbl any Value to check.
---@return boolean
M.islist = function(tbl)
  if type(tbl) ~= "table" then
    return false
  end

  local count = 0
  for k in pairs(tbl) do
    if type(k) ~= "number" or k % 1 ~= 0 then
      return false
    end
    count = count + 1
  end
  return count > 0 and count == #tbl
end

---Compute Cartesian product of multiple tables.
---
---Returns table containing all possible combinations of elements from the input tables.
---
---@param sets table Table containing sub-tables (sets) for the product calculation.
---@return table cartesian Table of all possible combinations.
M.cartesian = function(sets)
  local res = { {} }
  for i = 1, #sets do
    local temp = {}
    for j = 1, #sets[i] do
      for k = 1, #res do
        temp[#temp + 1] = { sets[i][j], tbl_unpack(res[k]) }
      end
    end
    res = temp
  end
  return res
end

M.cartesian_product = function(sets)
  local item_counts = {}
  local indices = {}
  local results = {}
  local set_count = #sets
  local combination_count = 1

  for set_index = set_count, 1, -1 do
    local set = sets[set_index]
    local item_count = #set
    item_counts[set_index] = item_count
    indices[set_index] = 1
    results[set_index] = set[1]
    combination_count = combination_count * item_count
  end

  local combination_index = 0

  return function()
    if combination_index >= combination_count then
      return
    end -- no more output

    if combination_index == 0 then
      goto skip_update
    end -- skip first index update

    indices[set_count] = indices[set_count] + 1

    for set_index = set_count, 1, -1 do -- update index list
      local set = sets[set_index]
      local index = indices[set_index]
      if index <= item_counts[set_index] then
        results[set_index] = set[index]
        break -- no further update needed
      else -- propagate item_counts overflow
        results[set_index] = set[1]
        indices[set_index] = 1
        if set_index > 1 then
          indices[set_index - 1] = indices[set_index - 1] + 1
        end
      end
    end

    ::skip_update::

    combination_index = combination_index + 1
    return combination_index, results
  end
end

M.cartesian_async = function(sets)
  local result = {}
  local set_count = #sets
  local function descend(depth)
    if depth == set_count then
      for _, v in pairs(sets[depth]) do
        result[depth] = v
        co_yield(result)
      end
    else
      for _, v in pairs(sets[depth]) do
        result[depth] = v
        descend(depth + 1)
      end
    end
  end
  return co_wrap(function()
    descend(1)
  end)
end

---Reverse array elements of table.
---
---Creates a new table containing the array part of the input table in reverse order.
---
---@param tbl table Table to reverse.
---@return table reversed New table with reversed array elements.
M.reverse = function(tbl)
  local reversed = {}
  for i = #tbl, 1, -1 do
    reversed[#reversed + 1] = tbl[i]
  end
  return reversed
end

---Reverse array elements of a table in-place.
---
---Swaps elements from both ends toward the center. Only the array portion (`1` to
---`#tbl`) is affected; hash keys are untouched.
---
---@param tbl table Table to reverse.
---@return table tbl The same table, reversed.
M.reverse = function(tbl)
  local n = #tbl
  local m = n / 2
  for i = 1, m do
    tbl[i], tbl[n - i + 1] = tbl[n - i + 1], tbl[i]
  end
  return tbl
end

return M
