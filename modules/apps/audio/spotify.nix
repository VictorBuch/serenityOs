args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "spotify";
  category = "audio";
  packages = { pkgs, ... }: [ pkgs.spotify ];
  description = "Spotify music streaming";
  # Spotify Connect discovery; the firewall option is NixOS-only.
  extraConfig =
    { lib, platform, ... }:
    lib.optionalAttrs (platform == "linux") {
      networking.firewall.allowedUDPPorts = [ 5353 ];
    };
} args
