#!/usr/bin/env bash

# Serenity-specific NixOS installation script with storage setup
# Handles the baremetal migration with mergerFS + SnapRAID configuration
#
# Usage:
#   ./install-serenity.sh           # Interactive mode
#   ./install-serenity.sh --auto    # Automatic mode (skip partitioning)

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HOSTNAME="serenity"
REPO_DIR="$HOME/serenityOs"
REQUIRED_LABELS=("nixos" "data01" "data02" "parity01")

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

# Check if running on NixOS
check_nixos() {
    if [ ! -f /etc/NIXOS ]; then
        print_error "This script must be run on NixOS"
        exit 1
    fi
}

# Find device by label
find_device_by_label() {
    local label=$1
    local device=$(ls -1 /dev/disk/by-label/ 2>/dev/null | grep "^${label}$" || true)

    if [ -n "$device" ]; then
        readlink -f "/dev/disk/by-label/$device"
    else
        echo ""
    fi
}

# Check filesystem type
check_fstype() {
    local device=$1
    lsblk -no FSTYPE "$device" 2>/dev/null || echo ""
}

# Validate storage configuration
validate_storage() {
    print_header "Storage Validation"

    local all_found=true
    local storage_info=()

    for label in "${REQUIRED_LABELS[@]}"; do
        local device=$(find_device_by_label "$label")

        if [ -z "$device" ]; then
            print_error "Label '$label' not found"
            all_found=false
        else
            local fstype=$(check_fstype "$device")
            local size=$(lsblk -no SIZE "$device" 2>/dev/null || echo "unknown")

            # Validate filesystem type
            local expected_fs=""
            case "$label" in
                "nixos")
                    expected_fs="btrfs"
                    ;;
                "data01"|"data02"|"parity01")
                    expected_fs="xfs"
                    ;;
            esac

            if [ "$fstype" != "$expected_fs" ]; then
                print_error "Label '$label' has wrong filesystem: $fstype (expected $expected_fs)"
                all_found=false
            else
                print_success "Found: $label → $device ($fstype, $size)"
            fi

            storage_info+=("$label|$device|$fstype|$size")
        fi
    done

    echo "" >&2

    if [ "$all_found" = false ]; then
        print_error "Storage validation failed!"
        echo "" >&2
        print_info "Required drive labels:"
        echo "  • nixos     - 4TB SSD with btrfs (root filesystem)" >&2
        echo "  • data01    - 12TB HDD with xfs (data disk 1)" >&2
        echo "  • data02    - 12TB HDD with xfs (data disk 2)" >&2
        echo "  • parity01  - 12TB HDD with xfs (parity disk)" >&2
        echo "" >&2
        print_info "See MIGRATION-GUIDE.md for partitioning instructions"
        return 1
    fi

    print_success "All storage labels validated!"
    return 0
}

# Show current disk layout
show_disk_layout() {
    print_header "Current Disk Layout"

    echo "Available disks:" >&2
    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT | grep -E "^(NAME|sd|nvme)" >&2
    echo "" >&2
}

# Interactive storage setup guidance
guide_storage_setup() {
    print_header "Storage Setup Guidance"

    print_warning "Storage not properly configured. Would you like guidance?"
    echo "" >&2

    echo "You need to:" >&2
    echo "  1. Partition all drives (GPT partition table)" >&2
    echo "  2. Format with correct filesystems:" >&2
    echo "     • 4TB SSD → btrfs (label: nixos)" >&2
    echo "     • 3x12TB HDD → xfs (labels: data01, data02, parity01)" >&2
    echo "" >&2

    print_info "Example commands:"
    echo "" >&2
    echo "# For 4TB SSD (root):" >&2
    echo "parted /dev/sda -- mklabel gpt" >&2
    echo "parted /dev/sda -- mkpart primary 1MiB 100%" >&2
    echo "mkfs.btrfs -L nixos /dev/sda1" >&2
    echo "" >&2
    echo "# For 12TB HDD (data01):" >&2
    echo "parted /dev/sdb -- mklabel gpt" >&2
    echo "parted /dev/sdb -- mkpart primary 1MiB 100%" >&2
    echo "mkfs.xfs -L data01 /dev/sdb1" >&2
    echo "" >&2
    echo "# Repeat for data02 (sdc) and parity01 (sdd)" >&2
    echo "" >&2

    print_info "For full instructions, see: hosts/serenity/MIGRATION-GUIDE.md"
    echo "" >&2

    read -p "Press Enter to exit and set up storage, or Ctrl+C to cancel..." >&2
    exit 1
}

