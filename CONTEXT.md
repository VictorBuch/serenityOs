# serenityOs

A personal NixOS / nix-darwin flake managing several hosts. This glossary fixes
the vocabulary for the desktop side, where four distinct concepts currently
share the single `desktop-environments` option namespace.

## Language

**Compositor**:
The Wayland (or X11) program that owns windows, outputs, and input. `mango`,
`niri`, and `hyprland` are compositors. It draws no bar, launcher, or lock
screen of its own.
_Avoid_: window manager, WM, desktop environment

**Shell**:
The layer riding on top of a Compositor that supplies the bar, launcher,
notifications, lock screen, session menu, and wallpaper. `noctalia` is the
Shell today. Exactly one Shell is active per session.
_Avoid_: bar, panel, widget system, status bar

**Desktop Environment**:
A prepackaged Compositor + Shell + application suite shipped as one unit —
`gnome`, `kde`. Mutually exclusive with running a standalone Compositor+Shell
pair.
_Avoid_: DE (when a Compositor is what is meant)

**Session**:
One selectable entry at the login manager. A Session names a Compositor and a
Shell, or names a Desktop Environment. `xorg-audio` is a Session, not a
Compositor.
_Avoid_: desktop, login option

**Theme Authority**:
The single component permitted to write a given app's appearance. Colors,
icons, fonts, and cursor each have exactly one Authority; a second writer for
the same aspect is a defect, not a fallback.
_Avoid_: theming, styling

**Live Seam**:
A file the Shell or the user may write at runtime, referenced by `include` or
`source` from a file Nix owns. It is how a setting changes without a rebuild
while the surrounding config stays declarative.
_Avoid_: override file, user config, dotfile

**Declarative Setting**:
A setting whose value is stated in Nix and reproduced on a fresh machine by a
rebuild. Contrasted with a **Runtime Setting**, which a GUI or CLI writes into
state that no rebuild reproduces.
_Avoid_: config (unqualified)
