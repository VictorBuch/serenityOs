args@{ config, pkgs, lib, mkModule, ... }:

mkModule {
  name = "spotify";
  category = "audio";
  packages = { pkgs, ... }: [ pkgs.spotify ];
  description = "Spotify music streaming";
  linuxExtraConfig = {
    networking.firewall.allowedUDPPorts = [ 5353 ];
  };
} args
