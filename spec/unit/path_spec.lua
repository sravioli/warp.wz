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

  -- ── normalize ────────────────────────────────────────────────────────

  describe("normalize", function()
    it("collapses repeated slashes", function()
      assert.are.equal("/home/user", path.normalize "//home///user")
    end)

    it("resolves single dot", function()
      assert.are.equal("home/user", path.normalize "home/./user")
    end)

    it("resolves double dot", function()
      assert.are.equal("/home", path.normalize "/home/user/..")
    end)

    it("resolves complex relative path", function()
      assert.are.equal("a/d", path.normalize "a/b/c/../../d")
    end)

    it("preserves leading tilde", function()
      assert.are.equal("~/projects", path.normalize "~/./projects")
    end)

    it("normalizes backslashes", function()
      assert.are.equal("/home/user", path.normalize "\\home\\user")
    end)

    it("does not go above root", function()
      assert.are.equal("/", path.normalize "/../..")
    end)

    it("returns dot for empty result", function()
      assert.are.equal(".", path.normalize "")
    end)

    it("keeps .. for relative paths above cwd", function()
      assert.are.equal("../..", path.normalize "a/../../..")
    end)

    it("handles root path", function()
      assert.are.equal("/", path.normalize "/")
    end)

    it("handles tilde alone", function()
      assert.are.equal("~", path.normalize "~")
    end)

    it("handles tilde with trailing slash", function()
      assert.are.equal("~", path.normalize "~/")
    end)
  end)

  -- ── dirname ──────────────────────────────────────────────────────────

  describe("dirname", function()
    it("returns parent of file path", function()
      assert.are.equal("/home/user", path.dirname "/home/user/file.txt")
    end)

    it("returns parent of directory path", function()
      assert.are.equal("/home", path.dirname "/home/user/")
    end)

    it("returns / for root-level file", function()
      assert.are.equal("/", path.dirname "/file.txt")
    end)

    it("returns . for bare filename", function()
      assert.are.equal(".", path.dirname "file.txt")
    end)

    it("returns . for empty string", function()
      assert.are.equal(".", path.dirname "")
    end)

    it("handles tilde path", function()
      assert.are.equal("~/projects", path.dirname "~/projects/repo")
    end)

    it("handles backslashes", function()
      assert.are.equal("home/user", path.dirname "home\\user\\file.txt")
    end)

    it("returns / for root", function()
      assert.are.equal("/", path.dirname "/")
    end)
  end)

  -- ── extension ────────────────────────────────────────────────────────

  describe("extension", function()
    it("returns extension with dot", function()
      assert.are.equal(".lua", path.extension "init.lua")
    end)

    it("returns last extension for double extension", function()
      assert.are.equal(".gz", path.extension "archive.tar.gz")
    end)

    it("returns empty for no extension", function()
      assert.are.equal("", path.extension "Makefile")
    end)

    it("returns empty for dotfile without extension", function()
      assert.are.equal("", path.extension ".gitignore")
    end)

    it("returns extension for dotfile with extension", function()
      assert.are.equal(".md", path.extension ".readme.md")
    end)

    it("works with full path", function()
      assert.are.equal(".toml", path.extension "/home/user/config.toml")
    end)

    it("returns empty for trailing dot", function()
      assert.are.equal("", path.extension "file.")
    end)

    it("returns empty for empty string", function()
      assert.are.equal("", path.extension "")
    end)
  end)

  -- ── is_absolute ──────────────────────────────────────────────────────

  describe("is_absolute", function()
    it("detects unix absolute path", function()
      assert.is_true(path.is_absolute "/home/user")
    end)

    it("detects relative path", function()
      assert.is_false(path.is_absolute "home/user")
    end)

    it("detects windows drive letter with backslash", function()
      assert.is_true(path.is_absolute "C:\\Users")
    end)

    it("detects windows drive letter with forward slash", function()
      assert.is_true(path.is_absolute "C:/Users")
    end)

    it("rejects bare drive letter without separator", function()
      assert.is_false(path.is_absolute "C:file")
    end)

    it("rejects tilde as not absolute", function()
      assert.is_false(path.is_absolute "~/projects")
    end)

    it("rejects empty string", function()
      assert.is_false(path.is_absolute "")
    end)

    it("detects lowercase windows drive", function()
      assert.is_true(path.is_absolute "d:/data")
    end)
  end)

  -- ── expand ───────────────────────────────────────────────────────────

  describe("expand", function()
    it("expands tilde to home directory", function()
      local result = path.expand "~/projects"
      assert.is_true(result:find "/projects$" ~= nil)
      assert.is_true(result:sub(1, 1) ~= "~")
    end)

    it("expands bare tilde", function()
      local result = path.expand "~"
      assert.is_true(result ~= "~")
    end)

    it("does not expand tilde in the middle", function()
      assert.are.equal("/home/~user", path.expand "/home/~user")
    end)

    it("returns non-tilde paths unchanged", function()
      assert.are.equal("/home/user", path.expand "/home/user")
    end)

    it("does not expand ~user (only bare ~)", function()
      assert.are.equal("~user/foo", path.expand "~user/foo")
    end)
  end)
end)
