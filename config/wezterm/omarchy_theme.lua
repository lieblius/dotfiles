local M = {}

local DEFAULT_BLUE_ACCENT = "#7aa2f7"

local function trim(str)
	return str:match("^%s*(.-)%s*$")
end

local function split_section_path(section)
	local parts = {}
	for part in section:gmatch("[^%.]+") do
		table.insert(parts, part)
	end
	return parts
end

local function create_nested_table(root, parts)
	local current = root
	for i = 1, #parts do
		if not current[parts[i]] then
			current[parts[i]] = {}
		end
		current = current[parts[i]]
	end
	return current
end

local function normalize_color_value(value)
	value = value:gsub("^[\"']", ""):gsub("[\"']$", "")
	if value == "None" then
		return nil
	end
	if value:match("^0x") then
		value = "#" .. value:sub(3)
	end
	return value
end

local function parse_toml_colors(file_path)
	local file = io.open(file_path, "r")
	if not file then
		return nil
	end

	local content = file:read("*all")
	file:close()

	local colors = {}
	local current_section = nil

	for line in content:gmatch("[^\r\n]+") do
		line = trim(line)

		if line:match("^%[") then
			local section = line:match("%[(.-)%]")
			if section then
				current_section = section
				local parts = split_section_path(section)
				create_nested_table(colors, parts)
			end
		elseif line:match("=") and current_section then
			local key, value = line:match("([^=]+)%s*=%s*(.+)")
			if key and value then
				key = trim(key)
				value = normalize_color_value(trim(value))

				if value then
					local parts = split_section_path(current_section)
					local target_table = create_nested_table(colors, parts)
					target_table[key] = value
				end
			end
		end
	end

	return colors
end

local function adjust_color_brightness(hex_color, delta_r, delta_g, delta_b)
	return hex_color:gsub("#(%x%x)(%x%x)(%x%x)", function(r, g, b)
		local nr = math.max(0, math.min(255, tonumber(r, 16) + delta_r))
		local ng = math.max(0, math.min(255, tonumber(g, 16) + delta_g))
		local nb = math.max(0, math.min(255, tonumber(b, 16) + delta_b))
		return string.format("#%02x%02x%02x", nr, ng, nb)
	end)
end

local function lighten_color(hex_color, amount)
	return adjust_color_brightness(hex_color, amount, amount, amount)
end

local function dim_color(hex_color, amount)
	return adjust_color_brightness(hex_color, -amount, -amount, -amount)
end

local function safe_get(table, key, fallback)
	return table and table[key] or fallback
end

local function convert_alacritty_to_wezterm(alacritty_colors)
	if not alacritty_colors or not alacritty_colors.colors then
		return nil
	end

	local colors = alacritty_colors.colors
	local wezterm_colors = {}

	wezterm_colors.background = safe_get(colors.primary, "background")
	wezterm_colors.foreground = safe_get(colors.primary, "foreground")

	wezterm_colors.selection_bg = safe_get(colors.selection, "background")
	local selection_text = safe_get(colors.selection, "text")
	if selection_text and selection_text ~= "CellForeground" then
		wezterm_colors.selection_fg = selection_text
	end

	local cursor_color = safe_get(colors.cursor, "cursor")
	if cursor_color then
		wezterm_colors.cursor_bg = cursor_color
		wezterm_colors.cursor_border = cursor_color
	end
	wezterm_colors.cursor_fg = safe_get(colors.cursor, "text")

	if colors.normal then
		wezterm_colors.ansi = {
			colors.normal.black or "#000000",
			colors.normal.red or "#ff0000",
			colors.normal.green or "#00ff00",
			colors.normal.yellow or "#ffff00",
			colors.normal.blue or "#0000ff",
			colors.normal.magenta or "#ff00ff",
			colors.normal.cyan or "#00ffff",
			colors.normal.white or "#ffffff",
		}
	end

	if colors.bright then
		wezterm_colors.brights = {
			colors.bright.black or "#808080",
			colors.bright.red or "#ff8080",
			colors.bright.green or "#80ff80",
			colors.bright.yellow or "#ffff80",
			colors.bright.blue or "#8080ff",
			colors.bright.magenta or "#ff80ff",
			colors.bright.cyan or "#80ffff",
			colors.bright.white or "#ffffff",
		}
	end

	local bg = wezterm_colors.background or "#000000"
	local fg = wezterm_colors.foreground or "#ffffff"
	local blue_accent = (wezterm_colors.ansi and wezterm_colors.ansi[5]) or DEFAULT_BLUE_ACCENT

	local bg_lighter = lighten_color(bg, 32)
	local tab_bg = adjust_color_brightness(bg, -4, -4, -8)
	local inactive_tab_bg = adjust_color_brightness(bg, -8, -8, -16)
	local dimmed_fg = dim_color(fg, 96)

	wezterm_colors.scrollbar_thumb = bg_lighter
	wezterm_colors.split = bg_lighter

	wezterm_colors.tab_bar = {
		background = tab_bg,
		inactive_tab_edge = inactive_tab_bg,
		active_tab = {
			bg_color = bg,
			fg_color = blue_accent,
		},
		inactive_tab = {
			bg_color = inactive_tab_bg,
			fg_color = dimmed_fg,
		},
		inactive_tab_hover = {
			bg_color = inactive_tab_bg,
			fg_color = blue_accent,
		},
		new_tab = {
			bg_color = tab_bg,
			fg_color = blue_accent,
		},
		new_tab_hover = {
			bg_color = blue_accent,
			fg_color = inactive_tab_bg,
		},
	}

	return wezterm_colors
end

function M.load_theme()
	local theme_path = os.getenv("HOME") .. "/.config/omarchy/current/theme/alacritty.toml"
	local alacritty_colors = parse_toml_colors(theme_path)
	if alacritty_colors then
		return convert_alacritty_to_wezterm(alacritty_colors)
	end
	return nil
end

return M
