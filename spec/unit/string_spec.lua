-- ---------------------------------------------------------------------------
-- Unit tests for warp.string  (busted)
-- ---------------------------------------------------------------------------

-- ── Mocks ────────────────────────────────────────────────────────────────

package.loaded["wezterm"] = require "spec.mocks.wezterm"
package.loaded["warp.maths"] = require "spec.mocks.maths"

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
    it("exposes empty string and single space", function()
      assert.are.equal("", str.empty)
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

    it("strips multiple interleaved escape sequences", function()
      assert.are.equal("blue bold", str.strip_ansi "\27[1m\27[34mblue bold\27[0m")
      assert.are.equal("abc", str.strip_ansi "a\27[1mb\27[2mc\27[0m")
    end)

    it("strips cursor-movement codes", function()
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
      assert.are.equal(0, str.width "\27[31m\27[0m")
    end)

    it("returns 0 for empty string", function()
      assert.are.equal(0, str.width "")
    end)

    it("counts UTF-8 codepoints via fast path", function()
      assert.are.equal(4, str.width "café")
      assert.are.equal(3, str.width "αβγ")
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

    it("accepts table with asymmetric sides", function()
      assert.are.equal("--hi", str.pad("hi", { left = 2, right = nil }, "-"))
      assert.are.equal("hi--", str.pad("hi", { left = nil, right = 2 }, "-"))
      assert.are.equal("..hi...", str.pad("hi", { left = 2, right = 3 }, "."))
    end)

    it("clamps negative padding to 0", function()
      assert.are.equal("hi", str.pad("hi", -5))
    end)

    it("uses custom character", function()
      assert.are.equal("xxhixx", str.pad("hi", 2, "x"))
    end)

    it("converts non-string input to string", function()
      assert.are.equal(" 42 ", str.pad(42))
    end)
  end)

  -- ── padl ─────────────────────────────────────────────────────────────

  describe("padl", function()
    it("adds spaces on the left only", function()
      assert.are.equal(" hi", str.padl "hi")
      assert.are.equal("   hi", str.padl("hi", 3))
    end)

    it("uses custom character", function()
      assert.are.equal("..hi", str.padl("hi", 2, "."))
    end)
  end)

  -- ── padr ─────────────────────────────────────────────────────────────

  describe("padr", function()
    it("adds spaces on the right only", function()
      assert.are.equal("hi ", str.padr "hi")
      assert.are.equal("hi   ", str.padr("hi", 3))
    end)

    it("uses custom character", function()
      assert.are.equal("hi..", str.padr("hi", 2, "."))
    end)
  end)

  -- ── trim ─────────────────────────────────────────────────────────────

  describe("trim", function()
    it("removes leading and trailing whitespace", function()
      assert.are.equal("hi", str.trim "  hi  ")
      assert.are.equal("hi", str.trim "\t\n hi \n\t")
    end)

    it("returns empty for whitespace-only input", function()
      assert.are.equal("", str.trim "   ")
      assert.are.equal("", str.trim "\t\t\t")
    end)

    it("does not alter inner whitespace", function()
      assert.are.equal("a  b", str.trim "  a  b  ")
      assert.are.equal("a\tb", str.trim "  a\tb  ")
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

    it("handles leading and trailing separators", function()
      assert.are.same({ "", "a", "b" }, collect(str.gsplit(",a,b", ",")))
      assert.are.same({ "a", "b", "" }, collect(str.gsplit("a,b,", ",")))
      assert.are.same({ "", "a", "" }, collect(str.gsplit("::a::", "::")))
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

    it("splits by pattern", function()
      assert.are.same({ "a", "b", "c" }, collect(str.gsplit("a1b2c", "%d")))
      assert.are.same({ "a", "b", "c" }, collect(str.gsplit("a1b2c", "[0-9]")))
    end)

    it("splits with plain=true treats sep as literal", function()
      assert.are.same({ "a", "b", "c" }, collect(str.gsplit("a.b.c", ".", { plain = true })))
    end)

    it("splits with empty separator yields individual characters", function()
      assert.are.same({ "a", "b", "c" }, collect(str.gsplit("abc", "")))
    end)

    describe("trimempty option", function()
      it("trims leading and trailing empty segments", function()
        assert.are.same({ "a", "b" }, collect(str.gsplit(",a,b,", ",", { trimempty = true })))
      end)

      it("handles all-empty segments", function()
        assert.are.same({}, collect(str.gsplit(",,,", ",", { trimempty = true })))
        assert.are.same({}, collect(str.gsplit("::::", "::", { trimempty = true })))
      end)

      it("collapses inner empty segments", function()
        assert.are.same({ "a", "b" }, collect(str.gsplit(",a,,b,", ",", { trimempty = true })))
      end)

      it("works with plain + trimempty combined", function()
        assert.are.same(
          { "b" },
          collect(str.gsplit(".b.", ".", { plain = true, trimempty = true }))
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

    it("splits by pattern", function()
      assert.are.same({ "one", "two", "three" }, str.split("one  two  three", "%s+"))
    end)
  end)

  -- ── fits ─────────────────────────────────────────────────────────────

  describe("fits", function()
    it("returns true when string fits within or at budget", function()
      assert.is_true(str.fits("hello", 5))
      assert.is_true(str.fits("hello", 10))
      assert.is_true(str.fits("", 0))
    end)

    it("returns false when string exceeds budget", function()
      assert.is_false(str.fits("hello", 3))
      assert.is_false(str.fits("a", 0))
    end)
  end)

  -- ── truncate_right ───────────────────────────────────────────────────

  describe("truncate_right", function()
    it("returns original when it fits", function()
      assert.are.equal("hello", str.truncate_right("hello", 10))
      assert.are.equal("hello", str.truncate_right("hello", 5))
    end)

    it("truncates and appends ellipsis", function()
      assert.are.equal("abcd…", str.truncate_right("abcdefgh", 5))
      assert.are.equal("a…", str.truncate_right("abcdefgh", 2))
    end)

    it("returns ellipsis when budget is at or below ellipsis width", function()
      assert.are.equal("…", str.truncate_right("abcdefgh", 1))
      assert.are.equal("…", str.truncate_right("abcdefgh", 0))
    end)

    it("handles empty string", function()
      assert.are.equal("", str.truncate_right("", 5))
    end)
  end)

  -- ── truncate_left ────────────────────────────────────────────────────

  describe("truncate_left", function()
    it("returns original when it fits", function()
      assert.are.equal("hello", str.truncate_left("hello", 10))
      assert.are.equal("hello", str.truncate_left("hello", 5))
    end)

    it("truncates and prepends ellipsis", function()
      assert.are.equal("…efgh", str.truncate_left("abcdefgh", 5))
      assert.are.equal("…h", str.truncate_left("abcdefgh", 2))
    end)

    it("returns ellipsis when budget is at or below ellipsis width", function()
      assert.are.equal("…", str.truncate_left("abcdefgh", 1))
      assert.are.equal("…", str.truncate_left("abcdef", 0))
    end)

    it("handles empty string", function()
      assert.are.equal("", str.truncate_left("", 5))
    end)
  end)

  -- ── truncate_middle ──────────────────────────────────────────────────

  describe("truncate_middle", function()
    it("returns original when it fits", function()
      assert.are.equal("hello", str.truncate_middle("hello", 10))
      assert.are.equal("hello", str.truncate_middle("hello", 5))
    end)

    it("truncates keeping both ends", function()
      assert.are.equal("ab…gh", str.truncate_middle("abcdefgh", 5))
    end)

    it("gives left side the extra column on odd remaining", function()
      assert.are.equal("abc…gh", str.truncate_middle("abcdefgh", 6))
    end)

    it("returns ellipsis when budget is at or below ellipsis width", function()
      assert.are.equal("…", str.truncate_middle("abcdefgh", 1))
      assert.are.equal("…", str.truncate_middle("abcdefgh", 0))
    end)

    it("handles small budgets", function()
      assert.are.equal("a…", str.truncate_middle("abcdefgh", 2))
      assert.are.equal("a…h", str.truncate_middle("abcdefgh", 3))
      assert.are.equal("ab…h", str.truncate_middle("abcdefgh", 4))
    end)

    it("handles empty string", function()
      assert.are.equal("", str.truncate_middle("", 5))
    end)
  end)

  -- ── truncate (dispatcher) ────────────────────────────────────────────

  describe("truncate", function()
    it("dispatches to the correct mode", function()
      assert.are.equal(str.truncate_left("abcdefgh", 5), str.truncate("left", "abcdefgh", 5))
      assert.are.equal(str.truncate_middle("abcdefgh", 5), str.truncate("middle", "abcdefgh", 5))
      assert.are.equal(str.truncate_right("abcdefgh", 5), str.truncate("right", "abcdefgh", 5))
    end)

    it("errors on unknown mode", function()
      assert.has_error(function()
        str.truncate("whatever", "abcdefgh", 5)
      end, "invalid truncate mode: whatever")
    end)

    it("errors on nil mode", function()
      assert.has_error(function()
        str.truncate(nil, "abcdefgh", 5)
      end, "invalid truncate mode: nil")
    end)
  end)

  -- ── starts_with ──────────────────────────────────────────────────────

  describe("starts_with", function()
    it("returns true for matching prefix", function()
      assert.is_true(str.starts_with("hello world", "hello"))
    end)

    it("returns false for non-matching prefix", function()
      assert.is_false(str.starts_with("hello world", "world"))
    end)

    it("returns true for empty prefix", function()
      assert.is_true(str.starts_with("hello", ""))
    end)

    it("returns true for exact match", function()
      assert.is_true(str.starts_with("hello", "hello"))
    end)

    it("returns false when prefix is longer", function()
      assert.is_false(str.starts_with("hi", "hello"))
    end)

    it("returns true for empty string with empty prefix", function()
      assert.is_true(str.starts_with("", ""))
    end)
  end)

  -- ── ends_with ────────────────────────────────────────────────────────

  describe("ends_with", function()
    it("returns true for matching suffix", function()
      assert.is_true(str.ends_with("hello world", "world"))
    end)

    it("returns false for non-matching suffix", function()
      assert.is_false(str.ends_with("hello world", "hello"))
    end)

    it("returns true for empty suffix", function()
      assert.is_true(str.ends_with("hello", ""))
    end)

    it("returns true for exact match", function()
      assert.is_true(str.ends_with("hello", "hello"))
    end)

    it("returns false when suffix is longer", function()
      assert.is_false(str.ends_with("hi", "hello"))
    end)

    it("returns true for empty string with empty suffix", function()
      assert.is_true(str.ends_with("", ""))
    end)
  end)

  -- ── ljust ────────────────────────────────────────────────────────────

  describe("ljust", function()
    it("pads short string to target width", function()
      assert.are.equal("hi   ", str.ljust("hi", 5))
    end)

    it("returns string unchanged when already at width", function()
      assert.are.equal("hello", str.ljust("hello", 5))
    end)

    it("returns string unchanged when wider than target", function()
      assert.are.equal("hello world", str.ljust("hello world", 5))
    end)

    it("uses custom padding character", function()
      assert.are.equal("hi...", str.ljust("hi", 5, "."))
    end)

    it("handles zero width", function()
      assert.are.equal("hi", str.ljust("hi", 0))
    end)
  end)

  -- ── rjust ────────────────────────────────────────────────────────────

  describe("rjust", function()
    it("pads short string to target width", function()
      assert.are.equal("   hi", str.rjust("hi", 5))
    end)

    it("returns string unchanged when already at width", function()
      assert.are.equal("hello", str.rjust("hello", 5))
    end)

    it("returns string unchanged when wider than target", function()
      assert.are.equal("hello world", str.rjust("hello world", 5))
    end)

    it("uses custom padding character", function()
      assert.are.equal("...hi", str.rjust("hi", 5, "."))
    end)

    it("handles zero width", function()
      assert.are.equal("hi", str.rjust("hi", 0))
    end)
  end)
end)
