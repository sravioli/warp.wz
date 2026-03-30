-- ---------------------------------------------------------------------------
-- Unit tests for warp.string  (busted)
-- ---------------------------------------------------------------------------
-- Run:  busted spec/string_spec.lua
-- ---------------------------------------------------------------------------

-- ── Mocks ────────────────────────────────────────────────────────────────

-- Provide mocks before the SUT is loaded.
package.loaded["wezterm"] = require "spec.mocks.wezterm"
package.loaded["warp.maths"] = require "spec.mocks.maths"

-- Adjust package.path so `require "warp.string"` resolves.
package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

local str = require "warp.string"

-- ── Helpers ──────────────────────────────────────────────────────────────

--- Collect all values from a gsplit iterator into a list.
local function collect(iter)
  local t = {}
  for v in iter do
    t[#t + 1] = v
  end
  return t
end

-- ── Tests ────────────────────────────────────────────────────────────────

describe("warp.string", function()
  -- ── Constants ────────────────────────────────────────────────────────

  describe("constants", function()
    it("exposes empty string", function()
      assert.are.equal("", str.empty)
    end)

    it("exposes single space", function()
      assert.are.equal(" ", str.space)
    end)
  end)

  -- ── strip_ansi ───────────────────────────────────────────────────────

  describe("strip_ansi", function()
    it("returns plain text unchanged", function()
      assert.are.equal("hello", str.strip_ansi "hello")
    end)

    it("strips SGR colour codes", function()
      assert.are.equal("hello", str.strip_ansi "\27[31mhello\27[0m")
    end)

    it("strips multiple escape sequences", function()
      local raw = "\27[1m\27[34mblue bold\27[0m"
      assert.are.equal("blue bold", str.strip_ansi(raw))
    end)

    it("strips cursor-movement codes", function()
      -- CSI A = cursor up
      assert.are.equal("abc", str.strip_ansi "\27[2Aabc")
    end)

    it("handles empty string", function()
      assert.are.equal("", str.strip_ansi "")
    end)
  end)

  -- ── width ────────────────────────────────────────────────────────────

  describe("width", function()
    it("returns length for plain ASCII", function()
      assert.are.equal(5, str.width "hello")
    end)

    it("ignores ANSI codes in width computation", function()
      assert.are.equal(5, str.width "\27[31mhello\27[0m")
    end)

    it("returns 0 for empty string", function()
      assert.are.equal(0, str.width "")
    end)

    it("counts UTF-8 codepoints", function()
      -- "café" = 4 codepoints (mock treats each as 1 column)
      assert.are.equal(4, str.width "café")
    end)
  end)

  -- ── pad ──────────────────────────────────────────────────────────────

  describe("pad", function()
    it("adds 1 space each side by default", function()
      assert.are.equal(" hi ", str.pad "hi")
    end)

    it("accepts a numeric padding for both sides", function()
      assert.are.equal("   hi   ", str.pad("hi", 3))
    end)

    it("accepts zero padding", function()
      assert.are.equal("hi", str.pad("hi", 0))
    end)

    it("accepts table with left only", function()
      assert.are.equal("--hi", str.pad("hi", { left = 2, right = nil }, "-"))
    end)

    it("accepts table with right only", function()
      assert.are.equal("hi--", str.pad("hi", { left = nil, right = 2 }, "-"))
    end)

    it("accepts table with both sides", function()
      assert.are.equal("..hi...", str.pad("hi", { left = 2, right = 3 }, "."))
    end)

    it("converts non-string input to string", function()
      assert.are.equal(" 42 ", str.pad(42))
    end)

    it("clamps negative padding to 0", function()
      assert.are.equal("hi", str.pad("hi", -5))
    end)

    it("handles nil padding as default (1, 1)", function()
      assert.are.equal(" hi ", str.pad("hi", nil))
    end)

    it("uses custom character", function()
      assert.are.equal("xxhixx", str.pad("hi", 2, "x"))
    end)
  end)

  -- ── padl ─────────────────────────────────────────────────────────────

  describe("padl", function()
    it("adds 1 space on the left by default", function()
      assert.are.equal(" hi", str.padl "hi")
    end)

    it("adds n spaces on the left", function()
      assert.are.equal("   hi", str.padl("hi", 3))
    end)

    it("uses custom character", function()
      assert.are.equal("..hi", str.padl("hi", 2, "."))
    end)

    it("does not add right padding", function()
      assert.are.equal("  hi", str.padl("hi", 2))
    end)
  end)

  -- ── padr ─────────────────────────────────────────────────────────────

  describe("padr", function()
    it("adds 1 space on the right by default", function()
      assert.are.equal("hi ", str.padr "hi")
    end)

    it("adds n spaces on the right", function()
      assert.are.equal("hi   ", str.padr("hi", 3))
    end)

    it("uses custom character", function()
      assert.are.equal("hi..", str.padr("hi", 2, "."))
    end)

    it("does not add left padding", function()
      assert.are.equal("hi  ", str.padr("hi", 2))
    end)
  end)

  -- ── trim ─────────────────────────────────────────────────────────────

  describe("trim", function()
    it("removes leading spaces", function()
      assert.are.equal("hi", str.trim "   hi")
    end)

    it("removes trailing spaces", function()
      assert.are.equal("hi", str.trim "hi   ")
    end)

    it("removes both leading and trailing spaces", function()
      assert.are.equal("hi", str.trim "  hi  ")
    end)

    it("removes tabs and newlines", function()
      assert.are.equal("hi", str.trim "\t\n hi \n\t")
    end)

    it("returns empty for whitespace-only input", function()
      assert.are.equal("", str.trim "   ")
    end)

    it("does not alter inner whitespace", function()
      assert.are.equal("a  b", str.trim "  a  b  ")
    end)

    it("handles empty string", function()
      assert.are.equal("", str.trim "")
    end)
  end)

  -- ── gsplit ───────────────────────────────────────────────────────────

  describe("gsplit", function()
    it("splits by single character", function()
      assert.are.same({ "a", "b", "c" }, collect(str.gsplit("a,b,c", ",")))
    end)

    it("splits by multi-char separator", function()
      assert.are.same({ "a", "b", "c" }, collect(str.gsplit("a::b::c", "::")))
    end)

    it("handles leading separator", function()
      assert.are.same({ "", "a", "b" }, collect(str.gsplit(",a,b", ",")))
    end)

    it("handles trailing separator", function()
      assert.are.same({ "a", "b", "" }, collect(str.gsplit("a,b,", ",")))
    end)

    it("handles consecutive separators", function()
      assert.are.same({ "a", "", "b" }, collect(str.gsplit("a,,b", ",")))
    end)

    it("returns whole string when separator not found", function()
      assert.are.same({ "abc" }, collect(str.gsplit("abc", ",")))
    end)

    it("handles empty string input", function()
      assert.are.same({ "" }, collect(str.gsplit("", ",")))
    end)

    it("splits by pattern character", function()
      assert.are.same({ "a", "b", "c" }, collect(str.gsplit("a1b2c", "%d")))
    end)

    it("splits with plain=true treats sep as literal", function()
      -- "." is a pattern metachar; plain mode should treat it literally
      assert.are.same(
        { "a", "b", "c" },
        collect(str.gsplit("a.b.c", ".", { plain = true }))
      )
    end)

    it("splits with empty separator yields individual characters", function()
      assert.are.same({ "a", "b", "c" }, collect(str.gsplit("abc", "")))
    end)

    describe("trimempty option", function()
      it("trims leading empty segments", function()
        assert.are.same(
          { "a", "b" },
          collect(str.gsplit(",a,b", ",", { trimempty = true }))
        )
      end)

      it("trims trailing empty segments", function()
        assert.are.same(
          { "a", "b" },
          collect(str.gsplit("a,b,", ",", { trimempty = true }))
        )
      end)

      it("trims both leading and trailing empty segments", function()
        assert.are.same(
          { "a", "b" },
          collect(str.gsplit(",a,b,", ",", { trimempty = true }))
        )
      end)

      it("handles all-empty segments", function()
        assert.are.same({}, collect(str.gsplit(",,,", ",", { trimempty = true })))
      end)

      it("collapses inner empty segments", function()
        assert.are.same(
          { "a", "b" },
          collect(str.gsplit(",a,,b,", ",", { trimempty = true }))
        )
      end)
    end)
  end)

  -- ── split ────────────────────────────────────────────────────────────

  describe("split", function()
    it("returns a table of parts", function()
      assert.are.same({ "a", "b", "c" }, str.split("a,b,c", ","))
    end)

    it("respects opts", function()
      assert.are.same({ "a", "b" }, str.split(",a,b,", ",", { trimempty = true }))
    end)

    it("handles single element", function()
      assert.are.same({ "hello" }, str.split("hello", ","))
    end)

    it("handles empty string", function()
      assert.are.same({ "" }, str.split("", ","))
    end)

    it("splits by pattern", function()
      assert.are.same({ "one", "two", "three" }, str.split("one  two  three", "%s+"))
    end)
  end)

  -- ── fits ─────────────────────────────────────────────────────────────

  describe("fits", function()
    it("returns true when string fits exactly", function()
      assert.is_true(str.fits("hello", 5))
    end)

    it("returns true when budget exceeds width", function()
      assert.is_true(str.fits("hello", 10))
    end)

    it("returns false when string exceeds budget", function()
      assert.is_false(str.fits("hello", 3))
    end)

    it("empty string fits in 0 budget", function()
      assert.is_true(str.fits("", 0))
    end)
  end)

  -- ── truncate_right ───────────────────────────────────────────────────

  describe("truncate_right", function()
    it("returns original when it fits", function()
      assert.are.equal("hello", str.truncate_right("hello", 10))
    end)

    it("returns original at exact budget", function()
      assert.are.equal("hello", str.truncate_right("hello", 5))
    end)

    it("truncates and appends ellipsis", function()
      local result = str.truncate_right("abcdefgh", 5)
      -- 5 budget - 1 ellipsis = 4 chars from left + "…"
      assert.are.equal("abcd…", result)
    end)

    it("returns just ellipsis when budget equals ellipsis width", function()
      assert.are.equal("…", str.truncate_right("abcdefgh", 1))
    end)

    it("returns ellipsis when budget is 0", function()
      -- budget <= ELLIPSIS_W (1), so returns bare ellipsis
      assert.are.equal("…", str.truncate_right("abcdefgh", 0))
    end)

    it("handles budget of 2 on long string", function()
      local result = str.truncate_right("abcdefgh", 2)
      assert.are.equal("a…", result)
    end)
  end)

  -- ── truncate_left ────────────────────────────────────────────────────

  describe("truncate_left", function()
    it("returns original when it fits", function()
      assert.are.equal("hello", str.truncate_left("hello", 10))
    end)

    it("returns original at exact budget", function()
      assert.are.equal("hello", str.truncate_left("hello", 5))
    end)

    it("truncates and prepends ellipsis", function()
      local result = str.truncate_left("abcdefgh", 5)
      -- "…" + 4 chars from right = "…efgh"
      assert.are.equal("…efgh", result)
    end)

    it("returns just ellipsis when budget equals ellipsis width", function()
      assert.are.equal("…", str.truncate_left("abcdefgh", 1))
    end)

    it("handles budget of 2 on long string", function()
      local result = str.truncate_left("abcdefgh", 2)
      assert.are.equal("…h", result)
    end)
  end)

  -- ── truncate_middle ──────────────────────────────────────────────────

  describe("truncate_middle", function()
    it("returns original when it fits", function()
      assert.are.equal("hello", str.truncate_middle("hello", 10))
    end)

    it("returns original at exact budget", function()
      assert.are.equal("hello", str.truncate_middle("hello", 5))
    end)

    it("truncates keeping both ends", function()
      local result = str.truncate_middle("abcdefgh", 5)
      -- remaining = 4, left = ceil(2) = 2, right = floor(2) = 2
      assert.are.equal("ab…gh", result)
    end)

    it("gives left side the extra column on odd remaining", function()
      local result = str.truncate_middle("abcdefgh", 6)
      -- remaining = 5, left = ceil(2.5) = 3, right = floor(2.5) = 2
      assert.are.equal("abc…gh", result)
    end)

    it("returns just ellipsis when budget equals ellipsis width", function()
      assert.are.equal("…", str.truncate_middle("abcdefgh", 1))
    end)

    it("handles budget of 2", function()
      local result = str.truncate_middle("abcdefgh", 2)
      -- remaining = 1, left = 1, right = 0
      assert.are.equal("a…", result)
    end)

    it("handles budget of 3", function()
      local result = str.truncate_middle("abcdefgh", 3)
      -- remaining = 2, left = 1, right = 1
      assert.are.equal("a…h", result)
    end)
  end)

  -- ── truncate (dispatcher) ────────────────────────────────────────────

  describe("truncate", function()
    it("dispatches mode='left'", function()
      assert.are.equal(
        str.truncate_left("abcdefgh", 5),
        str.truncate("abcdefgh", 5, "left")
      )
    end)

    it("dispatches mode='middle'", function()
      assert.are.equal(
        str.truncate_middle("abcdefgh", 5),
        str.truncate("abcdefgh", 5, "middle")
      )
    end)

    it("dispatches mode='right'", function()
      assert.are.equal(
        str.truncate_right("abcdefgh", 5),
        str.truncate("abcdefgh", 5, "right")
      )
    end)

    it("defaults to right truncation for unknown mode", function()
      assert.are.equal(
        str.truncate_right("abcdefgh", 5),
        str.truncate("abcdefgh", 5, "whatever")
      )
    end)

    it("defaults to right truncation for nil mode", function()
      assert.are.equal(
        str.truncate_right("abcdefgh", 5),
        str.truncate("abcdefgh", 5, nil)
      )
    end)
  end)
end)
