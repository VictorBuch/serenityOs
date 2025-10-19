args@{ config, pkgs, lib, inputs ? null, isLinux, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "reaper";
  linuxPackages = pkgs: [
    pkgs.reaper
    pkgs.wine-staging
    pkgs.yabridge
    pkgs.yabridgectl
  ];
  description = "Reaper DAW with Windows plugin support (Linux only)";
  linuxExtraConfig = {
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
  };
} args