# Check if system is already installed
check_existing_install() {
    if [ -d "$REPO_DIR" ]; then
        print_info "Found existing repository at $REPO_DIR"
        return 0
    fi
    return 1
}

# Create cache directory
setup_cache_dir() {
    print_header "Cache Directory Setup"

    if [ -d "/cache" ]; then
        print_success "Cache directory already exists"
    else
        print_info "Creating /cache directory..."
        mkdir -p /cache
        chmod 755 /cache
        print_success "Cache directory created"
    fi
}

# Run base installation
run_base_install() {
    print_header "Running Base Installation"

    local install_script="$REPO_DIR/install.sh"

    if [ ! -f "$install_script" ]; then
        # Repository doesn't exist yet, need to get it first
        print_info "Repository not found, will be cloned by install.sh"
    fi

    # Check if install.sh exists in current directory
    if [ -f "./install.sh" ]; then
        print_info "Running ./install.sh $HOSTNAME"
        bash ./install.sh "$HOSTNAME"
    else
        print_error "install.sh not found in current directory"
        print_info "Please ensure install.sh is available or repository is cloned"
        return 1
    fi
}

# Post-installation storage initialization
post_install_storage() {
    print_header "Post-Installation Storage Setup"

    # Verify mounts
    print_info "Verifying storage mounts..."

    local expected_mounts=("/mnt/disk1" "/mnt/disk2" "/mnt/parity1" "/mnt/cold" "/mnt/pool")
    local all_mounted=true

    for mount in "${expected_mounts[@]}"; do
        if mountpoint -q "$mount" 2>/dev/null; then
            print_success "Mounted: $mount"
        else
            print_warning "Not mounted: $mount"
            all_mounted=false
        fi
    done

    if [ "$all_mounted" = false ]; then
        print_warning "Some mounts are missing. This is normal on first boot."
        print_info "Rebooting is recommended to ensure all mounts are active."
        echo "" >&2
        read -p "Reboot now? [Y/n] " -n 1 -r >&2
        echo >&2
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            print_info "Rebooting..."
            reboot
            exit 0
        fi
        return 0
    fi

    # Create initial directory structure
    print_info "Creating directory structure on mergerFS pool..."

    mkdir -p /mnt/pool/media/{movies,tv,downloads}
    mkdir -p /mnt/pool/immich
    mkdir -p /mnt/pool/nextcloud
    mkdir -p /mnt/pool/backups/{postgres,mysql}

    # Set ownership
    local username=$(whoami)
    chown -R ${username}:users /mnt/pool/ 2>/dev/null || true

    print_success "Directory structure created"

    # Initial SnapRAID sync
    print_header "Initial SnapRAID Sync"

    print_warning "This will perform the first SnapRAID parity calculation."
    print_info "This can take several hours depending on data size."
    echo "" >&2

    read -p "Start initial SnapRAID sync now? [Y/n] " -n 1 -r >&2
    echo >&2

    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        print_info "Starting SnapRAID sync (this will take a while)..."
        print_info "You can monitor progress in another terminal with:"
        echo "  journalctl -u snapraid-sync.service -f" >&2
        echo "" >&2

        systemctl start snapraid-sync.service

        print_info "Waiting for sync to complete..."
        while systemctl is-active --quiet snapraid-sync.service; do
            sleep 10
        done

        if systemctl is-failed --quiet snapraid-sync.service; then
            print_error "SnapRAID sync failed!"
            print_info "Check logs: journalctl -u snapraid-sync.service"
            return 1
        else
            print_success "Initial SnapRAID sync completed!"
        fi
    else
        print_info "Skipped initial sync. Run manually later with:"
        echo "  sudo systemctl start snapraid-sync.service" >&2
    fi
}

