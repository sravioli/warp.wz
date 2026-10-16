-- ---------------------------------------------------------------------------
-- Unit tests for warp.filesystem.mkdir / is_dir fallback  (busted)
-- ---------------------------------------------------------------------------

package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

local real_getenv = os.getenv

---Load fresh warp.filesystem/process against a fake wezterm.
---`dirs` is the set of directories `read_dir` reports as existing; a
---successful `mkdir` run adds its target to it.
---@param opts { triple?: string, dirs?: table<string, boolean>, ok?: boolean, read_dir?: boolean }
---@return table fs, table calls
local function load(opts)
  opts = opts or {}
  local dirs = opts.dirs or {}
  local calls = {}
  os.getenv = function()
    return nil
  end
  package.loaded["wezterm"] = {
    home = "/home/u",
    target_triple = opts.triple or "x86_64-unknown-linux-gnu",
    hostname = function()
      return "h"
    end,
    read_dir = opts.read_dir ~= false and function(p)
      if dirs[p] then
        return {}
      end
      error("no such dir: " .. p)
    end or nil,
    run_child_process = function(argv)
      calls[#calls + 1] = argv
      if opts.ok ~= false then
        dirs[argv[#argv]] = true
        return true, "", ""
      end
      return false, "", "denied\r\n"
    end,
  }
  package.loaded["warp.filesystem"] = nil
  package.loaded["warp.process"] = nil
  local fs = require "warp.filesystem"
  os.getenv = real_getenv
  return fs, calls
end

describe("warp.filesystem", function()
  after_each(function()
    os.getenv = real_getenv
    package.loaded["wezterm"] = nil
    package.loaded["warp.filesystem"] = nil
    package.loaded["warp.process"] = nil
  end)

  describe("is_dir", function()
    it("falls back to wezterm.read_dir", function()
      local fs = load { dirs = { ["/virtual/dir"] = true } }
      assert.is_true(fs.is_dir "/virtual/dir")
      assert.is_false(fs.is_dir "/virtual/missing")
    end)

    it("returns false without read_dir", function()
      local fs = load { read_dir = false }
      assert.is_false(fs.is_dir "/virtual/missing")
    end)
  end)

  describe("mkdir", function()
    it("does nothing when the directory exists", function()
      local fs, calls = load { dirs = { ["/virtual/dir"] = true } }
      assert.is_true(fs.mkdir "/virtual/dir")
      assert.are.equal(0, #calls)
    end)

    it("runs mkdir -p -- on POSIX", function()
      local fs, calls = load()
      assert.is_true(fs.mkdir "/virtual/a b/c")
      assert.are.same({ "mkdir", "-p", "--", "/virtual/a b/c" }, {
        calls[1][1]:match "[^/\\]+$",
        calls[1][2],
        calls[1][3],
        calls[1][4],
      })
    end)

    it("uses cmd.exe with backslashes on Windows", function()
      local fs, calls = load { triple = "x86_64-pc-windows-msvc" }
      assert.is_true(fs.mkdir "Z:/virtual/a")
      local argv = calls[1]
      assert.are.equal("mkdir", argv[4])
      assert.are.equal("Z:\\virtual\\a", argv[5])
    end)

    it("refuses cmd.exe metacharacters on Windows", function()
      local fs, calls = load { triple = "x86_64-pc-windows-msvc" }
      for _, bad in ipairs { "Z:/a&calc", "Z:/%PATH%", "Z:/a|b", "Z:/a^b", 'Z:/a"b', "Z:/a!b" } do
        local ok, err = fs.mkdir(bad)
        assert.is_false(ok)
        assert.is_truthy(err:find "metacharacters", 1, true)
      end
      assert.are.equal(0, #calls)
    end)

    it("reports stderr on failure", function()
      local fs = load { ok = false }
      local ok, err = fs.mkdir "/virtual/nope"
      assert.is_false(ok)
      assert.are.equal("denied\n", err)
    end)

    it("rejects empty paths", function()
      local fs = load()
      assert.is_false((fs.mkdir ""))
    end)
  end)
end)
