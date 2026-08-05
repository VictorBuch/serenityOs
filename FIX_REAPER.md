# FIX_REAPER.md — Plan: Reliable REAPER + Windows VSTs (SSD5, Amplitube, TONEX) on jayne

Implementation plan for fixing the music-production stack. Execute steps in the order under "Implementation order". Per repo convention, create a jj change before each step: `jj new -m "<step>"`.

## Context

Music production on jayne works "semi well": SSD5 never worked (installer fails + iLok License Manager UI broken), most Windows VSTs are painful to set up, and plugin GUIs glitch on Wayland. Goal: `reaper` just works — plugins load, GUIs render, low latency, minimal manual steps.

Investigation found the current setup has real bugs, not just missing tweaks:

1. **`WINELOADER` env plumbing is ineffective for plugins.** nixpkgs' yabridge hardcodes its wine via `hardcode-dependencies.patch` + a `postFixup` that rewrites the winegcc wrapper. Plugins actually run under `pkgs-stable`'s yabridge wine (9.21), not the pinned 9.20. All the env-var effort in `reaper.nix` only affects installers.
2. **Dead config**: the reaper wrapper writes `~/.config/yabridge/yabridge.toml` — yabridge never reads it (it only reads tomls next to synced plugins in `~/.vst/yabridge/` etc.). The IK `editor_xembed`/`frame_rate=120` settings there never applied. The live tomls in `yabridge.nix` lack them, and the SSD5 sections are empty.
3. **Global env leak**: `environment.sessionVariables` pushes `WINEDLLOVERRIDES="d3d9,d3d10core,d3d11,dxgi=n"` + `WINELOADER` into every process — including gaming wine prefixes without DXVK (latent breakage).
4. **Stale-sync bug**: `yabridge.nix` activation runs `yabridgectl add/sync` only once ever (guarded on config.toml existence). New plugin installs / wine updates never re-sync.
5. **SSD5 root causes** (research): GUI needs dxvk but then needs **d2d1 disabled** (documented black-window fix); **iLok physical dongles do NOT work under wine** (current setup script recommends one — backwards); working recipe = **iLok Cloud + iLok License Manager 5.6.1** with msxml3/gdiplus/d3dx9-11. Current prefix is polluted (dotnet48 + wmp10/quartz/ffdshow etc. — likely the installer failure). SSD5.5 is pre-JUCE8 so it's fixable (JUCE8 D2D-1.3 plugins are not — yabridge issue #386).
6. **Yabridge/wine version wall**: stable yabridge 5.1.1 requires wine ≤9.21. Wine 10/11 support lives in the unreleased `new-wine10-embedding` branch (yabridge issue #409) — reportedly much better on wine 11, known cursor-offset quirk.
7. **GNOME 50 removed the Xorg session**; jayne's greeter is SDDM (set by mango.nix), not GDM.

Decisions made with the user: fresh-prefix SSD5 fix; **toggleable** wine track (pinned default, modern experimental); **musnix with stock kernel**; **XFCE Xorg** fallback session (GNOME Xorg impossible on this base).

## Changes

### 1. Overlay cleanup + new attrs — `overlays/default.nix`

- Rename `wine921` → `wineAudioPinned` (it is actually wine **9.20** stagingFull from `nixpkgs-wine920`); fix comments; update the consumer in `reaper.nix`.
- Add `wineAudioModern = final.wineWow64Packages.stagingFull;` (wine 11.12 at current lock; use the non-deprecated `wineWow64Packages` attr — `wineWowPackages` emits a deprecation warning).
- Add `yabridge-wine10` / `yabridgectl-wine10` from a new vendored package (step 6).

### 2. `wineTrack` option + reaper.nix restructure — `modules/apps/audio/reaper.nix`

Wrap the existing `mkModule` call to add an option (mkModule only declares `enable`; an applied mkModule is a plain module value, so `imports = [ (mkModule {...} args) ]` works):

```nix
options.apps.audio.reaper.wineTrack = lib.mkOption {
  type = lib.types.enum [ "pinned" "modern" ];
  default = "pinned";
};
# track = { wine, yabridge, yabridgectl } selected from the enum:
#   pinned = wineAudioPinned + pkgs-stable.yabridge/yabridgectl
#   modern = wineAudioModern + pkgs.yabridge-wine10/yabridgectl-wine10
```

Track switch = rebuild, not parallel commands (chainloader symlinks can only point at one build). Both tracks share `WINEPREFIX=~/.wine-audio` (preserves iLok/IK activations). Wrapper guards prefix mutation: on first modern-track launch (sentinel file absent), warn and instruct `cp -a ~/.wine-audio ~/.wine-audio.pre-wine11`.

**Wrapper (`reaper` script):**
- Delete the dead `~/.config/yabridge/yabridge.toml` block.
- Keep SWS/ReaPack symlink refresh.
- Env from `track.wine` (WINELOADER, WINEFSYNC=1, DXVK vars, `WINEDLLOVERRIDES="d3d9,d3d10core,d3d11,dxgi=n"` — d2d1 handled in prefix registry, step 3).
- Add `PIPEWIRE_LATENCY="${PIPEWIRE_LATENCY:-128/48000}"` — low latency scoped to REAPER only; desktop keeps quantum 1024.
- Add `yabridgectl sync >/dev/null 2>&1 || true` before exec (idempotent, fast — plugins stay fresh).
- Add a `makeDesktopItem` so GUI launches use the wrapper (stock `pkgs.reaper` desktop entry bypasses it today).

**linuxExtraConfig:**
- **Remove all wine/DXVK vars from `environment.sessionVariables`** (ineffective for plugins, dangerous globally).
- Keep pipewire jack + quantum config and PAM `@audio` limits (musnix's are additive/identical; optionally drop later).
- reaper.nix owns yabridge packages; drop the duplicate list from yabridge.nix.

### 3. Prefix recipe v2 + iLok fix — `setup-audio-wineprefix` rewrite in `reaper.nix`

```
setup-audio-wineprefix [--fresh] [--with-dotnet48]
```

- `--fresh`: `mv ~/.wine-audio ~/.wine-audio.bak-<date>`, rebuild. **Recommended for the current machine** — the existing prefix is polluted by dotnet48 + media codecs (plausible SSD5 installer failure cause). None of SSD5/iLok/IK need .NET (iLok LM is Qt); dotnet48 goes behind the flag only.
- Trimmed winetricks set: `win10 corefonts gdiplus msxml3 vcrun2010 vcrun2013 vcrun2022 d3dcompiler_43 d3dcompiler_47 d3dx9 d3dx10 d3dx11_43 dxvk` (drop vcrun6/2005/2008, msxml4/6, xact, xinput, wmp10/quartz/ffdshow/devenum/dm*).
- **d2d1 disable via prefix registry** (survives all launch paths, no env pollution):
  ```
  wine reg add 'HKCU\Software\Wine\DllOverrides' /v d2d1 /t REG_SZ /d "" /f
  # optional if GUIs still glitch: MaxVersionGL=0x30002 under HKCU\Software\Wine\Direct3D
  ```
- **iLok**: delete the "use physical dongle" advice (dongles don't work in wine). New `install-ilok` helper: download **iLok License Manager 5.6.1** (verify the installers.ilok.com URL at implementation time; fallback = manual download to ~/Downloads) and run via `audio-wine`. Flow = install LM → sign in → activate license to **iLok Cloud**.
- `audio-wine` / `audio-winetricks` use `track.wine`.

### 4. Consolidate yabridge config — `modules/apps/audio/yabridge.nix`

- `homeConfig` reads `osConfig.apps.audio.reaper.wineTrack` so `~/.local/share/yabridge/*` symlinks match the active track.
- Live tomls (`~/.vst/yabridge/`, `~/.vst3/yabridge/`, `~/.clap/yabridge/`):
  - IK sections gain `frame_rate = 120`, `editor_xembed = true` (moved from the dead file); add the missing `["*TONEX*"]` glob. Comment: xembed works around wayland embedding glitches; flip to false on the Xorg session if GUIs misbehave.
  - SSD5 sections: keep `["*SSD5*"]` / `["*Slate*"]` isolated (no group) + comment documenting the known in-plugin drag-drop crash (load preset kits, don't drag instruments onto the kit — not fixable from config).
  - Keep `editor_force_dnd = true`, FabFilter group + vst3 `editor_disable_host_scaling`.
- **Fix activation**: drop the once-ever guard; every HM activation loops candidate plugin dirs (`~/.wine-audio/drive_c/Program Files/{Steinberg/VstPlugins,VstPlugins,Common Files/{VST3,CLAP}}`), `yabridgectl add || true` each, then `yabridgectl sync || true`.
- Remove duplicated yabridge packages (owned by reaper.nix).

### 5. musnix — `flake.nix` + new `modules/nixos/system/audio-performance.nix` + `hosts/jayne/configuration.nix`

- Input: `musnix = { url = "github:musnix/musnix"; inputs.nixpkgs.follows = "nixpkgs"; };`
- New module in `modules/nixos/` (NOT `modules/apps/` — apps are imported by mal/darwin which must never see `musnix.*` options):
  ```nix
  # modules/nixos/system/audio-performance.nix
  { config, lib, inputs, ... }:
  {
    imports = [ inputs.musnix.nixosModules.default ];
    options.audio-performance.enable =
      lib.mkEnableOption "musnix realtime tuning on the stock kernel (threadirqs, irq priorities, performance governor)";
    config = lib.mkIf config.audio-performance.enable {
      musnix.enable = true;       # do NOT set musnix.kernel.realtime
      musnix.rtirq.enable = true; # prioritize the audio interface IRQ
    };
  }
  ```
- jayne: `audio-performance.enable = true;`
- Watch for a `vm.swappiness` sysctl conflict (jayne sets 10, musnix sets the same key) — delete jayne's duplicate line if nix errors.

### 6. Modern-track yabridge package — new `packages/yabridge-wine10/`

Vendor nixpkgs' `pkgs/tools/audio/yabridge/` (default.nix + 3 patches) following the existing `packages/` convention; `src` = pinned commit of the `new-wine10-embedding` branch; `wine` arg = `wineAudioModern`; matching `yabridgectl` (branch's `tools/yabridgectl`, new cargoHash). **Highest-risk step** — the repo's own comments record that swapping the wine arg previously broke the wineg++/meson dbus-1 cross-build. Mitigations in order:
  1. Build on the unstable toolchain via `callPackage` on unstable pkgs (not pkgs-stable).
  2. If `hardcode-dependencies.patch` won't apply, port only the WINELOADER postFixup substitution.
  3. Last resort: package the branch's CI artifact zip with autoPatchelfHook + a wrapper adding `wineAudioModern`'s `lib/wine` to the loader path.

Fully isolated: only evaluated when `wineTrack = "modern"`. Ship this step **last** — a broken modern track must not affect the pinned default.

### 7. XFCE Xorg session — new `modules/nixos/desktop-environments/xorg-audio.nix`

```nix
{ config, lib, ... }: {
  options.desktop-environments.xorg-audio.enable =
    lib.mkEnableOption "lightweight Xorg session for audio work (native X11 plugin embedding, no xwayland-satellite)";
  config = lib.mkIf config.desktop-environments.xorg-audio.enable {
    services.xserver.enable = true;
    services.xserver.desktopManager.xfce.enable = true;
  };
}
```
SDDM picks up the xsession automatically. Enable on jayne. This is the escape hatch for any residual wayland UI glitch — native X11 embedding, no xwayland-satellite.

### 8. Docs — `docs/AUDIO-PLUGIN-SETUP-GUIDE.md`

Rewrite: rebuild → `setup-audio-wineprefix --fresh` → `install-ilok` + iLok Cloud sign-in → run SSD5/IK installers via `audio-wine` → `yabridgectl sync` (also automatic) → `reaper` rescan. Document track switching + prefix backup, the SSD5 drag-drop workaround, the modern-track cursor-offset workaround (move the plugin window to recalibrate), and picking "Xfce" at SDDM for stubborn UIs.

## Implementation order

1. Steps 1 (rename + modern attr only) + 2 + 3 + 4 with paths hardcoded to pinned — fixes SSD5/iLok, hygiene, sync staleness, env leak. Highest value, lowest risk.
2. Step 5 (musnix) — independent.
3. Step 7 (XFCE session) — independent.
4. Step 8 (docs).
5. Step 6 (modern track) — risky, isolated, last.

Remember: `git add` all new files (flakes only see tracked files).

## Verification

```bash
nixos-rebuild build --flake .#jayne            # both tracks evaluate
sudo nixos-rebuild switch --flake .#jayne      # user runs, not the agent
env | grep -iE 'wine|dxvk'                     # fresh login shell: expect nothing
setup-audio-wineprefix --fresh
audio-wine reg query 'HKCU\Software\Wine\DllOverrides' /v d2d1   # empty-string override present
install-ilok                                   # then sign in, activate to iLok Cloud
audio-wine ~/Downloads/<SSD5-installer>.exe
yabridgectl sync && yabridgectl status         # all plugins listed, no version mismatch
YABRIDGE_DEBUG_LEVEL=1 reaper                  # log shows wine 9.20 per plugin host
# REAPER: rescan VST paths (~/.vst, ~/.vst3); open SSD5 (load preset kit, no drag-drop), Amplitube, TONEX
pw-top                                         # reaper client at quantum 128
grep threadirqs /proc/cmdline                  # musnix active
# SDDM → "Xfce" session → reaper → plugin GUIs (wayland-glitch escape hatch)
# later: set apps.audio.reaper.wineTrack = "modern" → rebuild → back up prefix on wrapper warning → retest
```

## Critical files

- `modules/apps/audio/reaper.nix` (major rewrite)
- `modules/apps/audio/yabridge.nix` (toml + activation fixes)
- `overlays/default.nix` (rename + new attrs)
- `flake.nix` (musnix input)
- `hosts/jayne/configuration.nix` (enable flags)
- New: `modules/nixos/system/audio-performance.nix`, `modules/nixos/desktop-environments/xorg-audio.nix`, `packages/yabridge-wine10/`, `docs/AUDIO-PLUGIN-SETUP-GUIDE.md`

## Research references

- yabridge wine-version wall + wine10 branch: https://github.com/robbert-vdh/yabridge/issues/409 (branch `new-wine10-embedding`, PR #405)
- yabridge 9.22+ GUI breakage (reason for pin): https://github.com/robbert-vdh/yabridge/issues/382
- JUCE8/Direct2D-1.3 plugins unfixable under wine: https://github.com/robbert-vdh/yabridge/issues/386
- SSD5 under wine (dxvk needed, d2d1 disable, drag-drop crash): https://forum.winehq.org/viewtopic.php?t=33683 , https://linuxmusicians.com/viewtopic.php?t=26456
- iLok under wine (Cloud works, dongle doesn't, LM 5.6.1 + msxml3/gdiplus/d3dx9-11): https://linuxmusicians.com/viewtopic.php?t=19963 , https://forum.winehq.org/viewtopic.php?t=28593
- musnix: https://github.com/musnix/musnix