# Verify installation
verify_installation() {
    print_header "Installation Verification"

    # Check services
    print_info "Checking systemd services..."

    local services=(
        "snapraid-sync.timer"
        "mergerfs-cache-mover.timer"
        "postgres-backup.timer"
        "mysql-backup.timer"
    )

    for service in "${services[@]}"; do
        if systemctl is-enabled --quiet "$service" 2>/dev/null; then
            print_success "Enabled: $service"
        else
            print_warning "Not enabled: $service"
        fi
    done

    echo "" >&2

    # Check storage
    print_info "Storage summary:"
    df -h / /cache /mnt/disk1 /mnt/disk2 /mnt/parity1 /mnt/pool 2>/dev/null | grep -v "^Filesystem" >&2

    echo "" >&2
    print_success "Installation verification complete!"
}

# Show next steps
show_next_steps() {
    print_header "Installation Complete! 🎉"

    print_success "Serenity has been configured with mergerFS + SnapRAID storage"
    echo "" >&2

    print_info "Storage Architecture:"
    echo "  • Root:  / (4TB SSD, btrfs)" >&2
    echo "  • Cache: /cache → /mnt/pool (SSD tier)" >&2
    echo "  • Pool:  /mnt/pool (24TB usable, 1-parity)" >&2
    echo "" >&2

    print_info "Useful Commands:"
    echo "  • Check SnapRAID:  sudo snapraid status" >&2
    echo "  • Check drives:    sudo snapraid smart" >&2
    echo "  • Manual sync:     sudo systemctl start snapraid-sync.service" >&2
    echo "  • View timers:     systemctl list-timers" >&2
    echo "  • Storage usage:   df -h /mnt/pool" >&2
    echo "" >&2

    print_info "Automatic Maintenance:"
    echo "  • Database backups: 01:00 & 01:30 daily" >&2
    echo "  • Cache mover:      02:00 daily" >&2
    echo "  • SnapRAID sync:    03:00 daily" >&2
    echo "  • SnapRAID scrub:   Weekly" >&2
    echo "" >&2

    print_info "Documentation:"
    echo "  • Migration guide: $REPO_DIR/hosts/serenity/MIGRATION-GUIDE.md" >&2
    echo "  • Storage config:  $REPO_DIR/modules/homelab/storage.nix" >&2
    echo "" >&2

    if ! mountpoint -q /mnt/pool 2>/dev/null; then
        print_warning "Reboot recommended to ensure all storage mounts are active"
        echo "" >&2
        read -p "Reboot now? [Y/n] " -n 1 -r >&2
        echo >&2
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            print_info "Rebooting..."
            reboot
        fi
    fi
}

# Main installation flow
main() {
    local auto_mode=false

    if [ "${1:-}" = "--auto" ]; then
        auto_mode=true
    fi

    print_header "Serenity Storage Installation"
    print_info "NixOS baremetal with mergerFS + SnapRAID"
    echo "" >&2

    # Check prerequisites
    check_nixos

    # Show current disk layout
    if [ "$auto_mode" = false ]; then
        show_disk_layout
    fi

    # Validate storage configuration
    if ! validate_storage; then
        if [ "$auto_mode" = true ]; then
            print_error "Storage not configured (auto mode)"
            exit 1
        else
            guide_storage_setup
            exit 1
        fi
    fi

    # Setup cache directory early
    setup_cache_dir

    # Check if already installed
    if check_existing_install && [ "$auto_mode" = false ]; then
        print_warning "Serenity appears to be already installed"
        read -p "Re-run installation? [y/N] " -n 1 -r >&2
        echo >&2
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Exiting without changes"
            exit 0
        fi
    fi

    # Run base installation
    run_base_install

    # Post-installation storage setup
    post_install_storage

    # Verify installation
    verify_installation

    # Show next steps
    show_next_steps
}

# Run main function
main "$@"
