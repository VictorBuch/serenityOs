# Personal NixOS/nix-darwin Configuration

My personal system configurations using Nix flakes for both NixOS (Linux) and nix-darwin (macOS).

## Quick Install

### One-Line Install (Recommended)

**NixOS or macOS (auto-detected):**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/VictorBuch/serenityOs/main/install.sh)
```

**With specific hostname:**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/VictorBuch/serenityOs/main/install.sh) <hostname>
```

**macOS only:**

```bash
bash <(curl -sSL https://raw.githubusercontent.com/VictorBuch/serenityOs/main/install-darwin.sh)
```

### Manual Install

1. **Clone the repository:**

   ```bash
   git clone https://github.com/VictorBuch/serenityOs.git ~/serenityOs
   cd ~/serenityOs
   ```

2. **Make scripts executable:**

   ```bash
   chmod +x install.sh install-darwin.sh
   ```

3. **Run the installer:**
   ```bash
   ./install.sh          # Interactive (auto-detects platform)
   ./install.sh jayne    # Specific NixOS host
   ./install-darwin.sh   # macOS specific
   ```

## Available Hosts

### NixOS (Linux)

- **jayne** - Primary desktop with Hyprland and full desktop environment
- **kaylee** - Lightweight desktop configuration
- **serenity** - Homelab server with services and static IP
- **shepherd** - Base configuration template for new systems

### macOS

- **inara** - macOS system with nix-darwin and Home Manager

## Prerequisites

### NixOS

- Fresh NixOS installation with internet access
- The installer will handle SSH key generation and setup

### macOS

- macOS 10.15 (Catalina) or later
- Internet connection
- The installer will install Nix if not already present

## What the Installer Does

1. **Detects your platform** (NixOS or macOS)
2. **Generates SSH key** (or reuses existing) for GitHub access
3. **Prompts you to add key to GitHub** for repo cloning
4. **Clones configuration** to `~/serenityOs`
5. **Copies hardware config** (NixOS only) from `/etc/nixos/hardware-configuration.nix`
6. **Builds and activates** your system configuration
7. **Sets user password** (NixOS only) - prompts you to set password for the configured user

## Post-Installation

### Updating Your System

**NixOS:**

```bash
cd ~/serenityOs
git pull
sudo nixos-rebuild switch --flake .#<hostname>
```

**macOS:**

```bash
cd ~/serenityOs
git pull
darwin-rebuild switch --flake .#inara
```

### Using nh (Nix Helper)

Both platforms include `nh` for easier management:

**NixOS:**

```bash
nh os switch    # Rebuild NixOS configuration
```

**macOS:**

```bash
nh darwin switch    # Rebuild darwin configuration
```

## Troubleshooting

### SSH Key Issues

If GitHub authentication fails:

1. Manually generate key: `ssh-keygen -t ed25519 -C "your@email.com"`
2. Add to GitHub: https://github.com/settings/ssh/new
3. Copy public key: `cat ~/.ssh/id_ed25519.pub`
4. Re-run installer

### Hardware Configuration (NixOS)

If hardware-configuration.nix is missing:

```bash
sudo nixos-generate-config --show-hardware-config > ~/serenityOs/hosts/<hostname>/hardware-configuration.nix
```

### User Password (NixOS)

If you get locked out or need to reset password:

```bash
# Boot to a TTY (Ctrl+Alt+F2) or recovery mode
sudo passwd <username>

# Where <username> is: jayne, kaylee, serenity, or shepherd
```

### First Build Takes Long

The first build downloads and compiles many packages. Subsequent builds are much faster thanks to Nix caching.

### macOS Permissions

Some macOS settings require logging out and back in to take effect.

## Documentation

See [CLAUDE.md](./CLAUDE.md) for detailed documentation on:

- System architecture and module structure
- Development commands and workflows
- Adding new packages and services
- Homelab configuration (serenity host)
- Secret management with SOPS
- Development shells for different project types
