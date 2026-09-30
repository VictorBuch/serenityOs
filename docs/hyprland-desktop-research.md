# Hyprland + noctalia desktop research

Researched 2026-09-30 against: noctalia `40be3092` (the rev in `flake.lock`), Hyprland 0.56.2 (nixpkgs unstable) and the
Hyprland wiki at `main` (`b9b9fc12`), home-manager `7b4c5ec4`, nixpkgs `7a0f122f`.

## Summary

- **This repo's noctalia is not the Quickshell shell.** `github:noctalia-dev/noctalia` is a native C++ Wayland shell
  that "is built directly on Wayland and OpenGL ES with no Qt or GTK dependency"
  ([README](https://github.com/noctalia-dev/noctalia/blob/40be3092eda60f458bee095a9d1d83a6e4086b04/README.md)). It
  lists Hyprland as a supported compositor, with its own Hyprland backend
  ([src/compositors/hyprland](https://github.com/noctalia-dev/noctalia/tree/40be3092eda60f458bee095a9d1d83a6e4086b04/src/compositors/hyprland)).
- **Hyprland config is Lua now.** "Since Hyprland 0.55, hyprlang is deprecated in favor of lua"
  ([0.56.0 wiki](https://wiki.hypr.land/0.56.0/Configuring/Basics/Window-Rules/)). The config file is
  `~/.config/hypr/hyprland.lua` ([Core](https://wiki.hypr.land/configuring/core/)). Window rules take the form
  `hl.window_rule({ match = {...}, <effect> = ... })`. `windowrule = ...` lines are the legacy syntax.
- **noctalia covers all 16 shell features** in the list below. DMS covers the same 16. Every DMS extra (printers,
  process list, colour picker, notepad) exists as a noctalia plugin, so switching to DMS gains nothing here.
- **Gaps neither shell fills:** a Secret Service provider, portals (FileChooser especially), automount on insert,
  Qt platform-theme env, KDE Connect and display arrangement. Only automount on insert and KDE Connect are missing from
  this repo today.

| Feature | noctalia | DMS | Source (noctalia / DMS) |
|---|---|---|---|
| Notifications daemon + history | yes | yes | [notifications.mdx][n-notif] / [Modules/Notifications][d-mod] |
| App launcher | yes | yes | [launcher][n-launch] / [README][d-readme] |
| Clipboard history | yes (encrypted; needs Secret Service) | yes | [shell.mdx][n-shell] / [core/internal/clipboard][d-clip] |
| Polkit agent | yes (`shell.polkit_agent`; **off here**) | yes | [src/dbus/polkit][n-polkit] / [PolkitService.qml][d-polkit] |
| OSD volume/brightness | yes | yes | [src/shell/osd][n-osd] / [Modules/OSD][d-mod] |
| Lock screen | yes | yes | [src/shell/lockscreen][n-lock] / [Modules/Lock][d-mod] |
| Idle management | yes (`ext_idle_notifier_v1`) | yes | [idle.mdx][n-idle] / [README][d-readme] |
| Screenshots | yes (region/full + annotation) | yes | [src/capture][n-cap] / [core/internal/screenshot][d-shot] |
| Network/wifi panel | yes | yes | [network_tab][n-tabs] / [Modules/Network][d-mod] |
| Bluetooth panel | yes | yes | [bluetooth_tab][n-tabs] / [README][d-readme] |
| Audio device panel | yes | yes | [audio_tab][n-tabs] / [README][d-readme] |
| Power/session menu | yes | yes | [src/shell/session][n-sess] / [Modules/PowerMenu][d-mod] |
| Night light | yes (`wlr-gamma-control`) | yes | [night-light.mdx][n-night] / [NightModeService.qml][d-night] |
| Calendar | yes (CalDAV/Google sync) | yes (khal backend) | [src/calendar][n-cal] / [README][d-readme] |
| Media controls | yes (MPRIS) | yes | [src/dbus/mpris][n-mpris] / [README][d-readme] |
| Tray | yes | yes | [src/dbus/tray][n-tray] / [SystemTrayBar.qml][d-tray] |

[n-notif]: https://github.com/noctalia-dev/noctalia/blob/40be3092eda60f458bee095a9d1d83a6e4086b04/docs/user/services/notifications.mdx
[n-launch]: https://github.com/noctalia-dev/noctalia/tree/40be3092eda60f458bee095a9d1d83a6e4086b04/src/launcher
[n-shell]: https://github.com/noctalia-dev/noctalia/blob/40be3092eda60f458bee095a9d1d83a6e4086b04/docs/user/configuration/shell.mdx
[n-polkit]: https://github.com/noctalia-dev/noctalia/tree/40be3092eda60f458bee095a9d1d83a6e4086b04/src/dbus/polkit
[n-osd]: https://github.com/noctalia-dev/noctalia/tree/40be3092eda60f458bee095a9d1d83a6e4086b04/src/shell/osd
[n-lock]: https://github.com/noctalia-dev/noctalia/tree/40be3092eda60f458bee095a9d1d83a6e4086b04/src/shell/lockscreen
[n-idle]: https://github.com/noctalia-dev/noctalia/blob/40be3092eda60f458bee095a9d1d83a6e4086b04/docs/user/services/idle.mdx
[n-cap]: https://github.com/noctalia-dev/noctalia/tree/40be3092eda60f458bee095a9d1d83a6e4086b04/src/capture
[n-tabs]: https://github.com/noctalia-dev/noctalia/tree/40be3092eda60f458bee095a9d1d83a6e4086b04/src/shell/control_center/tabs
[n-sess]: https://github.com/noctalia-dev/noctalia/tree/40be3092eda60f458bee095a9d1d83a6e4086b04/src/shell/session
[n-night]: https://github.com/noctalia-dev/noctalia/blob/40be3092eda60f458bee095a9d1d83a6e4086b04/docs/user/services/night-light.mdx
[n-cal]: https://github.com/noctalia-dev/noctalia/tree/40be3092eda60f458bee095a9d1d83a6e4086b04/src/calendar
[n-mpris]: https://github.com/noctalia-dev/noctalia/tree/40be3092eda60f458bee095a9d1d83a6e4086b04/src/dbus/mpris
[n-tray]: https://github.com/noctalia-dev/noctalia/tree/40be3092eda60f458bee095a9d1d83a6e4086b04/src/dbus/tray
[d-readme]: https://github.com/AvengeMedia/DankMaterialShell/blob/master/README.md
[d-mod]: https://github.com/AvengeMedia/DankMaterialShell/tree/master/quickshell/Modules
[d-clip]: https://github.com/AvengeMedia/DankMaterialShell/tree/master/core/internal/clipboard
[d-polkit]: https://github.com/AvengeMedia/DankMaterialShell/blob/master/quickshell/Services/PolkitService.qml
[d-shot]: https://github.com/AvengeMedia/DankMaterialShell/tree/master/core/internal/screenshot
[d-night]: https://github.com/AvengeMedia/DankMaterialShell/blob/master/quickshell/Services/NightModeService.qml
[d-tray]: https://github.com/AvengeMedia/DankMaterialShell/blob/master/quickshell/Modules/DankBar/Widgets/SystemTrayBar.qml

## 1. Shell coverage (noctalia vs DMS vs KDE)

### noctalia on Hyprland: how it is set up here

`modules/nixos/desktop-environments/_home/common/noctalia.nix` enables these features: bar widgets (tray,
notifications, network, bluetooth, volume and session), clipboard history (`clipboard_enabled = true`, 100 entries),
screenshots (`noctalia msg screenshot-region` / `screenshot-fullscreen`), OSD, lock screen, idle behaviours
(lock at 600 s, screen-off at 660 s) and a control center with wifi, bluetooth, caffeine, nightlight and power-profile
shortcuts. It also enables two plugins: `avivbintangaringga/nix-monitor` and `pozzoo/hassio`. `polkit_agent = false`
because `_session.nix` autostarts `polkit-gnome-authentication-agent-1`.

The Hyprland-specific facts below come from noctalia's source:

- **Protocols.** Lock, idle, screen capture and night light depend on protocols that Hyprland implements: SessionLock,
  IdleNotify, Screencopy and GammaControl ([src/protocols](https://github.com/hyprwm/Hyprland/tree/main/src/protocols)).
  noctalia's docs name Hyprland as a supported compositor for night light
  ([night-light.mdx][n-night]).
- **Screen-off.** noctalia's Hyprland output backend sends the Lua dispatcher
  `hl.dsp.dpms({ action = ... })` and falls back to the legacy `dpms on|off`
  ([hyprland_output_backend.cpp#L66](https://github.com/noctalia-dev/noctalia/blob/40be3092eda60f458bee095a9d1d83a6e4086b04/src/compositors/hyprland/hyprland_output_backend.cpp#L66)).
  The `screen-off` idle behaviour therefore works on Hyprland.
- **Encrypted storage.** Clipboard history and the calendar cache are encrypted with a key held in the Secret
  Service. If the keyring is locked at startup, those features are unavailable until it unlocks
  ([secret-service.mdx](https://github.com/noctalia-dev/noctalia/blob/40be3092eda60f458bee095a9d1d83a6e4086b04/docs/user/configuration/secret-service.mdx)).
- **Hyprland config snippets.** noctalia publishes Hyprland Lua snippets: autostart through `hl.on("hyprland.start", ...)`,
  persistent workspace rules so empty workspaces still appear in the widget, IPC binds, and a `hl.layer_rule` that
  turns on blur and `no_anim` for the `noctalia-*` namespaces
  ([compositor-settings/hyprland.mdx](https://github.com/noctalia-dev/noctalia/blob/40be3092eda60f458bee095a9d1d83a6e4086b04/docs/user/compositor-settings/hyprland.mdx)).
- **Stated scope.** Window management, "file management, removable-drive mounting, printers management, and screen
  mirroring/casting" are out of scope ([README § Scope](https://github.com/noctalia-dev/noctalia/blob/40be3092eda60f458bee095a9d1d83a6e4086b04/README.md)).
- **Redundant cliphist.** `_session.nix` still autostarts `wl-paste --watch cliphist store`, which duplicates noctalia's
  clipboard history.

### DMS

DMS is built on Quickshell and Go. Its README says it "replaces waybar, swaylock, swayidle, mako, fuzzel, polkit"
([README][d-readme]). It covers every row of the table above. It also has a CUPS printer widget, a process list, a
notepad, a colour picker and a greeter front-end
([Modules](https://github.com/AvengeMedia/DankMaterialShell/tree/master/quickshell/Modules)).

**Does switching buy anything? No.** Each DMS extra has a noctalia equivalent:

| DMS extra | noctalia equivalent |
|---|---|
| Printers | community plugin `andrewdems/printers` |
| Process list | community plugin `processes` |
| Colour picker | community plugin `oldirtty/color_picker` (hyprpicker) |
| Notepad | official plugin `notes` |
| Greeter | [noctalia-greeter](https://github.com/noctalia-dev/noctalia-greeter) |

The plugins are listed in [community-plugins](https://github.com/noctalia-dev/community-plugins) and
[official-plugins](https://github.com/noctalia-dev/official-plugins). Switching would also throw away this repo's
noctalia integration (Theme Authority templates, the live seam, the IPC-action check).

## 2. What KDE provides that neither shell covers

The Hyprland wiki's "Must-have" page lists what "DEs like Plasma or GNOME will take care of automatically": a
notification daemon, PipeWire, xdg-desktop-portal, an authentication agent, Qt Wayland and fonts
([must-have](https://wiki.hypr.land/useful-utilities/must-have/)). noctalia supplies the notification daemon and
(optionally) the authentication agent. The rest are handled as follows.

| Gap | Smallest fill on NixOS | In this repo? |
|---|---|---|
| Secret Service (KWallet in Plasma) | `services.gnome.gnome-keyring.enable` + `security.pam.services.login.enableGnomeKeyring`. noctalia "never ships or manages" a provider ([secret-service.mdx](https://github.com/noctalia-dev/noctalia/blob/40be3092eda60f458bee095a9d1d83a6e4086b04/docs/user/configuration/secret-service.mdx)) | **Yes**: `_session.nix` (`keyring` option, PAM on `login`) |
| Portals | `programs.hyprland.enable` adds `portalPackage` (xdph), `configPackages = [hyprland]`, and via `wayland-session.nix` also `xdg-desktop-portal-gtk`, polkit and dconf ([hyprland.nix](https://github.com/NixOS/nixpkgs/blob/7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f/nixos/modules/programs/wayland/hyprland.nix), [wayland-session.nix](https://github.com/NixOS/nixpkgs/blob/7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f/nixos/modules/programs/wayland/wayland-session.nix)) | **Yes** (in-progress `hyprland.nix`) |
| File chooser portal | xdph implements only Screenshot, ScreenCast, GlobalShortcuts and InputCapture ([hyprland.portal](https://github.com/hyprwm/xdg-desktop-portal-hyprland/blob/master/hyprland.portal)). FileChooser must come from `gtk`, or from `kde`, since plasma6 already installs `xdg-desktop-portal-kde` on jayne ([plasma6.nix#L298](https://github.com/NixOS/nixpkgs/blob/7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f/nixos/modules/services/desktop-managers/plasma6.nix#L298)) | **Yes**: `config.hyprland.FileChooser = ["gtk"]` |
| Polkit agent | Already covered: noctalia (`polkit_agent = true`) or the existing polkit-gnome. `hyprpolkitagent` 0.1.3 is also in nixpkgs, but none is needed | **Yes**: polkit_gnome autostart |
| Idle / lock | Covered by noctalia. hypridle/hyprlock are unnecessary | noctalia |
| Screenshots | Covered by noctalia. `grim` + `slurp` are installed as a fallback | **Yes** |
| Automount on insert | `udisks2` alone only provides the D-Bus service; the wiki pairs it with `udiskie` ([other § udiskie](https://wiki.hypr.land/useful-utilities/other/)). Smallest option: HM `services.udiskie.enable = true` (needs `services.udisks2.enable`). Alternative: noctalia plugin `aristides/udiskie` | **Partial**: udisks2 + gvfs + wheel polkit rule, so Dolphin mounts on click. No insert-time automount (the `# auto-mount` comment on udisks2 overstates it) |
| Qt/GTK theming | noctalia writes the qt6ct, kdeglobals and GTK templates, but Qt apps need `QT_QPA_PLATFORMTHEME=qt6ct`. Hyprland 0.56.2 already exports that var to systemd/D-Bus at start ([Compositor.cpp#L547](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/Compositor.cpp#L547)) | **Yes**: in-progress `_home/hyprland/hyprland.nix` sets it |
| KDE Connect | `programs.kdeconnect.enable = true` (opens TCP/UDP 1714–1764). Optional UI: noctalia plugin `icefish/phone-connect` ("Control paired phones via KDE Connect") | **No** (grep finds nothing) |
| Settings app (displays etc.) | noctalia's Settings covers the shell only. Monitor arrangement is compositor territory (README § Scope). Here outputs are declared in `desktop.session.outputs`; `pavucontrol`, `blueman` and `nm-applet` are installed | Mostly |
| Qt Wayland | `qt5.qtwayland` / `qt6.qtwayland` | **Yes**: `_session.nix` |

**Portal-config trap.** `xdg.portal.config.common` is linked to `/etc/xdg/xdg-desktop-portal/portals.conf`
([portal.nix](https://github.com/NixOS/nixpkgs/blob/7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f/nixos/modules/config/xdg/portal.nix)).
xdg-desktop-portal searches `$XDG_CONFIG_DIRS` (`/etc/xdg`) before `$XDG_DATA_DIRS`. Within each location it reads a
desktop-specific file first and falls back to `portals.conf`
([portals.conf(5)](https://github.com/flatpak/xdg-desktop-portal/blob/main/doc/portals.conf.rst.in)).

mango.nix sets `common.default = ["gtk"]`. That file sits in `/etc/xdg`, so it would shadow Hyprland's shipped
`share/xdg-desktop-portal/hyprland-portals.conf` (`default=hyprland;gtk`,
[source](https://github.com/hyprwm/Hyprland/blob/main/assets/hyprland-portals.conf)) and break screencast. The
in-progress `xdg.portal.config.hyprland` avoids this. Keep it.

## 3. Hyprland for a workspace-per-app workflow (0.56 Lua syntax)

### Window rule syntax (current)

```lua
hl.window_rule({
    name? = string,
    match = { prop = some_prop_value },
    effect = some_effect_value,
})
```

From [window-rules](https://wiki.hypr.land/configuring/core/rules/window-rules/) (same syntax in
[0.56.0](https://wiki.hypr.land/0.56.0/Configuring/Basics/Window-Rules/)):

- **Match props:** `class`, `title`, `initial_class`, `initial_title`, `float`, `fullscreen`, `workspace`, `tag`,
  `xwayland`, `modal` and others. Regexes use RE2, and a `negative:` prefix negates one
  ([naming-conventions](https://wiki.hypr.land/configuring/naming-conventions/)).
- **Static effects** (evaluated once, at open): `float`, `center`, `size`, `move`, `workspace` (`"N silent"`),
  `monitor`, `fullscreen`, `maximize`, `group`, `tile` and others.
- **Dynamic effects** (for example `opacity`, `persistent_size`, `no_blur`) are re-evaluated. When several rules
  match, the last one wins.
- `size` accepts `{w, h}`, `"WxH"`, or expressions such as `{"monitor_w*0.5", "monitor_h*0.5"}`.
- `hl.window_rule()` returns a handle, so a named rule can be toggled with `:set_enabled()`.

### Recipes

```lua
-- Pin an app to a workspace without stealing focus
hl.window_rule({ match = { class = "^(zen|zen-beta)$" }, workspace = "2 silent" })

-- Visiting an empty workspace launches its app (run-or-raise by workspace)
hl.workspace_rule({ workspace = "2", persistent = true, on_created_empty = "zen" })
hl.bind("SUPER + 2", hl.dsp.focus({ workspace = 2 }))

-- Scratchpad
hl.workspace_rule({ workspace = "special:term", on_created_empty = "ghostty" })
hl.bind("SUPER + grave",         hl.dsp.workspace.toggle_special("term"))    -- no "special:" prefix here
hl.bind("SUPER + SHIFT + grave", hl.dsp.window.move({ workspace = "special:term" }))

-- Dolphin (this repo's default file manager; class org.kde.dolphin per _home/common/apps.nix)
hl.window_rule({
    name  = "dolphin-float",
    match = { class = "^org\\.kde\\.dolphin$" },
    float = true,
    center = true,
    size  = { "monitor_w*0.6", "monitor_h*0.65" },
    persistent_size = true,   -- remembers a manual resize for the same class+title
})
```

Sources for the recipes:

- `on_created_empty`, `persistent` and `layout`/`layout_opts` per workspace:
  [workspace-rules](https://wiki.hypr.land/configuring/core/rules/workspace-rules/).
- `toggle_special` takes the name without the `special:` prefix, while `window.move` needs the prefix. `focus`,
  `exec_cmd(cmd, { rules })` and group dispatchers: [dispatchers](https://wiki.hypr.land/configuring/core/dispatchers/).
- The same bind shapes appear in the shipped
  [example/hyprland.lua (v0.56.2)](https://github.com/hyprwm/Hyprland/blob/v0.56.2/example/hyprland.lua).
- Kaylee and the shepherd profile use `nautilus` (class `org.gnome.Nautilus`). Use the same rule with that class there.
- An ad-hoc floating launch without a rule: `hl.dsp.exec_cmd("dolphin", { float = true })`. It tracks the PID, so
  forking apps may escape it (dispatchers § Executing with rules).

### Keeping a second window of the same app manageable

- **Monocle layout, per workspace:** `hl.workspace_rule({ workspace = "2", layout = "monocle" })`. Every window
  fills the workspace. Cycle with `hl.dsp.layout("cyclenext")`; `window.cycle_next()` does not work in monocle
  ([monocle-layout](https://wiki.hypr.land/configuring/layouts/monocle-layout/)). `general.layout` also accepts
  `"monocle"` ([config-options](https://wiki.hypr.land/configuring/core/config-options/)).
- **Master layout:** `new_status = "slave"` (default), `mfact`, and `orientation` including `center`
  ([master-layout](https://wiki.hypr.land/configuring/layouts/master-layout/)).
- **Maximize without fullscreen:** `hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })`. The window
  rule `maximize = true` does the same at open. `misc.on_focus_under_fullscreen` (default `2`, which un-maximizes)
  decides what happens when another window asks for focus.
- **Groups (tabs):** `hl.dsp.group.toggle()`, `group.next()` / `group.prev()`, `group.lock()`. The rule effect
  `group = "set"` opens a window as a group. `group.auto_group = true` (default) adds new windows to the focused
  unlocked group ([config-options § group](https://wiki.hypr.land/configuring/core/config-options/)).

### home-manager module + NixOS `programs.hyprland`

- **`package`/`portalPackage` from one source.** Set HM `package = null; portalPackage = null;` so HM uses the NixOS
  module's packages. The wiki says: "Make sure **not** to mix versions of Hyprland and XDPH"
  ([HM page](https://wiki.hypr.land/nix/configuring-hyprland-with-home-manager/)). The NixOS module is required for
  the session file ([same page](https://wiki.hypr.land/nix/configuring-hyprland-with-home-manager/),
  [NixOS page](https://wiki.hypr.land/nix/installing-hyprland-on-nixos/)).
- **`configType` must be set explicitly here.** HM's `wayland.windowManager.hyprland.configType` defaults by
  `home.stateVersion`: `"hyprlang"` before 26.05, `"lua"` from 26.05
  ([HM source](https://github.com/nix-community/home-manager/blob/7b4c5ec4bedaf1e062bbc1bcaeddbc6bd242aa1b/modules/services/window-managers/hyprland/default.nix)).
  This repo is on `home.stateVersion = "24.05"` (`home/home.nix`), so without `configType = "lua"` HM writes the
  deprecated `hyprland.conf`. The in-progress module sets it. In Lua mode, each `settings` attribute becomes an
  `hl.<name>(...)` call, `lib.generators.mkLuaInline` passes raw Lua through, and `extraLuaFiles` adds `require`d
  modules.
- **systemd / UWSM:**
  - Without UWSM, keep HM `systemd.enable = true` (the default). It provides `hyprland-session.target`, bound to
    `graphical-session.target`, and imports the env.
  - Hyprland `main` now starts that target itself (`HYPRLAND_NO_SD_TARGET`,
    [Compositor.cpp#L807](https://github.com/hyprwm/Hyprland/blob/main/src/Compositor.cpp#L807)), but 0.56.2 does not
    ([v0.56.2 Compositor.cpp](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/Compositor.cpp)).
  - The wiki calls UWSM "for advanced users" with "additional quirks". With `programs.hyprland.withUWSM = true` you
    get a `hyprland-uwsm.desktop` entry, and you **must** set HM `systemd.enable = false`
    ([uwsm](https://wiki.hypr.land/useful-utilities/uwsm/)).
  - Recommendation for this repo: no UWSM. Its sessions start the shell and autostart list from the compositor
    config, the same way mango does.
  - Caveat: "a single user is not expected to have multiple graphical sessions … running simultaneously", because
    exiting one stops `graphical-session.target`
    ([systemd](https://wiki.hypr.land/configuring/extra/systemd/)).
