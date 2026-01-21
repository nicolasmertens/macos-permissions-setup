#!/bin/bash
# ============================================================================
# macOS Permissions Setup
# ============================================================================
# Interactively configure macOS privacy permissions for automation tools
#
# Install:
#   curl -fsSL https://raw.githubusercontent.com/nicolasmertens/macos-permissions-setup/main/install.sh | bash
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
CONFIG_FILE="${INSTALL_DIR}/config"

# ============================================================================
# COLORS & FORMATTING
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'
BOLD='\033[1m'

# Box drawing characters
BOX_TL="╭"
BOX_TR="╮"
BOX_BL="╰"
BOX_BR="╯"
BOX_H="─"
BOX_V="│"

# ============================================================================
# STATE
# ============================================================================

SELECTED_TOOLS=()
TRIGGERED_PERMISSIONS=()
SKIPPED_PERMISSIONS=()
FAILED_PERMISSIONS=()

# ============================================================================
# TOOL DATABASE
# ============================================================================

declare -A TOOLS=(
    # Core Automation
    ["terminal"]="Terminal.app|Core Automation|Full Disk Access, Automation"
    ["osascript"]="osascript|Core Automation|Automation (per-app)"
    ["automator"]="Automator|Core Automation|Accessibility, Automation"
    ["shortcuts"]="Shortcuts|Core Automation|Varies by action"
    ["script_editor"]="Script Editor|Core Automation|Automation (per-app)"

    # Terminal Emulators
    ["iterm2"]="iTerm2|Terminal Emulators|Full Disk Access, Accessibility, Automation"
    ["warp"]="Warp|Terminal Emulators|Full Disk Access, Accessibility"
    ["alacritty"]="Alacritty|Terminal Emulators|Full Disk Access"
    ["kitty"]="kitty|Terminal Emulators|Full Disk Access, Accessibility"

    # Code Editors
    ["vscode"]="Visual Studio Code|Code Editors|Full Disk Access, Accessibility"
    ["cursor"]="Cursor|Code Editors|Full Disk Access, Accessibility"
    ["zed"]="Zed|Code Editors|Full Disk Access, Accessibility"
    ["sublime"]="Sublime Text|Code Editors|Full Disk Access"
    ["xcode"]="Xcode|Code Editors|Developer Tools, Full Disk Access"

    # Automation Tools
    ["peekaboo"]="Peekaboo|Automation Tools|Accessibility, Screen Recording"
    ["raycast"]="Raycast|Automation Tools|Accessibility, Automation, Screen Recording"
    ["alfred"]="Alfred|Automation Tools|Accessibility, Automation, Full Disk Access, Contacts"
    ["keyboard_maestro"]="Keyboard Maestro|Automation Tools|Accessibility, Automation, Screen Recording, Input Monitoring"
    ["hammerspoon"]="Hammerspoon|Automation Tools|Accessibility, Screen Recording"
    ["bettertouchtool"]="BetterTouchTool|Automation Tools|Accessibility, Input Monitoring, Screen Recording"
    ["karabiner"]="Karabiner-Elements|Automation Tools|Input Monitoring, Accessibility"
    ["shortcat"]="Shortcat|Automation Tools|Accessibility"

    # Browser Automation
    ["playwright"]="Playwright|Browser Automation|Accessibility, Screen Recording"
    ["puppeteer"]="Puppeteer|Browser Automation|Accessibility, Screen Recording"
    ["selenium"]="Selenium|Browser Automation|Accessibility, Screen Recording"

    # Screen & Recording
    ["obs"]="OBS Studio|Screen & Recording|Screen Recording, Microphone, Camera"
    ["cleanshot"]="CleanShot X|Screen & Recording|Screen Recording, Accessibility"
    ["loom"]="Loom|Screen & Recording|Screen Recording, Microphone, Camera"
    ["kap"]="Kap|Screen & Recording|Screen Recording"

    # Remote Access
    ["ssh"]="SSH (Remote Login)|Remote Access|Remote Login"
    ["screen_sharing"]="Screen Sharing|Remote Access|Screen Recording, Remote Management"
    ["anydesk"]="AnyDesk|Remote Access|Screen Recording, Accessibility"
    ["teamviewer"]="TeamViewer|Remote Access|Screen Recording, Accessibility"

    # AI & Assistants
    ["claude_code"]="Claude Code|AI & Assistants|Full Disk Access"
    ["github_copilot"]="GitHub Copilot|AI & Assistants|Full Disk Access"
)

