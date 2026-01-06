{
  lib,
  config,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.music-assistant;
in
{

  options.music-assistant = {
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
        "snapcast"
        "spotify"
        "spotify_connect"
      ];
    };
    # Open firewall ports
    networking.firewall.allowedTCPPorts = [
      8097
      8095
    ];

  };
}
