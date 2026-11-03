local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "Vs Code Dark+ (Gogh)"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 15.0
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

local act = wezterm.action

-- Cmd+C inside Herdr. Herdr runs with copy_on_select = false and copies its own
-- mouse selection when it receives Cmd+C. WezTerm drops the Cmd modifier from
-- forwarded keys (SendKey turns it into a plain "c"), so send Cmd+C in the
-- kitty keyboard encoding (CSI <codepoint>;<1 + super bit 8>u) ourselves. Only
-- Herdr understands it; a plain shell would print it as junk.
local KITTY_CMD_C = "\x1b[99;9u"

local function is_herdr(pane)
	local process = pane:get_foreground_process_name() or ""
	return process:match("/herdr$") ~= nil
end

-- Copy WezTerm's own selection (e.g. a Shift+drag) when there is one; otherwise
-- hand Cmd+C to Herdr so it copies its selection. Outside Herdr with nothing
-- selected this is the stock CopyTo, which does nothing.
local copy_or_forward_to_herdr = wezterm.action_callback(function(window, pane)
	local wezterm_has_selection = window:get_selection_text_for_pane(pane) ~= ""
	if not wezterm_has_selection and is_herdr(pane) then
		pane:send_text(KITTY_CMD_C)
	else
		window:perform_action(act.CopyTo("Clipboard"), pane)
	end
end)

config.keys = {
	{ key = "c", mods = "SUPER", action = copy_or_forward_to_herdr },

	-- macOS text-editing navigation, translated to the readline keys shells and
	-- TUIs understand.
	{ key = "LeftArrow", mods = "OPT", action = act.SendString("\x1bb") }, -- word left (Esc b)
	{ key = "RightArrow", mods = "OPT", action = act.SendString("\x1bf") }, -- word right (Esc f)
	{ key = "LeftArrow", mods = "SUPER", action = act.SendString("\x01") }, -- line start (Ctrl+A)
	{ key = "RightArrow", mods = "SUPER", action = act.SendString("\x05") }, -- line end (Ctrl+E)
	{ key = "Backspace", mods = "OPT", action = act.SendString("\x1b\x7f") }, -- delete word (Esc Backspace)
	{ key = "Backspace", mods = "SUPER", action = act.SendString("\x15") }, -- delete to line start (Ctrl+U)
}

-- Dim unfocused windows so the focused one is obvious at a glance.
local UNFOCUSED_FOREGROUND_TEXT_HSB = { hue = 1.0, saturation = 0.25, brightness = 0.45 }
local UNFOCUSED_WINDOW_BACKGROUND_OPACITY = 0.62

-- get_config_overrides() hands back a copy, so the current value is never the
-- same table we last stored; compare the fields instead of the identity.
local function same_text_hsb(actual, expected)
	if actual == nil or expected == nil then
		return actual == expected
	end
	return actual.hue == expected.hue
		and actual.saturation == expected.saturation
		and actual.brightness == expected.brightness
end

wezterm.on("window-focus-changed", function(window)
	local overrides = window:get_config_overrides() or {}
	local text_hsb, opacity
	if not window:is_focused() then
		text_hsb = UNFOCUSED_FOREGROUND_TEXT_HSB
		opacity = UNFOCUSED_WINDOW_BACKGROUND_OPACITY
	end

	-- Only write when one of the two values we own actually changes; a redundant
	-- set_config_overrides() call would trigger another config reload.
	if same_text_hsb(overrides.foreground_text_hsb, text_hsb) and overrides.window_background_opacity == opacity then
		return
	end

	overrides.foreground_text_hsb = text_hsb
	overrides.window_background_opacity = opacity
	window:set_config_overrides(overrides)
end)

return config
