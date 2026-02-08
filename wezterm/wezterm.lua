local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action

-- ===================
-- Appearance
-- ===================

-- Tokyo Night color scheme
config.color_scheme = "Tokyo Night"

-- Font
config.font = wezterm.font_with_fallback({
    { family = "JetBrainsMono Nerd Font", weight = "Regular" },
    { family = "JetBrains Mono",          weight = "Regular" },
    "Noto Color Emoji",
})
config.font_size = 12.0
config.line_height = 1.1

-- Window
config.window_background_opacity = 0.95
config.window_padding = {
    left = 10,
    right = 10,
    top = 10,
    bottom = 5,
}
config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
config.window_close_confirmation = "NeverPrompt"
config.initial_cols = 140
config.initial_rows = 40

-- Tab bar
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = true
config.tab_max_width = 32

-- Tab bar styling (matches Tokyo Night)
config.window_frame = {
    font = wezterm.font({ family = "JetBrainsMono Nerd Font", weight = "Bold" }),
    font_size = 10.0,
    active_titlebar_bg = "#1a1b26",
    inactive_titlebar_bg = "#1a1b26",
}

config.colors = {
    tab_bar = {
        active_tab = {
            bg_color = "#7aa2f7",
            fg_color = "#1a1b26",
        },
        inactive_tab = {
            bg_color = "#1a1b26",
            fg_color = "#565f89",
        },
        inactive_tab_hover = {
            bg_color = "#24283b",
            fg_color = "#a9b1d6",
        },
        new_tab = {
            bg_color = "#1a1b26",
            fg_color = "#565f89",
        },
        new_tab_hover = {
            bg_color = "#24283b",
            fg_color = "#a9b1d6",
        },
    },
}

-- Cursor
config.default_cursor_style = "SteadyBar"

-- No bell
config.audible_bell = "Disabled"
config.visual_bell = {
    fade_in_duration_ms = 0,
    fade_out_duration_ms = 0,
}

-- Performance (RTX 2070)
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 144
config.animation_fps = 60

-- ===================
-- Shell
-- ===================

config.default_prog = { "fish" }

-- ===================
-- Built-in Multiplexer
-- ===================

-- Leader key: Ctrl+Space
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1500 }

config.keys = {
    -- Pane splitting
    { key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "-", mods = "LEADER",       action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

    -- Pane navigation (vim-style)
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

    -- Arrow keys too
    { key = "LeftArrow",  mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "DownArrow",  mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "UpArrow",    mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "RightArrow", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

    -- Pane resize
    { key = "H", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
    { key = "J", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
    { key = "K", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
    { key = "L", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

    -- Close pane
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },

    -- Pane cycling: Ctrl+Tab / Ctrl+Shift+Tab
    { key = "Tab", mods = "CTRL", action = act.ActivatePaneDirection("Next") },
    { key = "Tab", mods = "CTRL|SHIFT", action = act.ActivatePaneDirection("Prev") },

    -- Tabs
    { key = "c", mods = "LEADER",       action = act.SpawnTab("CurrentPaneDomain") },
    { key = "n", mods = "LEADER",       action = act.ActivateTabRelative(1) },
    { key = "p", mods = "LEADER",       action = act.ActivateTabRelative(-1) },
    { key = "1", mods = "LEADER",       action = act.ActivateTab(0) },
    { key = "2", mods = "LEADER",       action = act.ActivateTab(1) },
    { key = "3", mods = "LEADER",       action = act.ActivateTab(2) },
    { key = "4", mods = "LEADER",       action = act.ActivateTab(3) },
    { key = "5", mods = "LEADER",       action = act.ActivateTab(4) },

	-- Scrollback
	{ key = "PageUp", mods = "NONE", action = act.ScrollByPage(-1) },
	{ key = "PageDown", mods = "NONE", action = act.ScrollByPage(1) },

	-- Delete word
	{ key = "Backspace", mods = "CTRL", action = act.SendKey({ key = "w", mods = "CTRL" }) },

    -- Zoom pane
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

    -- Quick DS workspace: top split left/right + full bottom
    {
        key = "d",
        mods = "LEADER",
        action = wezterm.action_callback(function(window, pane)
            -- Split current pane, new pane goes to bottom
            pane:split({ direction = "Bottom", size = 0.5 })
            -- Split current (top) pane, new pane goes to right
            pane:split({ direction = "Right", size = 0.5 })
        end),
    },

    -- Copy mode
    { key = "[", mods = "LEADER", action = act.ActivateCopyMode },

    -- Search & reload
    { key = "f", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },
    { key = "r", mods = "LEADER", action = act.ReloadConfiguration },

    -- Font size
    { key = "+", mods = "CTRL|SHIFT", action = act.IncreaseFontSize },
    { key = "-", mods = "CTRL",       action = act.DecreaseFontSize },
    { key = "0", mods = "CTRL",       action = act.ResetFontSize },
}

-- ===================
-- Mouse
-- ===================

config.mouse_bindings = {
    -- Ctrl+Click to open URLs
    {
        event = { Up = { streak = 1, button = "Left" } },
        mods = "CTRL",
        action = act.OpenLinkAtMouseCursor,
    },
    -- Right-click: copy if selection exists, paste if not
    {
        event = { Down = { streak = 1, button = "Right" } },
        action = wezterm.action_callback(function(window, pane)
            local has_selection = window:get_selection_text_for_pane(pane) ~= ""
            if has_selection then
                window:perform_action(act.CopyTo("Clipboard"), pane)
                window:perform_action(act.ClearSelection, pane)
            else
                window:perform_action(act.PasteFrom("Clipboard"), pane)
            end
        end),
    },
}

-- ===================
-- Status Bar
-- ===================

wezterm.on("update-status", function(window, pane)
    local date = wezterm.strftime("%H:%M  %a %b %d")
    local hostname = wezterm.hostname()

    window:set_right_status(wezterm.format({
        { Foreground = { Color = "#7aa2f7" } },
        { Text = " " .. hostname .. "  " },
        { Foreground = { Color = "#9ece6a" } },
        { Text = date .. "  " },
    }))
end)

-- ===================
-- Tab Title
-- ===================

wezterm.on("format-tab-title", function(tab, tabs, panes, cfg, hover, max_width)
    local title = tab.active_pane.title
    if title and #title > 0 then
        title = title:gsub("^(%S+).*", "%1")
    else
        title = "shell"
    end

    local index = tab.tab_index + 1
    return string.format(" %d: %s ", index, title)
end)

return config
