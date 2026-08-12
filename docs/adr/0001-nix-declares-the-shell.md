---
status: accepted
---

# Nix declares the Shell; the GUI does not

The Shell (noctalia) is configured from Nix via `programs.noctalia.settings`, and
DankMaterialShell was rejected specifically because its home-manager module
exposes only feature toggles and plugins — it has no `settings` option, so bar
layout, theming, and wallpaper policy would have become GUI-written state that no
rebuild reproduces. Reproducibility of the desktop outranks the polish of a
newer Shell.

## Considered Options

- **DankMaterialShell** — more modern, absorbs more components, supports mango.
  Rejected: `distro/nix/options.nix` offers `enable`, `systemd.*`,
  `enable{SystemMonitoring,VPN,DynamicTheming,AudioWavelength,CalendarEvents}`,
  `quickshell.*`, `plugins` — and nothing else. Upstream's own docs state the
  module "installs DMS but doesn't generate compositor-specific config files".
- **Caelestia / Ryoku** — never viable. Caelestia is Hyprland-only; Ryoku is an
  Arch distribution, not a consumable Shell.

## Consequences

The boundary is **deliberately chosen values**, not all values. Nix declares what
was picked on purpose — bar layout and styling, theme, wallpaper directory and
rotation policy, plugins and their settings, session actions, OSD kinds. Nix does
*not* re-declare upstream defaults (`system.monitor` thresholds, `keybinds`,
`hooks`, `battery`), or blocks belonging to disabled features.

noctalia merges `~/.config/noctalia/*.toml` alphabetically, then overlays
`~/.local/state/noctalia/settings.toml` on top. That state file therefore
**outranks anything Nix writes**, and the Shell writes to it deliberately for
app-managed state: the current wallpaper path, per-monitor overrides,
`plugins.auto_update`, and a theme-mode override. Current-wallpaper-in-state is
correct and wanted. A `theme.mode` key appearing there is drift and must be
deleted, not accommodated.

Live Seams remain the sanctioned escape hatch: a writable file the user or Shell
may edit at runtime, overlaid on the Nix-owned base. For noctalia the seam is a
plain unmanaged `~/.config/noctalia/zz-local.toml` — it must sort *after*
`config.toml`, which is the filename the home-manager module writes.
