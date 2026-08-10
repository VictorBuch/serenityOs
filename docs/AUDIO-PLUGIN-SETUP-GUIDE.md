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
| `reaper`                 | Wrapper: sets the wine env, syncs yabridge, then launches          |

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
- `dxvk` — **modern track only.** See "DXVK does not work on the pinned track" below
- a registry override disabling `d2d1` (see below)

If some installer genuinely demands .NET, re-run with `--with-dotnet48`.

Activations live inside the prefix, so after `--fresh` you have to re-activate everything.

### 2. iLok — Cloud only

```bash
install-ilok
```

Download **License Support Win64 v5.10.5** and unzip it anywhere under `~/Downloads`
first; `install-ilok` searches four levels deep for `*ilok*.exe` / `*license*support*.exe`
and takes the newest, or takes a path: `install-ilok /path/to/installer.exe`.

```
https://installers.ilok.com/iloklicensemanager/legacy/5_10/LicenseSupportInstallerWin64_v5.10.5_c55e8d80.zip
```

> **Do not use the unversioned `LicenseSupportInstallerWin.zip`** linked from the front
> page. It is a WiX Burn v5 bootstrapper and dies before unpacking anything, leaving only
> `%TEMP%\Setup_<timestamp>_Failed.log`:
>
> ```
> e000: Error 0x80070005: Failed to load manifest as XML document.
> e000: Error 0x80070005: Failed to initialize core.
> ```
>
> Installing `msxml6` does not help. The versioned v5.10.5 build uses different packaging
> and installs normally. (The Win32 v5.5.2 build exits 0 and installs nothing on a win64
> prefix — use the Win64 one.)

Then, in License Manager: sign in, and activate each license to **iLok Cloud**.

> **Physical iLok USB dongles do not work under wine.** The dongle driver is a kernel-mode
> Windows component wine has no equivalent for. iLok Cloud is the only path that works —
> keep the Cloud session open while REAPER runs.

### 3. Install the plugins

```bash
audio-wine ~/Downloads/<installer>.exe
```

Accept the default install paths — `yabridgectl` looks in
`C:\Program Files\{Steinberg\VstPlugins, VstPlugins, VstPlugIns, Common Files\VST3,
Common Files\CLAP}` inside the prefix.

Both spellings of `VstPlugins`/`VstPlugIns` are watched on purpose: `drive_c` is a real
Linux tree, so those are two different directories even though Windows treats them as one.
Wine writes into whichever spelling already exists, so which one an installer lands in
depends on who created it first. Watching only one is how AmpliTube's VST2 sat unbridged
in `VstPlugIns` while its VST3 worked fine.

#### SSD5 / Steven Slate Audio Center

SSD5 is installed by **Steven Slate Audio Center**, not by a standalone installer, and it
puts *both* formats in the VST3 folder — the VST2 `.dll` included:

```
C:\Program Files\Common Files\VST3\SSDSampler5.vst3   (VST3, legacy, 64-bit)
C:\Program Files\Common Files\VST3\SSDSampler5.dll    (VST2, 64-bit)
```

Both are 64-bit (PE machine type `0x8664`), so both bridge on either track. That directory
is already watched, so `yabridgectl sync` picks them up with no extra `add`.

**The sample library does not go in the prefix.** It is plain data the plugin reads at
runtime, and wine can see the whole filesystem. SSD5 stores its location in
`~/.wine-audio/drive_c/users/jayne/AppData/Roaming/ssd_sampler5/ssd_sampler5.ini`:

```xml
<VALUE name="SamplerBaseDirectory" val="C:\users\jayne\Documents\Music\SSD5Library"/>
```

`drive_c/users/<user>/Documents` is a symlink to the real `~/Documents`, so that resolves
to `~/Documents/Music/SSD5Library` on the Linux side. Point it at wherever the library
already lives rather than copying 15 GB into `drive_c` — that would only bloat the prefix
and every backup of it. Anything under `$HOME` is also reachable as `Z:\home\<user>\…`.

