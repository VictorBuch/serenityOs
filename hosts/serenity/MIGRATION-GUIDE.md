# Serenity Baremetal Migration Guide

Migration from Proxmox VM with TrueNAS NFS to baremetal NixOS with mergerFS + SnapRAID.

## Storage Architecture Overview

**Hardware:**
- 4TB SSD (btrfs): NixOS root + `/cache` directory for mergerFS cache tier
- 3x12TB HDD (XFS): mergerFS data pool with SnapRAID parity
- 250GB SSD: Unused (reserved for future download staging)

**Storage Layout:**
```
/dev/sda (4TB SSD)
  └─ / (btrfs with /cache directory)

/dev/sdb (12TB HDD) → /mnt/disk1 (data)
/dev/sdc (12TB HDD) → /mnt/disk2 (data)
/dev/sdd (12TB HDD) → /mnt/parity1 (parity)

/mnt/cold (mergerFS: disk1 + disk2)
/mnt/pool (mergerFS: /cache + /mnt/cold)
```

**Result:**
- 24TB usable capacity (2 data + 1 parity)
- 1-disk failure protection
- SSD cache for hot data (7-day retention)
- Automatic tiering to HDDs

## Pre-Installation Checklist

- [ ] Backup SOPS age key from current system: `/home/ghost/.config/sops/age/keys.txt`
- [ ] Verify all secrets are in git: `secrets/secrets.yaml`
- [ ] Download NixOS 24.05 ISO (or latest stable)
- [ ] Have physical access to server hardware
- [ ] Ethernet cable connected (for network installation)

## Phase 1: Baremetal NixOS Installation

### 1. Boot NixOS Installer
Boot from USB/ISO and get to the installer prompt.

### 2. Partition and Format Drives

**4TB SSD (root filesystem with btrfs):**
```bash
# Create single partition
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart primary 1MiB 100%

# Format as btrfs with label
mkfs.btrfs -L nixos /dev/sda1

# Mount
mount /dev/disk/by-label/nixos /mnt
```

**12TB HDDs (data disks with XFS):**
```bash
# First data disk
parted /dev/sdb -- mklabel gpt
parted /dev/sdb -- mkpart primary 1MiB 100%
mkfs.xfs -L data01 /dev/sdb1

# Second data disk
parted /dev/sdc -- mklabel gpt
parted /dev/sdc -- mkpart primary 1MiB 100%
mkfs.xfs -L data02 /dev/sdc1

# Parity disk
parted /dev/sdd -- mklabel gpt
parted /dev/sdd -- mkpart primary 1MiB 100%
mkfs.xfs -L parity01 /dev/sdd1
```

**Verify labels:**
```bash
lsblk -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT
# Should show: nixos, data01, data02, parity01
```

### 3. Generate Base Configuration
```bash
nixos-generate-config --root /mnt
```

This creates:
- `/mnt/etc/nixos/configuration.nix`
- `/mnt/etc/nixos/hardware-configuration.nix` (auto-detected hardware)

### 4. Basic System Setup

**Minimal configuration for initial boot:**
```bash
# Edit /mnt/etc/nixos/configuration.nix
nano /mnt/etc/nixos/configuration.nix
```

Add minimal essentials:
```nix
{
  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Networking
  networking.hostName = "serenity";
  networking.networkmanager.enable = true;

  # Enable flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # SSH
  services.openssh.enable = true;

  # User
  users.users.ghost = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
  };

  system.stateVersion = "24.05";
}
```

### 5. Install NixOS
```bash
nixos-install
# Set root password when prompted

# Reboot
reboot
```

## Phase 2: Deploy Serenity Configuration

### 1. Initial System Access
Boot into the new system and login as ghost.

### 2. Clone Repository
```bash
# Install git if not already available
nix-shell -p git

# Clone your configuration
git clone https://github.com/VictorBuch/serenityOs.git ~/serenityOs
cd ~/serenityOs
```

### 3. Restore SOPS Key
```bash
mkdir -p ~/.config/sops/age
# Copy your backed up age key to:
#   ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

### 4. Update Hardware Configuration
```bash
# Copy the generated hardware-configuration.nix to repository
sudo cp /etc/nixos/hardware-configuration.nix ~/serenityOs/hosts/serenity/

# Verify it has btrfs root filesystem
cat ~/serenityOs/hosts/serenity/hardware-configuration.nix
```

### 5. Build Configuration
```bash
cd ~/serenityOs

