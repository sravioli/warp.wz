-- ---------------------------------------------------------------------------
-- Unit tests for warp.filesystem  (busted)
-- ---------------------------------------------------------------------------
-- Run:  busted spec/filesystem_spec.lua
-- ---------------------------------------------------------------------------

-- ── Mock infrastructure ──────────────────────────────────────────────────

local fs_mocks = require "spec.mocks.filesystem"
local load_fs = fs_mocks.load_fs
local mock_pane = fs_mocks.mock_pane
local userdata_uri = fs_mocks.userdata_uri

-- ── Tests ────────────────────────────────────────────────────────────────

describe("warp.filesystem", function()
  -- ── platform ─────────────────────────────────────────────────────────

  describe("platform", function()
    it("detects Windows", function()
      local fs = load_fs { triple = "x86_64-pc-windows-msvc" }
      local p = fs.platform()
      assert.are.equal("windows", p.os)
      assert.is_true(p.is_win)
      assert.is_false(p.is_linux)
      assert.is_false(p.is_mac)
    end)

    it("detects Linux", function()
      local fs = load_fs { triple = "x86_64-unknown-linux-gnu" }
      local p = fs.platform()
      assert.are.equal("linux", p.os)
      assert.is_false(p.is_win)
      assert.is_true(p.is_linux)
      assert.is_false(p.is_mac)
    end)

    it("detects macOS", function()
      local fs = load_fs { triple = "aarch64-apple-darwin" }
      local p = fs.platform()
      assert.are.equal("mac", p.os)
      assert.is_false(p.is_win)
      assert.is_false(p.is_linux)
      assert.is_true(p.is_mac)
    end)

    it("returns unknown for unrecognised triple", function()
      local fs = load_fs { triple = "riscv64-unknown-freebsd" }
      local p = fs.platform()
      assert.are.equal("unknown", p.os)
      assert.is_false(p.is_win)
      assert.is_false(p.is_linux)
      assert.is_false(p.is_mac)
    end)
  end)

  -- ── is_win (load-time value) ─────────────────────────────────────────

  describe("is_win", function()
    it("is true on Windows triple", function()
      local fs = load_fs { triple = "x86_64-pc-windows-msvc" }
      assert.is_true(fs.is_win)
    end)

    it("is false on Linux triple", function()
      local fs = load_fs { triple = "x86_64-unknown-linux-gnu" }
      assert.is_false(fs.is_win)
    end)
  end)

  -- ── target_triple ────────────────────────────────────────────────────

  describe("target_triple", function()
    it("reflects the wezterm triple", function()
      local fs = load_fs { triple = "aarch64-apple-darwin" }
      assert.are.equal("aarch64-apple-darwin", fs.target_triple)
    end)
  end)

  -- ── home ─────────────────────────────────────────────────────────────

  describe("home", function()
    it("uses USERPROFILE when set (Windows-style)", function()
      local fs = load_fs {
        triple = "x86_64-pc-windows-msvc",
        env = { USERPROFILE = "C:\\Users\\Test" },
      }
      -- Backslashes are normalised to forward slashes.
      assert.are.equal("C:/Users/Test", fs.home)
    end)

    it("uses HOME when USERPROFILE is absent", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/testuser" },
      }
      assert.are.equal("/home/testuser", fs.home)
    end)

    it("falls back to wezterm home", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        home = "/wt/fallback",
        env = {},
      }
      assert.are.equal("/wt/fallback", fs.home)
    end)

    it("falls back to empty string when nothing is set", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        home = "",
        env = {},
      }
      assert.are.equal("", fs.home)
    end)
  end)

  -- ── basename ─────────────────────────────────────────────────────────

  describe("basename", function()
    local fs
    before_each(function()
      fs = load_fs { triple = "x86_64-unknown-linux-gnu" }
    end)

    it("returns last component of unix path", function()
      assert.are.equal("file.txt", fs.basename "/home/user/file.txt")
    end)

    it("returns last component of windows path", function()
      assert.are.equal("file.txt", fs.basename "C:\\Users\\test\\file.txt")
    end)

    it("strips trailing forward slashes", function()
      assert.are.equal("dir", fs.basename "/home/user/dir/")
    end)

    it("strips trailing backslashes", function()
      assert.are.equal("dir", fs.basename "C:\\Users\\dir\\")
    end)

    it("strips multiple trailing slashes", function()
      assert.are.equal("dir", fs.basename "/path/to/dir///")
    end)

    it("handles root path", function()
      assert.are.equal("", fs.basename "/")
    end)

    it("returns filename when no directory part", function()
      assert.are.equal("file.txt", fs.basename "file.txt")
    end)

    it("handles dotfiles", function()
      assert.are.equal(".bashrc", fs.basename "/home/user/.bashrc")
    end)

    it("handles path with spaces", function()
      assert.are.equal("my file.txt", fs.basename "/path/to/my file.txt")
    end)

    it("handles mixed separators", function()
      assert.are.equal("file", fs.basename "C:\\path/to\\file")
    end)
  end)

  -- ── find_git_dir ─────────────────────────────────────────────────────

  describe("find_git_dir", function()
    it("finds git root when .git/HEAD exists", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
        io_open = function(path, mode)
          if path == "/home/user/projects/repo/.git/HEAD" then
            return {} -- truthy handle
          end
          return nil
        end,
        io_close = function() end,
      }
      local root = fs.find_git_dir "/home/user/projects/repo/src/deep"
      assert.are.equal("~/projects/repo", root)
    end)

    it("returns nil when no git root found", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
        io_open = function()
          return nil
        end,
      }
      local root = fs.find_git_dir "/home/user/no-git-here"
      assert.is_nil(root)
    end)

    it("expands tilde to home", function()
      local opened_paths = {}
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
        io_open = function(path)
          opened_paths[#opened_paths + 1] = path
          if path == "/home/user/repo/.git/HEAD" then
            return {}
          end
          return nil
        end,
        io_close = function() end,
      }
      fs.find_git_dir "~/repo"
      -- The first io.open call should use the expanded path.
      assert.are.equal("/home/user/repo/.git/HEAD", opened_paths[1])
    end)

    it("finds git root at directory itself", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
        io_open = function(path)
          if path == "/home/user/myrepo/.git/HEAD" then
            return {}
          end
          return nil
        end,
        io_close = function() end,
      }
      assert.are.equal("~/myrepo", fs.find_git_dir "~/myrepo")
    end)

    it("stops at root /", function()
      local count = 0
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
        io_open = function()
          count = count + 1
          return nil
        end,
      }
      fs.find_git_dir "/a/b"
      -- Should try /a/b, /a, / then stop — not loop forever.
      assert.is_true(count <= 4)
    end)
  end)

  -- ── get_hostname ─────────────────────────────────────────────────────

  describe("get_hostname", function()
    local fs
    before_each(function()
      fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        hostname = "fallback-host",
      }
    end)

    it("extracts host from userdata URI", function()
      local pane = mock_pane(userdata_uri("/home/user", "mybox"))
      assert.are.equal("Mybox", fs.get_hostname(pane))
    end)

    it("falls back to wezterm.hostname() for userdata with no host", function()
      local pane = mock_pane(userdata_uri("/home/user", nil))
      assert.are.equal("Fallback-host", fs.get_hostname(pane))
    end)

    it("extracts host from string URI", function()
      local pane = mock_pane "file://myhost/home/user"
      assert.are.equal("Myhost", fs.get_hostname(pane))
    end)

    it("falls back to wezterm.hostname() for empty host in string URI", function()
      local pane = mock_pane "file:///home/user"
      assert.are.equal("Fallback-host", fs.get_hostname(pane))
    end)

    it("strips domain suffix", function()
      local pane = mock_pane "file://myhost.example.com/home/user"
      assert.are.equal("Myhost", fs.get_hostname(pane))
    end)

    it("title-cases the first character", function()
      local pane = mock_pane(userdata_uri("/home/user", "lowercase"))
      assert.are.equal("Lowercase", fs.get_hostname(pane))
    end)

    it("returns empty string when pane has no URI", function()
      local pane = mock_pane(nil)
      assert.are.equal("", fs.get_hostname(pane))
    end)
  end)

  -- ── get_cwd ──────────────────────────────────────────────────────────

  describe("get_cwd", function()
    it("extracts file_path from userdata URI on Linux", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
      }
      local pane = mock_pane(userdata_uri "/home/user/projects")
      assert.are.equal("~/projects", fs.get_cwd(pane, false))
    end)

    it("extracts cwd from string URI on Linux", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
      }
      local pane = mock_pane "file://host/home/user/code"
      assert.are.equal("~/code", fs.get_cwd(pane, false))
    end)

    it("decodes percent-encoded characters in string URI", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
      }
      local pane = mock_pane "file://host/home/user/my%20dir"
      assert.are.equal("~/my dir", fs.get_cwd(pane, false))
    end)

    it("extracts cwd from string URI on Windows", function()
      local fs = load_fs {
        triple = "x86_64-pc-windows-msvc",
        env = { USERPROFILE = "C:\\Users\\Test" },
      }
      local pane = mock_pane "file://host/C:/Users/Test/Documents"
      assert.are.equal("~/Documents", fs.get_cwd(pane, false))
    end)

    it("returns empty string when pane has no URI", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
      }
      local pane = mock_pane(nil)
      assert.are.equal("", fs.get_cwd(pane, false))
    end)

    it("returns path as-is when not under home", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
      }
      local pane = mock_pane(userdata_uri "/var/log")
      assert.are.equal("/var/log", fs.get_cwd(pane, false))
    end)

    it("delegates to find_git_dir when search_git_root_instead is true", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
        io_open = function(path)
          if path == "/home/user/repo/.git/HEAD" then
            return {}
          end
          return nil
        end,
        io_close = function() end,
      }
      local pane = mock_pane(userdata_uri "/home/user/repo/src/deep")
      assert.are.equal("~/repo", fs.get_cwd(pane, true))
    end)

    it("keeps cwd when find_git_dir returns nil", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
        io_open = function()
          return nil
        end,
      }
      local pane = mock_pane(userdata_uri "/home/user/no-git")
      assert.are.equal("~/no-git", fs.get_cwd(pane, true))
    end)
  end)

  -- ── get_cwd_hostname (deprecated combo) ──────────────────────────────

  describe("get_cwd_hostname", function()
    it("returns both cwd and hostname", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
        hostname = "mybox",
      }
      local pane = mock_pane(userdata_uri("/home/user/projects", "mybox"))
      local cwd, hostname = fs.get_cwd_hostname(pane, false)
      assert.are.equal("~/projects", cwd)
      assert.are.equal("Mybox", hostname)
    end)
  end)
end)
