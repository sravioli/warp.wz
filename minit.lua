---Minimal config for bug reports. Run it in isolation from your own config:
---
---    wezterm --config-file minit.lua
---
---Put your reproduction below the marker. Keep it as small as possible and
---paste the edited file into the bug report.
local wezterm = require "wezterm"
local warp = wezterm.plugin.require "https://github.com/sravioli/warp.wz"
local config = wezterm.config_builder()

-- Edit below this line --------------------------------------------------------

config.window_background_opacity = warp.maths.clamp(0.9, 0, 1)
wezterm.log_info(warp.string.trim "  Warp loaded  ")

return config
