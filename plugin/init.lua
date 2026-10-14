---@class Wezterm
local wz = require "wezterm" --[[@as Wezterm]]
local module_name = ...

---Locate the plugin's `plugin_dir` and add it to `package.path`.
---
---Reuses a Lua-local snapshot of installed WezTerm plugins whose URL
---contains `name`. When found, appends the plugin's
---`plugin_dir/plugin/?.lua` entry to `package.path` so that
---sub-modules can be loaded with `require`. Refreshes on a cache miss.
---
---@param name string Substring to match against plugin URLs.
---@return nil
local function bootstrap(name, refresh)
  -- selene: allow(incorrect_standard_library_use)
  local sep = package.config:sub(1, 1)

  local plugins = not refresh and wz.plugin._bootstrap_plugins
  if not plugins then
    plugins = wz.plugin.list()
    wz.plugin._bootstrap_plugins = plugins
  end
  for i = 1, #plugins do
    local p = plugins[i]
    if
      (module_name and p.component == module_name)
      or (not module_name and p.url:find(name, 1, true))
    then
      local path_entry = p.plugin_dir .. sep .. "plugin" .. sep .. "?.lua"
      if not package.path:find(path_entry, 1, true) then
        package.path = package.path .. ";" .. path_entry
      end
      return
    end
  end
  if not refresh then
    return bootstrap(name, true)
  end
  error("Installed plugin not found: " .. name)
end

bootstrap "warp.wz"

return require "warp.api"
