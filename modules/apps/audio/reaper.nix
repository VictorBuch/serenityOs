args@{
  config,
  pkgs,
  lib,
  inputs ? null,
  isLinux,
  mkApp,
  ...
}:

let
  # Use Wine Staging 9.20 Full - required for audio plugins and copy protection
  # Wine 9.22+ has GUI issues with yabridge: https://github.com/robbert-vdh/yabridge/issues/382
  # This uses a pinned Wine 9.20 stagingFull from the overlay (includes all dependencies)
  wineStaging = pkgs.wine921;

  # WINEPREFIX setup script for audio plugins with copy protection support
  # This script initializes a dedicated prefix for audio work
  audioWinePrefixSetup = pkgs.writeShellScriptBin "setup-audio-wineprefix" ''
    #!/usr/bin/env bash
    set -e

    AUDIO_WINEPREFIX="$HOME/.wine-audio"
    export WINEPREFIX="$AUDIO_WINEPREFIX"
    export WINEARCH="win64"
    export WINEDEBUG="-all"
    export WINELOADER="${wineStaging}/bin/wine"
    export WINESERVER="${wineStaging}/bin/wineserver"
    export PATH="${wineStaging}/bin:$PATH"

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
    echo "[7/7] Installing DXVK..."
    setup_dxvk install --symlink

    echo ""
    echo "=== Setup Complete ==="
    echo ""
    echo "Next steps:"
    echo "1. Set WINEPREFIX=$AUDIO_WINEPREFIX when running audio installers"
    echo "2. Download and install iLok License Manager from: https://www.ilok.com/"
    echo "3. Download and install IK Product Manager from: https://www.ikmultimedia.com/"
    echo "4. Install your VST plugins (SSD5, Amplitube 5, etc.)"
    echo "5. Run: yabridgectl add \"$AUDIO_WINEPREFIX/drive_c/Program Files/Steinberg/VstPlugins\""
    echo "6. Run: yabridgectl add \"$AUDIO_WINEPREFIX/drive_c/Program Files/Common Files/VST3\""
    echo "7. Run: yabridgectl sync"
    echo ""
    echo "To run installers in this prefix:"
    echo "  WINEPREFIX=$AUDIO_WINEPREFIX wine /path/to/installer.exe"
    echo ""
    echo "IMPORTANT: Use a physical iLok USB dongle if cloud authorization fails."
  '';

  # Helper script to run wine with audio prefix
  audioWine = pkgs.writeShellScriptBin "audio-wine" ''
    #!/usr/bin/env bash
    export WINEPREFIX="$HOME/.wine-audio"
    export WINEARCH="win64"
    export WINEDEBUG="-all"
    export WINEFSYNC="1"
    export WINE_LARGE_ADDRESS_AWARE="1"
    export WINELOADER="${wineStaging}/bin/wine"
    export WINESERVER="${wineStaging}/bin/wineserver"
    export PATH="${wineStaging}/bin:$PATH"
    exec "${wineStaging}/bin/wine" "$@"
  '';

  # Helper script to run winetricks with audio prefix
  audioWinetricks = pkgs.writeShellScriptBin "audio-winetricks" ''
    #!/usr/bin/env bash
    export WINEPREFIX="$HOME/.wine-audio"
    export WINEARCH="win64"
    export WINELOADER="${wineStaging}/bin/wine"
    export WINESERVER="${wineStaging}/bin/wineserver"
    export PATH="${wineStaging}/bin:$PATH"
    exec winetricks "$@"
  '';

  # REAPER wrapper that ensures Wine 9.20 is used for yabridge
  # This is more reliable than environment.sessionVariables for all shells
  # Also handles automatic installation of ReaPack and SWS extensions
  reaperWrapper = pkgs.writeShellScriptBin "reaper" ''
    #!/usr/bin/env bash
    
    # Ensure REAPER UserPlugins directory exists
    REAPER_USER_PLUGINS="$HOME/.config/REAPER/UserPlugins"
    mkdir -p "$REAPER_USER_PLUGINS"
    
    # Install ReaPack extension if not already present or broken
    REAPACK_SO="$REAPER_USER_PLUGINS/reaper_reapack-x86_64.so"
    if [ ! -e "$REAPACK_SO" ]; then
      echo "Installing ReaPack extension..."
      ln -sf ${pkgs.reaper-reapack-extension}/UserPlugins/reaper_reapack-x86_64.so "$REAPACK_SO"
    fi
    
    # Install SWS extension if not already present or broken
    SWS_SO="$REAPER_USER_PLUGINS/reaper_sws-x86_64.so"
    if [ ! -e "$SWS_SO" ]; then
      echo "Installing SWS extension..."
      ln -sf ${pkgs.reaper-sws-extension}/UserPlugins/reaper_sws-x86_64.so "$SWS_SO"
    fi
    
    # Set Wine environment for yabridge
    export WINELOADER="${wineStaging}/bin/wine"
    export WINEARCH="win64"
    export WINEDEBUG="-all"
    export WINEFSYNC="1"
    export WINE_LARGE_ADDRESS_AWARE="1"
    export DXVK_HUD="0"
    export DXVK_LOG_LEVEL="none"
    
    # Launch REAPER
    exec ${pkgs.unstable.reaper}/bin/reaper "$@"
  '';
