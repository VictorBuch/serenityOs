# Inara - macOS Configuration

This is the nix-darwin configuration for the Inara MacBook Pro.

## Setup Instructions

### Initial Installation

1. Clone this repository:

```bash
git clone <your-repo> ~/nixos
cd ~/nixos
```

2. Update the username in `hosts/inara/configuration.nix` if needed (currently set to "victorbuch")

3. Build and activate the configuration:

```bash
nix run nix-darwin -- switch --flake .#inara
```

4. For subsequent updates:

```bash
darwin-rebuild switch --flake .#inara
```

## Configuration Structure

- **hosts/inara/configuration.nix**: Main system configuration
- **modules/darwin/**: macOS-specific system modules
  - `homebrew.nix`: Homebrew package management
- **home/**: Home Manager configurations (cross-platform)
  - **Shared modules**: CLI tools, terminals (neovim, nushell, ghostty, kitty, git, tmux, etc.)
  - **home/linux/**: Linux-specific modules (Hyprland, GNOME, etc.) - automatically excluded on macOS

The home configuration uses conditional imports to only load platform-specific modules on the appropriate systems, allowing you to share most of your configuration between NixOS and macOS.

## Key Features

### System Defaults

- Dark mode enabled
- Dock: auto-hide with animations
- Finder: show extensions and path bar
- Fast key repeat
- Touch ID for sudo
- Caps Lock remapped to Escape

### Homebrew Integration

Homebrew is enabled and configured in `modules/darwin/homebrew.nix`.

To add packages:

```nix
# CLI tools
brews = [
  "wget"
  "curl"
];

# GUI applications
casks = [
  "firefox"
  "visual-studio-code"
];

# Mac App Store apps
masApps = {
  "Xcode" = 497799835;
};
```

### Auto-upgrade

The system is configured to auto-upgrade. You can disable this in `configuration.nix`:

```nix
system.autoUpgrade.enable = false;
```

## Customization

### Changing System Defaults

All macOS system defaults are in `hosts/inara/configuration.nix` under `system.defaults`.
See the [nix-darwin manual](https://daiderd.com/nix-darwin/manual/) for all available options.

### Adding Applications

- **Nix packages**: Add to home-manager configuration in `home/`
- **Homebrew packages**: Add to `modules/darwin/homebrew.nix`

## Updating

```bash
# Update flake inputs
nix flake update ~/nixos

# Rebuild system
darwin-rebuild switch --flake ~/nixos#inara
```
