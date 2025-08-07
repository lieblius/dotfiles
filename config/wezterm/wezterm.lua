local wezterm = require("wezterm")
local omarchy_theme = require("omarchy_theme")
local config = wezterm.config_builder()

config.enable_wayland = true
config.font_size = 14.0
config.use_fancy_tab_bar = false
config.window_close_confirmation = "NeverPrompt"

wezterm.add_to_config_reload_watch_list(os.getenv("HOME") .. "/.config/omarchy/current")

local success, theme_colors = pcall(omarchy_theme.load_theme)
if success and theme_colors then
	config.colors = theme_colors
end

return config
