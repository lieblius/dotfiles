-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

local config = {
	front_end = "WebGpu",
	webgpu_power_preference = "HighPerformance",
	color_scheme = "tokyonight",
	font = wezterm.font("JetBrains Mono"),
	font_size = 20,
	hide_tab_bar_if_only_one_tab = true,
	use_fancy_tab_bar = false,
	native_macos_fullscreen_mode = false,
	window_close_confirmation = "NeverPrompt",
	window_decorations = "RESIZE",
	window_background_opacity = 0.99,
	quick_select_patterns = {
		"git push --set-upstream origin .*",
	},
	keys = {
		{
			key = "w",
			mods = "CMD",
			action = wezterm.action.CloseCurrentPane({ confirm = false }),
		},
	},
}

-- and finally, return the configuration to wezterm
return config
