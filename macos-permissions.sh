#!/bin/zsh
# ============================================================================
# macOS Permissions Setup
# ============================================================================
# Interactively configure macOS privacy permissions for automation tools
#
# Install:
#   curl -fsSL https://raw.githubusercontent.com/nicolasmertens/macos-permissions-setup/main/install.sh | zsh
#
# Run:
#   macos-permissions
#
# Repository: https://github.com/nicolasmertens/macos-permissions-setup
# License: MIT
# ============================================================================

VERSION="1.0.0"
SCRIPT_NAME="macos-permissions"
INSTALL_DIR="${HOME}/.macos-permissions"
LOG_FILE="${INSTALL_DIR}/permissions.log"

# ============================================================================
# COLORS & FORMATTING
# ============================================================================

RED=$'\e[0;31m'
GREEN=$'\e[0;32m'
YELLOW=$'\e[1;33m'
BLUE=$'\e[0;34m'
MAGENTA=$'\e[0;35m'
CYAN=$'\e[0;36m'
WHITE=$'\e[1;37m'
DIM=$'\e[2m'
NC=$'\e[0m'
BOLD=$'\e[1m'

# ============================================================================
# STATE
# ============================================================================

typeset -a SELECTED_TOOLS
typeset -a TRIGGERED_PERMISSIONS
typeset -a SKIPPED_PERMISSIONS

# ============================================================================
# TOOL DATABASE
# Format: "key|Display Name|Category|Permissions"
# ============================================================================

