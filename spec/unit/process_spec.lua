-- ---------------------------------------------------------------------------
-- Unit tests for warp.process  (busted)
-- ---------------------------------------------------------------------------

package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

local real_getenv = os.getenv

---Load a fresh warp.process with a mock wezterm and a fake environment.
---@param opts { triple?: string, env?: table<string,string>, run?: function }
local function load(opts)
  opts = opts or {}
  local env = opts.env or {}
  os.getenv = function(k)
    return env[k]
  end
  package.loaded["wezterm"] = {
    home = "/home/u",
    target_triple = opts.triple or "x86_64-unknown-linux-gnu",
    hostname = function()
      return "h"
    end,
    run_child_process = opts.run,
  }
  package.loaded["warp.filesystem"] = nil
  package.loaded["warp.process"] = nil
  local p = require "warp.process"
  os.getenv = real_getenv
  return p
end

describe("warp.process", function()
  local tmpdir, exe

  before_each(function()
    exe = os.tmpname()
    os.remove(exe)
    local fh = assert(io.open(exe, "w"))
    fh:write "#!/bin/sh\n"
    fh:close()
    tmpdir = exe:match "^(.*)[/\\][^/\\]+$"
  end)

  after_each(function()
    os.remove(exe)
    os.getenv = real_getenv
  end)

  describe("which", function()
    it("finds an executable in extra dirs", function()
      local p = load()
      local name = exe:match "[^/\\]+$"
      local found = p.which(name, { dirs = { tmpdir } })
      assert.are.equal((exe:gsub("\\", "/")), found)
    end)

    it("finds an executable on PATH", function()
      local host_win = package.config:sub(1, 1) == "\\"
      local triple = host_win and "x86_64-pc-windows-msvc" or "x86_64-unknown-linux-gnu"
      local sep = host_win and ";" or ":"
      local p = load { triple = triple }
      os.getenv = function(k)
        return ({ PATH = "/nope" .. sep .. tmpdir })[k]
      end
      local found = p.which(exe:match "[^/\\]+$", { cache = false })
      os.getenv = real_getenv
      assert.are.equal((exe:gsub("\\", "/")), found)
    end)

    it("accepts an explicit path override", function()
      local p = load()
      assert.are.equal((exe:gsub("\\", "/")), p.which("whatever", { path = exe }))
    end)

    it("returns nil when missing and caches the miss", function()
      local p = load()
      assert.is_nil(p.which "definitely-not-a-real-binary-xyz")
      assert.is_nil(p.which "definitely-not-a-real-binary-xyz")
    end)

    it("returns nil for empty names", function()
      local p = load()
      assert.is_nil(p.which "")
      assert.is_nil(p.which(nil))
    end)

    it("tries windows extensions", function()
      local p = load { triple = "x86_64-pc-windows-msvc" }
      local base = exe .. "-bin"
      local fh = assert(io.open(base .. ".cmd", "w"))
      fh:close()
      local found = p.which(base:match "[^/\\]+$", { dirs = { tmpdir }, cache = false })
      os.remove(base .. ".cmd")
      assert.are.equal((base:gsub("\\", "/")) .. ".cmd", found)
    end)
  end)

  describe("run", function()
    it("rejects bad argv", function()
      local p = load()
      local ok, out, err = p.run "ls -la"
      assert.is_false(ok)
      assert.are.equal("", out)
      assert.is_truthy(err:find "argv")
    end)

    it("passes argv through and strips CR", function()
      local seen
      local p = load {
        run = function(argv)
          seen = argv
          return true, "a\r\nb\r\n", ""
        end,
      }
      local ok, out = p.run({ "tool", "--flag", 3 }, { resolve = false })
      assert.is_true(ok)
      assert.are.equal("a\nb\n", out)
      assert.are.same({ "tool", "--flag", "3" }, seen)
    end)

    it("never raises when the process cannot spawn", function()
      local p = load {
        run = function()
          error "spawn failed"
        end,
      }
      local ok, out, err = p.run({ "x" }, { resolve = false })
      assert.is_false(ok)
      assert.are.equal("", out)
      assert.is_truthy(err:find "spawn failed")
    end)

    it("reports a missing run_child_process", function()
      local p = load()
      local ok = p.run({ "x" }, { resolve = false })
      assert.is_false(ok)
    end)
  end)

  describe("lines", function()
    it("splits and drops blanks", function()
      local p = load()
      assert.are.same({ "a", "b" }, p.lines "a\r\n\nb\n")
      assert.are.same({}, p.lines(nil))
    end)
  end)

  describe("quoting", function()
    local p
    before_each(function()
      p = load()
    end)

    it("leaves safe words alone", function()
      assert.are.equal("nvim", p.quote "nvim")
      assert.are.equal("--max-depth=3", p.quote "--max-depth=3")
    end)

    it("quotes posix args", function()
      assert.are.equal("''", p.quote "")
      assert.are.equal("'a b'", p.quote "a b")
      assert.are.equal([['it'\''s']], p.quote "it's")
    end)

    it("quotes powershell args", function()
      assert.are.equal("'it''s'", p.quote("it's", "powershell"))
      assert.are.equal("& 'C:/a b/x.exe' -v", p.join({ "C:/a b/x.exe", "-v" }, "powershell"))
      assert.are.equal("nvim 'a b'", p.join({ "nvim", "a b" }, "powershell"))
    end)

    it("quotes cmd args", function()
      assert.are.equal([["a b"]], p.quote("a b", "cmd"))
      assert.are.equal([["say \"hi\""]], p.quote('say "hi"', "cmd"))
      assert.are.equal([["dir\\"]], p.quote("dir\\", "cmd"))
    end)

    it("picks styles from shell names", function()
      assert.are.equal("powershell", p.style_for "C:/x/pwsh.exe")
      assert.are.equal("powershell", p.style_for "powershell")
      assert.are.equal("cmd", p.style_for "cmd.exe")
      assert.are.equal("posix", p.style_for "/bin/zsh")
      assert.are.equal("posix", p.style_for(nil))
    end)
  end)

  it("lists default dirs per platform", function()
    local nix = load()
    assert.is_truthy(table.concat(nix.default_dirs(), ";"):find("/opt/homebrew/bin", 1, true))
    local win = load { triple = "x86_64-pc-windows-msvc" }
    os.getenv = function(k)
      return ({ LOCALAPPDATA = "C:\\L" })[k]
    end
    local first = win.default_dirs()[1]
    os.getenv = real_getenv
    assert.are.equal("C:/L/Microsoft/WinGet/Links", first)
  end)
end)
