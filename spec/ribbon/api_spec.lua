require "spec.mocks.recording_wezterm"
local ribbon = require "warp.ribbon"
local wezterm = require "wezterm"

describe("ribbon.wz", function()
  before_each(function()
    wezterm._reset()
    ribbon.setup()
  end)

  it("constructs ribbons with colon and dot syntax", function()
    local colon = ribbon:new "Colon"
    local dot = ribbon.new "Dot"

    assert.are.equal("Ribbon > Colon", colon.name)
    assert.are.equal("Ribbon > Dot", dot.name)
  end)

  it("appends format items in wezterm format order", function()
    local r = ribbon.new "Append"

    r:append("Black", "#ffffff", " hello ", "Bold")

    assert.are.same({
      { Background = { AnsiColor = "Black" } },
      { Foreground = { Color = "#ffffff" } },
      { Attribute = { Intensity = "Bold" } },
      { Text = " hello " },
    }, r:items())
  end)

  it("prepends format items before existing content", function()
    local r = ribbon.new "Prepend"

    r:append("Blue", "White", "tail")
    r:prepend("Red", "Black", "head", "Italic")

    -- The prepended segment keeps its own order: colors, attribute, text.
    assert.are.same({
      { Background = { AnsiColor = "Red" } },
      { Foreground = { AnsiColor = "Black" } },
      { Attribute = { Italic = true } },
      { Text = "head" },
      { Background = { AnsiColor = "Blue" } },
      { Foreground = { AnsiColor = "White" } },
      { Text = "tail" },
    }, r:items())
  end)

  it("resolves single and grouped attribute aliases", function()
    local r = ribbon.new "Aliases"

    r:append(nil, nil, "x", { "b", "highlight", "reset" })

    assert.are.same({
      { Background = { Color = "none" } },
      { Foreground = { Color = "none" } },
      { Attribute = { Intensity = "Bold" } },
      { Attribute = { Intensity = "Bold" } },
      { Attribute = { Underline = "Single" } },
      "ResetAttributes",
      { Text = "x" },
    }, r:items())
  end)

  it("adds reset attributes after each segment in atomic mode", function()
    local r = ribbon.new("Atomic", true)

    r:append("Green", "White", "x")

    assert.are.same({
      { Background = { AnsiColor = "Green" } },
      { Foreground = { AnsiColor = "White" } },
      { Text = "x" },
      "ResetAttributes",
    }, r:items())
  end)

  it("appends raw wezterm format items without processing", function()
    ribbon.setup {
      text = {
        transform = function(text)
          return text:upper()
        end,
      },
    }

    local r = ribbon.new("Raw", true)

    r:append("Blue", "White", "x"):append_items {
      { Foreground = { Color = "#57A143" } },
      { Text = "nvim" },
      "ResetAttributes",
    }

    assert.are.same({
      { Background = { AnsiColor = "Blue" } },
      { Foreground = { AnsiColor = "White" } },
      { Text = "X" },
      "ResetAttributes",
      { Foreground = { Color = "#57A143" } },
      { Text = "nvim" },
      "ResetAttributes",
    }, r:items())
  end)

  it("prepends raw wezterm format items in the provided order", function()
    local r = ribbon.new "RawPrepend"

    r:append("Blue", "White", "tail"):prepend_items {
      { Foreground = { Color = "#57A143" } },
      { Text = "nvim" },
      "ResetAttributes",
    }

    assert.are.same({
      { Foreground = { Color = "#57A143" } },
      { Text = "nvim" },
      "ResetAttributes",
      { Background = { AnsiColor = "Blue" } },
      { Foreground = { AnsiColor = "White" } },
      { Text = "tail" },
    }, r:items())
  end)

  it("accepts a single raw format item", function()
    local r = ribbon.new "SingleRaw"

    r:append_items { Text = "x" }
    r:prepend_items "ResetAttributes"

    assert.are.same({
      "ResetAttributes",
      { Text = "x" },
    }, r:items())
  end)

  it("processes text with strip, transform, and max length", function()
    ribbon.setup {
      text = {
        strip = true,
        max_length = 4,
        transform = function(text)
          return text:upper()
        end,
      },
    }

    local r = ribbon.new "Text"
    r:append(nil, nil, "  abcdef  ")

    assert.are.same({
      { Background = { Color = "none" } },
      { Foreground = { Color = "none" } },
      { Text = "ABC…" },
    }, r:items())
  end)

  it("cuts max_length by columns, never inside a multi-byte character", function()
    ribbon.setup { text = { max_length = 4 } }
    local text = ribbon.new("Wide"):append(nil, nil, "日本語テキスト"):items()[3].Text
    assert.is_not_nil(utf8.len(text))
    assert.is_true(wezterm.column_width(text) <= 4)
  end)

  it("warns for unknown attributes by default", function()
    ribbon.setup {
      log = { enabled = true, threshold = "WARN" },
    }

    local r = ribbon.new "Validation"
    r:append(nil, nil, "x", "Missing")

    assert.are.equal("log_warn", wezterm._calls[1].fn)
    assert.matches("Unknown attribute 'Missing'", wezterm._calls[1].args[1], 1, true)
    assert.are.equal("log_error", wezterm._calls[2].fn)
    assert.matches("attribute 'Missing' is not defined!", wezterm._calls[2].args[1], 1, true)
  end)

  it("errors for unknown attributes in strict mode", function()
    ribbon.setup {
      validate_attributes = true,
      strict_mode = true,
    }

    local r = ribbon.new "Strict"

    assert.has_error(function()
      r:append(nil, nil, "x", "Missing")
    end, "Unknown attribute 'Missing'")
  end)

  it("delegates format rendering to wezterm.format", function()
    local r = ribbon.new "Format"
    r:append("Blue", "White", "x")

    assert.are.equal("<formatted>", r:format())
    assert.are.equal("format", wezterm._calls[1].fn)
    assert.are.same(r:items(), wezterm._calls[1].args[1])
  end)

  describe("option validation", function()
    local function logged(fn_name)
      local n = 0
      for _, call in ipairs(wezterm._calls) do
        if call.fn == fn_name then
          n = n + 1
        end
      end
      return n
    end

    it("logs a wrong type and keeps the default and the valid fields", function()
      local cfg = ribbon.setup { strict_mode = "yes", atomic = true }

      assert.is_false(cfg.strict_mode)
      assert.is_true(cfg.atomic)
      assert.are.equal(1, logged "log_error")
    end)

    it("warns about unknown keys in fixed sections", function()
      ribbon.setup { text = { stip = true } }

      assert.are.equal(1, logged "log_warn")
    end)

    it("still extends defaults with custom aliases and accepts a transform", function()
      local transform = function(text)
        return text
      end
      local cfg = ribbon.setup {
        attribute_aliases = { loud = "Bold" },
        text = { transform = transform },
      }

      assert.are.equal(0, logged "log_error" + logged "log_warn")
      assert.are.equal("Bold", cfg.attribute_aliases.loud)
      assert.are.equal("Italic", cfg.attribute_aliases.i)
      assert.are.equal(transform, cfg.text.transform)
    end)

    it("drops a non-function transform", function()
      local cfg = ribbon.setup { text = { transform = "upper" } }

      assert.is_nil(cfg.text.transform)
      assert.are.equal(1, logged "log_error")
    end)

    it("ignores a non-table options value", function()
      assert.has_no.errors(function()
        ribbon.setup "oops"
      end)
    end)

    it("skips validation and never loads warden when validate = false", function()
      local validate = require "warp.validate"
      local real = validate.warden
      finally(function()
        validate.warden = real
      end)
      validate.warden = function()
        error "warden loaded"
      end

      local cfg = ribbon.setup { validate = false, strict_mode = "yes" }

      assert.are.equal("yes", cfg.strict_mode)
      assert.are.equal(0, logged "log_error" + logged "log_warn")
    end)
  end)
end)
