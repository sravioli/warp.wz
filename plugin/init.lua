---@class Wezterm
local wz = require "wezterm" --[[@as Wezterm]]

---Locate the plugin's `plugin_dir` and add it to package.path
---@return nil
local function bootstrap(name)
  -- selene: allow(incorrect_standard_library_use)
  local sep = package.config:sub(1, 1)

  local plugins = wz.plugin.list()
  for i = 1, #plugins do
    local p = plugins[i]
    if p.url:find(name, 1, true) then
      local path_entry = p.plugin_dir .. sep .. "plugin" .. sep .. "?.lua"
      if not package.path:find(path_entry, 1, true) then
        package.path = package.path .. ";" .. path_entry
      end
      return
    end
  end
end

bootstrap "warp.wz"

return require "warp.api"
