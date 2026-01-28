# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal NixOS/nix-darwin configuration repository using Nix flakes. The configuration manages multiple host systems across Linux (NixOS) and macOS (nix-darwin), including desktop environments and homelab services.

## System Architecture

### Host Configurations

**NixOS Hosts:**
- **jayne**: Primary desktop system with full desktop environment (Hyprland)
- **kaylee**: Lightweight desktop configuration
- **serenity**: Homelab server with services and static IP (192.168.0.243)
- **shepherd**: Base configuration template

**macOS Hosts:**
- **inara**: macOS system using nix-darwin with Home Manager integration

### Module Structure

The configuration uses a cross-platform module system:

- `modules/common.nix`: Base module imported by platform-specific configs, loads `apps/` and `system-configs/`
- `modules/nixos/`: NixOS-specific modules (imports common.nix + adds desktop-environments/)
- `modules/darwin/`: nix-darwin-specific modules (imports common.nix + homebrew config)
- `modules/apps/`: Cross-platform application modules organized by category (browsers, communication, development, media, productivity, utilities, gaming, audio, emulation, emacs)
- `modules/system-configs/`: Cross-platform system-level configurations (fonts, nh, maintenance)
- `modules/homelab/`: Server-specific services for serenity host (docker containers via systemd)
- `home/`: Home Manager configurations for user-level dotfiles and CLI tools (terminal emulators, shell configs, git, neovim, tmux, etc.)
- `hosts/`: Host-specific configurations and hardware profiles

**Key Architecture Decision:**
- Platform differences handled at the module import level (`modules/nixos/` vs `modules/darwin/`)
- Application modules in `modules/apps/` are cross-platform and handle OS detection via the `isLinux` parameter
- Home Manager is integrated into both NixOS and Darwin configurations via `home-manager.users.<username>`

### Key Dependencies

- **nixpkgs**: NixOS packages (unstable channel)
- **stable-nixpkgs**: Stable channel (25.05) available when needed
- **home-manager**: User environment management
- **nix-darwin**: macOS system configuration
- **nix-homebrew**: Homebrew integration for macOS
- **stylix**: System-wide theming (NixOS only)
- **catppuccin**: Catppuccin theme integration
- **nixvim**: Neovim configuration
- **sops-nix**: Secret management using SOPS
- **zen-browser**: Custom browser package

## Development Commands

### Building and Switching

**NixOS (Linux hosts):**
```bash
# Build and switch to new configuration (tell user to run - requires sudo, DON'T run yourself)
sudo nixos-rebuild switch --flake .

# Using nh (Nix Helper) - alternative approach (tell user to run, DON'T run yourself)
nh os switch

# Build specific host
sudo nixos-rebuild switch --flake .#jayne
sudo nixos-rebuild switch --flake .#serenity
```

**nix-darwin (macOS hosts):**
```bash
# Build and switch to new configuration (tell user to run - requires sudo, DON'T run yourself)
darwin-rebuild switch --flake .

# Using nh (if available)
nh darwin switch

# Build specific host
darwin-rebuild switch --flake .#inara
```

**Common commands (all platforms):**
```bash
# Check flake before building
nix flake check

# Update flake inputs
nix flake update

# Build without switching (test configuration)
sudo nixos-rebuild build --flake .    # NixOS
darwin-rebuild build --flake .        # macOS
```

### Development Environments

