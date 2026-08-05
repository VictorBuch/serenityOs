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

  # === Wine tracks ===
  #
  # yabridge's plugin hosts run under whatever wine the yabridge *build* was linked
  # against -- nixpkgs hardcodes it via hardcode-dependencies.patch plus a postFixup
  # that rewrites the winegcc wrapper. Setting WINELOADER in the environment only
  # affects installers and standalone apps, never the bridged plugins. So wine and
  # yabridge have to be selected as a matched pair, and switching between them is a
  # rebuild rather than a runtime flag: the chainloaders in ~/.local/share/yabridge
  # can only point at one build at a time.
  #
  # Both tracks share WINEPREFIX=~/.wine-audio so iLok/IK activations survive a switch.
  tracks = {
    # Wine 9.20 + yabridge 5.1.1 from stable. yabridge 5.1.1 requires wine <= 9.21 and
    # 9.22+ breaks plugin GUIs: https://github.com/robbert-vdh/yabridge/issues/382
    pinned = {
      wine = pkgs.wineAudioPinned;
      yabridge = pkgs-stable.yabridge;
      yabridgectl = pkgs-stable.yabridgectl;
    };
    # Wine 11 + yabridge's unreleased new-wine10-embedding branch (packages/yabridge-wine10).
    # Experimental: better on wine 11 overall, but has a known cursor-offset quirk.
    # https://github.com/robbert-vdh/yabridge/issues/409
    modern = {
      wine = pkgs.wineAudioModern;
      yabridge = pkgs.yabridge-wine10;
      yabridgectl = pkgs.yabridgectl-wine10;
    };
  };
  track = tracks.${cfg.wineTrack};

  # WINEPREFIX setup script for audio plugins with copy protection support
  # This script initializes a dedicated prefix for audio work
  audioWinePrefixSetup = pkgs.writeShellScriptBin "setup-audio-wineprefix" ''
    set -e

    AUDIO_WINEPREFIX="$HOME/.wine-audio"
    export WINEPREFIX="$AUDIO_WINEPREFIX"
    export WINEARCH="win64"
    export WINEDEBUG="-all"
    export WINELOADER="${track.wine}/bin/wine"
    export WINESERVER="${track.wine}/bin/wineserver"
    export PATH="${track.wine}/bin:$PATH"

    echo "=== Audio WINEPREFIX Setup Script ==="
    echo "Target: $AUDIO_WINEPREFIX"
    echo ""

    # Create prefix if it doesn't exist
    if [ ! -d "$AUDIO_WINEPREFIX" ]; then
      echo "[1/7] Creating new 64-bit WINEPREFIX..."
      wineboot --init
      sleep 5
    else
      echo "[1/7] WINEPREFIX already exists, updating..."
    fi

    # Set Windows version to Windows 10 (required for modern installers)
    echo "[2/7] Setting Windows version to Windows 10..."
    winetricks -q win10

    # Install core fonts (required for proper text rendering in plugins)
    echo "[3/7] Installing core fonts..."
    winetricks -q corefonts

    # Install .NET Framework 4.8 (required for iLok License Manager)
    echo "[4/7] Installing .NET Framework 4.8 (this may take a while)..."
    winetricks -q dotnet48

    # Install Visual C++ runtimes (required by many plugins)
    # Install all versions to maximize compatibility
    echo "[5/7] Installing Visual C++ runtimes (this may take a while)..."
    winetricks -q vcrun6 vcrun2005 vcrun2008 vcrun2010 vcrun2012 vcrun2013 vcrun2015 vcrun2019

    # Install GDI+ and other Windows components
    echo "[6/7] Installing additional Windows components..."
    winetricks -q gdiplus msxml3 msxml4 msxml6 d3dx9 d3dcompiler_43 d3dcompiler_47 \
      xact xact_x64 xinput ffdshow quartz wmp10 devenum dmsynth dsdmo dswave msdxmocx

    # Install DXVK for better Direct3D performance (uses Vulkan)
    # This fixes UI refresh issues with JUCE-based plugins (Amplitube, TONEX, etc.)
    echo "[7/7] Installing DXVK..."
    winetricks -q dxvk

    echo ""
    echo "=== Setup Complete ==="
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
    export WINEDEBUG="-all"
    export WINEFSYNC="1"
    export WINE_LARGE_ADDRESS_AWARE="1"

    # Force DXVK's D3D DLLs -- fixes IK Multimedia (TONEX, Amplitube) GUI refresh.
    # d2d1 is NOT listed here: it is disabled inside the prefix registry by
    # setup-audio-wineprefix, so it applies to every launch path, not just this one.
    export WINEDLLOVERRIDES="d3d9,d3d10core,d3d11,dxgi=n"
    export DXVK_HUD="0"
    export DXVK_LOG_LEVEL="none"
    export DXVK_LOG_PATH="none"
    export DXVK_STATE_CACHE_PATH="$HOME/.cache/dxvk"

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

          # === Wine + yabridge (matched pair, see `tracks` above) ===
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