# App bundle identifiers for precise matching
declare -A APP_BUNDLES=(
    ["terminal"]="com.apple.Terminal"
    ["iterm2"]="com.googlecode.iterm2"
    ["vscode"]="com.microsoft.VSCode"
    ["cursor"]="com.todesktop.230313mzl4w4u92"
    ["raycast"]="com.raycast.macos"
    ["alfred"]="com.runningwithcrayons.Alfred"
    ["hammerspoon"]="org.hammerspoon.Hammerspoon"
    ["obs"]="com.obsproject.obs-studio"
)

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
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
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

    echo -e "${CYAN}${BOX_TL}$(printf '%*s' "$width" '' | tr ' ' "$BOX_H")${BOX_TR}${NC}"
    echo -e "${CYAN}${BOX_V}${NC}$(printf '%*s' "$padding" '')${BOLD}${WHITE}$title${NC}$(printf '%*s' "$((width - padding - ${#title}))" '')${CYAN}${BOX_V}${NC}"
    echo -e "${CYAN}${BOX_BL}$(printf '%*s' "$width" '' | tr ' ' "$BOX_H")${BOX_BR}${NC}"
}

print_header() {
    echo ""
    print_box "macOS Permissions Setup v${VERSION}"
    echo -e "${DIM}  Configure privacy permissions for automation tools${NC}"
    echo ""
}

print_divider() {
    echo -e "${CYAN}$(printf '%*s' 68 '' | tr ' ' '─')${NC}"
}

print_step() {
    local step="$1"
    local total="$2"
    local title="$3"
    echo ""
    echo -e "${MAGENTA}━━━ Step $step/$total: $title ━━━${NC}"
    echo ""
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p "$pid" > /dev/null 2>&1; do
        for (( i=0; i<${#spinstr}; i++ )); do
            printf "\r${CYAN}[%s]${NC} " "${spinstr:$i:1}"
            sleep $delay
        done
    done
    printf "\r   \r"
}

wait_for_enter() {
    echo ""
    echo -e "${DIM}Press Enter to continue...${NC}"
    read -r
}

wait_for_permission() {
    local permission_name="$1"
    local app_name="$2"

    echo ""
    echo -e "${YELLOW}  Waiting for ${BOLD}$permission_name${NC}${YELLOW} permission...${NC}"
    echo -e "${DIM}  Click 'Allow' in the popup or add in System Settings${NC}"
    echo ""
    echo -e "  ${GREEN}[Enter]${NC} Done  ${YELLOW}[s]${NC} Skip  ${RED}[q]${NC} Quit setup"
    read -r response

    case "$response" in
        s|S)
            echo -e "  ${YELLOW}⏭  Skipped${NC}"
            SKIPPED_PERMISSIONS+=("$app_name: $permission_name")
            log_warn "Skipped: $app_name - $permission_name"
            return 1
            ;;
        q|Q)
            echo -e "  ${RED}Quitting setup...${NC}"
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
    local locations=(
        "/Applications/${app_name}.app"
        "$HOME/Applications/${app_name}.app"
        "/System/Applications/${app_name}.app"
        "/System/Applications/Utilities/${app_name}.app"
    )

    for loc in "${locations[@]}"; do
        [[ -d "$loc" ]] && return 0
    done

    # Check by bundle ID if available
    local key
    for key in "${!APP_BUNDLES[@]}"; do
        if [[ "${TOOLS[$key]}" == "$app_name|"* ]]; then
            mdfind "kMDItemCFBundleIdentifier == '${APP_BUNDLES[$key]}'" 2>/dev/null | grep -q . && return 0
        fi
    done

    return 1
}

check_cli_installed() {
    command -v "$1" &> /dev/null
}

get_macos_version() {
    sw_vers -productVersion
}

is_sequoia_or_later() {
    local version
    version=$(get_macos_version)
    local major
    major=$(echo "$version" | cut -d. -f1)
    [[ "$major" -ge 15 ]]
}

detect_installed_tools() {
    local installed=()

    # Map tool keys to detection methods
    check_app_installed "Terminal" && installed+=("terminal")
    check_cli_installed "osascript" && installed+=("osascript")
    check_app_installed "Automator" && installed+=("automator")
    check_app_installed "Shortcuts" && installed+=("shortcuts")
    check_app_installed "Script Editor" && installed+=("script_editor")

    check_app_installed "iTerm" && installed+=("iterm2")
    check_app_installed "Warp" && installed+=("warp")
    check_app_installed "Alacritty" && installed+=("alacritty")
    check_app_installed "kitty" && installed+=("kitty")

    check_app_installed "Visual Studio Code" && installed+=("vscode")
    check_app_installed "Cursor" && installed+=("cursor")
    check_app_installed "Zed" && installed+=("zed")
    check_app_installed "Sublime Text" && installed+=("sublime")
    check_app_installed "Xcode" && installed+=("xcode")

    check_cli_installed "peekaboo" && installed+=("peekaboo")
    check_app_installed "Raycast" && installed+=("raycast")
    (check_app_installed "Alfred 5" || check_app_installed "Alfred 4") && installed+=("alfred")
    check_app_installed "Keyboard Maestro" && installed+=("keyboard_maestro")
    check_app_installed "Hammerspoon" && installed+=("hammerspoon")
    check_app_installed "BetterTouchTool" && installed+=("bettertouchtool")
    check_app_installed "Karabiner-Elements" && installed+=("karabiner")
    check_app_installed "Shortcat" && installed+=("shortcat")

    check_cli_installed "npx" && installed+=("playwright" "puppeteer" "selenium")

    check_app_installed "OBS" && installed+=("obs")
    check_app_installed "CleanShot X" && installed+=("cleanshot")
    check_app_installed "Loom" && installed+=("loom")
    check_app_installed "Kap" && installed+=("kap")

    installed+=("ssh")  # Always available
    installed+=("screen_sharing")
    check_app_installed "AnyDesk" && installed+=("anydesk")
    check_app_installed "TeamViewer" && installed+=("teamviewer")

    check_cli_installed "claude" && installed+=("claude_code")

    echo "${installed[@]}"
}

# ============================================================================
# PERMISSION TRIGGERS
# ============================================================================

open_privacy_pane() {
    local pane="$1"
    local pane_map=(
        ["accessibility"]="Privacy_Accessibility"
        ["screen_recording"]="Privacy_ScreenCapture"
        ["full_disk"]="Privacy_AllFiles"
        ["automation"]="Privacy_Automation"
        ["input_monitoring"]="Privacy_ListenEvent"
        ["camera"]="Privacy_Camera"
        ["microphone"]="Privacy_Microphone"
        ["contacts"]="Privacy_Contacts"
        ["photos"]="Privacy_Photos"
        ["files_folders"]="Privacy_FilesAndFolders"
        ["remote_login"]="Sharing"
    )

    local target="${pane_map[$pane]:-$pane}"

    if [[ "$pane" == "remote_login" ]]; then
        open "x-apple.systempreferences:com.apple.preference.sharing?Services_RemoteLogin"
    else
        open "x-apple.systempreferences:com.apple.preference.security?$target"
    fi
}

trigger_accessibility() {
    local app_name="$1"

    echo -e "  ${BLUE}🔐 Accessibility${NC} - Control your computer"
    echo -e "  ${DIM}Required for: clicks, keystrokes, window management${NC}"
    echo ""

    open_privacy_pane "accessibility"

    echo -e "  ${YELLOW}➜ Add ${BOLD}$app_name${NC}${YELLOW} to the list${NC}"
    echo -e "  ${DIM}  Click + button → Select the app → Toggle ON${NC}"
}

trigger_screen_recording() {
    local app_name="$1"

    echo -e "  ${BLUE}🎬 Screen Recording${NC} - Capture screen content"
    echo -e "  ${DIM}Required for: screenshots, UI detection${NC}"

    if is_sequoia_or_later; then
        echo -e "  ${YELLOW}⚠  Sequoia: This permission expires monthly${NC}"
    fi
    echo ""

    open_privacy_pane "screen_recording"

    echo -e "  ${YELLOW}➜ Add ${BOLD}$app_name${NC}${YELLOW} to the list${NC}"
}

trigger_full_disk_access() {
    local app_name="$1"

    echo -e "  ${BLUE}💾 Full Disk Access${NC} - Access all files"
    echo -e "  ${DIM}Required for: reading/writing files anywhere${NC}"
    echo ""

    open_privacy_pane "full_disk"

    echo -e "  ${YELLOW}➜ Add ${BOLD}$app_name${NC}${YELLOW} to the list${NC}"
}

trigger_automation() {
    local source_app="$1"
    local target_app="$2"

    echo -e "  ${BLUE}🤖 Automation${NC} - Control other apps"
    echo -e "  ${DIM}Allowing ${BOLD}$source_app${NC}${DIM} to control ${BOLD}$target_app${NC}"
    echo ""

    # Actually trigger the permission
    osascript -e "tell application \"$target_app\" to activate" 2>/dev/null &
    local pid=$!
    sleep 1
    kill $pid 2>/dev/null || true

    echo -e "  ${YELLOW}➜ Click 'OK' or 'Allow' on the popup${NC}"
}

trigger_input_monitoring() {
    local app_name="$1"

    echo -e "  ${BLUE}⌨️  Input Monitoring${NC} - Monitor keyboard/mouse"
    echo -e "  ${DIM}Required for: key remapping, shortcuts${NC}"
    echo ""

    open_privacy_pane "input_monitoring"

    echo -e "  ${YELLOW}➜ Add ${BOLD}$app_name${NC}${YELLOW} to the list${NC}"
}

trigger_remote_login() {
    echo -e "  ${BLUE}🌐 Remote Login${NC} - Allow SSH connections"
    echo -e "  ${DIM}Required for: SSH access to this Mac${NC}"
    echo ""

    open_privacy_pane "remote_login"

    echo -e "  ${YELLOW}➜ Enable 'Remote Login' and add allowed users${NC}"
}

trigger_camera() {
    local app_name="$1"

    echo -e "  ${BLUE}📷 Camera${NC} - Access camera"
    echo ""

    open_privacy_pane "camera"

    echo -e "  ${YELLOW}➜ Add ${BOLD}$app_name${NC}${YELLOW} to the list${NC}"
}

trigger_microphone() {
    local app_name="$1"

    echo -e "  ${BLUE}🎤 Microphone${NC} - Access microphone"
    echo ""

    open_privacy_pane "microphone"

    echo -e "  ${YELLOW}➜ Add ${BOLD}$app_name${NC}${YELLOW} to the list${NC}"
}

trigger_developer_tools() {
    echo -e "  ${BLUE}🛠  Developer Tools${NC} - Enable developer mode"
    echo ""

    if sudo -n true 2>/dev/null; then
        sudo /usr/sbin/DevToolsSecurity -enable 2>/dev/null && {
            echo -e "  ${GREEN}✓ Developer Tools enabled${NC}"
            return 0
        }
    fi

    echo -e "  ${YELLOW}➜ Run: sudo DevToolsSecurity -enable${NC}"
}

# ============================================================================
# TOOL SETUP FUNCTIONS
# ============================================================================

setup_tool() {
    local tool_key="$1"
    local tool_data="${TOOLS[$tool_key]}"

    IFS='|' read -r tool_name category permissions <<< "$tool_data"

    clear_screen
    print_header
    print_box "Setting up: $tool_name"
    echo -e "  ${DIM}Category: $category${NC}"
    echo -e "  ${DIM}Permissions needed: $permissions${NC}"
    echo ""

    log_info "Starting setup for $tool_name"

    # Parse and trigger each permission
    IFS=', ' read -ra perm_array <<< "$permissions"
    local step=1
    local total=${#perm_array[@]}

    for perm in "${perm_array[@]}"; do
        print_step "$step" "$total" "$perm"

        case "$perm" in
            "Accessibility")
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
            "Automation"*)
                # For osascript and similar, trigger for common apps
                if [[ "$tool_key" == "osascript" || "$tool_key" == "terminal" ]]; then
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
            "Camera")
                trigger_camera "$tool_name"
                wait_for_permission "Camera" "$tool_name"
                ;;
            "Microphone")
                trigger_microphone "$tool_name"
                wait_for_permission "Microphone" "$tool_name"
                ;;
            "Contacts")
                open_privacy_pane "contacts"
                echo -e "  ${YELLOW}➜ Add ${BOLD}$tool_name${NC}${YELLOW} to Contacts access${NC}"
                wait_for_permission "Contacts" "$tool_name"
                ;;
            *)
                echo -e "  ${DIM}Skipping unknown permission: $perm${NC}"
                ;;
        esac

        ((step++))
    done

    echo ""
    echo -e "  ${GREEN}✓ $tool_name setup complete${NC}"
    sleep 1
}

