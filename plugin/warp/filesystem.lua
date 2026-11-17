---@module "warp.filesystem"

---@class Wezterm
local wt = require "wezterm"--[[@as Wezterm]]
local wt_home, wt_hostname, wt_triple = wt.home_dir, wt.hostname, wt.target_triple

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
  if trimmed_path == "" then
    return ssub(path, 1, 1) -- POSIX: basename("/") is "/"
  end
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

local tmp_seq = 0

---Unique sibling of `path`, so concurrent writers (other WezTerm processes,
---overlapping saves) never share a temporary file.
---@param path   string
---@param suffix string
---@return string
local function unique_sibling(path, suffix)
  tmp_seq = tmp_seq + 1
  return ("%s.%x%x%x%s"):format(path, os.time(), math.random(0, 0x7fffffff), tmp_seq, suffix)
end

---Write `contents` to a fresh file. The io/os functions are looked up per
---call so callers' specs can stub them.
---@param path     string
---@param contents string
---@return boolean ok
---@return string|nil err
local function write_new(path, contents)
  local handle, err = io.open(path, "wb")
  if not handle then
    return false, err
  end
  local wrote, write_err = handle:write(contents)
  local closed, close_err = handle:close()
  if not wrote or not closed then
    return false, write_err or close_err
  end
  return true
end

---Write a file atomically: readers see the old contents or the new ones,
---never a half-written file.
---
---Writes to a unique temporary sibling, then renames it over `path`. POSIX
---rename replaces the target in one step. On Windows `os.rename` cannot
---replace an existing file, so the old file is moved aside first and put
---back when the final rename fails. The parent directory must exist (see
---`mkdir`). Never raises.
---
---@param path     string File to write.
---@param contents string New contents, written byte for byte.
---@return boolean ok      True when `path` holds `contents`.
---@return string|nil err  Reason on failure. `path` is left as it was.
M.write_file = function(path, contents)
  if type(path) ~= "string" or path == "" then
    return false, "write_file: path must be a non-empty string"
  end
  if type(contents) ~= "string" then
    return false, "write_file: contents must be a string"
  end
  local tmp = unique_sibling(path, ".tmp")
  local ok, err = write_new(tmp, contents)
  if not ok then
    os.remove(tmp)
    return false, ("write_file: unable to write %s: %s"):format(tmp, tostring(err))
  end
  if os.rename(tmp, path) then
    return true
  end

  local target = io.open(path, "rb")
  if not target then
    local renamed, rename_err = os.rename(tmp, path)
    if not renamed then
      os.remove(tmp)
      return false, ("write_file: unable to replace %s: %s"):format(path, tostring(rename_err))
    end
    return true
  end
  target:close()
  local aside = unique_sibling(path, ".old")
  local moved, move_err = os.rename(path, aside)
  if not moved then
    os.remove(tmp)
    return false, ("write_file: unable to move %s aside: %s"):format(path, tostring(move_err))
  end
  local replaced, replace_err = os.rename(tmp, path)
  if not replaced then
    os.remove(tmp)
    local restored, restore_err = os.rename(aside, path)
    if not restored then
      return false,
        ("write_file: unable to replace %s (%s); rollback failed, recover %s: %s"):format(
          path,
          tostring(replace_err),
          aside,
          tostring(restore_err)
        )
    end
    return false, ("write_file: unable to replace %s: %s"):format(path, tostring(replace_err))
  end
  os.remove(aside)
  return true
end

---Non-empty value of an environment variable.
---@param name string
---@return string|nil
local function env(name)
  local value = os.getenv(name) -- looked up per call, so callers' specs can stub it
  return value ~= "" and value or nil
end

---Per-user application directory for WezTerm plugins, with forward slashes.
---@param xdg_var  string XDG variable consulted outside Windows.
---@param fallback string Path under the home directory when it is unset.
---@return string|nil
local function app_dir(xdg_var, fallback)
  local home = M.home ~= "" and M.home or nil
  local base
  if M.is_win then
    base = env "LOCALAPPDATA" or env "APPDATA" or (home and home .. "/AppData/Local")
  else
    base = env(xdg_var) or (home and home .. fallback)
  end
  if not base then
    return nil
  end
  return (sgsub(sgsub(base, "\\", "/"), "/+$", "")) .. "/wezterm"
end

---Directory for state a plugin keeps between runs (sessions, history,
---last choices). Create it with `mkdir` before writing.
---
---`%LOCALAPPDATA%/wezterm` (or `%APPDATA%`) on Windows,
---`$XDG_STATE_HOME/wezterm` or `~/.local/state/wezterm` elsewhere, macOS
---included, like WezTerm's own directories. Never `wezterm.config_dir`:
---WezTerm watches it, so writing there reloads the config.
---
---@return string|nil dir  Forward slashes, or nil when no home is known.
M.state_dir = function()
  return app_dir("XDG_STATE_HOME", "/.local/state")
end

---Directory for data a plugin produces (logs, records). Create it with
---`mkdir` before writing.
---
---Same as `state_dir`, but uses `$XDG_DATA_HOME` or `~/.local/share` outside
---Windows.
---
---@return string|nil dir  Forward slashes, or nil when no home is known.
M.data_dir = function()
  return app_dir("XDG_DATA_HOME", "/.local/share")
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
