-- ---------------------------------------------------------------------------
-- Unit tests for warp.list  (busted)
-- ---------------------------------------------------------------------------

package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

local list = require "warp.list"

-- ── Helpers ──────────────────────────────────────────────────────────────

--- Collect index/combo pairs from a cartesian iterator.
local function collect_iter(iter)
  local t = {}
  for i, combo in iter do
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
    it("finds a present value", function()
      assert.is_true(list.contains({ 1, 2, 3 }, 2))
      assert.is_true(list.contains({ "a", "b", "c" }, "b"))
    end)

    it("returns false when value is absent", function()
      assert.is_false(list.contains({ 1, 2, 3 }, 4))
    end)

    it("returns false for empty list", function()
      assert.is_false(list.contains({}, 1))
    end)

    it("finds false as a value", function()
      assert.is_true(list.contains({ true, false, true }, false))
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
      assert.are.equal(dst, list.extend(dst, { 2 }))
    end)

    it("appends nothing from empty src", function()
      local dst = { 1, 2 }
      list.extend(dst, {})
      assert.are.same({ 1, 2 }, dst)
    end)

    it("respects start and finish parameters", function()
      local dst = {}
      list.extend(dst, { 10, 20, 30 }, 2)
      assert.are.same({ 20, 30 }, dst)

      dst = {}
      list.extend(dst, { 10, 20, 30 }, nil, 2)
      assert.are.same({ 10, 20 }, dst)

      dst = {}
      list.extend(dst, { 10, 20, 30, 40, 50 }, 2, 4)
      assert.are.same({ 20, 30, 40 }, dst)
    end)

    it("does nothing when start > finish", function()
      local dst = { 1 }
      list.extend(dst, { 10, 20, 30 }, 3, 1)
      assert.are.same({ 1 }, dst)
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

    it("slices with start and/or finish", function()
      assert.are.same({ 2, 3 }, list.slice({ 1, 2, 3 }, 2))
      assert.are.same({ 1, 2 }, list.slice({ 1, 2, 3 }, nil, 2))
      assert.are.same({ 2, 3, 4 }, list.slice({ 1, 2, 3, 4, 5 }, 2, 4))
    end)

    it("returns empty for invalid range or empty list", function()
      assert.are.same({}, list.slice({ 1, 2, 3 }, 3, 1))
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
    it("removes duplicates preserving first-occurrence order", function()
      local t = { "c", "a", "b", "a", "c" }
      list.unique(t)
      assert.are.same({ "c", "a", "b" }, t)
    end)

    it("returns the same table reference", function()
      local t = { 1, 2, 3 }
      assert.are.equal(t, list.unique(t))
    end)

    it("handles empty and single-element lists", function()
      local t = {}
      list.unique(t)
      assert.are.same({}, t)

      t = { 42 }
      list.unique(t)
      assert.are.same({ 42 }, t)
    end)

    it("shrinks the list on all-duplicate input", function()
      local t = { 5, 5, 5, 5 }
      list.unique(t)
      assert.are.same({ 5 }, t)
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

    it("deduplicates by string key", function()
      local t = { "abc", "ABC", "def", "abc" }
      list.unique(t, string.lower)
      assert.are.same({ "abc", "def" }, t)
    end)

    it("treats nil key return as always unique", function()
      local t = { 1, 2, 3 }
      list.unique(t, function()
        return nil
      end)
      assert.are.same({ 1, 2, 3 }, t)
    end)

    it("handles mixed types", function()
      local t = { 1, "1", 1, "1" }
      list.unique(t)
      assert.are.same({ 1, "1" }, t)
    end)
  end)

  -- ── bisect ───────────────────────────────────────────────────────────

  describe("bisect", function()
    describe("lower bound (default)", function()
      it("finds insertion point", function()
        assert.are.equal(1, list.bisect({ 2, 4, 6 }, 1))
        assert.are.equal(2, list.bisect({ 1, 3, 5, 7 }, 3))
        assert.are.equal(4, list.bisect({ 1, 2, 3 }, 4))
      end)

      it("returns first position of duplicates", function()
        assert.are.equal(4, list.bisect({ 1, 2, 2, 3, 3, 3 }, 3))
        assert.are.equal(1, list.bisect({ 5, 5, 5, 5 }, 5))
      end)

      it("handles empty and single-element lists", function()
        assert.are.equal(1, list.bisect({}, 5))
        assert.are.equal(1, list.bisect({ 5 }, 3))
        assert.are.equal(2, list.bisect({ 5 }, 8))
        assert.are.equal(1, list.bisect({ 5 }, 5))
      end)

      it("respects lo and hi options", function()
        assert.are.equal(3, list.bisect({ 1, 2, 3, 4, 5 }, 3, { lo = 3 }))
        assert.are.equal(3, list.bisect({ 1, 2, 5, 7 }, 5, { hi = 3 }))
        assert.are.equal(3, list.bisect({ 1, 2, 3, 4, 5 }, 3, { lo = 2, hi = 5 }))
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
        assert.are.equal(5, list.bisect({ 5, 5, 5, 5 }, 5, { bound = "upper" }))
      end)

      it("returns correct position for non-duplicate values", function()
        assert.are.equal(3, list.bisect({ 1, 2, 4, 5 }, 2, { bound = "upper" }))
        assert.are.equal(1, list.bisect({ 2, 4, 6 }, 1, { bound = "upper" }))
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
    it("reverses a list in-place", function()
      local t = { 1, 2, 3, 4, 5 }
      list.reverse(t)
      assert.are.same({ 5, 4, 3, 2, 1 }, t)
    end)

    it("returns the same table reference", function()
      local t = { 1, 2, 3 }
      assert.are.equal(t, list.reverse(t))
    end)

    it("handles empty and single-element lists", function()
      local t = {}
      list.reverse(t)
      assert.are.same({}, t)

      t = { 42 }
      list.reverse(t)
      assert.are.same({ 42 }, t)
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

    it("produces correct count for larger sets", function()
      local results =
        collect_iter(list.cartesian_iter { { 1, 2, 3 }, { "a", "b" }, { true, false } })
      assert.are.equal(3 * 2 * 2, #results)
    end)

    it("reuses the same combo table (shared reference)", function()
      local seen = {}
      for _, combo in list.cartesian_iter { { 1, 2 }, { "a" } } do
        seen[#seen + 1] = combo
      end
      assert.are.equal(seen[1], seen[2])
    end)

    it("handles empty outer list (produces one empty combo)", function()
      local count = 0
      for _ in list.cartesian_iter {} do
        count = count + 1
      end
      assert.are.equal(1, count)
    end)
  end)

  -- ── cartesian_iter_copy ──────────────────────────────────────────────

  describe("cartesian_iter_copy", function()
    it("produces all combinations as independent copies", function()
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
      assert.are_not.equal(results[1], results[2])
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

    it("count matches product of set sizes", function()
      local result = list.cartesian { { 1, 2, 3 }, { "a", "b" } }
      assert.are.equal(6, #result)
    end)

    it("handles empty outer list", function()
      local result = list.cartesian {}
      assert.are.equal(1, #result)
      assert.are.same({}, result[1])
    end)
  end)
end)
