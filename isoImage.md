# Shepherd ISO Image - Implementation Plan

## Problem Statement

The current custom shepherd ISO configurations exist but don't provide significant value over the official NixOS ISO because:

- They don't include automated partitioning
- They don't include an installation wizard
- They still require manual disk setup and installation
- They're just "live testing environments" with your config pre-loaded

**Key Question:** Why build a custom ISO if you still have to manually partition and install?

## The Better Approach: Bootable Installer ISO

Transform the shepherd ISO into a true **bootable installer** that automates the entire installation process.

### Core Concept

1. **Clone via HTTPS** (no SSH key needed during installation)
2. **Automated partitioning** (using disko)
3. **One-command installation**
4. **Post-install SSH setup** (after first boot, for future updates)

### Installation Flow

```
Boot Shepherd ISO
    ↓
Run: sudo shepherd-install
    ↓
[Automated partitioning via disko]
    ↓
[Clone repo via HTTPS]
    ↓
[NixOS installation]
    ↓
Reboot into installed system
    ↓
Run: postInstall.sh
    ↓
[Generate SSH key, switch to git@github.com remote]
    ↓
Done! System ready for updates via git pull + nixos-rebuild
```

## Proposed Architecture

### 1. Split Installation Scripts

#### install.sh (HTTPS-based, for initial installation)
```bash
#!/usr/bin/env bash
# Modified to use HTTPS instead of SSH
REPO_URL="https://github.com/VictorBuch/serenityOs.git"

# Remove SSH setup steps entirely
# Focus on:
# - Clone repo (HTTPS, no auth needed for public repos)
# - Partition disks (manual or via disko)
# - Install NixOS
# - Copy hardware-configuration.nix
# - Build system
```

**Changes from current install.sh:**
- Change `REPO_URL` from SSH to HTTPS
- Remove `setup_ssh()` function
- Remove SSH key generation and GitHub setup
- Keep: prerequisites, repo cloning, hardware config, build

#### postInstall.sh (NEW - SSH setup after first boot)
```bash
#!/usr/bin/env bash
# Run this after first boot to set up SSH for future updates

# 1. Generate SSH key
ssh-keygen -t ed25519 -C "victorbuch@protonmail.com" -f ~/.ssh/id_ed25519

# 2. Display public key
echo "Add this key to GitHub:"
cat ~/.ssh/id_ed25519.pub

# 3. Wait for user confirmation
read -p "Press Enter after adding key to GitHub..."

# 4. Switch git remote from HTTPS to SSH
cd ~/serenityOs
git remote set-url origin git@github.com:VictorBuch/serenityOs.git

# 5. Test SSH connection
ssh -T git@github.com

# 6. Add SSH key to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

echo "Setup complete! You can now git pull and nixos-rebuild"
```

### 2. Add Disko for Automatic Partitioning

Create `hosts/shepherd/disko.nix`:

```nix
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/sda";  # Could be made interactive
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
```

