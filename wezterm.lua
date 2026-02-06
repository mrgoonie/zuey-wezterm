local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Session persistence plugin
local resurrect = wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'

-- Default working directory
config.default_cwd = wezterm.home_dir .. '/www'

-- Hide window decorations (app bar)
config.window_decorations = 'RESIZE'

-- Larger default window size (columns x rows)
config.initial_cols = 160
config.initial_rows = 45

-- Appearance
config.color_scheme = 'Tokyo Night'
config.font = wezterm.font('JetBrains Mono', { weight = 'Medium' })
config.font_size = 13
config.line_height = 1.3
config.window_padding = { left = 12, right = 12, top = 12, bottom = 12 }
config.window_background_opacity = 0.97
config.macos_window_background_blur = 20

-- Tab bar
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.tab_max_width = 50
config.show_tab_index_in_tab_bar = false

-- Performance
config.max_fps = 120
config.animation_fps = 60

-- Cursor
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500

-- Scrollback
config.scrollback_lines = 10000

-- Workspace name
config.default_workspace = 'main'

-- Long-running command notifications (alert after 10 seconds)
config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_duration_ms = 75,
  fade_out_duration_ms = 75,
  target = 'CursorColor',
}

-- Tab title formatting with padding and active tab highlight
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local title = tab.active_pane.title
  if tab.tab_title and #tab.tab_title > 0 then
    title = tab.tab_title
  end

  if tab.is_active then
    return {
      { Background = { Color = '#000000' } },
      { Foreground = { Color = '#a6e22e' } },
      { Attribute = { Intensity = 'Bold' } },
      { Text = '  ' .. title .. '  ' },
    }
  end
  return '  ' .. title .. '  '
end)

-- Status bar configuration
config.status_update_interval = 1000

wezterm.on('update-status', function(window, pane)
  -- Get current working directory
  local cwd = pane:get_current_working_dir()
  local cwd_str = ''
  if cwd then
    cwd_str = cwd.file_path or ''
    -- Shorten home directory to ~
    cwd_str = cwd_str:gsub(wezterm.home_dir, '~')
    -- Shorten long paths
    if #cwd_str > 40 then
      cwd_str = '...' .. cwd_str:sub(-37)
    end
  end

  -- Get git branch (if in a git repo)
  local git_branch = ''
  local success, stdout, stderr = wezterm.run_child_process({
    'git', '-C', cwd and cwd.file_path or '.', 'branch', '--show-current'
  })
  if success then
    git_branch = stdout:gsub('%s+', '')
  end

  -- Get current time
  local time = wezterm.strftime('%H:%M')

  -- Get battery info
  local battery = ''
  for _, b in ipairs(wezterm.battery_info()) do
    local icon = ''
    if b.state == 'Charging' then
      icon = '🔌'
    elseif b.state_of_charge >= 0.8 then
      icon = '🔋'
    elseif b.state_of_charge >= 0.4 then
      icon = '🪫'
    else
      icon = '⚠️'
    end
    battery = string.format('%s %.0f%%', icon, b.state_of_charge * 100)
  end

  -- Build status bar elements
  local status_elements = {}

  if git_branch ~= '' then
    table.insert(status_elements, { Foreground = { Color = '#7aa2f7' } })
    table.insert(status_elements, { Text = ' 🌿 ' .. git_branch })
  end

  if cwd_str ~= '' then
    table.insert(status_elements, { Foreground = { Color = '#9ece6a' } })
    table.insert(status_elements, { Text = ' 📂 ' .. cwd_str })
  end

  if battery ~= '' then
    table.insert(status_elements, { Foreground = { Color = '#e0af68' } })
    table.insert(status_elements, { Text = ' ' .. battery })
  end

  table.insert(status_elements, { Foreground = { Color = '#bb9af7' } })
  table.insert(status_elements, { Text = ' 🕐 ' .. time .. ' ' })

  window:set_right_status(wezterm.format(status_elements))
end)

