{
  config,
  pkgs,
  lib,
  ...
}:
{

  options = {
    apps.audio.reaper.enable = lib.mkEnableOption "Enables Reaper DAW";
  };

  config = lib.mkIf config.apps.audio.reaper.enable {
    environment.systemPackages = with pkgs; [
      reaper
      wine-staging
      yabridge
      yabridgectl
    ];

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
}
