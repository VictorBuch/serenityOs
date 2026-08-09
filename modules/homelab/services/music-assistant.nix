{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.homelab.music-assistant;
in
{

  options.homelab.music-assistant = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the music assistant service.";
    };
  };

  config = mkIf cfg.enable {

    services.music-assistant = {
      enable = true;
      providers = [
        "audiobookshelf"
        "builtin"
        "chromecast"
        "jellyfin"
        "podcastfeed"
        "radiobrowser"
        "spotify"
        "spotify_connect"
        "tidal"
      ];
      openFirewall = true;
    };

    # services.music-assistant.openFirewall only opens the stream port (8097)
    # and the airplay/squeezelite UDP ports — not the web/API port. LAN clients
    # (desktop app, mobile app) need 8095 reachable directly.
    networking.firewall.allowedTCPPorts = [ 8095 ];
  };
}