Project-specific development environments are available in `devenvs/` using [devenv.sh](https://devenv.sh). Each template provides isolated, reproducible environments with automatic activation via direnv.

**Available Templates:**
- `vue-nuxt` - Vue 3 + Nuxt 3 with Node.js 20, pnpm, Vue language server
- `nodejs` - Node.js 22 with npm/pnpm/yarn/bun (for Next.js, React, Vite, etc.)
- `flutter` - Flutter + Android SDK + Dart formatter
- `flutter-appwrite` - Flutter with Appwrite CLI integration
- `docker` - Docker Compose + Node.js + database CLIs
- `go` - Go toolchain + gopls + delve + golangci-lint + sqlc

**Quick usage:**
```bash
# Copy template to your project directory
cp -r ~/serenityOs/devenvs/nodejs/* /path/to/your-project/
cd /path/to/your-project/
direnv allow

# Environment auto-activates with tools available
# Custom scripts: dev, build, test, format
```

**Prerequisites (for teammates):**
```bash
# Install Nix if not already installed
sh <(curl -L https://nixos.org/nix/install)

# Install devenv
nix-env -iA nixpkgs.devenv

# Install direnv (optional but recommended)
nix-env -iA nixpkgs.direnv
eval "$(direnv hook bash)"  # or zsh
```

See `devenvs/README.md` for detailed documentation.

### Homelab-Specific (serenity host)

The serenity host runs as a homelab server with the following characteristics:

**Important Service Management:**
- Docker services run as systemd services with naming: `docker-<serviceName>`
- **DO NOT** use `docker` or `podman` commands directly - they won't work
- Use systemd commands: `systemctl status docker-<service>`, `systemctl restart docker-<service>`
- Services are declared in `modules/homelab/oci-containers/` and `modules/homelab/services/`

**Network Configuration:**
- Static IP: 192.168.0.243
- Reverse proxy: Caddy (configured in `modules/homelab/services/caddy.nix`)
- Cloudflare tunnels for external access
- Authentication: Tinyauth and pocket-id

**Services Available:**
- Dashboard: Homarr, Glance
- Monitoring: Uptime Kuma, AdGuard Home
- Media: Immich (photos), Mealie (recipes), Music Assistant, HyperHDR
- File Management: Filebrowser, Nextcloud
- Downloads: Deluge with VPN
- Gaming: Crafty (Minecraft server management)
- Authentication: Authelia, Tinyauth, Pocket-ID
- Finance: Wallos (subscription tracking)

**Maintenance:**
- Automatic updates enabled (daily at 02:00)
- Automatic garbage collection runs weekly
- SOPS for secret management (secrets in `secrets/secrets.yaml`, age key at `/home/serenity/.config/sops/age/keys.txt`)

### Testing and Validation

```bash
# Test any CLI tool without installing
nix-shell -p <packageName>

# Test flake evaluation
nix flake check

# Build without switching (NixOS)
sudo nixos-rebuild build --flake .

# Build without switching (macOS)
darwin-rebuild build --flake .

# Test specific host configuration
sudo nixos-rebuild build --flake .#serenity
sudo nixos-rebuild build --flake .#jayne
darwin-rebuild build --flake .#inara
```

## Secret Management

Uses SOPS-nix for secret management:

- Secrets stored in `secrets/secrets.yaml`
- Age key file: `/home/serenity/.config/sops/age/keys.txt`
- Cloudflare, VPN, and service credentials managed via SOPS

## Installation

New installations use the provided install scripts:

- `install.sh`: General NixOS installation
- `install-serenity.sh`: Serenity host specific installation with homelab setup

## Configuration Guidelines

### Module vs Home Manager Placement

**Use `modules/` for:**
- System-wide services (nginx, docker, databases, caddy)
- Hardware configuration (bluetooth, printing, sound)
- Desktop environments and window managers (Hyprland, niri, GNOME)
- Services requiring system privileges
- Multi-user applications
- Boot and system-level settings
- macOS system preferences (dock, finder, keyboard, etc.)

**Use `home/` (Home Manager) for:**
- User-specific dotfiles and configurations
- Terminal emulators and shells (ghostty, kitty, nushell, zsh)
- Editor configurations (neovim via nixvim)
- CLI tools that don't need system privileges (fzf, starship, tmux, git)
- User-specific theming and preferences
- Per-user environment variables and shell hooks

**Module Organization:**
- `modules/common.nix` - Base cross-platform module (imports apps/ and system-configs/)
- `modules/nixos/` - NixOS-specific (imports common.nix + desktop-environments/ + system-configs/)
- `modules/darwin/` - macOS-specific (imports common.nix + homebrew config)
- `modules/apps/` - Cross-platform app modules by category:
  - `audio/` - Audio production tools
  - `browsers/` - Web browsers (zen-browser, firefox, chromium)
  - `communication/` - Chat apps (discord, slack, telegram)
  - `development/` - Dev tools, editors, terminals
  - `emacs/` - Emacs configuration
  - `emulation/` - Emulators and VMs
  - `gaming/` - Games and gaming platforms
  - `media/` - Media players and editors (vlc, ffmpeg, obs)
  - `productivity/` - Office apps (obsidian, libreoffice)
  - `utilities/` - System utilities
- `modules/system-configs/` - Cross-platform system configuration:
  - `fonts.nix` - Font configuration
  - `nh.nix` - Nix Helper configuration
  - `maintenance/` - Garbage collection, auto-updates
- `modules/nixos/system-configs/` - NixOS-specific system configuration:
  - `amd-gpu.nix` - AMD GPU driver support
  - `nvidia-gpu.nix` - NVIDIA GPU driver support
  - `user.nix` - User account management
  - `networking/` - Network settings
  - `maintenance/` - System maintenance
- `modules/homelab/` - Serenity host services:
  - `oci-containers/` - Docker containers as systemd services
  - `services/` - Native NixOS services (caddy, nextcloud, etc.)

**Library Helpers (`lib/`):**
- `lib/mkApp.nix` - Universal app module helper with cross-platform and stable/unstable support
- `lib/mkCategory.nix` - Category module helper with auto-discovery of .nix files in directory (used in apps/*/default.nix)
- `lib/mkHomeModule.nix` - Home Manager individual module helper (similar to mkApp but for home/ directory)
- `lib/mkHomeCategory.nix` - Home Manager category helper (similar to mkCategory but for home/ directory)



### Using the mkApp Helper

The `mkApp` helper simplifies app module creation with automatic cross-platform support and stable/unstable package mixing.

**Basic usage (cross-platform):**
```nix
{ config, pkgs, lib, mkApp, ... }:

mkApp {
  name = "firefox";
  optionPath = "apps.browsers.firefox";
  packages = pkgs: [ pkgs.firefox ];
  description = "Mozilla Firefox web browser";
}
```

**Platform-specific packages:**
```nix
mkApp {
  name = "ghostty";
  optionPath = "apps.terminals.ghostty";
  linuxPackages = pkgs: [ pkgs.ghostty ];
  darwinPackages = pkgs: [ ];  # Installed via homebrew instead
  darwinExtraConfig = {
    homebrew.casks = [ "ghostty" ];
  };
}
```

**Linux-only (auto-asserts on Darwin):**
```nix
mkApp {
  name = "steam";
  optionPath = "apps.gaming.steam";
  linuxPackages = pkgs: [ pkgs.steam ];
  description = "Steam gaming platform";
}
```

**Mixing stable and unstable packages:**
```nix
mkApp {
  name = "myapp";
  optionPath = "apps.myapp";
  packages = { pkgs, stable-pkgs }: [
    pkgs.firefox           # from unstable
    stable-pkgs.libreoffice  # from stable (25.05)
  ];
}
```

**Benefits:**
- Automatic platform detection and assertions
- Single API for all use cases (cross-platform, platform-specific, Linux-only, Darwin-only)
- Built-in stable/unstable package support via `inputs.stable-nixpkgs`
- Reduced boilerplate compared to manual module creation
- Auto-imported in all modules via `specialArgs` in flake.nix
- Can auto-derive optionPath from file location using `_file` parameter (eliminates manual optionPath specification)

**Note on mkCategory:**
The `mkCategory` helper (in `lib/mkCategory.nix`) auto-discovers all `.nix` files in a category directory and creates a single enable option for the entire category (e.g., `apps.browsers.enable = true;` enables all browser modules). This is used in category `default.nix` files like `modules/apps/browsers/default.nix`. When the category is enabled, all discovered modules are automatically imported and enabled by default (overridable with `mkDefault`).

### Using the mkHomeModule Helper

The `mkHomeModule` helper simplifies Home Manager module creation with automatic enable options and minimal boilerplate.

**CRITICAL: The `args` Pattern**

All modules using `mkHomeModule` or `mkHomeCategory` **MUST** use the `args@{...}: ... } args` pattern:

```nix
args@{                    # Capture all arguments at the start
  config,
  pkgs,
  lib,
  mkHomeModule,          # The helper function
  ...
}:

mkHomeModule {
  # ... configuration ...
} args                    # Pass args at the end
```

**Without this pattern, you will get the error: "module does not look like a module"**

**Basic usage (auto-derive optionPath from file location):**
```nix
args@{ config, pkgs, lib, mkHomeModule, ... }:

mkHomeModule {
  _file = toString ./.;  # Auto-derives path like "home.cli.git"
  name = "git";
  description = "Git version control";
  homeConfig = { config, pkgs, lib, ... }: {
    programs.git = {
      enable = true;
      userName = "...";
    };
  };
} args
```

**Manual optionPath (when auto-derive doesn't work):**
```nix
args@{ config, pkgs, lib, mkHomeModule, ... }:

mkHomeModule {
  name = "noctalia";
  optionPath = "home.desktop-environments.noctalia";
  description = "Noctalia shell - A modern Wayland shell for niri";
  homeConfig = { config, pkgs, lib, ... }: {
    programs.noctalia-shell = {
      enable = true;
      # ... configuration ...
    };
  };
} args
```

**Key differences from mkApp:**
- Located in `home/` directory (not `modules/apps/`)
- Creates options like `home.cli.git.enable` (not `apps.*.enable`)
- No platform-specific package splitting (home manager handles that)
- Always uses `homeConfig` parameter (not `packages` or `linuxPackages`)

**Benefits:**
- Automatic enable option creation
- Auto-derives option path from file location
- Consistent with mkApp pattern but for Home Manager
- Reduces boilerplate in home configuration modules

### Using the mkHomeCategory Helper

The `mkHomeCategory` helper auto-discovers and enables all Home Manager modules in a category.

**Usage in category default.nix:**
```nix
args@{ mkHomeCategory, ... }:

mkHomeCategory {
  _file = toString ./.;
  name = "cli";
} args
```

**With custom enable defaults:**
```nix
args@{ mkHomeCategory, ... }:

mkHomeCategory {
  _file = toString ./.;
  name = "cli";
  enableByDefault = {
    zsh = false;      # Don't enable zsh by default
    nushell = true;   # Enable nushell by default
  };
} args
```

**Features:**
- Auto-discovers all `.nix` files in the directory (except `default.nix`)
- Auto-imports discovered files and subdirectory `default.nix` files
- Creates single enable option: `home.cli.enable = true;` enables all CLI modules
- Supports nested categories (subdirectories with their own `default.nix`)
- Optional manual control via `enableByDefault` parameter

**Example directory structure:**
```
home/cli/
├── default.nix       # Uses mkHomeCategory
├── git.nix           # Auto-discovered
├── tmux.nix          # Auto-discovered
└── neovim/           # Subdirectory
    └── default.nix   # Auto-imported
```

Enabling `home.cli.enable = true;` will automatically enable `home.cli.git`, `home.cli.tmux`, and `home.cli.neovim` (unless overridden).

## Common Errors and Troubleshooting

### "module does not look like a module"

**Cause:** Missing the `args@{...}: ... } args` pattern when using `mkHomeModule` or `mkHomeCategory`.

**Solution:** Always use this pattern:
```nix
args@{ config, pkgs, lib, mkHomeModule, ... }:

mkHomeModule {
  # configuration
} args
```

### "path does not exist" (in flake evaluation)

**Cause:** File not tracked by Git. Flakes only include Git-tracked files.

**Solution:**
```bash
git add path/to/file.nix
```

### mkApp vs mkHomeModule confusion

**mkApp (for `modules/apps/`):**
- Creates options like `apps.browsers.firefox.enable`
- Uses `packages`, `linuxPackages`, `darwinPackages` parameters
- For system-level applications

**mkHomeModule (for `home/`):**
- Creates options like `home.cli.git.enable`
- Uses `homeConfig` parameter (function returning Home Manager config)
- For user-level configurations

### Missing app icons in Qt/QML applications (noctalia, etc.)

**Cause:** Qt applications don't automatically detect GTK icon themes without proper environment variables.

**Solution:** Add to your Home Manager module:
```nix
home.sessionVariables = {
  QT_QPA_PLATFORMTHEME = "gtk3";      # Use GTK theme
  QS_ICON_THEME = "Papirus-Dark";     # Fallback icon theme
};
```

Or system-wide via:
```nix
environment.variables = {
  QT_QPA_PLATFORMTHEME = "gtk3";
  QS_ICON_THEME = "Papirus-Dark";
};
```

**Note:** Requires reboot or re-login to take effect.

### Flake module naming inconsistencies

Different flakes use different naming conventions for their Home Manager modules:

- Most flakes: `inputs.flake.homeManagerModules.default`
- Some flakes: `inputs.flake.homeModules.default` (e.g., noctalia)

**Solution:** Check the flake's outputs first:
```bash
nix flake show github:owner/repo
```

Look for either `homeManagerModules` or `homeModules` in the output.

## Platform-Specific Notes

### NixOS (jayne, kaylee, serenity, shepherd)
- All configurations use `nixos-unstable` channel
- Home Manager integrated via `inputs.home-manager.nixosModules.default`
- Desktop hosts (jayne, kaylee) use Catppuccin theming via `inputs.catppuccin.nixosModules.catppuccin`
- Serenity host does NOT use Home Manager (server-only configuration)
- SOPS-nix enabled on all hosts for secret management

### macOS (inara)
- Uses nix-darwin for system configuration
- Home Manager integrated via `inputs.home-manager.darwinModules.default`
- Homebrew managed via nix-homebrew (configured in `modules/darwin/homebrew.nix`)
- macOS system defaults configured in host configuration (dock, finder, keyboard, trackpad, etc.)
- `allowBroken = true` set to enable some Linux packages with broken dependencies on macOS
- Shell registered: nushell available as login shell

### Cross-Platform Configuration
- `isLinux` parameter passed to all modules for platform detection
- Application modules in `modules/apps/` handle platform differences internally
- Home Manager configurations in `home/` work on both platforms
- Core development tools: neovim (nixvim), git, fzf, starship, tmux, nh, zoxide, claude-code

## Common Development Tasks

### Adding a New Package

**Using mkApp helper:**
1. Determine placement: system (`modules/apps/<category>/`) vs user (`home/`)
2. Create a new module file using `mkApp` helper (see "Using the mkApp Helper" section)
3. Add the new file to the category's `default.nix` imports (or let add-package.sh do it)
4. Enable the module in your host configuration (`hosts/<hostname>/configuration.nix`)
5. Rebuild: `sudo nixos-rebuild switch --flake .` or `darwin-rebuild switch --flake .`

**Example module file:**
```nix
{ config, pkgs, lib, mkApp, ... }:

mkApp {
  name = "discord";
  optionPath = "apps.communication.discord";
  packages = pkgs: [ pkgs.discord ];
}
```

**Then enable in host config:**
```nix
apps.communication.discord.enable = true;
```

### Enabling Homelab Services

Services are disabled by default in `modules/homelab/default.nix`. To enable:

1. Edit `hosts/serenity/configuration.nix`
2. Set the service option to true (e.g., `immich.enable = true;`)
3. Configure service-specific options in the service module
4. Ensure secrets are configured in `secrets/secrets.yaml` if needed
5. Rebuild: `sudo nixos-rebuild switch --flake .#serenity`

### Working with Secrets (SOPS)

```bash
# Edit secrets (requires age key)
sops secrets/secrets.yaml

# Add new age key
sops updatekeys secrets/secrets.yaml
```

Secrets are automatically decrypted at runtime and made available to services via `config.sops.secrets.<name>.path`.

## Maintenance

- **Automatic garbage collection**: Runs weekly on all systems
- **Serenity host automatic updates**: Daily at 02:00
- **Manual garbage collection**: `nix-collect-garbage -d`
- **Optimize Nix store**: `nix-store --optimize`

