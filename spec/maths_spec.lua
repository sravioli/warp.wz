-- ---------------------------------------------------------------------------
-- Unit tests for warp.maths  (busted)
-- ---------------------------------------------------------------------------
-- Run:  busted spec/maths_spec.lua
-- ---------------------------------------------------------------------------

-- Adjust package.path so `require "warp.maths"` resolves.
package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

local maths = require "warp.maths"

describe("warp.maths", function()
  -- ── round (half-to-even / banker's rounding) ─────────────────────────

  describe("round", function()
    it("rounds down when fractional part < 0.5", function()
      assert.are.equal(3, maths.round(3.2))
    end)

    it("rounds up when fractional part > 0.5", function()
      assert.are.equal(4, maths.round(3.7))
    end)

    it("rounds 0.5 to nearest even (0)", function()
      assert.are.equal(0, maths.round(0.5))
    end)

    it("rounds 1.5 to nearest even (2)", function()
      assert.are.equal(2, maths.round(1.5))
    end)

    it("rounds 2.5 to nearest even (2)", function()
      assert.are.equal(2, maths.round(2.5))
    end)

    it("rounds 3.5 to nearest even (4)", function()
      assert.are.equal(4, maths.round(3.5))
    end)

    it("rounds 4.5 to nearest even (4)", function()
      assert.are.equal(4, maths.round(4.5))
    end)

    it("returns integer unchanged", function()
      assert.are.equal(5, maths.round(5))
    end)

    it("returns 0 for 0", function()
      assert.are.equal(0, maths.round(0))
    end)

    it("handles negative: rounds toward zero when < 0.5", function()
      assert.are.equal(-3, maths.round(-3.2))
    end)

    it("handles negative: rounds away from zero when > 0.5", function()
      assert.are.equal(-4, maths.round(-3.7))
    end)

    it("handles negative half: -0.5 rounds to 0 (even)", function()
      assert.are.equal(0, maths.round(-0.5))
    end)

    it("handles negative half: -1.5 rounds to -2 (even)", function()
      assert.are.equal(-2, maths.round(-1.5))
    end)

    it("handles negative half: -2.5 rounds to -2 (even)", function()
      assert.are.equal(-2, maths.round(-2.5))
    end)

    it("handles large numbers", function()
      assert.are.equal(1000000, maths.round(1000000.3))
    end)

    it("handles very small fractional part", function()
      assert.are.equal(1, maths.round(1.0000001))
    end)
  end)

  -- ── round_to ─────────────────────────────────────────────────────────

  describe("round_to", function()
    it("rounds to nearest multiple of 5", function()
      assert.are.equal(10, maths.round_to(12, 5))
    end)

    it("rounds to nearest multiple of 10", function()
      assert.are.equal(20, maths.round_to(17, 10))
    end)

    it("rounds to nearest multiple of 3", function()
      assert.are.equal(9, maths.round_to(10, 3))
    end)

    it("returns exact multiple unchanged", function()
      assert.are.equal(15, maths.round_to(15, 5))
    end)

    it("rounds 0 to 0 for any multiple", function()
      assert.are.equal(0, maths.round_to(0, 7))
    end)

    it("rounds negative numbers", function()
      assert.are.equal(-10, maths.round_to(-12, 5))
    end)

    it("rounds to nearest multiple of 1 (identity)", function()
      assert.are.equal(7, maths.round_to(7, 1))
    end)

    it("rounds to nearest multiple of 100", function()
      assert.are.equal(200, maths.round_to(250, 100))
    end)

    it("uses half-to-even: 7.5 with multiple 5 rounds to 10", function()
      -- 7.5 / 5 = 1.5 → rounds to 2 (even) → 2 * 5 = 10
      assert.are.equal(10, maths.round_to(7.5, 5))
    end)

    it("uses half-to-even: 12.5 with multiple 5 rounds to 10", function()
      -- 12.5 / 5 = 2.5 → rounds to 2 (even) → 2 * 5 = 10
      assert.are.equal(10, maths.round_to(12.5, 5))
    end)

    it("rounds small values to nearest multiple of 2", function()
      assert.are.equal(4, maths.round_to(3, 2))
    end)

    it("rounds with large multiple", function()
      assert.are.equal(1000, maths.round_to(1200, 1000))
    end)
  end)

  -- ── clamp ────────────────────────────────────────────────────────────

  describe("clamp", function()
    it("returns number when within range", function()
      assert.are.equal(5, maths.clamp(5, 0, 10))
    end)

    it("clamps to minimum when below range", function()
      assert.are.equal(0, maths.clamp(-5, 0, 10))
    end)

    it("clamps to maximum when above range", function()
      assert.are.equal(10, maths.clamp(15, 0, 10))
    end)

    it("returns minimum when number equals minimum", function()
      assert.are.equal(0, maths.clamp(0, 0, 10))
    end)

    it("returns maximum when number equals maximum", function()
      assert.are.equal(10, maths.clamp(10, 0, 10))
    end)

    it("works with negative range", function()
      assert.are.equal(-5, maths.clamp(-10, -5, -1))
    end)

    it("works when min equals max", function()
      assert.are.equal(5, maths.clamp(3, 5, 5))
      assert.are.equal(5, maths.clamp(7, 5, 5))
      assert.are.equal(5, maths.clamp(5, 5, 5))
    end)

    it("works with floating-point values", function()
      assert.are.equal(0.5, maths.clamp(0.5, 0, 1))
    end)

    it("clamps float to float minimum", function()
      assert.are.equal(0.1, maths.clamp(0.05, 0.1, 0.9))
    end)

    it("clamps float to float maximum", function()
      assert.are.equal(0.9, maths.clamp(1.0, 0.1, 0.9))
    end)

    it("handles large numbers", function()
      assert.are.equal(1e10, maths.clamp(1e15, 0, 1e10))
    end)

    it("handles math.huge as maximum", function()
      assert.are.equal(100, maths.clamp(100, 0, math.huge))
    end)

    it("clamps to 0 with math.huge upper bound", function()
      assert.are.equal(0, maths.clamp(-1, 0, math.huge))
    end)
  end)
end)
