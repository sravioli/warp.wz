---@module "warp.process"

---Executable lookup and safe child-process helpers.
---
---Everything here is argv based: no shell string is ever built or executed.
---Nothing runs at require time; call these from actions or event handlers,
---never while the config is being evaluated.

local fs = require "warp.filesystem"

local concat, insert = table.concat, table.insert
local sfind, sgmatch, sgsub, smatch = string.find, string.gmatch, string.gsub, string.match

---@class Warp.Process
local M = {}

---@type table<string, string|false>
local _which_cache = {}

---Lazily resolve the wezterm module so specs can swap mocks between cases.
---@return table
local function wezterm()
  return require "wezterm"
end

---@param path string
---@return boolean
local function is_file(path)
  local fh = io.open(path, "rb")
  if fh then
    fh:close()
    return true
  end
  return false
end

---@param path string
---@return string
local function slashes(path)
  return (sgsub(path, "\\", "/"))
end

---Well-known install locations that GUI-launched processes often miss
---because they do not inherit the login shell PATH.
---@return string[]
function M.default_dirs()
  local home = fs.home
  if fs.is_win then
    local lad = slashes(os.getenv "LOCALAPPDATA" or (home .. "/AppData/Local"))
    local pd = slashes(os.getenv "ProgramData" or "C:/ProgramData")
    return {
      lad .. "/Microsoft/WinGet/Links",
      home .. "/scoop/shims",
      home .. "/.cargo/bin",
      pd .. "/chocolatey/bin",
      lad .. "/Programs/WezTerm",
      "C:/Program Files/WezTerm",
    }
  end
  return {
    "/opt/homebrew/bin",
    "/usr/local/bin",
    home .. "/.local/bin",
    home .. "/.cargo/bin",
    home .. "/.nix-profile/bin",
    "/etc/profiles/per-user/" .. (os.getenv "USER" or "") .. "/bin",
    "/run/current-system/sw/bin",
    "/nix/var/nix/profiles/default/bin",
    "/home/linuxbrew/.linuxbrew/bin",
    "/snap/bin",
    "/usr/bin",
    "/bin",
  }
end

---@param name string
---@return string[]
local function candidates(name)
  if not fs.is_win or smatch(name, "%.[%w]+$") then
    return { name }
  end
  return { name .. ".exe", name .. ".cmd", name .. ".bat", name }
end

---@return string[]
local function path_dirs()
  local dirs = {}
  local sep = fs.is_win and ";" or ":"
  for dir in sgmatch(os.getenv "PATH" or "", "[^" .. sep .. "]+") do
    insert(dirs, slashes(dir))
  end
  return dirs
end

---@class Warp.Process.WhichOpts
---@field path?  string    Explicit path or name that takes precedence.
---@field dirs?  string[]  Extra directories searched before PATH.
---@field cache? boolean   Memoize the result (default true).

---Locate an executable.
---
---Search order: `opts.path`, `opts.dirs`, `PATH`, then `default_dirs()`.
---On Windows `.exe`, `.cmd` and `.bat` are tried when no extension is given.
---
---@param name string                    Executable name or path.
---@param opts? Warp.Process.WhichOpts
---@return string|nil path  Absolute path with forward slashes, or nil.
function M.which(name, opts)
  opts = opts or {}
  local wanted = opts.path or name
  if type(wanted) ~= "string" or wanted == "" then
    return nil
  end

  local key = wanted .. "\0" .. concat(opts.dirs or {}, "\0")
  if opts.cache ~= false and _which_cache[key] ~= nil then
    return _which_cache[key] or nil
  end

  local found
  if sfind(wanted, "[/\\]") then
    for _, cand in ipairs(candidates(wanted)) do
      if is_file(cand) then
        found = slashes(cand)
        break
      end
    end
  else
    local dirs = {}
    for _, list in ipairs { opts.dirs or {}, path_dirs(), M.default_dirs() } do
      for _, d in ipairs(list) do
        insert(dirs, d)
      end
    end
    for _, dir in ipairs(dirs) do
      for _, cand in ipairs(candidates(wanted)) do
        local full = sgsub(dir, "[/\\]+$", "") .. "/" .. cand
        if is_file(full) then
          found = slashes(full)
          break
        end
      end
      if found then
        break
      end
    end
  end

  if opts.cache ~= false then
    _which_cache[key] = found or false
  end
  return found
