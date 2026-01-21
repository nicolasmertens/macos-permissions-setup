# macOS Permissions Setup

Interactively configure macOS privacy permissions for automation tools. No more hunting through System Settings - this script triggers permission prompts one by one and guides you through each step.

Perfect for setting up new Macs or configuring tools like [Peekaboo](https://github.com/steipete/peekaboo), [Clawdbot](https://github.com/your-org/clawdbot), Raycast, Keyboard Maestro, and more.

![Demo](https://raw.githubusercontent.com/nicolasmertens/macos-permissions-setup/main/demo.gif)

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/nicolasmertens/macos-permissions-setup/main/install.sh | bash
```

Or with wget:
```bash
wget -qO- https://raw.githubusercontent.com/nicolasmertens/macos-permissions-setup/main/install.sh | bash
```

## Usage

```bash
# Interactive mode - select tools from a menu
macos-permissions

# Quick setup (Peekaboo + Terminal + osascript)
macos-permissions --quick

# List all supported tools
macos-permissions --list

# Show help
macos-permissions --help
```

## Features

- **Auto-detects installed tools** - Shows which apps are on your system
- **30+ supported tools** - Terminals, editors, automation tools, and more
- **Step-by-step guidance** - Triggers one permission at a time with clear instructions
- **Skip option** - Skip any permission you don't need
- **Logging** - Tracks what was configured for future reference
- **Sequoia-aware** - Warns about monthly Screen Recording expiration

## Supported Tools

### Core Automation
- Terminal, osascript, Automator, Shortcuts, Script Editor

### Terminal Emulators
- iTerm2, Warp, Alacritty, kitty

### Code Editors
- VS Code, Cursor, Zed, Sublime Text, Xcode

### Automation Tools
- **Peekaboo** - Screen capture & macOS automation
- **Raycast** - Launcher with automation
- **Alfred** - Productivity app
- **Keyboard Maestro** - Macro automation
- **Hammerspoon** - Lua-based automation
- **BetterTouchTool** - Input customization
- **Karabiner-Elements** - Keyboard remapping

### Browser Automation
- Playwright, Puppeteer, Selenium

### Screen & Recording
- OBS Studio, CleanShot X, Loom, Kap

### Remote Access
- SSH, Screen Sharing, AnyDesk, TeamViewer

### AI & Assistants
- Claude Code, GitHub Copilot

## Permissions Reference

| Permission | What It Allows | System Settings Location |
|------------|---------------|-------------------------|
| Accessibility | Control mouse, keyboard, windows | Privacy & Security → Accessibility |
| Screen Recording | Capture screen content | Privacy & Security → Screen Recording |
| Full Disk Access | Read/write any file | Privacy & Security → Full Disk Access |
| Automation | Control other apps (AppleScript) | Privacy & Security → Automation |
| Input Monitoring | Monitor keyboard/mouse | Privacy & Security → Input Monitoring |
| Camera | Access camera | Privacy & Security → Camera |
| Microphone | Access microphone | Privacy & Security → Microphone |

## macOS Sequoia Note

Starting with macOS 15 (Sequoia), Screen Recording permissions **expire monthly**. You'll need to re-grant this permission periodically. This script helps by opening the right System Settings pane.

## Logs

Setup logs are saved to `~/.macos-permissions/permissions.log`:

```bash
# View recent logs
macos-permissions --log

# Full log file
cat ~/.macos-permissions/permissions.log
```

## Uninstall

```bash
rm -rf ~/.macos-permissions
rm -f ~/.local/bin/macos-permissions
```

## Contributing

Found a tool that should be included? Open an issue or PR!

To add a new tool, edit the `TOOLS` array in `macos-permissions.sh`:

```bash
TOOLS["tool_key"]="Display Name|Category|Permission1, Permission2"
```

## Why This Exists

Setting up automation tools on macOS is painful. Each tool needs different permissions, and you have to manually navigate to System Settings multiple times. This script:

1. Detects what's installed on your system
2. Lets you select which tools to configure
3. Opens the right System Settings pane for each permission
4. Guides you through the process step by step

Originally created for setting up [Clawdbot](https://discord.gg/clawdbot) and [Peekaboo](https://github.com/steipete/peekaboo) on new Macs.

## License

MIT License - see [LICENSE](LICENSE)

## Credits

Created by [@nicolasmertens](https://github.com/nicolasmertens)

Inspired by the Clawdbot community discussions about permission setup pain points.
