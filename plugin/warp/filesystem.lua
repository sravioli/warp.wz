---@module "warp.filesystem"

---@class Wezterm
local wt = require "wezterm"--[[@as Wezterm]]
local wt_home, wt_hostname, wt_triple = wt.home, wt.hostname, wt.target_triple

local ioclose, ioopen = io.close, io.open
local ogetenv = os.getenv

local schar, sfind, sgsub, smatch, ssub =
  string.char, string.find, string.gsub, string.match, string.sub
local slower, supper = string.lower, string.upper
local tonumber = tonumber

---Filesystem helpers.
---@class Warp.FileSystem
local M = {}

--- Decode a single percent-encoded hex pair.
---@param hex string Two hex digits.
---@return string char The decoded character.
local function pct_decode(hex)
  return schar(tonumber(hex, 16))
end

---Target triple from WezTerm, used for platform detection.
---@package
M.target_triple = wt_triple

---@alias OsType "windows"|"linux"|"mac"|"unknown"

---@class Warp.FileSystem.Platform
---@field public os       OsType  Operating system name.
---@field public is_win   boolean Whether the platform is Windows.
---@field public is_linux boolean Whether the platform is Linux.
---@field public is_mac   boolean Whether the platform is macOS.

---Get platform information.
---
---Identifies OS based on target triple.
---
---@return Warp.FileSystem.Platform platform Platform details (OS name, boolean flags).
M.platform = function()
  local is_win = sfind(M.target_triple, "windows", 1, true) ~= nil
  local is_linux = sfind(M.target_triple, "linux", 1, true) ~= nil
  local is_mac = sfind(M.target_triple, "apple", 1, true) ~= nil
  local os_name = is_win and "windows" or is_linux and "linux" or is_mac and "mac" or "unknown"
  return { os = os_name, is_win = is_win, is_linux = is_linux, is_mac = is_mac }
end

---Whether the current platform is Windows.
---@type boolean
M.is_win = M.platform().is_win

---User home directory.
---
---Resolves via `USERPROFILE`, `HOME`, or WezTerm API.
---Normalizes backslashes to forward slashes.
---
---@type string
M.home = (sgsub((ogetenv "USERPROFILE" or ogetenv "HOME" or wt_home or ""), "\\", "/"))

---Extract base name from path.
---
---Equivalent to POSIX `basename(3)`. Returns the final component of the path.
---
---@param path string File path.
---@return string basename Final component of the path.
M.basename = function(path)
  local trimmed_path = sgsub(path, "[/\\]*$", "")
  local index = sfind(trimmed_path, "[^/\\]*$")
  return index and ssub(trimmed_path, index) or trimmed_path
end