-- Key bindings
config.keys = {
  -- Word navigation (Option + Arrow)
  { key = 'LeftArrow', mods = 'OPT', action = act.Multiple {
    act.SendKey { key = 'Escape' },
    act.SendKey { key = 'b' },
  }},
  { key = 'RightArrow', mods = 'OPT', action = act.Multiple {
    act.SendKey { key = 'Escape' },
    act.SendKey { key = 'f' },
  }},

  -- Line navigation (Cmd + Arrow)
  { key = 'LeftArrow', mods = 'CMD', action = act.SendKey { key = 'a', mods = 'CTRL' } },
  { key = 'RightArrow', mods = 'CMD', action = act.SendKey { key = 'e', mods = 'CTRL' } },

  -- Delete whole line (Cmd + Backspace)
  { key = 'Backspace', mods = 'CMD', action = act.SendKey { key = 'u', mods = 'CTRL' } },

  -- Split panes
  { key = 'd', mods = 'CMD', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'CMD|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Pane navigation (Cmd + Arrow in panes)
  { key = 'LeftArrow', mods = 'CMD|ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'CMD|ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'CMD|ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'CMD|ALT', action = act.ActivatePaneDirection 'Down' },

  -- Close pane (Cmd + W)
  { key = 'w', mods = 'CMD', action = act.CloseCurrentPane { confirm = true } },

  -- New tab (Cmd + T)
  { key = 't', mods = 'CMD', action = act.SpawnTab 'CurrentPaneDomain' },

  -- Tab navigation (Cmd + Shift + Arrow)
  { key = 'LeftArrow', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(1) },

  -- Clear scrollback (Cmd + K)
  { key = 'k', mods = 'CMD', action = act.ClearScrollback 'ScrollbackAndViewport' },

  -- Quick select mode (Cmd + Shift + Space) - select URLs, paths, etc.
  { key = 'Space', mods = 'CMD|SHIFT', action = act.QuickSelect },

  -- Copy mode / vim-like selection (Cmd + Shift + X)
  { key = 'x', mods = 'CMD|SHIFT', action = act.ActivateCopyMode },

  -- Search (Cmd + F)
  { key = 'f', mods = 'CMD', action = act.Search { CaseInSensitiveString = '' } },

  -- Toggle fullscreen
  { key = 'Enter', mods = 'CMD|SHIFT', action = act.ToggleFullScreen },

  -- Zoom current pane (Cmd + Z)
  { key = 'z', mods = 'CMD', action = act.TogglePaneZoomState },

  -- Move tab left/right (Cmd + Ctrl + Arrow)
  { key = 'LeftArrow', mods = 'CMD|CTRL', action = act.MoveTabRelative(-1) },
  { key = 'RightArrow', mods = 'CMD|CTRL', action = act.MoveTabRelative(1) },

  -- Resize panes (Cmd + Ctrl + Shift + Arrow)
  { key = 'LeftArrow', mods = 'CMD|CTRL|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'RightArrow', mods = 'CMD|CTRL|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'UpArrow', mods = 'CMD|CTRL|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'DownArrow', mods = 'CMD|CTRL|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },

  -- Command palette (Cmd + Shift + P)
  { key = 'p', mods = 'CMD|SHIFT', action = act.ActivateCommandPalette },

  -- Save/restore workspace
  { key = 's', mods = 'CMD|CTRL', action = act.ShowLauncherArgs { flags = 'WORKSPACES' } },

  -- Rename tab (Cmd + Shift + R)
  { key = 'r', mods = 'CMD|SHIFT', action = act.PromptInputLine {
    description = 'Enter new tab name:',
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        window:active_tab():set_title(line)
      end
    end),
  }},
}

-- Mouse bindings - ONLY Cmd+Click opens URLs (disable default click-to-open)
config.mouse_bindings = {
  -- Cmd+Click to open links
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = act.OpenLinkAtMouseCursor,
  },
  -- Disable default click on links (just move cursor instead)
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'ClipboardAndPrimarySelection',
  },
}

-- Session persistence: auto-save periodically and restore on startup
resurrect.state_manager.periodic_save({ interval_seconds = 300, save_workspaces = true })

wezterm.on('gui-startup', function(cmd)
  resurrect.state_manager.resurrect_on_gui_startup()
end)

wezterm.on('window-close-requested', function(window, pane)
  local workspace_state = resurrect.workspace_state.get_workspace_state()
  resurrect.state_manager.save_state(workspace_state)
  resurrect.state_manager.write_current_state(workspace_state.workspace, 'workspace')
end)

-- Long-running command notification (bell after command finishes)
-- Works with shell integration - add to your .zshrc:
-- precmd() { echo -ne '\a' }
-- Or for bash in .bashrc:
-- PROMPT_COMMAND='echo -ne "\a"'

return config
