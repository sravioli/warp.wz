-- ---------------------------------------------------------------------------
-- Integration tests: warp.path ↔ warp.string ↔ warp.maths (full stack)
-- ---------------------------------------------------------------------------
-- Exercises the full dependency chain: maths → string → path
-- All three real modules loaded together, only wezterm is mocked.

package.loaded["wezterm"] = require "spec.mocks.wezterm"
package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

local maths = require "warp.maths"
local str = require "warp.string"
local path = require "warp.path"

describe("path + string + maths full-stack integration", function()
  -- ── Padding then truncation pipeline ─────────────────────────────────

  describe("pad → truncate pipeline", function()
    it("padded string can be truncated back to budget", function()
      local padded = str.pad("status", 3)
      assert.are.equal("   status   ", padded)
      local truncated = str.truncate_right(padded, 8)
      assert.are.equal("   stat…", truncated)
      assert.is_true(str.col_width(truncated) <= 8)
    end)

    it("negative pad (clamped via maths) then truncate is identity-like", function()
      local padded = str.pad("hello", -10) -- clamped to 0 by maths
      assert.are.equal("hello", padded)
      local truncated = str.truncate_right(padded, 10)
      assert.are.equal("hello", truncated)
    end)
  end)

  -- ── Width measurement feeds path budget correctly ────────────────────

  describe("col_width feeds path.shorten_to budget", function()
    it("shorten_to at exact measured width returns full path", function()
      local p = "home/user/file.txt"
      local w = str.col_width(p)
      assert.are.equal(p, path.shorten_to(p, w))
    end)

    it("shorten_to below measured width abbreviates", function()
      local p = "home/user/documents/file.txt"
      local w = str.col_width(p)
      local result = path.shorten_to(p, w - 5)
      assert.is_true(str.col_width(result) <= w - 5)
      assert.are_not.equal(p, result)
    end)
  end)

  -- ── Round-trip: clamp → pad → width → fits ───────────────────────────

  describe("clamp → pad → width → fits round-trip", function()
    it("clamped padding produces predictable width", function()
      local pad_val = maths.clamp(-3, 0, 100) -- clamp to 0
      assert.are.equal(0, pad_val)

      local padded = str.pad("x", pad_val)
      assert.are.equal("x", padded)
      assert.are.equal(1, str.col_width(padded))
    end)

    it("positive clamped padding produces expected width", function()
      local pad_val = maths.clamp(5, 0, 10) -- stays 5
      assert.are.equal(5, pad_val)

      local padded = str.pad("a", pad_val)
      -- "a" + 5 left + 5 right = 11
      assert.are.equal(11, str.col_width(padded))
      assert.is_false(str.fits(padded, 10))
      assert.is_true(str.fits(padded, 11))
    end)
  end)

  -- ── Path shortening with split + width + truncation ──────────────────

  describe("shorten → col_width → shorten_to pipeline", function()
    it("shorten reduces width, shorten_to enforces exact budget", function()
      local original = "src/components/layout/header/Navigation.tsx"
      local shortened = path.shorten(original, 2)
      local budget = 25

      -- shorten reduces intermediate dirs
      assert.is_true(str.col_width(shortened) < str.col_width(original))

      -- shorten_to enforces exact budget
      local fitted = path.shorten_to(original, budget)
      assert.is_true(str.col_width(fitted) <= budget)
    end)
  end)

  -- ── Real-world: tab title formatting scenario ────────────────────────

  describe("real-world tab title formatting", function()
    it("formats a long path for a narrow tab", function()
      local cwd = "home/user/.config/wezterm/plugins/warp.wz"
      local tab_width = 20

      local short = path.shorten_to(cwd, tab_width)
      assert.is_true(str.col_width(short) <= tab_width)
      -- Should still look like a path
      assert.is_truthy(short:find("/"))
    end)

    it("formats and pads a short name for a wide tab", function()
      local name = "main"
      local tab_width = 20

      -- Pad to center the name
      local side = math.floor((tab_width - str.col_width(name)) / 2)
      local padded = str.pad(name, side)
      assert.is_true(str.col_width(padded) <= tab_width + 1)
    end)
  end)
end)
