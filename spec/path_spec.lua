-- ---------------------------------------------------------------------------
-- Unit tests for warp.path  (busted)
-- ---------------------------------------------------------------------------

-- ── Mocks ────────────────────────────────────────────────────────────────

package.loaded["wezterm"] = require "spec.mocks.wezterm"
package.loaded["warp.maths"] = require "spec.mocks.maths"

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
      assert.are.equal("ho/us/file.txt", path.shorten("home/user/file.txt", 2))
      assert.are.equal("doc/pro/myfile.txt", path.shorten("documents/projects/myfile.txt", 3))
    end)

    it("returns original when len >= all component lengths", function()
      assert.are.equal("home/user/file.txt", path.shorten("home/user/file.txt", 10))
      assert.are.equal("ab/cd/ef/file.txt", path.shorten("ab/cd/ef/file.txt", 100))
    end)

    it("handles rooted paths", function()
      assert.are.equal("/h/u/file.txt", path.shorten("/home/user/file.txt", 1))
      assert.are.equal("/file.txt", path.shorten("/file.txt", 1))
      assert.are.equal("/d/file.txt", path.shorten("/dir/file.txt", 1))
    end)

    it("handles single or two components", function()
      assert.are.equal("file.txt", path.shorten("file.txt", 1))
      assert.are.equal("hello", path.shorten("hello", 1))
      assert.are.equal("h/file.txt", path.shorten("home/file.txt", 1))
    end)

    it("handles len = 0 (empty short breaks early)", function()
      assert.are.equal("", path.shorten("home/user/file.txt", 0))
    end)

    it("preserves trailing component as-is", function()
      assert.are.equal(
        "s/d/really-long-filename.tar.gz",
        path.shorten("src/deep/really-long-filename.tar.gz", 1)
      )
    end)

    it("handles empty path", function()
      assert.are.equal("", path.shorten("", 1))
    end)

    it("handles deeply nested path with 1-char components", function()
      assert.are.equal("a/b/c/d/e/f/file.txt", path.shorten("a/b/c/d/e/f/file.txt", 1))
    end)
  end)

  -- ── shorten_to ───────────────────────────────────────────────────────

  describe("shorten_to", function()
    it("returns full path when it fits", function()
      assert.are.equal("home/user/file.txt", path.shorten_to("home/user/file.txt", 50))
      assert.are.equal("home/user/file.txt", path.shorten_to("home/user/file.txt", 18))
      assert.are.equal("src/file.txt", path.shorten_to("src/file.txt", 12))
    end)

    it("shortens directories to fit budget", function()
      local result = path.shorten_to("home/user/file.txt", 14)
      assert.are.equal("ho/us/file.txt", result)
    end)

    it("shortens single dir when tight", function()
      assert.are.equal("dir/file.txt", path.shorten_to("directory/file.txt", 12))
    end)

    it("middle-truncates bare filename when no dirs", function()
      assert.are.equal("avery….txt", path.shorten_to("averylongfilename.txt", 10))
      assert.are.equal("abc…ij", path.shorten_to("abcdefghij", 6))
      assert.are.equal("a…h", path.shorten_to("abcdefgh", 3))
      assert.are.equal("a…", path.shorten_to("abcdefgh", 2))
    end)

    it("returns ellipsis for very tight budget on bare name", function()
      assert.are.equal("…", path.shorten_to("longname", 1))
    end)

    it("strips trailing slashes", function()
      assert.are.equal("home/user/dir", path.shorten_to("home/user/dir///", 50))
    end)

    it("handles rooted path", function()
      assert.are.equal("/home/user/file.txt", path.shorten_to("/home/user/file.txt", 50))
      assert.are.equal("file.txt", path.shorten_to("/file.txt", 20))
    end)

    it("handles bare filename within budget", function()
      assert.are.equal("file.txt", path.shorten_to("file.txt", 20))
      assert.are.equal("short", path.shorten_to("short", 10))
      assert.are.equal("hello", path.shorten_to("hello", 5))
      assert.are.equal("abcde", path.shorten_to("abcde", 5))
    end)

    it("handles empty path", function()
      assert.are.equal("", path.shorten_to("", 10))
    end)

    it("handles deeply nested path with tight budget", function()
      assert.are.equal("a/b/c/d/file.txt", path.shorten_to("a/b/c/d/file.txt", 16))
    end)
  end)

  -- ── concat ───────────────────────────────────────────────────────────

  describe("concat", function()
    it("joins components with separator", function()
      assert.are.equal("home/user", path.concat("home", "user"))
      assert.are.equal("home/user/docs", path.concat("home", "user", "docs"))
      assert.are.equal("a/b/c/d/e", path.concat("a", "b", "c", "d", "e"))
    end)

    it("joins single component", function()
      assert.are.equal("home", path.concat "home")
    end)

    it("handles empty components", function()
      assert.are.equal("/home/", path.concat("", "home", ""))
      assert.are.equal("/", path.concat("", ""))
    end)
  end)
end)
