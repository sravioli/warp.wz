-- ---------------------------------------------------------------------------
-- Integration tests: warp.string ↔ warp.maths
-- ---------------------------------------------------------------------------
-- string.pad() delegates to maths.clamp() for padding normalization.
-- These tests verify the real modules work together without mocks.

package.loaded["wezterm"] = require "spec.mocks.wezterm"
package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

local str = require "warp.string"

describe("string + maths integration", function()
  describe("pad uses maths.clamp for padding bounds", function()
    it("negative padding is clamped to zero (no padding added)", function()
      assert.are.equal("hello", str.pad("hello", -5))
      assert.are.equal("hello", str.pad("hello", { left = -3, right = -1 }))
    end)

    it("zero padding produces the original string", function()
      assert.are.equal("hello", str.pad("hello", 0))
    end)

    it("positive padding adds correct whitespace", function()
      assert.are.equal("  hello  ", str.pad("hello", 2))
    end)

    it("mixed negative and positive padding clamps only the negative side", function()
      assert.are.equal("hello   ", str.pad("hello", { left = -1, right = 3 }))
      assert.are.equal("   hello", str.pad("hello", { left = 3, right = -1 }))
    end)

    it("large padding values pass through clamping unchanged", function()
      local result = str.pad("x", 100)
      -- 100 spaces on each side + "x" = 201 chars
      assert.are.equal(201, #result)
    end)
  end)

  describe("padl and padr with clamped values", function()
    it("padl clamps negative padding to zero", function()
      assert.are.equal("hello", str.padl("hello", -5))
    end)

    it("padr clamps negative padding to zero", function()
      assert.are.equal("hello", str.padr("hello", -5))
    end)

    it("asymmetric padding table with one nil side", function()
      assert.are.equal(" hello", str.pad("hello", { left = 1, right = nil }))
      assert.are.equal("hello ", str.pad("hello", { left = nil, right = 1 }))
    end)
  end)
end)
