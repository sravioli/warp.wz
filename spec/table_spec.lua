-- ---------------------------------------------------------------------------
-- Unit tests for warp.table  (busted)
-- ---------------------------------------------------------------------------
-- Run:  busted spec/table_spec.lua
-- ---------------------------------------------------------------------------

-- Adjust package.path so `require "warp.table"` resolves.
package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

local tbl = require "warp.table"

-- ── Helpers ──────────────────────────────────────────────────────────────

--- Collect key-value pairs from an iterator into a list of {k, v} pairs.
local function collect_pairs(iter)
  local t = {}
  for k, v in iter do
    t[#t + 1] = { k, v }
  end
  return t
end

--- Sort a list of values for order-independent comparison.
local function sorted(t)
  local copy = {}
  for i, v in ipairs(t) do
    copy[i] = v
  end
  table.sort(copy)
  return copy
end

-- ── Tests ────────────────────────────────────────────────────────────────

describe("warp.table", function()
  -- ── isempty ──────────────────────────────────────────────────────────

  describe("isempty", function()
    it("returns true for nil", function()
      assert.is_true(tbl.isempty(nil))
    end)

    it("returns true for empty table", function()
      assert.is_true(tbl.isempty {})
    end)

    it("returns true for hash-only table", function()
      assert.is_true(tbl.isempty { a = 1, b = 2 })
    end)

    it("returns false for non-empty list", function()
      assert.is_false(tbl.isempty { 1, 2, 3 })
    end)

    it("returns false for single-element list", function()
      assert.is_false(tbl.isempty { "x" })
    end)

    it("returns false for mixed table with array part", function()
      assert.is_false(tbl.isempty { 1, a = 2 })
    end)
  end)

  -- ── isblank ──────────────────────────────────────────────────────────

  describe("isblank", function()
    it("returns true for nil", function()
      assert.is_true(tbl.isblank(nil))
    end)

    it("returns true for empty table", function()
      assert.is_true(tbl.isblank {})
    end)

    it("returns false for hash-only table", function()
      assert.is_false(tbl.isblank { a = 1 })
    end)

    it("returns false for list table", function()
      assert.is_false(tbl.isblank { 1 })
    end)

    it("returns false for mixed table", function()
      assert.is_false(tbl.isblank { 1, a = 2 })
    end)
  end)

  -- ── islist ───────────────────────────────────────────────────────────

  describe("islist", function()
    it("returns true for contiguous 1-based list", function()
      assert.is_true(tbl.islist { "a", "b", "c" })
    end)

    it("returns true for single-element list", function()
      assert.is_true(tbl.islist { 42 })
    end)

    it("returns true for empty table", function()
      assert.is_true(tbl.islist {})
    end)

    it("returns false for hash-only table", function()
      assert.is_false(tbl.islist { a = 1 })
    end)

    it("returns false for mixed table", function()
      assert.is_false(tbl.islist { 1, 2, a = 3 })
    end)

    it("returns false for sparse table (gap)", function()
      local t = { [1] = "a", [3] = "c" }
      assert.is_false(tbl.islist(t))
    end)

    it("returns false for non-table: string", function()
      assert.is_false(tbl.islist "hello")
    end)

    it("returns false for non-table: number", function()
      assert.is_false(tbl.islist(42))
    end)

    it("returns false for non-table: nil", function()
      assert.is_false(tbl.islist(nil))
    end)

    it("returns false for non-table: boolean", function()
      assert.is_false(tbl.islist(true))
    end)
  end)

  -- ── isarray ──────────────────────────────────────────────────────────

  describe("isarray", function()
    it("returns true for contiguous 1-based list", function()
      assert.is_true(tbl.isarray { 1, 2, 3 })
    end)

    it("returns true for empty table", function()
      assert.is_true(tbl.isarray {})
    end)

    it("returns true for sparse integer-keyed table", function()
      local t = { [1] = "a", [5] = "e" }
      assert.is_true(tbl.isarray(t))
    end)

    it("returns true for 0-indexed table", function()
      assert.is_true(tbl.isarray { [0] = "zero", [1] = "one" })
    end)

    it("returns true for negative integer keys", function()
      assert.is_true(tbl.isarray { [-1] = "neg", [0] = "zero", [1] = "one" })
    end)

    it("returns false for string keys", function()
      assert.is_false(tbl.isarray { a = 1 })
    end)

    it("returns false for mixed integer and string keys", function()
      assert.is_false(tbl.isarray { [1] = "a", b = "c" })
    end)

    it("returns false for float keys", function()
      assert.is_false(tbl.isarray { [1.5] = "x" })
    end)

    it("returns false for non-table: string", function()
      assert.is_false(tbl.isarray "hello")
    end)

    it("returns false for non-table: nil", function()
      assert.is_false(tbl.isarray(nil))
    end)
  end)

  -- ── copy ─────────────────────────────────────────────────────────────

  describe("copy", function()
    it("returns a new table with same key-value pairs", function()
      local orig = { a = 1, b = 2 }
      local cp = tbl.copy(orig)
      assert.are.same(orig, cp)
      assert.are_not.equal(orig, cp) -- different reference
    end)

    it("copies array elements", function()
      local orig = { 10, 20, 30 }
      local cp = tbl.copy(orig)
      assert.are.same({ 10, 20, 30 }, cp)
    end)

    it("is a shallow copy: nested tables share references", function()
      local inner = { x = 1 }
      local orig = { nested = inner }
      local cp = tbl.copy(orig)
      assert.are.equal(inner, cp.nested)
    end)

    it("does not copy metatables", function()
      local mt = {
        __index = function()
          return 42
        end,
      }
      local orig = setmetatable({}, mt)
      local cp = tbl.copy(orig)
      assert.is_nil(getmetatable(cp))
    end)

    it("returns non-table values as-is", function()
      assert.are.equal(42, tbl.copy(42))
      assert.are.equal("hi", tbl.copy "hi")
      assert.are.equal(nil, tbl.copy(nil))
      assert.are.equal(true, tbl.copy(true))
    end)

    it("copies an empty table", function()
      local cp = tbl.copy {}
      assert.are.same({}, cp)
    end)

    it("modifying copy does not affect original", function()
      local orig = { a = 1, b = 2 }
      local cp = tbl.copy(orig)
      cp.a = 99
      assert.are.equal(1, orig.a)
    end)
  end)

  -- ── deepcopy ─────────────────────────────────────────────────────────

  describe("deepcopy", function()
    it("creates an independent deep clone", function()
      local orig = { a = { b = { c = 1 } } }
      local cp = tbl.deepcopy(orig)
      assert.are.same(orig, cp)
      assert.are_not.equal(orig.a, cp.a)
      assert.are_not.equal(orig.a.b, cp.a.b)
    end)

    it("copies array contents deeply", function()
      local orig = { { 1, 2 }, { 3, 4 } }
      local cp = tbl.deepcopy(orig)
      assert.are.same(orig, cp)
      assert.are_not.equal(orig[1], cp[1])
    end)

    it("preserves metatables", function()
      local mt = {}
      local orig = setmetatable({ x = 1 }, mt)
      local cp = tbl.deepcopy(orig)
      assert.are.equal(mt, getmetatable(cp))
    end)

    it("preserves nested metatables", function()
      local mt_inner = {}
      local orig = { inner = setmetatable({ y = 2 }, mt_inner) }
      local cp = tbl.deepcopy(orig)
      assert.are.equal(mt_inner, getmetatable(cp.inner))
    end)

    it("handles circular references (noref=false)", function()
      local orig = { a = 1 }
      orig.self = orig
      local cp = tbl.deepcopy(orig)
      assert.are.equal(1, cp.a)
      assert.are.equal(cp, cp.self) -- self-reference preserved
      assert.are_not.equal(orig, cp)
    end)

    it("shared sub-tables are copied once (noref=false)", function()
      local shared = { val = 42 }
      local orig = { x = shared, y = shared }
      local cp = tbl.deepcopy(orig)
      assert.are.equal(cp.x, cp.y) -- still same ref in copy
      assert.are_not.equal(shared, cp.x)
    end)

    it("noref=true creates separate copies for shared sub-tables", function()
      local shared = { val = 42 }
      local orig = { x = shared, y = shared }
      local cp = tbl.deepcopy(orig, true)
      assert.are_not.equal(cp.x, cp.y) -- distinct copies
      assert.are.same(cp.x, cp.y) -- but same content
    end)

    it("returns non-table values as-is", function()
      assert.are.equal(42, tbl.deepcopy(42))
      assert.are.equal("hi", tbl.deepcopy "hi")
      assert.are.equal(nil, tbl.deepcopy(nil))
    end)

    it("modifying deep copy does not affect original", function()
      local orig = { a = { b = 1 } }
      local cp = tbl.deepcopy(orig)
      cp.a.b = 99
      assert.are.equal(1, orig.a.b)
    end)

    it("copies an empty nested table", function()
      local orig = { inner = {} }
      local cp = tbl.deepcopy(orig)
      assert.are.same({}, cp.inner)
      assert.are_not.equal(orig.inner, cp.inner)
    end)
  end)

  -- ── keys ─────────────────────────────────────────────────────────────

  describe("keys", function()
    it("returns all keys of a hash table", function()
      local k = tbl.keys { a = 1, b = 2, c = 3 }
      assert.are.same({ "a", "b", "c" }, sorted(k))
    end)

    it("returns integer keys for a list", function()
      local k = tbl.keys { "x", "y", "z" }
      assert.are.same({ 1, 2, 3 }, sorted(k))
    end)

    it("returns empty list for empty table", function()
      assert.are.same({}, tbl.keys {})
    end)

    it("returns keys for mixed table", function()
      local k = tbl.keys { [1] = "a", name = "b" }
      table.sort(k, function(a, b)
        return tostring(a) < tostring(b)
      end)
      assert.are.equal(2, #k)
    end)
  end)

  -- ── values ───────────────────────────────────────────────────────────

  describe("values", function()
    it("returns all values of a hash table", function()
      local v = tbl.values { a = 1, b = 2, c = 3 }
      assert.are.same({ 1, 2, 3 }, sorted(v))
    end)

    it("returns array values", function()
      local v = tbl.values { "x", "y" }
      assert.are.same({ "x", "y" }, sorted(v))
    end)

    it("returns empty list for empty table", function()
      assert.are.same({}, tbl.values {})
    end)
  end)

  -- ── map ──────────────────────────────────────────────────────────────

  describe("map", function()
    it("applies fn to every value", function()
      local result = tbl.map({ 1, 2, 3 }, function(v)
        return v * 2
      end)
      assert.are.same({ 2, 4, 6 }, result)
    end)

    it("preserves keys", function()
      local result = tbl.map({ a = 1, b = 2 }, function(v)
        return v + 10
      end)
      assert.are.same({ a = 11, b = 12 }, result)
    end)

    it("returns empty table for empty input", function()
      local result = tbl.map({}, function(v)
        return v
      end)
      assert.are.same({}, result)
    end)

    it("can change value types", function()
      local result = tbl.map({ 1, 2, 3 }, tostring)
      assert.are.same({ "1", "2", "3" }, result)
    end)

    it("does not modify the original table", function()
      local orig = { a = 1 }
      tbl.map(orig, function(v)
        return v * 10
      end)
      assert.are.equal(1, orig.a)
    end)
  end)

  -- ── filter ───────────────────────────────────────────────────────────

  describe("filter", function()
    it("keeps values matching predicate", function()
      local result = tbl.filter({ 1, 2, 3, 4, 5 }, function(v)
        return v > 3
      end)
      assert.are.same({ 4, 5 }, sorted(result))
    end)

    it("returns empty table when nothing matches", function()
      local result = tbl.filter({ 1, 2, 3 }, function(v)
        return v > 10
      end)
      assert.are.same({}, result)
    end)

    it("returns all when everything matches", function()
      local result = tbl.filter({ 1, 2, 3 }, function()
        return true
      end)
      assert.are.same({ 1, 2, 3 }, sorted(result))
    end)

    it("works on hash tables (values only)", function()
      local result = tbl.filter({ a = 1, b = 5, c = 3 }, function(v)
        return v > 2
      end)
      assert.are.same({ 3, 5 }, sorted(result))
    end)

    it("returns empty table for empty input", function()
      assert.are.same(
        {},
        tbl.filter({}, function()
          return true
        end)
      )
    end)
  end)

  -- ── contains ─────────────────────────────────────────────────────────

  describe("contains", function()
    it("finds a value in a list", function()
      assert.is_true(tbl.contains({ 1, 2, 3 }, 2))
    end)

    it("returns false when value is absent", function()
      assert.is_false(tbl.contains({ 1, 2, 3 }, 4))
    end)

    it("finds a value in a hash table", function()
      assert.is_true(tbl.contains({ a = "x", b = "y" }, "y"))
    end)

    it("returns false for empty table", function()
      assert.is_false(tbl.contains({}, "anything"))
    end)

    it("uses predicate when opts.predicate is true", function()
      local result = tbl.contains({ 10, 20, 30 }, function(v)
        return v > 25
      end, { predicate = true })
      assert.is_true(result)
    end)

    it("predicate returns false when no match", function()
      local result = tbl.contains({ 10, 20 }, function(v)
        return v > 50
      end, { predicate = true })
      assert.is_false(result)
    end)

    it("compares by equality, not identity", function()
      assert.is_true(tbl.contains({ "abc" }, "abc"))
    end)
  end)

  -- ── count ────────────────────────────────────────────────────────────

  describe("count", function()
    it("counts list elements", function()
      assert.are.equal(3, tbl.count { 10, 20, 30 })
    end)

    it("counts hash entries", function()
      assert.are.equal(2, tbl.count { a = 1, b = 2 })
    end)

    it("counts mixed entries", function()
      assert.are.equal(3, tbl.count { 1, a = 2, b = 3 })
    end)

    it("returns 0 for empty table", function()
      assert.are.equal(0, tbl.count {})
    end)
  end)

  -- ── deep_equal ───────────────────────────────────────────────────────

  describe("deep_equal", function()
    it("returns true for identical primitives", function()
      assert.is_true(tbl.deep_equal(1, 1))
      assert.is_true(tbl.deep_equal("a", "a"))
      assert.is_true(tbl.deep_equal(true, true))
      assert.is_true(tbl.deep_equal(nil, nil))
    end)

    it("returns false for different primitives", function()
      assert.is_false(tbl.deep_equal(1, 2))
      assert.is_false(tbl.deep_equal("a", "b"))
      assert.is_false(tbl.deep_equal(true, false))
    end)

    it("returns false for different types", function()
      assert.is_false(tbl.deep_equal(1, "1"))
      assert.is_false(tbl.deep_equal({}, "table"))
    end)

    it("returns true for equal flat tables", function()
      assert.is_true(tbl.deep_equal({ a = 1, b = 2 }, { a = 1, b = 2 }))
    end)

    it("returns true for equal nested tables", function()
      assert.is_true(tbl.deep_equal({ a = { b = { c = 3 } } }, { a = { b = { c = 3 } } }))
    end)

    it("returns false when keys differ", function()
      assert.is_false(tbl.deep_equal({ a = 1 }, { b = 1 }))
    end)

    it("returns false when values differ", function()
      assert.is_false(tbl.deep_equal({ a = 1 }, { a = 2 }))
    end)

    it("returns false when one has extra keys", function()
      assert.is_false(tbl.deep_equal({ a = 1 }, { a = 1, b = 2 }))
      assert.is_false(tbl.deep_equal({ a = 1, b = 2 }, { a = 1 }))
    end)

    it("returns true for same reference", function()
      local t = { x = 1 }
      assert.is_true(tbl.deep_equal(t, t))
    end)

    it("returns true for equal lists", function()
      assert.is_true(tbl.deep_equal({ 1, 2, 3 }, { 1, 2, 3 }))
    end)

    it("returns false for lists of different length", function()
      assert.is_false(tbl.deep_equal({ 1, 2 }, { 1, 2, 3 }))
    end)

    it("returns true for empty tables", function()
      assert.is_true(tbl.deep_equal({}, {}))
    end)

    it("handles deeply nested equality", function()
      local a = { x = { y = { z = { w = "deep" } } } }
      local b = { x = { y = { z = { w = "deep" } } } }
      assert.is_true(tbl.deep_equal(a, b))
    end)

    it("handles deeply nested inequality", function()
      local a = { x = { y = { z = { w = "deep" } } } }
      local b = { x = { y = { z = { w = "different" } } } }
      assert.is_false(tbl.deep_equal(a, b))
    end)
  end)

  -- ── get ──────────────────────────────────────────────────────────────

  describe("get", function()
    it("retrieves a top-level key", function()
      assert.are.equal(1, tbl.get({ a = 1 }, "a"))
    end)

    it("retrieves a nested key", function()
      assert.are.equal(42, tbl.get({ a = { b = { c = 42 } } }, "a", "b", "c"))
    end)

    it("returns nil for missing top-level key", function()
      assert.is_nil(tbl.get({ a = 1 }, "b"))
    end)

    it("returns nil for missing nested key", function()
      assert.is_nil(tbl.get({ a = { b = 1 } }, "a", "c"))
    end)

    it("returns nil when intermediate is not a table", function()
      assert.is_nil(tbl.get({ a = 1 }, "a", "b"))
    end)

    it("returns nil with no keys", function()
      assert.is_nil(tbl.get { a = 1 })
    end)

    it("works with integer keys", function()
      assert.are.equal("x", tbl.get({ { "x", "y" } }, 1, 1))
    end)

    it("retrieves a table value at final key", function()
      local inner = { val = 1 }
      assert.are.equal(inner, tbl.get({ a = inner }, "a"))
    end)

    it("returns false without converting to nil", function()
      assert.are.equal(false, tbl.get({ a = false }, "a"))
    end)
  end)

  -- ── extend ───────────────────────────────────────────────────────────

  describe("extend", function()
    it("merges two tables with 'force'", function()
      local result = tbl.extend("force", { a = 1 }, { b = 2 })
      assert.are.same({ a = 1, b = 2 }, result)
    end)

    it("rightmost wins with 'force'", function()
      local result = tbl.extend("force", { a = 1 }, { a = 2 })
      assert.are.equal(2, result.a)
    end)

    it("leftmost wins with 'keep'", function()
      local result = tbl.extend("keep", { a = 1 }, { a = 2 })
      assert.are.equal(1, result.a)
    end)

    it("errors on conflict with 'error'", function()
      assert.has_error(function()
        tbl.extend("error", { a = 1 }, { a = 2 })
      end)
    end)

    it("merges three tables", function()
      local result = tbl.extend("force", { a = 1 }, { b = 2 }, { c = 3 })
      assert.are.same({ a = 1, b = 2, c = 3 }, result)
    end)

    it("does not modify source tables", function()
      local t1 = { a = 1 }
      local t2 = { b = 2 }
      tbl.extend("force", t1, t2)
      assert.is_nil(t1.b)
      assert.is_nil(t2.a)
    end)

    it("returns empty table when given empty tables", function()
      assert.are.same({}, tbl.extend("force", {}, {}))
    end)

    it("does not recurse into sub-tables", function()
      local result = tbl.extend("force", { a = { x = 1 } }, { a = { y = 2 } })
      -- With shallow extend, rightmost table replaces entirely
      assert.are.same({ y = 2 }, result.a)
    end)

    it("skips nil arguments", function()
      local result = tbl.extend("force", { a = 1 }, nil, { b = 2 })
      assert.are.same({ a = 1, b = 2 }, result)
    end)
  end)

  -- ── deep_extend ──────────────────────────────────────────────────────

  describe("deep_extend", function()
    it("recursively merges nested hash tables", function()
      local result = tbl.deep_extend("force", { a = { x = 1 } }, { a = { y = 2 } })
      assert.are.same({ a = { x = 1, y = 2 } }, result)
    end)

    it("rightmost wins for conflicting leaf values", function()
      local result = tbl.deep_extend("force", { a = { x = 1 } }, { a = { x = 2 } })
      assert.are.equal(2, result.a.x)
    end)

    it("keep preserves leftmost leaf values", function()
      local result = tbl.deep_extend("keep", { a = { x = 1 } }, { a = { x = 2 } })
      assert.are.equal(1, result.a.x)
    end)

    it("does not merge list-like sub-tables (replaces atomically)", function()
      local result = tbl.deep_extend(
        "force",
        { items = { 1, 2 } },
        { items = { 3, 4, 5 } }
      )
      assert.are.same({ 3, 4, 5 }, result.items)
    end)

    it("merges deeply nested structures", function()
      local result = tbl.deep_extend(
        "force",
        { a = { b = { c = 1, d = 2 } } },
        { a = { b = { e = 3 } } }
      )
      assert.are.same({ a = { b = { c = 1, d = 2, e = 3 } } }, result)
    end)

    it("errors on conflict with 'error'", function()
      assert.has_error(function()
        tbl.deep_extend("error", { a = { x = 1 } }, { a = { x = 2 } })
      end)
    end)

    it("does not modify source tables", function()
      local t1 = { a = { x = 1 } }
      local t2 = { a = { y = 2 } }
      tbl.deep_extend("force", t1, t2)
      assert.is_nil(t1.a.y)
      assert.is_nil(t2.a.x)
    end)

    it("merges empty sub-tables", function()
      local result = tbl.deep_extend("force", { a = {} }, { a = { x = 1 } })
      assert.are.same({ a = { x = 1 } }, result)
    end)

    it("merges three tables deeply", function()
      local result = tbl.deep_extend(
        "force",
        { a = { x = 1 } },
        { a = { y = 2 } },
        { a = { z = 3 } }
      )
      assert.are.same({ a = { x = 1, y = 2, z = 3 } }, result)
    end)
  end)

  -- ── spairs ───────────────────────────────────────────────────────────

  describe("spairs", function()
    it("iterates string keys in sorted order", function()
      local pairs_list = collect_pairs(tbl.spairs { c = 3, a = 1, b = 2 })
      assert.are.same({
        { "a", 1 },
        { "b", 2 },
        { "c", 3 },
      }, pairs_list)
    end)

    it("iterates integer keys in sorted order", function()
      local pairs_list = collect_pairs(tbl.spairs { [3] = "c", [1] = "a", [2] = "b" })
      assert.are.same({
        { 1, "a" },
        { 2, "b" },
        { 3, "c" },
      }, pairs_list)
    end)

    it("returns nothing for empty table", function()
      local pairs_list = collect_pairs(tbl.spairs {})
      assert.are.same({}, pairs_list)
    end)

    it("handles single-element table", function()
      local pairs_list = collect_pairs(tbl.spairs { only = 1 })
      assert.are.same({ { "only", 1 } }, pairs_list)
    end)
  end)
end)