# Check flake
nix flake check

# Build (don't switch yet)
sudo nixos-rebuild build --flake .#serenity
```

If build succeeds, review what will change:
```bash
nix store diff-closures /run/current-system ./result
```

### 6. Switch to New Configuration
```bash
sudo nixos-rebuild switch --flake .#serenity
```

This will:
- Mount HDDs at `/mnt/disk1`, `/mnt/disk2`, `/mnt/parity1`
- Create mergerFS pools at `/mnt/cold` and `/mnt/pool`
- Install mergerFS and snapraid
- Set up systemd services and timers
- Enable all configured homelab services

### 7. Create Cache Directory
```bash
sudo mkdir -p /cache
sudo chmod 755 /cache
```

## Phase 3: Initialize Storage

### 1. Verify Mounts
```bash
df -h
# Should show:
# - / (btrfs, 4TB)
# - /mnt/disk1, /mnt/disk2 (xfs, 12TB each)
# - /mnt/parity1 (xfs, 12TB)
# - /mnt/cold (mergerfs, ~24TB)
# - /mnt/pool (mergerfs, ~28TB with cache)

mount | grep mergerfs
# Should show cold and pool mounts
```

### 2. Test Write Access
```bash
# Test cache (SSD)
sudo touch /cache/test-cache
ls -la /cache/

# Test pool (should write to cache)
sudo touch /mnt/pool/test-pool
ls -la /mnt/pool/

# Verify file went to cache
ls -la /cache/
# Should show test-pool file

# Test cold pool (HDD only)
sudo touch /mnt/cold/test-cold
ls -la /mnt/cold/
```

### 3. Create Service Directories
```bash
# These will be created automatically by services, but can pre-create:
sudo mkdir -p /mnt/pool/media/{movies,tv,downloads}
sudo mkdir -p /mnt/pool/immich
sudo mkdir -p /mnt/pool/nextcloud
sudo mkdir -p /mnt/pool/backups/{postgres,mysql}

# Set permissions for your user
sudo chown -R ghost:users /mnt/pool
```

### 4. Initial SnapRAID Sync
```bash
# This will take several hours for first sync
sudo systemctl start snapraid-sync.service

# Monitor progress in another terminal
journalctl -u snapraid-sync.service -f
```

Wait for completion. First sync creates parity data for all existing files.

### 5. Verify SnapRAID Status
```bash
sudo snapraid status

# Should show:
# - No sync warnings
# - Parity is up to date
# - SMART status of all drives
```

## Phase 4: Service Validation

### 1. Check Systemd Services
```bash
# All Docker services should be running
systemctl list-units --type=service --state=running | grep docker

# Check storage-related services
systemctl status snapraid-sync.timer
systemctl status mergerfs-cache-mover.timer
systemctl status postgres-backup.timer
systemctl status mysql-backup.timer
```

### 2. Test Database Backups
```bash
# Manually trigger backups
sudo systemctl start postgres-backup.service
sudo systemctl start mysql-backup.service

# Verify backups created
ls -la /mnt/pool/backups/postgres/daily/
ls -la /mnt/pool/backups/mysql/daily/
```

### 3. Test Services
Access each service and verify functionality:
- **Immich**: http://192.168.0.243:2283
  - Upload a test photo
  - Verify it appears in `/mnt/pool/immich/photos`

- **Nextcloud**: https://nextcloud.victorbuch.com
  - Upload a test file
  - Verify in `/mnt/pool/nextcloud/data/`

- **Deluge**: http://192.168.0.243:8112
  - Check VPN connection (should show German IP)
  - Test download to `/mnt/pool/media/downloads`

### 4. Monitor Logs
```bash
# Watch for errors
journalctl -f
```

## Phase 5: Automation Verification

### 1. Verify Timer Schedule
```bash
systemctl list-timers

# Should show:
# - postgres-backup.timer (01:00 daily)
# - mysql-backup.timer (01:30 daily)
# - mergerfs-cache-mover.timer (02:00 daily)
# - snapraid-sync.timer (03:00 daily)
# - snapraid-scrub.timer (weekly)
```

### 2. Test Cache Mover (Optional)
```bash
# Fill cache with test data to trigger mover
# OR manually run:
sudo systemctl start mergerfs-cache-mover.service