in

mkApp {
  _file = toString ./.;
  name = "reaper";
  linuxPackages = pkgs: [
    # Use our wrapper instead of reaper directly
    reaperWrapper

    # === Wine Setup ===
    # Wine Staging with WoW64 support (64-bit + 32-bit Windows apps)
    # Staging is required for best plugin compatibility
    wineStaging

    # Yabridge - bridge for Windows VST plugins (uses our staging Wine)
    (pkgs.yabridge.override { wine = wineStaging; })
    pkgs.yabridgectl

    # Winetricks for installing Windows dependencies
    pkgs.winetricks

    # === DXVK & Vulkan (Critical for modern plugin GUIs) ===
    pkgs.dxvk # Direct3D to Vulkan translation layer
    pkgs.vulkan-loader # Vulkan runtime (AMD RADV driver used automatically)
    pkgs.vulkan-tools # For debugging (vulkaninfo, etc.)

    # === Runtime Dependencies ===
    pkgs.cabextract # Extract Windows cab files
    pkgs.wineasio # ASIO to JACK driver for Wine
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

    # Configure PAM limits for realtime audio
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

    # Low-latency PipeWire configuration for professional audio
    services.pipewire.extraConfig.pipewire."10-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 128;
        default.clock.min-quantum = 128;
        default.clock.max-quantum = 256;
      };
    };

    # JACK-specific PipeWire configuration
    services.pipewire.extraConfig.jack."20-realtime" = {
      jack.properties = {
        # Match PipeWire's sample rate
        "node.latency" = "128/48000";
        # Enable realtime scheduling
        "jack.realtime" = true;
        "jack.realtime-priority" = 88;
      };
    };

    users.users.${config.user.userName}.extraGroups = [ "audio" ];

    # Environment variables for Wine/yabridge audio setup
    # NOTE: Do NOT set WINEPREFIX globally - yabridge auto-detects prefix from plugin path
    # Setting it globally would override the auto-detection and cause issues
    environment.sessionVariables = {
      # Point yabridge to use Wine 9.20 instead of the system Wine
      # This is critical - Wine 9.22+ has GUI issues with yabridge
      WINELOADER = "${wineStaging}/bin/wine";

      # Wine configuration (no WINEPREFIX - let yabridge auto-detect from plugin location)
      WINEARCH = "win64";
      WINEDEBUG = "-all"; # Disable Wine debug output for performance

      # Performance optimizations
      WINEFSYNC = "1"; # Enable fsync for better threading (kernel 5.16+)
      WINE_LARGE_ADDRESS_AWARE = "1"; # Better memory handling for plugins

      # DXVK configuration
      DXVK_HUD = "0"; # Disable DXVK overlay (set to "fps" to show FPS)
      DXVK_LOG_LEVEL = "none"; # Disable DXVK logging for performance

      # Yabridge settings
      YABRIDGE_DEBUG_LEVEL = "0"; # Set to 1 or 2 for debugging plugin issues
    };
  };
} args