For IK plugins, install **IK Product Manager first**, then the plugins through it. The
Product Manager installs the licensing DLLs the plugins refuse to load without:

```bash
audio-wine ~/Downloads/IK_Product_Manager_*.exe
ik-product-manager
```

`ik-product-manager` and `slate-audio-center` find the executable in either of the paths
each vendor installs to, refuse to start a second instance behind a wedged first one, and
pass the flags those apps need under wine. Prefer them over calling `audio-wine` on the
`.exe` by hand.

### 4. Point REAPER at them

Options → Preferences → Plug-ins → VST → make sure `~/.vst` and `~/.vst3` are in the
search path, then "Clear cache and re-scan".

The re-scan is not optional after a prefix rebuild. REAPER caches *failed* scans and will
not retry them on its own, so a correctly installed, correctly synced plugin stays
invisible until the cache is cleared — see "REAPER caches failed plugin scans" below.

---

## Known quirks

### DXVK does not work on the pinned track

On wine 9.20, DXVK loads `winevulkan.dll` directly instead of going through
`vulkan-1.dll`, and that winevulkan does not advertise `VK_KHR_surface`. Every DXVK
release fails identically — 2.4.1, 2.5.2 and 3.0.2 all tested:

```
info:  Vulkan: Found vkGetInstanceProcAddr in winevulkan.dll
info:  Required Vulkan extension VK_KHR_surface not supported
err:   DxvkInstance: Required instance extensions not supported
```

The host side is not the problem (`radeon_icd`, Vulkan 1.4.350, all surface extensions
present) — it is the wine boundary. Worse, the native D3D DLLs DXVK drops in then crash
any Electron GPU process that touches them with `0xC0000005`, in a respawn loop: that is
what a Steven Slate Audio Center or IK Product Manager window stuck black actually is.

So `setup-audio-wineprefix` installs DXVK only on the `modern` track, and the `reaper`
wrapper only sets `WINEDLLOVERRIDES=d3d9,d3d10core,d3d11,dxgi=n` there. On `pinned`,
wine's builtin wined3d handles D3D and Electron apps render.

If you inherited a prefix that already has DXVK forced, drop the overrides — the DLLs can
stay on disk:

```bash
for d in d3d11 d3d10core dxgi d3d9 d3d8; do
  audio-wine reg delete 'HKCU\Software\Wine\DllOverrides' /v "*$d" /f
done
```

