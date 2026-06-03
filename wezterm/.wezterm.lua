-- =============================================================================
-- Wezterm Configuration
-- =============================================================================

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- =============================================================================
-- Core Configuration
-- =============================================================================

-- Performance
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.enable_kitty_graphics = true

-- Appearance
config.color_scheme = "tokyonight"
config.font = wezterm.font("JetBrains Mono")
config.font_size = os.getenv("WEZTERM_ORACLE") == "1" and 13 or 20
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.99

-- Behavior
config.window_close_confirmation = "NeverPrompt"
config.audible_bell = "SystemBeep"
config.notification_handling = "SuppressFromFocusedPane"
config.quick_select_patterns = {
	"git push --set-upstream origin .*",
	'claude --resume [0-9a-f-]+',
	'claude --resume "[%w_-]+"',
	"/[a-zA-Z][a-zA-Z0-9_:-]+ \\S+",
}

-- Tab Bar
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.status_update_interval = 1000

-- Multiplexing
config.leader = {
	key = "a",
	mods = "CTRL",
	timeout_milliseconds = 1000,
}
config.default_workspace = "main"
config.inactive_pane_hsb = {
	saturation = 0.24,
	brightness = 0.5,
}

config.native_macos_fullscreen_mode = false

-- =============================================================================
-- Visual Configuration
-- =============================================================================

local custom_status_colors = {
	red = "#D06F79",
	cyan = "#88C0D0",
	magenta = "#B48EAD",
	yellow = "#EBCB8B",
}

-- =============================================================================
-- Keybindings
-- =============================================================================

config.keys = {
	-- General
	{ key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "Enter", mods = "SHIFT", action = act.SendString("\x1b\r") },
	{ key = ":", mods = "LEADER", action = act.ActivateCommandPalette },
	{ key = "R", mods = "LEADER|SHIFT", action = wezterm.action.ReloadConfiguration },

	-- Leader Key Management
	{ key = "a", mods = "LEADER|CTRL", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	-- Copy Mode
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },

	-- Workspace Management
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

	-- Tab Management
	{ key = "w", mods = "LEADER", action = act.ShowTabNavigator },
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
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
	{ key = ".", mods = "LEADER", action = act.ActivateKeyTable({ name = "move_tab", one_shot = false }) },

	-- Pane Management
	-- CMD+H requires overriding macOS "Hide" shortcut via defaults write:
	--   defaults write com.github.wez.wezterm NSUserKeyEquivalents -dict-add "Hide WezTerm" -string '~^$\U00a7'
	--   defaults write com.apple.universalaccess com.apple.custommenu.apps -array-add "com.github.wez.wezterm"
	--   killall cfprefsd && restart WezTerm
	{ key = "h", mods = "CMD", action = act.ActivatePaneDirection("Left") },
	{ key = "g", mods = "CMD", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "CMD", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "CMD", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "CMD", action = act.ActivatePaneDirection("Right") },
	{ key = "h", mods = "CMD|SHIFT", action = act.SplitPane({ direction = "Left" }) },
	{ key = "j", mods = "CMD|SHIFT", action = act.SplitPane({ direction = "Down" }) },
	{ key = "k", mods = "CMD|SHIFT", action = act.SplitPane({ direction = "Up" }) },
	{ key = "l", mods = "CMD|SHIFT", action = act.SplitPane({ direction = "Right" }) },
	{ key = "h", mods = "CMD|CTRL", action = act.SplitPane({ direction = "Left", top_level = true }) },
	{ key = "j", mods = "CMD|CTRL", action = act.SplitPane({ direction = "Down", top_level = true }) },
	{ key = "k", mods = "CMD|CTRL", action = act.SplitPane({ direction = "Up", top_level = true }) },
	{ key = "l", mods = "CMD|CTRL", action = act.SplitPane({ direction = "Right", top_level = true }) },
	{ key = ";", mods = "CMD", action = act.TogglePaneZoomState },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false }) },
	{
		key = "!",
		mods = "LEADER | SHIFT",
		action = wezterm.action_callback(function(win, pane)
			pane:move_to_new_tab()
		end),
	},

	-- Session Management
	{
		key = "s",
		mods = "CMD",
		action = wezterm.action_callback(function(win, pane)
			resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
		end),
	},
	{
		key = "r",
		mods = "CMD",
		action = wezterm.action_callback(function(win, pane)
			resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
				local type = string.match(id, "^([^/]+)")
				id = string.match(id, "([^/]+)$")
				id = string.match(id, "(.+)%..+$")
				local opts = {
					relative = true,
					restore_text = true,
					on_pane_restore = resurrect.tab_state.default_on_pane_restore,
				}
				if type == "workspace" then
					local state = resurrect.state_manager.load_state(id, "workspace")
					resurrect.workspace_state.restore_workspace(state, opts)
				elseif type == "window" then
					local state = resurrect.state_manager.load_state(id, "window")
					resurrect.window_state.restore_window(pane:window(), state, opts)
				end
			end)
		end),
	},

	-- System
	{ key = "d", mods = "LEADER", action = wezterm.action.DetachDomain("CurrentPaneDomain") },
	{
		key = "?",
		mods = "LEADER",
		action = act.SplitVertical({
			domain = "CurrentPaneDomain",
			args = { "nvim", wezterm.config_dir .. "/wezterm-multiplexing.txt" },
		}),
	},
}

-- Tab Number Bindings
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

-- =============================================================================
-- Key Tables
-- =============================================================================
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

-- =============================================================================
-- Oracle Panel Support
-- =============================================================================
-- When launched with WEZTERM_ORACLE=1, sizes the window for the left gutter.
-- Normal launches pass through unchanged.

wezterm.on("gui-startup", function(cmd)
	local mux = wezterm.mux
	local tab, pane, window = mux.spawn_window(cmd or {})
	if os.getenv("WEZTERM_ORACLE") == "1" then
		window:gui_window():set_inner_size(440, 1100)
		window:gui_window():set_position(0, 30)
	end
end)

-- =============================================================================
-- Event Handlers
-- =============================================================================
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

-- =============================================================================
-- Session Management (resurrect.wezterm)
-- =============================================================================
resurrect.state_manager.periodic_save({
	interval_seconds = 300,
	save_workspaces = true,
	save_windows = true,
	save_tabs = true,
})

-- Return the configured object
return config