---Expand a leading `~` to the user home directory.
---
---Only expands a leading `~` followed by `/`, `\`, or end-of-string.
---
---@param path string File or directory path.
---@return string expanded Path with `~` replaced by the home directory.
M.expand = function(path)
  if smatch(path, "^~[/\\]") or path == "~" then
    return (M.home or "") .. ssub(path, 2)
  end
  return path
end

---Collapse the user home directory prefix to `~` (inverse of `expand`).
---
---Separator-agnostic, and case-insensitive on Windows. Only whole path
---components match: with home `/home/me`, `/home/media` is left alone.
---Matching paths are returned with forward slashes. Others stay unchanged.
---
---@param path string File or directory path.
---@return string path Path with the home prefix replaced by `~`.
M.tilde = function(path)
  local home = sgsub(M.home or "", "[/\\]+$", "")
  if home == "" then
    return path
  end
  local p = sgsub(path, "\\", "/")
  local hk, pk = sgsub(home, "\\", "/"), p
  if M.is_win then
    hk, pk = slower(hk), slower(pk)
  end
  if pk == hk then
    return "~"
  end
  if ssub(pk, 1, #hk + 1) == hk .. "/" then
    return "~" .. ssub(p, #hk + 1)
  end
  return path
end

---Whether `dir` holds a git repository: a `.git` directory, or the `.git`
---file that worktrees and submodules use (`gitdir: ...`).
---@param dir string
---@return boolean
local function has_git(dir)
  local handle = ioopen(dir .. "/.git/HEAD", "r")
  if handle then
    ioclose(handle)
    return true
  end
  handle = ioopen(dir .. "/.git", "r")
  if not handle then
    return false
  end
  local ok, line = pcall(handle.read, handle, "*l")
  ioclose(handle)
  return ok and type(line) == "string" and smatch(line, "^gitdir:") ~= nil
end

---Find git project root.
---
---Traverses up the directory tree looking for a `.git` directory, or the
---`.git` file of a worktree or submodule.
---
---@param directory string Starting directory path.
---@return string|nil git_root Root directory of the git repo, or nil if not found.
M.find_git_dir = function(directory)
  local dir = M.expand(directory)
  while dir do
    if has_git(dir) then
      return M.tilde(dir)
    elseif dir == "/" or dir == "" then
      break
    else
      dir = smatch(dir, "(.+)/[^/]*")
    end
  end

  return nil
end

---Get the hostname associated with the given pane.
---
---Parses the pane's current working directory URI to extract the host field.
---Falls back to `wezterm.hostname()` when the URI carries no host information.
---Strips any domain suffix and title-cases the result.
---
---@param pane Pane WezTerm pane object.
---@return string hostname Short hostname of the pane.
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
    hostname = sgsub(hostname, "^%l", supper)
  end

  return hostname
end

---Get the current working directory from the given pane.
---
---Parses the pane's current working directory URI.
---Normalises the home directory to `~`.
---Optionally resolves the git root instead of the literal CWD.
---
---@param pane                    Pane    WezTerm pane object.
---@param search_git_root_instead boolean If true, returns git root instead of CWD.
---@return string cwd Current working directory or git root.
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
        cwd = sgsub(cwd, "%%(%x%x)", pct_decode)
      end
    end
  end

  if M.is_win then
    -- file_path on Windows yields "/C:/…/"; strip the leading slash before a
    -- drive letter and any trailing slash so downstream code sees clean paths.
    cwd = sgsub(cwd, "^/(%a:)", "%1")
    cwd = sgsub(cwd, "/+$", "")
  end
  cwd = M.tilde(cwd)

  if search_git_root_instead then
    local git_root = M.find_git_dir(cwd)
    cwd = git_root or cwd
  end

  return cwd
end

---Check whether a path is a directory.
---
---Probes with `io.open(path .. "/.")` first (works on POSIX), then falls
---back to `wezterm.read_dir`, which is reliable on Windows where the
---`io.open` trick always fails. Never raises.
---
---@param path string Path to check.
---@return boolean
M.is_dir = function(path)
  local handle = ioopen(path .. "/.", "r")
  if handle then
    ioclose(handle)
    return true
  end
  local read_dir = wt.read_dir
  if type(read_dir) == "function" then
    local ok, entries = pcall(read_dir, path)
    return ok and type(entries) == "table"
  end
  return false
end

---Characters `cmd.exe` would interpret even inside an argv element.
local CMD_META = '[%%&|<>^"!%c]'

---Create a directory and any missing parents (like `mkdir -p`).
---
---Runs `mkdir` through `warp.process.run` (argv, no shell string on POSIX).
---On Windows `mkdir` is a `cmd.exe` builtin, so paths containing cmd
---metacharacters (`% & | < > ^ " !` or control characters) are refused
---rather than risk being interpreted. Do not call while the config is being
---evaluated: it may spawn a process.
---
---@param path string Directory to create.
---@return boolean ok      True when the directory exists afterwards.
---@return string|nil err  Reason on failure.
M.mkdir = function(path)
  if type(path) ~= "string" or path == "" then
    return false, "mkdir: path must be a non-empty string"
  end
  if M.is_dir(path) then
    return true
  end
  local argv
  if M.is_win then
    if sfind(path, CMD_META) then
      return false, "mkdir: refusing path with cmd.exe metacharacters: " .. path
    end
    argv = { "cmd.exe", "/d", "/c", "mkdir", (sgsub(path, "/", "\\")) }
  else
    argv = { "mkdir", "-p", "--", path }
  end
  local ok, _, stderr = require("warp.process").run(argv)
  if ok or M.is_dir(path) then
    return true
  end
  return false, (stderr ~= "" and stderr) or ("mkdir failed: " .. path)
end

---Read the entire contents of a small file.
---
---Returns `nil` when the file cannot be opened.
---
---@param path string File path to read.
---@return string|nil contents File contents, or `nil` on failure.
M.read_file = function(path)
  local handle = ioopen(path, "r")
  if not handle then
    return nil
  end
  local contents = handle:read "*a"
  ioclose(handle)
  return contents
end

---@deprecated Use `get_cwd` and `get_hostname` separately.
---Kept for backwards compatibility. Delegates to the two focused functions.
---
---@param pane                    Pane    WezTerm pane object.
---@param search_git_root_instead boolean If true, returns git root instead of CWD.
---@return string cwd      Current working directory or git root.
---@return string hostname Short hostname of the pane.
M.get_cwd_hostname = function(pane, search_git_root_instead)
  return M.get_cwd(pane, search_git_root_instead), M.get_hostname(pane)
end

return M
