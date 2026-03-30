---@module "warp.table"

local floor = math.floor
local sort = table.sort
local type, next, pairs, select = type, next, pairs, select
local setmetatable, getmetatable = setmetatable, getmetatable

---@class Warp.Table
local M = {}

---Check if a list has no array elements.
---
---Returns `true` when `tbl` is `nil` or its length is `0`.
---Hash-only entries are ignored; use
---[isblank](lua://Warp.Table.isblank) to test for a completely
---empty table.
---
---@param tbl table|nil List to check.
---@return boolean
M.isempty = function(tbl)
  return tbl == nil or #tbl == 0
end

---Check if a table has no entries (array or hash).
---
---Returns `true` when `tbl` is `nil` or `next(tbl)` is `nil`,
---meaning no array or hash-map keys exist.
---
---@param tbl table|nil Table to check.
---@return boolean
M.isblank = function(tbl)
  return tbl == nil or next(tbl) == nil
end

---Check if a table is a contiguous integer-indexed list.
---
---Returns `true` when every key in `tbl` is a consecutive integer
---from `1` to `#tbl` with no gaps or extra hash keys. An empty
---table (`{}`) is considered a valid list. Returns `false` for
---non-table values.
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

---Check if a table is indexed only by integers.
---
---Returns `true` when every key in `tbl` is an integer (positive,
---negative, or zero), even if there are gaps. An empty table (`{}`)
---is considered a valid array. Returns `false` for non-table values.
---Use [islist](lua://Warp.Table.islist) to test for a contiguous
---1-based sequence.
---
---@param tbl any Value to check.
---@return boolean
M.isarray = function(tbl)
  if type(tbl) ~= "table" then
    return false
  end
  for k in pairs(tbl) do
    if type(k) ~= "number" or k ~= floor(k) then
      return false
    end
  end
  return true
end

---Shallow copy of a table.
---
---Creates a new table with the same key-value pairs. Nested tables
---are not cloned — they share the same reference. Non-table values
---are returned as-is. Metatables are not copied.
---
---@param obj any Value to copy. Non-tables are returned as-is.
---@return any copy Shallow copy if table, otherwise the original.
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
---Recursively copies all nested tables, producing a fully
---independent clone. Metatables are preserved on every level.
---Non-table values are returned as-is.
---
---When `noref` is `false` (default) each table is copied at most
---once and circular references are handled — all references to the
---same source table point to one copy. When `noref` is `true` every
---occurrence produces a new copy, which is faster for tables with
---many unique sub-tables but will loop infinitely on cyclic
---structures.
---
---@param obj   any         Value to deep copy. Non-tables returned as-is.
---@param noref boolean|nil Skip reference tracking when `true`.
---@return any  copy        Deep copy if table, otherwise the original.
M.deepcopy = function(obj, noref)
  if type(obj) ~= "table" then
    return obj
  end
  local cache = not noref and {} or nil
  local function _copy(t)
    if type(t) ~= "table" then
      return t
    end
    if cache and cache[t] then
      return cache[t]
    end
    local copy = {}
    if cache then
      cache[t] = copy
    end
    for k, v in pairs(t) do
      copy[k] = _copy(v)
    end
    return setmetatable(copy, getmetatable(t))
  end
  return _copy(obj)
end

---Return all keys of a table.
---
---Creates a new list containing every key from `tbl`. The order is
---not guaranteed (follows `pairs()` traversal). Works on both
---list-like and hash tables.
---
---@generic K
---@param tbl table<K, any> Table to extract keys from.
---@return K[]              keys List of all keys.
M.keys = function(tbl)
  local keys = {}
  local n = 0
  for k in pairs(tbl) do
    n = n + 1
    keys[n] = k
  end
  return keys
end

---Return all values of a table.
---
---Creates a new list containing every value from `tbl`. The order
---is not guaranteed (follows `pairs()` traversal). Works on both
---list-like and hash tables.
---
---@generic V
---@param tbl table<any, V> Table to extract values from.
---@return V[]              values List of all values.
M.values = function(tbl)
  local values = {}
  local n = 0
  for _, v in pairs(tbl) do
    n = n + 1
    values[n] = v
  end
  return values
end

---Apply a function to every value of a table.
---
---Creates a new table where each value is the result of calling
---`fn` on the corresponding value in `tbl`. Keys are preserved.
---Iteration follows `pairs()` order (not guaranteed to be stable).
---
---@generic K, V
---@param tbl table<K, V>         Table to transform.
---@param fn  fun(value: V): any  Mapping function.
---@return table<K, any>          result Transformed table.
M.map = function(tbl, fn)
  local result = {}
  for k, v in pairs(tbl) do
    result[k] = fn(v)
  end
  return result
end

---Filter a table using a predicate function.
---
---Creates a new list containing only the values for which `fn`
---returns a truthy value. Keys are discarded — the result is
---always a flat list. Iteration follows `pairs()` order (not
---guaranteed to be stable).
---
---@generic V
---@param tbl table<any, V>            Table to filter.
---@param fn  fun(value: V): boolean   Predicate function.
---@return V[]                         result Filtered values.
M.filter = function(tbl, fn)
  local result = {}
  local n = 0
  for _, v in pairs(tbl) do
    if fn(v) then
      n = n + 1
      result[n] = v
    end
  end
  return result
end

---Check if a table contains a given value.
---
---Scans all values via `pairs()`. Comparison uses raw equality
---(`==`). When `opts.predicate` is `true`, `value` is treated as
---a predicate function that receives each table value and should
---return `true` for a match. Use
---[list.contains](lua://Warp.List.contains) for a faster check on
---list-like tables.
---
---@param tbl   table                        Table to search.
---@param value any                          Value to find, or predicate.
---@param opts  { predicate?: boolean }|nil  Options.
---@return boolean `true` if `tbl` contains a matching value.
M.contains = function(tbl, value, opts)
  if opts and opts.predicate then
    for _, v in pairs(tbl) do
      if value(v) then
        return true
      end
    end
  else
    for _, v in pairs(tbl) do
      if v == value then
        return true
      end
    end
  end
  return false
end

---Count all entries in a table.
---
---Returns the total number of key-value pairs (array and hash).
---For list-like tables the result equals `#tbl`; for mixed or hash
---tables it includes all keys.
---
---@param tbl table   Table to count.
---@return integer    count Number of entries.
M.count = function(tbl)
  local count = 0
  for _ in pairs(tbl) do
    count = count + 1
  end
  return count
end

---Deep compare two values for equality.
---
---Tables are compared recursively: two tables are equal when they
---have the same set of keys and every corresponding pair of values
---is deeply equal. Reference-equal values (`a == b`) short-circuit
---immediately, which also respects any `__eq` metamethod. All
---other types are compared with `==`.
---
---@param a any First value.
---@param b any Second value.
---@return boolean `true` if the values are deeply equal.
local function deep_equal(a, b)
  if a == b then
    return true
  end
  if type(a) ~= type(b) then
    return false
  end
  if type(a) == "table" then
    for k, v in pairs(a) do
      if not deep_equal(v, b[k]) then
        return false
      end
    end
    for k in pairs(b) do
      if a[k] == nil then
        return false
      end
    end
    return true
  end
  return false
end
M.deep_equal = deep_equal

---Index into a table via successive keys.
---
---Traverses nested tables by indexing with each key in order.
---Returns `nil` if any intermediate key is missing or leads to a
---non-table value before the final key.
---
---```lua
---M.get({ key = { nested = true } }, "key", "nested")
----- true
---M.get({ key = {} }, "key", "nested")
----- nil
---```
---
---@param tbl table      Table to index.
---@param ... any        Keys to traverse (one or more).
---@return any|nil value Nested value, or `nil` if not found.
M.get = function(tbl, ...)
  local nargs = select("#", ...)
  if nargs == 0 then
    return nil
  end
  local o = tbl
  for i = 1, nargs do
    o = o[select(i, ...)]
    if o == nil then
      return nil
    elseif type(o) ~= "table" and i ~= nargs then
      return nil
    end
  end
  return o
end

---Check if a value is a non-list table eligible for recursive
---merging. Returns `true` for empty tables and hash-like tables;
---returns `false` for list-like tables and non-table values.
---
---@param v any Value to check.
---@return boolean
local function can_merge(v)
  return type(v) == "table" and (next(v) == nil or not M.islist(v))
end

---@alias Warp.Table.MergeBehavior "error"|"keep"|"force"

---Recursive worker for [extend](lua://Warp.Table.extend) and
---[deep_extend](lua://Warp.Table.deep_extend).
---
---Iterates each source table and merges key-value pairs into a
---new table. When `deep` is `true`, non-list sub-tables are
---merged recursively via
---[can_merge](lua://can_merge).
---
---@param behavior Warp.Table.MergeBehavior Conflict strategy.
---@param deep     boolean                  Recurse into sub-tables.
---@param ...      table                    Source tables.
---@return table
local function tbl_extend_rec(behavior, deep, ...)
  local ret = {}
  for i = 1, select("#", ...) do
    local tbl = select(i, ...)
    if tbl then
      for k, v in pairs(tbl) do
        if deep and can_merge(v) and can_merge(ret[k]) then
          ret[k] = tbl_extend_rec(behavior, true, ret[k], v)
        elseif behavior ~= "force" and ret[k] ~= nil then
          if behavior == "error" then
            error("key found in more than one map: " .. k)
          end
        else
          ret[k] = v
        end
      end
    end
  end
  return ret
end

---Merge two or more tables.
---
---Returns a new table built by iterating every key-value pair from
---each source table in order. The `behavior` parameter controls
---what happens when a key appears in more than one table:
---
---- `"error"` — raise an error.
---- `"keep"` — use the value from the leftmost table.
---- `"force"` — use the value from the rightmost table.
---
---@param behavior Warp.Table.MergeBehavior Conflict strategy.
---@param ...      table Two or more tables to merge.
---@return table   merged Merged table.
M.extend = function(behavior, ...)
  return tbl_extend_rec(behavior, false, ...)
end

---Recursively merge two or more tables.
---
---Behaves like [extend](lua://Warp.Table.extend) but recursively
---merges values that are non-list tables. List-like tables and
---non-table values are overwritten according to `behavior`, not
---merged. This is useful for combining nested configuration tables
---where lists should be treated as atomic values.
---
---@param behavior Warp.Table.MergeBehavior Conflict strategy.
---@param ...      table Two or more tables to merge.
---@return table   merged Recursively merged table.
M.deep_extend = function(behavior, ...)
  return tbl_extend_rec(behavior, true, ...)
end

---Swap keys and values of a table.
---
---Creates a new table where each value becomes a key and
---its former key becomes the value. When multiple keys share
---the same value, one of them wins arbitrarily.
---
---@generic K, V
---@param tbl table<K, V> Table to invert.
---@return table<V, K>    inverted Inverted table.
M.invert = function(tbl)
  local result = {}
  for k, v in pairs(tbl) do
    result[v] = k
  end
  return result
end

---Fold a table into a single value.
---
---Iterates all entries via `pairs()` and accumulates a result
---by calling `fn(acc, value, key)` for each entry. The order
---is not guaranteed (follows `pairs()` traversal).
---
---@generic V, R
---@param tbl  table<any, V>                  Table to reduce.
---@param fn   fun(acc: R, value: V, key: any): R Reducer.
---@param init R                              Initial accumulator.
---@return R   result Final accumulated value.
M.reduce = function(tbl, fn, init)
  local acc = init
  for k, v in pairs(tbl) do
    acc = fn(acc, v, k)
  end
  return acc
end

---Iterate key-value pairs in sorted key order.
---
---Returns an iterator suitable for `for`-`in` loops. Keys are
---collected, sorted with `table.sort`, and yielded in ascending
---order. Only works correctly when all keys are of the same
---comparable type (typically strings or numbers).
---
---@generic K, V
---@param tbl table<K, V>          Table to iterate.
---@return fun(): K|nil, V|nil     iterator Sorted key-value iterator.
M.spairs = function(tbl)
  local keys = {}
  local n = 0
  for k in pairs(tbl) do
    n = n + 1
    keys[n] = k
  end
  sort(keys)
  local i = 0
  return function()
    i = i + 1
    local k = keys[i]
    if k ~= nil then
      return k, tbl[k]
    end
  end
end

return M
