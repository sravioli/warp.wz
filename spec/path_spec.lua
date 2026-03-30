-- ---------------------------------------------------------------------------
-- Unit tests for warp.path  (busted)
-- ---------------------------------------------------------------------------
-- Run:  busted spec/path_spec.lua
-- ---------------------------------------------------------------------------

-- ── Mocks ────────────────────────────────────────────────────────────────

-- Provide mocks before the SUT is loaded.
package.loaded["wezterm"] = require "spec.mocks.wezterm"
package.loaded["warp.maths"] = require "spec.mocks.maths"

-- Adjust package.path so modules resolve.
package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

local path = require "warp.path"

-- ── Tests ────────────────────────────────────────────────────────────────

describe("warp.path", function()
  -- ── is_win ───────────────────────────────────────────────────────────

  describe("is_win", function()
    it("is false for the default mock triple (linux)", function()
      assert.is_false(path.is_win)
    end)
  end)

  -- ── separator ────────────────────────────────────────────────────────

  describe("separator", function()
    it("is / on non-Windows", function()
      assert.are.equal("/", path.separator)
    end)
  end)

  -- ── shorten ──────────────────────────────────────────────────────────

  describe("shorten", function()
    it("shortens intermediate components to given length", function()
      assert.are.equal("h/u/file.txt", path.shorten("home/user/file.txt", 1))
    end)

    it("keeps the last component intact", function()
      assert.are.equal("ho/us/file.txt", path.shorten("home/user/file.txt", 2))
    end)

    it("returns original when len >= all component lengths", function()
      assert.are.equal("home/user/file.txt", path.shorten("home/user/file.txt", 10))
    end)

    it("handles rooted path", function()
      assert.are.equal("/h/u/file.txt", path.shorten("/home/user/file.txt", 1))
    end)

    it("handles single component (no separator)", function()
      assert.are.equal("file.txt", path.shorten("file.txt", 1))
    end)

    it("handles two components", function()
      assert.are.equal("h/file.txt", path.shorten("home/file.txt", 1))
    end)

    it("handles len = 0 (empty short breaks early)", function()
      -- When len=0, string.sub(part, 1, 0) returns "", which triggers break
      assert.are.equal("", path.shorten("home/user/file.txt", 0))
    end)

    it("preserves trailing component as-is", function()
      assert.are.equal(
        "s/d/really-long-filename.tar.gz",
        path.shorten("src/deep/really-long-filename.tar.gz", 1)
      )
    end)

    it("handles rooted single component", function()
      assert.are.equal("/file.txt", path.shorten("/file.txt", 1))
    end)
  end)

  -- ── shorten_to ───────────────────────────────────────────────────────

  describe("shorten_to", function()
    it("returns full path when it fits", function()
      assert.are.equal("home/user/file.txt", path.shorten_to("home/user/file.txt", 50))
    end)

    it("shortens intermediate dirs to fit budget", function()
      local result = path.shorten_to("home/user/file.txt", 18)
      -- 18 cols = full path fits exactly (h-o-m-e / u-s-e-r / f-i-l-e-.-t-x-t = 18)
      assert.are.equal("home/user/file.txt", result)
    end)

    it("shortens directories to 1 char when tight", function()
      local result = path.shorten_to("home/user/file.txt", 14)
      -- sep_count=2, sep_w=2, last_w=8, dir_budget=14-2-8=4, dirs=2, per=2
      assert.are.equal("ho/us/file.txt", result)
    end)

    it("middle-truncates bare filename when no dirs", function()
      local result = path.shorten_to("averylongfilename.txt", 10)
      -- No dirs → truncate_middle("averylongfilename.txt", 10)
      -- remaining=9, left=5, right=4 → "avery….txt"
      assert.are.equal("avery….txt", result)
    end)

    it("returns ellipsis for very tight budget on bare name", function()
      local result = path.shorten_to("longname", 1)
      assert.are.equal("…", result)
    end)

    it("strips trailing slashes", function()
      local result = path.shorten_to("home/user/dir///", 50)
      assert.are.equal("home/user/dir", result)
    end)

    it("handles rooted path", function()
      local result = path.shorten_to("/home/user/file.txt", 50)
      assert.are.equal("/home/user/file.txt", result)
    end)

    it("handles single-dir path within budget", function()
      assert.are.equal("dir/file.txt", path.shorten_to("dir/file.txt", 20))
    end)

    it("shortens single dir when tight", function()
      local result = path.shorten_to("directory/file.txt", 12)
      -- sep_count=1, sep_w=1, last_w=8, dir_budget=12-1-8=3, dirs=1, per=3
      assert.are.equal("dir/file.txt", result)
    end)
  end)

  -- ── truncate_middle (tested via shorten_to) ──────────────────────────

  describe("truncate_middle via shorten_to", function()
    it("returns string unchanged when it fits budget", function()
      assert.are.equal("short", path.shorten_to("short", 10))
    end)

    it("truncates middle with ellipsis", function()
      local result = path.shorten_to("abcdefghij", 6)
      -- truncate_middle("abcdefghij", 6)
      -- remaining=5, left=3, right=2
      assert.are.equal("abc…ij", result)
    end)

    it("handles budget equal to string width (no truncation)", function()
      assert.are.equal("abcde", path.shorten_to("abcde", 5))
    end)

    it("handles budget of 2 on long name", function()
      local result = path.shorten_to("abcdefgh", 2)
      -- remaining=1, left=1, right=0
      assert.are.equal("a…", result)
    end)

    it("handles budget of 3 on long name", function()
      local result = path.shorten_to("abcdefgh", 3)
      -- remaining=2, left=1, right=1
      assert.are.equal("a…h", result)
    end)
  end)

  -- ── concat ───────────────────────────────────────────────────────────

  describe("concat", function()
    it("joins two components", function()
      assert.are.equal("home/user", path.concat("home", "user"))
    end)

    it("joins three components", function()
      assert.are.equal("home/user/docs", path.concat("home", "user", "docs"))
    end)

    it("joins single component", function()
      assert.are.equal("home", path.concat "home")
    end)

    it("handles empty components", function()
      assert.are.equal("/home/", path.concat("", "home", ""))
    end)
  end)
end)
