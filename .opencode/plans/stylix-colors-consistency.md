# Plan: Stylix (Gruvbox Dark) Color Consistency

## Goal
Make Ghostty, Niri focus-ring, and Zen Browser all use the Stylix gruvbox-dark color scheme defined in `home/nixos/stylix.nix`.

## Gruvbox Dark Palette Reference
```
base00: #282828  (background)
base01: #3c3836  (lighter bg)
base02: #504945  (selection bg)
base03: #665c54  (comments/inactive)
base04: #928374  (dark fg)
base05: #ebdbb2  (foreground)
base06: #fbf1c7  (light fg)
base07: #f9f5d7  (lightest fg)
base08: #cc241d  (red)
base09: #d65d0e  (orange)
base0A: #d79921  (yellow)
base0B: #98971a  (green)
base0C: #689d6a  (cyan)
base0D: #458588  (blue)
base0E: #b16286  (magenta)
base0F: #9d0006  (dark red)
```

---

## Change 1: Fix Ghostty (`home/terminals/ghostty.nix`)

**Problem**: Hardcoded `theme = "Catppuccin Mocha"`, `font-family`, and `background-opacity` override Stylix's auto-generated ghostty theme.

**Action**: Remove the three settings that Stylix manages. Stylix's `targets.ghostty` auto-creates a `"stylix"` theme with gruvbox colors, sets fonts, and sets opacity.

```diff
 let
   ghosttySettings = {
-    background-opacity = 0.9;
+    # Colors, fonts, and opacity are managed by Stylix (gruvbox-dark)
     background-blur-radius = 25;
     window-decoration = false;
-    theme = "Catppuccin Mocha";
     confirm-close-surface = false;
-    font-family = "JetBrainsMono Nerd Font";
     font-size = 14;
     mouse-scroll-multiplier = 1;
   };
```

---

## Change 2: Fix Niri focus-ring (`home/nixos/desktop-environments/niri/niri.nix`)

**Problem**: Focus-ring colors hardcoded as `#aaaaaa` (active) and `#6c7086` (inactive). Stylix has no niri target.

**Action**: Use `config.lib.stylix.colors.withHashtag` to inject gruvbox colors. User chose base0B (green) for active, base03 for inactive.

```diff
 {
   config,
   pkgs,
   lib,
   ...
 }:
 
 let
   terminal = "ghostty";
   fileManager = "nautilus";
   browser = "zen";
   wallpaperDaemon = "swww";
   shell = "noctalia-shell";
   applicationLauncher = "fuzzel";
+  colors = config.lib.stylix.colors.withHashtag;
 in
```

Then in the KDL config string, replace the hardcoded colors:

```diff
         focus-ring {
             width 1.5
-            active-color "#aaaaaa"
-            inactive-color "#6c7086"
+            active-color "${colors.base0B}"
+            inactive-color "${colors.base03}"
         }
```

---

## Change 3: Set up Zen Browser via Home Manager

### 3a. Update `flake.nix` - Add follows for zen-browser's home-manager input

```diff
     zen-browser = {
       url = "github:0xc000022070/zen-browser-flake";
       inputs.nixpkgs.follows = "nixpkgs";
+      inputs.home-manager.follows = "home-manager";
     };
```

### 3b. Update `hosts/profiles/desktop-home.nix` - Import zen-browser HM module

```diff
 { inputs, ... }:
 {
   home-manager.sharedModules = [
     inputs.noctalia.homeModules.default
+    inputs.zen-browser.homeModules.default
     {
       home = {
```

### 3c. Create Zen browser HM config: `home/nixos/zen.nix`

New file that configures `programs.zen-browser` with a profile and Stylix target:

```nix
{
  config,
  lib,
  ...
}:
{
  options = {
    home.zen-browser.enable = lib.mkEnableOption "Enables Zen browser home manager";
  };

  config = lib.mkIf config.home.zen-browser.enable {
    programs.zen-browser = {
      enable = true;

      profiles.${config.home.username} = {
        # Default profile using the username
      };
    };

    stylix.targets.zen-browser.profileNames = [ config.home.username ];
  };
}
```

### 3d. Import zen.nix in `home/nixos/default.nix`

```diff
 { pkgs, lib, ... }:
 {
   imports = [
     ./stylix.nix
     # ./catppuccin.nix
     ./desktop-environments
     ./audio
+    ./zen.nix
   ];

   config = {
     home.stylix.enable = lib.mkDefault true;
     # home.catppuccin.enable = lib.mkDefault true;
+    home.zen-browser.enable = lib.mkDefault true;
   };
 }
```

### 3e. Disable system-level Zen package

**`hosts/jayne/configuration.nix`** - Add explicit disable since browsers.enable auto-enables zen:
```diff
   apps = {
     audio.enable = true;
     browsers = {
       enable = true;
       floorp.enable = false;
+      zen.enable = false;  # Managed by home-manager for Stylix theming
     };
```

**`hosts/kaylee/configuration.nix`** - Change zen to false:
```diff
   apps = {
     audio.enable = true;
-    browsers.zen.enable = true;
+    browsers = {
+      zen.enable = false;  # Managed by home-manager for Stylix theming
+    };
     communication.enable = true;
```

---

## Change 4: Verify

```bash
git add -A  # Flakes only see tracked files
nix flake check
```

Then rebuild:
```bash
sudo nixos-rebuild switch --flake .#jayne
# or on kaylee: sudo nixos-rebuild switch --flake .#kaylee
```

---

## Summary of files changed

| File | Action |
|------|--------|
| `home/terminals/ghostty.nix` | Remove hardcoded theme/font/opacity |
| `home/nixos/desktop-environments/niri/niri.nix` | Use Stylix colors for focus-ring |
| `flake.nix` | Add home-manager follows for zen-browser |
| `hosts/profiles/desktop-home.nix` | Import zen-browser HM module |
| `home/nixos/zen.nix` | **NEW** - Zen browser HM config with Stylix |
| `home/nixos/default.nix` | Import zen.nix and enable it |
| `hosts/jayne/configuration.nix` | Disable system-level zen |
| `hosts/kaylee/configuration.nix` | Disable system-level zen |
