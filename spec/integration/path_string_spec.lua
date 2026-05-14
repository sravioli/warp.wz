-- ---------------------------------------------------------------------------
-- Integration tests: warp.path ↔ warp.string
-- ---------------------------------------------------------------------------
-- path.shorten() uses string.split() for component splitting.
-- path.shorten_to() uses string.col_width() for column measurement.
-- path's local truncate_middle uses string.col_width() + wt.truncate_right().

package.loaded["wezterm"] = require "spec.mocks.wezterm"
package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

local path = require "warp.path"
local str = require "warp.string"

describe("path + string integration", function()
  -- ── shorten relies on string.split ───────────────────────────────────

  describe("shorten uses string.split for path decomposition", function()
    it("splits and truncates each intermediate component", function()
      local result = path.shorten("home/user/documents/project/file.txt", 1)
      -- string.split decomposes by "/", then shorten abbreviates each
      assert.are.equal("h/u/d/p/file.txt", result)
    end)

    it("split handles single-component path (no separator)", function()
      assert.are.equal("readme.md", path.shorten("readme.md", 1))
    end)

    it("split handles consecutive separators via root path", function()
      assert.are.equal("/h/u/file.txt", path.shorten("/home/user/file.txt", 1))
    end)
  end)

  -- ── shorten_to relies on string.col_width ────────────────────────────

  describe("shorten_to uses string.col_width for budget calculations", function()
    it("measures last component width to compute dir budget", function()
      -- "file.txt" is 8 cols, 2 seps = 2 cols, budget=14 → 4 cols for dirs
      local result = path.shorten_to("home/user/file.txt", 14)
      assert.are.equal("ho/us/file.txt", result)
      -- Verify col_width agrees on the result
      assert.is_true(str.col_width(result) <= 14)
    end)

    it("measures separator width correctly", function()
      local result = path.shorten_to("a/b/c/d/file.txt", 16)
      assert.are.equal("a/b/c/d/file.txt", result)
      assert.is_true(str.col_width(result) <= 16)
    end)

    it("middle-truncates bare filename using col_width", function()
      local result = path.shorten_to("averylongfilename.txt", 10)
      assert.are.equal("avery….txt", result)
      assert.is_true(str.col_width(result) <= 10)
    end)
  end)

  -- ── shorten_to middle-truncation uses col_width in truncate_middle ───

  describe("shorten_to middle-truncation measures with col_width", function()
    it("truncates last component when dirs consume all budget", function()
      -- Very tight budget forces 1-char dirs AND middle-truncates the last part
      local result = path.shorten_to("src/components/MyVeryLongComponentName.tsx", 20)
      assert.is_true(str.col_width(result) <= 20)
      -- Result still contains "/" separators, preserving path shape.
      assert.is_truthy(result:find "/")
    end)

    it("column budget is respected for unicode paths", function()
      local result = path.shorten_to("données/utilisateur/fichier.txt", 20)
      assert.is_true(str.col_width(result) <= 20)
    end)
  end)

  -- ── width and fits agree with path measurements ──────────────────────

  describe("string.fits agrees with path output widths", function()
    it("full path fits when budget is generous", function()
      local p = "home/user/file.txt"
      assert.is_true(str.fits(path.shorten_to(p, 50), 50))
    end)

    it("shortened path fits within its budget", function()
      local budgets = { 15, 20, 25, 30 }
      for _, budget in ipairs(budgets) do
        local result = path.shorten_to("home/user/documents/project/file.txt", budget)
        assert.is_true(
          str.fits(result, budget),
          "shorten_to result '" .. result .. "' exceeds budget " .. budget
        )
      end
    end)
  end)
end)
