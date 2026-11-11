# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal NixOS/nix-darwin configuration repository using Nix flakes. The configuration manages multiple host systems across Linux (NixOS) and macOS (nix-darwin), including desktop environments and homelab services.

## System Architecture

### Host Configurations

**NixOS Hosts:**
- **jayne**: Primary desktop system (KDE Plasma by default, mango also installed)
- **mal**: Homelab server with services and static IP (192.168.0.243)
- **wash**: Public Netcup VPS running Pangolin (edge for *.victorbuch.com)

**macOS Hosts:**
- **inara**: macOS system using nix-darwin with Home Manager integration (aarch64-darwin)

### Flake layout: flake-parts + aspects

`flake.nix` holds the inputs; its outputs are one `flake-parts.lib.mkFlake` call
over `import-tree ./modules`.
Every `.nix` file under `modules/` is a **flake-parts module**; paths containing
`/_` (e.g. `_session.nix`, `_home/`, `_wine-tracks.nix`) are skipped and imported
by path from a sibling.

A file contributes **aspects**: `flake.modules.<class>.<name>`, class being
`nixos`, `darwin` or `homeManager`. Several files may define the same aspect; the
definitions merge (every `modules/common/*.nix` adds to `base`). Inside, write a
plain module — `inputs` comes from the file's flake-parts arguments, not module args.

- `modules/flake/hosts.nix` - `mkHost` and the `hosts` list
- `modules/flake/systems.nix` - systems, `pkgs`/`pkgs-stable`, overlay, packages
- `modules/common/` - aspect `base` (nixos + darwin), every host gets it
- `modules/darwin/` - more of darwin `base` (homebrew)
- `modules/apps/<category>/<name>.nix` - one aspect per app, named `<name>`
- `modules/nixos/` - desktop and system aspects, one per file (`mango`, `amd-gpu`, `user`, ...)
- `modules/homelab/` - aspect `homelab` (mal); `facts.nix` is `homelab-facts` (mal, wash)
- `home/` - Home Manager entry point, imported by `modules/common/home-manager.nix`
- `hosts/<name>/` - plain NixOS/darwin module per host plus hardware files
- `overlays/`, `packages/`, `lib/expiring.nix` (used by the overlay)

### How hosts are built

`mkHost` builds every host. An entry in `hosts` has `name`, `features` (aspect
names), optional `class = "darwin"`, `system` and `extraModules` (external flake
modules). Each host gets, in order: `base`, the `features`,
`hosts/<name>/configuration.nix`, the Home Manager and sops-nix modules, and
`extraModules`. A feature pulls in `modules.<class>.<name>` and/or
`modules.homeManager.<name>` (the latter via `home-manager.sharedModules`);
naming one that has neither fails evaluation.

There are no `specialArgs`. Host files receive `inputs` and `pkgs-stable` as
module args, so they work in values but not in `imports`. Home Manager modules
still get `username`, `inputs` and `pkgs-stable` through `extraSpecialArgs`,
set in `modules/common/home-manager.nix` from `user.userName`; a host sets
`user.userName` and nothing else.

Options with real logic stay options: `desktop.*`, `homelab.*`,
`apps.audio.reaper.wineTrack`, `maintenance.enable` and friends. Hosts set those
in their configuration file.

### Key Dependencies

- **nixpkgs**: NixOS packages (unstable channel)
- **nixpkgs-stable**: Stable channel (25.11) available as escape hatch via `pkgs-stable`
- **home-manager**: User environment management
- **nix-darwin**: macOS system configuration
- **nix-homebrew**: Homebrew integration for macOS
- **flake-parts**: Flake output framework; `flake.modules` holds the aspects
- **import-tree** (`denful/import-tree`): Auto-import module directories
- **disko**: Declarative disk partitioning (used with nixos-anywhere for onboarding)
- **stylix**: System-wide theming
- **nvf**: Neovim flake
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
- Automatic updates: weekly (Sunday 02:00) rebuild of `github:VictorBuch/serenityOs` main. Inputs only move when an updated flake.lock is pushed; a manual deploy of unpushed work is reverted on the next run
- Automatic garbage collection runs weekly
- SOPS for secret management (secrets in `secrets/secrets.yaml`)

### Testing and Validation

```bash
# Test any CLI tool without installing
nix-shell -p <packageName>

# Evaluate every host (jayne, mal, wash, inara). Must stay green.
nix flake check --no-build

# Did my refactor change anything? Record drvPaths before and after, then diff:
nix eval --json .#nixosConfigurations --apply 'cs: builtins.mapAttrs (_: c: c.config.system.build.toplevel.drvPath) cs'
# A changed host: `nix run nixpkgs#nix-diff -- <old.drv> <new.drv>` says why.

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

## Configuration Guidelines

### Adding an app

Create `modules/apps/<category>/<name>.nix`, then add `"<name>"` to the
`features` of each host in `modules/flake/hosts.nix`. Shapes:

```nix
# system package, both platforms
let
  module = { pkgs, ... }: { environment.systemPackages = [ pkgs.firefox ]; };
in
{
  flake.modules.nixos.firefox = module;
  flake.modules.darwin.firefox = module;
}
```

```nix
# Home Manager only, or a platform split: define only the classes that apply
{
  flake.modules.nixos.ghostty = { pkgs, ... }: { environment.systemPackages = [ pkgs.ghostty ]; };
  flake.modules.darwin.ghostty.homebrew.casks = [ "ghostty" ];
  flake.modules.homeManager.ghostty = { ... }: { programs.ghostty.enable = true; };
}
```

Use `pkgs-stable` as a module argument for the stable (25.11) channel. A
Linux-only app defines no `darwin` aspect, so it goes only in Linux hosts'
`features`. An option that decides module *structure* (`options`, `imports`)
must not read `pkgs`; branch on the class instead (see
`modules/common/yubikey.nix`). New files must be tracked (`jj st`) before
evaluation sees them.

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

### "path does not exist" (in flake evaluation)

**Cause:** File not tracked by Git. Flakes only include Git-tracked files.

**Solution:**
```bash
git add path/to/file.nix
```

### Missing app icons in Qt/QML applications

**Cause:** Qt applications don't automatically detect GTK icon themes without proper environment variables.

**Solution:** Add to the app's `homeManager` aspect:
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

### NixOS (jayne, mal, wash)
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
- Platform differences are expressed by which classes an aspect defines
  (`nixos`, `darwin`, `homeManager`), not by runtime checks

## Maintenance

- **Automatic garbage collection**: Runs weekly on all systems
- **Mal and wash automatic updates**: Weekly, Sunday 02:00, from GitHub main
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
