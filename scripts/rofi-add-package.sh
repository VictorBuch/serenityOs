#!/usr/bin/env nix-shell
#! nix-shell -i bash -p jq
# Enhanced rofi-integrated script to add new packages to NixOS configuration
# Uses rofi for all prompts with icons and detailed feedback

set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIXOS_DIR="$(dirname "$SCRIPT_DIR")"

# Rofi theme matching your config
ROFI_OPTS="-dmenu -i -p -width 60 -columns 2 -lines 10 -eh 2"

# Nerd font icons for visual feedback
ICON_SEARCH="󰍉"
ICON_PACKAGE="󰏖"
ICON_CATEGORY="󰉋"
ICON_FOLDER=""
ICON_CONFIG="⚙"
ICON_SUCCESS="󰄬"
ICON_ERROR="󰅙"
ICON_INFO="󰋼"
ICON_QUESTION=""

# Function to show rofi selection menu with icon
rofi_select() {
    local prompt="$1"
    local icon="$2"
    shift 2
    printf '%s\n' "$@" | rofi $ROFI_OPTS "$icon $prompt"
}

# Function to show rofi input with icon
rofi_input() {
    local prompt="$1"
    local icon="$2"
    rofi $ROFI_OPTS "$icon $prompt" -filter ""
}

# Function to show rofi message (non-blocking)
rofi_message() {
    local title="$1"
    local icon="$2"
    local message="$3"
    echo -e "$message" | rofi -dmenu -p "$icon $title" -mesg "$message" -no-custom -no-fixed-num-lines
}

# Function to send notification
notify() {
    local icon="$1"
    local message="$2"
    notify-send -u normal "$icon NixOS Package Manager" "$message"
}

# Step 1: Ask for package name
notify "$ICON_SEARCH" "Starting package search..."
PACKAGE_NAME=$(rofi_input "Search package" "$ICON_SEARCH")

if [ -z "$PACKAGE_NAME" ]; then
    notify "$ICON_ERROR" "Package name cannot be empty"
    exit 1
fi

# Step 2: Search for package and show results
notify "$ICON_SEARCH" "Searching for '$PACKAGE_NAME' in nixpkgs..."

# Search using JSON output for reliable parsing
SEARCH_RESULTS=$(nix search nixpkgs "$PACKAGE_NAME" --json 2>/dev/null)

if [ "$SEARCH_RESULTS" = "{}" ]; then
    # No results found - offer to continue anyway or search again
    CHOICE=$(rofi_select "Package not found. What to do?" "$ICON_QUESTION" \
        "󰑓 Search again" \
        "󰐊 Continue anyway" \
        "󰜺 Cancel")

    case "$CHOICE" in
        "󰑓 Search again")
            exec "$0"  # Restart script
            ;;
        "󰐊 Continue anyway")
            notify "$ICON_INFO" "Continuing with package: $PACKAGE_NAME"
            ;;
        *)
            exit 0
            ;;
    esac
else
    # Format search results with jq: "package (version) | description"
    FORMATTED_RESULTS=$(echo "$SEARCH_RESULTS" | jq -r 'to_entries[] |
        (.key | split(".") | last) as $pkg_name |
        (.value.description |
            if length > 150 then .[0:147] + "..." else . end) as $desc |
        "\($pkg_name) (\(.value.version)) | \($desc)"' | head -15)

    # Show results and let user select
    SELECTED=$(echo "$FORMATTED_RESULTS" | rofi $ROFI_OPTS "$ICON_PACKAGE Select package" -format "s" -no-custom)

    if [ -n "$SELECTED" ]; then
        # Extract package name (before the pipe and version)
        PACKAGE_NAME=$(echo "$SELECTED" | awk -F' \\| ' '{print $1}' | awk '{print $1}')
        notify "$ICON_SUCCESS" "Selected: $PACKAGE_NAME"
    fi
fi

# Step 3: Ask for category with icons
CATEGORY_DISPLAY=$(rofi_select "Select category" "$ICON_CATEGORY" \
    "󰀻 Apps - Desktop/CLI applications" \
    "󰨇 Desktop Environment - WM/DE components" \
    "⚙ System - System-level services/tools" \
    " Homelab - Server services" \
    " Home Manager - User-specific config")

case "$CATEGORY_DISPLAY" in
    "󰀻 Apps"*)
        CATEGORY="apps"
        BASE_DIR="$NIXOS_DIR/modules/apps"
        NEEDS_SUBCAT=true
        ;;
    "󰨇 Desktop"*)
        CATEGORY="desktop-environments"
        BASE_DIR="$NIXOS_DIR/modules/nixos/desktop-environments"
        NEEDS_SUBCAT=false
        ;;
    "⚙ System"*)
        CATEGORY="system-configs"
        BASE_DIR="$NIXOS_DIR/modules/system-configs"
        NEEDS_SUBCAT=false
        ;;
    " Homelab"*)
        CATEGORY="homelab"
        BASE_DIR="$NIXOS_DIR/modules/homelab"
        NEEDS_SUBCAT=false
        ;;
    " Home Manager"*)
        CATEGORY="home"
        BASE_DIR="$NIXOS_DIR/home"
        NEEDS_SUBCAT=false
        ;;
    *)
        notify "$ICON_ERROR" "Invalid category selected"
        exit 1
        ;;