# ============================================================================
# TOOL SELECTION UI
# ============================================================================

show_tool_selection() {
    clear_screen
    print_header

    local installed
    installed=$(detect_installed_tools)

    echo -e "${BOLD}Select tools to configure:${NC}"
    echo ""

    # Organize tools by category
    declare -A categories
    for tool_key in "${!TOOLS[@]}"; do
        IFS='|' read -r name cat perms <<< "${TOOLS[$tool_key]}"
        categories["$cat"]+="$tool_key "
    done

    local index=1
    declare -A INDEX_TO_TOOL

    for category in "Core Automation" "Terminal Emulators" "Code Editors" "Automation Tools" "Browser Automation" "Screen & Recording" "Remote Access" "AI & Assistants"; do
        if [[ -n "${categories[$category]}" ]]; then
            echo -e "${CYAN}$category${NC}"

            for tool_key in ${categories[$category]}; do
                IFS='|' read -r name cat perms <<< "${TOOLS[$tool_key]}"

                local marker=""
                if [[ " $installed " == *" $tool_key "* ]]; then
                    marker="${GREEN}●${NC}"
                else
                    marker="${DIM}○${NC}"
                fi

                INDEX_TO_TOOL[$index]="$tool_key"
                printf "  %s ${CYAN}%2d${NC}) %-24s ${DIM}%s${NC}\n" "$marker" "$index" "$name" "$perms"
                ((index++))
            done
            echo ""
        fi
    done

    print_divider
    echo -e "  ${GREEN}a${NC}) All installed tools (recommended)"
    echo -e "  ${GREEN}q${NC}) Quick setup (Peekaboo + Terminal + osascript)"
    echo -e "  ${GREEN}c${NC}) Custom selection"
    echo -e "  ${RED}x${NC}) Exit"
    echo ""
    echo -e "${DIM}Legend: ${GREEN}●${NC} installed  ${DIM}○ not found${NC}"
    echo ""
    echo -n "Your choice: "
    read -r selection

    case "$selection" in
        x|X)
            echo -e "${YELLOW}Goodbye!${NC}"
            exit 0
            ;;
        a|A)
            for tool_key in $installed; do
                SELECTED_TOOLS+=("$tool_key")
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
            echo -e "Enter tool numbers separated by spaces (e.g., '1 5 12'):"
            read -r numbers
            for num in $numbers; do
                if [[ -n "${INDEX_TO_TOOL[$num]}" ]]; then
                    SELECTED_TOOLS+=("${INDEX_TO_TOOL[$num]}")
                fi
            done
            ;;
        *)
            # Try to parse as numbers
            for num in $selection; do
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
        echo -e "${GREEN}Configured:${NC}"
        for perm in "${TRIGGERED_PERMISSIONS[@]}"; do
            echo -e "  ${GREEN}✓${NC} $perm"
        done
        echo ""
    fi

    if [[ ${#SKIPPED_PERMISSIONS[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Skipped:${NC}"
        for perm in "${SKIPPED_PERMISSIONS[@]}"; do
            echo -e "  ${YELLOW}⏭${NC} $perm"
        done
        echo ""
    fi

    print_divider
    echo ""
    echo -e "${CYAN}Tips:${NC}"
    echo -e "  • Restart apps for permissions to take effect"
    if is_sequoia_or_later; then
        echo -e "  • ${YELLOW}Sequoia:${NC} Screen Recording expires monthly - re-run this script"
    fi
    echo -e "  • Run ${BOLD}macos-permissions${NC} anytime to add more tools"
    echo -e "  • Logs saved to: ${DIM}$LOG_FILE${NC}"
    echo ""

    if check_cli_installed "peekaboo"; then
        echo -e "${CYAN}Verify Peekaboo:${NC} peekaboo permissions"
    fi
    echo ""

    log_info "Setup completed. Configured: ${#TRIGGERED_PERMISSIONS[@]}, Skipped: ${#SKIPPED_PERMISSIONS[@]}"
}

# ============================================================================
# MAIN
# ============================================================================

show_help() {
    echo "macOS Permissions Setup v${VERSION}"
    echo ""
    echo "Usage: $SCRIPT_NAME [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help"
    echo "  -v, --version   Show version"
    echo "  -l, --list      List all supported tools"
    echo "  -q, --quick     Quick setup (Peekaboo + Terminal + osascript)"
    echo "  --log           Show recent log entries"
    echo ""
    echo "Interactive mode (default):"
    echo "  $SCRIPT_NAME"
    echo ""
    echo "Repository: https://github.com/nicolasmertens/macos-permissions-setup"
}

list_tools() {
    echo "Supported tools:"
    echo ""

    local installed
    installed=$(detect_installed_tools)

    for tool_key in "${!TOOLS[@]}"; do
        IFS='|' read -r name cat perms <<< "${TOOLS[$tool_key]}"

        local marker="  "
        if [[ " $installed " == *" $tool_key "* ]]; then
            marker="${GREEN}✓${NC}"
        fi

        printf "  %s %-24s ${DIM}[%s]${NC}\n" "$marker" "$name" "$cat"
    done | sort
}

main() {
    # Check macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        echo -e "${RED}Error: This script only runs on macOS${NC}"
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
            local installed
            installed=$(detect_installed_tools)
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

            echo -e "This tool helps you configure macOS privacy permissions"
            echo -e "for automation tools like Peekaboo, Raycast, and more."
            echo ""
            echo -e "${YELLOW}Note:${NC} You'll need to manually click 'Allow' on popups"
            echo -e "or add apps in System Settings > Privacy & Security."
            echo ""

            local macos_ver
            macos_ver=$(get_macos_version)
            echo -e "${DIM}Detected: macOS $macos_ver${NC}"

            if is_sequoia_or_later; then
                echo -e "${YELLOW}Sequoia detected:${NC} Screen Recording permissions expire monthly"
            fi

            wait_for_enter
            show_tool_selection
            ;;
        *)
            echo "Unknown option: $1"
            echo "Run '$SCRIPT_NAME --help' for usage"
            exit 1
            ;;
    esac

    if [[ ${#SELECTED_TOOLS[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No tools selected.${NC}"
        exit 0
    fi

    log_info "Selected tools: ${SELECTED_TOOLS[*]}"

    echo ""
    echo -e "${GREEN}Selected: ${SELECTED_TOOLS[*]}${NC}"
    echo -e "${DIM}Starting in 2 seconds...${NC}"
    sleep 2

    for tool in "${SELECTED_TOOLS[@]}"; do
        setup_tool "$tool"
    done

    show_summary
}

main "$@"
