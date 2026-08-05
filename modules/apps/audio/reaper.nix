args@{
  config,
  pkgs,
  pkgs-stable,
  lib,
  mkModule,
  ...
}:

let
  cfg = config.apps.audio.reaper;

  # Wine + yabridge, chosen as a matched pair. See _wine-tracks.nix for why.
  track = (import ./_wine-tracks.nix { inherit pkgs pkgs-stable; }).${cfg.wineTrack};

  # Builds ~/.wine-audio, the prefix every Windows plugin and its copy-protection stack
  # lives in. Kept deliberately minimal: the previous recipe installed dotnet48 plus a
  # pile of legacy media codecs (wmp10, quartz, ffdshow, devenum, dm*, xact, msxml4/6),
  # and that polluted prefix is the most likely reason the SSD5 installer failed. None of
  # SSD5, iLok License Manager (Qt) or the IK installers need any of it.
  audioWinePrefixSetup = pkgs.writeShellScriptBin "setup-audio-wineprefix" ''
    set -euo pipefail

    AUDIO_WINEPREFIX="$HOME/.wine-audio"
    FRESH=0
    WITH_DOTNET48=0

    while [ $# -gt 0 ]; do
      case "$1" in
        --fresh) FRESH=1 ;;
        --with-dotnet48) WITH_DOTNET48=1 ;;
        -h|--help)
          cat <<'USAGE'
    setup-audio-wineprefix [--fresh] [--with-dotnet48]

      --fresh          Move any existing ~/.wine-audio aside and build from scratch.
                       Recommended once, to shed the old dotnet48 + media-codec prefix.
      --with-dotnet48  Also install .NET Framework 4.8. Nothing in the current plugin
                       set needs it; only add it if a specific installer demands it.
    USAGE
          exit 0
          ;;
        *) echo "unknown option: $1" >&2; exit 2 ;;
      esac
      shift
    done

    export WINEPREFIX="$AUDIO_WINEPREFIX"
    export WINEARCH="win64"
    export WINEDEBUG="-all"
    export WINELOADER="${track.wine}/bin/wine"
    export WINESERVER="${track.wine}/bin/wineserver"
    # winetricks shells out to cabextract/7z/unzip/curl; pin all of them so the recipe
    # does not depend on what happens to be on the user's PATH.
    export PATH="${track.wine}/bin:${
      lib.makeBinPath [
        pkgs-stable.winetricks
        pkgs.cabextract
        pkgs.p7zip
        pkgs.unzip
        pkgs.curl
      ]
    }:$PATH"

    echo "=== Audio WINEPREFIX setup (${cfg.wineTrack} track, ${track.wine.version or "wine"}) ==="
    echo "Target: $AUDIO_WINEPREFIX"
    echo ""

    if [ "$FRESH" = 1 ] && [ -d "$AUDIO_WINEPREFIX" ]; then
      BACKUP="$AUDIO_WINEPREFIX.bak-$(date +%Y%m%d-%H%M%S)"
      echo "--fresh: moving existing prefix to $BACKUP"
      mv "$AUDIO_WINEPREFIX" "$BACKUP"
      echo "         (plugin activations live in the prefix -- you will need to"
      echo "          re-activate via iLok Cloud / the IK Product Manager afterwards)"
      echo ""
    fi

    if [ ! -d "$AUDIO_WINEPREFIX" ]; then
      echo "[1/5] Creating 64-bit WINEPREFIX..."
      wineboot --init
      wineserver -w
    else
      echo "[1/5] WINEPREFIX exists, updating in place..."
    fi

    echo "[2/5] Windows version + fonts + core runtimes..."
    # win10:               modern installers refuse to run on anything older
    # corefonts:           plugin GUIs render text with them
    # gdiplus, msxml3:     iLok License Manager
    # vcrun2010/2013/2022: the redists SSD5 and the IK plugins actually link against
    #                      (vcrun2022 covers the whole VS2015-2022 ABI series)
    winetricks -q win10 corefonts gdiplus msxml3 vcrun2010 vcrun2013 vcrun2022

    echo "[3/5] Direct3D helper libraries..."
    winetricks -q d3dcompiler_43 d3dcompiler_47 d3dx9 d3dx10 d3dx11_43

    if [ "$WITH_DOTNET48" = 1 ]; then
      echo "[3b/5] .NET Framework 4.8 (slow, and usually unnecessary)..."
      winetricks -q dotnet48
    fi

    ${
      if cfg.wineTrack == "modern" then
        ''
          echo "[4/5] DXVK (Direct3D -> Vulkan)..."
          winetricks -q dxvk
        ''
      else
        ''
          echo "[4/5] Skipping DXVK -- unusable on the pinned wine 9.20 track."
          # wine 9.20's winevulkan does not advertise VK_KHR_surface to DXVK, which loads
          # winevulkan.dll directly rather than going through vulkan-1.dll. Every DXVK
          # release fails identically ("DxvkInstance: Required instance extensions not
          # supported"), 2.4.1 through 3.0.2, and the D3D DLLs it drops in then crash any
          # Electron GPU process that touches them. Wine's builtin wined3d works.
        ''
    }
    echo "[5/5] Direct3D renderer + d2d1..."
    # wined3d cannot create an OpenGL context in this prefix at all:
    #   err:d3d:wined3d_caps_gl_ctx_create Failed to find a suitable pixel format.
    #   err:d3d:wined3d_adapter_gl_init Failed to get a GL context for adapter ...
    # even though host GL is perfectly healthy (RX 7900 GRE, direct rendering, GL 4.6,
    # mesa 26.1) -- wine 9.20 is from Oct 2024 and does not get on with this mesa.
    # wined3d's own Vulkan backend sidesteps GL entirely and does work here. Measured:
    # Steven Slate Audio Center's Electron GPU process goes from '--use-gl=disabled'
    # plus a crash-respawn loop to '--use-gl=angle' with zero crashes.
    wine reg add 'HKCU\Software\Wine\Direct3D' /v renderer /t REG_SZ /d vulkan /f

    # wine's Direct2D implementation makes SSD5 open as a black window. Disabling d2d1
    # makes those plugins fall back to a path that works. This
    # goes in the prefix registry rather than WINEDLLOVERRIDES so it applies no matter
    # how the plugin is launched (reaper wrapper, audio-wine, yabridge host).
    #
    # NOTE: this is for SSD5 only. It has no effect on the AmpliTube editor crash --
    # that reproduces identically with d2d1 enabled and disabled.
    wine reg add 'HKCU\Software\Wine\DllOverrides' /v d2d1 /t REG_SZ /d "" /f
    # If plugin GUIs still glitch, capping the reported GL version sometimes helps:
    #   audio-wine reg add 'HKCU\Software\Wine\Direct3D' /v MaxVersionGL /t REG_DWORD /d 0x30002 /f
    wineserver -w

    echo ""
    echo "=== Setup complete ==="
    echo ""
    echo "Next:"
    echo "  1. install-ilok                      # then sign in and activate to iLok Cloud"
    echo "  2. audio-wine ~/Downloads/<installer>.exe   # SSD5, IK Product Manager, ..."
    echo "  3. yabridgectl sync                  # also runs automatically on rebuild/launch"
    echo "  4. reaper                            # then rescan ~/.vst and ~/.vst3 in REAPER"
  '';

  # iLok License Manager installer.
  #
  # Physical iLok USB dongles do NOT work under wine -- the driver is a kernel-mode
  # Windows component. iLok Cloud does work, and that is the only supported path here.
  #
  # The ilok.com download page is JS-only, but the installers themselves sit on a stable
  # CDN path. Point this at a downloaded installer (or unzip it under ~/Downloads and let
  # it be found).
  #
  # This is the one build verified to install and launch on the pinned wine 9.20 track.
  ilokInstallerUrl = "https://installers.ilok.com/iloklicensemanager/legacy/5_10/LicenseSupportInstallerWin64_v5.10.5_c55e8d80.zip";

  installIlok = pkgs.writeShellScriptBin "install-ilok" ''
    set -euo pipefail

    INSTALLER="''${1:-}"

    if [ -z "$INSTALLER" ]; then
      # PACE ships License Manager inside a "License Support" bundle, and the .exe is
      # usually two directories deep in whatever the browser unzipped. Match on both
      # names and recurse, newest first.
      INSTALLER="$(find "$HOME/Downloads" -maxdepth 4 -type f \
        \( -iname '*ilok*.exe' -o -iname '*license*support*.exe' \) \
        -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -n 1 | cut -d' ' -f2- || true)"
    fi

    if [ -z "$INSTALLER" ] || [ ! -f "$INSTALLER" ]; then
      cat <<'EOF'
    No iLok License Manager installer found.

      1. Download the known-good build (License Support Win64 v5.10.5):

         ${ilokInstallerUrl}

         Do NOT use the unversioned LicenseSupportInstallerWin.zip from the front
         page -- it is a WiX Burn v5 bundle that cannot initialize under wine
         ("Failed to load manifest as XML document", 0x80070005).
      2. Unzip it anywhere under ~/Downloads
      3. Re-run: install-ilok            (or: install-ilok /path/to/installer.exe)

    Then, once License Manager is running:
      - Sign in with your iLok account
      - Activate each license to *iLok Cloud*, not to a physical dongle.
        USB dongles do not work under wine; Cloud does.
      - Leave the Cloud session open while REAPER runs.
    EOF
      exit 1
    fi

    echo "Installing: $INSTALLER"
    echo ""
    echo "After it finishes: sign in, then activate licenses to iLok Cloud (not a dongle)."
    echo ""
    exec ${audioWine}/bin/audio-wine "$INSTALLER"
  '';

  # Helper script to run wine with audio prefix
  audioWine = pkgs.writeShellScriptBin "audio-wine" ''
    export WINEPREFIX="$HOME/.wine-audio"
    export WINEARCH="win64"
    export WINEDEBUG="-all"
    export WINEFSYNC="1"
    export WINE_LARGE_ADDRESS_AWARE="1"
    export WINELOADER="${track.wine}/bin/wine"
    export WINESERVER="${track.wine}/bin/wineserver"
    export PATH="${track.wine}/bin:$PATH"
    exec "${track.wine}/bin/wine" "$@"
  '';

  # Helper script to run winetricks with audio prefix
  audioWinetricks = pkgs.writeShellScriptBin "audio-winetricks" ''
    export WINEPREFIX="$HOME/.wine-audio"
    export WINEARCH="win64"
    export WINELOADER="${track.wine}/bin/wine"
    export WINESERVER="${track.wine}/bin/wineserver"
    export PATH="${track.wine}/bin:$PATH"
    exec ${pkgs-stable.winetricks}/bin/winetricks "$@"
  '';

  # REAPER wrapper.
  #
  # Everything wine-related lives here rather than in environment.sessionVariables:
  # WINEDLLOVERRIDES in particular must NOT be global, because it forces DXVK DLLs into
  # every wine prefix on the system, including gaming prefixes that have no DXVK
  # installed (see modules/apps/gaming/wine.nix).
  reaperWrapper = pkgs.writeShellScriptBin "reaper" ''
    # Ensure REAPER UserPlugins directory exists
    REAPER_USER_PLUGINS="$HOME/.config/REAPER/UserPlugins"
    mkdir -p "$REAPER_USER_PLUGINS"

    # Always recreate symlinks to handle nix store path changes after system updates
    ln -sf ${pkgs.reaper-reapack-extension}/UserPlugins/reaper_reapack-x86_64.so "$REAPER_USER_PLUGINS/reaper_reapack-x86_64.so"
    ln -sf ${pkgs.reaper-sws-extension}/UserPlugins/reaper_sws-x86_64.so "$REAPER_USER_PLUGINS/reaper_sws-x86_64.so"

    ${lib.optionalString (cfg.wineTrack == "modern") ''
      # First launch on the modern (wine 11) track: wine upgrades the prefix in place and
      # there is no way back. Refuse to start until the user has taken a backup.
      if [ -d "$HOME/.wine-audio" ] && [ ! -e "$HOME/.wine-audio/.wine11-ok" ]; then
        echo "!!! apps.audio.reaper.wineTrack = \"modern\" (wine 11)." >&2
        echo "!!! ~/.wine-audio will be upgraded in place and cannot be downgraded." >&2
        echo "!!! Back it up first, then re-run:" >&2
        echo "!!!   cp -a ~/.wine-audio ~/.wine-audio.pre-wine11" >&2
        echo "!!!   touch ~/.wine-audio/.wine11-ok" >&2
        exit 1
      fi
    ''}

    # Wine environment for the bridged plugin hosts.
    # NOTE: WINELOADER does not actually redirect yabridge's plugin hosts (they are linked
    # against their build-time wine); it is set so any wine tool REAPER shells out to lands
    # on the same version the prefix was built with.
    export WINELOADER="${track.wine}/bin/wine"
    export WINESERVER="${track.wine}/bin/wineserver"
    export WINEARCH="win64"
    # Overridable. "-all" silences wine's err channel too, which hides plugin-host
    # crashes completely -- a host dying mid-load then just looks like REAPER freezing.
    # `WINEDEBUG=fixme-all reaper` keeps err: without the fixme firehose.
    export WINEDEBUG="''${WINEDEBUG:--all}"
    export WINEFSYNC="1"
    export WINE_LARGE_ADDRESS_AWARE="1"

    # d2d1 is NOT listed here: it is disabled inside the prefix registry by
    # setup-audio-wineprefix, so it applies to every launch path, not just this one.
    ${lib.optionalString (cfg.wineTrack == "modern") ''
      # Force DXVK's D3D DLLs -- fixes IK Multimedia (TONEX, Amplitube) GUI refresh.
      export WINEDLLOVERRIDES="d3d9,d3d10core,d3d11,dxgi=n"
      export DXVK_HUD="0"
      export DXVK_LOG_LEVEL="none"
      export DXVK_LOG_PATH="none"
      export DXVK_STATE_CACHE_PATH="$HOME/.cache/dxvk"
    ''}

    export YABRIDGE_DEBUG_LEVEL="''${YABRIDGE_DEBUG_LEVEL:-0}"

    # Low latency for REAPER only -- the desktop keeps its 1024 quantum.
    export PIPEWIRE_LATENCY="''${PIPEWIRE_LATENCY:-128/48000}"

    # Keep bridged plugins in step with whatever is installed in the prefix.
    # Idempotent and fast; home-manager activation does the same on rebuild.
    ${track.yabridgectl}/bin/yabridgectl sync >/dev/null 2>&1 || true

    exec ${pkgs.reaper}/bin/reaper "$@"
  '';

  # pkgs.reaper is deliberately not in systemPackages (its bin/reaper would collide with
  # the wrapper), so ship a desktop entry pointing at the wrapper instead. Exec is the
  # bare name so it resolves to the wrapper on PATH; the icon is an absolute store path
  # since reaper's icon theme files are not installed either.
  reaperDesktopItem = pkgs.makeDesktopItem {
    name = "cockos-reaper";
    desktopName = "REAPER";
    comment = "Digital audio workstation";
    exec = "reaper %F";
    icon = "${pkgs.reaper}/share/icons/hicolor/256x256/apps/cockos-reaper.png";
    startupWMClass = "REAPER";
    categories = [
      "AudioVideo"
      "Audio"
      "AudioVideoEditing"
      "Recorder"
    ];
    mimeTypes = [
      "application/x-reaper-project"
      "application/x-reaper-project-backup"
      "application/x-reaper-theme"
    ];
  };