esac

# Step 4: For apps, ask for subcategory with icons
if [ "$NEEDS_SUBCAT" = true ]; then
    SUBCAT_DISPLAY=$(rofi_select "App subcategory" "$ICON_FOLDER" \
        "󰈙 Productivity" \
        "󰅨 Development" \
        "󰝚 Media" \
        "󰊗 Gaming" \
        "󰻞 Communication" \
        "󰒓 Utilities")

    SUBCATEGORY=$(echo "$SUBCAT_DISPLAY" | sed 's/^[^ ]* //' | tr '[:upper:]' '[:lower:]')
    BASE_DIR="$BASE_DIR/$SUBCATEGORY"
fi

# Step 5: Ask if creating new module or adding to existing
MODULE_TYPE=$(rofi_select "Module type" "$ICON_CONFIG" \
    "󰝒 Create new module (complex packages)" \
    "󰐕 Add to existing module (simple packages)")

if [[ "$MODULE_TYPE" == "󰝒 Create new module"* ]]; then
    # Create new module
    MODULE_FILE="$BASE_DIR/${PACKAGE_NAME}.nix"

    if [ -f "$MODULE_FILE" ]; then
        notify "$ICON_ERROR" "Module file already exists:\n$MODULE_FILE"
        exit 1
    fi

    # Generate module template
    cat > "$MODULE_FILE" << EOF
{ config, pkgs, lib, ... }: {

  options = {
    ${CATEGORY}.${SUBCATEGORY:+${SUBCATEGORY}.}${PACKAGE_NAME}.enable = lib.mkEnableOption "Enables ${PACKAGE_NAME}";
  };

  config = lib.mkIf config.${CATEGORY}.${SUBCATEGORY:+${SUBCATEGORY}.}${PACKAGE_NAME}.enable {
    environment.systemPackages = with pkgs; [
      ${PACKAGE_NAME}
    ];
  };
}
EOF

    # Copy enable line to clipboard
    ENABLE_LINE="${CATEGORY}.${SUBCATEGORY:+${SUBCATEGORY}.}${PACKAGE_NAME}.enable = true;"
    echo "$ENABLE_LINE" | wl-copy

    # Check if module needs to be added to default.nix
    DEFAULT_FILE="$BASE_DIR/default.nix"
    IMPORT_REMINDER=""
    if [ -f "$DEFAULT_FILE" ]; then
        if ! grep -q "${PACKAGE_NAME}.nix" "$DEFAULT_FILE"; then
            IMPORT_REMINDER="\n\n$ICON_INFO Remember to add:\n  ./${PACKAGE_NAME}.nix\nto imports in:\n  $DEFAULT_FILE"
        fi
    fi

    notify "$ICON_SUCCESS" "Module created successfully!\n\n$ICON_FOLDER Location:\n  $MODULE_FILE\n\n$ICON_CONFIG Enable with:\n  $ENABLE_LINE\n\n(Enable line copied to clipboard!)$IMPORT_REMINDER"

else
    # Show instructions for manual editing
    notify "$ICON_INFO" "Manual configuration needed:\n\nAdd '$PACKAGE_NAME' to systemPackages in:\n  $BASE_DIR/\n\nLocation copied to clipboard!"
    echo "$BASE_DIR/" | wl-copy
fi
