# Audio Plugin Setup Guide — REAPER + Windows VSTs on jayne

How to get Windows plugins (SSD5, Amplitube, TONEX, T-RackS, FabFilter …) running in
REAPER through wine + yabridge.

Everything here is driven by `modules/apps/audio/reaper.nix` and
`modules/apps/audio/yabridge.nix`. The commands below come from those modules; you never
need to set `WINEPREFIX` or `WINELOADER` by hand.

---

## The short version

```bash
sudo nixos-rebuild switch --flake .#jayne   # then log out and back in
setup-audio-wineprefix --fresh              # ~15 min, builds ~/.wine-audio from scratch
install-ilok                                # then sign in → activate to iLok Cloud
audio-wine ~/Downloads/<SSD5-installer>.exe # and any other plugin installers
yabridgectl sync                            # also runs automatically, see below
reaper                                      # then rescan ~/.vst and ~/.vst3 in REAPER
```

---

## How the pieces fit together

| Command                  | What it is                                                       |
| ------------------------ | ---------------------------------------------------------------- |
| `setup-audio-wineprefix` | Builds/updates `~/.wine-audio`, the prefix all plugins live in    |
| `audio-wine`             | Runs any `.exe` inside that prefix with the right wine            |
| `audio-winetricks`       | winetricks against that prefix (e.g. `audio-winetricks winecfg`)  |
| `install-ilok`           | Installs iLok License Manager into that prefix                    |
| `yabridgectl`            | Generates the Linux `.so`/`.vst3` stubs REAPER actually loads     |
| `reaper`                 | Wrapper: sets the wine/DXVK env, syncs yabridge, then launches    |

`reaper` is a wrapper script, not stock REAPER. Launching REAPER any other way (including
from a desktop file you made yourself) skips the environment it sets up. The desktop entry
shipped by the module points at the wrapper, so the app launcher is fine.

**yabridge stays in sync automatically.** `yabridgectl add` + `yabridgectl sync` run on
every home-manager activation (i.e. every `nixos-rebuild switch`) and again every time you
run `reaper`. You only need to run `yabridgectl sync` by hand if you install a plugin and
want it available without restarting REAPER.

---

## First-time setup

### 1. Build the wine prefix

```bash
setup-audio-wineprefix --fresh
```

`--fresh` moves any existing `~/.wine-audio` to `~/.wine-audio.bak-<timestamp>` and starts
over. **Do this once**: the old prefix carried .NET 4.8 plus a pile of legacy media codecs
(wmp10, quartz, ffdshow, devenum, dm\*, xact, msxml4/6), which is the most likely reason
the SSD5 installer used to fail. The new recipe installs only what the current plugin set
needs:

- `win10`, `corefonts`
- `gdiplus`, `msxml3` — iLok License Manager
- `vcrun2010`, `vcrun2013`, `vcrun2022`
- `d3dcompiler_43/47`, `d3dx9`, `d3dx10`, `d3dx11_43`
- `dxvk` — Direct3D → Vulkan, required for SSD5 and the JUCE-based IK GUIs
- a registry override disabling `d2d1` (see below)

If some installer genuinely demands .NET, re-run with `--with-dotnet48`.

Activations live inside the prefix, so after `--fresh` you have to re-activate everything.

### 2. iLok — Cloud only

```bash
install-ilok
```

Download iLok License Manager (**5.6.1** is the last version known to work under wine)
from <https://www.ilok.com/#!license-manager> into `~/Downloads` first; `install-ilok`
picks it up from there, or takes a path: `install-ilok /path/to/installer.exe`.

Then, in License Manager: sign in, and activate each license to **iLok Cloud**.

> **Physical iLok USB dongles do not work under wine.** The dongle driver is a kernel-mode
> Windows component wine has no equivalent for. iLok Cloud is the only path that works —
> keep the Cloud session open while REAPER runs.

### 3. Install the plugins

```bash
audio-wine ~/Downloads/<installer>.exe
```

Accept the default install paths — `yabridgectl` looks in
`C:\Program Files\{Steinberg\VstPlugins, VstPlugins, Common Files\VST3, Common Files\CLAP}`
inside the prefix.

For IK plugins, install **IK Product Manager first**, then the plugins through it. The
Product Manager installs the licensing DLLs the plugins refuse to load without:

```bash
audio-wine ~/Downloads/IK_Product_Manager_*.exe
audio-wine "$HOME/.wine-audio/drive_c/Program Files (x86)/IK Multimedia/IK Product Manager/IK Product Manager.exe"
```

### 4. Point REAPER at them

Options → Preferences → Plug-ins → VST → make sure `~/.vst` and `~/.vst3` are in the
search path, then "Clear cache and re-scan".

---

## Known quirks

### SSD5: don't drag instruments onto the kit

Dragging an instrument from SSD5's own browser onto the kit crashes the plugin under wine.
Load preset kits instead. This is a plugin-side bug and cannot be worked around from
yabridge config.

### SSD5 opens as a black window

That is the Direct2D path. `setup-audio-wineprefix` already disables `d2d1` in the prefix
registry, which fixes it:

```bash
audio-wine reg query 'HKCU\Software\Wine\DllOverrides' /v d2d1   # should exist, empty value
```

If GUIs still glitch, try capping the reported GL version:

```bash
audio-wine reg add 'HKCU\Software\Wine\Direct3D' /v MaxVersionGL /t REG_DWORD /d 0x30002 /f
```

### IK plugin GUIs freeze or stop repainting

They are configured with `editor_xembed = true` and `frame_rate = 120` in
`~/.vst/yabridge/yabridge.toml` (generated by `modules/apps/audio/yabridge.nix`). If they
misbehave on the Xorg session specifically, xembed is the thing to turn off there.

### Anything Wayland-related: use the Xorg session

Plugin editors are X11 windows that yabridge embeds into REAPER's window. Under Wayland
that goes through XWayland and the embedding is where things break. Log out, pick **Xfce**
at the SDDM session menu, and run `reaper` there — embedding is native and none of it
applies. (GNOME 50 removed its own Xorg session, which is why the escape hatch is XFCE.)

### JUCE 8 plugins

Plugins built with JUCE 8 use Direct2D 1.3, which wine does not implement — they cannot be
made to work at any wine version ([yabridge#386]). SSD5.5 predates JUCE 8, so it is fine.

### `wine client error:0: version mismatch`

Stale wineserver from a different wine version:

```bash
audio-wine wineboot -k    # kills the prefix's wineserver
```

Wait a few seconds and retry.

---

## Switching the wine track

The whole stack is pinned to **wine 9.20 + yabridge 5.1.1**, because yabridge 5.1.1
requires wine ≤ 9.21 and wine 9.22+ breaks plugin GUIs ([yabridge#382]). Wine 10/11
support lives in yabridge's unreleased `new-wine10-embedding` branch ([yabridge#409]),
packaged here as `packages/yabridge-wine10`.

In `hosts/jayne/configuration.nix`:

```nix
apps.audio.reaper.wineTrack = "modern";   # default is "pinned"
```

then rebuild. Both tracks share `~/.wine-audio`, so activations survive the switch — but
**wine 11 upgrades the prefix irreversibly on first launch**. The `reaper` wrapper refuses
to start until you have taken a backup:

```bash
cp -a ~/.wine-audio ~/.wine-audio.pre-wine11
touch ~/.wine-audio/.wine11-ok
```

Switching tracks is a rebuild, not a runtime toggle — the chainloaders in
`~/.local/share/yabridge` can only point at one build at a time.

Known modern-track limitations:

- The mouse cursor can be offset inside plugin editors. Moving the plugin window
  recalibrates it.
- **No 32-bit Windows plugins.** The pinned track comes from nixpkgs 25.11, which still
  builds yabridge's 32-bit bitbridge host; the modern track is built from unstable's
  expression, which does not. If any of your plugins are 32-bit, stay on `pinned`.

---

## Realtime tuning

`audio-performance.enable = true` on jayne turns on [musnix] against the **stock** kernel
(no PREEMPT_RT): the `threadirqs` boot parameter, `rtirq` IRQ-thread priorities, `@audio`
rlimits, and the CPU governor.

Note this sets the CPU governor to `performance` **system-wide**, not just while a DAW is
running — musnix defines it without `mkDefault`, so it overrides the `schedutil` default
from `modules/nixos/system/amd-gpu.nix`.

REAPER itself runs at a 128-frame quantum via `PIPEWIRE_LATENCY`, set by the wrapper. The
rest of the desktop stays at 1024, so nothing else pays for the low latency.

```bash
grep threadirqs /proc/cmdline           # musnix active
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
pw-top                                  # REAPER's client should show quantum 128
```

---

## Debugging

```bash
YABRIDGE_DEBUG_LEVEL=1 reaper           # per-plugin init log
yabridgectl status                      # every plugin, and any version mismatch
audio-wine --version
audio-winetricks list-installed
cat ~/.vst/yabridge/yabridge.toml       # generated; edit yabridge.nix, not this
env | grep -iE 'wine|dxvk'              # in a normal shell: expect nothing
```

A healthy plugin logs:

```
[PluginName-XXXXX] Initializing yabridge version 5.1.1
[PluginName-XXXXX] wine version: '9.20 (Staging)'
[PluginName-XXXXX] Finished initializing
```

`env | grep wine` returning nothing is **correct**. Wine variables used to be set globally
via `environment.sessionVariables`, which did nothing for bridged plugins (they run under
the wine their yabridge was built against) while leaking `WINEDLLOVERRIDES` — forcing DXVK
DLLs — into every other wine prefix on the system, including gaming ones without DXVK
installed. It is all scoped to the `reaper` wrapper now.

If a plugin fails with `LoadLibrary failed: Module not found`, its authorization software
is missing or not signed in — check iLok License Manager / IK Product Manager first.

[musnix]: https://github.com/musnix/musnix
[yabridge#382]: https://github.com/robbert-vdh/yabridge/issues/382
[yabridge#386]: https://github.com/robbert-vdh/yabridge/issues/386
[yabridge#409]: https://github.com/robbert-vdh/yabridge/issues/409