TOOLS_DATA=(
    # Core Automation
    "terminal|Terminal.app|Core Automation|Full Disk Access, Automation"
    "osascript|osascript|Core Automation|Automation (per-app)"
    "automator|Automator|Core Automation|Accessibility, Automation"
    "shortcuts|Shortcuts|Core Automation|Varies by action"
    "script_editor|Script Editor|Core Automation|Automation (per-app)"

    # Terminal Emulators
    "iterm2|iTerm2|Terminal Emulators|Full Disk Access, Accessibility, Automation"
    "warp|Warp|Terminal Emulators|Full Disk Access, Accessibility"
    "alacritty|Alacritty|Terminal Emulators|Full Disk Access"
    "kitty|kitty|Terminal Emulators|Full Disk Access, Accessibility"

    # Code Editors
    "vscode|Visual Studio Code|Code Editors|Full Disk Access, Accessibility"
    "cursor|Cursor|Code Editors|Full Disk Access, Accessibility"
    "zed|Zed|Code Editors|Full Disk Access, Accessibility"
    "sublime|Sublime Text|Code Editors|Full Disk Access"
    "xcode|Xcode|Code Editors|Developer Tools, Full Disk Access"

    # Automation Tools
    "peekaboo|Peekaboo|Automation Tools|Accessibility, Screen Recording"
    "raycast|Raycast|Automation Tools|Accessibility, Automation, Screen Recording"
    "alfred|Alfred|Automation Tools|Accessibility, Automation, Full Disk Access, Contacts"
    "keyboard_maestro|Keyboard Maestro|Automation Tools|Accessibility, Automation, Screen Recording, Input Monitoring"
    "hammerspoon|Hammerspoon|Automation Tools|Accessibility, Screen Recording"
    "bettertouchtool|BetterTouchTool|Automation Tools|Accessibility, Input Monitoring, Screen Recording"
    "karabiner|Karabiner-Elements|Automation Tools|Input Monitoring, Accessibility"
    "shortcat|Shortcat|Automation Tools|Accessibility"

    # Browser Automation
    "playwright|Playwright|Browser Automation|Accessibility, Screen Recording"
    "puppeteer|Puppeteer|Browser Automation|Accessibility, Screen Recording"
    "selenium|Selenium|Browser Automation|Accessibility, Screen Recording"

    # Screen & Recording
    "obs|OBS Studio|Screen & Recording|Screen Recording, Microphone, Camera"
    "cleanshot|CleanShot X|Screen & Recording|Screen Recording, Accessibility"
    "loom|Loom|Screen & Recording|Screen Recording, Microphone, Camera"
    "kap|Kap|Screen & Recording|Screen Recording"

    # Remote Access
    "ssh|SSH (Remote Login)|Remote Access|Remote Login"
    "screen_sharing|Screen Sharing|Remote Access|Screen Recording, Remote Management"
    "anydesk|AnyDesk|Remote Access|Screen Recording, Accessibility"
    "teamviewer|TeamViewer|Remote Access|Screen Recording, Accessibility"

    # AI & Assistants
    "claude_code|Claude Code|AI & Assistants|Full Disk Access"
    "github_copilot|GitHub Copilot|AI & Assistants|Full Disk Access"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

get_tool_field() {
    local key="$1"
    local field="$2"  # 1=name, 2=category, 3=permissions

    for entry in "${TOOLS_DATA[@]}"; do
        if [[ "$entry" == "$key|"* ]]; then
            echo "$entry" | cut -d'|' -f$((field + 1))
            return 0
        fi
    done
    return 1
}

get_tool_keys() {
    for entry in "${TOOLS_DATA[@]}"; do
        echo "$entry" | cut -d'|' -f1
    done
}

# ============================================================================
# LOGGING
# ============================================================================

ensure_dirs() {
    mkdir -p "$INSTALL_DIR"
    touch "$LOG_FILE"
}

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

# ============================================================================
# UI HELPERS
# ============================================================================

clear_screen() {
    printf "\033c"
}

print_box() {
    local title="$1"
    local width=66
    local padding=$(( (width - ${#title} - 2) / 2 ))

    echo "${CYAN}╭$(printf '%*s' "$width" '' | tr ' ' '─')╮${NC}"
    echo "${CYAN}│${NC}$(printf '%*s' "$padding" '')${BOLD}${WHITE}$title${NC}$(printf '%*s' "$((width - padding - ${#title}))" '')${CYAN}│${NC}"
    echo "${CYAN}╰$(printf '%*s' "$width" '' | tr ' ' '─')╯${NC}"
}

print_header() {
    echo ""
    print_box "macOS Permissions Setup v${VERSION}"
    echo "${DIM}  Configure privacy permissions for automation tools${NC}"
    echo ""
}

print_divider() {
    echo "${CYAN}$(printf '%*s' 68 '' | tr ' ' '─')${NC}"
}

print_step() {
    local step="$1"
    local total="$2"
    local title="$3"
    echo ""
    echo "${MAGENTA}━━━ Step $step/$total: $title ━━━${NC}"
    echo ""
}

wait_for_enter() {
    echo ""
    echo "${DIM}Press Enter to continue...${NC}"
    read -r
}

wait_for_permission() {
    local permission_name="$1"
    local app_name="$2"

    echo ""
    echo "  ${YELLOW}Waiting for ${BOLD}$permission_name${NC}${YELLOW} permission...${NC}"
    echo "  ${DIM}Click 'Allow' in the popup or add in System Settings${NC}"
    echo ""
    echo "  ${GREEN}[Enter]${NC} Done  ${YELLOW}[s]${NC} Skip  ${RED}[q]${NC} Quit setup"
    read -r response

    case "$response" in
        s|S)
            echo "  ${YELLOW}⏭  Skipped${NC}"
            SKIPPED_PERMISSIONS+=("$app_name: $permission_name")
            log_warn "Skipped: $app_name - $permission_name"
            return 1
            ;;
        q|Q)
            echo "  ${RED}Quitting setup...${NC}"
            show_summary
            exit 0
            ;;
        *)
            TRIGGERED_PERMISSIONS+=("$app_name: $permission_name")
            log_success "Granted: $app_name - $permission_name"
            return 0
            ;;
    esac
}

# ============================================================================
# DETECTION
# ============================================================================

check_app_installed() {
    local app_name="$1"

    [[ -d "/Applications/${app_name}.app" ]] && return 0
    [[ -d "$HOME/Applications/${app_name}.app" ]] && return 0
    [[ -d "/System/Applications/${app_name}.app" ]] && return 0
    [[ -d "/System/Applications/Utilities/${app_name}.app" ]] && return 0

    # Check variations
    [[ -d "/Applications/${app_name}" ]] && return 0

    return 1
}

check_cli_installed() {
    command -v "$1" &> /dev/null
}

get_macos_version() {
    sw_vers -productVersion
}

is_sequoia_or_later() {
    local version=$(get_macos_version)
    local major=$(echo "$version" | cut -d. -f1)
    [[ "$major" -ge 15 ]]
}

detect_installed_tools() {
    local installed=()

    # Core
    check_app_installed "Terminal" && installed+=("terminal")
    check_cli_installed "osascript" && installed+=("osascript")
    check_app_installed "Automator" && installed+=("automator")
    check_app_installed "Shortcuts" && installed+=("shortcuts")
    check_app_installed "Script Editor" && installed+=("script_editor")

    # Terminals
    check_app_installed "iTerm" && installed+=("iterm2")
    check_app_installed "Warp" && installed+=("warp")
    check_app_installed "Alacritty" && installed+=("alacritty")
    check_app_installed "kitty" && installed+=("kitty")

    # Editors
    check_app_installed "Visual Studio Code" && installed+=("vscode")
    check_app_installed "Cursor" && installed+=("cursor")
    check_app_installed "Zed" && installed+=("zed")
    check_app_installed "Sublime Text" && installed+=("sublime")
    check_app_installed "Xcode" && installed+=("xcode")

    # Automation
    check_cli_installed "peekaboo" && installed+=("peekaboo")
    check_app_installed "Raycast" && installed+=("raycast")
    (check_app_installed "Alfred 5" || check_app_installed "Alfred 4" || check_app_installed "Alfred") && installed+=("alfred")
    check_app_installed "Keyboard Maestro" && installed+=("keyboard_maestro")
    check_app_installed "Hammerspoon" && installed+=("hammerspoon")
    check_app_installed "BetterTouchTool" && installed+=("bettertouchtool")
    check_app_installed "Karabiner-Elements" && installed+=("karabiner")
    check_app_installed "Shortcat" && installed+=("shortcat")

    # Browser automation
    check_cli_installed "npx" && installed+=("playwright" "puppeteer" "selenium")

    # Recording
    check_app_installed "OBS" && installed+=("obs")
    check_app_installed "CleanShot X" && installed+=("cleanshot")
    check_app_installed "Loom" && installed+=("loom")
    check_app_installed "Kap" && installed+=("kap")

    # Remote
    installed+=("ssh")
    installed+=("screen_sharing")
    check_app_installed "AnyDesk" && installed+=("anydesk")
    check_app_installed "TeamViewer" && installed+=("teamviewer")

    # AI
    check_cli_installed "claude" && installed+=("claude_code")

    echo "${installed[@]}"
}

# ============================================================================
# PERMISSION TRIGGERS
# ============================================================================

open_privacy_pane() {
    local pane="$1"

    case "$pane" in
        accessibility)    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" ;;
        screen_recording) open "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture" ;;
        full_disk)        open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles" ;;
        automation)       open "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation" ;;
        input_monitoring) open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent" ;;
        camera)           open "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera" ;;
        microphone)       open "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone" ;;
        contacts)         open "x-apple.systempreferences:com.apple.preference.security?Privacy_Contacts" ;;
        remote_login)     open "x-apple.systempreferences:com.apple.preference.sharing?Services_RemoteLogin" ;;
    esac
}

