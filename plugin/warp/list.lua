---@module "warp.list"

local floor = math.floor

---@class Warp.List
local M = {}

---Check if a list contains a given value.
---
---Scans the array portion (`1` to `#list`) using a numeric `for`.
---Comparison uses raw equality (`==`). For general tables (hash
---keys, predicate matching) use
---[tbl.contains](lua://Warp.Table.contains).
---
---@generic T
---@param list  T[] List to search.
---@param value T   Value to find.
---@return boolean `true` if `list` contains `value`.
M.contains = function(list, value)
  local n = #list
  for i = 1, n do
    if list[i] == value then
      return true
    end
  end
  return false
end

---Append elements from one list into another in-place.
---
---Inserts elements from `src` (from index `start` to `finish`,
---inclusive) at the end of `dst`. Mutates and returns `dst`.
---
---@generic T: table
---@param dst    T           Destination list (modified in-place).
---@param src    table       Source list.
---@param start  integer|nil First index in `src` (default `1`).
---@param finish integer|nil Last index in `src` (default `#src`).
---@return T     dst         The destination list.
M.extend = function(dst, src, start, finish)
  local n = #dst
  for i = start or 1, finish or #src do
    n = n + 1
    dst[n] = src[i]
  end
  return dst
end

---Create a sub-list copy.
---
---Returns a new list containing elements from `start` to `finish`
---(inclusive). Does not modify the original list.
---
---@generic T
---@param list   T[]         Source list.
---@param start  integer|nil First index (default `1`).
---@param finish integer|nil Last index (default `#list`).
---@return T[]   slice       New list with the selected elements.
M.slice = function(list, start, finish)
  local new = {}
  local n = 0
  for i = start or 1, finish or #list do
    n = n + 1
    new[n] = list[i]
  end
  return new
end

---Remove duplicate values from a list in-place.
---
---Only the first occurrence of each value is kept. When `key` is
---provided it is called for each element to compute a hash key for
---uniqueness comparison. If `key` returns `nil` for a value, that
---value is always considered unique.
---
---```lua
---M.unique({ 1, 2, 2, 3, 1 })
----- { 1, 2, 3 }
---
---M.unique(
---  { { id = 1 }, { id = 2 }, { id = 1 } },
---  function(x) return x.id end
---)
----- { { id = 1 }, { id = 2 } }
---```
---
---@generic T
---@param list T[]             List to deduplicate (modified in-place).
---@param key? fun(x: T): any Optional uniqueness key function.
---@return T[] list            The same list, deduplicated.
M.unique = function(list, key)
  local seen = {}
  local n = #list
  local j = 1
  for i = 1, n do
    local v = list[i]
    local h = key and key(v) or v
    if not seen[h] then
      list[j] = v
      if h ~= nil then
        seen[h] = true
      end
      j = j + 1
    end
  end
  for i = j, n do
    list[i] = nil
  end
  return list
end

---Find the first position where `val` can be inserted.
---
---Returns index `i` such that `t[j] < val` for all `j < i` and
---`t[j] >= val` for all `j >= i`, or `hi` if no such index exists.
---
---@generic T
---@param t   T[]                    Sorted list.
---@param val T                      Value to search for.
---@param lo  integer                Start index (inclusive).
---@param hi  integer                End index (exclusive).
---@param key? fun(val: any): any    Map before comparison.
---@return integer
local function lower_bound(t, val, lo, hi, key)
  local val_key = key and key(val) or val
  while lo < hi do
    local mid = floor((lo + hi) / 2)
    local mid_key = key and key(t[mid]) or t[mid]
    if mid_key < val_key then
      lo = mid + 1
    else
      hi = mid
    end
  end
  return lo
end

---Find the last position where `val` can be inserted.
---
---Returns index `i` such that `t[j] <= val` for all `j < i` and
---`t[j] > val` for all `j >= i`, or `hi` if no such index exists.
---
---@generic T
---@param t   T[]                    Sorted list.
---@param val T                      Value to search for.
---@param lo  integer                Start index (inclusive).
---@param hi  integer                End index (exclusive).
---@param key? fun(val: any): any    Map before comparison.
---@return integer
local function upper_bound(t, val, lo, hi, key)
  local val_key = key and key(val) or val
  while lo < hi do
    local mid = floor((lo + hi) / 2)
    local mid_key = key and key(t[mid]) or t[mid]
    if val_key < mid_key then
      hi = mid
    else
      lo = mid + 1
    end
  end
  return lo
end

---@class Warp.List.BisectOpts
---@field lo?    integer              Start index (default `1`).
---@field hi?    integer              End index, exclusive (default `#list + 1`).
---@field key?   fun(val: any): any   Map each element before comparison.
---@field bound? "lower"|"upper"      Search variant (default `"lower"`).

---Binary search for an insertion point in a sorted list.
---
---Returns the index where `val` can be inserted while keeping
---`list` sorted. With `bound = "lower"` (default) returns the first
---valid position; with `bound = "upper"` returns the last valid
---position. Behavior is undefined on unsorted lists.
---
---```lua
---local t = { 1, 2, 2, 3, 3, 3 }
---M.bisect(t, 3)                        -- 4 (first position)
---M.bisect(t, 3, { bound = "upper" })   -- 7 (past last)
---```
---
---@generic T
---@param list T[]                    Sorted list.
---@param val  T                      Value to search for.
---@param opts? Warp.List.BisectOpts  Options.
---@return integer index              Insertion point.
M.bisect = function(list, val, opts)
  local lo, hi, key, bound
  if opts then
    lo = opts.lo
    hi = opts.hi
    key = opts.key
    bound = opts.bound
  end
  lo = lo or 1
  hi = hi or #list + 1
  if bound == "upper" then
    return upper_bound(list, val, lo, hi, key)
  end
  return lower_bound(list, val, lo, hi, key)
end

---Reverse list elements in-place.
---
---Swaps elements from both ends toward the center. Only the array
---portion (`1` to `#list`) is affected; hash keys are untouched.
---
---@generic T
---@param list T[] List to reverse.
---@return T[] list The same list, reversed.
M.reverse = function(list)
  local n = #list
  local m = n / 2
  for i = 1, m do
    list[i], list[n - i + 1] = list[n - i + 1], list[i]
  end
  return list
end

---Compute Cartesian product of multiple lists (iterator).
---
---Returns an iterator yielding each combination as a shared table.
---The returned table is reused between iterations; copy it if you
---need to store or mutate individual results.
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
---@param sets any[][] List of sub-lists for the product.
---@return fun(): integer|nil, any[]|nil iterator
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

---Compute Cartesian product of multiple lists (copying iterator).
---
---Wraps [cartesian_iter](lua://Warp.List.cartesian_iter), copying
---each yielded combination into a fresh table that the caller can
---safely store or mutate.
---
---@param sets any[][] List of sub-lists for the product.
---@return fun(): integer|nil, any[]|nil iterator
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

---Compute Cartesian product of multiple lists.
---
---Collects all combinations from
---[cartesian_iter_copy](lua://Warp.List.cartesian_iter_copy) into
---a single table. Each entry is an independent table that can be
---safely stored or mutated.
---
---@param sets any[][] List of sub-lists for the product.
---@return any[][] combinations All combinations.
M.cartesian = function(sets)
  local out = {}
  local n = 0
  for _, combo in M.cartesian_iter_copy(sets) do
    n = n + 1
    out[n] = combo
  end
  return out
end

return M
