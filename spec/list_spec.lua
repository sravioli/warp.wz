-- ---------------------------------------------------------------------------
-- Unit tests for warp.list  (busted)
-- ---------------------------------------------------------------------------
-- Run:  busted spec/list_spec.lua
-- ---------------------------------------------------------------------------

-- Adjust package.path so `require "warp.list"` resolves.
package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

local list = require "warp.list"

-- ── Helpers ──────────────────────────────────────────────────────────────

--- Collect index/combo pairs from a cartesian iterator.
local function collect_iter(iter)
  local t = {}
  for i, combo in iter do
    -- deep-copy combo so we capture the snapshot
    local c = {}
    for j = 1, #combo do
      c[j] = combo[j]
    end
    t[#t + 1] = { i, c }
  end
  return t
end

-- ── Tests ────────────────────────────────────────────────────────────────

describe("warp.list", function()
  -- ── contains ─────────────────────────────────────────────────────────

  describe("contains", function()
    it("finds a value at the beginning", function()
      assert.is_true(list.contains({ 1, 2, 3 }, 1))
    end)

    it("finds a value in the middle", function()
      assert.is_true(list.contains({ 1, 2, 3 }, 2))
    end)

    it("finds a value at the end", function()
      assert.is_true(list.contains({ 1, 2, 3 }, 3))
    end)

    it("returns false when value is absent", function()
      assert.is_false(list.contains({ 1, 2, 3 }, 4))
    end)

    it("returns false for empty list", function()
      assert.is_false(list.contains({}, 1))
    end)

    it("finds a string value", function()
      assert.is_true(list.contains({ "a", "b", "c" }, "b"))
    end)

    it("uses raw equality (not identity)", function()
      assert.is_true(list.contains({ "abc" }, "abc"))
    end)

    it("finds false as a value", function()
      assert.is_true(list.contains({ true, false, true }, false))
    end)

    it("does not find nil", function()
      assert.is_false(list.contains({ 1, 2, 3 }, nil))
    end)

    it("only scans the array portion", function()
      local t = { 10, 20, 30, key = 99 }
      assert.is_false(list.contains(t, 99))
    end)
  end)

  -- ── extend ───────────────────────────────────────────────────────────

  describe("extend", function()
    it("appends all elements from src to dst", function()
      local dst = { 1, 2 }
      list.extend(dst, { 3, 4, 5 })
      assert.are.same({ 1, 2, 3, 4, 5 }, dst)
    end)

    it("returns the dst table", function()
      local dst = { 1 }
      local ret = list.extend(dst, { 2 })
      assert.are.equal(dst, ret)
    end)

    it("appends nothing from empty src", function()
      local dst = { 1, 2 }
      list.extend(dst, {})
      assert.are.same({ 1, 2 }, dst)
    end)

    it("appends to empty dst", function()
      local dst = {}
      list.extend(dst, { 1, 2, 3 })
      assert.are.same({ 1, 2, 3 }, dst)
    end)

    it("respects start parameter", function()
      local dst = {}
      list.extend(dst, { 10, 20, 30 }, 2)
      assert.are.same({ 20, 30 }, dst)
    end)

    it("respects finish parameter", function()
      local dst = {}
      list.extend(dst, { 10, 20, 30 }, nil, 2)
      assert.are.same({ 10, 20 }, dst)
    end)

    it("respects both start and finish", function()
      local dst = {}
      list.extend(dst, { 10, 20, 30, 40, 50 }, 2, 4)
      assert.are.same({ 20, 30, 40 }, dst)
    end)

    it("does nothing when start > finish", function()
      local dst = { 1 }
      list.extend(dst, { 10, 20, 30 }, 3, 1)
      assert.are.same({ 1 }, dst)
    end)

    it("handles single-element range", function()
      local dst = {}
      list.extend(dst, { 10, 20, 30 }, 2, 2)
      assert.are.same({ 20 }, dst)
    end)
  end)

  -- ── slice ────────────────────────────────────────────────────────────

  describe("slice", function()
    it("returns full copy with no start/finish", function()
      local orig = { 1, 2, 3 }
      local s = list.slice(orig)
      assert.are.same({ 1, 2, 3 }, s)
      assert.are_not.equal(orig, s)
    end)

    it("slices from start to end", function()
      assert.are.same({ 2, 3 }, list.slice({ 1, 2, 3 }, 2))
    end)

    it("slices from 1 to finish", function()
      assert.are.same({ 1, 2 }, list.slice({ 1, 2, 3 }, nil, 2))
    end)

    it("slices a middle range", function()
      assert.are.same({ 2, 3, 4 }, list.slice({ 1, 2, 3, 4, 5 }, 2, 4))
    end)

    it("returns single element for equal start/finish", function()
      assert.are.same({ 3 }, list.slice({ 1, 2, 3, 4 }, 3, 3))
    end)

    it("returns empty for invalid range", function()
      assert.are.same({}, list.slice({ 1, 2, 3 }, 3, 1))
    end)

    it("returns empty for empty list", function()
      assert.are.same({}, list.slice {})
    end)

    it("does not modify the original", function()
      local orig = { 1, 2, 3 }
      list.slice(orig, 2, 3)
      assert.are.same({ 1, 2, 3 }, orig)
    end)
  end)

  -- ── unique ───────────────────────────────────────────────────────────

  describe("unique", function()
    it("removes duplicates", function()
      local t = { 1, 2, 2, 3, 1 }
      list.unique(t)
      assert.are.same({ 1, 2, 3 }, t)
    end)

    it("returns the same table reference", function()
      local t = { 1, 2, 3 }
      assert.are.equal(t, list.unique(t))
    end)

    it("preserves order of first occurrences", function()
      local t = { "c", "a", "b", "a", "c" }
      list.unique(t)
      assert.are.same({ "c", "a", "b" }, t)
    end)

    it("handles already-unique list", function()
      local t = { 1, 2, 3 }
      list.unique(t)
      assert.are.same({ 1, 2, 3 }, t)
    end)

    it("handles single-element list", function()
      local t = { 42 }
      list.unique(t)
      assert.are.same({ 42 }, t)
    end)

    it("handles empty list", function()
      local t = {}
      list.unique(t)
      assert.are.same({}, t)
    end)

    it("handles all-duplicate list", function()
      local t = { 5, 5, 5, 5 }
      list.unique(t)
      assert.are.same({ 5 }, t)
    end)

    it("shrinks the list (removes trailing slots)", function()
      local t = { 1, 2, 1, 2, 1 }
      list.unique(t)
      assert.are.equal(2, #t)
    end)

    it("uses key function for uniqueness", function()
      local t = { { id = 1 }, { id = 2 }, { id = 1 } }
      list.unique(t, function(x)
        return x.id
      end)
      assert.are.equal(2, #t)
      assert.are.equal(1, t[1].id)
      assert.are.equal(2, t[2].id)
    end)

    it("treats nil key return as always unique", function()
      local t = { 1, 2, 3 }
      list.unique(t, function()
        return nil
      end)
      assert.are.same({ 1, 2, 3 }, t)
    end)

    it("deduplicates by string key", function()
      local t = { "abc", "ABC", "def", "abc" }
      list.unique(t, string.lower)
      assert.are.same({ "abc", "def" }, t)
    end)
  end)

  -- ── bisect ───────────────────────────────────────────────────────────

  describe("bisect", function()
    describe("lower bound (default)", function()
      it("finds insertion point for value at start", function()
        assert.are.equal(1, list.bisect({ 2, 4, 6 }, 1))
      end)

      it("finds insertion point for value in middle", function()
        assert.are.equal(2, list.bisect({ 1, 3, 5, 7 }, 3))
      end)

      it("finds insertion point for value at end", function()
        assert.are.equal(4, list.bisect({ 1, 2, 3 }, 4))
      end)

      it("returns first position of duplicates", function()
        assert.are.equal(4, list.bisect({ 1, 2, 2, 3, 3, 3 }, 3))
      end)

      it("handles single-element list (before)", function()
        assert.are.equal(1, list.bisect({ 5 }, 3))
      end)

      it("handles single-element list (after)", function()
        assert.are.equal(2, list.bisect({ 5 }, 8))
      end)

      it("handles single-element list (equal)", function()
        assert.are.equal(1, list.bisect({ 5 }, 5))
      end)

      it("handles empty list", function()
        assert.are.equal(1, list.bisect({}, 5))
      end)

      it("respects lo option", function()
        assert.are.equal(3, list.bisect({ 1, 2, 3, 4, 5 }, 3, { lo = 3 }))
      end)

      it("respects hi option", function()
        assert.are.equal(3, list.bisect({ 1, 2, 5, 7 }, 5, { hi = 3 }))
      end)

      it("uses key function", function()
        local t = { { v = 1 }, { v = 3 }, { v = 5 } }
        local key = function(x)
          return x.v
        end
        assert.are.equal(2, list.bisect(t, { v = 3 }, { key = key }))
      end)
    end)

    describe("upper bound", function()
      it("returns position past duplicates", function()
        assert.are.equal(7, list.bisect({ 1, 2, 2, 3, 3, 3 }, 3, { bound = "upper" }))
      end)

      it("returns position past single match", function()
        assert.are.equal(3, list.bisect({ 1, 2, 4, 5 }, 2, { bound = "upper" }))
      end)

      it("returns 1 for value before all elements", function()
        assert.are.equal(1, list.bisect({ 2, 4, 6 }, 1, { bound = "upper" }))
      end)

      it("returns past end for value after all elements", function()
        assert.are.equal(4, list.bisect({ 1, 2, 3 }, 4, { bound = "upper" }))
      end)

      it("handles empty list", function()
        assert.are.equal(1, list.bisect({}, 5, { bound = "upper" }))
      end)

      it("uses key function", function()
        local t = { { v = 1 }, { v = 3 }, { v = 3 }, { v = 5 } }
        local key = function(x)
          return x.v
        end
        assert.are.equal(4, list.bisect(t, { v = 3 }, { bound = "upper", key = key }))
      end)
    end)
  end)

  -- ── reverse ──────────────────────────────────────────────────────────

  describe("reverse", function()
    it("reverses a list", function()
      local t = { 1, 2, 3, 4, 5 }
      list.reverse(t)
      assert.are.same({ 5, 4, 3, 2, 1 }, t)
    end)

    it("returns the same table reference", function()
      local t = { 1, 2, 3 }
      assert.are.equal(t, list.reverse(t))
    end)

    it("reverses a two-element list", function()
      local t = { "a", "b" }
      list.reverse(t)
      assert.are.same({ "b", "a" }, t)
    end)

    it("handles single-element list", function()
      local t = { 42 }
      list.reverse(t)
      assert.are.same({ 42 }, t)
    end)

    it("handles empty list", function()
      local t = {}
      list.reverse(t)
      assert.are.same({}, t)
    end)

    it("reverses an even-length list", function()
      local t = { 1, 2, 3, 4 }
      list.reverse(t)
      assert.are.same({ 4, 3, 2, 1 }, t)
    end)

    it("reverses an odd-length list (middle stays)", function()
      local t = { 1, 2, 3 }
      list.reverse(t)
      assert.are.same({ 3, 2, 1 }, t)
    end)

    it("double reverse restores original", function()
      local t = { "x", "y", "z" }
      list.reverse(t)
      list.reverse(t)
      assert.are.same({ "x", "y", "z" }, t)
    end)
  end)

  -- ── cartesian_iter ───────────────────────────────────────────────────

  describe("cartesian_iter", function()
    it("produces all combinations of two lists", function()
      local results = collect_iter(list.cartesian_iter { { 1, 2 }, { "a", "b" } })
      assert.are.same({
        { 1, { 1, "a" } },
        { 2, { 1, "b" } },
        { 3, { 2, "a" } },
        { 4, { 2, "b" } },
      }, results)
    end)

    it("produces all combinations of three lists", function()
      local results = collect_iter(list.cartesian_iter { { 1, 2 }, { "a" }, { true, false } })
      assert.are.equal(4, #results)
      assert.are.same({ 1, "a", true }, results[1][2])
      assert.are.same({ 1, "a", false }, results[2][2])
      assert.are.same({ 2, "a", true }, results[3][2])
      assert.are.same({ 2, "a", false }, results[4][2])
    end)

    it("handles single list", function()
      local results = collect_iter(list.cartesian_iter { { 10, 20, 30 } })
      assert.are.equal(3, #results)
      assert.are.same({ 10 }, results[1][2])
      assert.are.same({ 20 }, results[2][2])
      assert.are.same({ 30 }, results[3][2])
    end)

    it("handles single-element lists", function()
      local results = collect_iter(list.cartesian_iter { { 1 }, { 2 }, { 3 } })
      assert.are.equal(1, #results)
      assert.are.same({ 1, 2, 3 }, results[1][2])
    end)

    it("produces correct count for larger sets", function()
      local results =
        collect_iter(list.cartesian_iter { { 1, 2, 3 }, { "a", "b" }, { true, false } })
      assert.are.equal(3 * 2 * 2, #results)
    end)

    it("returns sequential indices", function()
      local results = collect_iter(list.cartesian_iter { { 1, 2 }, { "a", "b" } })
      for i, r in ipairs(results) do
        assert.are.equal(i, r[1])
      end
    end)

    it("reuses the same combo table (shared reference)", function()
      local seen = {}
      for _, combo in list.cartesian_iter { { 1, 2 }, { "a" } } do
        seen[#seen + 1] = combo
      end
      -- All entries should be the same table reference
      assert.are.equal(seen[1], seen[2])
    end)
  end)

  -- ── cartesian_iter_copy ──────────────────────────────────────────────

  describe("cartesian_iter_copy", function()
    it("produces all combinations", function()
      local results = {}
      for _, combo in list.cartesian_iter_copy { { 1, 2 }, { "a", "b" } } do
        results[#results + 1] = combo
      end
      assert.are.same({
        { 1, "a" },
        { 1, "b" },
        { 2, "a" },
        { 2, "b" },
      }, results)
    end)

    it("yields independent copies", function()
      local results = {}
      for _, combo in list.cartesian_iter_copy { { 1, 2 }, { "a" } } do
        results[#results + 1] = combo
      end
      assert.are_not.equal(results[1], results[2])
    end)

    it("copies are safe to mutate", function()
      local results = {}
      for _, combo in list.cartesian_iter_copy { { 1 }, { 2 } } do
        results[#results + 1] = combo
      end
      results[1][1] = 99
      -- Only one combo here, but confirm mutation doesn't break anything
      assert.are.equal(99, results[1][1])
    end)
  end)

  -- ── cartesian ────────────────────────────────────────────────────────

  describe("cartesian", function()
    it("returns all combinations as a table", function()
      local result = list.cartesian { { 1, 2 }, { "a", "b" } }
      assert.are.same({
        { 1, "a" },
        { 1, "b" },
        { 2, "a" },
        { 2, "b" },
      }, result)
    end)

    it("returns independent sub-tables", function()
      local result = list.cartesian { { 1, 2 }, { 3 } }
      assert.are_not.equal(result[1], result[2])
    end)

    it("handles single set", function()
      local result = list.cartesian { { "x", "y" } }
      assert.are.same({ { "x" }, { "y" } }, result)
    end)

    it("handles three sets", function()
      local result = list.cartesian { { 1 }, { 2 }, { 3 } }
      assert.are.same({ { 1, 2, 3 } }, result)
    end)

    it("count matches product of set sizes", function()
      local result = list.cartesian { { 1, 2, 3 }, { "a", "b" } }
      assert.are.equal(6, #result)
    end)

    it("handles large product", function()
      local result = list.cartesian { { 1, 2, 3, 4 }, { 1, 2, 3, 4 }, { 1, 2 } }
      assert.are.equal(4 * 4 * 2, #result)
    end)
  end)

  -- ── Additional edge-case coverage ────────────────────────────────────

  describe("contains edge cases", function()
    it("finds value at the very end of a large list", function()
      local t = {}
      for i = 1, 100 do
        t[i] = i
      end
      assert.is_true(list.contains(t, 100))
    end)

    it("returns false for empty string value in non-empty list", function()
      assert.is_false(list.contains({ "a", "b", "c" }, ""))
    end)

    it("finds empty string when present", function()
      assert.is_true(list.contains({ "", "a" }, ""))
    end)

    it("does not scan hash portion", function()
      local t = { 1, 2, 3 }
      t.key = 42
      assert.is_false(list.contains(t, 42))
    end)
  end)

  describe("extend edge cases", function()
    it("handles start beyond src length (no-op)", function()
      local dst = { 1 }
      list.extend(dst, { 10, 20, 30 }, 5)
      assert.are.same({ 1 }, dst)
    end)

    it("handles finish of 0 (no-op)", function()
      local dst = { 1 }
      list.extend(dst, { 10, 20, 30 }, 1, 0)
      assert.are.same({ 1 }, dst)
    end)

    it("extends into non-empty dst with offset range", function()
      local dst = { 100, 200 }
      list.extend(dst, { 10, 20, 30, 40 }, 2, 3)
      assert.are.same({ 100, 200, 20, 30 }, dst)
    end)
  end)

  describe("slice edge cases", function()
    it("handles start = 0 (extends before list start)", function()
      -- Lua for-loop from 0 will include index 0 which is nil
      local s = list.slice({ 10, 20, 30 }, 0)
      -- index 0 has nil, so only 1,2,3 are stored with gaps
      assert.are.equal(nil, s[1])
    end)

    it("handles finish beyond list length", function()
      local s = list.slice({ 10, 20 }, 1, 5)
      -- indices 3,4,5 are nil, only 10 and 20 are added
      assert.are.equal(10, s[1])
      assert.are.equal(20, s[2])
    end)

    it("returns new table even for single-element slice", function()
      local orig = { 42 }
      local s = list.slice(orig, 1, 1)
      assert.are.same({ 42 }, s)
      assert.are_not.equal(orig, s)
    end)
  end)

  describe("unique edge cases", function()
    it("handles boolean values", function()
      local t = { true, false, true, false }
      list.unique(t)
      assert.are.same({ true, false }, t)
    end)

    it("handles mixed types", function()
      local t = { 1, "1", 1, "1" }
      list.unique(t)
      assert.are.same({ 1, "1" }, t)
    end)

    it("key function returning same value collapses all", function()
      local t = { "a", "b", "c" }
      list.unique(t, function()
        return "same"
      end)
      assert.are.same({ "a" }, t)
    end)
  end)

  describe("bisect edge cases", function()
    it("lower bound: all elements equal to val", function()
      assert.are.equal(1, list.bisect({ 5, 5, 5, 5 }, 5))
    end)

    it("upper bound: all elements equal to val", function()
      assert.are.equal(5, list.bisect({ 5, 5, 5, 5 }, 5, { bound = "upper" }))
    end)

    it("lower bound: val smaller than all", function()
      assert.are.equal(1, list.bisect({ 10, 20, 30 }, 1))
    end)

    it("upper bound: val larger than all", function()
      assert.are.equal(4, list.bisect({ 10, 20, 30 }, 40, { bound = "upper" }))
    end)

    it("lower bound with lo and hi narrowing range", function()
      assert.are.equal(3, list.bisect({ 1, 2, 3, 4, 5 }, 3, { lo = 2, hi = 5 }))
    end)

    it("upper bound with lo and hi narrowing range", function()
      assert.are.equal(4, list.bisect({ 1, 2, 3, 4, 5 }, 3, { lo = 2, hi = 5, bound = "upper" }))
    end)

    it("key function with upper bound", function()
      local t = { { v = 1 }, { v = 2 }, { v = 2 }, { v = 3 } }
      local key = function(x)
        return x.v
      end
      assert.are.equal(4, list.bisect(t, { v = 2 }, { key = key, bound = "upper" }))
    end)

    it("handles large sorted list", function()
      local t = {}
      for i = 1, 1000 do
        t[i] = i * 2
      end
      assert.are.equal(500, list.bisect(t, 1000)) -- 1000 = t[500]
    end)
  end)

  describe("reverse edge cases", function()
    it("reverses list with mixed types", function()
      local t = { 1, "two", true }
      list.reverse(t)
      assert.are.same({ true, "two", 1 }, t)
    end)

    it("does not affect hash keys", function()
      local t = { 1, 2, 3, key = "value" }
      list.reverse(t)
      assert.are.same({ 3, 2, 1 }, { t[1], t[2], t[3] })
      assert.are.equal("value", t.key)
    end)
  end)

  describe("cartesian edge cases", function()
    it("handles empty outer list (produces one empty combo)", function()
      local result = list.cartesian {}
      -- With zero sets, combination_count is 1 (product of nothing)
      assert.are.equal(1, #result)
      assert.are.same({}, result[1])
    end)

    it("cartesian_iter yields one empty combo for empty sets", function()
      local count = 0
      for _ in list.cartesian_iter {} do
        count = count + 1
      end
      -- Product of zero dimensions is 1 (empty tuple)
      assert.are.equal(1, count)
    end)

    it("cartesian_iter_copy with single element sets", function()
      local results = {}
      for _, combo in list.cartesian_iter_copy { { "a" }, { "b" }, { "c" } } do
        results[#results + 1] = combo
      end
      assert.are.same({ { "a", "b", "c" } }, results)
    end)
  end)
end)
