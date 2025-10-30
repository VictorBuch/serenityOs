args@{ config, pkgs, lib, mkApp, ... }:

mkApp {
  _file = toString ./.;
  name = "music-assistant";
  description = "Music Assistant - open source music server";
  packages = pkgs: [];  # No packages for services

  extraConfig = {
    services.music-assistant = {
      enable = true;
      providers = [
        "audiobookshelf"
        "builtin"
        "builtin_player"
        "chromecast"
        "jellyfin"
        "player_group"
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
} args