trigger_accessibility() {
    local app_name="$1"

    echo "  ${BLUE}🔐 Accessibility${NC} - Control your computer"
    echo "  ${DIM}Required for: clicks, keystrokes, window management${NC}"
    echo ""

    open_privacy_pane "accessibility"

    echo "  ${YELLOW}➜ Add ${BOLD}$app_name${NC}${YELLOW} to the list${NC}"
    echo "  ${DIM}  Click + button → Select the app → Toggle ON${NC}"
}

trigger_screen_recording() {
    local app_name="$1"

    echo "  ${BLUE}🎬 Screen Recording${NC} - Capture screen content"
    echo "  ${DIM}Required for: screenshots, UI detection${NC}"

    if is_sequoia_or_later; then
        echo "  ${YELLOW}⚠  Sequoia: This permission expires monthly${NC}"
    fi
    echo ""

    open_privacy_pane "screen_recording"

    echo "  ${YELLOW}➜ Add ${BOLD}$app_name${NC}${YELLOW} to the list${NC}"
}

trigger_full_disk_access() {
    local app_name="$1"

    echo "  ${BLUE}💾 Full Disk Access${NC} - Access all files"
    echo "  ${DIM}Required for: reading/writing files anywhere${NC}"
    echo ""

    open_privacy_pane "full_disk"

    echo "  ${YELLOW}➜ Add ${BOLD}$app_name${NC}${YELLOW} to the list${NC}"
}

trigger_automation() {
    local source_app="$1"
    local target_app="$2"

    echo "  ${BLUE}🤖 Automation${NC} - Control other apps"
    echo "  ${DIM}Allowing ${BOLD}$source_app${NC}${DIM} to control ${BOLD}$target_app${NC}"
    echo ""

    # Trigger the permission popup
    osascript -e "tell application \"$target_app\" to activate" 2>/dev/null &
    local pid=$!
    sleep 1
    kill $pid 2>/dev/null || true

    echo "  ${YELLOW}➜ Click 'OK' or 'Allow' on the popup${NC}"
}

