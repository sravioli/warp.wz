-- ---------------------------------------------------------------------------
-- Unit tests for warp.maths  (busted)
-- ---------------------------------------------------------------------------

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

    it("applies half-to-even rule on positive halves", function()
      assert.are.equal(0, maths.round(0.5)) -- even=0
      assert.are.equal(2, maths.round(1.5)) -- even=2
      assert.are.equal(2, maths.round(2.5)) -- even=2
      assert.are.equal(4, maths.round(3.5)) -- even=4
    end)

    it("applies half-to-even rule on negative halves", function()
      assert.are.equal(0, maths.round(-0.5)) -- even=0
      assert.are.equal(-2, maths.round(-1.5)) -- even=-2
      assert.are.equal(-2, maths.round(-2.5)) -- even=-2
      assert.are.equal(-4, maths.round(-3.5)) -- even=-4
    end)

    it("returns integer unchanged", function()
      assert.are.equal(5, maths.round(5))
      assert.are.equal(0, maths.round(0))
    end)

    it("handles negative non-half values", function()
      assert.are.equal(-3, maths.round(-3.2))
      assert.are.equal(-4, maths.round(-3.7))
    end)
  end)

  -- ── round_to ─────────────────────────────────────────────────────────

  describe("round_to", function()
    it("rounds to nearest multiple", function()
      assert.are.equal(10, maths.round_to(12, 5))
      assert.are.equal(20, maths.round_to(17, 10))
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
      assert.are.equal(-9, maths.round_to(-10, 3))
    end)

    it("uses half-to-even on tie-breaking", function()
      -- 7.5 / 5 = 1.5 → even=2 → 10
      assert.are.equal(10, maths.round_to(7.5, 5))
      -- 12.5 / 5 = 2.5 → even=2 → 10
      assert.are.equal(10, maths.round_to(12.5, 5))
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

    it("returns boundary when number equals boundary", function()
      assert.are.equal(0, maths.clamp(0, 0, 10))
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
      assert.are.equal(0.1, maths.clamp(0.05, 0.1, 0.9))
      assert.are.equal(0.9, maths.clamp(1.0, 0.1, 0.9))
    end)

    it("handles extreme values", function()
      assert.are.equal(1e10, maths.clamp(1e15, 0, 1e10))
      assert.are.equal(0, maths.clamp(-math.huge, 0, 10))
      assert.are.equal(10, maths.clamp(math.huge, 0, 10))
    end)
  end)
end)
