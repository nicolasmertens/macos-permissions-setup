#!/bin/zsh
# ============================================================================
# macOS Permissions Setup - Installer
# ============================================================================
# Install with:
#   curl -fsSL https://raw.githubusercontent.com/nicolasmertens/macos-permissions-setup/main/install.sh | zsh
#
# Or with wget:
#   wget -qO- https://raw.githubusercontent.com/nicolasmertens/macos-permissions-setup/main/install.sh | bash
# ============================================================================

set -e

# Config
REPO="nicolasmertens/macos-permissions-setup"
INSTALL_DIR="${HOME}/.macos-permissions"
BIN_DIR="${HOME}/.local/bin"
SCRIPT_NAME="macos-permissions"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${CYAN}╭────────────────────────────────────────────────╮${NC}"
echo -e "${CYAN}│${NC}  ${BOLD}macOS Permissions Setup - Installer${NC}          ${CYAN}│${NC}"
echo -e "${CYAN}╰────────────────────────────────────────────────╯${NC}"
echo ""

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error: This tool only runs on macOS${NC}"
    exit 1
fi

# Create directories
echo -e "${CYAN}Creating directories...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

# Download main script
echo -e "${CYAN}Downloading script...${NC}"
if command -v curl &> /dev/null; then
    curl -fsSL "https://raw.githubusercontent.com/${REPO}/main/macos-permissions.sh" -o "${INSTALL_DIR}/macos-permissions.sh"
elif command -v wget &> /dev/null; then
    wget -qO "${INSTALL_DIR}/macos-permissions.sh" "https://raw.githubusercontent.com/${REPO}/main/macos-permissions.sh"
else
    echo -e "${RED}Error: curl or wget required${NC}"
    exit 1
fi

chmod +x "${INSTALL_DIR}/macos-permissions.sh"

# Create symlink
echo -e "${CYAN}Creating command link...${NC}"
ln -sf "${INSTALL_DIR}/macos-permissions.sh" "${BIN_DIR}/${SCRIPT_NAME}"

# Check if bin dir is in PATH
if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    echo ""
    echo -e "${YELLOW}Add this to your shell config (~/.zshrc or ~/.bashrc):${NC}"
    echo ""
    echo -e "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""

    # Try to add automatically
    if [[ -f "${HOME}/.zshrc" ]]; then
        if ! grep -q '.local/bin' "${HOME}/.zshrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.zshrc"
            echo -e "${GREEN}✓ Added to ~/.zshrc${NC}"
        fi
    elif [[ -f "${HOME}/.bashrc" ]]; then
        if ! grep -q '.local/bin' "${HOME}/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "${HOME}/.bashrc"
            echo -e "${GREEN}✓ Added to ~/.bashrc${NC}"
        fi
    fi
fi

echo ""
echo -e "${GREEN}╭────────────────────────────────────────────────╮${NC}"
echo -e "${GREEN}│${NC}  ${BOLD}Installation complete!${NC}                       ${GREEN}│${NC}"
echo -e "${GREEN}╰────────────────────────────────────────────────╯${NC}"
echo ""
echo -e "Run the tool:"
echo -e "  ${CYAN}${SCRIPT_NAME}${NC}           # Interactive mode"
echo -e "  ${CYAN}${SCRIPT_NAME} --quick${NC}   # Quick setup"
echo -e "  ${CYAN}${SCRIPT_NAME} --help${NC}    # Show all options"
echo ""
echo -e "${YELLOW}Tip:${NC} Open a new terminal or run: source ~/.zshrc"
echo ""

# Offer to run now
echo -n "Run setup now? [Y/n] "
read -r response
if [[ "$response" != "n" && "$response" != "N" ]]; then
    exec "${INSTALL_DIR}/macos-permissions.sh"
fi