trigger_input_monitoring() {
    local app_name="$1"

    echo "  ${BLUE}⌨️  Input Monitoring${NC} - Monitor keyboard/mouse"
    echo "  ${DIM}Required for: key remapping, shortcuts${NC}"
    echo ""

    open_privacy_pane "input_monitoring"

    echo "  ${YELLOW}➜ Add ${BOLD}$app_name${NC}${YELLOW} to the list${NC}"
}

trigger_remote_login() {
    echo "  ${BLUE}🌐 Remote Login${NC} - Allow SSH connections"
    echo "  ${DIM}Required for: SSH access to this Mac${NC}"
    echo ""

    open_privacy_pane "remote_login"

    echo "  ${YELLOW}➜ Enable 'Remote Login' and add allowed users${NC}"
}

trigger_camera() {
    local app_name="$1"
    echo "  ${BLUE}📷 Camera${NC} - Access camera"
    echo ""
    open_privacy_pane "camera"
    echo "  ${YELLOW}➜ Add ${BOLD}$app_name${NC}${YELLOW} to the list${NC}"
}

trigger_microphone() {
    local app_name="$1"
    echo "  ${BLUE}🎤 Microphone${NC} - Access microphone"
    echo ""
    open_privacy_pane "microphone"
    echo "  ${YELLOW}➜ Add ${BOLD}$app_name${NC}${YELLOW} to the list${NC}"
}

trigger_developer_tools() {
    echo "  ${BLUE}🛠  Developer Tools${NC} - Enable developer mode"
    echo ""

    if sudo -n true 2>/dev/null; then
        sudo /usr/sbin/DevToolsSecurity -enable 2>/dev/null && {
            echo "  ${GREEN}✓ Developer Tools enabled${NC}"
            return 0
        }
    fi

    echo "  ${YELLOW}➜ Run: sudo DevToolsSecurity -enable${NC}"
}

# ============================================================================
# TOOL SETUP
# ============================================================================

setup_tool() {
    local tool_key="$1"
    local tool_name=$(get_tool_field "$tool_key" 1)
    local category=$(get_tool_field "$tool_key" 2)
    local permissions=$(get_tool_field "$tool_key" 3)

    clear_screen
    print_header
    print_box "Setting up: $tool_name"
    echo "  ${DIM}Category: $category${NC}"
    echo "  ${DIM}Permissions needed: $permissions${NC}"
    echo ""

    log_info "Starting setup for $tool_name"

    # Split permissions by comma
    local perm_array=("${(@s/, /)permissions}")
    local step=1
    local total=${#perm_array[@]}

    for perm in "${perm_array[@]}"; do
        print_step "$step" "$total" "$perm"

        case "$perm" in
            Accessibility)
                trigger_accessibility "$tool_name"
                wait_for_permission "Accessibility" "$tool_name"
                ;;
            "Screen Recording")
                trigger_screen_recording "$tool_name"
                wait_for_permission "Screen Recording" "$tool_name"
                ;;
            "Full Disk Access")
                trigger_full_disk_access "$tool_name"
                wait_for_permission "Full Disk Access" "$tool_name"
                ;;
            Automation*|"Automation (per-app)")
                if [[ "$tool_key" == "osascript" || "$tool_key" == "terminal" || "$tool_key" == "script_editor" ]]; then
                    for target in "System Events" "Finder" "Safari"; do
                        trigger_automation "$tool_name" "$target"
                        wait_for_permission "Automation ($target)" "$tool_name"
                    done
                else
                    trigger_automation "$tool_name" "System Events"
                    wait_for_permission "Automation" "$tool_name"
                fi
                ;;
            "Input Monitoring")
                trigger_input_monitoring "$tool_name"
                wait_for_permission "Input Monitoring" "$tool_name"
                ;;
            "Remote Login")
                trigger_remote_login
                wait_for_permission "Remote Login" "$tool_name"
                ;;
            "Developer Tools")
                trigger_developer_tools
                wait_for_permission "Developer Tools" "$tool_name"
                ;;
            Camera)
                trigger_camera "$tool_name"
                wait_for_permission "Camera" "$tool_name"
                ;;
            Microphone)
                trigger_microphone "$tool_name"
                wait_for_permission "Microphone" "$tool_name"
                ;;
            Contacts)
                open_privacy_pane "contacts"
                echo "  ${YELLOW}➜ Add ${BOLD}$tool_name${NC}${YELLOW} to Contacts access${NC}"
                wait_for_permission "Contacts" "$tool_name"
                ;;
            "Varies by action"|"Remote Management")
                echo "  ${DIM}This permission varies - configure as needed${NC}"
                wait_for_enter
                ;;
        esac

        ((step++))
    done

    echo ""
    echo "  ${GREEN}✓ $tool_name setup complete${NC}"
    sleep 1
}

