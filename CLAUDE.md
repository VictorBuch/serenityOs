# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal NixOS/nix-darwin configuration repository using Nix flakes. The configuration manages multiple host systems across Linux (NixOS) and macOS (nix-darwin), including desktop environments and homelab services.

## System Architecture

### Host Configurations

**NixOS Hosts:**
- **jayne**: Primary desktop system with full desktop environment (Hyprland)
- **kaylee**: Lightweight desktop configuration
- **mal**: Homelab server with services and static IP (192.168.0.243)
- **shepherd**: Base configuration template (x86_64)
- **shepherd-arm**: Base configuration template (aarch64)

**macOS Hosts:**
- **inara**: macOS system using nix-darwin with Home Manager integration (aarch64-darwin)

### Module Auto-Discovery with import-tree

Modules are auto-discovered using `import-tree` (from `github:vic/import-tree`). This replaces manual import lists — just drop a `.nix` file in the right directory and it's automatically imported.

**Key convention:** Files prefixed with `_` (e.g., `_categories.nix`, `_defaults.nix`, `_config.nix`) are **excluded** from import-tree auto-discovery. They are imported explicitly in `flake.nix` when needed.

### Module Structure

- `modules/common/` - Base cross-platform modules (auto-discovered via import-tree)
- `modules/common/_defaults.nix` - Default enable values for common modules (imported explicitly)
- `modules/nixos/` - NixOS-specific modules (desktop environments, system configs)
- `modules/darwin/` - macOS-specific modules (homebrew config)
- `modules/apps/` - Cross-platform application modules organized by category (auto-discovered)
- `modules/apps/_categories.nix` - Auto-discovers categories and creates per-category enable options (imported explicitly)
- `modules/homelab/` - Mal host services (auto-discovered, plus `_config.nix` imported explicitly)
- `home/` - Minimal Home Manager entry point (default.nix, home.nix, wallpapers)
- `hosts/` - Host-specific configurations and hardware profiles
- `hosts/profiles/` - Reusable host profiles (shepherd.nix, desktop.nix, desktop-home.nix, disko-btrfs.nix)
- `lib/` - Custom helpers (only `mkModule`)
- `overlays/` - Nixpkgs overlays (llm-agents, pam-cli, lute-v3, wine921)
- `packages/` - Custom Nix packages (pam-cli, lute-v3)

### How Modules Are Composed in flake.nix

Each host gets these module layers:
1. `modules/common/` (auto-discovered) + `_defaults.nix` (explicit)
2. `modules/apps/` (auto-discovered) + `_categories.nix` (explicit)
3. Host-specific config from `hosts/<name>/configuration.nix`
4. Platform modules: `modules/nixos/` for NixOS or `modules/darwin/` for macOS
5. Home Manager + SOPS-nix integration modules

Mal is special — it gets `modules/homelab/` instead of `modules/nixos/` (no desktop modules).

### Category System

`modules/apps/_categories.nix` auto-discovers all subdirectories under `modules/apps/` and creates enable options:
- `apps.browsers.enable = true` enables all browser modules (zen, firefox, etc.)
- Individual modules can be overridden: `apps.browsers.zen.enable = false`
- Per-category overrides in `_categories.nix` control which modules default to disabled (e.g., `gaming.ps3 = false`, `neovim.nixvim = false`)

### Key Dependencies

- **nixpkgs**: NixOS packages (unstable channel)
- **nixpkgs-stable**: Stable channel (25.11) available as escape hatch via `pkgs-stable`
- **home-manager**: User environment management
- **nix-darwin**: macOS system configuration
- **nix-homebrew**: Homebrew integration for macOS
- **import-tree**: Auto-import module directories
- **disko**: Declarative disk partitioning (used with nixos-anywhere for onboarding)
- **stylix**: System-wide theming
- **nvf**: Neovim flake
- **nixvim**: Neovim configuration
- **sops-nix**: Secret management using SOPS
- **zen-browser**: Custom browser package
- **llm-agents**: AI coding agents (claude-code, etc.) from numtide
- **nixpkgs-wine920**: Pinned nixpkgs for Wine 9.20 (yabridge audio compatibility)
- **quickshell** / **noctalia**: Desktop shell components

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
sudo nixos-rebuild switch --flake .#mal
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

