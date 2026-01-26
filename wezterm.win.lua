local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Session persistence plugin
local resurrect = wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'

-- Default shell: PowerShell (Windows)
config.default_prog = { 'powershell.exe' }

-- Default working directory
config.default_cwd = 'D:/www'

-- Hide window decorations (app bar)
config.window_decorations = 'RESIZE'

-- Larger default window size (columns x rows)
config.initial_cols = 160
config.initial_rows = 45

-- Appearance
config.color_scheme = 'Tokyo Night'
config.font = wezterm.font('JetBrains Mono', { weight = 'Medium' })
config.font_size = 12
config.line_height = 1.2
config.window_padding = { left = 12, right = 12, top = 12, bottom = 12 }
config.window_background_opacity = 0.97

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
      icon = '+'
    elseif b.state_of_charge >= 0.8 then
      icon = 'Full'
    elseif b.state_of_charge >= 0.4 then
      icon = 'Med'
    else
      icon = 'Low'
    end
    battery = string.format('%s %.0f%%', icon, b.state_of_charge * 100)
  end

  -- Build status bar elements
  local status_elements = {}

  if git_branch ~= '' then
    table.insert(status_elements, { Foreground = { Color = '#7aa2f7' } })
    table.insert(status_elements, { Text = ' git:' .. git_branch })
  end

  if cwd_str ~= '' then
    table.insert(status_elements, { Foreground = { Color = '#9ece6a' } })
    table.insert(status_elements, { Text = ' ' .. cwd_str })
  end

  if battery ~= '' then
    table.insert(status_elements, { Foreground = { Color = '#e0af68' } })
    table.insert(status_elements, { Text = ' [' .. battery .. ']' })
  end

  table.insert(status_elements, { Foreground = { Color = '#bb9af7' } })
  table.insert(status_elements, { Text = ' ' .. time .. ' ' })

  window:set_right_status(wezterm.format(status_elements))
end)

-- Key bindings (Windows: CTRL instead of CMD)
config.keys = {
  -- Smart Ctrl+C: copy if selection exists, otherwise send SIGINT
  { key = 'c', mods = 'CTRL', action = wezterm.action_callback(function(window, pane)
    local has_selection = window:get_selection_text_for_pane(pane) ~= ''
    if has_selection then
      window:perform_action(act.CopyTo 'ClipboardAndPrimarySelection', pane)
      window:perform_action(act.ClearSelection, pane)
    else
      window:perform_action(act.SendKey { key = 'c', mods = 'CTRL' }, pane)
    end
  end) },

  -- Smart Ctrl+V: paste from clipboard
  { key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard' },

  -- Word navigation (Alt + Arrow)
  { key = 'LeftArrow', mods = 'ALT', action = wezterm.action_callback(function(window, pane)
    pane:send_text('\x1bb')
  end) },
  { key = 'RightArrow', mods = 'ALT', action = wezterm.action_callback(function(window, pane)
    pane:send_text('\x1bf')
  end) },

  -- Line navigation (Ctrl + Arrow)
  { key = 'LeftArrow', mods = 'CTRL', action = act.SendKey { key = 'Home' } },
  { key = 'RightArrow', mods = 'CTRL', action = act.SendKey { key = 'End' } },

  -- Delete word backward (Ctrl + Backspace)
  { key = 'Backspace', mods = 'CTRL', action = act.SendString '\x17' },

  -- Delete word forward (Ctrl + Delete)
  { key = 'Delete', mods = 'CTRL', action = act.SendString '\x1bd' },

  -- Delete to beginning of line (Ctrl + Shift + Backspace)
  { key = 'Backspace', mods = 'CTRL|SHIFT', action = wezterm.action_callback(function(window, pane)
    pane:send_text('\x15')
  end) },

  -- Delete to end of line (Ctrl + Shift + Delete)
  { key = 'Delete', mods = 'CTRL|SHIFT', action = wezterm.action_callback(function(window, pane)
    pane:send_text('\x0b')
  end) },

  -- Split panes (Ctrl+D horizontal, Ctrl+Shift+D vertical)
  { key = 'd', mods = 'CTRL', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },

  -- Pane navigation (Ctrl+Alt+Arrow)
  { key = 'LeftArrow', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'CTRL|ALT', action = act.ActivatePaneDirection 'Down' },

  -- Close pane (Ctrl+W)
  { key = 'w', mods = 'CTRL', action = act.CloseCurrentPane { confirm = true } },

  -- New tab (Ctrl+T)
  { key = 't', mods = 'CTRL', action = act.SpawnTab 'CurrentPaneDomain' },

  -- Tab navigation (Ctrl+Shift+Arrow)
  { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },

  -- Move tab left/right (Ctrl+Alt+Arrow)
  { key = 'LeftArrow', mods = 'CTRL|ALT', action = act.MoveTabRelative(-1) },
  { key = 'RightArrow', mods = 'CTRL|ALT', action = act.MoveTabRelative(1) },

  -- Clear scrollback (Ctrl+K)
  { key = 'k', mods = 'CTRL', action = act.ClearScrollback 'ScrollbackAndViewport' },

  -- Quick select mode (Ctrl+Shift+Space) - select URLs, paths, etc.
  { key = 'Space', mods = 'CTRL|SHIFT', action = act.QuickSelect },

  -- Copy mode / vim-like selection (Ctrl+Shift+X)
  { key = 'x', mods = 'CTRL|SHIFT', action = act.ActivateCopyMode },

  -- Search (Ctrl+F)
  { key = 'f', mods = 'CTRL', action = act.Search { CaseInSensitiveString = '' } },

  -- Toggle fullscreen (Ctrl+Shift+Enter)
  { key = 'Enter', mods = 'CTRL|SHIFT', action = act.ToggleFullScreen },

  -- Zoom current pane (Ctrl+Z)
  { key = 'z', mods = 'CTRL', action = act.TogglePaneZoomState },

  -- Resize panes (Ctrl+Shift+Arrow)
  { key = 'LeftArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'RightArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Right', 5 } },
  { key = 'UpArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'DownArrow', mods = 'ALT|SHIFT', action = act.AdjustPaneSize { 'Down', 5 } },

  -- Command palette (Ctrl+Shift+P)
  { key = 'p', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },

  -- Save/restore workspace (Ctrl+Alt+S)
  { key = 's', mods = 'CTRL|ALT', action = act.ShowLauncherArgs { flags = 'WORKSPACES' } },

  -- Rename tab (Ctrl+Shift+R)
  { key = 'r', mods = 'CTRL|SHIFT', action = act.PromptInputLine {
    description = 'Enter new tab name:',
    action = wezterm.action_callback(function(window, pane, line)
      if line then
        window:active_tab():set_title(line)
      end
    end),
  }},
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

-- Mouse bindings - ONLY Ctrl+Click opens URLs (disable default click-to-open)
config.mouse_bindings = {
  -- Ctrl+Click to open links
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  },
  -- Disable default click on links (just move cursor instead)
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'ClipboardAndPrimarySelection',
  },
}

return config
