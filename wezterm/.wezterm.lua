-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action -- Alias for wezterm.action

-- Initialize the configuration builder
local config = wezterm.config_builder()

-- Core Wezterm UI and behavior settings
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.color_scheme = "tokyonight"
config.font = wezterm.font("JetBrains Mono")
config.font_size = 20
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.native_macos_fullscreen_mode = false
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.99
config.quick_select_patterns = {
	"git push --set-upstream origin .*",
}
config.audible_bell = "SystemBeep"
config.notification_handling = "SuppressFromFocusedPane"

-- Define the leader key for multiplexing commands (Ctrl-a)
config.leader = {
	key = "a",
	mods = "CTRL",
	timeout_milliseconds = 1000,
}

-- Visual dimming for inactive panes
config.inactive_pane_hsb = {
	saturation = 0.24,
	brightness = 0.5,
}

-- Set default workspace name
config.default_workspace = "main"

-- Configure tab bar position and status update interval
config.tab_bar_at_bottom = true
config.status_update_interval = 1000

-- Define custom colors for status bar indicators
local custom_status_colors = {
	red = "#D06F79",
	cyan = "#88C0D0",
	magenta = "#B48EAD",
	yellow = "#EBCB8B",
}

-- Keybindings
config.keys = {
	-- Existing general keybindings
	{
		key = "w",
		mods = "CMD",
		action = act.CloseCurrentPane({ confirm = false }),
	},
	{
		key = "Enter",
		mods = "SHIFT",
		action = act.SendString("\x1b[13;2u"),
	},

	-- Multiplexing: Send literal Ctrl-a to terminal when Leader + a is pressed
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	-- Multiplexing: Activate copy mode
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },

	-- Activate command palette
	{ key = ":", mods = "LEADER", action = act.ActivateCommandPalette },

	-- Multiplexing: Show workspace launcher for fuzzy switching
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

	-- Multiplexing: Show tab navigator for quick switching
	{ key = "w", mods = "LEADER", action = act.ShowTabNavigator },
	-- Multiplexing: Create a new tab in the current pane's domain
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	-- Multiplexing: Activate previous tab
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	-- Multiplexing: Activate next tab
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },

	-- Multiplexing: Prompt to rename the current tab's title
	{
		key = ",",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Renaming Tab Title...:" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},

	-- Multiplexing: Enter key table for moving tabs
	{ key = ".", mods = "LEADER", action = act.ActivateKeyTable({ name = "move_tab", one_shot = false }) },

	-- Multiplexing: Split current pane vertically
	{ key = '"', mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	-- Multiplexing: Split current pane horizontally
	{ key = "%", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

	-- Multiplexing: Activate pane in specified direction (Left)
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	-- Multiplexing: Activate pane in specified direction (Down)
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	-- Multiplexing: Activate pane in specified direction (Up)
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	-- Multiplexing: Activate pane in specified direction (Right)
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	-- Multiplexing: Rotate panes clockwise within the current split
	{ key = "phys:Space", mods = "LEADER", action = act.RotatePanes("Clockwise") },

	-- Multiplexing: Toggle zoom state of the current pane
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	-- Multiplexing: Close the current pane with confirmation
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

	-- Multiplexing: Move the current pane to a new tab (and new window if only tab)
	{
		key = "!",
		mods = "LEADER | SHIFT",
		action = wezterm.action_callback(function(win, pane)
			local tab, window = pane:move_to_new_tab()
		end),
	},

	-- Multiplexing: Enter key table for resizing panes
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },

	-- Multiplexing: Detach from the current multiplexer domain
	{
		key = "d",
		mods = "LEADER",
		action = wezterm.action.DetachDomain("CurrentPaneDomain"), -- Corrected action
	},

	-- Reload Wezterm configuration
	{
		key = "R",
		mods = "LEADER|SHIFT",
		action = wezterm.action.ReloadConfiguration,
	},

	-- Open multiplexing cheatsheet
	{
		key = "?",
		mods = "LEADER",
		action = act.SplitVertical({
			domain = "CurrentPaneDomain",
			args = { "nvim", "/Users/liebl/.config/wezterm/wezterm-multiplexing.txt" },
		}),
	},
}

-- Multiplexing: Bind Leader + number to activate tabs by index (0-based)
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

-- Define key tables for modal actions
config.key_tables = {
	-- Key table for resizing panes
	resize_pane = {
		{ key = "<", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "-", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "+", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = ">", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "Escape", action = "PopKeyTable" }, -- Exit key table
		{ key = "Enter", action = "PopKeyTable" }, -- Exit key table
	},
	-- Key table for moving tabs relative to current position
	move_tab = {
		{ key = "h", action = act.MoveTabRelative(-1) },
		{ key = "j", action = act.MoveTabRelative(-1) }, -- Move left (consistent with source config)
		{ key = "k", action = act.MoveTabRelative(1) }, -- Move right (consistent with source config)
		{ key = "l", action = act.MoveTabRelative(1) },
		{ key = "Escape", action = "PopKeyTable" }, -- Exit key table
		{ key = "Enter", action = "PopKeyTable" }, -- Exit key table
	},
}

-- Status bar customization for multiplexing-related information
wezterm.on("update-status", function(window, pane)
	local status_text = window:active_workspace()
	local status_color = custom_status_colors.red

	-- Display active key table name if in a modal state
	if window:active_key_table() then
		status_text = window:active_key_table()
		status_color = custom_status_colors.cyan
	end
	-- Display "LDR" if leader key is active
	if window:leader_is_active() then
		status_text = "LDR"
		status_color = custom_status_colors.magenta
	end

	-- Left status bar content: multiplexing state indicator
	window:set_left_status(wezterm.format({
		{ Foreground = { Color = status_color } },
		{ Text = "  " },
		{ Text = wezterm.nerdfonts.oct_table .. "  " .. status_text },
		{ Text = " |" },
	}))

	-- Right status bar content: intentionally left mostly blank for multiplexing focus
	window:set_right_status(wezterm.format({
		{ Text = "  " },
	}))
end)

-- Return the configured object
return config