See `devenvs/README.md` for detailed documentation.

### Homelab-Specific (mal host)

The mal host runs as a homelab server with the following characteristics:

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

**Storage Architecture:**
- `/cache` (SSD): Hot storage for new writes
- `/mnt/disk1`, `/mnt/disk2`: Cold storage HDDs
- `/mnt/parity1`: SnapRAID parity disk
- `/mnt/cold`: MergerFS union of disk1 + disk2
- `/mnt/pool`: User-facing mount point (cache + cold)
- Cache mover runs daily, SnapRAID syncs daily, scrub runs weekly
- See `modules/homelab/STORAGE.md` for commands reference

**Maintenance:**
- Automatic updates enabled (daily at 02:00)
- Automatic garbage collection runs weekly
- SOPS for secret management (secrets in `secrets/secrets.yaml`)

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
sudo nixos-rebuild build --flake .#mal
sudo nixos-rebuild build --flake .#jayne
darwin-rebuild build --flake .#inara
```

## Secret Management

Uses SOPS-nix for secret management:

- Secrets stored in `secrets/secrets.yaml`
- Age key file location varies per host (check host config for `sops.age.keyFile`)
- YubiKey support configured in `.sops.yaml` for jayne and inara hosts
- Cloudflare, VPN, and service credentials managed via SOPS

## Installation

**Primary method:** nixos-anywhere + disko (one command, no manual partitioning). See `docs/onboarding.md` for the full walkthrough.

**Fallback:** `install.sh` for cases where nixos-anywhere isn't an option.

### Host Profiles

Reusable profiles in `hosts/profiles/`:
- `shepherd.nix` - Base profile for all shepherd-derived hosts (locale, desktop env, base apps)
- `desktop.nix` / `desktop-home.nix` - Desktop host configuration
- `disko-btrfs.nix` - Shared btrfs partitioning layout with `@` / `@home` / `@nix` / `@log` subvolumes (parameterized by device path)

## Configuration Guidelines

### The mkModule Helper

All application and service modules use the single `mkModule` helper (`lib/mkModule.nix`). It replaces the older `mkApp`, `mkHomeModule`, and `mkCategory` helpers.

**CRITICAL: The `args` Pattern**

All modules using `mkModule` **MUST** use the `args@{...}: ... } args` pattern:

```nix
args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  # configuration
} args
```

**Without this pattern, you will get the error: "module does not look like a module"**

**Basic app module** (system packages only):
```nix
args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "firefox";
  category = "browsers";
  packages = { pkgs, ... }: [ pkgs.firefox ];
  description = "Mozilla Firefox web browser";
} args
```

This creates the option `apps.browsers.firefox.enable`.

**With Home Manager config** (e.g., CLI tools):
```nix
args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "fzf";
  category = "cli";
  description = "Fuzzy finder";
  homeConfig = { config, pkgs, lib, ... }: {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };
  };
} args
```

**Platform-specific packages:**
```nix
mkModule {
  name = "ghostty";
  category = "development";
  linuxPackages = { pkgs, ... }: [ pkgs.ghostty ];
  darwinExtraConfig = {
    homebrew.casks = [ "ghostty" ];
  };
}
```

**Mixing stable and unstable packages:**
```nix
mkModule {
  name = "myapp";
  category = "media";
  packages = { pkgs, pkgs-stable, ... }: [
    pkgs.something         # from unstable
    pkgs-stable.something  # from stable (25.11)
  ];
}
```

**mkModule parameters:**
- `name` (required) - Module name, used in option path
- `category` (optional) - Subdirectory category, creates `apps.<category>.<name>.enable`
- `namespace` (default: `"apps"`) - Top-level option namespace
- `packages` / `linuxPackages` / `darwinPackages` - System packages (functions receiving `{ pkgs, pkgs-stable }`)
- `extraConfig` / `linuxExtraConfig` / `darwinExtraConfig` - Additional NixOS/Darwin config
- `homeConfig` / `linuxHomeConfig` / `darwinHomeConfig` - Home Manager config (injected via `home-manager.sharedModules`)
- Linux-only modules (only `linuxPackages` set) are automatically skipped on Darwin

### Adding a New Package

1. Create `modules/apps/<category>/<name>.nix` using `mkModule`
2. The file is auto-discovered by import-tree — no need to edit any imports
3. Enable the category in host config: `apps.<category>.enable = true;` (enables all modules in category)
4. Or enable individually: `apps.<category>.<name>.enable = true;`
5. `git add` the new file (flakes only see Git-tracked files)
6. Rebuild: `sudo nixos-rebuild switch --flake .` or `darwin-rebuild switch --flake .`

### Enabling Homelab Services

Services are disabled by default. To enable:

1. Edit `hosts/mal/configuration.nix`
2. Set the service option to true (e.g., `immich.enable = true;`)
3. Ensure secrets are configured in `secrets/secrets.yaml` if needed
4. Rebuild: `sudo nixos-rebuild switch --flake .#mal`