**Add disko to flake.nix inputs:**
```nix
inputs = {
  # ... existing inputs ...
  disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

**Import in shepherd configuration:**
```nix
modules = [
  ./hosts/shepherd/configuration.nix
  ./hosts/shepherd/disko.nix  # Add this
  inputs.disko.nixosModules.disko
  # ... other modules ...
];
```

### 3. Update ISO Configuration

**Modifications to `hosts/shepherd/iso-arm.nix` and `hosts/shepherd/iso.nix`:**

```nix
{
  # ... existing ISO config ...

  # Include installer scripts in the ISO
  environment.systemPackages = with pkgs; [
    # ... existing packages ...

    # Add installer script as command
    (writeScriptBin "shepherd-install" (builtins.readFile ../../scripts/iso-install.sh))

    # Add post-install script
    (writeScriptBin "shepherd-postinstall" (builtins.readFile ../../scripts/postInstall.sh))
  ];

  # Copy scripts to obvious locations
  system.activationScripts.copyInstallerScripts = ''
    mkdir -p /root/installer
    cp ${../../scripts/iso-install.sh} /root/installer/install.sh
    cp ${../../scripts/postInstall.sh} /root/installer/postInstall.sh
    cp ${../../README-ISO.md} /root/installer/README.md
    chmod +x /root/installer/*.sh
  '';

  # Display welcome message on login
  programs.bash.loginShellInit = ''
    cat /root/installer/README.md
  '';
}
```

### 4. Create Welcome/Instructions File

Create `README-ISO.md`:

```markdown
# Shepherd NixOS Installer

Welcome to the Shepherd bootable installer!

## Quick Start

1. Partition and install:
   ```bash
   sudo shepherd-install
   ```

2. After installation completes, the system will prompt you to reboot.

3. After first boot, set up SSH for future updates:
   ```bash
   shepherd-postinstall
   ```

## Manual Installation

If you prefer manual control:

1. Partition your disk:
   ```bash
   parted /dev/sda -- mklabel gpt
   parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
   parted /dev/sda -- mkpart primary 512MiB 100%
   ```

2. Format and mount:
   ```bash
   mkfs.fat -F 32 /dev/sda1
   mkfs.ext4 /dev/sda2
   mount /dev/sda2 /mnt
   mkdir /mnt/boot && mount /dev/sda1 /mnt/boot
   ```

3. Run the installer:
   ```bash
   cd /root/installer
   ./install.sh shepherd
   ```

## What This ISO Provides

- Automated installation with your exact configuration
- Pre-configured tools (neovim, git, nushell)
- SSH server enabled (for remote installation)
- Network Manager for easy network setup

## After Installation

Run `shepherd-postinstall` to:
- Generate SSH key for GitHub
- Switch git remote to SSH
- Enable seamless updates via git pull

## Support

For issues or questions, see: https://github.com/VictorBuch/serenityOs
```

### 5. Create ISO-Specific Install Script

Create `scripts/iso-install.sh`:

This would be a simplified version of `install.sh` that:
- Assumes it's running from the ISO environment
- Uses HTTPS for git clone
- Handles partitioning (either manual prompts or disko integration)
- Runs nixos-install
- Doesn't require SSH setup

## Benefits of This Approach

### What You Get

✅ **True bootable installer** - Not just a live environment
✅ **One-command installation** - `sudo shepherd-install`
✅ **No SSH blocking** - Clone via HTTPS, set up SSH later
✅ **Repeatable** - Reinstall on new hardware anytime
✅ **Self-contained** - Everything needed is on the ISO
✅ **Clear workflow** - Install → Boot → Configure SSH

### Use Cases Enabled

- **Server installations** - Easy deployment to new hardware
- **Testing** - Try new hardware before committing
- **Recovery** - Reinstall your exact config quickly
- **Multiple machines** - Deploy shepherd config to many systems
- **Offline install** - All packages pre-downloaded (with proper cache)

## Implementation Checklist

### Phase 1: Split Installation Scripts
- [ ] Create `postInstall.sh` for SSH setup
- [ ] Modify `install.sh` to use HTTPS instead of SSH
- [ ] Remove SSH setup from `install.sh`
- [ ] Test modified `install.sh` in VM

### Phase 2: Add Disko
- [ ] Add disko to flake.nix inputs
- [ ] Create `hosts/shepherd/disko.nix`
- [ ] Import disko module in shepherd configuration
- [ ] Test disko partitioning in VM

### Phase 3: Update ISO Configurations
- [ ] Add installer scripts to `iso.nix` and `iso-arm.nix`
- [ ] Create `README-ISO.md` welcome file
- [ ] Create `scripts/iso-install.sh` (ISO-specific installer)
- [ ] Add login shell init to display README
- [ ] Test ISO build: `nix build .#nixosConfigurations.shepherd-iso.config.system.build.isoImage`

### Phase 4: Testing
- [ ] Build x86_64 ISO
- [ ] Build ARM ISO
- [ ] Test installation in VM
- [ ] Test post-install SSH setup
- [ ] Test updates after SSH is configured

### Phase 5: Documentation
- [ ] Update main README.md with ISO instructions
- [ ] Document build process
- [ ] Document installation process
- [ ] Add troubleshooting section

## Build Commands

### Build the ISO images

```bash
# x86_64 ISO
nix build .#nixosConfigurations.shepherd-iso.config.system.build.isoImage

# ARM ISO
nix build .#nixosConfigurations.shepherd-iso-arm.config.system.build.isoImage

# Output location
ls -lh result/iso/*.iso
```

### Write to USB

```bash
# Find USB device
lsblk

# Write ISO (replace /dev/sdX with your USB device)
sudo dd if=result/iso/nixos-shepherd-*.iso of=/dev/sdX bs=4M status=progress
```

### Installation Usage

1. **Boot from USB**
2. **Run installer**: `sudo shepherd-install`
3. **Reboot** when prompted
4. **Set up SSH**: `shepherd-postinstall`
5. **Update**: `cd ~/serenityOs && git pull && sudo nixos-rebuild switch --flake .#shepherd`

## Alternative: nixos-anywhere

For remote installation from your Mac (inara) to a target machine:

```bash
# Boot target machine with official NixOS ISO
# Then from your Mac:
nixos-anywhere --flake .#shepherd root@<target-ip>
```

This combines well with disko for fully automated remote installation.

## Future Enhancements

### Potential Additions

- **Interactive disk selection** - Prompt for which disk to install to
- **Encrypted disk support** - Add LUKS encryption option
- **Network configuration** - Pre-configure static IPs for servers
- **Multi-boot support** - Dual-boot configurations
- **Preset templates** - Different partition layouts (server vs desktop)

### Advanced Features

- **Automated testing** - CI/CD to build and test ISOs
- **Version pinning** - Lock specific nixpkgs commits in ISO
- **Custom kernel** - Include specific kernel versions
- **Driver bundles** - Include firmware for specific hardware

## Notes

- Public repo required for HTTPS clone (or handle authentication differently)
- Disko can be made interactive to choose disk device
- Post-install script could be included in installed system (add to PATH)
- Consider adding automated tests for ISO builds

## References

- [Disko Documentation](https://github.com/nix-community/disko)
- [NixOS ISO Building](https://nixos.org/manual/nixos/stable/#sec-building-image)
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere)
- [NixOS Installation Guide](https://nixos.org/manual/nixos/stable/#sec-installation)
