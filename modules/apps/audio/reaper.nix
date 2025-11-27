args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "reaper";
  linuxPackages = pkgs: [
    pkgs.reaper
    # Wine with WoW64 support (64-bit + 32-bit Windows apps)
    pkgs.wineWowPackages.staging
    # Yabridge - bridge for Windows VST plugins (overridden to use system Wine)
    (pkgs.yabridge.override { wine = pkgs.wineWowPackages.staging; })
    pkgs.yabridgectl # CLI tool to manage yabridge
    pkgs.winetricks # Install Windows libraries VSTs might need
    # Runtime dependencies for VSTs
    pkgs.cabextract # Extract Windows cab files
    # Additional audio VST support
    pkgs.wineasio # ASIO to JACK driver for Wine
  ];
  description = "Reaper DAW with Windows plugin support and JACK audio (Linux only)";
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

    environment.sessionVariables = {
      WINEPREFIX = "$HOME/.wine";
      WINEARCH = "win64"; # Use 64-bit Wine prefix (can still run 32-bit plugins)
      WINEDEBUG = "-all"; # Disable Wine debug output for performance
    };
  };
} args