# Check logs
journalctl -u mergerfs-cache-mover -n 100
```

### 3. Test Manual SnapRAID Operations
```bash
# Check array status
sudo snapraid status

# Check drive health
sudo snapraid smart

# Test diff (see what changed since last sync)
sudo snapraid diff

# Manual sync (if needed after large data addition)
sudo systemctl start snapraid-sync.service
```

## Daily Operations

### Adding Large Amounts of Data
After uploading 100GB+ of new content:
```bash
# Manually trigger sync to protect immediately
sudo systemctl start snapraid-sync.service
```

### Checking System Health
```bash
# Weekly check (automated, but can run manually)
sudo snapraid scrub

# Drive health
sudo snapraid smart

# Array status
sudo snapraid status
```

### Monitoring Cache Usage
```bash
df -h /cache
# If consistently above 80%, consider adjusting mover threshold in storage.nix
```

## Troubleshooting

### MergerFS Pool Not Mounting
```bash
# Check individual disk mounts first
mount | grep /mnt/disk

# Check mergerfs logs
journalctl -xe | grep mergerfs

# Try manual mount
sudo mount -t mergerfs -o defaults,allow_other /mnt/disk* /mnt/cold
```

### SnapRAID Sync Failing
```bash
# Check logs
journalctl -u snapraid-sync -n 200

# Common issues:
# - Disk full
# - Too many deletions (safety threshold)
# - SMART errors

# Check disk space
df -h /mnt/disk* /mnt/parity1

# Check SMART status
sudo snapraid smart
```

### Services Can't Write to Storage
```bash
# Check permissions
ls -la /mnt/pool/

# Fix ownership if needed
sudo chown -R ghost:users /mnt/pool/media
sudo chown -R nextcloud:nextcloud /mnt/pool/nextcloud
```

### Database Backups Not Running
```bash
# Check service status
systemctl status postgres-backup.service
systemctl status mysql-backup.service

# Check timer
systemctl list-timers | grep backup

# Manual run
sudo systemctl start postgres-backup.service
```

## Future Expansion

### Adding 4th Data Drive (→ 36TB usable)
```bash
# 1. Physically install drive
# 2. Partition and format
parted /dev/sdX -- mklabel gpt
parted /dev/sdX -- mkpart primary 1MiB 100%
mkfs.xfs -L data03 /dev/sdX1

# 3. Edit storage.nix, add:
fileSystems."/mnt/disk3" = {
  device = "/dev/disk/by-label/data03";
  fsType = "xfs";
  options = ["defaults" "noatime"];
};

# Update dataDisks in snapraid section:
dataDisks = {
  d1 = "/mnt/disk1/";
  d2 = "/mnt/disk2/";
  d3 = "/mnt/disk3/";  # New!
};

# 4. Rebuild
sudo nixos-rebuild switch --flake .#serenity

# 5. Run SnapRAID sync
sudo systemctl start snapraid-sync.service
```

### Adding 2nd Parity Disk (2-disk failure protection)
Similar process, add to `parityFiles` array and mount as `/mnt/parity2`.

### Adding 250GB SSD as Download Staging
Edit storage.nix to add mount for 250GB SSD, update deluge volumes.

## Configuration Files Changed

All changes are in git, commit and push:
```bash
git add modules/homelab/storage.nix
git add modules/homelab/database-backups.nix
git add modules/homelab/configs.nix
git add modules/homelab/default.nix
git add modules/homelab/oci-containers/deluge-vpn.nix
git add modules/homelab/services/nextcloud.nix
git add hosts/serenity/hardware-configuration.nix
git add hosts/serenity/MIGRATION-GUIDE.md

git commit -m "feat: migrate serenity to baremetal with mergerFS + SnapRAID"
git push
```

## Rollback Plan

If anything goes wrong during migration:
1. Boot back into Proxmox VM
2. TrueNAS data is untouched (nothing was deleted)
3. Revert git changes: `git reset --hard <commit-before-migration>`
4. Old VM configuration still works with NFS mounts

## Resources

- [SnapRAID Manual](https://www.snapraid.it/manual)
- [MergerFS Documentation](https://github.com/trapexit/mergerfs)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- Migration Obsidian Doc: `~/Documents/Obsidian/Jarvis/02 - Areas/Homelab/Migrating from TrueNAS ZFS to NixOS with mergerfs + SnapRAID.md`
