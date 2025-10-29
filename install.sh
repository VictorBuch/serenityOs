#!/usr/bin/env bash

# Universal NixOS/nix-darwin installation script
# Usage: ./install.sh [hostname]
#   or: curl -sSL https://raw.githubusercontent.com/VictorBuch/serenityOs/main/install.sh | bash -s -- [hostname]

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="git@github.com:VictorBuch/serenityOs.git"
INSTALL_DIR="$HOME/serenityOs"
SSH_KEY="$HOME/.ssh/id_ed25519"
EMAIL="victorbuch@protonmail.com"

# Available hosts
NIXOS_HOSTS=("jayne" "kaylee" "serenity" "shepherd" "shepherd-arm")
DARWIN_HOSTS=("inara")

# Helper functions
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1" >&2
}

print_success() {
    echo -e "${GREEN}✓${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1" >&2
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_header() {
    echo "" >&2
    echo -e "${BLUE}═══════════════════════════════════════${NC}" >&2
    echo -e "${BLUE}  $1${NC}" >&2
    echo -e "${BLUE}═══════════════════════════════════════${NC}" >&2
    echo "" >&2
}

# Detect platform
detect_platform() {
    if [ -f /etc/NIXOS ]; then
        echo "nixos"
    elif [ "$(uname)" = "Darwin" ]; then
        echo "darwin"
    else
        print_error "Unsupported platform. This script only works on NixOS or macOS."
        exit 1
    fi
}

# Map hostname to host directory (strips -arm suffix for architecture variants)
get_host_dir() {
    local hostname=$1
    echo "${hostname%-arm}"  # Remove -arm suffix if present
}

# Check if hostname is valid
is_valid_host() {
    local host=$1
    local platform=$2

    if [ "$platform" = "nixos" ]; then
        for valid in "${NIXOS_HOSTS[@]}"; do
            [ "$host" = "$valid" ] && return 0
        done
    else
        for valid in "${DARWIN_HOSTS[@]}"; do
            [ "$host" = "$valid" ] && return 0
        done
    fi
    return 1
}

# Show available hosts
show_hosts() {
    local platform=$1
    echo "" >&2
    if [ "$platform" = "nixos" ]; then
        print_info "Available NixOS hosts:"
        echo "  • jayne        - Primary desktop (Hyprland, full desktop environment)" >&2
        echo "  • kaylee       - Lightweight desktop configuration" >&2
        echo "  • serenity     - Homelab server (services, static IP)" >&2
        echo "  • shepherd     - Base configuration template (x86_64)" >&2
        echo "  • shepherd-arm - Base configuration template (ARM/aarch64)" >&2
    else
        print_info "Available macOS hosts:"
        echo "  • inara     - macOS system with nix-darwin" >&2
    fi
    echo "" >&2
}

# Interactive host selection
select_host() {
    local platform=$1
    local hosts

    if [ "$platform" = "nixos" ]; then
        hosts=("${NIXOS_HOSTS[@]}")
    else
        hosts=("${DARWIN_HOSTS[@]}")
    fi

    echo "" >&2
    print_info "Select a host configuration:"
    select host in "${hosts[@]}"; do
        if [ -n "$host" ]; then
            echo "$host"  # Only this goes to stdout
            return 0
        else
            print_warning "Invalid selection. Please try again."
        fi
    done
}

# Check prerequisites
check_prerequisites() {
    local platform=$1

    print_info "Checking prerequisites..."

    # Check if nix is installed
    if ! command -v nix &> /dev/null; then
        print_error "Nix is not installed. Please install Nix first:"
        if [ "$platform" = "nixos" ]; then
            echo "  Visit: https://nixos.org/download.html"
        else
            echo "  Run: curl -L https://nixos.org/nix/install | sh"
        fi
        exit 1
    fi

    # Check if git is available (might need to be installed via nix-shell)
    if ! command -v git &> /dev/null && ! nix-shell -p git --run "git --version" &> /dev/null; then
        print_error "Git is not available. Cannot proceed."
        exit 1
    fi

    # Check internet connectivity
    if ! ping -c 1 github.com &> /dev/null; then
        print_warning "Cannot reach github.com. Check your internet connection."
        read -p "Continue anyway? [y/N] " -n 1 -r >&2
        echo >&2
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    print_success "Prerequisites check passed"
}

# Setup SSH key
setup_ssh() {
    print_header "SSH Key Setup"

    if [ -f "$SSH_KEY" ]; then
        print_success "SSH key already exists at $SSH_KEY"
        cat "$SSH_KEY.pub" >&2
        echo "" >&2
        read -p "Use existing key? [Y/n] " -n 1 -r >&2
        echo >&2
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            print_info "Generating new SSH key..."
            rm -f "$SSH_KEY" "$SSH_KEY.pub"
            ssh-keygen -t ed25519 -C "$EMAIL" -N "" -f "$SSH_KEY"
            print_success "New SSH key generated"
        fi
    else
        print_info "Generating SSH key..."
        mkdir -p "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$EMAIL" -N "" -f "$SSH_KEY"
        print_success "SSH key generated"
    fi

    # Start SSH agent and add key
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add "$SSH_KEY" 2>/dev/null || true

    # Display public key
    echo "" >&2
    print_info "Your public SSH key:"
    echo -e "${GREEN}$(cat "$SSH_KEY.pub")${NC}" >&2
    echo "" >&2
    print_warning "Add this key to GitHub: https://github.com/settings/ssh/new"
    echo "" >&2
    read -p "Press Enter once you've added the key to GitHub..." -r >&2
}

# Clone repository
clone_repo() {
    print_header "Repository Setup"

    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Directory $INSTALL_DIR already exists."
        read -p "Remove and re-clone? [y/N] " -n 1 -r >&2
        echo >&2
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$INSTALL_DIR"
        else
            print_info "Using existing directory"
            cd "$INSTALL_DIR"
            return 0
        fi
    fi

    print_info "Cloning repository..."

    # Use nix-shell to ensure git is available
    if command -v git &> /dev/null; then
        git clone "$REPO_URL" "$INSTALL_DIR"
    else
        nix-shell -p git --run "git clone $REPO_URL $INSTALL_DIR"
    fi

    cd "$INSTALL_DIR"
    print_success "Repository cloned to $INSTALL_DIR"
}

# Setup hardware configuration (NixOS only)
setup_hardware_config() {
    local hostname=$1
    local host_dir=$(get_host_dir "$hostname")

    print_header "Hardware Configuration"

    local hw_config_src="/etc/nixos/hardware-configuration.nix"
    local hw_config_dst="$INSTALL_DIR/hosts/$host_dir/hardware-configuration.nix"

    if [ ! -f "$hw_config_src" ]; then
        print_warning "Hardware configuration not found at $hw_config_src"
        print_info "You may need to generate it with: nixos-generate-config"
        read -p "Continue anyway? [y/N] " -n 1 -r >&2
        echo >&2
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
        return
    fi

    print_info "Copying hardware configuration..."
    sudo rm -f "$hw_config_dst"
    sudo cp "$hw_config_src" "$hw_config_dst"

    # Stage the hardware config if inside git repo
    if [ -d "$INSTALL_DIR/.git" ]; then
        git add "$hw_config_dst" 2>/dev/null || true
    fi

    print_success "Hardware configuration updated"
}

# Extract username from host configuration
get_username() {
    local hostname=$1
    local host_dir=$(get_host_dir "$hostname")
    local config_file="$INSTALL_DIR/hosts/$host_dir/configuration.nix"

    if [ ! -f "$config_file" ]; then
        echo ""
        return 1
    fi

    # Try to extract username from 'let username = "xxx";' pattern
    local username=$(grep -E '^\s*username\s*=\s*"[^"]+";' "$config_file" | sed -E 's/.*"\s*([^"]+)\s*".*/\1/' | head -1)

    if [ -n "$username" ]; then
        echo "$username"
        return 0
    fi

    # Fallback: try to extract from user.userName = xxx;
    username=$(grep -E 'user\.userName\s*=\s*[a-zA-Z_][a-zA-Z0-9_]*;' "$config_file" | sed -E 's/.*=\s*([a-zA-Z_][a-zA-Z0-9_]*);.*/\1/' | head -1)

    if [ -n "$username" ]; then
        # This gives us the variable name, now we need to find its value
        local var_name="$username"
        username=$(grep -E "^\s*${var_name}\s*=\s*\"[^\"]+\";" "$config_file" | sed -E 's/.*"\s*([^"]+)\s*".*/\1/' | head -1)
    fi

    if [ -n "$username" ]; then
        echo "$username"
        return 0
    fi

    echo ""
    return 1
}

# Setup user password (NixOS only)
setup_user_password() {
    local hostname=$1

    print_header "User Password Setup"

    # Extract username from configuration
    local username=$(get_username "$hostname")

    if [ -z "$username" ]; then
        print_warning "Could not detect username from configuration"
        read -p "Enter the username to set password for: " username >&2
        if [ -z "$username" ]; then
            print_error "No username provided. You'll need to set password manually later."
            print_info "To set password: sudo passwd <username>"
            return 1
        fi
    fi

    print_info "Setting password for user: $username"
    echo "" >&2

    # Set password using passwd command
    if sudo passwd "$username"; then
        print_success "Password set successfully for $username"
    else
        print_error "Failed to set password"
        print_warning "You can set it manually later with: sudo passwd $username"
        return 1
    fi
}

# Build and switch configuration
build_system() {
    local platform=$1
    local hostname=$2

    print_header "Building System Configuration"

    cd "$INSTALL_DIR"

    print_info "This will take several minutes on first build..."
    echo "" >&2

    if [ "$platform" = "nixos" ]; then
        print_info "Running: sudo nixos-rebuild switch --flake .#$hostname"
        echo "" >&2
        sudo nixos-rebuild switch --flake ".#$hostname"
    else
        print_info "Running: darwin-rebuild switch --flake .#$hostname"
        echo "" >&2
        darwin-rebuild switch --flake ".#$hostname"
    fi

    print_success "System configuration applied!"
}

# Main installation flow
main() {
    local hostname=${1:-}

    print_header "NixOS/nix-darwin Configuration Installer"

    # Detect platform
    PLATFORM=$(detect_platform)
    print_info "Detected platform: $PLATFORM"

    # Get hostname
    if [ -z "$hostname" ]; then
        show_hosts "$PLATFORM"
        hostname=$(select_host "$PLATFORM")
    else
        if ! is_valid_host "$hostname" "$PLATFORM"; then
            print_error "Invalid hostname: $hostname"
            show_hosts "$PLATFORM"
            exit 1
        fi
    fi

    print_success "Installing configuration: $hostname"

    # Run installation steps
    check_prerequisites "$PLATFORM"
    setup_ssh
    clone_repo

    if [ "$PLATFORM" = "nixos" ]; then
        setup_hardware_config "$hostname"
    fi

    build_system "$PLATFORM" "$hostname"

    # Setup user password (NixOS only)
    if [ "$PLATFORM" = "nixos" ]; then
        setup_user_password "$hostname"
    fi

    # Success message
    print_header "Installation Complete! 🎉"
    print_success "Your system has been configured with the $hostname profile"

    if [ "$PLATFORM" = "nixos" ]; then
        print_info "You may need to reboot for all changes to take effect"
    else
        print_info "You may need to restart applications for all changes to take effect"
    fi

    echo "" >&2
    print_info "Configuration directory: $INSTALL_DIR"
    print_info "To update: cd $INSTALL_DIR && git pull && sudo nixos-rebuild switch --flake .#$hostname"
    echo "" >&2
}

# Run main function with arguments
main "$@"
