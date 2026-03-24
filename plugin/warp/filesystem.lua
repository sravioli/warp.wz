---@module "warp.filesystem"

---@class Wezterm
local wt = require "wezterm"--[[@as Wezterm]]
local wt_home, wt_hostname, wt_triple = wt.home, wt.hostname, wt.target_triple

---@class Memo.Api
local memo = wt.plugin.require "https://github.com/sravioli/memo.wz"
memo.cache.configure { ttl = nil, stats = false, debug = false }
local cache = memo.cache.namespace "warp.fs" ---@class Memo.Cache

local ioclose, ioopen = io.close, io.open
local ogetenv = os.getenv
local tconcat = table.concat

local schar, sfind, sgsub, smatch, ssub =
  string.char, string.find, string.gsub, string.match, string.sub

---@class Warp.FileSystem
local M = {}

---@package
---
---Class logger
M.log = require("utils.logger").new "Fn.FileSystem"

cache.set("target-triple", wt_triple)
---@package
M.target_triple = cache.get "target-triple"

---Get platform information.
---
---Identifies OS based on target triple. Memoized for performance.
---
---@return Fn.FileSystem.Platform platform Platform details (OS name, boolean flags).
M.platform = function()
  return cache.compute("platform", function()
    local is_win = sfind(M.target_triple, "windows", 1, true) ~= nil
    local is_linux = sfind(M.target_triple, "linux", 1, true) ~= nil
    local is_mac = sfind(M.target_triple, "apple", 1, true) ~= nil
    local os_name = is_win and "windows"
      or is_linux and "linux"
      or is_mac and "mac"
      or "unknown"
    return { os = os_name, is_win = is_win, is_linux = is_linux, is_mac = is_mac }
  end)
end

cache.set("is-win", M.platform().is_win)
M.is_win = cache.get "is-win"

cache.set(
  "home",
  (sgsub((ogetenv "USERPROFILE" or ogetenv "HOME" or wt_home or ""), "\\", "/"))
)
---User home directory.
---
---Resolves via `USERPROFILE`, `HOME`, or WezTerm API. Normalizes backslashes to forward
---slashes.
M.home = cache.get "home"

---Extract base name from path.
---
---Equivalent to POSIX `basename(3)`. Returns the final component of the path.
---Uses a simple direct-lookup cache to avoid generic cache machinery overhead.
---
---@param path string File path.
---@return string basename Final component of the path.
local _basename_cache = {}
M.basename = function(path)
  local cached = _basename_cache[path]
  if cached then
    return cached
  end
  local trimmed_path = sgsub(path, "[/\\]*$", "")
  local index = sfind(trimmed_path, "[^/\\]*$")
  local result = index and ssub(trimmed_path, index) or trimmed_path
  _basename_cache[path] = result
  return result
end

---Find git project root.
---
---Traverses up the directory tree looking for a `.git` directory.
---
---@param directory string Starting directory path.
---@return string|nil git_root Root directory of the git repo, or nil if not found.
M.find_git_dir = function(directory)
  return cache.compute("find-git-dir", function()
    directory = sgsub(directory, "~", M.home)
    while directory do
      local handle = ioopen(directory .. "/.git/HEAD", "r")
      if handle then
        ioclose(handle)
        return (directory:gsub(M.home, "~"))
      elseif directory == "/" or directory == "" then
        break
      else
        directory = smatch(directory, "(.+)/[^/]*")
      end
    end

    return nil
  end, directory)
end

---Get the hostname associated with the given pane.
---
---Parses the pane's current working directory URI to extract the host field.
---Falls back to `wezterm.hostname()` when the URI carries no host information.
---Strips any domain suffix and title-cases the result.
---
---@param  pane Pane WezTerm pane object.
---@return string hostname
M.get_hostname = function(pane)
  local hostname = ""
  local cwd_uri = pane:get_current_working_dir()

  if cwd_uri then
    if type(cwd_uri) == "userdata" then
      hostname = cwd_uri.host or wt_hostname() ---@diagnostic disable-line: undefined-field
    else
      local uri = ssub(cwd_uri, 8)
      local slash = sfind(uri, "/")
      if slash then
        hostname = ssub(uri, 1, slash - 1)
      end
    end

    local dot = sfind(hostname, "[.]")
    if dot then
      hostname = ssub(hostname, 1, dot - 1)
    end
    if hostname == "" then
      hostname = wt_hostname()
    end
    hostname = sgsub(hostname, "^%l", string.upper)
  end

  return hostname
end

---Get the current working directory from the given pane.
---
---Parses the pane's current working directory URI.
---Normalises the home directory to `~`.
---Optionally resolves the git root instead of the literal CWD.
---
---@param  pane                    Pane    WezTerm pane object.
---@param  search_git_root_instead boolean If true, returns git root instead of CWD.
---@return string cwd
M.get_cwd = function(pane, search_git_root_instead)
  local cwd = ""
  local cwd_uri = pane:get_current_working_dir()

  if cwd_uri then
    if type(cwd_uri) == "userdata" then
      cwd = cwd_uri.file_path ---@diagnostic disable-line: undefined-field
    else
      local uri = ssub(cwd_uri, 8)
      local slash = sfind(uri, "/")
      if slash then
        cwd = ssub(uri, slash)
        cwd = sgsub(cwd, "%%(%x%x)", function(hex)
          return schar(tonumber(hex, 16))
        end)
      end
    end
  end

  if M.is_win then
    cwd = sgsub(cwd, "/" .. M.home .. "(.-)$", "~%1")
  else
    cwd = sgsub(cwd, M.home .. "(.-)$", "~%1")
  end

  if search_git_root_instead then
    local git_root = M.find_git_dir(cwd)
    cwd = git_root or cwd
  end

  return cwd
end

---@deprecated Use `get_cwd` and `get_hostname` separately.
---Kept for backwards compatibility; delegates to the two focused functions.
---
---@param  pane                    Pane    WezTerm pane object.
---@param  search_git_root_instead boolean If true, returns git root instead of CWD.
---@return string cwd
---@return string hostname
M.get_cwd_hostname = function(pane, search_git_root_instead)
  return M.get_cwd(pane, search_git_root_instead), M.get_hostname(pane)
end

return M