end

---Forget memoized `which` results.
function M.clear_cache()
  _which_cache = {}
end

---@class Warp.Process.RunOpts
---@field resolve? boolean                  Resolve argv[1] via `which` (default true).
---@field which?   Warp.Process.WhichOpts   Options forwarded to `which`.

---Run a child process without a shell.
---
---Wraps `wezterm.run_child_process` in `pcall`, so a missing executable never
---raises. Carriage returns are stripped from both streams.
---
---@param argv string[]                 Program and arguments.
---@param opts? Warp.Process.RunOpts
---@return boolean ok      True when the process exited successfully.
---@return string  stdout
---@return string  stderr  Process stderr, or the error message on failure.
function M.run(argv, opts)
  opts = opts or {}
  if type(argv) ~= "table" or type(argv[1]) ~= "string" or argv[1] == "" then
    return false, "", "warp.process.run: argv must be a non-empty list of strings"
  end

  local cmd = {}
  for i, arg in ipairs(argv) do
    cmd[i] = tostring(arg)
  end
  if opts.resolve ~= false then
    cmd[1] = M.which(cmd[1], opts.which) or cmd[1]
  end

  local wt = wezterm()
  if type(wt.run_child_process) ~= "function" then
    return false, "", "wezterm.run_child_process is unavailable"
  end

  local pok, success, stdout, stderr = pcall(wt.run_child_process, cmd)
  if not pok then
    return false, "", tostring(success)
  end
  return success == true, (sgsub(stdout or "", "\r", "")), (sgsub(stderr or "", "\r", ""))
end

---Split command output into non-empty lines (CRLF safe).
---@param text string|nil
---@return string[]
function M.lines(text)
  local out = {}
  for line in sgmatch((text or "") .. "\n", "([^\n]*)\n") do
    line = sgsub(line, "\r$", "")
    if line ~= "" then
      insert(out, line)
    end
  end
  return out
end

---@alias Warp.Process.QuoteStyle "posix"|"powershell"|"cmd"

---Pick a quoting style for a shell executable.
---@param shell string|nil  Shell path or name (e.g. `/bin/zsh`, `pwsh.exe`).
---@return Warp.Process.QuoteStyle
function M.style_for(shell)
  local base = (smatch(shell or "", "[^/\\]+$") or ""):lower()
  base = sgsub(base, "%.exe$", "")
  if base == "pwsh" or base == "powershell" then
    return "powershell"
  end
  if base == "cmd" then
    return "cmd"
  end
  if shell == nil and fs.is_win then
    return "powershell"
  end
  return "posix"
end

---Quote one argument for a shell command line.
---@param arg   string
---@param style? Warp.Process.QuoteStyle  Defaults to `"posix"`.
---@return string
function M.quote(arg, style)
  arg = tostring(arg)
  if arg ~= "" and smatch(arg, "^[%w@%%+=:,./_%-]+$") then
    return arg
  end
  if style == "powershell" then
    return "'" .. sgsub(arg, "'", "''") .. "'"
  end
  if style == "cmd" then
    local s = sgsub(arg, '(\\*)"', function(bs)
      return bs .. bs .. '\\"'
    end)
    s = sgsub(s, "(\\+)$", "%1%1")
    return '"' .. s .. '"'
  end
  return "'" .. sgsub(arg, "'", "'\\''") .. "'"
end

---Join argv into a single command line for `pane:send_text`.
---
---PowerShell needs the call operator when the program itself is quoted.
---@param argv  string[]
---@param style? Warp.Process.QuoteStyle
---@return string
function M.join(argv, style)
  local parts = {}
  for i, arg in ipairs(argv or {}) do
    parts[i] = M.quote(arg, style)
  end
  local line = concat(parts, " ")
  if style == "powershell" and parts[1] and parts[1] ~= argv[1] then
    line = "& " .. line
  end
  return line
end

return M
