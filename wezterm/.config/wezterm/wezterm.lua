local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.enable_wayland = true
config.font_size = 14.0
-- config.dpi = 120.0  -- Let Wayland handle scaling automatically

config.color_scheme = 'Tokyo Night'
config.use_fancy_tab_bar = false
config.window_close_confirmation = 'NeverPrompt'

return config