### Working with Secrets (SOPS)

```bash
# Edit secrets (requires age key)
sops secrets/secrets.yaml

# Add new age key
sops updatekeys secrets/secrets.yaml
```

Secrets are automatically decrypted at runtime and made available to services via `config.sops.secrets.<name>.path`.

## Common Errors and Troubleshooting

### "module does not look like a module"

**Cause:** Missing the `args@{...}: ... } args` pattern when using `mkModule`.

**Solution:** Always use this pattern:
```nix
args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  # configuration
} args
```

### "path does not exist" (in flake evaluation)

**Cause:** File not tracked by Git. Flakes only include Git-tracked files.

**Solution:**
```bash
git add path/to/file.nix
```

### Missing app icons in Qt/QML applications

**Cause:** Qt applications don't automatically detect GTK icon themes without proper environment variables.

**Solution:** Add to your module's `extraConfig` or `homeConfig`:
```nix
home.sessionVariables = {
  QT_QPA_PLATFORMTHEME = "gtk3";
  QS_ICON_THEME = "Papirus-Dark";
};
```

### Flake module naming inconsistencies

Different flakes use different naming conventions for their Home Manager modules:

- Most flakes: `inputs.flake.homeManagerModules.default`
- Some flakes: `inputs.flake.homeModules.default` (e.g., noctalia)

**Solution:** Check the flake's outputs first:
```bash
nix flake show github:owner/repo
```

## Platform-Specific Notes

### NixOS (jayne, kaylee, mal, shepherd)
- All configurations use `nixos-unstable` channel
- Home Manager integrated via `inputs.home-manager.nixosModules.default`
- Mal host does NOT use desktop modules (homelab modules instead)
- SOPS-nix enabled on all hosts for secret management

### macOS (inara)
- Uses nix-darwin for system configuration
- Home Manager integrated via `inputs.home-manager.darwinModules.default`
- Homebrew managed via nix-homebrew (configured in `modules/darwin/`)
- `allowBroken = true` set to enable some Linux packages with broken dependencies on macOS

### Cross-Platform Configuration
- Platform detection handled inside `mkModule` via `pkgs.stdenv.isLinux`
- Application modules in `modules/apps/` handle platform differences internally
- `mkModule` available in all modules via `specialArgs` in flake.nix

## Maintenance

- **Automatic garbage collection**: Runs weekly on all systems
- **Mal host automatic updates**: Daily at 02:00
- **Manual garbage collection**: `nix-collect-garbage -d`
- **Optimize Nix store**: `nix-store --optimize`

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health