# ============================================================================
# TOOL SELECTION UI
# ============================================================================

show_tool_selection() {
    clear_screen
    print_header

    local installed=$(detect_installed_tools)

    echo "${BOLD}Select tools to configure:${NC}"
    echo ""

    # Organize by category
    local categories=("Core Automation" "Terminal Emulators" "Code Editors" "Automation Tools" "Browser Automation" "Screen & Recording" "Remote Access" "AI & Assistants")

    local index=1
    typeset -A INDEX_TO_TOOL

    for category in "${categories[@]}"; do
        local has_tools=false
        for entry in "${TOOLS_DATA[@]}"; do
            local cat=$(echo "$entry" | cut -d'|' -f3)
            if [[ "$cat" == "$category" ]]; then
                has_tools=true
                break
            fi
        done

        if $has_tools; then
            echo "${CYAN}$category${NC}"

            for entry in "${TOOLS_DATA[@]}"; do
                local key=$(echo "$entry" | cut -d'|' -f1)
                local name=$(echo "$entry" | cut -d'|' -f2)
                local cat=$(echo "$entry" | cut -d'|' -f3)
                local perms=$(echo "$entry" | cut -d'|' -f4)

                if [[ "$cat" == "$category" ]]; then
                    local marker=""
                    if [[ " $installed " == *" $key "* ]]; then
                        marker="${GREEN}●${NC}"
                    else
                        marker="${DIM}○${NC}"
                    fi

                    INDEX_TO_TOOL[$index]="$key"
                    printf "  %s ${CYAN}%2d${NC}) %-24s ${DIM}%s${NC}\n" "$marker" "$index" "$name" "$perms"
                    ((index++))
                fi
            done
            echo ""
        fi
    done

    print_divider
    echo "  ${GREEN}a${NC}) All installed tools (recommended)"
    echo "  ${GREEN}q${NC}) Quick setup (Peekaboo + Terminal + osascript)"
    echo "  ${GREEN}c${NC}) Custom selection"
    echo "  ${RED}x${NC}) Exit"
    echo ""
    echo "${DIM}Legend: ${GREEN}●${NC} installed  ${DIM}○ not found${NC}"
    echo ""
    echo -n "Your choice: "
    read -r selection

    case "$selection" in
        x|X)
            echo "${YELLOW}Goodbye!${NC}"
            exit 0
            ;;
        a|A)
            for key in ${=installed}; do
                SELECTED_TOOLS+=("$key")
            done
            ;;
        q|Q)
            for tool in "peekaboo" "terminal" "osascript"; do
                if [[ " $installed " == *" $tool "* ]]; then
                    SELECTED_TOOLS+=("$tool")
                fi
            done
            ;;
        c|C)
            echo ""
            echo "Enter tool numbers separated by spaces (e.g., '1 5 12'):"
            read -r numbers
            for num in ${=numbers}; do
                if [[ -n "${INDEX_TO_TOOL[$num]}" ]]; then
                    SELECTED_TOOLS+=("${INDEX_TO_TOOL[$num]}")
                fi
            done
            ;;
        *)
            for num in ${=selection}; do
                if [[ -n "${INDEX_TO_TOOL[$num]}" ]]; then
                    SELECTED_TOOLS+=("${INDEX_TO_TOOL[$num]}")
                fi
            done
            ;;
    esac
}

# ============================================================================
# SUMMARY
# ============================================================================