What DXVK was actually for here is **still unknown**. With DXVK absent, AmpliTube 5 gets
as far as creating its editor — `setProcessing` and `createView` both succeed — and then
hangs at `IPlugView::attached`. That hang is an editor-embedding problem (see "IK plugins
hang REAPER on load"), and it is not known whether DXVK ever affected it, because DXVK has
never successfully initialized on this machine in either configuration.

What is established: DXVK cannot run on the pinned track at all, and its DLLs actively
break Electron apps. That is reason enough not to install it here. It is *not* evidence
that plugins do not want it.

SSD5 is untested — it is not installed in the current prefix.

### IK Product Manager opens a black window

Different cause from the DXVK one above, and it survives onto the `modern` track. The
launcher passes `--disable-gpu`, which fixes it.

Chromium's GPU process starts, answers version queries and looks healthy, so the usual
"is Vulkan/GL working" checks all pass. What fails is the command buffer channel between
renderer and GPU process:

```
ERROR:command_buffer_proxy_impl.cc(122)] ContextResult::kTransientFailure:
    Failed to send GpuChannelMsg_CreateCommandBuffer
```

The window is created but never mapped — `xwininfo -id <win>` reports `IsUnMapped` for
every one of its top-levels, because the app waits on `ready-to-show` and the renderer
never gets there. Measured on the same prefix, back to back:

| | first IPC (`e:REQUEST`) | window | outcome |
|---|---|---|---|
| default | t+133s | never `IsViewable` | process dies |
| `--disable-gpu` | t+3s | shows, renders | works |

Note what the failure is *not*: the app is not crashing on startup and it is not stuck on
JavaScript. `document.readyState` sits at `"loading"` with a null `document.body` for
minutes. To see that for yourself, launch with `--remote-debugging-port=9222` and query
the renderer over CDP — `curl -s http://127.0.0.1:9222/json` lists the pages, and
`Runtime.evaluate` against the page's `webSocketDebuggerUrl` reads its actual state. That
is far more direct than guessing from a blank window.

Steven Slate Audio Center does **not** need this flag; it renders through the
`renderer=vulkan` wined3d setting `setup-audio-wineprefix` applies. Add `--disable-gpu` to
`slate-audio-center` only if it ever regresses.

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

### IK plugins hang REAPER on load

Adding AmpliTube hangs REAPER outright. The bridge log ends on the editor-embedding call,
with no reply — every other call gets one on the next line:

```
[host -> plugin] >> 1: IEditController::createView(name = "editor")   <IPlugView*>
[host -> plugin] >> 1: IPlugView::attached(parent = …, "X11EmbedWindowID")
                                                              ← log ends here
```

and the processes settle into:

```
SLl+  futex_do_wait     .reaper-wrapped            <- blocked
S+    anon_pipe_read    start.exe                  <- its wine child
Zl+   —                 yabridge-host.e <defunct>  <- dead, reparented to init
```

Reaching `attached` looks like a successful load and is not one — check for the reply, not
for the call.

`editor_xembed = true` (real X11 embedding instead of yabridge's default reparenting) is
the documented remedy and is what the IK sections now set. **Whether it fixes this is
unverified.** If it does not, the next lever is `editor_coordinate_hack`, then trying a
Wayland session.

Do not try to rescue a frozen REAPER by killing the wine host — that takes REAPER down
with it and loses unsaved work.

### REAPER caches *failed* plugin scans, and never retries them

A plugin that is correctly installed and correctly synced can still be invisible in
REAPER, because REAPER remembers that a scan failed and does not try again. This is what
made SSD5 look broken after the prefix was rebuilt: the old stub was orphaned, REAPER
scanned it once, got nothing, and cached that.

The tell is in `~/.config/REAPER/reaper-vstplugins64.ini`. Compare a failed entry with a
good one:

```
SSDSampler5.vst3=80D63A13F663DC01                      <- timestamp only: scan FAILED
AmpliTube_5.vst3=001B6F38DD63DC01,1566108953{5653...},AmpliTube 5 (IK Multimedia)
```

A healthy entry carries a UID and a display name; instruments also get `!!!VSTi`. Bare
timestamp means "scanned, yielded nothing" — and it is sticky. `yabridgectl status` will
happily report the plugin as `synced` the whole time, because the sync genuinely worked.

Fix it from the GUI with Preferences → Plug-ins → VST → **Clear cache and re-scan**, or
surgically, which avoids rescanning everything:

```bash
cp ~/.config/REAPER/reaper-vstplugins64.ini{,.bak}      # REAPER must be closed
grep -vi "SSDSampler5" ~/.config/REAPER/reaper-vstplugins64.ini > /tmp/vst.tmp
cp /tmp/vst.tmp ~/.config/REAPER/reaper-vstplugins64.ini
```

Then start REAPER and check the entry came back populated. After any
`setup-audio-wineprefix --fresh`, or any `yabridgectl sync --prune`, assume every plugin
whose stub changed identity needs this.

### yabridge.toml sections that silently match nothing

A section matching no plugin is not an error; the plugin quietly falls through to `["*"]`.
Two ways to hit it, both of which happened here and each of which cost a wrong diagnosis:

1. **The globs are case-sensitive.** `["*Amplitube*"]` never matches `AmpliTube`.
2. **They match the bridged path, not the bundle name.** For a VST3 bundle that path is
   `AmpliTube 5.vst3/Contents/x86_64-linux/AmpliTube 5.so` — so any pattern ending in
   `.vst3` matches nothing. Use `["*AmpliTube*"]`, never `["*AmpliTube*.vst3"]`.

Never assume a section applied. Verify:

```bash
YABRIDGE_DEBUG_LEVEL=1 reaper 2>&1 | grep -E "config from|other options"
```

`config from: … section "*"` means your section did **not** match.

### `group = …` does not work in this build

Group hosting needs `yabridge-group-host.exe`, and the packaged yabridge ships only
`yabridge-host.exe` and `yabridge-host-32.exe`. The `group` keys were removed from all
three tomls for that reason — they had never been reachable anyway, thanks to the
matching bugs above.

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

**jayne runs `modern` (wine 11.14).** The `pinned` track (wine 9.20 + yabridge 5.1.1)
exists because yabridge 5.1.1 requires wine ≤ 9.21 and wine 9.22+ breaks plugin GUIs
([yabridge#382]) — but 9.20 is from Oct 2024 and fails three separate ways against a
current system (mesa 26.1, kernel 6.18): DXVK cannot create a Vulkan instance, wined3d
cannot create a GL context, and opening AmpliTube's editor stack-overflows inside wine's
`ntdll` and kills the plugin host. All three are gone on `modern`, where AmpliTube loads
and its editor opens. Wine 10/11 support lives in yabridge's unreleased
`new-wine10-embedding` branch ([yabridge#409]), packaged here as `packages/yabridge-wine10`.

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

### Migrating an existing prefix, pinned → modern

The tracks differ in wine **flavour**, not just version:

| track | attr | WoW64 |
| --- | --- | --- |
| pinned | `wineWowPackages.stagingFull` (9.20) | old-style, real 32-bit builtins |
| modern | `wineWow64Packages.stagingFull` (11.x) | new WoW64 |

The prefix layouts differ, and a prefix built by the old flavour does **not** cleanly
upgrade. Two failures show up in this order, both of which look like the plugin is
broken when nothing is wrong with it.

**1. `wine client error:0: version mismatch 844/958`**

An old-flavour `wineserver` is still running and holding the prefix — usually a wine app
you left open (Steven Slate Audio Center, IK Product Manager, a stray installer). The new
client cannot talk to it. Note `wineserver -k` from the *new* wine will not kill it either,
for the same reason. Find it by binary and kill it:

```bash
for p in $(pgrep -x wineserver); do echo "$p -> $(readlink -f /proc/$p/exe)"; done
pkill -9 -x wineserver     # once you have confirmed which one it is
```

**2. `module not found for forward 'cryptbase.SystemFunction036' used by advapi32.dll`**

The plugin host exits immediately. `cryptbase.dll` does not exist in an old-flavour
prefix, and `wineboot -u` **cannot install it** — the update itself calls
`SystemFunction036`, which forwards to the very DLL it would be installing. It aborts with
`Call from … to unimplemented function advapi32.dll.SystemFunction036`. Break the
deadlock by hand, using the wine the modern track resolves to:

```bash
w=$(dirname $(dirname $(grep -o '/nix/store/[^/]*wine[^/]*/bin/wine' \
      /run/current-system/sw/bin/audio-wine | head -1)))
cp -n "$w/lib/wine/x86_64-windows/cryptbase.dll" ~/.wine-audio/drive_c/windows/system32/
cp -n "$w/lib/wine/i386-windows/cryptbase.dll"   ~/.wine-audio/drive_c/windows/syswow64/
audio-wine wineboot -u        # now completes silently
```

After that the prefix is a working wine 11 prefix and plugins load normally. A fresh
`setup-audio-wineprefix --fresh` on the modern track produces a correct prefix directly
and needs none of this — the workaround is only for carrying an existing prefix across.

Known modern-track limitations:

- The mouse cursor can be offset inside plugin editors. Moving the plugin window
  recalibrates it.
- **No 32-bit Windows plugins.** The pinned track comes from nixpkgs 25.11, which still
  builds yabridge's 32-bit bitbridge host; the modern track is built from unstable's
  expression, which does not. If any of your plugins are 32-bit, stay on `pinned`.

The tracks also differ in D3D: DXVK is installed and forced only on `modern`, because it
cannot initialize at all on `pinned`. See "DXVK does not work on the pinned track".

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
