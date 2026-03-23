---@module "warp.tbl"

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
  local n = #tbl
  if n == 0 then
    return next(tbl) == nil
  end
  for i = 1, n do
    if tbl[i] == nil then
      return false
    end
  end
  return next(tbl, n) == nil
end

---Shallow copy of a table.
---
---Creates a new table with the same key-value pairs. Nested tables are not cloned —
---they share the same reference. Non-table values are returned as-is. Metatables are
---not copied.
---
---@param obj any Value to copy. Non-tables are returned as-is.
---@return any copy Shallow copy if table, otherwise the original value.
M.copy = function(obj)
  if type(obj) ~= "table" then
    return obj
  end
  local copy = {}
  for k, v in pairs(obj) do
    copy[k] = v
  end
  return copy
end

---Deep copy of a table.
---
---Recursively copies all nested tables, producing a fully independent clone. Circular
---references are handled; each table is copied at most once. Metatables are preserved
---on every level. Non-table values are returned as-is.
---
---@param obj any Value to deep copy. Non-tables are returned as-is.
---@return any copy Deep copy if table, otherwise the original value.
M.deepcopy = function(obj)
  if type(obj) ~= "table" then
    return obj
  end
  local seen = {}
  local function _copy(t)
    if type(t) ~= "table" then
      return t
    end
    if seen[t] then
      return seen[t]
    end
    local copy = {}
    seen[t] = copy
    for k, v in pairs(t) do
      copy[k] = _copy(v)
    end
    return setmetatable(copy, getmetatable(t))
  end
  return _copy(obj)
end

---Compute Cartesian product of multiple tables (iterator).
---
---Returns an iterator yielding each combination as a shared table. The returned table
---is reused between iterations; copy it if you need to store or mutate individual
---results.
---
---```lua
---for i, combo in M.cartesian_iter({ { 1, 2 }, { "a", "b" } }) do
---  print(i, combo[1], combo[2])
---end
----- 1  1  a
----- 2  1  b
----- 3  2  a
----- 4  2  b
---```
---
---@param sets table Table containing sub-tables (sets) for the product calculation.
---@return function iterator Iterator returning (index, combination).
M.cartesian_iter = function(sets)
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
    end

    if combination_index > 0 then
      indices[set_count] = indices[set_count] + 1

      for set_index = set_count, 1, -1 do
        local set = sets[set_index]
        local index = indices[set_index]
        if index <= item_counts[set_index] then
          results[set_index] = set[index]
          break
        else
          results[set_index] = set[1]
          indices[set_index] = 1
          if set_index > 1 then
            indices[set_index - 1] = indices[set_index - 1] + 1
          end
        end
      end
    end

    combination_index = combination_index + 1
    return combination_index, results
  end
end

---Compute Cartesian product of multiple tables (copying iterator).
---
---Wraps [cartesian_iter](lua://Warp.Table.cartesian_iter), copying each yielded
---combination into a fresh table that the caller can safely store or mutate.
---
---@param sets table Table containing sub-tables (sets) for the product calculation.
---@return function iterator Iterator returning (index, combination).
M.cartesian_iter_copy = function(sets)
  local iter = M.cartesian_iter(sets)
  local set_count = #sets
  return function()
    local i, results = iter()
    if not i then
      return
    end
    local copy = {}
    for j = 1, set_count do
      copy[j] = results[j]
    end
    return i, copy
  end
end

---Compute Cartesian product of multiple tables.
---
---Collects all combinations from
---[cartesian_iter_copy](lua://Warp.Table.cartesian_iter_copy) into a single table. Each
---entry is an independent table that can be safely stored or mutated.
---
---@param sets table Table containing sub-tables (sets) for the product calculation.
---@return table combinations Table of all combinations.
M.cartesian = function(sets)
  local out = {}
  for _, combo in M.cartesian_iter_copy(sets) do
    out[#out + 1] = combo
  end
  return out
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
