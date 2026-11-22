-- ---------------------------------------------------------------------------
-- Integration tests: warp.api module composition
-- ---------------------------------------------------------------------------
-- Verifies that the public API surface correctly exposes all submodules
-- and that cross-module calls work through the API entry point.

package.loaded["wezterm"] = require "spec.mocks.wezterm"
package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

-- Cleared before warp.api loads, so the lazy-loading test sees a fresh state.
package.loaded["warp.log"] = nil
package.loaded["warp.ribbon"] = nil

local api = require "warp.api"

describe("api module composition", function()
  -- ── Modules load on first access ─────────────────────────────────────

  it("loads log and ribbon only when first read", function()
    assert.is_nil(package.loaded["warp.log"])
    assert.is_nil(package.loaded["warp.ribbon"])
    assert.is_nil(rawget(api, "log"))

    local log = api.log

    assert.are.equal(package.loaded["warp.log"], log)
    assert.are.equal(log, rawget(api, "log"))
    assert.is_nil(package.loaded["warp.ribbon"])
  end)

  it("returns nil for names that are not modules", function()
    assert.is_nil(api.nope)
  end)

  -- ── All submodules are accessible ────────────────────────────────────

  describe("exposes all submodules", function()
    it("contains all nine submodule fields", function()
      assert.is_table(api.list)
      assert.is_table(api.maths)
      assert.is_table(api.table)
      assert.is_table(api.filesystem)
      assert.is_table(api.path)
      assert.is_table(api.process)
      assert.is_table(api.string)
      assert.is_table(api.log)
      assert.is_table(api.ribbon)
    end)
  end)

  -- ── Cross-module calls through the API ───────────────────────────────

  describe("cross-module calls through api", function()
    it("string.pad uses maths.clamp (via api entry point)", function()
      -- api.string.pad delegates to api.maths.clamp internally
      assert.are.equal("hello", api.string.pad("hello", -5))
      assert.are.equal(" hello ", api.string.pad("hello", 1))
    end)

    it("path.shorten uses string.split (via api entry point)", function()
      local result = api.path.shorten("home/user/file.txt", 1)
      assert.are.equal("h/u/file.txt", result)
    end)

    it("path.shorten_to uses string.col_width (via api entry point)", function()
      local result = api.path.shorten_to("home/user/file.txt", 14)
      assert.is_true(api.string.col_width(result) <= 14)
    end)
  end)

  -- ── Standalone modules work independently ────────────────────────────

  describe("standalone modules are independent", function()
    it("list operations work without other modules", function()
      assert.is_true(api.list.contains({ 1, 2, 3 }, 2))
      assert.are.same({ 3, 2, 1 }, api.list.reverse { 1, 2, 3 })
    end)

    it("table operations work without other modules", function()
      assert.is_true(api.table.islist { "a", "b" })
      assert.are.same({ a = 1, b = 2 }, api.table.extend("force", { a = 1 }, { b = 2 }))
    end)

    it("maths operations work without other modules", function()
      assert.are.equal(2, api.maths.round(1.5))
      assert.are.equal(5, api.maths.clamp(10, 0, 5))
    end)
  end)

  -- ── Multi-module workflow through api ────────────────────────────────

  describe("multi-module workflow", function()
    it("measures, truncates, and pads a path", function()
      local full_path = "home/user/documents/project/README.md"
      local budget = 20

      -- Shorten via path (uses string internally)
      local short = api.path.shorten_to(full_path, budget)
      assert.is_true(api.string.fits(short, budget))

      -- Pad the result
      local padded = api.string.pad(short, 1)
      assert.are.equal(" " .. short .. " ", padded)
    end)

    it("splits a path and checks containment in list", function()
      local parts = api.string.split("src/components/Button.tsx", "/")
      assert.is_true(api.list.contains(parts, "components"))
      assert.is_false(api.list.contains(parts, "utils"))
    end)

    it("merges config tables then extracts nested value", function()
      local defaults = { ui = { theme = "dark", font_size = 12 } }
      local overrides = { ui = { font_size = 14 } }
      local config = api.table.deep_extend("force", defaults, overrides)
      assert.are.equal(14, api.table.get(config, "ui", "font_size"))
      assert.are.equal("dark", api.table.get(config, "ui", "theme"))
    end)
  end)
end)
