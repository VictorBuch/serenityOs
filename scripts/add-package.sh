#!/usr/bin/env nix-shell
#! nix-shell -i bash -p jq
# Script to help add new packages to NixOS configuration
# Makes it easy to create new modules or add to existing configurations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIXOS_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}=== NixOS Package Addition Helper ===${NC}\n"

# Ask for package name
read -p "$(echo -e ${GREEN}Enter package name:${NC} )" PACKAGE_NAME

if [ -z "$PACKAGE_NAME" ]; then
    echo -e "${RED}Error: Package name cannot be empty${NC}"
    exit 1
fi

# Verify package exists in nixpkgs
echo -e "\n${YELLOW}Searching for package in nixpkgs...${NC}"
SEARCH_RESULTS=$(nix search nixpkgs "$PACKAGE_NAME" --json 2>/dev/null)

if [ "$SEARCH_RESULTS" = "{}" ]; then
    echo -e "${RED}Error: No packages found matching '${PACKAGE_NAME}'${NC}"
    exit 1
fi

# Display search results
echo -e "\n${GREEN}Found packages:${NC}"
echo "$SEARCH_RESULTS" | jq -r 'to_entries[] |
    (.key | split(".") | last) as $pkg_name |
    "  \($pkg_name) (\(.value.version)) - \(.value.description)"' | head -10

# Check for exact match
EXACT_MATCH=$(echo "$SEARCH_RESULTS" | jq -r --arg pkg "$PACKAGE_NAME" '
    to_entries[] |
    select((.key | split(".") | last) == $pkg) |
    .key' | head -1)

if [ -z "$EXACT_MATCH" ]; then
    echo -e "\n${YELLOW}Warning: No exact match for '${PACKAGE_NAME}' found${NC}"
    echo -e "${YELLOW}The above are similar packages. Please verify the correct package name.${NC}"
    read -p "$(echo -e ${YELLOW}Continue anyway? [y/N]:${NC} )" CONTINUE
    if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
        exit 0
    fi
else
    echo -e "\n${GREEN}✓ Exact match found: $EXACT_MATCH${NC}"
fi

# Ask for category
echo -e "\n${GREEN}Select category:${NC}"
echo "1) Apps - Desktop/CLI applications"
echo "2) Desktop Environment - WM/DE components"
echo "3) System - System-level services/tools"
echo "4) Homelab - Server services (serenity host)"
echo "5) Home Manager - User-specific config"
read -p "$(echo -e ${GREEN}Choice [1-5]:${NC} )" CATEGORY_CHOICE

case $CATEGORY_CHOICE in
    1)
        CATEGORY="apps"
        BASE_DIR="$NIXOS_DIR/modules/apps"
        ;;
    2)
        CATEGORY="desktop-environments"
        BASE_DIR="$NIXOS_DIR/modules/nixos/desktop-environments"
        ;;
    3)
        CATEGORY="system-configs"
        BASE_DIR="$NIXOS_DIR/modules/system-configs"
        ;;
    4)
        CATEGORY="homelab"
        BASE_DIR="$NIXOS_DIR/modules/homelab"
        ;;
    5)
        CATEGORY="home"
        BASE_DIR="$NIXOS_DIR/home"
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        exit 1
        ;;
esac

# For apps, ask for subcategory
if [ "$CATEGORY" = "apps" ]; then
    echo -e "\n${GREEN}Select app subcategory:${NC}"
    echo "1) Productivity"
    echo "2) Development"
    echo "3) Media"
    echo "4) Gaming"
    echo "5) Communication"
    echo "6) Utilities"
    read -p "$(echo -e ${GREEN}Choice [1-6]:${NC} )" SUBCAT_CHOICE

    case $SUBCAT_CHOICE in
        1) SUBCATEGORY="productivity" ;;
        2) SUBCATEGORY="development" ;;
        3) SUBCATEGORY="media" ;;
        4) SUBCATEGORY="gaming" ;;
        5) SUBCATEGORY="communication" ;;
        6) SUBCATEGORY="utilities" ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac

    BASE_DIR="$BASE_DIR/$SUBCATEGORY"
fi

# Ask if creating new module or adding to existing
echo -e "\n${GREEN}Create new module or add to existing?${NC}"
echo "1) Create new module (recommended for complex packages with configuration)"
echo "2) Add to existing module (for simple packages)"
read -p "$(echo -e ${GREEN}Choice [1-2]:${NC} )" MODULE_CHOICE

if [ "$MODULE_CHOICE" = "1" ]; then
    # Create new module
    MODULE_FILE="$BASE_DIR/${PACKAGE_NAME}.nix"

    if [ -f "$MODULE_FILE" ]; then
        echo -e "${RED}Error: Module file already exists: $MODULE_FILE${NC}"
        exit 1
    fi

    # Ask about platform support
    echo -e "\n${GREEN}Platform support:${NC}"
    echo "1) Cross-platform (works on both Linux and macOS)"
    echo "2) Linux only"
    echo "3) macOS only"
    echo "4) Platform-specific packages (different on each)"
    read -p "$(echo -e ${GREEN}Choice [1-4]:${NC} )" PLATFORM_CHOICE

    # Generate module template using mkApp helper
    case $PLATFORM_CHOICE in
        1)
            # Cross-platform
            cat > "$MODULE_FILE" << 'EOF'
{ config, pkgs, lib, mkApp, ... }:

mkApp {
  name = "PACKAGE_NAME";
  optionPath = "OPTION_PATH";
  packages = pkgs: [ pkgs.PACKAGE_NAME ];
  description = "DESCRIPTION";
}
EOF
            ;;
        2)
            # Linux only
            cat > "$MODULE_FILE" << 'EOF'
{ config, pkgs, lib, mkApp, ... }:

mkApp {
  name = "PACKAGE_NAME";
  optionPath = "OPTION_PATH";
  linuxPackages = pkgs: [ pkgs.PACKAGE_NAME ];
  description = "DESCRIPTION (Linux only)";
}
EOF
            ;;
        3)
            # macOS only
            cat > "$MODULE_FILE" << 'EOF'
{ config, pkgs, lib, mkApp, ... }:

mkApp {
  name = "PACKAGE_NAME";
  optionPath = "OPTION_PATH";
  darwinPackages = pkgs: [ pkgs.PACKAGE_NAME ];
  description = "DESCRIPTION (macOS only)";
}
EOF
            ;;
        4)
            # Platform-specific
            cat > "$MODULE_FILE" << 'EOF'
{ config, pkgs, lib, mkApp, ... }:

mkApp {
  name = "PACKAGE_NAME";
  optionPath = "OPTION_PATH";
  linuxPackages = pkgs: [ pkgs.PACKAGE_NAME ];  # Adjust package name if different
  darwinPackages = pkgs: [ pkgs.PACKAGE_NAME ]; # Adjust package name if different
  description = "DESCRIPTION";
}
EOF
            ;;
    esac

    # Replace placeholders
    OPTION_PATH="${CATEGORY}.${SUBCATEGORY:+${SUBCATEGORY}.}${PACKAGE_NAME}"
    DESCRIPTION="${PACKAGE_NAME}"

    sed -i.bak "s/PACKAGE_NAME/${PACKAGE_NAME}/g" "$MODULE_FILE"
    sed -i.bak "s|OPTION_PATH|${OPTION_PATH}|g" "$MODULE_FILE"
    sed -i.bak "s/DESCRIPTION/${DESCRIPTION}/g" "$MODULE_FILE"
    rm "${MODULE_FILE}.bak"

    echo -e "\n${GREEN}✓ Created module: $MODULE_FILE${NC}"

    # Auto-add to default.nix imports
    DEFAULT_FILE="$BASE_DIR/default.nix"
    if [ -f "$DEFAULT_FILE" ]; then
        if ! grep -q "${PACKAGE_NAME}.nix" "$DEFAULT_FILE"; then
            echo -e "${YELLOW}Adding to imports in $DEFAULT_FILE...${NC}"

            # Add import after the last import line
            if grep -q "imports = \[" "$DEFAULT_FILE"; then
                # Find the imports section and add before the closing bracket
                sed -i.bak "/imports = \[/,/\];/ { /\];/i\\
    ./${PACKAGE_NAME}.nix
}" "$DEFAULT_FILE"
                rm "${DEFAULT_FILE}.bak"
                echo -e "${GREEN}✓ Added to imports${NC}"
            else
                echo -e "${YELLOW}Could not auto-add import. Please add manually:${NC}"
                echo -e "  imports = [ ./${PACKAGE_NAME}.nix ];"
            fi
        else
            echo -e "${GREEN}✓ Already in imports${NC}"
        fi
    fi

    echo -e "\n${BLUE}To enable this package, add to your host configuration:${NC}"
    echo -e "  ${CATEGORY}.${SUBCATEGORY:+${SUBCATEGORY}.}${PACKAGE_NAME}.enable = true;"

elif [ "$MODULE_CHOICE" = "2" ]; then
    # Add to existing module
    echo -e "\n${YELLOW}Please manually add '${PACKAGE_NAME}' to the appropriate systemPackages list${NC}"
    echo -e "${YELLOW}Common locations:${NC}"
    echo "  - $BASE_DIR/"
    echo "  - $NIXOS_DIR/hosts/jayne/configuration.nix (host-specific)"
else
    echo -e "${RED}Invalid choice${NC}"
    exit 1
fi

echo -e "\n${GREEN}=== Guidelines ===${NC}"
echo -e "${BLUE}Module placement:${NC}"
echo "  • modules/apps/ - Cross-platform applications (uses mkApp helper)"
echo "  • home/ - User-specific configs, dotfiles, per-user applications"
echo ""
echo -e "${BLUE}mkApp helper benefits:${NC}"
echo "  • Automatic platform detection (Linux/macOS)"
echo "  • Built-in assertions for platform-specific apps"
echo "  • Support for stable/unstable package mixing"
echo "  • Reduced boilerplate code"
echo ""
echo -e "${BLUE}When to use which:${NC}"
echo "  • Module: Requires system privileges, affects all users, system service"
echo "  • Home Manager: User preferences, dotfiles, CLI tools, user apps"
echo ""
echo -e "${GREEN}Done!${NC}"