show_summary() {
    clear_screen
    print_header
    print_box "Setup Complete!"
    echo ""

    if [[ ${#TRIGGERED_PERMISSIONS[@]} -gt 0 ]]; then
        echo "${GREEN}Configured:${NC}"
        for perm in "${TRIGGERED_PERMISSIONS[@]}"; do
            echo "  ${GREEN}✓${NC} $perm"
        done
        echo ""
    fi

    if [[ ${#SKIPPED_PERMISSIONS[@]} -gt 0 ]]; then
        echo "${YELLOW}Skipped:${NC}"
        for perm in "${SKIPPED_PERMISSIONS[@]}"; do
            echo "  ${YELLOW}⏭${NC} $perm"
        done
        echo ""
    fi

    print_divider
    echo ""
    echo "${CYAN}Tips:${NC}"
    echo "  • Restart apps for permissions to take effect"
    if is_sequoia_or_later; then
        echo "  • ${YELLOW}Sequoia:${NC} Screen Recording expires monthly - re-run this script"
    fi
    echo "  • Run ${BOLD}macos-permissions${NC} anytime to add more tools"
    echo "  • Logs saved to: ${DIM}$LOG_FILE${NC}"
    echo ""

    if check_cli_installed "peekaboo"; then
        echo "${CYAN}Verify Peekaboo:${NC} peekaboo permissions"
    fi
    echo ""

    log_info "Setup completed. Configured: ${#TRIGGERED_PERMISSIONS[@]}, Skipped: ${#SKIPPED_PERMISSIONS[@]}"
}

# ============================================================================
# CLI OPTIONS
# ============================================================================

show_help() {
    cat << 'EOF'
macOS Permissions Setup

Interactive tool to configure macOS privacy permissions for automation tools.

Usage: macos-permissions [options]

Options:
  -h, --help      Show this help
  -v, --version   Show version
  -l, --list      List all supported tools
  -q, --quick     Quick setup (Peekaboo + Terminal + osascript)
  --log           Show recent log entries

Examples:
  macos-permissions          # Interactive mode
  macos-permissions --quick  # Fast setup for essentials
  macos-permissions --list   # See all supported tools

Repository: https://github.com/nicolasmertens/macos-permissions-setup
EOF
}

list_tools() {
    echo "Supported tools:"
    echo ""

    local installed=$(detect_installed_tools)

    for entry in "${TOOLS_DATA[@]}"; do
        local key=$(echo "$entry" | cut -d'|' -f1)
        local name=$(echo "$entry" | cut -d'|' -f2)
        local cat=$(echo "$entry" | cut -d'|' -f3)

        local marker="  "
        if [[ " $installed " == *" $key "* ]]; then
            marker="${GREEN}✓${NC}"
        fi

        printf "  %s %-24s ${DIM}[%s]${NC}\n" "$marker" "$name" "$cat"
    done
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Check macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        echo "${RED}Error: This script only runs on macOS${NC}"
        exit 1
    fi

    ensure_dirs
    log_info "Starting macOS Permissions Setup v${VERSION}"

    # Parse arguments
    case "${1:-}" in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--version)
            echo "v${VERSION}"
            exit 0
            ;;
        -l|--list)
            list_tools
            exit 0
            ;;
        -q|--quick)
            local installed=$(detect_installed_tools)
            for tool in "peekaboo" "terminal" "osascript"; do
                if [[ " $installed " == *" $tool "* ]]; then
                    SELECTED_TOOLS+=("$tool")
                fi
            done
            ;;
        --log)
            tail -50 "$LOG_FILE" 2>/dev/null || echo "No logs yet"
            exit 0
            ;;
        "")
            # Interactive mode
            clear_screen
            print_header

            echo "This tool helps you configure macOS privacy permissions"
            echo "for automation tools like Peekaboo, Raycast, and more."
            echo ""
            echo "${YELLOW}Note:${NC} You'll need to manually click 'Allow' on popups"
            echo "or add apps in System Settings > Privacy & Security."
            echo ""

            local macos_ver=$(get_macos_version)
            echo "${DIM}Detected: macOS $macos_ver${NC}"

            if is_sequoia_or_later; then
                echo "${YELLOW}Sequoia detected:${NC} Screen Recording permissions expire monthly"
            fi

            wait_for_enter
            show_tool_selection
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run 'macos-permissions --help' for usage"
            exit 1
            ;;
    esac

    if [[ ${#SELECTED_TOOLS[@]} -eq 0 ]]; then
        echo "${YELLOW}No tools selected.${NC}"
        exit 0
    fi

    log_info "Selected tools: ${SELECTED_TOOLS[*]}"

    echo ""
    echo "${GREEN}Selected: ${SELECTED_TOOLS[*]}${NC}"
    echo "${DIM}Starting in 2 seconds...${NC}"
    sleep 2

    for tool in "${SELECTED_TOOLS[@]}"; do
        setup_tool "$tool"
    done

    show_summary
}

main "$@"
