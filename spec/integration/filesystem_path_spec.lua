-- ---------------------------------------------------------------------------
-- Integration tests: warp.filesystem + warp.path workflow
-- ---------------------------------------------------------------------------
-- Real-world scenario: extract cwd from a pane, then shorten the path
-- for display in a tab title. Tests the data flow between these two
-- modules (filesystem produces paths that path module shortens).

local fs_mocks = require "spec.mocks.filesystem"
local load_fs = fs_mocks.load_fs
local mock_pane = fs_mocks.mock_pane
local userdata_uri = fs_mocks.userdata_uri

-- We need the real path and string modules (path depends on string).
package.loaded["wezterm"] = require "spec.mocks.wezterm"
package.path = "plugin/?.lua;plugin/?/init.lua;" .. package.path

local path = require "warp.path"
local str = require "warp.string"

describe("filesystem + path integration", function()
  -- ── cwd extraction → path shortening ─────────────────────────────────

  describe("cwd → shorten pipeline", function()
    it("shortens a Linux home cwd for tab display", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
      }
      local pane = mock_pane(userdata_uri "/home/user/projects/warp/src/components")
      local cwd = fs.get_cwd(pane, false)
      assert.are.equal("~/projects/warp/src/components", cwd)

      -- Shorten for a narrow tab
      local short = path.shorten(cwd, 1)
      assert.are.equal("~/p/w/s/components", short)
    end)

    it("shorten_to respects a column budget on extracted cwd", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
      }
      local pane = mock_pane(userdata_uri "/home/user/documents/very-long-project-name/src")
      local cwd = fs.get_cwd(pane, false)

      local budget = 25
      local result = path.shorten_to(cwd, budget)
      assert.is_true(str.col_width(result) <= budget)
    end)
  end)

  -- ── git root → path shortening ───────────────────────────────────────

  describe("git root cwd → shorten pipeline", function()
    it("shortens git root path for tab display", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
        io_open = function(p)
          if p == "/home/user/projects/my-app/.git/HEAD" then
            return {}
          end
          return nil
        end,
        io_close = function() end,
      }
      local pane = mock_pane(userdata_uri "/home/user/projects/my-app/src/lib/utils")
      local cwd = fs.get_cwd(pane, true) -- search git root
      assert.are.equal("~/projects/my-app", cwd)

      local short = path.shorten(cwd, 1)
      assert.are.equal("~/p/my-app", short)
    end)
  end)

  -- ── basename + path operations ───────────────────────────────────────

  describe("basename as path component", function()
    it("basename of cwd matches last split component", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
      }
      local raw_path = "/home/user/projects/warp"
      local pane = mock_pane(userdata_uri(raw_path))
      local cwd = fs.get_cwd(pane, false)
      local base = fs.basename(raw_path)

      local parts = str.split(cwd, "/")
      assert.are.equal(base, parts[#parts])
    end)
  end)

  -- ── hostname + cwd formatting ────────────────────────────────────────

  describe("hostname + cwd combined display", function()
    it("formats 'hostname:cwd' and shortens to fit budget", function()
      local fs = load_fs {
        triple = "x86_64-unknown-linux-gnu",
        env = { HOME = "/home/user" },
        hostname = "devbox",
      }
      local pane = mock_pane(userdata_uri("/home/user/projects/frontend", "devbox"))
      local cwd = fs.get_cwd(pane, false)
      local hostname = fs.get_hostname(pane)

      -- Format: "Hostname:~/path"
      local display = hostname .. ":" .. cwd
      assert.are.equal("Devbox:~/projects/frontend", display)

      -- Shorten path portion to fit a tab budget
      local tab_budget = 20
      local host_prefix = hostname .. ":"
      local path_budget = tab_budget - str.col_width(host_prefix)
      local short_cwd = path.shorten_to(cwd, path_budget)

      local final = host_prefix .. short_cwd
      assert.is_true(str.col_width(final) <= tab_budget)
    end)
  end)
end)
