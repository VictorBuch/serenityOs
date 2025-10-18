#!/usr/bin/env bash

# macOS-specific nix-darwin installation script
# Usage: ./install-darwin.sh [hostname]
#   or: curl -sSL https://raw.githubusercontent.com/VictorBuch/serenityOs/main/install-darwin.sh | bash -s -- [hostname]

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
DEFAULT_HOST="inara"

# Helper functions
print_info() {
    echo -e "${BLUE}ℹ ${NC}$1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════${NC}"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    # Verify we're on macOS
    if [ "$(uname)" != "Darwin" ]; then
        print_error "This script is for macOS only. Use install.sh for other platforms."
        exit 1
    fi

    # Check if nix is installed
    if ! command -v nix &> /dev/null; then
        print_error "Nix is not installed. Installing Nix..."
        echo ""
        print_info "Running the official Nix installer..."
        curl -L https://nixos.org/nix/install | sh

        # Source nix
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi

        print_success "Nix installed successfully"
    fi

    # Check if git is available
    if ! command -v git &> /dev/null && ! nix-shell -p git --run "git --version" &> /dev/null; then
        print_error "Git is not available. Cannot proceed."
        exit 1
    fi

    # Check internet connectivity
    if ! ping -c 1 github.com &> /dev/null; then
        print_warning "Cannot reach github.com. Check your internet connection."
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
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
        cat "$SSH_KEY.pub"
        echo ""
        read -p "Use existing key? [Y/n] " -n 1 -r
        echo
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
    echo ""
    print_info "Your public SSH key:"
    echo -e "${GREEN}$(cat "$SSH_KEY.pub")${NC}"
    echo ""
    print_warning "Add this key to GitHub: https://github.com/settings/ssh/new"
    echo ""
    read -p "Press Enter once you've added the key to GitHub..." -r
}

# Clone repository
clone_repo() {
    print_header "Repository Setup"

    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Directory $INSTALL_DIR already exists."
        read -p "Remove and re-clone? [y/N] " -n 1 -r
        echo
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

# Build and switch configuration
build_system() {
    local hostname=$1

    print_header "Building macOS Configuration"

    cd "$INSTALL_DIR"

    print_info "This will take several minutes on first build..."
    echo ""
    print_info "Running: darwin-rebuild switch --flake .#$hostname"
    echo ""

    # Check if darwin-rebuild exists, if not, bootstrap it
    if ! command -v darwin-rebuild &> /dev/null; then
        print_warning "darwin-rebuild not found. Bootstrapping nix-darwin..."
        nix run nix-darwin -- switch --flake ".#$hostname"
    else
        darwin-rebuild switch --flake ".#$hostname"
    fi

    print_success "System configuration applied!"
}

# Main installation flow
main() {
    local hostname=${1:-$DEFAULT_HOST}

    print_header "macOS nix-darwin Configuration Installer"

    print_info "Target host: $hostname"

    # Run installation steps
    check_prerequisites
    setup_ssh
    clone_repo
    build_system "$hostname"

    # Success message
    print_header "Installation Complete! 🎉"
    print_success "Your macOS system has been configured with the $hostname profile"
    print_info "You may need to restart applications for all changes to take effect"

    echo ""
    print_info "Configuration directory: $INSTALL_DIR"
    print_info "To update: cd $INSTALL_DIR && git pull && darwin-rebuild switch --flake .#$hostname"
    echo ""
    print_info "Note: Some macOS settings may require logging out and back in"
    echo ""
}

# Run main function with arguments
main "$@"
