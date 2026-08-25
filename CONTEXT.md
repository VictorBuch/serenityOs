# serenityOs

A personal NixOS / nix-darwin flake managing several hosts. This glossary fixes
the vocabulary for the desktop side. Each term below names an option path, and
the option paths are the only names hosts should use.

## Language

**Compositor**:
The Wayland (or X11) program that owns windows, outputs, and input. `mango`,
`niri`, and `hyprland` are compositors. It draws no bar, launcher, or lock
screen of its own.
_Option_: `desktop.compositor.<name>.enable`
_Avoid_: window manager, WM, desktop environment

**Shell**:
The layer riding on top of a Compositor that supplies the bar, launcher,
notifications, lock screen, session menu, and wallpaper. `noctalia` is the
Shell today. Exactly one Shell is active per session.
_Option_: `home.desktop.shell.<name>.enable`
_Avoid_: bar, panel, widget system, status bar

**Desktop Environment**:
A prepackaged Compositor + Shell + application suite shipped as one unit —
`gnome`, `kde`. Mutually exclusive with running a standalone Compositor+Shell
pair.
_Option_: `desktop.environment.<name>.enable`
_Avoid_: DE (when a Compositor is what is meant)

**Session**:
One selectable entry at the login manager. A Session names a Compositor and a
Shell, or names a Desktop Environment. `xorg-audio` is a Session, not a
Compositor.
_Option_: `desktop.session.*` for the standalone Wayland Session, whose module
carries everything a Session needs regardless of Compositor;
`desktop.extraSessions.<name>.enable` for an additional login entry.
_Avoid_: desktop, login option

**Theme Authority**:
The single component permitted to write a given app's appearance. Colors,
icons, fonts, and cursor each have exactly one Authority; a second writer for
the same aspect is a defect, not a fallback. Stated per app in one table, from
which stylix's disabled targets and noctalia's template ids are both derived.
_Option_: `theme.authority.*` (`modules/common/theme-authority.nix`)
_Avoid_: theming, styling

**Live Seam**:
A file the Shell or the user may write at runtime, referenced by `include` or
`source` from a file Nix owns. It is how a setting changes without a rebuild
while the surrounding config stays declarative. Declared, not hand-written:
the module creates the file and its header.
_Option_: `home.liveSeams.<name>` (`home/live-seams.nix`)
_Avoid_: override file, user config, dotfile

**Declarative Setting**:
A setting whose value is stated in Nix and reproduced on a fresh machine by a
rebuild. Contrasted with a **Runtime Setting**, which a GUI or CLI writes into
state that no rebuild reproduces.
_Avoid_: config (unqualified)

**App Slot**:
An application reachable by a dedicated keybind. What the app is called -- every
app_id or class it presents -- and how to launch it are stated once and read by
every Compositor. Which key the slot sits on stays with the Compositor, whose
modifier budget and tag model differ.
_Option_: `home.desktop.apps.<name>` (`modules/nixos/desktop-environments/_home/common/apps.nix`)
_Avoid_: launcher entry, shortcut