in
{
  options.apps.audio.reaper.wineTrack = lib.mkOption {
    type = lib.types.enum [
      "pinned"
      "modern"
    ];
    default = "pinned";
    description = ''
      Which wine/yabridge pair to build the audio stack against.

      "pinned" (default): wine 9.20 + yabridge 5.1.1 from nixpkgs-stable. Known-good.
      "modern": wine 11 + the vendored new-wine10-embedding yabridge. Experimental;
      upgrades ~/.wine-audio irreversibly on first launch (the wrapper refuses to start
      until you have taken a backup).

      Switching tracks is a rebuild, not a runtime toggle: the chainloaders in
      ~/.local/share/yabridge can only point at one build at a time.
    '';
  };

  imports = [
    (mkModule {
      name = "reaper";
      category = "audio";
      linuxPackages =
        { pkgs, pkgs-stable, ... }:
        [
          # Use our wrapper instead of reaper directly
          reaperWrapper
          reaperDesktopItem

          # === Wine + yabridge (matched pair, see _wine-tracks.nix) ===
          track.wine
          track.yabridge
          track.yabridgectl

          # Winetricks for installing Windows dependencies
          pkgs-stable.winetricks

          # === DXVK & Vulkan (Critical for modern plugin GUIs) ===
          pkgs.dxvk # Direct3D to Vulkan translation layer
          pkgs.vulkan-loader # Vulkan runtime (AMD RADV driver used automatically)
          pkgs.vulkan-tools # For debugging (vulkaninfo, etc.)

          # === Runtime Dependencies ===
          pkgs.cabextract # Extract Windows cab files
          pkgs-stable.wineasio # ASIO to JACK driver for Wine (stable for audio reliability)
          pkgs.p7zip # For extracting various installer formats
          pkgs.unzip # Common archive extraction
          pkgs.reaper-sws-extension
          pkgs.reaper-reapack-extension

          # === Helper Scripts ===
          audioWinePrefixSetup # setup-audio-wineprefix command
          audioWine # audio-wine command
          audioWinetricks # audio-winetricks command
          installIlok # install-ilok command
        ];

      description = "Reaper DAW with Windows VST support, DXVK, and copy protection compatibility (Linux only)";

      linuxExtraConfig = {
        # Enable JACK audio emulation via PipeWire
        services.pipewire.jack.enable = true;

        # Configure PAM limits for realtime audio.
        # musnix (audio-performance.enable) sets memlock/rtprio identically plus nofile;
        # `nice` is ours alone, and duplicate limits.conf lines are harmless.
        security.pam.loginLimits = [
          {
            domain = "@audio";
            item = "memlock";
            type = "-";
            value = "unlimited";
          }
          {
            domain = "@audio";
            item = "rtprio";
            type = "-";
            value = "99";
          }
          {
            domain = "@audio";
            item = "nice";
            type = "-";
            value = "-20";
          }
        ];

        # Low-latency PipeWire configuration for professional audio.
        # The default quantum stays desktop-friendly; the reaper wrapper drops its own
        # client to 128 via PIPEWIRE_LATENCY.
        # Keys must be quoted strings to preserve dot-notation in the generated JSON,
        # otherwise Nix expands them into nested objects that PipeWire ignores.
        services.pipewire.extraConfig.pipewire."10-low-latency" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 1024;
            "default.clock.min-quantum" = 32;
            "default.clock.max-quantum" = 8192;
          };
        };

        # JACK-specific PipeWire configuration
        services.pipewire.extraConfig.jack."20-realtime" = {
          "jack.properties" = {
            # Match PipeWire's sample rate
            "node.latency" = "64/48000";
            # Enable realtime scheduling
            "jack.realtime" = true;
            "jack.realtime-priority" = 88;
          };
        };

        users.users.${config.user.userName}.extraGroups = [ "audio" ];

        # NOTE: no environment.sessionVariables here on purpose. WINELOADER never reached
        # the bridged plugin hosts (they are linked against their build-time wine), and
        # WINEDLLOVERRIDES leaked DXVK into every wine prefix on the system. All of it now
        # lives in the reaper wrapper, scoped to REAPER, or in the prefix registry.
      };
    } args)
  ];
}
