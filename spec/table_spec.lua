-- ---------------------------------------------------------------------------
-- Unit tests for warp.table  (busted)
-- ---------------------------------------------------------------------------

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
    it("returns true for nil or empty table", function()
      assert.is_true(tbl.isempty(nil))
      assert.is_true(tbl.isempty {})
    end)

    it("returns true for hash-only table (no array part)", function()
      assert.is_true(tbl.isempty { a = 1, b = 2 })
    end)

    it("returns false when array part exists", function()
      assert.is_false(tbl.isempty { 1, 2, 3 })
      assert.is_false(tbl.isempty { "x" })
      assert.is_false(tbl.isempty { false })
      assert.is_false(tbl.isempty { 1, a = 2 })
    end)
  end)

  -- ── isblank ──────────────────────────────────────────────────────────

  describe("isblank", function()
    it("returns true for nil or empty table", function()
      assert.is_true(tbl.isblank(nil))
      assert.is_true(tbl.isblank {})
    end)

    it("returns false for any non-empty table", function()
      assert.is_false(tbl.isblank { a = 1 })
      assert.is_false(tbl.isblank { 1 })
      assert.is_false(tbl.isblank { false })
      assert.is_false(tbl.isblank { 1, a = 2 })
    end)
  end)

  -- ── islist ───────────────────────────────────────────────────────────

  describe("islist", function()
    it("returns true for contiguous 1-based lists", function()
      assert.is_true(tbl.islist { "a", "b", "c" })
      assert.is_true(tbl.islist { 42 })
      assert.is_true(tbl.islist {})
    end)

    it("returns false for non-list tables", function()
      assert.is_false(tbl.islist { a = 1 })
      assert.is_false(tbl.islist { 1, 2, a = 3 })
      assert.is_false(tbl.islist { [0] = "zero" })
    end)

    it("returns false for sparse tables", function()
      local t = { [1] = "a", [3] = "c" }
      assert.is_false(tbl.islist(t))
    end)

    it("returns false for non-table types", function()
      assert.is_false(tbl.islist "hello")
      assert.is_false(tbl.islist(42))
      assert.is_false(tbl.islist(nil))
      assert.is_false(tbl.islist(true))
    end)
  end)

  -- ── isarray ──────────────────────────────────────────────────────────

  describe("isarray", function()
    it("returns true for integer-keyed tables", function()
      assert.is_true(tbl.isarray { 1, 2, 3 })
      assert.is_true(tbl.isarray {})
      assert.is_true(tbl.isarray { [1] = "a", [5] = "e" })
      assert.is_true(tbl.isarray { [0] = "zero", [1] = "one" })
      assert.is_true(tbl.isarray { [-1] = "neg", [0] = "zero", [1] = "one" })
    end)

    it("returns false for non-integer or non-table inputs", function()
      assert.is_false(tbl.isarray { a = 1 })
      assert.is_false(tbl.isarray { [1] = "a", b = "c" })
      assert.is_false(tbl.isarray { [1.5] = "x" })
      assert.is_false(tbl.isarray "hello")
      assert.is_false(tbl.isarray(nil))
      assert.is_false(tbl.isarray { [true] = "x" })
    end)
  end)

  -- ── copy ─────────────────────────────────────────────────────────────

  describe("copy", function()
    it("returns a shallow clone with same key-value pairs", function()
      local orig = { a = 1, b = 2 }
      local cp = tbl.copy(orig)
      assert.are.same(orig, cp)
      assert.are_not.equal(orig, cp)
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

    it("preserves metatables at all levels", function()
      local mt = {}
      local mt_inner = {}
      local orig = setmetatable({ inner = setmetatable({ y = 2 }, mt_inner) }, mt)
      local cp = tbl.deepcopy(orig)
      assert.are.equal(mt, getmetatable(cp))
      assert.are.equal(mt_inner, getmetatable(cp.inner))
    end)

    it("handles circular references (noref=false)", function()
      local orig = { a = 1 }
      orig.self = orig
      local cp = tbl.deepcopy(orig)
      assert.are.equal(1, cp.a)
      assert.are.equal(cp, cp.self)
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
      assert.are_not.equal(cp.x, cp.y)
      assert.are.same(cp.x, cp.y)
    end)

    it("handles mutual references (noref=false)", function()
      local a = { val = "a" }
      local b = { val = "b" }
      a.other = b
      b.other = a
      local cp = tbl.deepcopy(a)
      assert.are.equal("a", cp.val)
      assert.are.equal("b", cp.other.val)
      assert.are.equal(cp, cp.other.other)
    end)

    it("returns non-table values as-is", function()
      assert.are.equal(42, tbl.deepcopy(42))
      assert.are.equal("hi", tbl.deepcopy "hi")
      assert.are.equal(nil, tbl.deepcopy(nil))
      assert.are.equal(false, tbl.deepcopy(false))
    end)

    it("modifying deep copy does not affect original", function()
      local orig = { a = { b = 1 } }
      local cp = tbl.deepcopy(orig)
      cp.a.b = 99
      assert.are.equal(1, orig.a.b)
    end)
  end)

  -- ── keys ─────────────────────────────────────────────────────────────

  describe("keys", function()
    it("returns all keys", function()
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
  end)

  -- ── values ───────────────────────────────────────────────────────────

  describe("values", function()
    it("returns all values", function()
      local v = tbl.values { a = 1, b = 2, c = 3 }
      assert.are.same({ 1, 2, 3 }, sorted(v))
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

    it("preserves keys on hash tables", function()
      local result = tbl.map({ a = 1, b = 2 }, function(v)
        return v + 10
      end)
      assert.are.same({ a = 11, b = 12 }, result)
    end)

    it("does not modify the original table", function()
      local orig = { a = 1 }
      tbl.map(orig, function(v)
        return v * 10
      end)
      assert.are.equal(1, orig.a)
    end)

    it("can change value types", function()
      local result = tbl.map({ 1, 2, 3 }, tostring)
      assert.are.same({ "1", "2", "3" }, result)
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

    it("works on hash tables (collects matching values)", function()
      local result = tbl.filter({ a = 1, b = 5, c = 3 }, function(v)
        return v > 2
      end)
      assert.are.same({ 3, 5 }, sorted(result))
    end)

    it("filters with type check predicate", function()
      local result = tbl.filter({ 1, "a", 2, "b", 3 }, function(v)
        return type(v) == "number"
      end)
      assert.are.same({ 1, 2, 3 }, sorted(result))
    end)
  end)

  -- ── contains ─────────────────────────────────────────────────────────

  describe("contains", function()
    it("finds a value in a list or hash", function()
      assert.is_true(tbl.contains({ 1, 2, 3 }, 2))
      assert.is_true(tbl.contains({ a = "x", b = "y" }, "y"))
    end)

    it("returns false when value is absent or table is empty", function()
      assert.is_false(tbl.contains({ 1, 2, 3 }, 4))
      assert.is_false(tbl.contains({}, "anything"))
    end)

    it("finds false as a value", function()
      assert.is_true(tbl.contains({ true, false }, false))
    end)

    it("uses predicate when opts.predicate is true", function()
      assert.is_true(tbl.contains({ 10, 20, 30 }, function(v)
        return v > 25
      end, { predicate = true }))

      assert.is_false(tbl.contains({ 10, 20 }, function(v)
        return v > 50
      end, { predicate = true }))
    end)
  end)

  -- ── count ────────────────────────────────────────────────────────────

  describe("count", function()
    it("counts all entries including hash keys", function()
      assert.are.equal(3, tbl.count { 10, 20, 30 })
      assert.are.equal(2, tbl.count { a = 1, b = 2 })
      assert.are.equal(3, tbl.count { 1, a = 2, b = 3 })
      assert.are.equal(0, tbl.count {})
    end)
  end)

  -- ── deep_equal ───────────────────────────────────────────────────────

  describe("deep_equal", function()
    it("compares primitives", function()
      assert.is_true(tbl.deep_equal(1, 1))
      assert.is_true(tbl.deep_equal("a", "a"))
      assert.is_true(tbl.deep_equal(nil, nil))
      assert.is_false(tbl.deep_equal(1, 2))
      assert.is_false(tbl.deep_equal(1, "1"))
    end)

    it("compares flat and nested tables", function()
      assert.is_true(tbl.deep_equal({ a = 1, b = 2 }, { a = 1, b = 2 }))
      assert.is_true(tbl.deep_equal({ a = { b = { c = 3 } } }, { a = { b = { c = 3 } } }))
      assert.is_true(tbl.deep_equal({}, {}))
    end)

    it("detects differences", function()
      assert.is_false(tbl.deep_equal({ a = 1 }, { b = 1 }))
      assert.is_false(tbl.deep_equal({ a = 1 }, { a = 2 }))
      assert.is_false(tbl.deep_equal({ a = 1 }, { a = 1, b = 2 }))
      assert.is_false(tbl.deep_equal({ 1, 2 }, { 1, 2, 3 }))
    end)

    it("returns false for table vs non-table", function()
      assert.is_false(tbl.deep_equal({}, 1))
      assert.is_false(tbl.deep_equal(nil, {}))
    end)

    it("handles same reference", function()
      local t = { x = 1 }
      assert.is_true(tbl.deep_equal(t, t))
    end)
  end)

  -- ── get ──────────────────────────────────────────────────────────────

  describe("get", function()
    it("retrieves nested keys", function()
      assert.are.equal(1, tbl.get({ a = 1 }, "a"))
      assert.are.equal(42, tbl.get({ a = { b = { c = 42 } } }, "a", "b", "c"))
      assert.are.equal("x", tbl.get({ { "x", "y" } }, 1, 1))
    end)

    it("returns nil for missing or invalid paths", function()
      assert.is_nil(tbl.get({ a = 1 }, "b"))
      assert.is_nil(tbl.get({ a = { b = 1 } }, "a", "c"))
      assert.is_nil(tbl.get({ a = 1 }, "a", "b"))
      assert.is_nil(tbl.get { a = 1 })
    end)

    it("returns falsy values without converting to nil", function()
      assert.are.equal(false, tbl.get({ a = false }, "a"))
      assert.are.equal(0, tbl.get({ a = 0 }, "a"))
      assert.are.equal("", tbl.get({ a = "" }, "a"))
    end)
  end)

  -- ── extend ───────────────────────────────────────────────────────────

  describe("extend", function()
    it("merges tables with 'force' (rightmost wins)", function()
      local result = tbl.extend("force", { a = 1 }, { a = 2, b = 2 })
      assert.are.equal(2, result.a)
      assert.are.equal(2, result.b)
    end)

    it("merges tables with 'keep' (leftmost wins)", function()
      local result = tbl.extend("keep", { a = 1 }, { a = 2, b = 2 })
      assert.are.equal(1, result.a)
      assert.are.equal(2, result.b)
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

    it("does not recurse into sub-tables", function()
      local result = tbl.extend("force", { a = { x = 1 } }, { a = { y = 2 } })
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
      local result = tbl.deep_extend("force", { items = { 1, 2 } }, { items = { 3, 4, 5 } })
      assert.are.same({ 3, 4, 5 }, result.items)
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

    it("merges three tables deeply", function()
      local result = tbl.deep_extend(
        "force",
        { a = { x = 1 } },
        { a = { y = 2 } },
        { a = { z = 3 } }
      )
      assert.are.same({ a = { x = 1, y = 2, z = 3 } }, result)
    end)

    it("handles type changes with force", function()
      assert.are.equal(42, tbl.deep_extend("force", { a = { x = 1 } }, { a = 42 }).a)
      assert.are.same({ x = 1 }, tbl.deep_extend("force", { a = 42 }, { a = { x = 1 } }).a)
    end)
  end)

  -- ── spairs ───────────────────────────────────────────────────────────

  describe("spairs", function()
    it("iterates keys in sorted order", function()
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
      assert.are.same({}, collect_pairs(tbl.spairs {}))
    end)
  end)
end)
