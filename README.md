# Zuey WezTerm Config

A polished WezTerm configuration with Tokyo Night theme, status bar, and macOS-friendly keybindings.

## Features

- **Theme**: Tokyo Night color scheme with JetBrains Mono font
- **Status Bar**: Git branch, current directory, battery, and time
- **Tab Bar**: Minimal tab bar at bottom with active tab highlight
- **Pane Splits**: Horizontal/vertical splits with easy navigation
- **Performance**: 120 FPS max, 10K scrollback lines
- **macOS Native**: Cmd-based shortcuts that feel natural

## Installation

```bash
# Backup existing config
mv ~/.wezterm.lua ~/.wezterm.lua.backup

# Copy this config
cp wezterm.lua ~/.wezterm.lua
```

## Requirements

- [WezTerm](https://wezfurlong.org/wezterm/)
- [JetBrains Mono](https://www.jetbrains.com/lp/mono/) font

## Key Bindings

| Shortcut | Action |
|----------|--------|
| `Cmd + D` | Split horizontally |
| `Cmd + Shift + D` | Split vertically |
| `Cmd + Alt + Arrow` | Navigate panes |
| `Cmd + Ctrl + Arrow` | Resize panes |
| `Cmd + W` | Close pane |
| `Cmd + T` | New tab |
| `Cmd + Shift + Arrow` | Navigate tabs |
| `Cmd + Z` | Zoom pane |
| `Cmd + K` | Clear scrollback |
| `Cmd + F` | Search |
| `Cmd + Shift + P` | Command palette |
| `Cmd + Shift + R` | Rename tab |
| `Cmd + Shift + X` | Copy/vim mode |
| `Cmd + Shift + Space` | Quick select (URLs, paths) |
| `Cmd + Click` | Open link |
| `Opt + Arrow` | Word navigation |
| `Cmd + Arrow` | Line start/end |
| `Cmd + Backspace` | Delete line |

## Status Bar

Shows in right status:
- Git branch (when in repo)
- Current directory
- Battery status
- Current time

## License

MIT
